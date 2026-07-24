import SwiftUI

struct IPodView: View {
    @ObservedObject var viewModel: PlayerViewModel

    private let bodyWidth: CGFloat = 210
    private let bodyHeight: CGFloat = 352
    private let bodyCornerRadius: CGFloat = 32
    private let contentWidth: CGFloat = 178

    var body: some View {
        VStack(spacing: 14) {
            screen
            clickWheel
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .frame(width: bodyWidth, height: bodyHeight)
        .background(metalBody)
        .shadow(color: .black.opacity(0.4), radius: 16, y: 10)
        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
    }

    // MARK: - Body

    /// Real iPod Classic bodies are mostly flat brushed steel with very soft
    /// shading, not a strong stripe texture — a subtle diagonal gradient
    /// plus a thin bevel reads closer to the real thing than heavy stripes.
    private var metalBody: some View {
        RoundedRectangle(cornerRadius: bodyCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.99), Color(white: 0.87), Color(white: 0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: bodyCornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white, Color(white: 0.75)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: bodyCornerRadius, style: .continuous)
                    .stroke(.black.opacity(0.15), lineWidth: 0.75)
            )
    }

    // MARK: - Screen

    private var title: String {
        if !viewModel.isSpotifyRunning { return "Nothing Playing" }
        return viewModel.track?.name ?? "Nothing Playing"
    }

    private var subtitle: String {
        if !viewModel.isSpotifyRunning { return "Open Spotify" }
        return viewModel.track?.artist ?? " "
    }

    private var screenSize: CGSize { CGSize(width: contentWidth, height: 132) }
    private let screenCornerRadius: CGFloat = 14

    private var screen: some View {
        ZStack {
            Rectangle().fill(.black)

            if let image = viewModel.artworkImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: screenSize.width, height: screenSize.height)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 22))
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.55))
            }

            if viewModel.track != nil {
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(title)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                            Text(subtitle)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 4)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                }
                .foregroundStyle(.white)
            }

            glassReflection
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .clipShape(RoundedRectangle(cornerRadius: screenCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: screenCornerRadius, style: .continuous)
                .strokeBorder(.black.opacity(0.7), lineWidth: 1)
        )
    }

    private var glassReflection: some View {
        Ellipse()
            .fill(.white.opacity(0.16))
            .frame(width: 220, height: 60)
            .rotationEffect(.degrees(-18))
            .offset(x: 35, y: -30)
            .blur(radius: 6)
    }

    // MARK: - Click wheel

    private let wheelDiameter: CGFloat = 178
    private let centerButtonDiameter: CGFloat = 66

    private var clickWheel: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [Color(white: 1.0), Color(white: 0.92)], center: .center, startRadius: 20, endRadius: wheelDiameter / 2)
                )
                .overlay(Circle().stroke(.black.opacity(0.12), lineWidth: 1))

            Text("MENU")
                .font(.system(size: 11, weight: .bold))
                .offset(y: -wheelDiameter / 2 + 26)

            Image(systemName: "backward.end.fill")
                .font(.system(size: 13))
                .offset(x: -(wheelDiameter / 2 - 26))
                .contentShape(Circle())
                .onTapGesture { viewModel.skipPrevious() }

            Image(systemName: "forward.end.fill")
                .font(.system(size: 13))
                .offset(x: wheelDiameter / 2 - 26)
                .contentShape(Circle())
                .onTapGesture { viewModel.skipNext() }

            Image(systemName: viewModel.state == .playing ? "pause.fill" : "play.fill")
                .font(.system(size: 13))
                .offset(y: wheelDiameter / 2 - 26)
                .contentShape(Circle())
                .onTapGesture { viewModel.togglePlayPause() }

            Circle()
                .fill(
                    RadialGradient(colors: [Color(white: 0.97), Color(white: 0.86)], center: UnitPoint(x: 0.4, y: 0.35), startRadius: 4, endRadius: centerButtonDiameter / 2 + 10)
                )
                .overlay(Circle().stroke(.black.opacity(0.15), lineWidth: 1))
                .frame(width: centerButtonDiameter, height: centerButtonDiameter)
                .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
                .contentShape(Circle())
                .onTapGesture { viewModel.togglePlayPause() }
        }
        .foregroundStyle(.black.opacity(0.55))
        .frame(width: wheelDiameter, height: wheelDiameter)
        .opacity(viewModel.isSpotifyRunning ? 1 : 0.5)
        .allowsHitTesting(viewModel.isSpotifyRunning)
    }
}
