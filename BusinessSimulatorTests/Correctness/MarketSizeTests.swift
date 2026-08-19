import Foundation
import Testing
@testable import BusinessSimulator

struct MarketSizeTests {}

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
