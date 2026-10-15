import SwiftUI

struct FinanceView: View {
    let summaries: [DaySummary]

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
        }
        .clipped()
    }
}
