import SwiftUI

struct MarketingView: View {
    let productID: ProductID

    private let sourceSize = CGSize(width: 1024, height: 1536)

    private var flyerImageName: String {
        switch productID {
        case .hotDogs:
            return "hot_dog_flyer"
        case .smoothies:
            return "smoothie_flyer"
        case .pies:
            return "pie_flyer"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = max(
                geometry.size.width / sourceSize.width,
                geometry.size.height / sourceSize.height
            )
            let renderedSize = CGSize(
                width: sourceSize.width * scale,
                height: sourceSize.height * scale
            )

            ZStack(alignment: .topLeading) {
                Image("marketing_background")
                    .resizable()
                    .frame(
                        width: renderedSize.width,
                        height: renderedSize.height
                    )

                Image(flyerImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 192 * scale)
                    .position(
                        x: 390 * scale,
                        y: 475 * scale
                    )

                marketingButton(
                    title: "Advertisement",
                    systemImage: "megaphone.fill",
                    scale: scale
                )
                .position(
                    x: 380 * scale,
                    y: 690 * scale
                )

                marketingButton(
                    title: "Business Reputation",
                    systemImage: "star.fill",
                    scale: scale
                )
                .position(
                    x: 700 * scale,
                    y: 1_145 * scale
                )
            }
            .frame(
                width: renderedSize.width,
                height: renderedSize.height
            )
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
        }
        .clipped()
    }

    private func marketingButton(
        title: String,
        systemImage: String,
        scale: CGFloat
    ) -> some View {
        Button {
            // Navigation will be connected when each marketing screen is built.
        } label: {
            Label(title, systemImage: systemImage)
                .font(.system(size: 32 * scale, weight: .bold))
                .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.07))
                .frame(
                    width: 320 * scale,
                    height: 78 * scale
                )
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.98, blue: 0.88),
                            Color(red: 1.0, green: 0.84, blue: 0.46)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 20 * scale)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20 * scale)
                        .stroke(
                            Color(red: 0.95, green: 0.63, blue: 0.13),
                            lineWidth: 3 * scale
                        )
                }
                .shadow(
                    color: Color.orange.opacity(0.45),
                    radius: 10 * scale
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
