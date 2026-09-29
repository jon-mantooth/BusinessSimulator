//
//  Calendar.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/25/26.
//

import Foundation
import Observation

enum GameWeekday: Int {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}

@Observable
final class GameCalendar {
    static let defaultStartDate: Date = {
        let calendar = Foundation.Calendar(identifier: .gregorian)
        return calendar.date(
            from: DateComponents(
                year: 2026,
                month: 4,
                day: 1
            )
        )!
    }()

    var simulationDay: Int
    private(set) var seasonDay: Int
    private(set) var season: Season

    private let foundationCalendar: Foundation.Calendar

    var currentDate: Date {
        guard seasonDay > 0 else {
            return season.startDate
        }

        date(forSimulationDay: simulationDay)
    }

    var currentWeekday: GameWeekday {
        let weekdayNumber = foundationCalendar.component(
            .weekday,
            from: currentDate
        )

        guard let weekday = GameWeekday(rawValue: weekdayNumber) else {
            preconditionFailure("Unable to determine the current weekday.")
        }

        return weekday
    }

    var currentWeekStartDate: Date {
        let daysSinceMonday =
            (currentWeekday.rawValue - GameWeekday.monday.rawValue + 7) % 7

        return foundationCalendar.date(
            byAdding: .day,
            value: -daysSinceMonday,
            to: currentDate
        )!
    }

    init(
        simulationDay: Int = 0,
        startDate: Date = GameCalendar.defaultStartDate
    ) {
        precondition(simulationDay >= 0, "Simulation day cannot be negative.")

        let calendar = Foundation.Calendar(identifier: .gregorian)
        let resolvedStartDate = Self.firstWeekday(
            onOrAfter: calendar.startOfDay(for: startDate),
            using: calendar
        )

        self.foundationCalendar = calendar
        self.simulationDay = simulationDay
        self.seasonDay = simulationDay
        self.season = Season(
            number: 1,
            startSimulationDay: 1,
            endSimulationDay: nil,
            startDate: resolvedStartDate,
            endDate: nil
        )
    }

    init(
        simulationDay: Int,
        seasonDay: Int,
        season: Season
    ) {
        precondition(simulationDay >= 0, "Simulation day cannot be negative.")
        precondition(seasonDay >= 0, "Season day cannot be negative.")
        precondition(
            season.startSimulationDay >= 1,
            "A season must start on simulation day one or later."
        )
        precondition(
            seasonDay == 0
                || season.startSimulationDay <= simulationDay,
            "An initialized season cannot begin after the current simulation day."
        )

        let calendar = Foundation.Calendar(identifier: .gregorian)
        self.foundationCalendar = calendar
        self.simulationDay = simulationDay
        self.seasonDay = seasonDay
        self.season = season
    }

    func date(forSimulationDay simulationDay: Int) -> Date {
        precondition(
            simulationDay >= season.startSimulationDay,
            "Simulation day cannot precede the current season."
        )

        var date = season.startDate
        var businessDaysRemaining =
            simulationDay - season.startSimulationDay

        while businessDaysRemaining > 0 {
            date = foundationCalendar.date(
                byAdding: .day,
                value: 1,
                to: date
            )!

            if !foundationCalendar.isDateInWeekend(date) {
                businessDaysRemaining -= 1
            }
        }

        return date
    }

    func beginLocation(
        on startDate: Date
    ) {
        locationStartSimulationDay = simulationDay
        locationStartDate = Self.firstWeekday(
            onOrAfter: foundationCalendar.startOfDay(for: startDate),
            using: foundationCalendar
        )
    }

    private static func firstWeekday(
        onOrAfter date: Date,
        using calendar: Foundation.Calendar
    ) -> Date {
        var weekday = date

        while calendar.isDateInWeekend(weekday) {
            weekday = calendar.date(
                byAdding: .day,
                value: 1,
                to: weekday
            )!
        }

        return weekday
    }
}
