import SwiftUI

/// The "Enter Full Screen" destination for the Pill, CD, and Vinyl skins:
/// artwork centered and filling most of the screen, title/artist always
/// visible, and the transport controls revealed on mouse activity —
/// modeled on Spotify desktop's fullscreen now-playing view. Not offered
/// from the iPod skin, which has its own fixed-size device screen.
struct FullScreenNowPlayingView: View {
    @ObservedObject var viewModel: PlayerViewModel
    var onExit: () -> Void

    // This view fills the entire screen, so plain `.onHover` is useless
    // for auto-hiding controls — the cursor is *always* over it while
    // fullscreen, with nowhere to move "away" to. Instead this tracks the
    // last time the mouse actually moved and hides the controls once
    // that's been idle for a bit, the same idle-based reveal every
    // fullscreen video/media player uses.
    @State private var controlsVisible = true
    @State private var lastActivity = Date()
    @StateObject private var marqueeSync = MarqueeSync()

    private static let idleTimeout: TimeInterval = 2.5
    private let idleTicker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            backdrop
            artwork
            controlsOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .contentShape(Rectangle())
        .onContinuousHover { phase in
            switch phase {
            case .active:
                lastActivity = Date()
                controlsVisible = true
            case .ended:
                break
            }
        }
        .onReceive(idleTicker) { _ in
            if controlsVisible, Date().timeIntervalSince(lastActivity) > Self.idleTimeout {
                controlsVisible = false
            }
        }
        // Belt-and-suspenders alongside the hover-driven reveal above: a
        // single click always counts as activity too, in case continuous
        // hover reporting isn't reliable in some environment.
        .onTapGesture(count: 1) {
            lastActivity = Date()
            controlsVisible = true
        }
        .onTapGesture(count: 2, perform: onExit)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.fullScreenRoot)
    }

    /// A blurred, darkened fill of the artwork behind the centered piece,
    /// the same trick Spotify/Apple Music use so the backdrop always
    /// harmonizes with whatever's playing instead of being flat black.
    @ViewBuilder
    private var backdrop: some View {
        if let image = viewModel.artworkImage {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .blur(radius: 60)
                .overlay(Color.black.opacity(0.55))
                .clipped()
        } else {
            Color.black
        }
    }

    private var artwork: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height) * 0.62
            Group {
                if let image = viewModel.artworkImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.08))
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.5), radius: 40, y: 20)
            // Nudged up slightly so the always-visible title/artist below
            // (and the controls that fade in under those on hover) have
            // breathing room without the whole group feeling bottom-heavy.
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2 - side * 0.08)
        }
    }

    private var controlsOverlay: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    MarqueeText(text: viewModel.nowPlayingTitle, font: .system(size: 22, weight: .semibold), color: .white, sync: marqueeSync)
                        .accessibilityIdentifier(AccessibilityID.nowPlayingTitle)
                    MarqueeText(text: viewModel.nowPlayingSubtitle, font: .system(size: 15), color: .white.opacity(0.7), sync: marqueeSync)
                        .accessibilityIdentifier(AccessibilityID.nowPlayingSubtitle)
                }
                .frame(maxWidth: 420)

                VStack(spacing: 10) {
                    PlaybackControlButtons(viewModel: viewModel, fontSize: 28)
                    if viewModel.duration > 0 {
                        PlaybackProgressView(elapsed: viewModel.elapsed, duration: viewModel.duration)
                            .frame(maxWidth: 420)
                    }
                }
                .opacity(controlsVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: controlsVisible)
            }
            .padding(.bottom, 64)
        }
    }
}
