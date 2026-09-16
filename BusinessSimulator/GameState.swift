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
    case invalidEquipmentData
}

@Observable
final class GameState {
    private static let startingDay = 1

    var finance: Finance!
    var calendar: GameCalendar!
    var weather: WeatherState!

    var productState: ProductState?
    var reputation: BusinessReputationState?
    var advertisementState: AdvertisementState?
    var equipmentState: EquipmentState?
    var businessHours: BusinessHours?
    var production: Production?
    var marketing: MarketingDepartment?
    var environment: EnvironmentDepartment?
    var pendingBusinessEvents: [BusinessEvent] = []
    var pendingUpgrades: [PendingUpgrade] = []
    var upgradeTracker = UpgradeTracker()
    var simulationSummary : SimulationSummary = SimulationSummary()

    // Total cost of pending outflows. This is helpful in getting the displayed balance correct
    // when restoring game and also when keeping up with ingredients that are in the car tbut not yet
    // purchased
    var pendingOutflowTotal: Double {
        pendingBusinessEvents.reduce(0.0) {
            total, businessEvent in
            guard let transaction = businessEvent.financialTransaction,
                  transaction.direction == .outflow else {
                return total
            }

            return total + transaction.amount
        }
    }

    func movePendingBusinessEvents(
        to summary: DaySummary
    ) {
        for businessEvent in pendingBusinessEvents {
            summary.businessEvents.append(businessEvent)

            if let transaction = businessEvent.financialTransaction,
               transaction.direction == .outflow {
                summary.cashFlowCosts.append(
                    Cost(
                        name: businessEvent.title,
                        amount: transaction.amount
                    )
                )
            }
        }

        pendingBusinessEvents.removeAll()
    }

    /// Routes delayed upgrades to the state responsible for applying them.
    func applyPendingUpgrades() {
        for pendingUpgrade in pendingUpgrades {
            switch pendingUpgrade {
            case let .ingredient(ingredientUpgrade):
                productState!.applyIngredientUpgrade(
                    ingredientUpgrade
                )
            }
        }

        pendingUpgrades.removeAll()
    }
    
    func initializeBusiness(
        product: Product
    ) {
        self.pendingBusinessEvents = []
        self.pendingUpgrades = []
        self.calendar = GameCalendar(simulationDay: Self.startingDay)
        self.weather = WeatherState()
        self.upgradeTracker = UpgradeTracker()

        let productState = ProductState(
            product: product,
            currentDay: self.calendar.simulationDay,
            price: 0.00
        )
        
        self.productState = productState
        self.finance = Finance(
            product: product,
            productInventoryStates: productState.productInventoryStates
        )
        self.reputation = BusinessReputationState()
        self.businessHours = BusinessHours(
            openingTime: BusinessTime(hour: 9, minute: 0),
            closingTime: BusinessTime(hour: 17, minute: 0)
        )

        let advertisementCatalog = AdvertisementCatalog(product: product)
        self.advertisementState = AdvertisementState(
            tiers: advertisementCatalog.tiersByProduct[product.id]!,
            activeAdvertisement: ActiveAdvertisement(
                advertisement: advertisementCatalog.noAdvertisement,
                tierLevel: 0
            )
        )

        let equipmentCatalog = EquipmentCatalog()
        self.equipmentState = EquipmentState(
            primaryTiers: equipmentCatalog.primaryTiers(for: product),
            secondaryEquipmentCatalog:
                equipmentCatalog.secondaryEquipment(for: product)
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
        let productCatalog = ProductCatalog()

        guard let product = productCatalog.products.first(
            where: { $0.id == gameSave.productState.productID }
        ) else {
            throw GameStateRestoreError.productNotFound(
                gameSave.productState.productID
            )
        }

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

        let savedInventoryIDs = gameSave.inventoryStates.map(\.inventoryID)
        guard Set(savedInventoryIDs).count == savedInventoryIDs.count else {
            throw GameStateRestoreError.invalidInventoryData
        }

        let restoredProductState = ProductState(
            product: product,
            currentDay: calendar.simulationDay,
            price: gameSave.productState.price
        )

        let restoredInventoryIDs =
            restoredProductState.allProductInventoryStates.map(\.id)
        guard Set(restoredInventoryIDs) == Set(savedInventoryIDs),
              restoredInventoryIDs.count == savedInventoryIDs.count else {
            throw GameStateRestoreError.invalidInventoryData
        }

        for productInventoryState in
            restoredProductState.allProductInventoryStates {
            guard let savedInventory = gameSave.inventoryStates.first(
                where: {
                    $0.inventoryID == productInventoryState
                        .productInventory.inventory.id
                }
            ) else {
                throw GameStateRestoreError.invalidInventoryData
            }

            productInventoryState.inventoryByAge.inventoryByPurchaseDay =
                savedInventory.inventoryByPurchaseDay
            productInventoryState.recipeAmountMultiplier =
                savedInventory.recipeAmountMultiplier
            productInventoryState.lifespanMultiplier =
                savedInventory.lifespanMultiplier
            productInventoryState.isActive = savedInventory.isActive
        }

        guard restoredProductState.allProductInventoryStates.count
                == gameSave.inventoryStates.count else {
            throw GameStateRestoreError.invalidInventoryData
        }

        productState = restoredProductState

        finance = Finance(
            product: product,
            productInventoryStates:
                restoredProductState.productInventoryStates,
            balance: gameSave.finance.actualBalance
        )

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

        let advertisementCatalog = AdvertisementCatalog(product: product)
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

        let equipmentCatalog = EquipmentCatalog()
        let secondaryEquipmentCatalog =
            equipmentCatalog.secondaryEquipment(for: product)

        let primaryTiers = equipmentCatalog.primaryTiers(for: product)
        let savedActiveEquipment =
            gameSave.equipmentState.activePrimaryEquipment
        let savedOwnedEquipment =
            gameSave.equipmentState.ownedSecondaryEquipment

        guard primaryTiers.contains(where: { tier in
            tier.level == savedActiveEquipment.tierLevel
                && tier.equipment.contains {
                    $0.id == savedActiveEquipment.id
                }
        }) else {
            throw GameStateRestoreError.invalidEquipmentData
        }

        let ownedEquipmentIDs = savedOwnedEquipment.equipment.map(\.id)
        let secondaryCatalogIDs = Set(
            secondaryEquipmentCatalog.equipment.map(\.id)
        )
        guard Set(ownedEquipmentIDs).count == ownedEquipmentIDs.count,
              ownedEquipmentIDs.allSatisfy({
                  secondaryCatalogIDs.contains($0)
              }) else {
            throw GameStateRestoreError.invalidEquipmentData
        }

        equipmentState = EquipmentState(
            primaryTiers: primaryTiers,
            secondaryEquipmentCatalog: secondaryEquipmentCatalog,
            activePrimaryEquipment: savedActiveEquipment,
            ownedSecondaryEquipment: savedOwnedEquipment
        )

        pendingBusinessEvents = gameSave.pendingBusinessEvents
        pendingUpgrades = gameSave.pendingUpgrades

        finance.displayedBalance = finance.actualBalance - pendingOutflowTotal

        upgradeTracker = UpgradeTracker(
            lastUpgradeDays: gameSave.upgradeTracker.lastUpgradeDays
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
