//
//  weather.swift
//  BusinessSimulator
//

import Foundation
import GameplayKit
import Observation

enum WeatherCondition: String, Codable {
    case sunny
    case cloudy
    case rain
    case snow
}

struct DailyWeather: Identifiable {
    let date: Date
    let highTemperature: Int
    let lowTemperature: Int
    let condition: WeatherCondition

    var id: Date {
        date
    }
}

@Observable
final class WeatherState {
    private struct MonthlyTemperature {
        let averageHigh: Double
        let averageLow: Double
    }

    private struct MonthlyConditionProbability {
        let precipitation: Float
        let cloudiness: Float
    }

    private static let monthlyTemperatures: [Int: MonthlyTemperature] = [
        1: MonthlyTemperature(averageHigh: 43, averageLow: 27),
        2: MonthlyTemperature(averageHigh: 48, averageLow: 30),
        3: MonthlyTemperature(averageHigh: 58, averageLow: 38),
        4: MonthlyTemperature(averageHigh: 69, averageLow: 47),
        5: MonthlyTemperature(averageHigh: 77, averageLow: 56),
        6: MonthlyTemperature(averageHigh: 84, averageLow: 64),
        7: MonthlyTemperature(averageHigh: 88, averageLow: 68),
        8: MonthlyTemperature(averageHigh: 86, averageLow: 67),
        9: MonthlyTemperature(averageHigh: 80, averageLow: 59),
        10: MonthlyTemperature(averageHigh: 69, averageLow: 47),
        11: MonthlyTemperature(averageHigh: 57, averageLow: 37),
        12: MonthlyTemperature(averageHigh: 47, averageLow: 30)
    ]

    private static let monthlyConditionProbabilities: [
        Int: MonthlyConditionProbability
    ] = [
        1: MonthlyConditionProbability(precipitation: 0.30, cloudiness: 0.45),
        2: MonthlyConditionProbability(precipitation: 0.29, cloudiness: 0.43),
        3: MonthlyConditionProbability(precipitation: 0.35, cloudiness: 0.42),
        4: MonthlyConditionProbability(precipitation: 0.38, cloudiness: 0.40),
        5: MonthlyConditionProbability(precipitation: 0.36, cloudiness: 0.35),
        6: MonthlyConditionProbability(precipitation: 0.32, cloudiness: 0.28),
        7: MonthlyConditionProbability(precipitation: 0.30, cloudiness: 0.25),
        8: MonthlyConditionProbability(precipitation: 0.28, cloudiness: 0.24),
        9: MonthlyConditionProbability(precipitation: 0.25, cloudiness: 0.27),
        10: MonthlyConditionProbability(precipitation: 0.24, cloudiness: 0.31),
        11: MonthlyConditionProbability(precipitation: 0.30, cloudiness: 0.40),
        12: MonthlyConditionProbability(precipitation: 0.32, cloudiness: 0.46)
    ]

    @ObservationIgnored
    private let randomSource: any GKRandom

    @ObservationIgnored
    private let calendar = Foundation.Calendar(identifier: .gregorian)

    private(set) var weeklyForecast: [DailyWeather]

    init(
        weeklyForecast: [DailyWeather] = [],
        randomSource: any GKRandom = GKMersenneTwisterRandomSource()
    ) {
        self.weeklyForecast = weeklyForecast
        self.randomSource = randomSource
    }

    @discardableResult
    func generateWeeklyForecast(
        starting monday: Date
    ) -> [DailyWeather] {
        precondition(
            calendar.component(.weekday, from: monday) == 2,
            "A weekly forecast must begin on Monday."
        )

        //calculate a weekly adjustment so the week can be cooler than normal
        //or warmer than normal
        let weeklyAdjustment = GKGaussianDistribution(
            randomSource: randomSource,
            lowestValue: -12,
            highestValue: 12
        ).nextInt()

        //find daily forecasts for next five days
        let forecast = (0..<5).map { dayOffset in
            guard let date = calendar.date(
                byAdding: .day,
                value: dayOffset,
                to: monday
            ) else {
                preconditionFailure("Unable to create a forecast date.")
            }

            return generateDailyForecast(
                for: date,
                weeklyAdjustment: weeklyAdjustment
            )
        }

        weeklyForecast = forecast
        return forecast
    }

    //once weekly forecast is generated returns weather for any day in that week
    func weather(
        for date: Date
    ) -> DailyWeather {
        guard let weather = weeklyForecast.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) else {
            preconditionFailure(
                "No weather exists for the requested business date."
            )
        }

        return weather
    }

    func displayedWeather(
        for date: Date
    ) -> Int {
        weather(for: date).highTemperature
    }

    private func generateDailyForecast(
        for date: Date,
        weeklyAdjustment: Int
    ) -> DailyWeather {
        //find average high and low for this date historically
        let normalTemperature = normalTemperature(for: date)

        //add a daily adjustment factor
        let dailyChange = GKGaussianDistribution(
            randomSource: randomSource,
            lowestValue: -6,
            highestValue: 6
        ).nextInt()

        //add a low temp adjustment factor so that the spread is not always identical
        let lowTemperatureChange = GKGaussianDistribution(
            randomSource: randomSource,
            lowestValue: -3,
            highestValue: 3
        ).nextInt()

        let highTemperature =
            Int(normalTemperature.averageHigh.rounded())
            + weeklyAdjustment
            + dailyChange

        let lowTemperature =
            Int(normalTemperature.averageLow.rounded())
            + weeklyAdjustment
            + dailyChange
            + lowTemperatureChange

        let condition = generateCondition(
            month: calendar.component(.month, from: date),
            highTemperature: highTemperature
        )

        return DailyWeather(
            date: date,
            highTemperature: highTemperature,
            lowTemperature: lowTemperature,
            condition: condition
        )
    }

    private func generateCondition(
        month: Int,
        highTemperature: Int
    ) -> WeatherCondition {
        guard let probabilities = Self.monthlyConditionProbabilities[month]
        else {
            preconditionFailure("Unable to find weather probabilities.")
        }

        let precipitationOccurs =
            randomSource.nextUniform() < probabilities.precipitation

        if precipitationOccurs {
            if highTemperature >= 40 {
                return .rain
            }

            if highTemperature >= 32 {
                return randomSource.nextUniform() < 0.5
                    ? .rain
                    : .snow
            }

            return .snow
        }

        let cloudinessOccurs =
            randomSource.nextUniform() < probabilities.cloudiness

        return cloudinessOccurs ? .cloudy : .sunny
    }

    //starts with avg historical temp for month and interpolates for where in the month you are
    private func normalTemperature(
        for date: Date,
    ) -> MonthlyTemperature {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let nextMonth = month == 12 ? 1 : month + 1

        guard
            let currentTemperature = Self.monthlyTemperatures[month],
            let nextTemperature = Self.monthlyTemperatures[nextMonth],
            let daysInMonth = calendar.range(
                of: .day,
                in: .month,
                for: date
            )?.count
        else {
            preconditionFailure("Unable to calculate seasonal temperature.")
        }

        let monthProgress = Double(day - 1) / Double(daysInMonth)

        return MonthlyTemperature(
            averageHigh: currentTemperature.averageHigh
                + monthProgress
                * (nextTemperature.averageHigh
                    - currentTemperature.averageHigh),
            averageLow: currentTemperature.averageLow
                + monthProgress
                * (nextTemperature.averageLow
                    - currentTemperature.averageLow)
        )
    }
}

final class WeatherDimension: Dimension {

    //this is the weight this dimension has on total demand. All dimension weights
    //must add up to 1.0
    static let demandWeight = 0.11

    private let weatherState: WeatherState
    private let product: Product
    private let calendar: GameCalendar

    init(
        weatherState: WeatherState,
        product: Product,
        calendar: GameCalendar
    ) {
        self.weatherState = weatherState
        self.product = product
        self.calendar = calendar
    }

    func calculateDemand() -> Double {
        let weather = weatherState.weather(for: calendar.currentDate)
        let temperature = Double(weather.highTemperature)
        let effectScore: Double

        switch product.temperatureInterpolationFormula {
        case .warmWeather:
            effectScore = min(
                (temperature - 68) / 22,
                1.0
            )

        case .coldWeather:
            effectScore = min(
                (65 - temperature) / 20,
                1.0
            )

        case .temperateWeather:
            switch temperature {
            case ..<50:
                effectScore = (temperature - 50) / (50.0 / 3.0)
            case 50..<70:
                effectScore = (temperature - 50) / 20
            case 70...80:
                effectScore = 1.0
            default:
                effectScore = (95 - temperature) / 15
            }
        }

        return SimulationBalance.demand.multiplier(
            weight: Self.demandWeight,
            effectScore: effectScore
        )
    }

    ///Weather is a temporary market size modifier and is not part of
    ///the permanent market size progression.
    func calculateMarketSize() -> Double {
        let weather = weatherState.weather(for: calendar.currentDate)

        switch weather.condition {
        case .sunny:
            return 1.10
        case .cloudy:
            return 1.00
        case .rain:
            return 0.85
        case .snow:
            return 0.85
        }
    }
}

enum TemperatureInterpolationFormula {
    case warmWeather
    case coldWeather
    case temperateWeather
}
