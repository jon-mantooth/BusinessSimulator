import Foundation
import Testing
@testable import BusinessSimulator

struct BusinessAnalyticsTests {

    @Test
    func newAnalyticsStartsWithEveryDatasetEmpty() {
        let analytics = BusinessAnalytics(product: analyticsTestProduct)

        #expect(analytics.priceAnalytics.rows.isEmpty)
        #expect(analytics.salesAnalytics.rows.isEmpty)
        #expect(analytics.financialSummary.rows.isEmpty)
    }

    @Test
    func operatingSummaryIsDispatchedToEveryDataset() {
        let summary = makeBusinessAnalyticsOperatingSummary(day: 1)
        var analytics = BusinessAnalytics(product: analyticsTestProduct)

        analytics.append(from: summary)

        #expect(analytics.priceAnalytics.rows.map(\.simulationDay) == [1])
        #expect(analytics.salesAnalytics.rows.map(\.simulationDay) == [1])
        #expect(analytics.financialSummary.rows.map(\.day) == [1])
    }

    @Test
    func relocationSummaryIsDispatchedOnlyToFinancialSummary() {
        let relocation = DaySummary(
            day: 2,
            locationID: LocationID(rawValue: "home"),
            startingBalance: 20_000,
            type: .relocation
        )
        relocation.cashFlowCosts = [
            Cost(
                category: .relocation,
                name: "Relocation",
                amount: 15_000
            )
        ]
        var analytics = BusinessAnalytics(product: analyticsTestProduct)

        analytics.append(from: relocation)

        #expect(analytics.priceAnalytics.rows.isEmpty)
        #expect(analytics.salesAnalytics.rows.isEmpty)
        #expect(analytics.financialSummary.rows.map(\.day) == [2])
    }

    @Test
    func historicalInitializationSortsOnceAndAppliesDatasetRules() {
        let relocation = DaySummary(
            day: 2,
            locationID: LocationID(rawValue: "home"),
            startingBalance: 1_500,
            type: .relocation
        )
        let analytics = BusinessAnalytics(
            product: analyticsTestProduct,
            summaries: [
                makeBusinessAnalyticsOperatingSummary(day: 3),
                relocation,
                makeBusinessAnalyticsOperatingSummary(day: 1)
            ]
        )

        #expect(
            analytics.priceAnalytics.rows.map(\.simulationDay) == [1, 3]
        )
        #expect(
            analytics.salesAnalytics.rows.map(\.simulationDay) == [1, 3]
        )
        #expect(
            analytics.financialSummary.rows.map(\.day) == [1, 2, 3]
        )
    }

    @Test
    func readingReportsDoesNotAppendOrDuplicateRows() {
        let analytics = BusinessAnalytics(
            product: analyticsTestProduct,
            summaries: [makeBusinessAnalyticsOperatingSummary(day: 1)]
        )

        _ = analytics.priceAnalytics.weatherAnalysis(for: .allTime)
        _ = analytics.salesAnalytics.salesCapacityAnalysis(for: .allTime)
        _ = analytics.financialSummary.report(for: nil)
        _ = analytics.priceAnalytics.weatherAnalysis(for: .allTime)
        _ = analytics.salesAnalytics.salesCapacityAnalysis(for: .allTime)
        _ = analytics.financialSummary.report(for: nil)

        #expect(analytics.priceAnalytics.rows.count == 1)
        #expect(analytics.salesAnalytics.rows.count == 1)
        #expect(analytics.financialSummary.rows.count == 1)
    }
}

private var analyticsTestProduct: Product {
    ProductCatalog().product(for: .pies)
}

private func makeBusinessAnalyticsOperatingSummary(
    day: Int
) -> DaySummary {
    let summary = DaySummary(
        day: day,
        locationID: LocationID(rawValue: "home"),
        startingBalance: 1_000
    )
    summary.demandedSales = 100
    summary.sales = 80
    summary.revenue = 800
    summary.price = 10
    summary.idealPrice = 10
    summary.highTemperature = 70
    summary.lowTemperature = 50
    summary.weatherDemandMultiplier = 1
    summary.businessReputation = 75
    summary.equipmentLevel = 1
    summary.advertisementLevel = 1
    summary.salesLimits = [
        SalesLimit(type: .equipment, units: 100),
        SalesLimit(type: .ingredient(type: .apple, name: "Apples"), units: 80)
    ]
    summary.consumedIngredientCost = 25
    summary.expiredIngredientCost = 5
    summary.cashFlowCosts = [
        Cost(category: .ingredients, name: "Ingredients", amount: 25)
    ]
    return summary
}
