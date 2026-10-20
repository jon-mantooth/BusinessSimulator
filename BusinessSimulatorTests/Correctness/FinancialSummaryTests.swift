import Foundation
import Testing
@testable import BusinessSimulator

struct FinancialSummaryTests {}

// MARK: - Dataset Construction

extension FinancialSummaryTests {

    @Test
    func initializationSortsAndIncludesOperatingAndRelocationSummaries() {
        let summary = FinancialSummary(
            summaries: [
                makeFinancialDaySummary(day: 8, revenue: 800),
                makeFinancialDaySummary(
                    day: 3,
                    type: .relocation,
                    revenue: 0
                ),
                makeFinancialDaySummary(day: 1, revenue: 100)
            ]
        )

        #expect(summary.rows.map(\.day) == [1, 3, 8])
        #expect(summary.rows.map(\.revenue) == [100, 0, 800])
    }

    @Test
    func appendCopiesEveryFinancialSourceFieldIntoOneRow() throws {
        let locationID = LocationID(rawValue: "beach")
        let costs = [
            Cost(category: .ingredients, name: "Fruit", amount: 25),
            Cost(category: .labor, name: "Mixologist", amount: 75)
        ]
        let daySummary = makeFinancialDaySummary(
            day: 4,
            locationID: locationID,
            startingBalance: 2_000,
            revenue: 500,
            costs: costs
        )
        var summary = FinancialSummary()

        summary.append(from: daySummary)

        let row = try #require(summary.rows.first)
        #expect(summary.rows.count == 1)
        #expect(row.day == 4)
        #expect(row.locationID == locationID)
        #expect(row.startingBalance == 2_000)
        #expect(row.revenue == 500)
        #expect(row.costs.count == 2)
        #expect(row.costs.map(\.name) == ["Fruit", "Mixologist"])
        #expect(row.costs.map(\.amount) == [25, 75])
    }

    @Test
    func rowEndingBalanceUsesRevenueAndEveryCashFlowCost() throws {
        let summary = FinancialSummary(
            summaries: [
                makeFinancialDaySummary(
                    day: 1,
                    startingBalance: 1_000,
                    revenue: 400,
                    costs: [
                        Cost(
                            category: .ingredients,
                            name: "Ingredients",
                            amount: 125
                        ),
                        Cost(
                            category: .labor,
                            name: "Chef",
                            amount: 75
                        )
                    ]
                )
            ]
        )

        let row = try #require(summary.rows.first)

        #expect(row.endingBalance == 1_200)
    }

    @Test
    func relocationRowRetainsZeroRevenueAndRelocationCosts() throws {
        let relocationCost = Cost(
            category: .relocation,
            name: "Relocation",
            amount: 15_000
        )
        let summary = FinancialSummary(
            summaries: [
                makeFinancialDaySummary(
                    day: 2,
                    type: .relocation,
                    startingBalance: 20_000,
                    revenue: 0,
                    costs: [relocationCost]
                )
            ]
        )
        let row = try #require(summary.rows.first)

        #expect(row.revenue == 0)
        #expect(row.costs.count == 1)
        #expect(row.costs.first?.category == .relocation)
        #expect(row.costs.first?.amount == 15_000)
        #expect(row.endingBalance == 5_000)
    }

    @Test
    func rebuildingAndAppendingProduceEquivalentRows() {
        let summaries = financialReportFixture
        let rebuilt = FinancialSummary(summaries: summaries)
        var appended = FinancialSummary()

        for summary in summaries {
            appended.append(from: summary)
        }

        #expect(
            financialRowSignatures(rebuilt.rows)
                == financialRowSignatures(appended.rows)
        )
    }
}

// MARK: - Report Filtering and Revenue

extension FinancialSummaryTests {

    @Test
    func allLocationReportIncludesEveryOperatingAndRelocationDay() {
        let summary = FinancialSummary(summaries: financialReportFixture)

        let report = summary.report(for: nil)

        #expect(report.locationID == nil)
        #expect(report.totalDays == 3)
        #expect(report.totalRevenue == 1_100)
        #expect(approximatelyEqual(report.revenuePerDay, 1_100 / 3))
        #expect(report.startingBalance == 1_000)
        #expect(report.endingBalance == 1_675)
        #expect(report.revenueByDay.map(\.day) == [1, 2, 3])
        #expect(report.revenueByDay.map(\.revenue) == [500, 0, 600])
    }

    @Test
    func locationReportIncludesOnlyRowsAssignedToThatLocation() {
        let summary = FinancialSummary(summaries: financialReportFixture)

        let homeReport = summary.report(for: homeLocationID)
        let beachReport = summary.report(for: beachLocationID)

        #expect(homeReport.locationID == homeLocationID)
        #expect(homeReport.totalDays == 2)
        #expect(homeReport.totalRevenue == 500)
        #expect(homeReport.revenuePerDay == 250)
        #expect(homeReport.startingBalance == 1_000)
        #expect(homeReport.endingBalance == 1_200)
        #expect(homeReport.revenueByDay.map(\.day) == [1, 2])

        #expect(beachReport.locationID == beachLocationID)
        #expect(beachReport.totalDays == 1)
        #expect(beachReport.totalRevenue == 600)
        #expect(beachReport.revenuePerDay == 600)
        #expect(beachReport.startingBalance == 1_200)
        #expect(beachReport.endingBalance == 1_675)
        #expect(beachReport.revenueByDay.map(\.day) == [3])
    }

    @Test
    func relocationDayIsReportedAgainstOriginLocation() {
        let summary = FinancialSummary(summaries: financialReportFixture)

        let originReport = summary.report(for: homeLocationID)
        let destinationReport = summary.report(for: beachLocationID)

        #expect(originReport.revenueByDay.map(\.day).contains(2))
        #expect(!destinationReport.revenueByDay.map(\.day).contains(2))
        #expect(originReport.totalDays == 2)
        #expect(destinationReport.totalDays == 1)
    }
}

// MARK: - Cost Aggregation and Profit

extension FinancialSummaryTests {

    @Test
    func costsGroupByCategoryThenNameAndRepeatedItemsAreTotaled() throws {
        let summary = FinancialSummary(summaries: financialReportFixture)
        let report = summary.report(for: nil)
        let ingredients = report.costs(for: .ingredients)
        let equipment = report.costs(for: .equipment)
        let flour = try #require(
            ingredients.items.first { $0.name == "Flour" }
        )
        let apples = try #require(
            ingredients.items.first { $0.name == "Apples" }
        )
        let oven = try #require(
            equipment.items.first { $0.name == "Oven" }
        )

        #expect(ingredients.items.map(\.name) == ["Apples", "Flour"])
        #expect(flour.total == 25)
        #expect(apples.total == 5)
        #expect(ingredients.total == 30)
        #expect(oven.total == 150)
        #expect(equipment.total == 150)
    }

    @Test
    func identicalItemNamesInDifferentCategoriesRemainSeparate() throws {
        let summaries = [
            makeFinancialDaySummary(
                day: 1,
                costs: [
                    Cost(category: .equipment, name: "Service", amount: 100),
                    Cost(category: .labor, name: "Service", amount: 40)
                ]
            )
        ]
        let report = FinancialSummary(summaries: summaries).report(for: nil)
        let equipmentService = try #require(
            report.costs(for: .equipment).items.first
        )
        let laborService = try #require(
            report.costs(for: .labor).items.first
        )

        #expect(equipmentService.name == "Service")
        #expect(equipmentService.total == 100)
        #expect(laborService.name == "Service")
        #expect(laborService.total == 40)
    }

    @Test
    func reportReturnsEveryCostCategoryIncludingZeroCostCategories() {
        let report = FinancialSummary(
            summaries: [makeFinancialDaySummary(day: 1)]
        ).report(for: nil)

        #expect(report.costCategories.map(\.category) == CostCategory.allCases)
        #expect(report.costs(for: .transportation).items.isEmpty)
        #expect(report.costs(for: .transportation).total == 0)
    }

    @Test
    func reportCalculatesTotalCostsAndNetProfit() {
        let report = FinancialSummary(
            summaries: financialReportFixture
        ).report(for: nil)

        #expect(report.totalCosts == 425)
        #expect(report.netProfit == 675)
        #expect(
            report.costCategories.reduce(0) { $0 + $1.total }
                == report.totalCosts
        )
    }
}

// MARK: - Empty Reports and Location Names

extension FinancialSummaryTests {

    @Test
    func emptyReportReturnsSafeTotalsAndNoBalances() {
        let report = FinancialSummary().report(for: nil)

        #expect(report.totalDays == 0)
        #expect(report.startingBalance == nil)
        #expect(report.endingBalance == nil)
        #expect(report.totalRevenue == 0)
        #expect(report.revenuePerDay == 0)
        #expect(report.revenueByDay.isEmpty)
        #expect(report.totalCosts == 0)
        #expect(report.netProfit == 0)
        #expect(report.costCategories.count == CostCategory.allCases.count)
    }

    @Test
    func financeLocationNamesReturnPlayerFacingNamesAndFallback() {
        #expect(FinanceLocationNames.name(for: homeLocationID) == "Neighborhood")
        #expect(FinanceLocationNames.name(for: beachLocationID) == "Beach")
        #expect(
            FinanceLocationNames.name(
                for: LocationID(rawValue: "future-location")
            ) == "future-location"
        )
    }
}

private let homeLocationID = LocationID(rawValue: "home")
private let beachLocationID = LocationID(rawValue: "beach")

private var financialReportFixture: [DaySummary] {
    [
        makeFinancialDaySummary(
            day: 1,
            locationID: homeLocationID,
            startingBalance: 1_000,
            revenue: 500,
            costs: [
                Cost(category: .ingredients, name: "Flour", amount: 10),
                Cost(category: .equipment, name: "Oven", amount: 100)
            ]
        ),
        makeFinancialDaySummary(
            day: 2,
            type: .relocation,
            locationID: homeLocationID,
            startingBalance: 1_390,
            revenue: 0,
            costs: [
                Cost(
                    category: .relocation,
                    name: "Relocation",
                    amount: 190
                )
            ]
        ),
        makeFinancialDaySummary(
            day: 3,
            locationID: beachLocationID,
            startingBalance: 1_200,
            revenue: 600,
            costs: [
                Cost(category: .ingredients, name: "Flour", amount: 15),
                Cost(category: .ingredients, name: "Apples", amount: 5),
                Cost(category: .equipment, name: "Oven", amount: 50),
                Cost(category: .labor, name: "Chef", amount: 55)
            ]
        )
    ]
}

private func makeFinancialDaySummary(
    day: Int,
    type: DaySummaryType = .operating,
    locationID: LocationID = homeLocationID,
    startingBalance: Double = 1_000,
    revenue: Double = 0,
    costs: [Cost] = []
) -> DaySummary {
    let summary = DaySummary(
        day: day,
        locationID: locationID,
        startingBalance: startingBalance,
        type: type
    )
    summary.revenue = revenue
    summary.cashFlowCosts = costs
    return summary
}

private func financialRowSignatures(
    _ rows: [FinancialSummaryRow]
) -> [String] {
    rows.map { row in
        let costs = row.costs.map {
            "\($0.category.rawValue):\($0.name):\($0.amount)"
        }.joined(separator: ",")

        return [
            String(row.day),
            row.locationID.rawValue,
            String(row.startingBalance),
            String(row.revenue),
            costs
        ].joined(separator: "|")
    }
}

private func approximatelyEqual(
    _ actual: Double,
    _ expected: Double,
    tolerance: Double = 0.000_001
) -> Bool {
    abs(actual - expected) < tolerance
}
