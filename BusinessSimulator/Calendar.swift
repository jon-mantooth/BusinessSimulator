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

struct OperatingPeriodCalendarDate: Codable, Equatable {
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

struct OperatingPeriod: Codable, Equatable {
    let number: Int
    let length: Int?
    let startSimulationDay: Int
    let endSimulationDay: Int?
    let startDate: Date
    let endDate: Date?
}

enum SeasonOfYear {
    case winter
    case spring
    case summer
    case fall

    init(
        date: Date,
        calendar: Foundation.Calendar = Foundation.Calendar(
            identifier: .gregorian
        )
    ) {
        switch calendar.component(.month, from: date) {
        case 12, 1, 2:
            self = .winter
        case 3...5:
            self = .spring
        case 6...8:
            self = .summer
        case 9...11:
            self = .fall
        default:
            preconditionFailure("Unable to resolve the season of year.")
        }
    }
}

@Observable
final class GameCalendar {
    struct RollbackState {
        let simulationDay: Int
        let operatingPeriodDay: Int
        let operatingPeriod: OperatingPeriod?
        let currentDate: Date
    }

    private(set) var simulationDay: Int
    private(set) var operatingPeriodDay: Int
    private(set) var operatingPeriod: OperatingPeriod?
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

    var seasonOfYear: SeasonOfYear {
        SeasonOfYear(
            date: currentDate,
            calendar: foundationCalendar
        )
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
        self.operatingPeriodDay = 0
        self.operatingPeriod = nil
        self.currentDate = calendar.startOfDay(for: currentDate)
    }

    init(
        simulationDay: Int,
        operatingPeriodDay: Int,
        operatingPeriod: OperatingPeriod?,
        currentDate: Date
    ) {
        precondition(simulationDay >= 0, "Simulation day cannot be negative.")
        precondition(
            operatingPeriodDay >= 0,
            "Operating-period day cannot be negative."
        )

        if let operatingPeriod {
            precondition(
                operatingPeriod.startSimulationDay >= 1,
                "An operating period must start on simulation day one or later."
            )
            precondition(
                operatingPeriodDay == 0
                    || operatingPeriod.startSimulationDay <= simulationDay,
                "An initialized operating period cannot begin after the current simulation day."
            )
        } else {
            precondition(
                operatingPeriodDay == 0,
                "A calendar without an operating period must be awaiting initialization."
            )
        }

        let calendar = Foundation.Calendar(identifier: .gregorian)
        self.foundationCalendar = calendar
        self.simulationDay = simulationDay
        self.operatingPeriodDay = operatingPeriodDay
        self.operatingPeriod = operatingPeriod
        self.currentDate = calendar.startOfDay(for: currentDate)
    }

    func date(forSimulationDay simulationDay: Int) -> Date {
        guard let operatingPeriod else {
            preconditionFailure(
                "A simulation date cannot be calculated before the first operating period begins."
            )
        }

        precondition(
            simulationDay >= operatingPeriod.startSimulationDay,
            "Simulation day cannot precede the current operating period."
        )

        var date = operatingPeriod.startDate
        var businessDaysRemaining =
            simulationDay - operatingPeriod.startSimulationDay

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

        if let operatingPeriod {
            operatingPeriodDay += 1

            if let operatingPeriodLength = operatingPeriod.length,
               operatingPeriodDay > operatingPeriodLength {
                operatingPeriodDay = 0
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

    func captureRollbackState() -> RollbackState {
        RollbackState(
            simulationDay: simulationDay,
            operatingPeriodDay: operatingPeriodDay,
            operatingPeriod: operatingPeriod,
            currentDate: currentDate
        )
    }

    func revert(to state: RollbackState) {
        simulationDay = state.simulationDay
        operatingPeriodDay = state.operatingPeriodDay
        operatingPeriod = state.operatingPeriod
        currentDate = state.currentDate
    }

    func prepareForNewOperatingPeriod() {
        simulationDay += 1
        operatingPeriodDay = 0
    }

    func beginOperatingPeriod(
        product: Product
    ) {
        let nextOperatingPeriodNumber =
            (operatingPeriod?.number ?? 0) + 1
        let startSimulationDay = max(1, simulationDay)

        if operatingPeriod == nil {
            let startDate = Self.firstWeekday(
                onOrAfter: currentDate,
                using: foundationCalendar
            )

            simulationDay = startSimulationDay
            operatingPeriodDay = 1
            currentDate = startDate
            operatingPeriod = OperatingPeriod(
                number: nextOperatingPeriodNumber,
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
            for: product.recurringOperatingPeriodStartDate,
            year: currentYear
        )
        startDate = Self.firstWeekday(
            onOrAfter: startDate,
            using: foundationCalendar
        )

        if startDate < comparisonDate {
            startDate = resolvedDate(
                for: product.recurringOperatingPeriodStartDate,
                year: currentYear + 1
            )
            startDate = Self.firstWeekday(
                onOrAfter: startDate,
                using: foundationCalendar
            )
        }

        let startYear = foundationCalendar.component(.year, from: startDate)
        var endDate = resolvedDate(
            for: product.recurringOperatingPeriodEndDate,
            year: startYear
        )

        if endDate < startDate {
            endDate = resolvedDate(
                for: product.recurringOperatingPeriodEndDate,
                year: startYear + 1
            )
        }

        endDate = Self.lastWeekday(
            onOrBefore: endDate,
            using: foundationCalendar
        )

        let operatingPeriodLength = businessDayCount(
            from: startDate,
            through: endDate
        )

        simulationDay = startSimulationDay
        operatingPeriodDay = 1
        currentDate = startDate
        operatingPeriod = OperatingPeriod(
            number: nextOperatingPeriodNumber,
            length: operatingPeriodLength,
            startSimulationDay: startSimulationDay,
            endSimulationDay:
                startSimulationDay + operatingPeriodLength - 1,
            startDate: startDate,
            endDate: endDate
        )
    }

    private func resolvedDate(
        for calendarDate: OperatingPeriodCalendarDate,
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
                "Unable to resolve operating-period date for \(calendarDate.month)/\(calendarDate.day)/\(year)."
            )
        }

        return foundationCalendar.startOfDay(for: date)
    }

    private func businessDayCount(
        from startDate: Date,
        through endDate: Date
    ) -> Int {
        precondition(
            startDate <= endDate,
            "An operating period cannot end before it starts."
        )

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
