//
//  Dimension.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/28/26.
//

protocol Dimension {

    func calculateDemand() -> Double

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

    init(
        production: [any Dimension] = [],
        distribution: [any Dimension] = [],
        marketing: [any Dimension] = [],
        finance: [any Dimension] = []
    ) {
        self.production = production
        self.distribution = distribution
        self.marketing = marketing
        self.finance = finance
    }

    static func create(
        product: Product,
        inventoryStates: [InventoryState]
    ) -> BusinessDimensions {
        BusinessDimensions(
            production: [
                InventoryDimension(
                    productInventories: product.productInventories,
                    inventoryStates: inventoryStates
                )
            ]
        )
    }
}
