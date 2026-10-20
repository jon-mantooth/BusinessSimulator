import Foundation
import Testing
@testable import BusinessSimulator

struct PriceAnalyticsTests {}

// MARK: - Analysis Periods

extension PriceAnalyticsTests {

    @Test
    func tenDayPeriodReturnsLatestTenRowsInOriginalOrder() {
        let rows = Array(1...35)

        #expect(AnalysisPeriod.tenDays.rows(from: rows) == Array(26...35))
    }

    @Test
    func thirtyDayPeriodReturnsLatestThirtyRowsInOriginalOrder() {
        let rows = Array(1...35)

        #expect(AnalysisPeriod.thirtyDays.rows(from: rows) == Array(6...35))
    }

    @Test
    func longerPeriodReturnsEveryAvailableRow() {
        let rows = Array(1...7)

        #expect(AnalysisPeriod.tenDays.rows(from: rows) == rows)
        #expect(AnalysisPeriod.thirtyDays.rows(from: rows) == rows)
    }

    @Test
    func allTimePeriodReturnsEveryRowInOriginalOrder() {
        let rows = [7, 3, 9, 1]

        #expect(AnalysisPeriod.allTime.rows(from: rows) == rows)
    }
}

// MARK: - Dataset Construction

extension PriceAnalyticsTests {

    @Test
    func historicalInitializationSortsOperatingSummariesAndSkipsRelocations() {
        let analytics = PriceAnalytics(
            summaries: [
                makePriceSummary(day: 8, price: 12),
                makePriceSummary(day: 3, type: .relocation),
                makePriceSummary(day: 2, price: 8),
                makePriceSummary(day: 5, price: 10)
            ]
        )

        #expect(analytics.rows.map(\.simulationDay) == [2, 5, 8])
        #expect(analytics.rows.map(\.operatingDay) == [1, 2, 3])
        #expect(analytics.rows.map(\.price) == [8, 10, 12])
    }

    @Test
    func appendingOperatingSummaryAddsExactlyOneRowAtEnd() {
        var analytics = PriceAnalytics(
            summaries: [makePriceSummary(day: 1)]
        )

        analytics.append(from: makePriceSummary(day: 4, price: 12))

        #expect(analytics.rows.count == 2)
        #expect(analytics.rows.last?.simulationDay == 4)
        #expect(analytics.rows.last?.operatingDay == 2)
        #expect(analytics.rows.last?.price == 12)
    }

    @Test
    func appendingRelocationSummaryAddsNoRow() {
        var analytics = PriceAnalytics(
            summaries: [makePriceSummary(day: 1)]
        )

        analytics.append(from: makePriceSummary(day: 2, type: .relocation))

        #expect(analytics.rows.count == 1)
        #expect(analytics.rows.first?.simulationDay == 1)
    }

    @Test
    func operatingPositionsRemainConsecutiveAcrossSimulationDayGaps() {
        let analytics = PriceAnalytics(
            summaries: [
                makePriceSummary(day: 1),
                makePriceSummary(day: 2, type: .relocation),
                makePriceSummary(day: 9),
                makePriceSummary(day: 20)
            ]
        )

        #expect(analytics.rows.map(\.simulationDay) == [1, 9, 20])
        #expect(analytics.rows.map(\.operatingDay) == [1, 2, 3])
    }

    @Test
    func priceDeviationUsesPriceRelativeToIdealPrice() throws {
        let analytics = PriceAnalytics(
            summaries: [makePriceSummary(day: 1, price: 12, idealPrice: 10)]
        )
        let row = try #require(analytics.rows.first)

        #expect(abs(row.priceDeviation - 0.2) < 0.000_001)
    }

    @Test
    func rowRetainsEveryRequiredHistoricalFactor() throws {
        let locationID = LocationID(rawValue: "beach")
        let analytics = PriceAnalytics(
            summaries: [
                makePriceSummary(
                    day: 7,
                    locationID: locationID,
                    price: 9,
                    idealPrice: 10,
                    highTemperature: 91,
                    lowTemperature: 73,
                    weatherDemandMultiplier: 1.06,
                    businessReputation: 88,
                    equipmentLevel: 3,
                    advertisementLevel: 4
                )
            ]
        )
        let row = try #require(analytics.rows.first)

        #expect(row.simulationDay == 7)
        #expect(row.locationID == locationID)
        #expect(row.price == 9)
        #expect(row.idealPrice == 10)
        #expect(row.highTemperature == 91)
        #expect(row.lowTemperature == 73)
        #expect(row.weatherDemandMultiplier == 1.06)
        #expect(row.businessReputation == 88)
        #expect(row.equipmentLevel == 3)
        #expect(row.advertisementLevel == 4)
    }
}

// MARK: - Overall Trend

extension PriceAnalyticsTests {

    @Test
    func overallTrendUsesSelectedPeriodAndChronologicalRows() {
        let analytics = PriceAnalytics(
            summaries: (1...14).reversed().map {
                makePriceSummary(day: $0, price: Double($0))
            }
        )

        let rows = AnalysisPeriod.tenDays.rows(from: analytics.rows)

        #expect(rows.map(\.simulationDay) == Array(5...14))
        #expect(rows.map(\.operatingDay) == Array(5...14))
    }
}

// MARK: - Weather Analysis

extension PriceAnalyticsTests {

    @Test
    func weatherAnalysisUsesStoredMultiplierAndCalculatesGroupAverages() throws {
        let analytics = PriceAnalytics(
            summaries: [
                makePriceSummary(
                    day: 1,
                    price: 8,
                    weatherDemandMultiplier: 1.00
                ),
                makePriceSummary(
                    day: 2,
                    price: 10,
                    weatherDemandMultiplier: 1.01
                ),
                makePriceSummary(
                    day: 3,
                    price: 12,
                    weatherDemandMultiplier: 1.02
                ),
                makePriceSummary(
                    day: 4,
                    price: 10,
                    weatherDemandMultiplier: 1.05
                ),
                makePriceSummary(
                    day: 5,
                    price: 15,
                    highTemperature: 20,
                    lowTemperature: 10,
                    weatherDemandMultiplier: 1.06
                )
            ]
        )
        let results = analytics.weatherAnalysis(for: .allTime)
        let fair = try weatherResult(.fairOrWorse, in: results)
        let good = try weatherResult(.good, in: results)
        let great = try weatherResult(.great, in: results)

        #expect(fair.observationCount == 2)
        #expect(good.observationCount == 2)
        #expect(great.observationCount == 1)
        #expect(approximatelyEqual(fair.averagePriceRatio, -0.1))
        #expect(approximatelyEqual(good.averagePriceRatio, 0.1))
        #expect(approximatelyEqual(great.averagePriceRatio, 0.5))
    }

    @Test
    func weatherGroupWithoutObservationsReturnsNoAverage() throws {
        let analytics = PriceAnalytics(
            summaries: [
                makePriceSummary(
                    day: 1,
                    weatherDemandMultiplier: 1.06
                )
            ]
        )
        let results = analytics.weatherAnalysis(for: .allTime)

        let fair = try weatherResult(.fairOrWorse, in: results)
        let good = try weatherResult(.good, in: results)

        #expect(fair.observationCount == 0)
        #expect(fair.averagePriceRatio == nil)
        #expect(good.observationCount == 0)
        #expect(good.averagePriceRatio == nil)
    }

    @Test
    func weatherAveragesUseOnlyRowsInsideSelectedPeriod() throws {
        var summaries = [
            makePriceSummary(
                day: 1,
                price: 0,
                weatherDemandMultiplier: 1.00
            )
        ]
        summaries.append(
            contentsOf: (2...11).map {
                makePriceSummary(
                    day: $0,
                    price: 10,
                    weatherDemandMultiplier: 1.00
                )
            }
        )
        let analytics = PriceAnalytics(summaries: summaries)

        let tenDayFair = try weatherResult(
            .fairOrWorse,
            in: analytics.weatherAnalysis(for: .tenDays)
        )
        let allTimeFair = try weatherResult(
            .fairOrWorse,
            in: analytics.weatherAnalysis(for: .allTime)
        )

        #expect(approximatelyEqual(tenDayFair.averagePriceRatio, 0))
        #expect(approximatelyEqual(allTimeFair.averagePriceRatio, -1.0 / 11.0))
    }
}

// MARK: - Business Reputation Analysis

extension PriceAnalyticsTests {

    @Test
    func businessReputationUsesRawScoreBoundariesCountsAndAverages() throws {
        let analytics = PriceAnalytics(
            summaries: [
                makePriceSummary(day: 1, price: 8, businessReputation: 74.9),
                makePriceSummary(day: 2, price: 10, businessReputation: 75),
                makePriceSummary(day: 3, price: 12, businessReputation: 89.9),
                makePriceSummary(day: 4, price: 14, businessReputation: 90)
            ]
        )
        let results = analytics.businessReputationAnalysis(for: .allTime)
        let fair = try reputationResult(.fairOrBelow, in: results)
        let good = try reputationResult(.good, in: results)
        let great = try reputationResult(.great, in: results)

        #expect(fair.observationCount == 1)
        #expect(good.observationCount == 2)
        #expect(great.observationCount == 1)
        #expect(approximatelyEqual(fair.averagePriceRatio, -0.2))
        #expect(approximatelyEqual(good.averagePriceRatio, 0.1))
        #expect(approximatelyEqual(great.averagePriceRatio, 0.4))
    }
}

// MARK: - Upgrade Level Analysis

extension PriceAnalyticsTests {

    @Test
    func equipmentAnalysisGroupsByHistoricalLevelAndMarksEmptyLevels() throws {
        let analytics = PriceAnalytics(
            summaries: [
                makePriceSummary(day: 1, price: 8, equipmentLevel: 0),
                makePriceSummary(day: 2, price: 10, equipmentLevel: 0),
                makePriceSummary(day: 3, price: 14, equipmentLevel: 2)
            ]
        )
        let results = analytics.equipmentLevelAnalysis(for: .allTime)
        let levelZero = try levelResult(0, in: results)
        let levelOne = try levelResult(1, in: results)
        let levelTwo = try levelResult(2, in: results)

        #expect(levelZero.observationCount == 2)
        #expect(approximatelyEqual(levelZero.averagePriceRatio, -0.1))
        #expect(levelOne.observationCount == 0)
        #expect(levelOne.averagePriceRatio == nil)
        #expect(levelTwo.observationCount == 1)
        #expect(approximatelyEqual(levelTwo.averagePriceRatio, 0.4))
    }

    @Test
    func advertisementAnalysisGroupsByHistoricalLevelAndMarksEmptyLevels() throws {
        let analytics = PriceAnalytics(
            summaries: [
                makePriceSummary(day: 1, price: 9, advertisementLevel: 1),
                makePriceSummary(day: 2, price: 11, advertisementLevel: 1),
                makePriceSummary(day: 3, price: 15, advertisementLevel: 4)
            ]
        )
        let results = analytics.advertisementLevelAnalysis(for: .allTime)
        let levelZero = try levelResult(0, in: results)
        let levelOne = try levelResult(1, in: results)
        let levelFour = try levelResult(4, in: results)

        #expect(levelZero.observationCount == 0)
        #expect(levelZero.averagePriceRatio == nil)
        #expect(levelOne.observationCount == 2)
        #expect(approximatelyEqual(levelOne.averagePriceRatio, 0))
        #expect(levelFour.observationCount == 1)
        #expect(approximatelyEqual(levelFour.averagePriceRatio, 0.5))
    }
}

// MARK: - Location Analysis

extension PriceAnalyticsTests {

    @Test
    func locationAnalysisPreservesFirstObservedOrderNamesCountsAndAverages() throws {
        let home = LocationID(rawValue: "home")
        let beach = LocationID(rawValue: "beach")
        let analytics = PriceAnalytics(
            summaries: [
                makePriceSummary(day: 1, locationID: home, price: 8),
                makePriceSummary(day: 2, locationID: beach, price: 15),
                makePriceSummary(day: 3, locationID: home, price: 12)
            ]
        )

        let results = analytics.locationAnalysis(for: .allTime)
        let homeResult = try #require(results.first)
        let beachResult = try #require(results.last)

        #expect(results.map(\.locationID) == [home, beach])
        #expect(results.map(\.locationName) == ["Neighborhood", "Beach"])
        #expect(results.map(\.observationCount) == [2, 1])
        #expect(approximatelyEqual(homeResult.averagePriceRatio, 0))
        #expect(approximatelyEqual(beachResult.averagePriceRatio, 0.5))
    }
}

private func makePriceSummary(
    day: Int,
    type: DaySummaryType = .operating,
    locationID: LocationID = LocationID(rawValue: "home"),
    price: Double = 10,
    idealPrice: Double = 10,
    highTemperature: Int = 80,
    lowTemperature: Int = 60,
    weatherDemandMultiplier: Double = 1,
    businessReputation: Double = 80,
    equipmentLevel: Int = 0,
    advertisementLevel: Int = 0
) -> DaySummary {
    let summary = DaySummary(
        day: day,
        locationID: locationID,
        startingBalance: 1_000,
        type: type
    )

    guard type == .operating else {
        return summary
    }

    summary.price = price
    summary.idealPrice = idealPrice
    summary.highTemperature = highTemperature
    summary.lowTemperature = lowTemperature
    summary.weatherDemandMultiplier = weatherDemandMultiplier
    summary.businessReputation = businessReputation
    summary.equipmentLevel = equipmentLevel
    summary.advertisementLevel = advertisementLevel
    return summary
}

private func weatherResult(
    _ group: WeatherAnalysisGroup,
    in results: [WeatherPriceAnalysisResult]
) throws -> WeatherPriceAnalysisResult {
    try #require(results.first { $0.group == group })
}

private func reputationResult(
    _ group: BusinessReputationAnalysisGroup,
    in results: [BusinessReputationPriceAnalysisResult]
) throws -> BusinessReputationPriceAnalysisResult {
    try #require(results.first { $0.group == group })
}

private func levelResult(
    _ level: Int,
    in results: [LevelPriceAnalysisResult]
) throws -> LevelPriceAnalysisResult {
    try #require(results.first { $0.level == level })
}

private func approximatelyEqual(
    _ actual: Double?,
    _ expected: Double,
    tolerance: Double = 0.000_001
) -> Bool {
    guard let actual else { return false }
    return abs(actual - expected) < tolerance
}
