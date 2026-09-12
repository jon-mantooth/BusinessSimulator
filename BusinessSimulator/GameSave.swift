import Foundation

struct GameSave: Codable {
    static let currentSchemaVersion = 6

    let schemaVersion: Int
    let finance: FinanceSave
    let calendar: CalendarSave
    let weather: WeatherSave
    let productState: ProductStateSave
    let inventoryStates: [InventoryStateSave]
    let reputation: ReputationSave
    let advertisementState: AdvertisementStateSave
    let equipmentState: EquipmentStateSave
    let pendingBusinessEvents: [BusinessEvent]
    let pendingUpgrades: [PendingUpgrade]
    let upgradeTracker: UpgradeTrackerSave
    let summaries: [DaySummarySave]
}

struct FinanceSave: Codable {
    let actualBalance: Double
}

struct CalendarSave: Codable {
    let simulationDay: Int
    let locationStartDate: Date
    let locationStartSimulationDay: Int
}

struct WeatherSave: Codable {
    let weeklyForecast: [DailyWeatherSave]
}

struct DailyWeatherSave: Codable {
    let date: Date
    let highTemperature: Int
    let lowTemperature: Int
    let condition: WeatherCondition
}

struct ProductStateSave: Codable {
    let productID: ProductID
    let price: Double
}

struct InventoryStateSave: Codable {
    let inventoryID: InventoryType
    let inventoryByPurchaseDay: [Int: Double]
    let recipeAmountMultiplier: Double
    let lifespanMultiplier: Double
    let isActive: Bool
}

struct ReputationSave: Codable {
    let overallReputation: Double
    let overallFactorScores: ReputationFactorScores
    let recentOverallReputations: [Double]
    let hasRatings: Bool
}

struct AdvertisementStateSave: Codable {
    let activeAdvertisement: ActiveAdvertisement
}

struct EquipmentStateSave: Codable {
    let activePrimaryEquipment: ActivePrimaryEquipment
    let ownedSecondaryEquipment: SecondaryEquipmentCollection
}

struct UpgradeTrackerSave: Codable {
    let lastUpgradeDays: [PurchaseCategory: Int]
}

struct DaySummarySave: Codable {
    let day: Int
    let startingBalance: Double
    let demandedSales: Int
    let sales: Int
    let revenue: Double
    let economicCosts: [CostSave]
    let cashFlowCosts: [CostSave]
    let businessEvents: [BusinessEvent]
    let dailyReputationResult: DailyReputationResult?
    let sections: [SummarySectionSave]
}

struct CostSave: Codable {
    let name: String
    let amount: Double
}

struct SummarySectionSave: Codable {
    let name: String
    let notes: [String]
}

// MARK: - GameState Conversion

extension GameSave {
    init(gameState: GameState) {
        guard
            let finance = gameState.finance,
            let calendar = gameState.calendar,
            let weather = gameState.weather,
            let productState = gameState.productState,
            let reputation = gameState.reputation,
            let advertisementState = gameState.advertisementState,
            let activeAdvertisement = advertisementState.activeAdvertisement,
            let equipmentState = gameState.equipmentState
        else {
            preconditionFailure(
                "A business must be initialized before it can be saved."
            )
        }

        schemaVersion = Self.currentSchemaVersion

        self.finance = FinanceSave(
            actualBalance: finance.actualBalance
        )

        self.calendar = CalendarSave(
            simulationDay: calendar.simulationDay,
            locationStartDate: calendar.locationStartDate,
            locationStartSimulationDay:
                calendar.locationStartSimulationDay
        )

        self.weather = WeatherSave(
            weeklyForecast: weather.weeklyForecast.map { dailyWeather in
                DailyWeatherSave(
                    date: dailyWeather.date,
                    highTemperature: dailyWeather.highTemperature,
                    lowTemperature: dailyWeather.lowTemperature,
                    condition: dailyWeather.condition
                )
            }
        )

        self.productState = ProductStateSave(
            productID: productState.product.id,
            price: productState.price
        )

        inventoryStates = productState.allProductInventoryStates.map {
            productInventoryState in
            InventoryStateSave(
                inventoryID:
                    productInventoryState.productInventory.inventory.id,
                inventoryByPurchaseDay:
                    productInventoryState.inventoryByAge
                        .inventoryByPurchaseDay,
                recipeAmountMultiplier:
                    productInventoryState.recipeAmountMultiplier,
                lifespanMultiplier:
                    productInventoryState.lifespanMultiplier,
                isActive: productInventoryState.isActive
            )
        }

        self.reputation = ReputationSave(
            overallReputation: reputation.overallReputation,
            overallFactorScores: reputation.overallFactorScores,
            recentOverallReputations: reputation.recentOverallReputations,
            hasRatings: reputation.hasRatings
        )

        self.advertisementState = AdvertisementStateSave(
            activeAdvertisement: activeAdvertisement
        )

        self.equipmentState = EquipmentStateSave(
            activePrimaryEquipment:
                equipmentState.activePrimaryEquipment,
            ownedSecondaryEquipment:
                equipmentState.ownedSecondaryEquipment
        )

        pendingBusinessEvents = gameState.pendingBusinessEvents
        pendingUpgrades = gameState.pendingUpgrades
        upgradeTracker = UpgradeTrackerSave(
            lastUpgradeDays: gameState.upgradeTracker.lastUpgradeDays
        )

        summaries = gameState.simulationSummary.daySummaries.map { summary in
            DaySummarySave(
                day: summary.day,
                startingBalance: summary.startingBalance,
                demandedSales: summary.demandedSales,
                sales: summary.sales,
                revenue: summary.revenue,
                economicCosts: summary.economicCosts.map { cost in
                    CostSave(
                        name: cost.name,
                        amount: cost.amount
                    )
                },
                cashFlowCosts: summary.cashFlowCosts.map { cost in
                    CostSave(
                        name: cost.name,
                        amount: cost.amount
                    )
                },
                businessEvents: summary.businessEvents,
                dailyReputationResult: summary.dailyReputationResult,
                sections: summary.sections.map { section in
                    SummarySectionSave(
                        name: section.name,
                        notes: section.notes
                    )
                }
            )
        }
    }
}
