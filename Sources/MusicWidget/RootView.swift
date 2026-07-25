import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @ObservedObject var skinStore: SkinStore

    var body: some View {
        Group {
            switch skinStore.skin {
            case .pill: PillView(viewModel: viewModel)
            case .cd: RotatingCDView(viewModel: viewModel)
            case .ipod: IPodView(viewModel: viewModel)
            case .vinyl: VinylView(viewModel: viewModel)
            }
        }
        .transition(.scale(scale: 0.9).combined(with: .opacity))
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
            }
            Divider()
            if viewModel.isSpotifyConnected {
                Button("Disconnect Spotify Account") { viewModel.disconnectSpotify() }
            } else {
                Button("Connect Spotify Account…") { viewModel.connectSpotify() }
            }
            Divider()
            Button("Quit") { NSApp.terminate(nil) }
        }
    }
}
