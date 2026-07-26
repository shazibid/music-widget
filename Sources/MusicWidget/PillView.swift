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

    private var showsProgressBar: Bool {
        currentWidth >= Self.progressBarThreshold && viewModel.duration > 0
    }

    var body: some View {
        HStack(spacing: 12) {
            artwork
            VStack(alignment: .leading, spacing: 2) {
                MarqueeText(text: title, font: .system(size: 13, weight: .semibold))
                MarqueeText(text: subtitle, font: .system(size: 11), color: .secondary)
            }
            if showsProgressBar {
                progressGroup
            } else {
                Spacer(minLength: 8)
            }
            controls
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
    }

    private var progressGroup: some View {
        HStack(spacing: 6) {
            timeLabel(viewModel.elapsed)
            progressBar
            timeLabel(viewModel.duration)
        }
    }

    private func timeLabel(_ seconds: TimeInterval) -> some View {
        Text(Self.formatTime(seconds))
            .font(.system(size: 10, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(.secondary)
    }

    private var progressBar: some View {
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
        guard viewModel.duration > 0 else { return 0 }
        return min(max(viewModel.elapsed / viewModel.duration, 0), 1)
    }

    private static func formatTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private var title: String {
        if !viewModel.isSourceRunning { return "Nothing playing" }
        return viewModel.track?.name ?? "Nothing playing"
    }

    private var subtitle: String {
        if !viewModel.isSourceRunning { return "Open Spotify or Music to get started" }
        return viewModel.track?.artist ?? " "
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

    private var controls: some View {
        HStack(spacing: 14) {
            Button(action: viewModel.skipPrevious) {
                Image(systemName: "backward.fill")
            }
            Button(action: viewModel.togglePlayPause) {
                Image(systemName: viewModel.state == .playing ? "pause.fill" : "play.fill")
            }
            Button(action: viewModel.skipNext) {
                Image(systemName: "forward.fill")
            }
        }
        .buttonStyle(.plain)
        .font(.system(size: 16, weight: .medium))
        .disabled(!viewModel.isSourceRunning)
    }
}
