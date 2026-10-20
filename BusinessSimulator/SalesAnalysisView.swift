import SwiftUI
import Charts

struct SalesAnalysisView: View {
    let salesAnalytics: SalesAnalytics
    let onClose: () -> Void

    @State private var selectedPeriod: AnalysisPeriod = .allTime
    @State private var selectedReport: SalesAnalysisReport = .salesAndCapacity

    private let sourceSize = CGSize(width: 853, height: 1_844)
    private let periodWidthRatio = 0.385
    private let periodHeightRatio = 0.065
    private let periodXRatio = 0.268
    private let periodYRatio = 0.218
    private let reportWidthRatio = 0.32
    private let reportHeightRatio = 0.065
    private let reportXRatio = 0.732
    private let reportYRatio = 0.218
    private let graphWidthRatio = 0.82
    private let graphHeightRatio = 0.34
    private let graphXRatio = 0.50
    private let graphYRatio = 0.475
    private let guideWidthRatio = 0.4464
    private let guideYRatio = 0.90
    private let speechBubbleWidthRatio = 0.62
    private let speechBubbleXRatio = 0.69
    private let speechBubbleYRatio = 0.85

    private var salesCapacityPoints: [SalesCapacityAnalysisPoint] {
        salesAnalytics.salesCapacityAnalysis(for: selectedPeriod)
    }

    private var selloutResults: [SelloutAnalysisResult] {
        salesAnalytics.selloutAnalysis(for: selectedPeriod)
    }

    private var ingredientUsage: IngredientUsageAnalysisResult {
        salesAnalytics.ingredientUsageAnalysis(for: selectedPeriod)
    }

    private var displayedDayDomain: ClosedRange<Int> {
        let firstDay = salesCapacityPoints.first?.operatingDay ?? 1
        let lastDay = salesCapacityPoints.last?.operatingDay ?? firstDay
        return firstDay...max(lastDay, firstDay + 1)
    }

    private var maximumGraphValue: Int {
        let recordedMaximum = salesCapacityPoints.reduce(0) { result, point in
            max(
                result,
                max(point.actualSales, point.potentialSalesCapacity)
            )
        }
        let highestValue = max(
            recordedMaximum,
            salesAnalytics.maximumOperationalCapacity
        )
        return max(Int((Double(highestValue) * 1.10).rounded(.up)), 1)
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
                Image("sales_analysis")
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

                periodControl(size: renderedSize)
                    .frame(
                        width: renderedSize.width * periodWidthRatio,
                        height: renderedSize.height * periodHeightRatio
                    )
                    .position(
                        x: renderedOrigin.x
                            + renderedSize.width * periodXRatio,
                        y: renderedOrigin.y
                            + renderedSize.height * periodYRatio
                    )

                reportControl(size: renderedSize)
                    .frame(
                        width: renderedSize.width * reportWidthRatio,
                        height: renderedSize.height * reportHeightRatio
                    )
                    .position(
                        x: renderedOrigin.x
                            + renderedSize.width * reportXRatio,
                        y: renderedOrigin.y
                            + renderedSize.height * reportYRatio
                    )

                reportContent
                    .frame(
                        width: renderedSize.width * graphWidthRatio,
                        height: renderedSize.height * graphHeightRatio
                    )
                    .padding(renderedSize.width * 0.018)
                    .background(
                        Color.white.opacity(0.22),
                        in: RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                        .stroke(
                            Color.black.opacity(0.48),
                            lineWidth: 1.5
                        )
                    }
                    .position(
                        x: renderedOrigin.x
                            + renderedSize.width * graphXRatio,
                        y: renderedOrigin.y
                            + renderedSize.height * graphYRatio
                    )

                Image("speech_bubble")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: renderedSize.width
                            * speechBubbleWidthRatio
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
                .accessibilityLabel("Close Sales Analysis")
            }
        }
        .clipped()
        .ignoresSafeArea()
    }

    private func periodControl(size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("View Period")
                .font(controlLabelFont(for: size))
                .foregroundStyle(.black)
                .padding(.horizontal, 5)

            HStack(spacing: 0) {
                ForEach(AnalysisPeriod.allCases) { period in
                    Button {
                        selectedPeriod = period
                    } label: {
                        Text(period.title)
                            .font(controlFont(for: size))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                selectedPeriod == period
                                    ? Color.black.opacity(0.18)
                                    : Color.clear
                            )
                            .clipShape(controlShape)
                            .overlay {
                                controlShape.stroke(
                                    Color.black.opacity(0.55),
                                    lineWidth: 1.5
                                )
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxHeight: .infinity)
            .scaleEffect(0.8, anchor: .center)
        }
    }

    private func reportControl(size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("View Report")
                .font(controlLabelFont(for: size))
                .foregroundStyle(.black)
                .padding(.horizontal, 5)

            Menu {
                ForEach(SalesAnalysisReport.allCases) { report in
                    Button {
                        selectedReport = report
                    } label: {
                        Label(report.title, systemImage: report.icon)
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: selectedReport.icon)

                    Text(selectedReport.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    Spacer(minLength: 3)
                    Image(systemName: "chevron.down")
                }
                .font(controlFont(for: size))
                .foregroundStyle(.black)
                .padding(.horizontal, 9)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(controlShape)
                .overlay {
                    controlShape.stroke(
                        Color.black.opacity(0.55),
                        lineWidth: 1.5
                    )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxHeight: .infinity)
            .scaleEffect(0.90)
            .offset(y: -4)
        }
    }

    @ViewBuilder
    private var reportContent: some View {
        switch selectedReport {
        case .salesAndCapacity:
            salesAndCapacityReport
        case .sellouts:
            selloutReport
        case .ingredientUsage:
            ingredientUsageReport
        }
    }

    @ViewBuilder
    private var salesAndCapacityReport: some View {
        if salesCapacityPoints.isEmpty {
            noDataView(
                title: "No Sales History",
                description: "Complete an operating day to begin sales analysis.",
                systemImage: "chart.xyaxis.line"
            )
        } else {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    SalesChartLegend(color: .blue, title: "Sales")
                    SalesChartLegend(color: .green, title: "Capacity")
                    SalesChartLegend(
                        color: .red,
                        title: "Maximum",
                        isDashed: true
                    )
                }
                .font(.caption.bold())
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

                Chart {
                    RuleMark(
                        y: .value(
                            "Maximum Capacity",
                            salesAnalytics.maximumOperationalCapacity
                        )
                    )
                    .foregroundStyle(Color.red)
                    .lineStyle(
                        StrokeStyle(lineWidth: 2, dash: [7, 5])
                    )
                    .annotation(position: .top, alignment: .trailing) {
                        Text(
                            "Max: \(salesAnalytics.maximumOperationalCapacity)"
                        )
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                    }

                    ForEach(salesCapacityPoints) { point in
                        LineMark(
                            x: .value("Operating Day", point.operatingDay),
                            y: .value("Actual Sales", point.actualSales),
                            series: .value("Series", "Actual Sales")
                        )
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.linear)

                        LineMark(
                            x: .value("Operating Day", point.operatingDay),
                            y: .value(
                                "Capacity",
                                point.potentialSalesCapacity
                            ),
                            series: .value("Series", "Capacity")
                        )
                        .foregroundStyle(Color.green)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.linear)

                        if salesCapacityPoints.count <= 30 {
                            PointMark(
                                x: .value(
                                    "Operating Day",
                                    point.operatingDay
                                ),
                                y: .value("Actual Sales", point.actualSales)
                            )
                            .foregroundStyle(Color.blue)
                            .symbolSize(42)

                            PointMark(
                                x: .value(
                                    "Operating Day",
                                    point.operatingDay
                                ),
                                y: .value(
                                    "Capacity",
                                    point.potentialSalesCapacity
                                )
                            )
                            .foregroundStyle(Color.green)
                            .symbolSize(42)
                        }
                    }
                }
                .chartXScale(domain: displayedDayDomain)
                .chartYScale(domain: 0...maximumGraphValue)
                .chartXAxisLabel {
                    Text("Operating Day")
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                }
                .chartYAxisLabel {
                    Text("Units")
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 7)) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.black.opacity(0.12))
                        AxisTick()
                            .foregroundStyle(Color.black.opacity(0.7))
                        AxisValueLabel {
                            if let day = value.as(Int.self) {
                                Text("\(day)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.black.opacity(0.16))
                        AxisTick()
                            .foregroundStyle(Color.black.opacity(0.7))
                        AxisValueLabel {
                            if let units = value.as(Int.self) {
                                Text("\(units)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                currentCapacityNote
            }
        }
    }

    @ViewBuilder
    private var selloutReport: some View {
        let observedDays = selloutResults.reduce(0) { $0 + $1.dayCount }

        if observedDays == 0 {
            noDataView(
                title: "No Sales History",
                description: "Complete an operating day to analyze sellouts.",
                systemImage: "chart.pie"
            )
        } else {
            let displayedResults = selloutResults.filter { $0.dayCount > 0 }

            GeometryReader { geometry in
                let diameter = min(
                    geometry.size.width * 0.64,
                    geometry.size.height * 0.58
                )

                VStack(spacing: 20) {
                    Chart(displayedResults) { result in
                        SectorMark(
                            angle: .value("Days", result.dayCount),
                            angularInset: 2
                        )
                        .cornerRadius(5)
                        .foregroundStyle(result.outcome.chartColor)
                        .annotation(position: .overlay) {
                            if let percentage = result.percentage,
                               percentage >= 0.08 {
                                Text(
                                    percentage,
                                    format: .percent.precision(
                                        .fractionLength(0)
                                    )
                                )
                                .font(.callout.bold())
                                .foregroundStyle(.white)
                            }
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(width: diameter, height: diameter)

                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 115), spacing: 18)
                        ],
                        spacing: 10
                    ) {
                        ForEach(displayedResults) { result in
                            PieChartLegend(
                                color: result.outcome.chartColor,
                                title: result.outcome.title
                            )
                        }
                    }
                    .font(.callout.bold())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private var ingredientUsageReport: some View {
        if ingredientUsage.totalCost <= 0 {
            noDataView(
                title: "No Ingredient History",
                description: "Ingredient use and expiration will appear after an operating day.",
                systemImage: "chart.pie"
            )
        } else {
            let slices = IngredientUsageSlice.results(from: ingredientUsage)

            GeometryReader { geometry in
                let diameter = min(
                    geometry.size.width * 0.64,
                    geometry.size.height * 0.64
                )

                VStack(spacing: 20) {
                    Chart(slices) { slice in
                        SectorMark(
                            angle: .value("Ingredient Value", slice.amount),
                            angularInset: 2
                        )
                        .cornerRadius(5)
                        .foregroundStyle(slice.chartColor)
                        .annotation(position: .overlay) {
                            Text(
                                slice.percentage,
                                format: .percent.precision(.fractionLength(0))
                            )
                            .font(.callout.bold())
                            .foregroundStyle(.white)
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(width: diameter, height: diameter)

                    HStack(spacing: 40) {
                        ForEach(slices) { slice in
                            PieChartLegend(
                                color: slice.chartColor,
                                title: slice.title
                            )
                        }
                    }
                    .font(.callout.bold())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var currentCapacityNote: some View {
        VStack(spacing: 2) {
            Text(currentCapacitySummary)
                .font(.caption.weight(.semibold))

            Text("*Any purchases made today not included.")
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(.black)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private var currentCapacitySummary: AttributedString {
        var capacityLabel = AttributedString("Current Capacity: ")
        capacityLabel.font = .caption.bold()

        var summary = capacityLabel
        summary += AttributedString(
            salesAnalytics.currentOperationalCapacity.map(String.init) ?? "—"
        )

        if !salesAnalytics.currentOperationalCapacityLimiters.isEmpty {
            summary += AttributedString("  •  ")

            var limiterLabel = AttributedString("Limited by: ")
            limiterLabel.font = .caption.bold()
            summary += limiterLabel
            summary += AttributedString(currentCapacityLimiterText)
        }

        return summary
    }

    private var currentCapacityLimiterText: String {
        let names = Set(
            salesAnalytics.currentOperationalCapacityLimiters.map {
                $0.type.operationalTitle
            }
        )
        return names.sorted().formatted(.list(type: .and))
    }

    private func noDataView(
        title: String,
        description: String,
        systemImage: String
    ) -> some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(description)
        )
        .foregroundStyle(.black)
    }

    private var controlShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
    }

    private func controlLabelFont(for size: CGSize) -> Font {
        .system(
            size: max(size.width * 0.026, 12),
            weight: .black,
            design: .rounded
        )
    }

    private func controlFont(for size: CGSize) -> Font {
        .system(
            size: max(size.width * 0.022, 11),
            weight: .bold,
            design: .rounded
        )
    }
}

private struct SalesChartLegend: View {
    let color: Color
    let title: String
    var isDashed = false

    var body: some View {
        HStack(spacing: 4) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 4))
                path.addLine(to: CGPoint(x: 18, y: 4))
            }
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: 3,
                    dash: isDashed ? [5, 3] : []
                )
            )
            .frame(width: 18, height: 8)

            Text(title)
                .foregroundStyle(.black)
        }
    }
}

private struct PieChartLegend: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(title)
                .foregroundStyle(.black)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.8)
        }
    }
}

private enum SalesAnalysisReport: String, CaseIterable, Identifiable {
    case salesAndCapacity
    case sellouts
    case ingredientUsage

    var id: Self { self }

    var title: String {
        switch self {
        case .salesAndCapacity:
            return "Sales & Capacity"
        case .sellouts:
            return "Sellouts"
        case .ingredientUsage:
            return "Ingredient Usage"
        }
    }

    var icon: String {
        switch self {
        case .salesAndCapacity:
            return "chart.xyaxis.line"
        case .sellouts:
            return "chart.pie"
        case .ingredientUsage:
            return "leaf.fill"
        }
    }
}

private extension SalesOutcome {
    var title: String {
        switch self {
        case .didNotSellOut:
            return "Did Not Sell Out"
        case .ingredients:
            return "Ingredients"
        case .labor:
            return "Labor"
        case .equipment:
            return "Equipment"
        case .storage:
            return "Storage"
        }
    }

    var chartColor: Color {
        switch self {
        case .didNotSellOut:
            return .green
        case .ingredients:
            return .orange
        case .labor:
            return .blue
        case .equipment:
            return .purple
        case .storage:
            return .red
        }
    }
}

private extension SalesLimitType {
    var operationalTitle: String {
        switch self {
        case .equipment:
            return "Equipment"
        case .labor:
            return "Labor"
        case .storage:
            return "Storage"
        case .ingredient:
            return "Ingredients"
        }
    }
}

private struct IngredientUsageSlice: Identifiable {
    let title: String
    let amount: Double
    let percentage: Double

    var id: String { title }

    var chartColor: Color {
        title == "Consumed" ? .green : .red
    }

    static func results(
        from analysis: IngredientUsageAnalysisResult
    ) -> [IngredientUsageSlice] {
        [
            IngredientUsageSlice(
                title: "Consumed",
                amount: analysis.consumedCost,
                percentage: analysis.consumedPercentage ?? 0
            ),
            IngredientUsageSlice(
                title: "Expired",
                amount: analysis.expiredCost,
                percentage: analysis.expiredPercentage ?? 0
            )
        ]
        .filter { $0.amount > 0 }
    }
}
