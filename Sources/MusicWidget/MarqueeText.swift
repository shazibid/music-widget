import SwiftUI

/// A single-line text view that scrolls continuously to the left when its
/// content is wider than the space available, instead of truncating with an
/// ellipsis.
struct MarqueeText: View {
    let text: String
    var font: Font
    var color: Color = .primary

    private static let speed: CGFloat = 40 // points per second
    private static let gap: CGFloat = 20 // space between looping copies
    private static let pause: Double = 1.5 // rest at the start of each loop

    @State private var containerWidth: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    private var overflowing: Bool {
        textWidth > containerWidth + 1
    }

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
                        .task(id: LoopKey(text: text, distance: textWidth + Self.gap)) {
                            await scroll(distance: textWidth + Self.gap)
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

    private struct LoopKey: Equatable {
        let text: String
        let distance: CGFloat
    }

    private func scroll(distance: CGFloat) async {
        offset = 0
        guard distance > Self.gap + 1 else { return }
        let duration = Double(distance / Self.speed)
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Self.pause))
            guard !Task.isCancelled else { return }
            withAnimation(.linear(duration: duration)) { offset = -distance }
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            offset = 0 // instant snap back; identical on-screen to -distance since the copies loop seamlessly
        }
    }
}
