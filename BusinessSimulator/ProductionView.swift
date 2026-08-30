import SwiftUI

struct ProductionView: View {
    private let sourceSize = CGSize(width: 851, height: 1_849)
    private let darkBrown = Color(red: 0.20, green: 0.12, blue: 0.06)
    private let warmGold = Color(red: 0.91, green: 0.65, blue: 0.25)
    private let paleGold = Color(red: 1.00, green: 0.91, blue: 0.60)

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
                Image("production_background")
                    .resizable()
                    .frame(
                        width: renderedSize.width,
                        height: renderedSize.height
                    )

                productionButton(
                    title: "Equipment",
                    systemImage: "gearshape.fill",
                    scale: scale
                )
                .position(
                    x: 650 * scale,
                    y: 550 * scale
                )

                productionButton(
                    title: "Labor",
                    systemImage: "person.2.fill",
                    scale: scale
                )
                .position(
                    x: 555 * scale,
                    y: 790 * scale
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

    private func productionButton(
        title: String,
        systemImage: String,
        scale: CGFloat
    ) -> some View {
        Button {
            // The corresponding upgrade view will be connected later.
        } label: {
            Label(title, systemImage: systemImage)
                .font(
                    .system(
                        size: max(26 * scale, 13),
                        weight: .black,
                        design: .rounded
                    )
                )
                .textCase(.uppercase)
                .foregroundStyle(darkBrown)
                .frame(
                    width: 250 * scale,
                    height: max(68 * scale, 38)
                )
                .background(
                    LinearGradient(
                        colors: [paleGold, warmGold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: max(12 * scale, 7))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: max(12 * scale, 7))
                        .stroke(darkBrown.opacity(0.55), lineWidth: 1.5)
                }
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
