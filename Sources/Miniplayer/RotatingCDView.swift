import SwiftUI

struct RotatingCDView: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        SpinningDiscSkin(viewModel: viewModel) {
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
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.cdRoot)
    }
}
