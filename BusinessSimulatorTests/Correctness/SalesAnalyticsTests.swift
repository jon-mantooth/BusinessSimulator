import Foundation
import Testing
@testable import BusinessSimulator

struct SalesAnalyticsTests {}

// MARK: - Dataset Construction

extension SalesAnalyticsTests {

    @Test
    func historicalInitializationSortsOperatingSummariesAndSkipsRelocations() {
        let analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: [
                makeSalesSummary(day: 8, sales: 80),
                makeSalesSummary(day: 3, type: .relocation),
                makeSalesSummary(day: 2, sales: 20),
                makeSalesSummary(day: 5, sales: 50)
            ]
        )

        #expect(analytics.rows.map(\.simulationDay) == [2, 5, 8])
        #expect(analytics.rows.map(\.operatingDay) == [1, 2, 3])
        #expect(analytics.rows.map(\.actualSales) == [20, 50, 80])
    }

    @Test
    func appendingOperatingSummaryAddsExactlyOneRowAtEnd() {
        var analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: [makeSalesSummary(day: 1)]
        )

        analytics.append(from: makeSalesSummary(day: 4, sales: 75))

        #expect(analytics.rows.count == 2)
        #expect(analytics.rows.last?.simulationDay == 4)
        #expect(analytics.rows.last?.operatingDay == 2)
        #expect(analytics.rows.last?.actualSales == 75)
    }

    @Test
    func appendingRelocationSummaryAddsNoRow() {
        var analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: [makeSalesSummary(day: 1)]
        )

        analytics.append(from: makeSalesSummary(day: 2, type: .relocation))

        #expect(analytics.rows.count == 1)
        #expect(analytics.rows.first?.simulationDay == 1)
    }

    @Test
    func rowRetainsSalesCapacitySelloutLimitersAndIngredientCosts() throws {
        let summary = makeSalesSummary(
            day: 7,
            demandedSales: 150,
            sales: 60,
            limits: [
                SalesLimit(type: .equipment, units: 90),
                SalesLimit(type: .labor, units: 90),
                SalesLimit(
                    type: .ingredient(type: .apple, name: "Apples"),
                    units: 60
                )
            ],
            consumedIngredientCost: 32.50,
            expiredIngredientCost: 7.25
        )
        let analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: [summary]
        )
        let row = try #require(analytics.rows.first)

        #expect(row.simulationDay == 7)
        #expect(row.actualSales == 60)
        #expect(row.operationalCapacity == 90)
        #expect(row.operationalCapacityLimiters.count == 2)
        #expect(row.didSellOut)
        #expect(row.selloutCause == .ingredients)
        #expect(row.consumedIngredientCost == 32.50)
        #expect(row.expiredIngredientCost == 7.25)
    }

    @Test
    func rebuildingAndAppendingProduceEquivalentRowsAndGraphs() {
        let summaries = [
            makeSalesSummary(day: 1, sales: 30),
            makeSalesSummary(day: 2, type: .relocation),
            makeSalesSummary(day: 5, sales: 50),
            makeSalesSummary(day: 9, sales: 70)
        ]
        let rebuilt = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: summaries
        )
        var appended = SalesAnalytics(product: salesAnalyticsProduct)
        for summary in summaries {
            appended.append(from: summary)
        }

        #expect(rowSignatures(rebuilt.rows) == rowSignatures(appended.rows))
        #expect(
            trendSignatures(rebuilt.salesCapacityAnalysis(for: .allTime))
                == trendSignatures(
                    appended.salesCapacityAnalysis(for: .allTime)
                )
        )
    }

    @Test
    func currentCapacityUsesLatestOperatingRowAndEveryTiedLimiter() {
        let analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: [
                makeSalesSummary(day: 1, capacity: 90),
                makeSalesSummary(day: 2, type: .relocation),
                makeSalesSummary(
                    day: 5,
                    demandedSales: 200,
                    sales: 30,
                    limits: [
                        SalesLimit(type: .equipment, units: 120),
                        SalesLimit(type: .labor, units: 120),
                        SalesLimit(
                            type: .ingredient(
                                type: .apple,
                                name: "Apples"
                            ),
                            units: 30
                        )
                    ]
                )
            ]
        )

        #expect(analytics.currentOperationalCapacity == 120)
        #expect(analytics.currentOperationalCapacityLimiters.count == 2)
        #expect(
            analytics.currentOperationalCapacityLimiters.allSatisfy {
                $0.type.isOperationalCapacity && $0.units == 120
            }
        )
    }

    @Test
    func maximumCapacityUsesCentralizedTierFiveSchedule() {
        let expectedCapacity = ProductionCapacityBalance.schedule.capacity(
            for: .tier(.tierFive),
            product: salesAnalyticsProduct
        )
        let analytics = SalesAnalytics(product: salesAnalyticsProduct)

        #expect(analytics.maximumOperationalCapacity == expectedCapacity)
    }
}

// MARK: - Sales and Capacity Trend

extension SalesAnalyticsTests {

    @Test
    func trendReturnsSelectedRowsInChronologicalOperatingDayOrder() {
        let analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: (1...14).reversed().map {
                makeSalesSummary(
                    day: $0,
                    sales: $0,
                    capacity: 100 + $0
                )
            }
        )

        let points = analytics.salesCapacityAnalysis(for: .tenDays)

        #expect(points.map(\.operatingDay) == Array(5...14))
        #expect(points.map(\.actualSales) == Array(5...14))
        #expect(
            points.map(\.potentialSalesCapacity)
                == Array(105...114)
        )
    }

    @Test
    func ingredientShortageLowersSalesWithoutLoweringCapacityLine() throws {
        let analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: [
                makeSalesSummary(
                    day: 1,
                    demandedSales: 120,
                    sales: 40,
                    limits: [
                        SalesLimit(type: .equipment, units: 100),
                        SalesLimit(
                            type: .ingredient(
                                type: .flour,
                                name: "Flour"
                            ),
                            units: 40
                        )
                    ]
                )
            ]
        )
        let point = try #require(
            analytics.salesCapacityAnalysis(for: .allTime).first
        )

        #expect(point.actualSales == 40)
        #expect(point.potentialSalesCapacity == 100)
    }

    @Test
    func demandBelowCapacityDoesNotClassifyDayAsSellout() throws {
        let analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: [
                makeSalesSummary(
                    day: 1,
                    demandedSales: 50,
                    sales: 50,
                    capacity: 100
                )
            ]
        )
        let row = try #require(analytics.rows.first)
        let didNotSellOut = try selloutResult(
            .didNotSellOut,
            in: analytics.selloutAnalysis(for: .allTime)
        )

        #expect(!row.didSellOut)
        #expect(row.selloutCause == nil)
        #expect(didNotSellOut.dayCount == 1)
    }
}

// MARK: - Sellout Breakdown

extension SalesAnalyticsTests {

    @Test
    func everyOperatingDayContributesToOneMutuallyExclusiveOutcome() throws {
        let analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: selloutOutcomeSummaries
        )
        let results = analytics.selloutAnalysis(for: .allTime)

        #expect(results.map(\.outcome) == SalesOutcome.allCases)
        #expect(results.map(\.dayCount) == [1, 1, 1, 1, 1])
        #expect(results.reduce(0) { $0 + $1.dayCount } == 5)

        let percentages = try results.map {
            try #require($0.percentage)
        }
        #expect(percentages.allSatisfy { approximatelyEqual($0, 0.2) })
        #expect(approximatelyEqual(percentages.reduce(0, +), 1.0))
    }

    @Test
    func selloutBreakdownUsesOnlyRowsInSelectedPeriod() throws {
        var summaries = [
            makeSalesSummary(
                day: 1,
                demandedSales: 100,
                sales: 50,
                limits: [
                    SalesLimit(type: .equipment, units: 100),
                    SalesLimit(
                        type: .ingredient(type: .apple, name: "Apples"),
                        units: 50
                    )
                ]
            )
        ]
        summaries.append(
            contentsOf: (2...11).map {
                makeSalesSummary(
                    day: $0,
                    demandedSales: 50,
                    sales: 50
                )
            }
        )
        let analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: summaries
        )

        let tenDayResults = analytics.selloutAnalysis(for: .tenDays)
        let didNotSellOut = try selloutResult(
            .didNotSellOut,
            in: tenDayResults
        )
        let ingredients = try selloutResult(
            .ingredients,
            in: tenDayResults
        )

        #expect(didNotSellOut.dayCount == 10)
        #expect(didNotSellOut.percentage == 1)
        #expect(ingredients.dayCount == 0)
        #expect(ingredients.percentage == 0)
    }

    @Test
    func emptySelloutPeriodReturnsCountsAndUnavailablePercentages() {
        let analytics = SalesAnalytics(product: salesAnalyticsProduct)
        let results = analytics.selloutAnalysis(for: .allTime)

        #expect(results.count == SalesOutcome.allCases.count)
        #expect(results.allSatisfy { $0.dayCount == 0 })
        #expect(results.allSatisfy { $0.percentage == nil })
    }

    @Test
    func tiedSelloutCausesUseHighestPriorityOutcome() throws {
        let analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: [
                makeSalesSummary(
                    day: 1,
                    demandedSales: 100,
                    sales: 50,
                    limits: [
                        SalesLimit(type: .storage, units: 50),
                        SalesLimit(type: .equipment, units: 50),
                        SalesLimit(type: .labor, units: 50),
                        SalesLimit(
                            type: .ingredient(
                                type: .apple,
                                name: "Apples"
                            ),
                            units: 50
                        )
                    ]
                )
            ]
        )
        let results = analytics.selloutAnalysis(for: .allTime)
        let ingredients = try selloutResult(.ingredients, in: results)
        let labor = try selloutResult(.labor, in: results)
        let equipment = try selloutResult(.equipment, in: results)
        let storage = try selloutResult(.storage, in: results)

        #expect(ingredients.dayCount == 1)
        #expect(labor.dayCount == 0)
        #expect(equipment.dayCount == 0)
        #expect(storage.dayCount == 0)
    }
}

// MARK: - Ingredient Usage and Expiration

extension SalesAnalyticsTests {

    @Test
    func ingredientUsageTotalsOnlySelectedPeriodAndCalculatesPercentages() {
        var summaries = [
            makeSalesSummary(
                day: 1,
                consumedIngredientCost: 1_000,
                expiredIngredientCost: 1_000
            )
        ]
        summaries.append(
            contentsOf: (2...11).map {
                makeSalesSummary(
                    day: $0,
                    consumedIngredientCost: 9,
                    expiredIngredientCost: 1
                )
            }
        )
        let analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: summaries
        )

        let result = analytics.ingredientUsageAnalysis(for: .tenDays)

        #expect(result.consumedCost == 90)
        #expect(result.expiredCost == 10)
        #expect(result.totalCost == 100)
        #expect(result.consumedPercentage == 0.9)
        #expect(result.expiredPercentage == 0.1)
        #expect(
            approximatelyEqual(
                (result.consumedPercentage ?? 0)
                    + (result.expiredPercentage ?? 0),
                1
            )
        )
    }

    @Test
    func zeroIngredientDispositionReturnsUnavailablePercentages() {
        let analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: [makeSalesSummary(day: 1)]
        )

        let result = analytics.ingredientUsageAnalysis(for: .allTime)

        #expect(result.totalCost == 0)
        #expect(result.consumedPercentage == nil)
        #expect(result.expiredPercentage == nil)
    }

    @Test
    func ingredientUsageIgnoresInventoryPurchaseCashFlow() {
        let summary = makeSalesSummary(
            day: 1,
            consumedIngredientCost: 30,
            expiredIngredientCost: 10
        )
        summary.cashFlowCosts.append(
            Cost(
                category: .ingredients,
                name: "Ingredient Purchase",
                amount: 10_000
            )
        )
        let analytics = SalesAnalytics(
            product: salesAnalyticsProduct,
            summaries: [summary]
        )

        let result = analytics.ingredientUsageAnalysis(for: .allTime)

        #expect(result.consumedCost == 30)
        #expect(result.expiredCost == 10)
        #expect(result.totalCost == 40)
        #expect(result.expiredPercentage == 0.25)
    }
}

private let salesAnalyticsProduct = ProductCatalog().product(for: .pies)

private let selloutOutcomeSummaries = [
    makeSalesSummary(day: 1, demandedSales: 50, sales: 50),
    makeSalesSummary(
        day: 2,
        demandedSales: 100,
        sales: 50,
        limits: [
            SalesLimit(type: .equipment, units: 100),
            SalesLimit(
                type: .ingredient(type: .apple, name: "Apples"),
                units: 50
            )
        ]
    ),
    makeSalesSummary(
        day: 3,
        demandedSales: 100,
        sales: 50,
        limits: [
            SalesLimit(type: .equipment, units: 100),
            SalesLimit(type: .labor, units: 50)
        ]
    ),
    makeSalesSummary(
        day: 4,
        demandedSales: 100,
        sales: 50,
        limits: [SalesLimit(type: .equipment, units: 50)]
    ),
    makeSalesSummary(
        day: 5,
        demandedSales: 100,
        sales: 50,
        limits: [
            SalesLimit(type: .equipment, units: 100),
            SalesLimit(type: .storage, units: 50)
        ]
    )
]

private func makeSalesSummary(
    day: Int,
    type: DaySummaryType = .operating,
    demandedSales: Int = 100,
    sales: Int = 50,
    capacity: Int = 100,
    limits: [SalesLimit]? = nil,
    consumedIngredientCost: Double = 0,
    expiredIngredientCost: Double = 0
) -> DaySummary {
    let summary = DaySummary(
        day: day,
        startingBalance: 1_000,
        type: type
    )

    guard type == .operating else {
        return summary
    }

    summary.demandedSales = demandedSales
    summary.sales = sales
    summary.salesLimits = limits
        ?? [SalesLimit(type: .equipment, units: capacity)]
    summary.consumedIngredientCost = consumedIngredientCost
    summary.expiredIngredientCost = expiredIngredientCost
    return summary
}

private func rowSignatures(
    _ rows: [SalesAnalyticsRow]
) -> [String] {
    rows.map { row in
        [
            String(row.simulationDay),
            String(row.operatingDay),
            String(row.actualSales),
            String(row.operationalCapacity),
            salesLimitSignatures(row.operationalCapacityLimiters)
                .joined(separator: ","),
            String(row.didSellOut),
            row.selloutCause?.rawValue ?? "none",
            String(row.consumedIngredientCost),
            String(row.expiredIngredientCost)
        ].joined(separator: "|")
    }
}

private func salesLimitSignatures(
    _ limits: [SalesLimit]
) -> [String] {
    limits.map { limit in
        let type: String

        switch limit.type {
        case .equipment:
            type = "equipment"
        case .labor:
            type = "labor"
        case .storage:
            type = "storage"
        case let .ingredient(inventoryType, name):
            type = "ingredient:\(inventoryType.rawValue):\(name)"
        }

        return "\(type):\(limit.units)"
    }
}

private func trendSignatures(
    _ points: [SalesCapacityAnalysisPoint]
) -> [String] {
    points.map {
        "\($0.operatingDay)|\($0.actualSales)|\($0.potentialSalesCapacity)"
    }
}

private func selloutResult(
    _ outcome: SalesOutcome,
    in results: [SelloutAnalysisResult]
) throws -> SelloutAnalysisResult {
    try #require(results.first { $0.outcome == outcome })
}

private func approximatelyEqual(
    _ actual: Double,
    _ expected: Double,
    tolerance: Double = 0.000_001
) -> Bool {
    abs(actual - expected) < tolerance
}
