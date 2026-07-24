import SwiftUI

struct PillView: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        HStack(spacing: 12) {
            artwork
            VStack(alignment: .leading, spacing: 2) {
                MarqueeText(text: title, font: .system(size: 13, weight: .semibold))
                MarqueeText(text: subtitle, font: .system(size: 11), color: .secondary)
            }
            Spacer(minLength: 8)
            controls
        }
        .padding(12)
        .frame(width: 320, height: 68)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var title: String {
        if !viewModel.isSpotifyRunning { return "Spotify isn't running" }
        return viewModel.track?.name ?? "Nothing playing"
    }

    private var subtitle: String {
        if !viewModel.isSpotifyRunning { return "Open Spotify to get started" }
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
        .disabled(!viewModel.isSpotifyRunning)
    }
}
