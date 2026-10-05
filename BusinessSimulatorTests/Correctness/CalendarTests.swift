import Foundation
import Testing
@testable import BusinessSimulator

struct CalendarTests {}

// MARK: - Operating Calendar

extension CalendarTests {

    @Test
    func initializationPreservesSuppliedStartingDate() {
        let startingDate = makeDate(year: 2031, month: 7, day: 9)
        let calendar = GameCalendar(
            simulationDay: 12,
            currentDate: startingDate
        )

        #expect(calendar.simulationDay == 12)
        #expect(calendar.currentDate == startingDate)
        #expect(calendar.operatingPeriodDay == 0)
        #expect(calendar.operatingPeriod == nil)
    }

    @Test
    func phaseOneContinuesWithoutAnOperatingPeriodEnd() {
        let product = ProductCatalog().products[0]
        let calendar = GameCalendar(
            simulationDay: 1,
            currentDate: makeDate(year: 2026, month: 4, day: 1)
        )
        calendar.beginOperatingPeriod(product: product)

        let advances = 300
        for _ in 0..<advances {
            calendar.advanceDay()
        }

        #expect(calendar.operatingPeriod?.length == nil)
        #expect(calendar.operatingPeriod?.endDate == nil)
        #expect(calendar.simulationDay == 1 + advances)
        #expect(calendar.operatingPeriodDay == 1 + advances)
    }

    @Test
    func recurringOperatingPeriodUsesProductsConfiguredWindow() throws {
        let product = ProductCatalog().products[0]
        let calendar = beginRecurringOperatingPeriod(
            product: product,
            year: 2030
        )
        let period = try #require(calendar.operatingPeriod)
        let foundationCalendar = gregorianCalendar()

        #expect(
            foundationCalendar.component(.month, from: period.startDate)
                == product.recurringOperatingPeriodStartDate.month
        )
        #expect(
            foundationCalendar.component(.month, from: period.endDate!)
                == product.recurringOperatingPeriodEndDate.month
        )
        #expect(period.length != nil)
        #expect(period.endSimulationDay != nil)
    }

    @Test
    func weekendStartingDateMovesToFollowingWeekday() {
        let product = ProductCatalog().products[0]
        let saturday = makeDate(year: 2026, month: 4, day: 4)
        let calendar = GameCalendar(
            simulationDay: 1,
            currentDate: saturday
        )

        calendar.beginOperatingPeriod(product: product)

        #expect(calendar.currentWeekday == .monday)
        #expect(calendar.currentDate > saturday)
    }

    @Test(arguments: [2029, 2030])
    func recurringWeekendStartMovesToFollowingMonday(year: Int) {
        let pie = ProductCatalog().product(for: .pies)
        let configuredStartDate = makeDate(
            year: year,
            month: pie.recurringOperatingPeriodStartDate.month,
            day: pie.recurringOperatingPeriodStartDate.day
        )
        let calendar = beginRecurringOperatingPeriod(
            product: pie,
            year: year
        )

        #expect(calendar.currentWeekday == .monday)
        #expect(calendar.currentDate > configuredStartDate)
    }

    @Test
    func recurringPeriodWithSaturdayEndDateStopsOnFriday() throws {
        let pie = ProductCatalog().product(for: .pies)
        let calendar = beginRecurringOperatingPeriod(
            product: pie,
            year: 2024
        )
        let endDate = try #require(calendar.operatingPeriod?.endDate)

        #expect(weekday(for: endDate) == .friday)
        try verifyOperatingPeriodEndsWithoutAnExtraActiveDay(calendar)
    }

    @Test
    func recurringPeriodWithSundayEndDateStopsOnFriday() throws {
        let pie = ProductCatalog().product(for: .pies)
        let calendar = beginRecurringOperatingPeriod(
            product: pie,
            year: 2025
        )
        let endDate = try #require(calendar.operatingPeriod?.endDate)

        #expect(weekday(for: endDate) == .friday)
        try verifyOperatingPeriodEndsWithoutAnExtraActiveDay(calendar)
    }

    @Test
    func recurringOperatingPeriodNeverCreatesActiveDayAfterEndDate() throws {
        let product = ProductCatalog().products[0]
        let calendar = beginRecurringOperatingPeriod(
            product: product,
            year: 2030
        )
        let period = try #require(calendar.operatingPeriod)
        let periodLength = try #require(period.length)
        let endDate = try #require(period.endDate)

        for _ in 1..<periodLength {
            #expect(calendar.operatingPeriodDay > 0)
            #expect(calendar.currentDate <= endDate)
            calendar.advanceDay()
        }

        #expect(calendar.operatingPeriodDay == periodLength)
        #expect(calendar.currentDate == endDate)

        calendar.advanceDay()

        #expect(calendar.operatingPeriodDay == 0)
    }

    @Test
    func nextRecurringPeriodMovesForwardWithoutResettingSimulationDay() throws {
        let product = ProductCatalog().products[0]
        let calendar = beginRecurringOperatingPeriod(
            product: product,
            year: 2030
        )
        let previousPeriod = try #require(calendar.operatingPeriod)
        let periodLength = try #require(previousPeriod.length)

        for _ in 0..<periodLength {
            calendar.advanceDay()
        }

        let simulationDayBeforeNextPeriod = calendar.simulationDay

        calendar.beginOperatingPeriod(product: product)

        let nextPeriod = try #require(calendar.operatingPeriod)
        #expect(nextPeriod.number == previousPeriod.number + 1)
        #expect(nextPeriod.startDate > previousPeriod.startDate)
        #expect(calendar.simulationDay == simulationDayBeforeNextPeriod)
        #expect(calendar.operatingPeriodDay == 1)
    }

    @Test
    func relocationDayAdvancesSimulationDayAndAwaitsDestinationPeriod() {
        let calendar = GameCalendar(
            simulationDay: 47,
            currentDate: makeDate(year: 2030, month: 5, day: 6)
        )

        calendar.prepareForNewOperatingPeriod()

        #expect(calendar.simulationDay == 48)
        #expect(calendar.operatingPeriodDay == 0)
    }

    @Test
    func rollbackRestoresCompleteCalendarState() {
        let product = ProductCatalog().products[0]
        let calendar = GameCalendar(
            simulationDay: 1,
            currentDate: makeDate(year: 2026, month: 4, day: 1)
        )
        calendar.beginOperatingPeriod(product: product)
        let originalState = calendar.captureRollbackState()

        calendar.advanceDay()
        calendar.advanceDay()
        calendar.revert(to: originalState)

        #expect(calendar.simulationDay == originalState.simulationDay)
        #expect(
            calendar.operatingPeriodDay
                == originalState.operatingPeriodDay
        )
        #expect(calendar.operatingPeriod == originalState.operatingPeriod)
        #expect(calendar.currentDate == originalState.currentDate)
    }
}

private func verifyOperatingPeriodEndsWithoutAnExtraActiveDay(
    _ calendar: GameCalendar
) throws {
    let period = try #require(calendar.operatingPeriod)
    let periodLength = try #require(period.length)
    let endDate = try #require(period.endDate)

    for _ in 1..<periodLength {
        calendar.advanceDay()
    }

    #expect(calendar.operatingPeriodDay == periodLength)
    #expect(calendar.currentDate == endDate)

    calendar.advanceDay()

    #expect(calendar.operatingPeriodDay == 0)
}

private func beginRecurringOperatingPeriod(
    product: Product,
    year: Int
) -> GameCalendar {
    let calendar = GameCalendar(
        simulationDay: 1,
        currentDate: makeDate(year: year, month: 1, day: 2)
    )

    calendar.beginOperatingPeriod(product: product)
    calendar.prepareForNewOperatingPeriod()
    calendar.beginOperatingPeriod(product: product)

    return calendar
}

private func makeDate(
    year: Int,
    month: Int,
    day: Int
) -> Date {
    gregorianCalendar().date(
        from: DateComponents(
            year: year,
            month: month,
            day: day
        )
    )!
}

private func gregorianCalendar() -> Foundation.Calendar {
    Foundation.Calendar(identifier: .gregorian)
}

private func weekday(for date: Date) -> GameWeekday? {
    GameWeekday(
        rawValue: gregorianCalendar().component(.weekday, from: date)
    )
}
