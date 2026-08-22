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
    private(set) var locationStartDate: Date
    private(set) var locationStartSimulationDay: Int

    private let foundationCalendar: Foundation.Calendar

    var currentDate: Date {
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
        simulationDay: Int = 1,
        locationStartDate: Date = GameCalendar.defaultStartDate,
        locationStartSimulationDay: Int = 1
    ) {
        precondition(simulationDay >= 1, "Simulation day must be at least 1.")
        precondition(
            locationStartSimulationDay >= 1
                && locationStartSimulationDay <= simulationDay,
            "Location start day must fall within the simulation timeline."
        )

        let calendar = Foundation.Calendar(identifier: .gregorian)
        self.foundationCalendar = calendar
        self.simulationDay = simulationDay
        self.locationStartSimulationDay = locationStartSimulationDay
        self.locationStartDate = Self.firstWeekday(
            onOrAfter: calendar.startOfDay(for: locationStartDate),
            using: calendar
        )
    }

    func date(forSimulationDay simulationDay: Int) -> Date {
        precondition(
            simulationDay >= locationStartSimulationDay,
            "Simulation day cannot precede the current location."
        )

        var date = locationStartDate
        var businessDaysRemaining =
            simulationDay - locationStartSimulationDay

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
