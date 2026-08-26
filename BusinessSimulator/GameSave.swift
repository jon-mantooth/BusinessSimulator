import Foundation

struct GameSave: Codable {
    static let currentSchemaVersion = 2

    let schemaVersion: Int
    let finance: FinanceSave
    let calendar: CalendarSave
    let weather: WeatherSave
    let productState: ProductStateSave
    let inventoryStates: [InventoryStateSave]
    let reputation: ReputationSave
    let advertisementState: AdvertisementStateSave
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
}

struct ReputationSave: Codable {
    let overallReputation: Double
    let overallFactorScores: ReputationFactorScores
    let recentOverallReputations: [Double]
    let hasRatings: Bool
}

struct AdvertisementStateSave: Codable {
    let activeAdvertisementID: AdvertisementID
}

struct DaySummarySave: Codable {
    let day: Int
    let startingBalance: Double
    let demandedSales: Int
    let sales: Int
    let revenue: Double
    let economicCosts: [CostSave]
    let cashFlowCosts: [CostSave]
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
            let activeAdvertisementID = advertisementState.activeAdvertisementID
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

        inventoryStates = gameState.inventoryStates.map { inventoryState in
            InventoryStateSave(
                inventoryID: inventoryState.inventory.id,
                inventoryByPurchaseDay:
                    inventoryState.inventoryByAge.inventoryByPurchaseDay
            )
        }

        self.reputation = ReputationSave(
            overallReputation: reputation.overallReputation,
            overallFactorScores: reputation.overallFactorScores,
            recentOverallReputations: reputation.recentOverallReputations,
            hasRatings: reputation.hasRatings
        )

        self.advertisementState = AdvertisementStateSave(
            activeAdvertisementID: activeAdvertisementID
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
