import Foundation

/// Coordinates a group of `MarqueeText` instances (typically a track's title
/// and artist line) so they rest and restart together instead of drifting
/// out of phase. Each line still scrolls at its own constant speed — a
/// longer line simply takes longer to cross — but the whole group only
/// pauses and loops again once every overflowing line has finished its
/// current pass.
@MainActor
final class MarqueeSync: ObservableObject {
    enum Phase: Equatable {
        case resting
        case scrolling(generation: Int)
    }

    private static let pause: Double = 1.5

    @Published private(set) var phase: Phase = .resting

    private var durations: [UUID: Double] = [:]
    private var pending: Set<UUID> = []
    private var generation = 0
    private var loopTask: Task<Void, Never>?

    /// Called by a `MarqueeText` whenever its own scroll duration is known
    /// (or changes, e.g. the track title changed length). Lazily kicks off
    /// the shared loop on the first registrant.
    func register(id: UUID, duration: Double) {
        durations[id] = duration
        if loopTask == nil {
            loopTask = Task { [weak self] in
                await self?.runLoop()
                self?.loopTask = nil
            }
        }
    }

    /// Called when a line stops overflowing (or disappears), so it can't
    /// hold up the group waiting for a finish signal that will never come.
    func unregister(id: UUID) {
        durations.removeValue(forKey: id)
        pending.remove(id)
    }

    /// Called by a `MarqueeText` once its own pass across `distance` has
    /// finished. `generation` guards against a late signal from a cycle the
    /// group has already moved on from.
    func markFinished(id: UUID, generation: Int) {
        guard generation == self.generation else { return }
        pending.remove(id)
    }

    private func runLoop() async {
        while !durations.isEmpty {
            if Task.isCancelled { return }

            phase = .resting
            try? await Task.sleep(for: .seconds(Self.pause))
            if Task.isCancelled || durations.isEmpty { return }

            generation += 1
            pending = Set(durations.keys)
            // Bounds how long the group waits for stragglers: normally every
            // member finishes within its own duration, but this keeps a
            // member that unregisters mid-cycle (e.g. song changed) from
            // stalling the loop indefinitely.
            let deadline = Date().addingTimeInterval((durations.values.max() ?? 0) + 0.5)
            phase = .scrolling(generation: generation)

            while !pending.isEmpty, Date() < deadline {
                if Task.isCancelled { return }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    deinit {
        loopTask?.cancel()
    }
}
