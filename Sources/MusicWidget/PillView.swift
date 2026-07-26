import SwiftUI

struct PillView: View {
    @ObservedObject var viewModel: PlayerViewModel

    /// The gap between the text block and the controls is a plain
    /// `Spacer` up to this width. Beyond it there's enough freed-up room
    /// (from dragging the pill wider) that the elapsed/duration readout and
    /// bar read as intentional rather than a cramped sliver, so they take
    /// over that gap.
    private static let progressBarThreshold: CGFloat = 420

    @State private var currentWidth: CGFloat = 320
    @StateObject private var marqueeSync = MarqueeSync()

    private var showsProgressBar: Bool {
        currentWidth >= Self.progressBarThreshold && viewModel.duration > 0
    }

    var body: some View {
        HStack(spacing: 12) {
            artwork
            VStack(alignment: .leading, spacing: 2) {
                MarqueeText(text: viewModel.nowPlayingTitle, font: .system(size: 13, weight: .semibold), sync: marqueeSync)
                    .accessibilityIdentifier(AccessibilityID.nowPlayingTitle)
                MarqueeText(text: viewModel.nowPlayingSubtitle, font: .system(size: 11), color: .secondary, sync: marqueeSync)
                    .accessibilityIdentifier(AccessibilityID.nowPlayingSubtitle)
            }
            if showsProgressBar {
                PlaybackProgressView(elapsed: viewModel.elapsed, duration: viewModel.duration)
            } else {
                Spacer(minLength: 8)
            }
            PlaybackControlButtons(viewModel: viewModel, fontSize: 16)
        }
        .padding(12)
        .frame(height: 68)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .background(
            GeometryReader { proxy in
                Color.clear.onChange(of: proxy.size.width, initial: true) { _, newValue in
                    currentWidth = newValue
                }
            }
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.pillRoot)
    }

    private var artwork: some View {
        Group {
            if let image = viewModel.artworkImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.quaternary)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
