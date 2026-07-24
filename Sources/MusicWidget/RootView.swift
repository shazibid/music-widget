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
            }
        }
        .contextMenu {
            ForEach(WidgetSkin.allCases) { option in
                Button {
                    skinStore.skin = option
                } label: {
                    if option == skinStore.skin {
                        Label(option.displayName, systemImage: "checkmark")
                    } else {
                        Text(option.displayName)
                    }
                }
            }
            Divider()
            Button("Quit") { NSApp.terminate(nil) }
        }
    }
}
