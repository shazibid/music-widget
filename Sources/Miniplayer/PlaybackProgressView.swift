import SwiftUI

/// Elapsed/bar/duration readout shared by the pill and the two
/// spinning-disc skins (CD, Vinyl).
struct PlaybackProgressView: View {
    let elapsed: TimeInterval
    let duration: TimeInterval

    var body: some View {
        HStack(spacing: 6) {
            timeLabel(elapsed)
            bar
            timeLabel(duration)
        }
    }

    private var bar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.primary.opacity(0.12))
                Capsule()
                    .fill(.primary.opacity(0.8))
                    .frame(width: max(3, proxy.size.width * fraction))
                    .animation(.linear(duration: 1), value: fraction)
            }
        }
        .frame(minWidth: 40, maxWidth: .infinity)
        .frame(height: 4)
    }

    private var fraction: Double {
        guard duration > 0 else { return 0 }
        return min(max(elapsed / duration, 0), 1)
    }

    private func timeLabel(_ seconds: TimeInterval) -> some View {
        Text(Self.formatTime(seconds))
            .font(.system(size: 10, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(.secondary)
    }

    private static func formatTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
