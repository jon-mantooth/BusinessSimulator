//
//  Finance.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/25/26.
//

import Foundation

struct FinancialTransaction {
    let simulationDay: Int
    let calendarDate: Date
    let category: String
    let description: String
    let amount: Double
}

struct Finance {
    var actualBalance: Double
    var displayedBalance: Double
    let minimumOperatingAllowance: Double

    init(
        product: Product,
        balance: Double? = nil
    ) {
        let minimumOperatingAllowance =
            Self.minimumOperatingReserve(for: product)
        let initialBalance = max(
            balance ?? minimumOperatingAllowance,
            minimumOperatingAllowance
        )

        self.actualBalance = initialBalance
        self.displayedBalance = initialBalance
        self.minimumOperatingAllowance = minimumOperatingAllowance
    }

    /// Calculates the cash needed to purchase enough whole inventory packages
    /// to produce half of the product's ideal daily sales, then rounds that cost
    /// up to the next $50. New games use this amount as both their starting
    /// balance and minimum operating reserve.
    static func minimumOperatingReserve(
        for product: Product
    ) -> Double {
        let idealRevenue =
            product.baseIdealPrice * Double(product.idealUnitsSold)
        let idealSales = idealRevenue / product.baseIdealPrice
        let targetSales = idealSales / 2.0

        let inventoryCost = product.productInventories.reduce(0.0) {
            totalCost,
            productInventory in

            let requiredIngredientAmount =
                targetSales * productInventory.amount
            let purchasePackagesNeeded = ceil(
                requiredIngredientAmount
                    / Double(productInventory.inventory.purchaseAmount)
            )

            return totalCost
                + purchasePackagesNeeded
                * productInventory.inventory.pricePerUnit
        }

        return ceil(inventoryCost / 50.0) * 50.0
    }
}
