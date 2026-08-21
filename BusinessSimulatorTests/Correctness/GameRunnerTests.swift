import Foundation
import Testing
@testable import BusinessSimulator

struct GameRunnerTests {}

// MARK: - Demand Fulfillment Rate

struct DemandFulfillmentRateCase: Sendable {
    let name: String
    let demandedBatches: Int
    let actualBatches: Int
    let expectedRate: Double
}

private let demandFulfillmentRateCases = [
    DemandFulfillmentRateCase(
        name: "all demand is fulfilled",
        demandedBatches: 100,
        actualBatches: 100,
        expectedRate: 1.0
    ),
    DemandFulfillmentRateCase(
        name: "three quarters of demand is fulfilled",
        demandedBatches: 100,
        actualBatches: 75,
        expectedRate: 0.75
    ),
    DemandFulfillmentRateCase(
        name: "fractional fulfillment is preserved",
        demandedBatches: 3,
        actualBatches: 1,
        expectedRate: 1.0 / 3.0
    ),
    DemandFulfillmentRateCase(
        name: "none of the demand is fulfilled",
        demandedBatches: 100,
        actualBatches: 0,
        expectedRate: 0.0
    ),
    DemandFulfillmentRateCase(
        name: "zero demand is fully fulfilled",
        demandedBatches: 0,
        actualBatches: 0,
        expectedRate: 1.0
    )
]

extension GameRunnerTests {

    @Test(arguments: demandFulfillmentRateCases)
    func demandFulfillmentRateUsesActualOverDemandedBatches(
        testCase: DemandFulfillmentRateCase
    ) {
        let rate = GameRunner.calculateDemandFulfillmentRate(
            demandedBatches: testCase.demandedBatches,
            actualBatches: testCase.actualBatches
        )

        #expect(abs(rate - testCase.expectedRate) < 0.000_001)
    }
}

// MARK: - Sellout Time

struct SelloutTimeCase: Sendable {
    let name: String
    let openingTime: BusinessTime
    let closingTime: BusinessTime
    let demandFulfillmentRate: Double
    let expectedHour: Int
    let expectedMinute: Int
}

private let selloutTimeCases = [
    SelloutTimeCase(
        name: "no demand fulfilled sells out at opening",
        openingTime: BusinessTime(hour: 9, minute: 0),
        closingTime: BusinessTime(hour: 17, minute: 0),
        demandFulfillmentRate: 0.0,
        expectedHour: 9,
        expectedMinute: 0
    ),
    SelloutTimeCase(
        name: "one quarter fulfilled sells out one quarter through the day",
        openingTime: BusinessTime(hour: 9, minute: 0),
        closingTime: BusinessTime(hour: 17, minute: 0),
        demandFulfillmentRate: 0.25,
        expectedHour: 11,
        expectedMinute: 0
    ),
    SelloutTimeCase(
        name: "half fulfilled sells out halfway through the day",
        openingTime: BusinessTime(hour: 9, minute: 0),
        closingTime: BusinessTime(hour: 17, minute: 0),
        demandFulfillmentRate: 0.50,
        expectedHour: 13,
        expectedMinute: 0
    ),
    SelloutTimeCase(
        name: "three quarters fulfilled sells out late in the day",
        openingTime: BusinessTime(hour: 9, minute: 0),
        closingTime: BusinessTime(hour: 17, minute: 0),
        demandFulfillmentRate: 0.75,
        expectedHour: 15,
        expectedMinute: 0
    ),
    SelloutTimeCase(
        name: "all demand fulfilled reaches closing time",
        openingTime: BusinessTime(hour: 9, minute: 0),
        closingTime: BusinessTime(hour: 17, minute: 0),
        demandFulfillmentRate: 1.0,
        expectedHour: 17,
        expectedMinute: 0
    ),
    SelloutTimeCase(
        name: "sellout time rounds to the nearest minute",
        openingTime: BusinessTime(hour: 9, minute: 30),
        closingTime: BusinessTime(hour: 14, minute: 45),
        demandFulfillmentRate: 0.50,
        expectedHour: 12,
        expectedMinute: 8
    )
]

extension GameRunnerTests {

    @Test(arguments: selloutTimeCases)
    func selloutTimeUsesFulfillmentPortionOfBusinessHours(
        testCase: SelloutTimeCase
    ) {
        let businessHours = BusinessHours(
            openingTime: testCase.openingTime,
            closingTime: testCase.closingTime
        )

        let selloutTime = businessHours.calculateSelloutTime(
            demandFulfillmentRate: testCase.demandFulfillmentRate
        )

        #expect(selloutTime.hour == testCase.expectedHour)
        #expect(selloutTime.minute == testCase.expectedMinute)
    }
}
