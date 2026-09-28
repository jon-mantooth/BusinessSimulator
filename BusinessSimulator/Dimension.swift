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

/// Defines primary equipment's capacity progression. Location Tier 1 equipment
/// grows from 90% to 210% of ideal unit sales, while Location Tier 2 equipment
/// extends capacity to 330%.
enum ProductionCapacityBalance {

    static let schedule = CapacitySchedule(
        upgrades: [
            CapacityUpgrade(
                upgradeID: .tier(.tierZero),
                scheduledCapacity: 0.90
            ),
            CapacityUpgrade(
                upgradeID: .tier(.tierOne),
                scheduledCapacity: 1.30
            ),
            CapacityUpgrade(
                upgradeID: .tier(.tierTwo),
                scheduledCapacity: 1.70
            ),
            CapacityUpgrade(
                upgradeID: .tier(.tierThree),
                scheduledCapacity: 2.10
            ),
            CapacityUpgrade(
                upgradeID: .tier(.tierFour),
                scheduledCapacity: 2.70
            ),
            CapacityUpgrade(
                upgradeID: .tier(.tierFive),
                scheduledCapacity: 3.30
            )
        ]
    )
    static let totalTiers = UpgradeTierLevel.allCases.count - 1
    static let baselineRatio = schedule.scheduledCapacity(
        for: .tier(.tierZero)
    )
    static let targetRatio = schedule.scheduledCapacity(
        for: .tier(.tierFive)
    )

    static func baseCapacity(
        baseIdealUnitsSold: Int
    ) -> Int {
        schedule.capacity(
            for: .tier(.tierZero),
            idealUnitsSold: baseIdealUnitsSold
        )
    }

    /// Returns the cumulative capacity increase above the 90% baseline after
    /// reaching the supplied primary-equipment tier.
    static func expectedCapacityIncrease(
        baseIdealUnitsSold: Int,
        tierLevel: Int
    ) -> Int {
        assert(baseIdealUnitsSold > 0)
        assert((0...totalTiers).contains(tierLevel))

        guard let tier = UpgradeTierLevel(rawValue: tierLevel) else {
            preconditionFailure("Invalid primary-equipment tier \(tierLevel).")
        }

        return schedule.capacity(
            for: .tier(tier),
            idealUnitsSold: baseIdealUnitsSold
        ) - schedule.capacity(
            for: .tier(.tierZero),
            idealUnitsSold: baseIdealUnitsSold
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
                    productState: gameState.productState!
                ),
                EquipmentDimension(
                    equipmentState: gameState.equipmentState!
                ),
                LaborDimension(
                    laborState: gameState.laborState!
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
                LocationDimension(
                    locationState: gameState.locationState!
                ),
                WeatherDimension(
                    weatherState: gameState.weather,
                    product: gameState.productState!.product,
                    calendar: gameState.calendar
                )
            ]
        )
    }
}

struct MarketSizeLevelAllocation: Equatable {
    let locationTier: LocationTierLevel
    let totalStars: Int

    init(
        locationTier: LocationTierLevel,
        totalStars: Int
    ) {
        assert(
            totalStars >= 0,
            "Market-size stars cannot be negative."
        )

        self.locationTier = locationTier
        self.totalStars = totalStars
    }
}

enum MarketSizeProgression {
    /// Calculates the target market-size multiplier represented by an
    /// upgrade's cumulative stars. Each location tier has a target of one
    /// additional base market. Any growth not earned in a tier with no stars
    /// carries forward and is divided evenly among the next tier's stars.
    static func targetMultiplier(
        marketSizeStars: Int,
        allocations: [MarketSizeLevelAllocation]
    ) -> Double {
        assert(marketSizeStars >= 0)
        assert(
            !allocations.isEmpty,
            "Market-size progression requires at least one location tier."
        )

        let locationTiers = allocations.map(\.locationTier)
        assert(
            Set(locationTiers).count == locationTiers.count,
            "Market-size progression cannot repeat a location tier."
        )

        let orderedAllocations = allocations.sorted {
            $0.locationTier < $1.locationTier
        }
        let totalAvailableStars = orderedAllocations.reduce(0) {
            $0 + $1.totalStars
        }
        assert(
            marketSizeStars <= totalAvailableStars,
            "Market-size stars cannot exceed the configured progression."
        )

        var remainingStars = marketSizeStars
        var targetMultiplier = 1.0

        for allocation in orderedAllocations {
            guard allocation.totalStars > 0 else {
                continue
            }

            let starsUsed = min(
                remainingStars,
                allocation.totalStars
            )
            let locationTargetMultiplier = Double(
                allocation.locationTier.rawValue + 1
            )
            let growthPerStar = (
                locationTargetMultiplier - targetMultiplier
            ) / Double(allocation.totalStars)

            targetMultiplier += Double(starsUsed) * growthPerStar
            remainingStars -= starsUsed

            if remainingStars == 0 {
                break
            }
        }

        return targetMultiplier
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

    /// Applies a dimension's weight to a target multiplier that has already
    /// been calculated by a non-uniform progression.
    func multiplier(
        weight: Double,
        targetMultiplier: Double
    ) -> Double {
        assert(targetMultiplier > 0)

        return pow(
            targetMultiplier / startingMultiplier,
            weight
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
