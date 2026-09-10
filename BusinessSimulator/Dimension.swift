//
//  Dimension.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/28/26.
//

import Foundation

enum PaymentSchedule: String, Codable, Hashable {
    case oneTime
    case daily
    case weekly
}

/// Defines the shared capacity progression for equipment, labor, storage, and
/// other production constraints. Tier zero starts at 90% of ideal unit sales,
/// and completing all five tiers reaches 200% of ideal unit sales.
enum ProductionCapacityBalance {

    static let baselineRatio = 0.90
    static let targetRatio = 2.00
    static let totalTiers = 5

    static func baseCapacity(
        baseIdealUnitsSold: Int
    ) -> Int {
        assert(baseIdealUnitsSold > 0)

        return Int(
            (Double(baseIdealUnitsSold) * baselineRatio)
                .rounded(.up)
        )
    }

    /// Returns the cumulative capacity increase above the baseline expected
    /// after reaching the supplied tier.
    static func expectedCapacityIncrease(
        baseIdealUnitsSold: Int,
        tierLevel: Int
    ) -> Int {
        assert(baseIdealUnitsSold > 0)
        assert((0...totalTiers).contains(tierLevel))

        let baselineCapacity = baseCapacity(
            baseIdealUnitsSold: baseIdealUnitsSold
        )
        let targetCapacity = Int(
            (Double(baseIdealUnitsSold) * targetRatio)
                .rounded()
        )
        let totalCapacityIncrease = targetCapacity - baselineCapacity
        let tierProgress = Double(tierLevel) / Double(totalTiers)

        return Int(
            (Double(totalCapacityIncrease) * tierProgress)
                .rounded()
        )
    }
}

struct UpgradeTracker {
    private(set) var lastUpgradeDays: [PurchaseCategory: Int]

    init(
        lastUpgradeDays: [PurchaseCategory: Int] = [:]
    ) {
        self.lastUpgradeDays = lastUpgradeDays
    }

    func canUpgrade(
        _ category: PurchaseCategory,
        on simulationDay: Int
    ) -> Bool {
        lastUpgradeDays[category] != simulationDay
    }

    mutating func recordUpgrade(
        _ category: PurchaseCategory,
        on simulationDay: Int
    ) {
        lastUpgradeDays[category] = simulationDay
    }
}

protocol Dimension {

    func calculateDemand() -> Double

    func calculateMarketSize() -> Double

    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int
    
    func calculateDailyCosts(
        sales: Int,
        summary: DaySummary
    ) -> Double

    func calculateWeeklyCosts(
        summary: DaySummary
    ) -> Double
    
    func prepForNextDay(
        currentDay: Int,
        summary: DaySummary
    )
}

extension Dimension {

    func calculateDemand() -> Double {
        return 1.0
    }

    func calculateMarketSize() -> Double {
        return 1.0
    }

    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int {

        return sales
    }
    
    func calculateDailyCosts(
        sales: Int,
        summary: DaySummary
    ) -> Double {

        return 0
    }

    func calculateWeeklyCosts(
        summary: DaySummary
    ) -> Double {
        return 0
    }
    
    func prepForNextDay(
        currentDay: Int,
        summary: DaySummary
    ) {
        // Default implementation: no end-of-day work required.
    }
}

/// Each department will have multiple dimensions that will affect
/// the game simulation financials through demand, production capacity, costs etc
/// This struct defines the dimensions for each department so we know which dimensions
/// to iterate through.
struct BusinessDimensions {

    let production: [any Dimension]
    let distribution: [any Dimension]
    let marketing: [any Dimension]
    let finance: [any Dimension]
    let environment: [any Dimension]

    init(
        production: [any Dimension] = [],
        distribution: [any Dimension] = [],
        marketing: [any Dimension] = [],
        finance: [any Dimension] = [],
        environment: [any Dimension] = []
    ) {
        self.production = production
        self.distribution = distribution
        self.marketing = marketing
        self.finance = finance
        self.environment = environment
    }

    static func create(
        gameState: GameState
    ) -> BusinessDimensions {
        let product = gameState.productState!.product

        return BusinessDimensions(
            production: [
                InventoryDimension(
                    productInventoryStates:
                        gameState.productState!.productInventoryStates
                ),
                EquipmentDimension(
                    equipmentState: gameState.equipmentState!
                )
            ],
            marketing: [
                BusinessReputationDimension(
                    reputation: gameState.reputation!
                ),
                AdvertisementDimension(
                    advertisementState: gameState.advertisementState!,
                    businessHours: gameState.businessHours!
                )
            ],
            environment: [
                WeatherDimension(
                    weatherState: gameState.weather,
                    product: gameState.productState!.product,
                    calendar: gameState.calendar
                )
            ]
        )
    }
}

///To calculate the growth affect of any dimension we need to first determine
///the total growth affect and the portion of each dimension on that affect.
///The weights of individual dimensions will be determined inside those dimensions
///but the total growth affect is determined here and used by each dimension.
struct GrowthBalance {

    let startingMultiplier: Double
    let targetMultiplier: Double

    var totalGrowthFactor: Double {
        targetMultiplier / startingMultiplier
    }

    //calculate growth affect using the totalGrowthFactor, weight of specific dimension
    //and how much of dimension is used in specific situation.
    func multiplier(
        weight: Double,
        effectScore: Double
    ) -> Double {
        // multiplier = totalGrowthFactor ^ (weight * effectScore)
        pow(
            totalGrowthFactor,
            weight * effectScore
        )
    }
}

enum SimulationBalance {

    static let demand = GrowthBalance(
        startingMultiplier: 1.00,
        targetMultiplier: 1.875
    )

    static let marketSize = GrowthBalance(
        startingMultiplier: 1.00,
        targetMultiplier: 2.00
    )

    static let freshness = GrowthBalance(
        startingMultiplier: 1.00,
        targetMultiplier: 0.93
    )
}
