import Foundation
import Testing
@testable import BusinessSimulator

struct GameRunnerTests {}

// MARK: - Demand Fulfillment Rate

struct DemandFulfillmentRateCase: Sendable {
    let name: String
    let demandedSales: Int
    let actualSales: Int
    let expectedRate: Double
}

private let demandFulfillmentRateCases = [
    DemandFulfillmentRateCase(
        name: "all demand is fulfilled",
        demandedSales: 100,
        actualSales: 100,
        expectedRate: 1.0
    ),
    DemandFulfillmentRateCase(
        name: "three quarters of demand is fulfilled",
        demandedSales: 100,
        actualSales: 75,
        expectedRate: 0.75
    ),
    DemandFulfillmentRateCase(
        name: "fractional fulfillment is preserved",
        demandedSales: 3,
        actualSales: 1,
        expectedRate: 1.0 / 3.0
    ),
    DemandFulfillmentRateCase(
        name: "none of the demand is fulfilled",
        demandedSales: 100,
        actualSales: 0,
        expectedRate: 0.0
    ),
    DemandFulfillmentRateCase(
        name: "zero demand is fully fulfilled",
        demandedSales: 0,
        actualSales: 0,
        expectedRate: 1.0
    )
]

extension GameRunnerTests {

    @Test(arguments: demandFulfillmentRateCases)
    func demandFulfillmentRateUsesActualOverDemandedSales(
        testCase: DemandFulfillmentRateCase
    ) {
        let rate = GameRunner.calculateDemandFulfillmentRate(
            demandedSales: testCase.demandedSales,
            actualSales: testCase.actualSales
        )

        #expect(abs(rate - testCase.expectedRate) < 0.000_001)
    }
}

// MARK: - Daily Summary Reporting Data

extension GameRunnerTests {

    @Test
    func operatingSummaryRecordsPriceWeatherReputationUpgradeAndLocation() {
        let gameState = reportingTestGameState()
        let productState = gameState.productState!
        let expectedPrice = productState.price
        let expectedWeather = gameState.weather.weather(
            for: gameState.calendar.currentDate
        )
        let expectedWeatherMultiplier = productState.product
            .temperatureInterpolationFormula.demandMultiplier(
                for: expectedWeather.demandTemperature
            )

        let summary = GameRunner(gameState: gameState).simulateDay()

        #expect(summary.type == .operating)
        #expect(summary.locationID == gameState.locationState!.activeLocationID)
        #expect(summary.price == expectedPrice)
        #expect(summary.idealPrice == productState.currentIdealPrice)
        #expect(summary.highTemperature == expectedWeather.highTemperature)
        #expect(summary.lowTemperature == expectedWeather.lowTemperature)
        #expect(
            summary.weatherDemandMultiplier == expectedWeatherMultiplier
        )
        #expect(
            summary.businessReputation
                == gameState.reputation!.overallReputation
        )
        #expect(
            summary.equipmentLevel
                == gameState.equipmentState!
                    .activePrimaryEquipment.tierLevel
        )
        #expect(
            summary.advertisementLevel
                == gameState.advertisementState!
                    .activeAdvertisement!.tierLevel
        )
    }

    @Test
    func operatingSummaryRecordsDemandSalesAndEveryApplicableLimit() {
        let gameState = reportingTestGameState()
        let expectedLimits = gameState.departments.flatMap {
            $0.calculateSalesLimits()
        }

        let summary = GameRunner(gameState: gameState).simulateDay()
        let lowestLimit = expectedLimits.map(\.units).min()
            ?? summary.demandedSales
        let highestLimit = expectedLimits.map(\.units).max()
            ?? lowestLimit

        #expect(summary.demandedSales >= summary.sales)
        #expect(
            summary.sales
                == min(summary.demandedSales, lowestLimit)
        )
        #expect(
            salesLimitsByIdentity(summary.salesLimits)
                == salesLimitsByIdentity(expectedLimits)
        )
        #expect(highestLimit > lowestLimit)
        #expect(summary.salesLimits.contains { $0.units == highestLimit })

        for inventoryState in gameState.productState!.productInventoryStates {
            let inventory = inventoryState.productInventory.inventory
            #expect(
                summary.salesLimits.contains { limit in
                    guard case let .ingredient(type, name) = limit.type else {
                        return false
                    }
                    return type == inventory.type && name == inventory.name
                }
            )
        }
    }

    @Test
    func finalizedSummaryRecordsConsumedAndExpiredIngredientCostsSeparately() {
        let gameState = reportingTestGameState(
            includesExpiringInventory: true
        )
        let runner = GameRunner(gameState: gameState)
        let summary = runner.simulateDay()

        runner.finalizeDay()

        #expect(summary.consumedIngredientCost > 0)
        #expect(summary.expiredIngredientCost > 0)
        #expect(
            summary.economicCosts.contains {
                $0.category == .ingredients
                    && $0.name == "Ingredients"
                    && $0.amount == summary.consumedIngredientCost
            }
        )
        #expect(
            summary.economicCosts.contains {
                $0.category == .ingredients
                    && $0.name == "Expired Inventory"
                    && $0.amount == summary.expiredIngredientCost
            }
        )
    }
}

private func reportingTestGameState(
    includesExpiringInventory: Bool = false
) -> GameState {
    let gameState = GameState()
    let product = ProductCatalog().product(for: .pies)
    gameState.initializeBusiness(product: product)
    gameState.beginOperatingPeriodIfNeeded()
    gameState.productState!.price = product.baseIdealPrice

    for inventoryState in gameState.productState!.productInventoryStates {
        let currentDay = gameState.calendar.simulationDay
        var inventoryByPurchaseDay = [currentDay: 1_000.0]

        if includesExpiringInventory {
            inventoryByPurchaseDay[
                currentDay - inventoryState.effectiveLifespan
            ] = 1_000.0
        }

        inventoryState.inventoryByAge.inventoryByPurchaseDay =
            inventoryByPurchaseDay
    }

    return gameState
}

private func salesLimitsByIdentity(
    _ limits: [SalesLimit]
) -> [String: Int] {
    Dictionary(uniqueKeysWithValues: limits.map { limit in
        let identity: String

        switch limit.type {
        case .equipment:
            identity = "equipment"
        case .labor:
            identity = "labor"
        case .storage:
            identity = "storage"
        case let .ingredient(type, name):
            identity = "ingredient:\(type.rawValue):\(name)"
        }

        return (identity, limit.units)
    })
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
