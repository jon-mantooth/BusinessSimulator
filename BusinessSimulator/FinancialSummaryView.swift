import Charts
import SwiftUI

struct FinancialSummaryView: View {
    let financialSummary: FinancialSummary
    let onClose: () -> Void

    @State private var selectedLocation: FinancialLocationFilter = .all
    @State private var selectedMode: FinancialReportMode = .summary
    @State private var selectedCostCategory: FinancialCostCategory?

    private let sourceSize = CGSize(width: 853, height: 1_844)
    private let guideWidthRatio = 0.4464
    private let guideYRatio = 0.90
    private let speechBubbleWidthRatio = 0.62
    private let speechBubbleXRatio = 0.69
    private let speechBubbleYRatio = 0.85

    private var report: FinancialReport {
        financialSummary.report(for: selectedLocation.locationID)
    }

    private var availableLocationFilters: [FinancialLocationFilter] {
        var locationIDs: [LocationID] = []

        for row in financialSummary.rows
            where !locationIDs.contains(row.locationID) {
            locationIDs.append(row.locationID)
        }

        return [.all] + locationIDs.map(FinancialLocationFilter.location)
    }

    private var expenseRows: [FinancialExpenseRow] {
        [
            FinancialExpenseRow(category: .ingredients, yRatio: 0.337),
            FinancialExpenseRow(category: .equipment, yRatio: 0.370),
            FinancialExpenseRow(category: .labor, yRatio: 0.402),
            FinancialExpenseRow(category: .advertising, yRatio: 0.434),
            FinancialExpenseRow(category: .storage, yRatio: 0.466),
            FinancialExpenseRow(category: .transportation, yRatio: 0.499),
            FinancialExpenseRow(category: .relocation, yRatio: 0.532)
        ]
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
            let renderedOrigin = CGPoint(
                x: (geometry.size.width - renderedSize.width) / 2,
                y: (geometry.size.height - renderedSize.height) / 2
            )

            ZStack {
                Image("financial_summary")
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

                if selectedMode == .revenueTrend {
                    revenueGraphBackground(
                        size: renderedSize,
                        origin: renderedOrigin
                    )

                    revenueGraph(
                        size: renderedSize,
                        origin: renderedOrigin
                    )
                } else {
                    summaryValues(
                        size: renderedSize,
                        origin: renderedOrigin
                    )
                }

                locationControl(size: renderedSize)
                    .frame(
                        width: renderedSize.width * 0.40,
                        height: renderedSize.height * 0.075
                    )
                    .position(
                        x: renderedOrigin.x + renderedSize.width * 0.275,
                        y: renderedOrigin.y + renderedSize.height * 0.205
                    )

                modeControl(size: renderedSize)
                    .frame(
                        width: renderedSize.width * 0.40,
                        height: renderedSize.height * 0.075
                    )
                    .position(
                        x: renderedOrigin.x + renderedSize.width * 0.74,
                        y: renderedOrigin.y + renderedSize.height * 0.205
                    )

                Image("speech_bubble")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: renderedSize.width * speechBubbleWidthRatio
                    )
                    .position(
                        x: renderedOrigin.x
                            + renderedSize.width * speechBubbleXRatio,
                        y: renderedOrigin.y
                            + renderedSize.height * speechBubbleYRatio
                    )
                    .allowsHitTesting(false)

                Image("guide")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: renderedSize.width * guideWidthRatio
                    )
                    .position(
                        x: renderedSize.width * guideWidthRatio / 2,
                        y: renderedOrigin.y
                            + renderedSize.height * guideYRatio
                    )
                    .allowsHitTesting(false)

                Button(action: onClose) {
                    Rectangle()
                        .fill(Color.white.opacity(0.001))
                        .contentShape(Rectangle())
                }
                .frame(
                    width: renderedSize.width * 0.13,
                    height: renderedSize.height * 0.07
                )
                .position(
                    x: renderedOrigin.x + renderedSize.width * 0.93,
                    y: renderedOrigin.y + renderedSize.height * 0.04
                )
                .buttonStyle(.plain)
                .accessibilityLabel("Close Financial Report")
            }
        }
        .clipped()
        .ignoresSafeArea()
        .sheet(item: $selectedCostCategory) { category in
            CostBreakdownView(costCategory: category)
        }
    }

    private func locationControl(
        size: CGSize
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Location")
                .font(controlTitleFont(size: size))
                .foregroundStyle(.black)
                .padding(.horizontal, 6)

            Menu {
                ForEach(availableLocationFilters) { filter in
                    Button {
                        selectedLocation = filter
                    } label: {
                        if selectedLocation == filter {
                            Label(filter.title, systemImage: "checkmark")
                        } else {
                            Text(filter.title)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")

                    Text(selectedLocation.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.down")
                }
                .font(controlFont(size: size))
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.black.opacity(0.55), lineWidth: 1.5)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxHeight: .infinity)
        }
    }

    private func modeControl(
        size: CGSize
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("View Report")
                .font(controlTitleFont(size: size))
                .foregroundStyle(.black)
                .padding(.horizontal, 6)

            HStack(spacing: 0) {
                ForEach(FinancialReportMode.allCases) { mode in
                    Button {
                        selectedMode = mode
                    } label: {
                        Text(mode.title)
                            .font(controlFont(size: size))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                            .background(
                                selectedMode == mode
                                    ? Color.black.opacity(0.18)
                                    : Color.clear
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 9,
                                    style: .continuous
                                )
                            )
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 9,
                                    style: .continuous
                                )
                                .stroke(
                                    Color.black.opacity(0.50),
                                    lineWidth: 1.25
                                )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    private func summaryValues(
        size: CGSize,
        origin: CGPoint
    ) -> some View {
        ZStack {
            reportValue(
                currency(report.revenuePerDay),
                size: size,
                origin: origin,
                xRatio: 0.405,
                yRatio: 0.338,
                widthRatio: 0.15
            )

            reportValue(
                report.totalDays.formatted(),
                size: size,
                origin: origin,
                xRatio: 0.405,
                yRatio: 0.370,
                widthRatio: 0.15
            )

            reportValue(
                currency(report.totalRevenue),
                size: size,
                origin: origin,
                xRatio: 0.273,
                yRatio: 0.460,
                widthRatio: 0.36,
                weight: .black
            )

            ForEach(expenseRows) { expenseRow in
                let category = report.costs(for: expenseRow.category)

                Button {
                    selectedCostCategory = category
                } label: {
                    HStack {
                        Spacer()

                        Text(currency(category.total))
                            .font(valueFont(size: size, weight: .bold))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                            .frame(
                                width: size.width * 0.15,
                                alignment: .center
                            )

                        Spacer()
                            .frame(width: size.width * 0.035)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(
                    width: size.width * 0.43,
                    height: size.height * 0.030
                )
                .position(
                    x: origin.x + size.width * 0.74,
                    y: origin.y + size.height * expenseRow.yRatio
                )
                .accessibilityLabel(
                    "\(expenseRow.category.breakdownAccessibilityName), \(currency(category.total))"
                )
                .accessibilityHint("Shows the itemized cost breakdown")
            }

            reportValue(
                currency(report.totalCosts),
                size: size,
                origin: origin,
                xRatio: 0.823,
                yRatio: 0.576,
                widthRatio: 0.22,
                weight: .black
            )

            reportValue(
                currency(report.netProfit),
                size: size,
                origin: origin,
                xRatio: 0.765,
                yRatio: 0.652,
                widthRatio: 0.29,
                weight: .black
            )

            reportValue(
                optionalCurrency(report.startingBalance),
                size: size,
                origin: origin,
                xRatio: 0.806,
                yRatio: 0.696,
                widthRatio: 0.20
            )

            reportValue(
                currency(report.netProfit),
                size: size,
                origin: origin,
                xRatio: 0.806,
                yRatio: 0.722,
                widthRatio: 0.20
            )

            reportValue(
                optionalCurrency(report.endingBalance),
                size: size,
                origin: origin,
                xRatio: 0.775,
                yRatio: 0.768,
                widthRatio: 0.28,
                weight: .black
            )
        }
    }

    private func revenueGraphBackground(
        size: CGSize,
        origin: CGPoint
    ) -> some View {
        Image("graph_background")
            .resizable()
            .scaledToFit()
            .frame(width: size.width * 0.96)
            .position(
                x: origin.x + size.width * 0.50,
                y: origin.y + size.height * 0.555
            )
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private func revenueGraph(
        size: CGSize,
        origin: CGPoint
    ) -> some View {
        Group {
            if report.revenueByDay.isEmpty {
                ContentUnavailableView(
                    "No Financial History",
                    systemImage: "chart.xyaxis.line",
                    description: Text(
                        "Complete a day to begin financial reporting."
                    )
                )
                .foregroundStyle(.black)
            } else {
                VStack(spacing: size.height * 0.012) {
                    VStack(spacing: 2) {
                        Text("Daily Revenue")
                            .font(
                                .system(
                                    size: max(size.width * 0.036, 17),
                                    weight: .black,
                                    design: .rounded
                                )
                            )

                        Text(reportPeriodTitle)
                            .font(
                                .system(
                                    size: max(size.width * 0.020, 10),
                                    weight: .semibold,
                                    design: .rounded
                                )
                            )
                    }
                    .foregroundStyle(.black)

                    Chart(report.revenueByDay) { point in
                        LineMark(
                            x: .value("Day", point.day),
                            y: .value("Revenue", point.revenue)
                        )
                        .foregroundStyle(Color.green)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        PointMark(
                            x: .value("Day", point.day),
                            y: .value("Revenue", point.revenue)
                        )
                        .foregroundStyle(Color.blue)
                        .symbolSize(42)
                    }
                    .chartXScale(domain: revenueDayDomain)
                    .chartYScale(domain: 0...maximumRevenueGraphValue)
                    .chartXAxisLabel("Simulation Day")
                    .chartYAxisLabel("Revenue")
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 6)) {
                            AxisGridLine()
                                .foregroundStyle(Color.black.opacity(0.14))
                            AxisTick()
                                .foregroundStyle(Color.black.opacity(0.65))
                            AxisValueLabel()
                                .foregroundStyle(.black)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { value in
                            AxisGridLine()
                                .foregroundStyle(Color.black.opacity(0.14))
                            AxisTick()
                                .foregroundStyle(Color.black.opacity(0.65))
                            AxisValueLabel {
                                if let amount = value.as(Double.self) {
                                    Text(currency(amount))
                                }
                            }
                            .foregroundStyle(.black)
                        }
                    }
                }
            }
        }
        .frame(
            width: size.width * 0.78,
            height: size.height * 0.43
        )
        .position(
            x: origin.x + size.width * 0.50,
            y: origin.y + size.height * 0.545
        )
    }

    private func reportValue(
        _ text: String,
        size: CGSize,
        origin: CGPoint,
        xRatio: Double,
        yRatio: Double,
        widthRatio: Double,
        weight: Font.Weight = .bold
    ) -> some View {
        Text(text)
            .font(valueFont(size: size, weight: weight))
            .foregroundStyle(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.50)
            .frame(width: size.width * widthRatio)
            .position(
                x: origin.x + size.width * xRatio,
                y: origin.y + size.height * yRatio
            )
    }

    private func controlTitleFont(
        size: CGSize
    ) -> Font {
        .system(
            size: max(size.width * 0.026, 12),
            weight: .black,
            design: .rounded
        )
    }

    private func controlFont(
        size: CGSize
    ) -> Font {
        .system(
            size: max(size.width * 0.021, 10),
            weight: .bold,
            design: .rounded
        )
    }

    private func valueFont(
        size: CGSize,
        weight: Font.Weight
    ) -> Font {
        .system(
            size: max(size.width * 0.023, 11),
            weight: weight,
            design: .rounded
        )
    }

    private func currency(
        _ value: Double
    ) -> String {
        value.formatted(
            .currency(code: "USD")
                .precision(.fractionLength(2))
        )
    }

    private func optionalCurrency(
        _ value: Double?
    ) -> String {
        value.map(currency) ?? "—"
    }

    private var reportPeriodTitle: String {
        guard
            let firstDay = report.revenueByDay.first?.day,
            let lastDay = report.revenueByDay.last?.day
        else {
            return "No days recorded"
        }

        return firstDay == lastDay
            ? "Day \(firstDay)"
            : "Days \(firstDay)–\(lastDay)"
    }

    private var revenueDayDomain: ClosedRange<Int> {
        let firstDay = report.revenueByDay.first?.day ?? 1
        let lastDay = report.revenueByDay.last?.day ?? firstDay
        return firstDay...max(firstDay + 1, lastDay)
    }

    private var maximumRevenueGraphValue: Double {
        let maximumRevenue = report.revenueByDay
            .map(\.revenue)
            .max() ?? 0
        return max(maximumRevenue * 1.10, 1)
    }
}

private enum FinancialReportMode: String, CaseIterable, Identifiable {
    case summary
    case revenueTrend

    var id: Self { self }

    var title: String {
        switch self {
        case .summary:
            return "Summary"
        case .revenueTrend:
            return "Revenue"
        }
    }
}

private enum FinancialLocationFilter: Hashable, Identifiable {
    case all
    case location(LocationID)

    var id: String {
        switch self {
        case .all:
            return "all-locations"
        case let .location(locationID):
            return locationID.rawValue
        }
    }

    var locationID: LocationID? {
        switch self {
        case .all:
            return nil
        case let .location(locationID):
            return locationID
        }
    }

    @MainActor
    var title: String {
        guard let locationID else { return "All Locations" }
        return FinanceLocationNames.name(for: locationID)
    }
}

private struct FinancialExpenseRow: Identifiable {
    var id: CostCategory { category }

    let category: CostCategory
    let yRatio: Double
}

private extension CostCategory {
    var breakdownAccessibilityName: String {
        switch self {
        case .ingredients:
            return "Ingredients"
        case .equipment:
            return "Equipment"
        case .labor:
            return "Labor"
        case .advertising:
            return "Advertising"
        case .storage:
            return "Storage"
        case .transportation:
            return "Transport"
        case .relocation:
            return "Locations"
        case .other:
            return "Other"
        }
    }
}
