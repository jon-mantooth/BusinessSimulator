//
//  Calendar.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/25/26.
//

import Foundation

struct GameCalendar {
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

    var day: Int
    let startDate: Date

    private let foundationCalendar: Foundation.Calendar

    var currentDate: Date {
        date(forBusinessDay: day)
    }

    init(
        day: Int = 1,
        startDate: Date = GameCalendar.defaultStartDate
    ) {
        precondition(day >= 1, "Business day must be at least 1.")

        let calendar = Foundation.Calendar(identifier: .gregorian)
        self.foundationCalendar = calendar
        self.day = day
        self.startDate = Self.firstWeekday(
            onOrAfter: calendar.startOfDay(for: startDate),
            using: calendar
        )
    }

    func date(forBusinessDay businessDay: Int) -> Date {
        precondition(businessDay >= 1, "Business day must be at least 1.")

        var date = startDate
        var businessDaysRemaining = businessDay - 1

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
