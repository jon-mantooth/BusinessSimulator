import SwiftUI

struct CostBreakdownView: View {
    let costCategory: FinancialCostCategory

    @Environment(\.dismiss) private var dismiss

    private let sourceSize = CGSize(width: 853, height: 1_383)

    var body: some View {
        GeometryReader { geometry in
            let scale = min(
                geometry.size.width / sourceSize.width,
                geometry.size.height / sourceSize.height
            )
            let renderedSize = CGSize(
                width: sourceSize.width * scale,
                height: sourceSize.height * scale
            )
            let origin = CGPoint(
                x: (geometry.size.width - renderedSize.width) / 2,
                y: (geometry.size.height - renderedSize.height) / 2
            )

            ZStack {
                Color.black
                    .ignoresSafeArea()

                Image("cost_breakdown")
                    .resizable()
                    .frame(
                        width: renderedSize.width,
                        height: renderedSize.height
                    )
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )

                Text(costCategory.category.breakdownTitle)
                    .font(.system(size: 46 * scale, weight: .black))
                    .foregroundStyle(Color(red: 0.24, green: 0.12, blue: 0.07))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: renderedSize.width * 0.68)
                    .position(
                        x: origin.x + renderedSize.width * 0.48,
                        y: origin.y + renderedSize.height * 0.115
                    )

                itemizedCosts(scale: scale)
                    .frame(
                        width: renderedSize.width * 0.85,
                        height: renderedSize.height * 0.60,
                        alignment: .top
                    )
                    .position(
                        x: origin.x + renderedSize.width * 0.485,
                        y: origin.y + renderedSize.height * 0.49
                    )

                Text(
                    costCategory.total,
                    format: .currency(code: "USD")
                        .precision(.fractionLength(2))
                )
                .font(.system(size: 44 * scale, weight: .black))
                .foregroundStyle(Color(red: 0.24, green: 0.12, blue: 0.07))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(
                    width: renderedSize.width * 0.32,
                    alignment: .leading
                )
                .position(
                    x: origin.x + renderedSize.width * 0.73,
                    y: origin.y + renderedSize.height * 0.90
                )

                Button {
                    dismiss()
                } label: {
                    Rectangle()
                        .fill(Color.white.opacity(0.001))
                        .contentShape(Rectangle())
                }
                .frame(
                    width: renderedSize.width * 0.13,
                    height: renderedSize.width * 0.13
                )
                .position(
                    x: origin.x + renderedSize.width * 0.94,
                    y: origin.y + renderedSize.height * 0.045
                )
                .buttonStyle(.plain)
                .accessibilityLabel("Close cost breakdown")
            }
        }
        .presentationDetents([.fraction(0.75)])
        .presentationDragIndicator(.hidden)
    }

    private func itemizedCosts(
        scale: CGFloat
    ) -> some View {
        ScrollView {
            LazyVStack(spacing: 13 * scale) {
                ForEach(costCategory.items) { item in
                    HStack(spacing: 14 * scale) {
                        Text(item.name)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )

                        Text(
                            item.total,
                            format: .currency(code: "USD")
                                .precision(.fractionLength(2))
                        )
                        .frame(
                            width: 190 * scale,
                            alignment: .leading
                        )
                    }
                    .font(.system(size: 31 * scale, weight: .bold))
                    .foregroundStyle(
                        Color(red: 0.24, green: 0.12, blue: 0.07)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .padding(.horizontal, 18 * scale)
                    .frame(height: 69 * scale)
                }

                if costCategory.items.isEmpty {
                    Text("No costs recorded")
                        .font(.system(size: 34 * scale, weight: .bold))
                        .foregroundStyle(
                            Color(red: 0.24, green: 0.12, blue: 0.07)
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 69 * scale)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

private extension CostCategory {
    var breakdownTitle: String {
        switch self {
        case .ingredients:
            return "Ingredient Costs"
        case .equipment:
            return "Equipment Costs"
        case .labor:
            return "Labor Costs"
        case .advertising:
            return "Advertising Costs"
        case .storage:
            return "Storage Costs"
        case .transportation:
            return "Transport Costs"
        case .relocation:
            return "Relocation Costs"
        case .other:
            return "Other Costs"
        }
    }
}
