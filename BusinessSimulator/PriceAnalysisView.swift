import SwiftUI
import Charts

struct PriceAnalysisView: View {
    let priceAnalytics: PriceAnalytics
    let onClose: () -> Void

    @State private var selectedPeriod: PriceAnalysisPeriod = .allTime
    @State private var selectedAnalysis: PriceAnalysisGrouping = .overall

    private let sourceSize = CGSize(width: 853, height: 1_844)
    private let periodWidthRatio = 0.47
    private let periodHeightRatio = 0.065
    private let periodXRatio = 0.295
    private let periodYRatio = 0.21
    private let analysisWidthRatio = 0.36
    private let analysisHeightRatio = 0.065
    private let analysisXRatio = 0.76
    private let analysisYRatio = 0.21
    private let graphWidthRatio = 0.72
    private let graphHeightRatio = 0.31
    private let graphXRatio = 0.58
    private let graphYRatio = 0.465
    private let guideWidthRatio = 0.4464
    private let guideYRatio = 0.90
    private let speechBubbleWidthRatio = 0.62
    private let speechBubbleXRatio = 0.69
    private let speechBubbleYRatio = 0.85

    private var displayedRows: [PriceAnalyticsRow] {
        selectedPeriod.rows(from: priceAnalytics.rows)
    }

    private var displayedWeatherAnalysis: [WeatherPriceAnalysisResult] {
        priceAnalytics.weatherAnalysis(for: selectedPeriod)
    }

    private var displayedBusinessReputationAnalysis:
        [BusinessReputationPriceAnalysisResult] {
        priceAnalytics.businessReputationAnalysis(
            for: selectedPeriod
        )
    }

    private var displayedCategoricalAnalysis: [PriceAnalysisBarData] {
        switch selectedAnalysis {
        case .equipment:
            return priceAnalytics.equipmentLevelAnalysis(
                for: selectedPeriod
            ).compactMap(PriceAnalysisBarData.init)
        case .advertisement:
            return priceAnalytics.advertisementLevelAnalysis(
                for: selectedPeriod
            ).compactMap(PriceAnalysisBarData.init)
        case .location:
            return priceAnalytics.locationAnalysis(
                for: selectedPeriod
            ).map(PriceAnalysisBarData.init)
        default:
            return []
        }
    }

    private var displayedDayDomain: ClosedRange<Int> {
        let firstDay = displayedRows.first?.operatingDay ?? 1
        let lastDay = displayedRows.last?.operatingDay ?? firstDay

        return firstDay...max(lastDay, firstDay + 1)
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
                Image("price_analysis")
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

                VStack(alignment: .leading, spacing: 4) {
                    Text("View Period")
                        .font(
                            .system(
                                size: max(renderedSize.width * 0.026, 12),
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.black)
                        .padding(.horizontal, 5)

                    HStack(spacing: 0) {
                        ForEach(PriceAnalysisPeriod.allCases) { period in
                            Button {
                                selectedPeriod = period
                            } label: {
                                Text(period.title)
                                    .font(
                                        .system(
                                            size: max(
                                                renderedSize.width * 0.022,
                                                11
                                            ),
                                            weight: .bold,
                                            design: .rounded
                                        )
                                    )
                                    .foregroundStyle(.black)
                                    .frame(
                                        maxWidth: .infinity,
                                        maxHeight: .infinity
                                    )
                                    .background(
                                        selectedPeriod == period
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

                VStack(alignment: .leading, spacing: 4) {
                    Text("Analyze By")
                        .font(
                            .system(
                                size: max(renderedSize.width * 0.026, 12),
                                weight: .black,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.black)
                        .padding(.horizontal, 5)

                    Menu {
                        ForEach(PriceAnalysisGrouping.allCases) { grouping in
                            Button {
                                selectedAnalysis = grouping
                            } label: {
                                Label(grouping.title, systemImage: grouping.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: selectedAnalysis.icon)

                            Text(selectedAnalysis.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)

                            Spacer(minLength: 4)

                            Image(systemName: "chevron.down")
                        }
                        .font(
                            .system(
                                size: max(renderedSize.width * 0.022, 11),
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                Color.black.opacity(0.55),
                                lineWidth: 1.5
                            )
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(maxHeight: .infinity)
                }
                .frame(
                    width: renderedSize.width * analysisWidthRatio,
                    height: renderedSize.height * analysisHeightRatio
                )
                .position(
                    x: renderedOrigin.x
                        + renderedSize.width * analysisXRatio,
                    y: renderedOrigin.y
                        + renderedSize.height * analysisYRatio
                )

                Group {
                    if displayedRows.isEmpty {
                        ContentUnavailableView(
                            "No Price History",
                            systemImage: "chart.xyaxis.line",
                            description: Text(
                                "Complete an operating day to begin price analysis."
                            )
                        )
                        .foregroundStyle(.black)
                    } else if selectedAnalysis == .weather {
                        Chart {
                            RuleMark(y: .value("Perfect Price", 0.0))
                                .foregroundStyle(Color.red)
                                .lineStyle(
                                    StrokeStyle(
                                        lineWidth: 2,
                                        dash: [7, 5]
                                    )
                                )

                            ForEach(displayedWeatherAnalysis) { result in
                                if let averagePriceRatio =
                                    result.averagePriceRatio {
                                    BarMark(
                                        x: .value(
                                            "Weather",
                                            result.axisLabel
                                        ),
                                        y: .value(
                                            "Average Price Deviation",
                                            averagePriceRatio
                                        )
                                    )
                                    .foregroundStyle(Color.blue)
                                    .annotation(position: .overlay) {
                                        Text(
                                            averagePriceRatio,
                                            format: .percent.precision(
                                                .fractionLength(0)
                                            )
                                        )
                                        .font(.caption.bold())
                                        .foregroundStyle(.black)
                                    }
                                } else {
                                    BarMark(
                                        x: .value(
                                            "Weather",
                                            result.axisLabel
                                        ),
                                        y: .value("No Data", 0.0001)
                                    )
                                    .foregroundStyle(
                                        Color.black.opacity(0.001)
                                    )
                                    .annotation(position: .top) {
                                        Text("No Data\nAvailable")
                                            .font(.caption.bold())
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(
                                                Color.black.opacity(0.7)
                                            )
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding(.horizontal, 4)
                                            .background(
                                                Color.white.opacity(0.65),
                                                in: RoundedRectangle(
                                                    cornerRadius: 4
                                                )
                                            )
                                    }
                                }
                            }
                        }
                        .chartYScale(domain: -1.0...1.0)
                        .chartYAxis {
                            AxisMarks(
                                position: .leading,
                                values: [-1.0, -0.5, 0.0, 0.5, 1.0]
                            ) { value in
                                AxisGridLine()
                                    .foregroundStyle(Color.black.opacity(0.16))
                                AxisTick()
                                    .foregroundStyle(Color.black.opacity(0.7))
                                AxisValueLabel {
                                    if let deviation = value.as(Double.self) {
                                        Text(
                                            deviation,
                                            format: .percent.precision(
                                                .fractionLength(0)
                                            )
                                        )
                                        .foregroundStyle(.black)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let label = value.as(String.self) {
                                        Text(label)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(.black)
                                    }
                                }
                            }
                        }
                    } else if selectedAnalysis == .businessReputation {
                        Chart {
                            RuleMark(y: .value("Perfect Price", 0.0))
                                .foregroundStyle(Color.red)
                                .lineStyle(
                                    StrokeStyle(
                                        lineWidth: 2,
                                        dash: [7, 5]
                                    )
                                )

                            ForEach(
                                displayedBusinessReputationAnalysis
                            ) { result in
                                if let averagePriceRatio =
                                    result.averagePriceRatio {
                                    BarMark(
                                        x: .value(
                                            "Business Reputation",
                                            result.axisLabel
                                        ),
                                        y: .value(
                                            "Average Price Deviation",
                                            averagePriceRatio
                                        )
                                    )
                                    .foregroundStyle(Color.blue)
                                    .annotation(position: .overlay) {
                                        Text(
                                            averagePriceRatio,
                                            format: .percent.precision(
                                                .fractionLength(0)
                                            )
                                        )
                                        .font(.caption.bold())
                                        .foregroundStyle(.black)
                                    }
                                } else {
                                    BarMark(
                                        x: .value(
                                            "Business Reputation",
                                            result.axisLabel
                                        ),
                                        y: .value("No Data", 0.0001)
                                    )
                                    .foregroundStyle(
                                        Color.black.opacity(0.001)
                                    )
                                    .annotation(position: .top) {
                                        Text("No Data\nAvailable")
                                            .font(.caption.bold())
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(
                                                Color.black.opacity(0.7)
                                            )
                                            .fixedSize(
                                                horizontal: false,
                                                vertical: true
                                            )
                                            .padding(.horizontal, 4)
                                            .background(
                                                Color.white.opacity(0.65),
                                                in: RoundedRectangle(
                                                    cornerRadius: 4
                                                )
                                            )
                                    }
                                }
                            }
                        }
                        .chartYScale(domain: -1.0...1.0)
                        .chartYAxis {
                            AxisMarks(
                                position: .leading,
                                values: [-1.0, -0.5, 0.0, 0.5, 1.0]
                            ) { value in
                                AxisGridLine()
                                    .foregroundStyle(Color.black.opacity(0.16))
                                AxisTick()
                                    .foregroundStyle(Color.black.opacity(0.7))
                                AxisValueLabel {
                                    if let deviation = value.as(Double.self) {
                                        Text(
                                            deviation,
                                            format: .percent.precision(
                                                .fractionLength(0)
                                            )
                                        )
                                        .foregroundStyle(.black)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let label = value.as(String.self) {
                                        Text(label)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(.black)
                                    }
                                }
                            }
                        }
                    } else if selectedAnalysis == .equipment
                                || selectedAnalysis == .advertisement
                                || selectedAnalysis == .location {
                        Chart {
                            RuleMark(y: .value("Perfect Price", 0.0))
                                .foregroundStyle(Color.red)
                                .lineStyle(
                                    StrokeStyle(
                                        lineWidth: 2,
                                        dash: [7, 5]
                                    )
                                )

                            ForEach(displayedCategoricalAnalysis) { result in
                                BarMark(
                                    x: .value(
                                        "Category",
                                        result.axisLabel
                                    ),
                                    y: .value(
                                        "Average Price Deviation",
                                        result.averagePriceRatio
                                    )
                                )
                                .foregroundStyle(Color.blue)
                                .annotation(position: .overlay) {
                                    Text(
                                        result.averagePriceRatio,
                                        format: .percent.precision(
                                            .fractionLength(0)
                                        )
                                    )
                                    .font(.caption.bold())
                                    .foregroundStyle(.black)
                                }
                            }
                        }
                        .chartYScale(domain: -1.0...1.0)
                        .chartYAxis {
                            AxisMarks(
                                position: .leading,
                                values: [-1.0, -0.5, 0.0, 0.5, 1.0]
                            ) { value in
                                AxisGridLine()
                                    .foregroundStyle(Color.black.opacity(0.16))
                                AxisTick()
                                    .foregroundStyle(Color.black.opacity(0.7))
                                AxisValueLabel {
                                    if let deviation = value.as(Double.self) {
                                        Text(
                                            deviation,
                                            format: .percent.precision(
                                                .fractionLength(0)
                                            )
                                        )
                                        .foregroundStyle(.black)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(
                                values: displayedCategoricalAnalysis.map(
                                    \.axisLabel
                                )
                            ) { value in
                                AxisValueLabel {
                                    if let label = value.as(String.self) {
                                        Text(label)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(.black)
                                    }
                                }
                            }
                        }
                    } else {
                        Chart {
                            RuleMark(y: .value("Perfect Price", 0.0))
                                .foregroundStyle(Color.red)
                                .lineStyle(
                                    StrokeStyle(
                                        lineWidth: 2,
                                        dash: [7, 5]
                                    )
                                )

                            ForEach(displayedRows, id: \.operatingDay) { row in
                                AreaMark(
                                    x: .value(
                                        "Operating Day",
                                        row.operatingDay
                                    ),
                                    yStart: .value("Lower Bound", -1.0),
                                    yEnd: .value(
                                        "Price Deviation",
                                        row.priceDeviation
                                    )
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.22),
                                            Color.green.opacity(0.10)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.linear)

                                LineMark(
                                    x: .value(
                                        "Operating Day",
                                        row.operatingDay
                                    ),
                                    y: .value(
                                        "Price Deviation",
                                        row.priceDeviation
                                    )
                                )
                                .foregroundStyle(Color.blue)
                                .lineStyle(StrokeStyle(lineWidth: 3))
                                .interpolationMethod(.linear)

                                if displayedRows.count <= 30 {
                                    PointMark(
                                        x: .value(
                                            "Operating Day",
                                            row.operatingDay
                                        ),
                                        y: .value(
                                            "Price Deviation",
                                            row.priceDeviation
                                        )
                                    )
                                    .foregroundStyle(Color.blue)
                                    .symbolSize(55)
                                }
                            }
                        }
                        .chartYScale(domain: -1.0...1.0)
                        .chartXScale(domain: displayedDayDomain)
                        .chartYAxis {
                            AxisMarks(
                                position: .leading,
                                values: [-1.0, -0.5, 0.0, 0.5, 1.0]
                            ) { value in
                                AxisGridLine()
                                    .foregroundStyle(Color.black.opacity(0.16))
                                AxisTick()
                                    .foregroundStyle(Color.black.opacity(0.7))
                                AxisValueLabel {
                                    if let deviation = value.as(Double.self) {
                                        Text(
                                            deviation,
                                            format: .number.precision(
                                                .fractionLength(1)
                                            )
                                        )
                                        .foregroundStyle(.black)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 8)) {
                                AxisGridLine()
                                    .foregroundStyle(Color.black.opacity(0.12))
                                AxisTick()
                                    .foregroundStyle(Color.black.opacity(0.7))
                                AxisValueLabel()
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                }
                .frame(
                    width: renderedSize.width * graphWidthRatio,
                    height: renderedSize.height * graphHeightRatio
                )
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
                .accessibilityLabel("Close Price Analysis")
            }
        }
        .clipped()
        .ignoresSafeArea()
    }
}

private extension PriceAnalysisPeriod {
    var title: String {
        switch self {
        case .tenDays:
            return "10 Days"
        case .thirtyDays:
            return "30 Days"
        case .allTime:
            return "All Time"
        }
    }
}

private extension WeatherAnalysisGroup {
    var title: String {
        switch self {
        case .fairOrWorse:
            return "Fair or Worse"
        case .good:
            return "Good"
        case .great:
            return "Great"
        }
    }
}

private extension WeatherPriceAnalysisResult {
    var axisLabel: String {
        let dayLabel = observationCount == 1 ? "Day" : "Days"
        return "\(group.title)\n\(observationCount) \(dayLabel)"
    }
}

private extension BusinessReputationAnalysisGroup {
    var title: String {
        switch self {
        case .great:
            return "Great"
        case .good:
            return "Good"
        case .fairOrBelow:
            return "Fair or Below"
        }
    }
}

private extension BusinessReputationPriceAnalysisResult {
    var axisLabel: String {
        let dayLabel = observationCount == 1 ? "Day" : "Days"
        return "\(group.title)\n\(observationCount) \(dayLabel)"
    }
}

private struct PriceAnalysisBarData: Identifiable {
    let id: String
    let axisLabel: String
    let averagePriceRatio: Double

    nonisolated init?(_ result: LevelPriceAnalysisResult) {
        guard let averagePriceRatio = result.averagePriceRatio else {
            return nil
        }

        let dayLabel = result.observationCount == 1 ? "Day" : "Days"
        id = "level-\(result.level)"
        axisLabel = "Level \(result.level)\n\(result.observationCount) \(dayLabel)"
        self.averagePriceRatio = averagePriceRatio
    }

    nonisolated init(_ result: LocationPriceAnalysisResult) {
        let dayLabel = result.observationCount == 1 ? "Day" : "Days"
        id = "location-\(result.locationID.rawValue)"
        axisLabel = "\(result.locationName)\n\(result.observationCount) \(dayLabel)"
        averagePriceRatio = result.averagePriceRatio
    }
}

private enum PriceAnalysisGrouping: String, CaseIterable, Identifiable {
    case overall
    case weather
    case businessReputation
    case equipment
    case advertisement
    case location

    var id: Self { self }

    var title: String {
        switch self {
        case .overall:
            return "Overall"
        case .weather:
            return "Weather"
        case .businessReputation:
            return "Business Reputation"
        case .equipment:
            return "Equipment"
        case .advertisement:
            return "Advertisement"
        case .location:
            return "Location"
        }
    }

    var icon: String {
        switch self {
        case .overall:
            return "chart.line.uptrend.xyaxis"
        case .weather:
            return "cloud.sun.fill"
        case .businessReputation:
            return "star.fill"
        case .equipment:
            return "oven.fill"
        case .advertisement:
            return "megaphone.fill"
        case .location:
            return "mappin.and.ellipse"
        }
    }
}
