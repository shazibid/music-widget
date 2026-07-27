import SwiftUI

/// Skip-back / play-pause / skip-forward row shared by the Pill, CD, and
/// Vinyl skins. The iPod skin has its own click-wheel hit targets instead
/// (see `IPodView.wheelHitTargets`).
struct PlaybackControlButtons: View {
    @ObservedObject var viewModel: PlayerViewModel
    var fontSize: CGFloat

    var body: some View {
        HStack(spacing: 14) {
            Button(action: viewModel.skipPrevious) {
                Image(systemName: "backward.fill")
            }
            .accessibilityIdentifier(AccessibilityID.previousButton)
            Button(action: viewModel.togglePlayPause) {
                Image(systemName: viewModel.state == .playing ? "pause.fill" : "play.fill")
            }
            .accessibilityIdentifier(AccessibilityID.playPauseButton)
            Button(action: viewModel.skipNext) {
                Image(systemName: "forward.fill")
            }
            .accessibilityIdentifier(AccessibilityID.nextButton)
        }
        .buttonStyle(.plain)
        .font(.system(size: fontSize, weight: .medium))
        .disabled(!viewModel.isSourceRunning)
    }
}
