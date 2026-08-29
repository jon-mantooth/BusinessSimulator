import Foundation
import Testing
@testable import BusinessSimulator

struct MarketSizeTests {}

// MARK: - Total Market Size Allocation

// TODO: Enable once every permanent market size dimension has been implemented.
// Weather is excluded because its market size effect is transient.
// @Test
// func marketSizeDimensionWeightsAddUpToOne() {
//     let totalMarketSizeWeight =
//         AdvertisingDimension.marketSizeWeight
//         + DistributionDimension.marketSizeWeight
//         + ReputationDimension.marketSizeWeight
//
//     #expect(abs(totalMarketSizeWeight - 1.0) < 0.000_001)
// }

// MARK: - Advertisements

struct AdvertisementMarketSizeCase: Sendable {
    let name: String
    let marketSizeLevel: Int
}

private let advertisementMarketSizeCases = (0...5).map { marketSizeLevel in
    AdvertisementMarketSizeCase(
        name: "market size level \(marketSizeLevel)",
        marketSizeLevel: marketSizeLevel
    )
}

extension MarketSizeTests {

    @Test(arguments: advertisementMarketSizeCases)
    func advertisementReturnsExpectedMarketSize(
        testCase: AdvertisementMarketSizeCase
    ) {
        let totalLevels = 5
        let advertisementDimension = makeAdvertisementDimension(
            demandLevel: 0,
            marketSizeLevel: testCase.marketSizeLevel,
            totalLevels: totalLevels
        )
        let expectedMarketSize = SimulationBalance.marketSize.multiplier(
            weight: AdvertisementDimension.marketSizeWeight,
            effectScore: Double(testCase.marketSizeLevel)
                / Double(totalLevels)
        )

        let marketSize = advertisementDimension.calculateMarketSize()

        #expect(
            abs(marketSize - expectedMarketSize) < 0.000_001,
            Comment(rawValue: testCase.name)
        )
    }

    @Test
    func advertisementDemandLevelDoesNotAffectMarketSize() {
        let lowDemandMarketSize = makeAdvertisementDimension(
            demandLevel: 0,
            marketSizeLevel: 3
        ).calculateMarketSize()
        let highDemandMarketSize = makeAdvertisementDimension(
            demandLevel: 5,
            marketSizeLevel: 3
        ).calculateMarketSize()

        #expect(
            abs(lowDemandMarketSize - highDemandMarketSize) < 0.000_001
        )
    }

    @Test
    func canvassingTimeReducesEntireReachableMarket() {
        let catalog = AdvertisementCatalog()
        let canvassing = catalog.canvassing
        let advertisementDimension = makeAdvertisementDimension(
            advertisement: canvassing
        )
        let advertisementMultiplier =
            SimulationBalance.marketSize.multiplier(
                weight: AdvertisementDimension.marketSizeWeight,
                effectScore: canvassing.marketSizeEffectScore
            )
        let expectedSellingTimeMultiplier = 7.5 / 8.0
        let expectedMarketSize =
            advertisementMultiplier * expectedSellingTimeMultiplier

        let marketSize = advertisementDimension.calculateMarketSize()

        #expect(abs(marketSize - expectedMarketSize) < 0.000_001)
    }
}

// MARK: - Business Reputation Market Size

struct ReputationMarketSizeCase: Sendable {
    let name: String
    let overallReputation: Double
    let expectedEffectScore: Double
}

private let reputationMarketSizeCases = [
    ReputationMarketSizeCase(
        name: "minimum reputation has maximum negative effect",
        overallReputation: 0.0,
        expectedEffectScore: -1.0
    ),
    ReputationMarketSizeCase(
        name: "reputation halfway below neutral has half negative effect",
        overallReputation: 37.5,
        expectedEffectScore: -0.5
    ),
    ReputationMarketSizeCase(
        name: "neutral reputation does not affect market size",
        overallReputation: 75.0,
        expectedEffectScore: 0.0
    ),
    ReputationMarketSizeCase(
        name: "reputation halfway above neutral has half positive effect",
        overallReputation: 87.5,
        expectedEffectScore: 0.5
    ),
    ReputationMarketSizeCase(
        name: "maximum reputation has maximum positive effect",
        overallReputation: 100.0,
        expectedEffectScore: 1.0
    )
]

extension MarketSizeTests {

    @Test(arguments: reputationMarketSizeCases)
    func reputationReturnsExpectedMarketSize(
        testCase: ReputationMarketSizeCase
    ) {
        let reputation = BusinessReputationState(
            overallReputation: testCase.overallReputation
        )
        let reputationDimension = BusinessReputationDimension(
            reputation: reputation
        )
        let expectedMarketSize = SimulationBalance.marketSize.multiplier(
            weight: BusinessReputationDimension.marketSizeWeight,
            effectScore: testCase.expectedEffectScore
        )

        let marketSize = reputationDimension.calculateMarketSize()

        #expect(
            abs(marketSize - expectedMarketSize) < 0.000_001,
            Comment(rawValue: testCase.name)
        )
    }
}

private func makeAdvertisementDimension(
    demandLevel: Int,
    marketSizeLevel: Int,
    totalLevels: Int = 5
) -> AdvertisementDimension {
    makeAdvertisementDimension(
        advertisement: Advertisement(
            id: AdvertisementID(rawValue: "market-size-test-advertisement"),
            name: "Market Size Test Advertisement",
            smallIcon: .system("megaphone.fill"),
            description: "Tests advertisement market size.",
            paymentSchedule: .oneTime,
            demandLevel: demandLevel,
            marketSizeLevel: marketSizeLevel,
            totalLevels: totalLevels
        )
    )
}

private func makeAdvertisementDimension(
    advertisement: Advertisement
) -> AdvertisementDimension {
    let tier = AdvertisementTier(
        id: AdvertisementTierID(rawValue: "market-size-test-tier"),
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

// MARK: - Weather Market Size

struct WeatherMarketSizeCase: Sendable {
    let condition: String
    let expectedMarketSize: Double
}

private let weatherMarketSizeCases = [
    WeatherMarketSizeCase(
        condition: "sunny",
        expectedMarketSize: 1.10
    ),
    WeatherMarketSizeCase(
        condition: "cloudy",
        expectedMarketSize: 1.00
    ),
    WeatherMarketSizeCase(
        condition: "rain",
        expectedMarketSize: 0.85
    ),
    WeatherMarketSizeCase(
        condition: "snow",
        expectedMarketSize: 0.85
    )
]

extension MarketSizeTests {

    @Test(arguments: weatherMarketSizeCases)
    func weatherConditionReturnsExpectedMarketSize(
        testCase: WeatherMarketSizeCase
    ) {
        let marketSize = weatherMarketSize(
            condition: weatherCondition(named: testCase.condition)
        )

        #expect(
            abs(marketSize - testCase.expectedMarketSize) < 0.000_001
        )
    }

    @Test
    func temperatureDoesNotAffectWeatherMarketSize() {
        let coldWeatherMarketSize = weatherMarketSize(
            highTemperature: 25,
            lowTemperature: 5,
            condition: .sunny
        )
        let hotWeatherMarketSize = weatherMarketSize(
            highTemperature: 106,
            lowTemperature: 89,
            condition: .sunny
        )

        #expect(
            abs(coldWeatherMarketSize - hotWeatherMarketSize) < 0.000_001
        )
    }

    private func weatherMarketSize(
        highTemperature: Int = 70,
        lowTemperature: Int = 50,
        condition: WeatherCondition
    ) -> Double {
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
        let product = ProductCatalog().products.first {
            $0.id == .smoothies
        }!
        let weatherDimension = WeatherDimension(
            weatherState: weatherState,
            product: product,
            calendar: calendar
        )

        return weatherDimension.calculateMarketSize()
    }

    private func weatherCondition(
        named name: String
    ) -> WeatherCondition {
        switch name {
        case "sunny":
            return .sunny
        case "cloudy":
            return .cloudy
        case "rain":
            return .rain
        case "snow":
            return .snow
        default:
            preconditionFailure("Unknown weather condition.")
        }
    }
}
