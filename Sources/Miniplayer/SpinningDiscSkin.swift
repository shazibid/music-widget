import SwiftUI

/// Shared chrome for the two spinning-disc skins (CD, Vinyl): identical
/// size, rotation ticker, now-playing labels, and controls — only the disc
/// artwork itself (supplied via `disc`) differs between them.
struct SpinningDiscSkin<Disc: View>: View {
    @ObservedObject var viewModel: PlayerViewModel
    @ViewBuilder var disc: () -> Disc

    @State private var angle: Double = 0
    @StateObject private var marqueeSync = MarqueeSync()

    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    private let degreesPerTick: Double = 1.2

    var body: some View {
        VStack(spacing: 14) {
            disc()
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(angle))
            VStack(spacing: 8) {
                VStack(spacing: 2) {
                    MarqueeText(text: viewModel.nowPlayingTitle, font: .system(size: 13, weight: .semibold), sync: marqueeSync)
                        .accessibilityIdentifier(AccessibilityID.nowPlayingTitle)
                    MarqueeText(text: viewModel.nowPlayingSubtitle, font: .system(size: 11), color: .secondary, sync: marqueeSync)
                        .accessibilityIdentifier(AccessibilityID.nowPlayingSubtitle)
                }
                if viewModel.duration > 0 {
                    PlaybackProgressView(elapsed: viewModel.elapsed, duration: viewModel.duration)
                }
            }
            PlaybackControlButtons(viewModel: viewModel, fontSize: 18)
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
