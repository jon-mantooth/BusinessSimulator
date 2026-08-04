//
//  Dimension.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/28/26.
//

protocol Dimension {

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

    /// Creates the common simulation structure used by every product.
    /// Product-specific behavior should be supplied through product
    /// configuration so the available gameplay systems remain parallel.
    static func create(
        product: Product,
        inventoryStates: [InventoryState]
    ) -> BusinessDimensions {
        BusinessDimensions(
            production: [
                InventoryControl(
                    productInventories: product.productInventories,
                    inventoryStates: inventoryStates
                )
            ]
        )
    }
}
