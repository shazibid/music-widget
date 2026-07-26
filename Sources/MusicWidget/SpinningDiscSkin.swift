import SwiftUI

/// Shared chrome for the two spinning-disc skins (CD, Vinyl): identical
/// size, rotation ticker, now-playing labels, and controls — only the disc
/// artwork itself (supplied via `disc`) differs between them.
struct SpinningDiscSkin<Disc: View>: View {
    @ObservedObject var viewModel: PlayerViewModel
    @ViewBuilder var disc: () -> Disc

    @State private var angle: Double = 0

    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    private let degreesPerTick: Double = 1.2

    var body: some View {
        VStack(spacing: 14) {
            disc()
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(angle))
            VStack(spacing: 2) {
                Text(viewModel.nowPlayingTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .accessibilityIdentifier(AccessibilityID.nowPlayingTitle)
                Text(viewModel.nowPlayingSubtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .accessibilityIdentifier(AccessibilityID.nowPlayingSubtitle)
            }
            PlaybackControlButtons(viewModel: viewModel, fontSize: 14)
        }
        .padding(20)
        .frame(width: 240, height: 300)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onReceive(ticker) { _ in
            guard viewModel.state == .playing else { return }
            angle = (angle + degreesPerTick).truncatingRemainder(dividingBy: 360)
        }
    }
}
