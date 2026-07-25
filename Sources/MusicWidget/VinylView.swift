import SwiftUI

struct VinylView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @State private var angle: Double = 0

    private let ticker = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
    private let degreesPerTick: Double = 1.2

    var body: some View {
        VStack(spacing: 14) {
            record
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
        if !viewModel.isSourceRunning { return "Nothing playing" }
        return viewModel.track?.name ?? "Nothing playing"
    }

    private var subtitle: String {
        if !viewModel.isSourceRunning { return "Open Spotify or Music to get started" }
        return viewModel.track?.artist ?? " "
    }

    private var record: some View {
        ZStack {
            Circle()
                .fill(.black)

            grooves

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.18), .clear],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .blendMode(.plusLighter)

            label

            Circle()
                .fill(.black)
                .frame(width: 6, height: 6)
        }
        .frame(width: 160, height: 160)
        .rotationEffect(.degrees(angle))
    }

    /// Concentric ring strokes fake the record's groove texture.
    private var grooves: some View {
        ZStack {
            ForEach(Array(stride(from: 44, through: 78, by: 4)), id: \.self) { radius in
                Circle()
                    .stroke(.white.opacity(0.07), lineWidth: 1)
                    .frame(width: CGFloat(radius) * 2, height: CGFloat(radius) * 2)
            }
        }
    }

    private var label: some View {
        ZStack {
            Circle()
                .fill(Color(white: 0.85))
                .frame(width: 62, height: 62)

            if let image = viewModel.artworkImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 62, height: 62)
                    .clipShape(Circle())
            }

            Circle()
                .stroke(.black.opacity(0.3), lineWidth: 1)
                .frame(width: 62, height: 62)
        }
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
        .disabled(!viewModel.isSourceRunning)
    }
}
