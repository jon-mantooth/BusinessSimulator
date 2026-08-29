import Foundation
import Testing
@testable import BusinessSimulator

struct DemandTests {}

// MARK: - Total Demand Allocation

// TODO: Enable once every demand dimension has been implemented.
// @Test
// func demandDimensionWeightsAddUpToOne() {
//     let totalDemandWeight =
//         WeatherDimension.demandWeight
//         + EquipmentDimension.demandWeight
//         + LaborDimension.demandWeight
//         + AdvertisingDimension.demandWeight
//         + ReputationDimension.demandWeight
//
//     #expect(abs(totalDemandWeight - 1.0) < 0.000_001)
// }

// MARK: - Inventory Demand

struct InventoryDemandCase: Sendable {
    let name: String
    let currentDay: Int
    let butterPurchaseDay: Int
    let applePurchaseDay: Int
    let expectedDemand: Double
}

private let inventoryDemandCases = [
    InventoryDemandCase(
        name: "both ingredients have intermediate freshness",
        currentDay: 3,
        butterPurchaseDay: 1,
        applePurchaseDay: 0,
        expectedDemand: 0.966555
    ),
    InventoryDemandCase(
        name: "both ingredients have zero freshness",
        currentDay: 4,
        butterPurchaseDay: 0,
        applePurchaseDay: 0,
        expectedDemand: 0.93
    ),
    InventoryDemandCase(
        name: "both ingredients are fully fresh",
        currentDay: 4,
        butterPurchaseDay: 4,
        applePurchaseDay: 4,
        expectedDemand: 1
    ),
    InventoryDemandCase(
        name: "one ingredient is partially fresh and one is fully fresh",
        currentDay: 4,
        butterPurchaseDay: 2,
        applePurchaseDay: 4,
        expectedDemand: 0.994572
    ),
    InventoryDemandCase(
        name: "one ingredient is partially fresh and one has zero freshness",
        currentDay: 4,
        butterPurchaseDay: 2,
        applePurchaseDay: 0,
        expectedDemand: 0.945310
    )
]

extension DemandTests {

    @Test(arguments: inventoryDemandCases)
    func inventoryDemandCombinesFreshnessCoefficients(
        testCase: InventoryDemandCase
    ) {
        let butter = Inventory(
            type: .butter,
            name: "Butter",
            smallIcon: .emoji("🧈"),
            pricePerUnit: 8,
            amount: 4,
            lifespan: 4
        )

        let apple = Inventory(
            type: .apple,
            name: "Apples",
            smallIcon: .emoji("🍎"),
            pricePerUnit: 60,
            amount: 100,
            lifespan: 4
        )

        let productInventories = [
            ProductInventory(
                inventory: butter,
                amount: 0.5,
                freshnessCoefficient: 0.3
            ),
            ProductInventory(
                inventory: apple,
                amount: 5,
                freshnessCoefficient: 0.7
            )
        ]

        let butterState = InventoryState(
            inventory: butter,
            currentDay: testCase.currentDay
        )
        butterState.inventoryByAge.inventoryByPurchaseDay = [
            testCase.butterPurchaseDay: 1
        ]

        let appleState = InventoryState(
            inventory: apple,
            currentDay: testCase.currentDay
        )
        appleState.inventoryByAge.inventoryByPurchaseDay = [
            testCase.applePurchaseDay: 1
        ]

        let inventoryDimension = InventoryDimension(
            productInventories: productInventories,
            inventoryStates: [butterState, appleState]
        )

        let demand = inventoryDimension.calculateDemand()

        #expect(
            abs(demand - testCase.expectedDemand) < 0.000_001
        )
    }
}

// MARK: - Advertisements

struct AdvertisementDemandCase: Sendable {
    let name: String
    let demandLevel: Int
}

private let advertisementDemandCases = (0...5).map { demandLevel in
    AdvertisementDemandCase(
        name: "demand level \(demandLevel)",
        demandLevel: demandLevel
    )
}

extension DemandTests {

    @Test(arguments: advertisementDemandCases)
    func advertisementReturnsExpectedDemand(
        testCase: AdvertisementDemandCase
    ) {
        let totalLevels = 5
        let advertisementDimension = makeAdvertisementDimension(
            demandLevel: testCase.demandLevel,
            marketSizeLevel: 0,
            totalLevels: totalLevels
        )
        let expectedDemand = SimulationBalance.demand.multiplier(
            weight: AdvertisementDimension.demandWeight,
            effectScore: Double(testCase.demandLevel)
                / Double(totalLevels)
        )

        let demand = advertisementDimension.calculateDemand()

        #expect(
            abs(demand - expectedDemand) < 0.000_001,
            Comment(rawValue: testCase.name)
        )
    }

    @Test
    func advertisementMarketSizeLevelDoesNotAffectDemand() {
        let lowMarketSizeDemand = makeAdvertisementDimension(
            demandLevel: 3,
            marketSizeLevel: 0
        ).calculateDemand()
        let highMarketSizeDemand = makeAdvertisementDimension(
            demandLevel: 3,
            marketSizeLevel: 5
        ).calculateDemand()

        #expect(
            abs(lowMarketSizeDemand - highMarketSizeDemand) < 0.000_001
        )
    }
}

// MARK: - Business Reputation Demand

struct ReputationDemandCase: Sendable {
    let name: String
    let overallReputation: Double
    let expectedEffectScore: Double
}

private let reputationDemandCases = [
    ReputationDemandCase(
        name: "minimum reputation has maximum negative effect",
        overallReputation: 0.0,
        expectedEffectScore: -1.0
    ),
    ReputationDemandCase(
        name: "reputation halfway below neutral has half negative effect",
        overallReputation: 37.5,
        expectedEffectScore: -0.5
    ),
    ReputationDemandCase(
        name: "neutral reputation does not affect demand",
        overallReputation: 75.0,
        expectedEffectScore: 0.0
    ),
    ReputationDemandCase(
        name: "reputation halfway above neutral has half positive effect",
        overallReputation: 87.5,
        expectedEffectScore: 0.5
    ),
    ReputationDemandCase(
        name: "maximum reputation has maximum positive effect",
        overallReputation: 100.0,
        expectedEffectScore: 1.0
    )
]

extension DemandTests {

    @Test(arguments: reputationDemandCases)
    func reputationReturnsExpectedDemand(
        testCase: ReputationDemandCase
    ) {
        let reputation = BusinessReputationState(
            overallReputation: testCase.overallReputation
        )
        let reputationDimension = BusinessReputationDimension(
            reputation: reputation
        )
        let expectedDemand = SimulationBalance.demand.multiplier(
            weight: BusinessReputationDimension.demandWeight,
            effectScore: testCase.expectedEffectScore
        )

        let demand = reputationDimension.calculateDemand()

        #expect(
            abs(demand - expectedDemand) < 0.000_001,
            Comment(rawValue: testCase.name)
        )
    }
}

private func makeAdvertisementDimension(
    demandLevel: Int,
    marketSizeLevel: Int,
    totalLevels: Int = 5
) -> AdvertisementDimension {
    let advertisement = Advertisement(
        id: AdvertisementID(rawValue: "demand-test-advertisement"),
        name: "Demand Test Advertisement",
        smallIcon: .system("megaphone.fill"),
        description: "Tests advertisement demand.",
        paymentSchedule: .oneTime,
        demandLevel: demandLevel,
        marketSizeLevel: marketSizeLevel,
        totalLevels: totalLevels
    )
    let tier = AdvertisementTier(
        id: AdvertisementTierID(rawValue: "demand-test-tier"),
        level: 0,
        advertisements: [advertisement]
    )
    let advertisementState = AdvertisementState(
        tiers: [tier],
        activeAdvertisement: ActiveAdvertisement(
            advertisement: advertisement,
            tierLevel: tier.level
        )
    )

    return AdvertisementDimension(
        advertisementState: advertisementState,
        businessHours: BusinessHours(
            openingTime: BusinessTime(hour: 9, minute: 0),
            closingTime: BusinessTime(hour: 17, minute: 0)
        )
    )
}

// MARK: - Weather Demand

struct WeatherDemandCase: Sendable {
    let name: String
    let productID: String
    let highTemperature: Int
    let expectedEffectScore: Double
}

private let weatherDemandCases = [
    WeatherDemandCase(
        name: "smoothies at neutral temperature",
        productID: "smoothies",
        highTemperature: 68,
        expectedEffectScore: 0.0
    ),
    WeatherDemandCase(
        name: "smoothies above neutral temperature",
        productID: "smoothies",
        highTemperature: 79,
        expectedEffectScore: 0.5
    ),
    WeatherDemandCase(
        name: "smoothies below neutral temperature",
        productID: "smoothies",
        highTemperature: 57,
        expectedEffectScore: -0.5
    ),
    WeatherDemandCase(
        name: "smoothies at maximum favorable temperature",
        productID: "smoothies",
        highTemperature: 90,
        expectedEffectScore: 1.0
    ),
    WeatherDemandCase(
        name: "smoothies above maximum favorable temperature",
        productID: "smoothies",
        highTemperature: 106,
        expectedEffectScore: 1.0
    ),
    WeatherDemandCase(
        name: "smoothies at extreme unfavorable temperature",
        productID: "smoothies",
        highTemperature: 25,
        expectedEffectScore: -43.0 / 22.0
    ),
    WeatherDemandCase(
        name: "pies at neutral temperature",
        productID: "pies",
        highTemperature: 65,
        expectedEffectScore: 0.0
    ),
    WeatherDemandCase(
        name: "pies below neutral temperature",
        productID: "pies",
        highTemperature: 55,
        expectedEffectScore: 0.5
    ),
    WeatherDemandCase(
        name: "pies above neutral temperature",
        productID: "pies",
        highTemperature: 75,
        expectedEffectScore: -0.5
    ),
    WeatherDemandCase(
        name: "pies at maximum favorable temperature",
        productID: "pies",
        highTemperature: 45,
        expectedEffectScore: 1.0
    ),
    WeatherDemandCase(
        name: "pies beyond maximum favorable temperature",
        productID: "pies",
        highTemperature: 25,
        expectedEffectScore: 1.0
    ),
    WeatherDemandCase(
        name: "pies at extreme unfavorable temperature",
        productID: "pies",
        highTemperature: 106,
        expectedEffectScore: -2.05
    ),
    WeatherDemandCase(
        name: "hot dogs at lower neutral temperature",
        productID: "hotDogs",
        highTemperature: 50,
        expectedEffectScore: 0.0
    ),
    WeatherDemandCase(
        name: "hot dogs on rising interpolation",
        productID: "hotDogs",
        highTemperature: 60,
        expectedEffectScore: 0.5
    ),
    WeatherDemandCase(
        name: "hot dogs at lower ideal boundary",
        productID: "hotDogs",
        highTemperature: 70,
        expectedEffectScore: 1.0
    ),
    WeatherDemandCase(
        name: "hot dogs inside ideal range",
        productID: "hotDogs",
        highTemperature: 75,
        expectedEffectScore: 1.0
    ),
    WeatherDemandCase(
        name: "hot dogs at upper ideal boundary",
        productID: "hotDogs",
        highTemperature: 80,
        expectedEffectScore: 1.0
    ),
    WeatherDemandCase(
        name: "hot dogs on falling interpolation",
        productID: "hotDogs",
        highTemperature: 87,
        expectedEffectScore: 8.0 / 15.0
    ),
    WeatherDemandCase(
        name: "hot dogs at upper neutral temperature",
        productID: "hotDogs",
        highTemperature: 95,
        expectedEffectScore: 0.0
    ),
    WeatherDemandCase(
        name: "hot dogs below lower neutral temperature",
        productID: "hotDogs",
        highTemperature: 25,
        expectedEffectScore: -1.5
    ),
    WeatherDemandCase(
        name: "hot dogs above upper neutral temperature",
        productID: "hotDogs",
        highTemperature: 106,
        expectedEffectScore: -11.0 / 15.0
    )
]

extension DemandTests {

    @Test(arguments: weatherDemandCases)
    func weatherDemandUsesProductTemperatureCurve(
        testCase: WeatherDemandCase
    ) {
        let demand = weatherDemand(
            productID: testCase.productID,
            highTemperature: testCase.highTemperature
        )
        let expectedDemand = pow(
            SimulationBalance.demand.totalGrowthFactor,
            WeatherDimension.demandWeight
                * testCase.expectedEffectScore
        )

        #expect(
            abs(demand - expectedDemand) < 0.000_001,
            Comment(rawValue: testCase.name)
        )
    }

    @Test
    func weatherConditionDoesNotAffectDemand() {
        let conditions: [WeatherCondition] = [
            .sunny,
            .cloudy,
            .rain,
            .snow
        ]

        let demands = conditions.map {
            weatherDemand(
                productID: "smoothies",
                highTemperature: 79,
                condition: $0
            )
        }

        #expect(
            demands.allSatisfy {
                abs($0 - demands[0]) < 0.000_001
            }
        )
    }

    @Test
    func weatherLowTemperatureDoesNotAffectDemand() {
        let demandWithLowLow = weatherDemand(
            productID: "smoothies",
            highTemperature: 79,
            lowTemperature: 30
        )
        let demandWithHighLow = weatherDemand(
            productID: "smoothies",
            highTemperature: 79,
            lowTemperature: 70
        )

        #expect(
            abs(demandWithLowLow - demandWithHighLow) < 0.000_001
        )
    }

    private func weatherDemand(
        productID: String,
        highTemperature: Int,
        lowTemperature: Int = 50,
        condition: WeatherCondition = .cloudy
    ) -> Double {
        let productID = ProductID(rawValue: productID)!
        let product = ProductCatalog().products.first {
            $0.id == productID
        }!
        let calendar = GameCalendar()
        let weatherState = WeatherState(
            weeklyForecast: [
                DailyWeather(
                    date: calendar.currentDate,
                    highTemperature: highTemperature,
                    lowTemperature: lowTemperature,
                    condition: condition
                )
            ]
        )
        let weatherDimension = WeatherDimension(
            weatherState: weatherState,
            product: product,
            calendar: calendar
        )

        return weatherDimension.calculateDemand()
    }
}
