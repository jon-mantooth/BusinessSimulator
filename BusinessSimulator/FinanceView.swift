import SwiftUI

struct FinanceView: View {
    let priceAnalytics: PriceAnalytics

    @State private var showingPriceAnalysis = false

    private let sourceSize = CGSize(width: 853, height: 1_844)

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

            let renderedOrigin = CGPoint(
                x: (geometry.size.width - renderedSize.width) / 2,
                y: (geometry.size.height - renderedSize.height) / 2
            )

            ZStack {
                Image("finance_background")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: renderedSize.width,
                        height: renderedSize.height
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )

                Button {
                    showingPriceAnalysis = true
                } label: {
                    Rectangle()
                        .fill(Color.white.opacity(0.001))
                        .contentShape(Rectangle())
                }
                .frame(
                    width: renderedSize.width * 0.39,
                    height: renderedSize.height * 0.08
                )
                .position(
                    x: renderedOrigin.x + renderedSize.width * 0.30,
                    y: renderedOrigin.y + renderedSize.height * 0.27
                )
                .buttonStyle(.plain)
                .accessibilityLabel("Price Analysis")
                .zIndex(1)
            }
        }
        .clipped()
        .fullScreenCover(isPresented: $showingPriceAnalysis) {
            PriceAnalysisView(
                priceAnalytics: priceAnalytics,
                onClose: {
                    showingPriceAnalysis = false
                }
            )
        }
    }
}
