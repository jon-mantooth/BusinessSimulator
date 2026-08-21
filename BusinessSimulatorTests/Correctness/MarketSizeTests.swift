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
