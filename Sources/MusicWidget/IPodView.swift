import SwiftUI

struct IPodView: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: 18) {
            screen
            clickWheel
        }
        .padding(16)
        .frame(width: 220, height: 334)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: [.white, Color(white: 0.85)], startPoint: .top, endPoint: .bottom))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.black.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
    }

    private var title: String {
        if !viewModel.isSpotifyRunning { return "Nothing Playing" }
        return viewModel.track?.name ?? "Nothing Playing"
    }

    private var subtitle: String {
        if !viewModel.isSpotifyRunning { return "Open Spotify" }
        return viewModel.track?.artist ?? " "
    }

    private var screen: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(viewModel.state == .playing ? "Now Playing" : "Paused")
                    .font(.system(size: 9, weight: .semibold))
                Spacer()
                Image(systemName: "battery.100")
                    .font(.system(size: 9))
            }
            .foregroundStyle(.black.opacity(0.65))

            Spacer(minLength: 2)

            HStack(spacing: 8) {
                artworkThumbnail
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.black.opacity(0.6))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 2)
        }
        .padding(10)
        .frame(width: 188, height: 110)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(red: 0.78, green: 0.86, blue: 0.74)))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.black.opacity(0.25), lineWidth: 1))
    }

    private var artworkThumbnail: some View {
        Group {
            if let image = viewModel.artworkImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(.black.opacity(0.15))
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
    }

    private var clickWheel: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.87))
                .frame(width: 176, height: 176)

            Text("MENU")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.black.opacity(0.55))
                .offset(y: -64)

            Image(systemName: "backward.end.fill")
                .font(.system(size: 13))
                .foregroundStyle(.black.opacity(0.55))
                .offset(x: -64)
                .contentShape(Circle())
                .onTapGesture { viewModel.skipPrevious() }

            Image(systemName: "forward.end.fill")
                .font(.system(size: 13))
                .foregroundStyle(.black.opacity(0.55))
                .offset(x: 64)
                .contentShape(Circle())
                .onTapGesture { viewModel.skipNext() }

            Image(systemName: viewModel.state == .playing ? "pause.fill" : "play.fill")
                .font(.system(size: 13))
                .foregroundStyle(.black.opacity(0.55))
                .offset(y: 64)
                .contentShape(Circle())
                .onTapGesture { viewModel.togglePlayPause() }

            Circle()
                .fill(Color(white: 0.97))
                .frame(width: 68, height: 68)
                .overlay(Circle().strokeBorder(.black.opacity(0.08)))
                .shadow(color: .black.opacity(0.15), radius: 1)
                .contentShape(Circle())
                .onTapGesture { viewModel.togglePlayPause() }
        }
        .frame(width: 176, height: 176)
        .opacity(viewModel.isSpotifyRunning ? 1 : 0.5)
        .allowsHitTesting(viewModel.isSpotifyRunning)
    }
}
