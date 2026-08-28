//
//  GameState.swift
//  HelloSwift
//
//  Created by jon mantooth on 7/16/26.
//

import Foundation
import Observation

enum GameStateRestoreError: Error {
    case productNotFound(ProductID)
    case invalidInventoryData
    case invalidAdvertisementData
}

@Observable
final class GameState {
    private static let startingBalance = 10_000.0
    private static let startingDay = 1

    var finance: Finance!
    var calendar: GameCalendar!
    var weather: WeatherState!

    var productState: ProductState?
    var inventoryStates: [InventoryState] = []
    var reputation: BusinessReputationState?
    var advertisementState: AdvertisementState?
    var businessHours: BusinessHours?
    var production: Production?
    var marketing: MarketingDepartment?
    var environment: EnvironmentDepartment?
    var simulationSummary : SimulationSummary = SimulationSummary()
    
    func initializeBusiness(
        product: Product
    ) {
        self.finance = Finance(
            actualBalance: Self.startingBalance,
            displayedBalance: Self.startingBalance
        )
        self.calendar = GameCalendar(simulationDay: Self.startingDay)
        self.weather = WeatherState()

        let productState = ProductState(
            product: product,
            price: 0.00
        )
        
        let inventoryStates = product.productInventories.map {
            InventoryState(
                inventory: $0.inventory,
                currentDay: self.calendar.simulationDay
            )
        }

        self.productState = productState
        self.inventoryStates = inventoryStates
        self.reputation = BusinessReputationState()
        self.businessHours = BusinessHours(
            openingTime: BusinessTime(hour: 9, minute: 0),
            closingTime: BusinessTime(hour: 17, minute: 0)
        )

        let advertisementCatalog = AdvertisementCatalog()
        self.advertisementState = AdvertisementState(
            tiers: advertisementCatalog.tiersByProduct[product.id]!,
            activeAdvertisement: ActiveAdvertisement(
                advertisement: advertisementCatalog.noAdvertisement,
                tierLevel: 0
            )
        )
        
        let dimensions = BusinessDimensions.create(
            gameState: self
        )

        let production = Production(
            dimensions: dimensions.production
        )

        let marketing = MarketingDepartment(
            dimensions: dimensions.marketing
        )

        let environment = EnvironmentDepartment(
            dimensions: dimensions.environment
        )

        self.production = production
        self.marketing = marketing
        self.environment = environment

        self.weather.generateWeeklyForecast(
            starting: self.calendar.currentWeekStartDate
        )
    }

    func restoreBusiness(
        from gameSave: GameSave
    ) throws {
        guard let product = ProductCatalog().products.first(
            where: { $0.id == gameSave.productState.productID }
        ) else {
            throw GameStateRestoreError.productNotFound(
                gameSave.productState.productID
            )
        }

        finance = Finance(
            actualBalance: gameSave.finance.actualBalance,
            displayedBalance: gameSave.finance.actualBalance
        )

        calendar = GameCalendar(
            simulationDay: gameSave.calendar.simulationDay,
            locationStartDate: gameSave.calendar.locationStartDate,
            locationStartSimulationDay:
                gameSave.calendar.locationStartSimulationDay
        )

        weather = WeatherState(
            weeklyForecast: gameSave.weather.weeklyForecast.map {
                DailyWeather(
                    date: $0.date,
                    highTemperature: $0.highTemperature,
                    lowTemperature: $0.lowTemperature,
                    condition: $0.condition
                )
            }
        )

        productState = ProductState(
            product: product,
            price: gameSave.productState.price
        )

        let savedInventoryIDs = gameSave.inventoryStates.map(\.inventoryID)
        guard Set(savedInventoryIDs).count == savedInventoryIDs.count else {
            throw GameStateRestoreError.invalidInventoryData
        }

        inventoryStates = try product.productInventories.map {
            productInventory in
            guard let savedInventory = gameSave.inventoryStates.first(
                where: { $0.inventoryID == productInventory.inventory.id }
            ) else {
                throw GameStateRestoreError.invalidInventoryData
            }

            let inventoryState = InventoryState(
                inventory: productInventory.inventory,
                currentDay: calendar.simulationDay
            )
            inventoryState.inventoryByAge.inventoryByPurchaseDay =
                savedInventory.inventoryByPurchaseDay

            return inventoryState
        }

        guard inventoryStates.count == gameSave.inventoryStates.count else {
            throw GameStateRestoreError.invalidInventoryData
        }

        reputation = BusinessReputationState(
            overallReputation: gameSave.reputation.overallReputation,
            overallFactorScores: gameSave.reputation.overallFactorScores,
            recentOverallReputations:
                gameSave.reputation.recentOverallReputations,
            hasRatings: gameSave.reputation.hasRatings
        )

        businessHours = BusinessHours(
            openingTime: BusinessTime(hour: 9, minute: 0),
            closingTime: BusinessTime(hour: 17, minute: 0)
        )

        let advertisementCatalog = AdvertisementCatalog()
        let advertisementTiers =
            advertisementCatalog.tiersByProduct[product.id]!
        let activeAdvertisement =
            gameSave.advertisementState.activeAdvertisement

        guard advertisementTiers.contains(where: { tier in
            tier.level == activeAdvertisement.tierLevel
        }) else {
            throw GameStateRestoreError.invalidAdvertisementData
        }

        advertisementState = AdvertisementState(
            tiers: advertisementTiers,
            activeAdvertisement: activeAdvertisement
        )

        simulationSummary = SimulationSummary()
        simulationSummary.daySummaries = gameSave.summaries.map {
            savedSummary in
            let summary = DaySummary(
                day: savedSummary.day,
                startingBalance: savedSummary.startingBalance
            )
            summary.demandedSales = savedSummary.demandedSales
            summary.sales = savedSummary.sales
            summary.revenue = savedSummary.revenue
            summary.economicCosts = savedSummary.economicCosts.map {
                Cost(name: $0.name, amount: $0.amount)
            }
            summary.cashFlowCosts = savedSummary.cashFlowCosts.map {
                Cost(name: $0.name, amount: $0.amount)
            }
            summary.businessEvents = savedSummary.businessEvents
            summary.dailyReputationResult =
                savedSummary.dailyReputationResult

            for section in savedSummary.sections {
                for note in section.notes {
                    summary.addNote(
                        sectionName: section.name,
                        note: note
                    )
                }
            }

            return summary
        }

        let dimensions = BusinessDimensions.create(gameState: self)
        production = Production(dimensions: dimensions.production)
        marketing = MarketingDepartment(dimensions: dimensions.marketing)
        environment = EnvironmentDepartment(
            dimensions: dimensions.environment
        )
    }
}
