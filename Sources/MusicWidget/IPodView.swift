import SwiftUI

/// Overlays a live screen and real tap targets on top of the baked-in
/// `ipod-body` artwork (a cropped device render — see Resources/) instead of
/// hand-drawing the body/wheel in SwiftUI. All the geometry below was
/// measured directly from that image's pixels, then scaled to `bodyWidth`.
struct IPodView: View {
    @ObservedObject var viewModel: PlayerViewModel

    private let bodyWidth: CGFloat = 210
    private let bodyHeight: CGFloat = 210 * (486.0 / 295.0)
    private let scale: CGFloat = 210 / 295.0

    /// Loaded via `NSImage(contentsOf:)` rather than `Image(_:bundle:)` —
    /// the latter only resolves asset-catalog entries, not loose `.copy`
    /// resources like this one.
    private static let bodyImage: NSImage? = {
        guard let url = Bundle.module.url(forResource: "ipod-body", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }()

    var body: some View {
        ZStack {
            if let bodyImage = Self.bodyImage {
                Image(nsImage: bodyImage)
                    .resizable()
                    .frame(width: bodyWidth, height: bodyHeight)
            }

            screen
                .frame(width: screenSize.width, height: screenSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                .position(x: screenOrigin.x + screenSize.width / 2, y: screenOrigin.y + screenSize.height / 2)

            wheelHitTargets
        }
        .frame(width: bodyWidth, height: bodyHeight)
    }

    // MARK: - Screen

    private var title: String {
        if !viewModel.isSourceRunning { return "Nothing Playing" }
        return viewModel.track?.name ?? "Nothing Playing"
    }

    private var subtitle: String {
        if !viewModel.isSourceRunning { return "Open Spotify or Music" }
        return viewModel.track?.artist ?? " "
    }

    private var screenOrigin: CGPoint { CGPoint(x: 32 * scale, y: 26 * scale) }
    private var screenSize: CGSize { CGSize(width: 231 * scale, height: 175 * scale) }

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
        }
    }

    // MARK: - Click wheel hit targets

    private var wheelCenter: CGPoint { CGPoint(x: 147.5 * scale, y: 328.5 * scale) }
    private var wheelDiameter: CGFloat { 169 * scale }
    private var iconRadius: CGFloat { 72 * scale }

    /// Clipped to the wheel's own circle so a pressed button's shadow stays
    /// on the white ring instead of bleeding onto the plain body around it.
    private var wheelHitTargets: some View {
        ZStack {
            hitTarget(diameter: 42, offset: CGPoint(x: 0, y: -iconRadius)) {
                // Menu currently has no destination — reserved for future use.
            }
            hitTarget(diameter: 42, offset: CGPoint(x: -iconRadius, y: 0)) {
                viewModel.skipPrevious()
            }
            hitTarget(diameter: 42, offset: CGPoint(x: iconRadius, y: 0)) {
                viewModel.skipNext()
            }
            hitTarget(diameter: 42, offset: CGPoint(x: 0, y: iconRadius)) {
                viewModel.togglePlayPause()
            }
            hitTarget(diameter: 50, offset: .zero) {
                viewModel.togglePlayPause()
            }
        }
        .frame(width: wheelDiameter, height: wheelDiameter)
        .clipShape(Circle())
        .position(wheelCenter)
        .allowsHitTesting(viewModel.isSourceRunning)
    }

    private func hitTarget(diameter: CGFloat, offset: CGPoint, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(.clear)
                .contentShape(Circle())
        }
        .buttonStyle(WheelButtonStyle())
        .frame(width: diameter, height: diameter)
        .offset(x: offset.x, y: offset.y)
    }
}

/// Darkens the tapped spot with an inset-looking shadow so a click reads as
/// the button being pushed into the wheel, since the icons themselves are
/// baked into the body artwork and can't shift or highlight on their own.
private struct WheelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle()
                    .fill(.black.opacity(configuration.isPressed ? 0.06 : 0))
                    .shadow(color: .black.opacity(configuration.isPressed ? 0.12 : 0), radius: 2, y: 0.5)
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
