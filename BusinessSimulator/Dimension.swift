//
//  Dimension.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/28/26.
//

import Foundation

protocol Dimension {

    func calculateDemand() -> Double

    func calculateMarketSize() -> Double

    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int
    
    func calculateCosts(
        sales: Int,
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
    
    func calculateCosts(
        sales: Int,
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
                    productInventories: product.productInventories,
                    inventoryStates: gameState.inventoryStates
                )
            ],
            marketing: [
                BusinessReputationDimension(
                    reputation: gameState.reputation!
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
        startingMultiplier: 0.80,
        targetMultiplier: 1.50
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
