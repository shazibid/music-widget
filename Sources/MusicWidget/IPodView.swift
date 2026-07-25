import SwiftUI

/// Overlays a live screen and real tap targets on top of the baked-in
/// `ipod-body` artwork (a cropped device render — see Resources/) instead of
/// hand-drawing the body/wheel in SwiftUI. All the geometry below was
/// measured directly from that image's pixels, then scaled to `bodyWidth`.
struct IPodView: View {
    @ObservedObject var viewModel: PlayerViewModel

    @State private var showingQueue = false

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

    /// The artwork's canvas is taller than the device itself: it reserves
    /// space at the bottom for a baked-in drop shadow. Measured from the
    /// image's pixels (using the unobstructed top half as reference, since
    /// the shadow contaminates the bottom edge), the device itself sits at
    /// x:[12, 283], y:[6, 462] out of the 295×486 canvas. Masking to that
    /// rect discards the baked shadow so the window's own native shadow
    /// (see `main.swift`) hugs the device's true silhouette instead of the
    /// full padded canvas.
    private var deviceBounds: CGRect {
        CGRect(x: 12 * scale, y: 6 * scale, width: 271 * scale, height: 456 * scale)
    }
    private var deviceCornerRadius: CGFloat { 20 * scale }

    /// The screen bezel was measured on a reference canvas where the device
    /// (i.e. `deviceBounds`, not the shadow-padded PNG) rendered at 375×628:
    /// an inner rect of 308×231 and an outer rect of 318×243 with a corner
    /// radius of 5. Only the padding between those two rects is used here —
    /// applied to the already-tuned `screenSize` — so this doesn't disturb
    /// the screen's own hand-fitted position. `deviceBounds.width / 375`
    /// converts that reference canvas into this view's own point space.
    private var screenBorderPadding: CGSize {
        let referenceScale = deviceBounds.width / 375
        return CGSize(width: 5 * referenceScale, height: 6 * referenceScale)
    }
    private var screenBorderRadius: CGFloat { 5 * deviceBounds.width / 375 }

    var body: some View {
        ZStack {
            if let bodyImage = Self.bodyImage {
                Image(nsImage: bodyImage)
                    .resizable()
                    .frame(width: bodyWidth, height: bodyHeight)
                    .mask(
                        RoundedRectangle(cornerRadius: deviceCornerRadius, style: .continuous)
                            .frame(width: deviceBounds.width, height: deviceBounds.height)
                            .position(x: deviceBounds.midX, y: deviceBounds.midY)
                    )
            }

            RoundedRectangle(cornerRadius: screenBorderRadius, style: .continuous)
                .fill(.black)
                .frame(
                    width: screenSize.width + screenBorderPadding.width * 2,
                    height: screenSize.height + screenBorderPadding.height * 2
                )
                .position(x: screenOrigin.x + screenSize.width / 2, y: screenOrigin.y + screenSize.height / 2)

            screen
                .frame(width: screenSize.width, height: screenSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                .position(x: screenOrigin.x + screenSize.width / 2, y: screenOrigin.y + screenSize.height / 2)

            wheelHitTargets
        }
        .frame(width: bodyWidth, height: bodyHeight)
        // The ZStack above is laid out on the full, shadow-padded canvas so
        // every pixel-measured position (screenOrigin, wheelCenter, etc.)
        // stays valid. Shifting by -deviceBounds.origin and re-framing to
        // deviceBounds.size crops that padding away from the *window* too —
        // otherwise the window stays canvas-sized while only the artwork
        // gets clipped, leaving a dead-space margin between the visible
        // device and the window/screen edge.
        .offset(x: -deviceBounds.minX, y: -deviceBounds.minY)
        .frame(width: deviceBounds.width, height: deviceBounds.height, alignment: .topLeading)
        .clipped()
        .onChange(of: viewModel.isSourceRunning) { _, isRunning in
            if !isRunning {
                showingQueue = false
                viewModel.setQueueVisible(false)
            }
        }
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

            if showingQueue && viewModel.isSourceRunning {
                queueScreen
            } else {
                nowPlayingScreen
            }
        }
    }

    private var nowPlayingScreen: some View {
        ZStack {
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

    // MARK: - Queue

    /// Styled after the click-wheel iPod's own list screens: a Monaco
    /// (classic bitmap-Mac heritage) header over a plain list, since there's
    /// no bundled facsimile of the original device's actual bitmap font.
    private var queueScreen: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("UP NEXT")
                .font(.custom("Monaco", size: 11))
                .fontWeight(.bold)
                .tracking(0.5)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .padding(.bottom, 5)

            Rectangle()
                .fill(.white.opacity(0.25))
                .frame(height: 1)

            if !viewModel.queueSupported {
                queueMessage("Queue not available\nfor Spotify")
            } else if viewModel.isQueueOnOtherDevice {
                queueMessage("Playing on\nanother device")
            } else if viewModel.queue.isEmpty {
                queueMessage(viewModel.isLoadingQueue ? "Loading…" : "No Upcoming Tracks")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(viewModel.queue) { track in
                            VStack(alignment: .leading, spacing: 1) {
                                Text(track.name)
                                    .font(.custom("Monaco", size: 10))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(track.artist)
                                    .font(.custom("Monaco", size: 9))
                                    .foregroundStyle(.white.opacity(0.55))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private func queueMessage(_ text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.custom("Monaco", size: 10))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
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
                showingQueue.toggle()
                viewModel.setQueueVisible(showingQueue)
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
            hitTarget(diameter: 50, offset: .zero, clipDiameter: holeDiameter) {
                viewModel.togglePlayPause()
            }
        }
        .frame(width: wheelDiameter, height: wheelDiameter)
        .clipShape(Circle())
        .position(wheelCenter)
        .allowsHitTesting(viewModel.isSourceRunning)
    }

    /// The recessed hole at the wheel's center. Sized from the traced
    /// reference (84×84 against a 375-wide device), via the same
    /// `deviceBounds.width / 375` reference scale used for the screen bezel
    /// above — the earlier pixel-guessed value (83 against the 295-wide
    /// canvas) was noticeably too large relative to the actual device.
    private var holeDiameter: CGFloat { 84 * deviceBounds.width / 375 }

    private func hitTarget(diameter: CGFloat, offset: CGPoint, clipDiameter: CGFloat? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(.clear)
                .contentShape(Circle())
        }
        .buttonStyle(WheelButtonStyle(diameter: diameter, clipDiameter: clipDiameter))
        .frame(width: diameter, height: diameter)
        .offset(x: offset.x, y: offset.y)
    }
}

/// Darkens the tapped spot with a soft radial fade (no hard edge) so a click
/// reads as gentle shading pushed into the wheel, rather than a sticker
/// dropped on top — `.multiply` lets it shade the artwork underneath instead
/// of sitting as a flat, opaque disc. `clipDiameter`, when set, caps the glow
/// to a specific circle (e.g. the wheel's center hole) instead of letting it
/// grow past `diameter` on its own.
private struct WheelButtonStyle: ButtonStyle {
    let diameter: CGFloat
    var clipDiameter: CGFloat? = nil

    private var visualDiameter: CGFloat { diameter * 1.7 }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(glow(pressed: configuration.isPressed))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    @ViewBuilder
    private func glow(pressed: Bool) -> some View {
        let fade = Circle()
            .fill(
                RadialGradient(
                    colors: [.black.opacity(pressed ? 0.16 : 0), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: visualDiameter / 2
                )
            )
            .blendMode(.multiply)
            .frame(width: visualDiameter, height: visualDiameter)

        if let clipDiameter {
            fade.mask(Circle().frame(width: clipDiameter, height: clipDiameter))
        } else {
            fade
        }
    }
}
