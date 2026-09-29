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

struct SeasonCalendarDate: Codable, Equatable {
    let month: Int
    let day: Int

    init(
        month: Int,
        day: Int
    ) {
        precondition((1...12).contains(month), "Month must be between 1 and 12.")
        precondition((1...31).contains(day), "Day must be between 1 and 31.")

        self.month = month
        self.day = day
    }
}

struct Season: Codable, Equatable {
    let number: Int
    let length: Int?
    let startSimulationDay: Int
    let endSimulationDay: Int?
    let startDate: Date
    let endDate: Date?
}

@Observable
final class GameCalendar {
    private(set) var simulationDay: Int
    private(set) var seasonDay: Int
    private(set) var season: Season?
    private(set) var currentDate: Date

    private let foundationCalendar: Foundation.Calendar

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
        currentDate: Date = Foundation.Calendar(
            identifier: .gregorian
        ).date(
            from: DateComponents(
                year: 2026,
                month: 4,
                day: 1
            )
        )!
    ) {
        precondition(simulationDay >= 0, "Simulation day cannot be negative.")

        let calendar = Foundation.Calendar(identifier: .gregorian)

        self.foundationCalendar = calendar
        self.simulationDay = simulationDay
        self.seasonDay = 0
        self.season = nil
        self.currentDate = calendar.startOfDay(for: currentDate)
    }

    init(
        simulationDay: Int,
        seasonDay: Int,
        season: Season?,
        currentDate: Date
    ) {
        precondition(simulationDay >= 0, "Simulation day cannot be negative.")
        precondition(seasonDay >= 0, "Season day cannot be negative.")

        if let season {
            precondition(
                season.startSimulationDay >= 1,
                "A season must start on simulation day one or later."
            )
            precondition(
                seasonDay == 0
                    || season.startSimulationDay <= simulationDay,
                "An initialized season cannot begin after the current simulation day."
            )
        } else {
            precondition(
                seasonDay == 0,
                "A calendar without a season must be awaiting initialization."
            )
        }

        let calendar = Foundation.Calendar(identifier: .gregorian)
        self.foundationCalendar = calendar
        self.simulationDay = simulationDay
        self.seasonDay = seasonDay
        self.season = season
        self.currentDate = calendar.startOfDay(for: currentDate)
    }

    func date(forSimulationDay simulationDay: Int) -> Date {
        guard let season else {
            preconditionFailure(
                "A simulation date cannot be calculated before the first season begins."
            )
        }

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

    func advanceDay() {
        simulationDay += 1

        if let season {
            seasonDay += 1

            if let seasonLength = season.length,
               seasonDay > seasonLength {
                seasonDay = 0
            }
        }

        let followingDate = foundationCalendar.date(
            byAdding: .day,
            value: 1,
            to: currentDate
        )!
        currentDate = Self.firstWeekday(
            onOrAfter: followingDate,
            using: foundationCalendar
        )
    }

    func beginSeason(
        product: Product
    ) {
        let nextSeasonNumber = (season?.number ?? 0) + 1
        let startSimulationDay = max(1, simulationDay)

        if season == nil {
            let startDate = Self.firstWeekday(
                onOrAfter: currentDate,
                using: foundationCalendar
            )

            simulationDay = startSimulationDay
            seasonDay = 1
            currentDate = startDate
            season = Season(
                number: nextSeasonNumber,
                length: nil,
                startSimulationDay: startSimulationDay,
                endSimulationDay: nil,
                startDate: startDate,
                endDate: nil
            )
            return
        }

        let comparisonDate = foundationCalendar.startOfDay(for: currentDate)
        let currentYear = foundationCalendar.component(
            .year,
            from: comparisonDate
        )
        var startDate = resolvedDate(
            for: product.seasonTwoStartDate,
            year: currentYear
        )
        startDate = Self.firstWeekday(
            onOrAfter: startDate,
            using: foundationCalendar
        )

        if startDate < comparisonDate {
            startDate = resolvedDate(
                for: product.seasonTwoStartDate,
                year: currentYear + 1
            )
            startDate = Self.firstWeekday(
                onOrAfter: startDate,
                using: foundationCalendar
            )
        }

        let startYear = foundationCalendar.component(.year, from: startDate)
        var endDate = resolvedDate(
            for: product.seasonTwoEndDate,
            year: startYear
        )

        if endDate < startDate {
            endDate = resolvedDate(
                for: product.seasonTwoEndDate,
                year: startYear + 1
            )
        }

        endDate = Self.lastWeekday(
            onOrBefore: endDate,
            using: foundationCalendar
        )

        let seasonLength = businessDayCount(
            from: startDate,
            through: endDate
        )

        simulationDay = startSimulationDay
        seasonDay = 1
        currentDate = startDate
        season = Season(
            number: nextSeasonNumber,
            length: seasonLength,
            startSimulationDay: startSimulationDay,
            endSimulationDay: startSimulationDay + seasonLength - 1,
            startDate: startDate,
            endDate: endDate
        )
    }

    private func resolvedDate(
        for calendarDate: SeasonCalendarDate,
        year: Int
    ) -> Date {
        guard let date = foundationCalendar.date(
            from: DateComponents(
                year: year,
                month: calendarDate.month,
                day: calendarDate.day
            )
        ) else {
            preconditionFailure(
                "Unable to resolve season date for \(calendarDate.month)/\(calendarDate.day)/\(year)."
            )
        }

        return foundationCalendar.startOfDay(for: date)
    }

    private func businessDayCount(
        from startDate: Date,
        through endDate: Date
    ) -> Int {
        precondition(startDate <= endDate, "A season cannot end before it starts.")

        var date = startDate
        var count = 0

        while date <= endDate {
            if !foundationCalendar.isDateInWeekend(date) {
                count += 1
            }

            date = foundationCalendar.date(
                byAdding: .day,
                value: 1,
                to: date
            )!
        }

        return count
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

    private static func lastWeekday(
        onOrBefore date: Date,
        using calendar: Foundation.Calendar
    ) -> Date {
        var weekday = date

        while calendar.isDateInWeekend(weekday) {
            weekday = calendar.date(
                byAdding: .day,
                value: -1,
                to: weekday
            )!
        }

        return weekday
    }
}
