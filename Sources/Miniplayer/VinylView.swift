import SwiftUI

struct VinylView: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        SpinningDiscSkin(viewModel: viewModel) {
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
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.vinylRoot)
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
}
