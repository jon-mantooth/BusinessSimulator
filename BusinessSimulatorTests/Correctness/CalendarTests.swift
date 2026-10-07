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

// MARK: - Operating Period Initialization

extension CalendarTests {

    @Test
    func beginningNeededOperatingPeriodCreatesPlayableFirstDayAndForecast() {
        let gameState = initializedGameState(productID: .pies)

        #expect(gameState.calendar.operatingPeriodDay == 0)
        #expect(gameState.weather.weeklyForecast.isEmpty)

        gameState.beginOperatingPeriodIfNeeded()

        #expect(gameState.calendar.operatingPeriodDay == 1)
        #expect(gameState.calendar.operatingPeriod != nil)
        #expect(gameState.weather.weeklyForecast.count == 5)
        #expect(
            gameState.weather.weeklyForecast.first?.date
                == gameState.calendar.currentWeekStartDate
        )
    }

    @Test
    func beginningOperatingPeriodClearsOnlyActiveIngredientQuantities() throws {
        let gameState = initializedGameState(productID: .hotDogs)
        let productState = try #require(gameState.productState)
        let activeStates = productState.productInventoryStates
        let inactiveStates = productState.allProductInventoryStates.filter {
            !$0.isActive
        }

        #expect(!activeStates.isEmpty)
        #expect(!inactiveStates.isEmpty)

        for state in activeStates {
            state.inventoryByAge.inventoryByPurchaseDay = [1: 2]
        }
        for state in inactiveStates {
            state.inventoryByAge.inventoryByPurchaseDay = [1: 3]
        }

        gameState.beginOperatingPeriodIfNeeded()

        for state in activeStates {
            #expect(state.inventoryByAge.inventoryByPurchaseDay.isEmpty)
            #expect(
                state.inventoryByAge.currentDay
                    == gameState.calendar.simulationDay
            )
        }
        for state in inactiveStates {
            #expect(state.inventoryByAge.inventoryByPurchaseDay == [1: 3])
            #expect(!state.isActive)
        }
    }

    @Test
    func beginningOperatingPeriodPreservesIngredientConfiguration() throws {
        let gameState = initializedGameState(productID: .hotDogs)
        let productState = try #require(gameState.productState)
        let replacementUpgrade = try #require(
            EquipmentCatalog().meatGrinder.ingredientUpgrade
        )
        productState.applyIngredientUpgrade(replacementUpgrade)
        let activeState = try #require(
            productState.productInventoryStates.first
        )
        activeState.recipeAmountMultiplier = 0.8
        activeState.lifespanMultiplier = 1.5

        let expectedConfiguration = Dictionary(
            uniqueKeysWithValues:
                productState.allProductInventoryStates.map { state in
                    (
                        state.id,
                        IngredientConfiguration(
                            recipeAmountMultiplier:
                                state.recipeAmountMultiplier,
                            lifespanMultiplier: state.lifespanMultiplier,
                            isActive: state.isActive
                        )
                    )
                }
        )

        gameState.beginOperatingPeriodIfNeeded()

        for state in productState.allProductInventoryStates {
            let expected = try #require(expectedConfiguration[state.id])
            #expect(
                state.recipeAmountMultiplier
                    == expected.recipeAmountMultiplier
            )
            #expect(state.lifespanMultiplier == expected.lifespanMultiplier)
            #expect(state.isActive == expected.isActive)
        }
    }

    @Test
    func beginningOperatingPeriodResetsUpgradeTracker() {
        let gameState = initializedGameState(productID: .pies)
        gameState.upgradeTracker.recordUpgrade(
            on: gameState.calendar.simulationDay,
            weekStarting: gameState.calendar.currentWeekStartDate
        )

        gameState.beginOperatingPeriodIfNeeded()

        #expect(gameState.upgradeTracker.lastUpgradeSimulationDay == nil)
        #expect(gameState.upgradeTracker.lastUpgradeWeekStartDate == nil)
    }

    @Test
    func beginningOperatingPeriodAgainDuringActivePeriodDoesNothing() throws {
        let gameState = initializedGameState(productID: .pies)
        gameState.beginOperatingPeriodIfNeeded()

        let inventoryState = try #require(
            gameState.productState?.productInventoryStates.first
        )
        inventoryState.inventoryByAge.inventoryByPurchaseDay = [
            gameState.calendar.simulationDay: 4
        ]
        gameState.upgradeTracker.recordUpgrade(
            on: gameState.calendar.simulationDay,
            weekStarting: gameState.calendar.currentWeekStartDate
        )

        let simulationDay = gameState.calendar.simulationDay
        let operatingPeriodDay = gameState.calendar.operatingPeriodDay
        let currentDate = gameState.calendar.currentDate
        let forecastDates = gameState.weather.weeklyForecast.map(\.date)
        let forecastHighs = gameState.weather.weeklyForecast.map(
            \.highTemperature
        )
        let forecastLows = gameState.weather.weeklyForecast.map(
            \.lowTemperature
        )
        let forecastConditions = gameState.weather.weeklyForecast.map(
            \.condition
        )

        gameState.beginOperatingPeriodIfNeeded()

        #expect(gameState.calendar.simulationDay == simulationDay)
        #expect(gameState.calendar.operatingPeriodDay == operatingPeriodDay)
        #expect(gameState.calendar.currentDate == currentDate)
        #expect(gameState.weather.weeklyForecast.map(\.date) == forecastDates)
        #expect(
            gameState.weather.weeklyForecast.map(\.highTemperature)
                == forecastHighs
        )
        #expect(
            gameState.weather.weeklyForecast.map(\.lowTemperature)
                == forecastLows
        )
        #expect(
            gameState.weather.weeklyForecast.map(\.condition)
                == forecastConditions
        )
        #expect(
            inventoryState.inventoryByAge.inventoryByPurchaseDay
                == [simulationDay: 4]
        )
        #expect(
            gameState.upgradeTracker.lastUpgradeSimulationDay
                == simulationDay
        )
    }
}

private struct IngredientConfiguration {
    let recipeAmountMultiplier: Double
    let lifespanMultiplier: Double
    let isActive: Bool
}

private func initializedGameState(productID: ProductID) -> GameState {
    let gameState = GameState()
    gameState.initializeBusiness(
        product: ProductCatalog().product(for: productID)
    )
    return gameState
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
