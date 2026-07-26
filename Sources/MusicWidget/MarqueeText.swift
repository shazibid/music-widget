import SwiftUI

/// A single-line text view that scrolls continuously to the left when its
/// content is wider than the space available, instead of truncating with an
/// ellipsis. Sibling `MarqueeText`s sharing a `MarqueeSync` rest and restart
/// together — see that type for why.
struct MarqueeText: View {
    let text: String
    var font: Font
    var color: Color = .primary
    @ObservedObject var sync: MarqueeSync

    private static let speed: CGFloat = 40 // points per second
    private static let gap: CGFloat = 20 // space between looping copies

    @State private var containerWidth: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var id = UUID()

    private var overflowing: Bool {
        textWidth > containerWidth + 1
    }

    private var distance: CGFloat { textWidth + Self.gap }
    private var duration: Double { Double(distance / Self.speed) }

    var body: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .opacity(0)
            .accessibilityHidden(true)
            .background(
                GeometryReader { proxy in
                    Color.clear.onChange(of: proxy.size.width, initial: true) { _, newValue in
                        containerWidth = newValue
                    }
                }
            )
            .overlay(alignment: .leading) {
                ZStack(alignment: .leading) {
                    label
                        .fixedSize(horizontal: true, vertical: false)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.onChange(of: proxy.size.width, initial: true) { _, newValue in
                                    textWidth = newValue
                                }
                            }
                        )
                        .opacity(overflowing ? 0 : 1)

                    if overflowing {
                        HStack(spacing: Self.gap) {
                            label
                            label
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .offset(x: offset)
                        .onChange(of: duration, initial: true) { _, newValue in
                            sync.register(id: id, duration: newValue)
                        }
                        .onDisappear { sync.unregister(id: id) }
                        .task(id: sync.phase) {
                            await follow(sync.phase)
                        }
                    }
                }
            }
            .clipped()
    }

    private var label: some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(1)
    }

    private func follow(_ phase: MarqueeSync.Phase) async {
        switch phase {
        case .resting:
            offset = 0
        case .scrolling(let generation):
            withAnimation(.linear(duration: duration)) { offset = -distance }
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            sync.markFinished(id: id, generation: generation)
        }
    }
}
