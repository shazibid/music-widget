import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var skinStore: SkinStore
    var onMinimize: () -> Void

    var body: some View {
        Group {
            switch skinStore.skin {
            case .pill: PillView(viewModel: viewModel)
            case .cd: RotatingCDView(viewModel: viewModel)
            case .vinyl: VinylView(viewModel: viewModel)
            case .ipod: IPodView(viewModel: viewModel)
            }
        }
        // No fade/scale here on purpose: each skin view already renders at
        // its own fixed size (see WidgetSkin.windowSize), and the window
        // frame animates separately in AppDelegate.resizeWindow. Leaving
        // this as `.identity` means the *only* motion you see is that
        // frame animating — the new skin's content is simply revealed or
        // clipped as the border grows/shrinks to meet it.
        .transition(.identity)
        .contentShape(Rectangle())
        .contextMenu {
            ForEach(WidgetSkin.allCases) { option in
                Button {
                    withAnimation(.easeInOut(duration: WidgetSkin.transitionDuration)) {
                        skinStore.skin = option
                    }
                } label: {
                    if option == skinStore.skin {
                        Label(option.displayName, systemImage: "checkmark")
                    } else {
                        Text(option.displayName)
                    }
                }
                .accessibilityIdentifier(AccessibilityID.skinMenuItem(option))
            }
            Divider()
            if viewModel.isSpotifyConnected {
                Button("Disconnect Spotify Account") { viewModel.disconnectSpotify() }
            } else {
                Button("Connect Spotify Account…") { viewModel.connectSpotify() }
            }
            Divider()
            Button("Minimize") { onMinimize() }
            Button("Quit") { NSApp.terminate(nil) }
                .accessibilityIdentifier(AccessibilityID.quitMenuItem)
        }
    }
}
