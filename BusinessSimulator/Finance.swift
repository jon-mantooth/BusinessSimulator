//
//  Finance.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/25/26.
//

import Foundation

enum CashFlowDirection: String, Codable {
    case inflow
    case outflow
}

enum PurchaseAvailability: Equatable {
    case available
    case locationLocked(requiredTier: LocationTierLevel)
    case insufficientFunds
    case operatingReserveRequired
}

struct FinancialTransaction: Codable {
    let amount: Double
    let direction: CashFlowDirection
}

/// One operating day's normalized inputs for price analysis.
struct PriceAnalyticsRow {
    let day: Int
    let locationID: LocationID
    let price: Double
    let idealPrice: Double
    let highTemperature: Int
    let businessReputation: Double
    let equipmentLevel: Int
    let advertisementLevel: Int

    var priceDeviation: Double {
        (price / idealPrice) - 1.0
    }
}

/// Derived, in-memory reporting data rebuilt from persisted day summaries.
struct FinancialAnalytics {
    private(set) var priceAnalytics: [PriceAnalyticsRow] = []

    mutating func appendPriceAnalytics(
        from summary: DaySummary
    ) {
        guard summary.type == .operating else {
            return
        }

        guard let price = summary.price,
              let idealPrice = summary.idealPrice,
              let highTemperature = summary.highTemperature,
              let businessReputation = summary.businessReputation,
              let equipmentLevel = summary.equipmentLevel,
              let advertisementLevel = summary.advertisementLevel else {
            preconditionFailure(
                "An operating summary must contain all price-analysis factors."
            )
        }

        precondition(
            idealPrice > 0,
            "Ideal price must be greater than zero for price analysis."
        )

        priceAnalytics.append(
            PriceAnalyticsRow(
                day: summary.day,
                locationID: summary.locationID,
                price: price,
                idealPrice: idealPrice,
                highTemperature: highTemperature,
                businessReputation: businessReputation,
                equipmentLevel: equipmentLevel,
                advertisementLevel: advertisementLevel
            )
        )
    }
}

struct Finance {
    var actualBalance: Double
    var displayedBalance: Double
    let minimumOperatingAllowance: Double

    init(
        product: Product,
        productInventoryStates: [ProductInventoryState],
        balance: Double? = nil
    ) {
        let minimumOperatingAllowance =
            Self.minimumOperatingReserve(
                for: product,
                productInventoryStates: productInventoryStates
            )
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
        for product: Product,
        productInventoryStates: [ProductInventoryState]
    ) -> Double {
        let idealRevenue =
            product.baseIdealPrice * Double(product.idealUnitsSold)
        let idealSales = idealRevenue / product.baseIdealPrice
        let targetSales = idealSales / 2.0

        var inventoryCost = 0.0
        for productInventoryState in productInventoryStates {
            let productInventory =
                productInventoryState.productInventory
            let requiredIngredientAmount =
                targetSales
                    * productInventoryState.effectiveRecipeAmount
            let purchasePackagesNeeded = ceil(
                requiredIngredientAmount
                    / Double(productInventory.inventory.purchaseAmount)
            )

            inventoryCost += purchasePackagesNeeded
                * productInventory.inventory.pricePerUnit
        }

        return ceil(inventoryCost / 50.0) * 50.0
    }

    func purchaseAvailability(
        for price: Double
    ) -> PurchaseAvailability {
        if price == 0 {
            return .available
        }

        if price > displayedBalance {
            return .insufficientFunds
        }

        if price + minimumOperatingAllowance > displayedBalance {
            return .operatingReserveRequired
        }

        return .available
    }
}
