import SwiftUI

struct RotatingCDView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @State private var angle: Double = 0

    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    private let degreesPerTick: Double = 1.2

    var body: some View {
        VStack(spacing: 14) {
            disc
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            controls
        }
        .padding(20)
        .frame(width: 240, height: 300)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onReceive(ticker) { _ in
            guard viewModel.state == .playing else { return }
            angle = (angle + degreesPerTick).truncatingRemainder(dividingBy: 360)
        }
    }

    private var title: String {
        if !viewModel.isSpotifyRunning { return "Spotify isn't running" }
        return viewModel.track?.name ?? "Nothing playing"
    }

    private var subtitle: String {
        if !viewModel.isSpotifyRunning { return "Open Spotify to get started" }
        return viewModel.track?.artist ?? " "
    }

    private var disc: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [.black, .gray.opacity(0.7), .black, .gray.opacity(0.6), .black],
                        center: .center
                    )
                )

            if let image = viewModel.artworkImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 132, height: 132)
                    .clipShape(Circle())
            }

            Circle()
                .stroke(.white.opacity(0.15), lineWidth: 1)

            Circle()
                .fill(.black)
                .frame(width: 16, height: 16)
            Circle()
                .fill(.white.opacity(0.25))
                .frame(width: 5, height: 5)
        }
        .frame(width: 160, height: 160)
        .rotationEffect(.degrees(angle))
        .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
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
        .font(.system(size: 14, weight: .medium))
        .disabled(!viewModel.isSpotifyRunning)
    }
}
