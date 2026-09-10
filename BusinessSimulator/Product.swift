//
//  Product.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/17/26.
//

import SwiftUI

struct Product: Identifiable {
    let id: ProductID
    let singularName: String
    let pluralName: String
    let smallIcon: GameIcon
    let accent: Color
    let description: String
    let productLine: any ProductLine
    let productInventories: [ProductInventory]
    let upgradeProductInventories: [ProductInventory]
    let instructions: [String]
    let baseIdealPrice: Double
    let idealUnitsSold: Int
    let priceSensitivity: Double
    let temperatureInterpolationFormula: TemperatureInterpolationFormula
}

enum ProductID: String, Codable {
    case pies
    case smoothies
    case hotDogs
}


final class ProductState: Identifiable {
    let product: Product
    private(set) var allProductInventoryStates: [ProductInventoryState]

    var productInventoryStates: [ProductInventoryState] {
        allProductInventoryStates.filter(\.isActive)
    }

    var price: Double
    private(set) var currentIdealPrice: Double

    init(
        product: Product,
        currentDay: Int,
        price: Double = 0
    ) {
        self.product = product

        let baseStates = product.productInventories.map {
            ProductInventoryState(
                productInventory: $0,
                currentDay: currentDay,
                isActive: true
            )
        }

        let upgradeStates = product.upgradeProductInventories.map {
            ProductInventoryState(
                productInventory: $0,
                currentDay: currentDay,
                isActive: false
            )
        }

        self.allProductInventoryStates = baseStates + upgradeStates
        self.price = price
        self.currentIdealPrice = product.baseIdealPrice
    }

    func updateCurrentIdealPrice(
        demand: Double
    ) {
        currentIdealPrice = product.baseIdealPrice * demand
        assert(currentIdealPrice > 0, "Ideal price must be positive.")
    }

    /// Applies an ingredient upgrade when its delayed activation date arrives.
    func applyIngredientUpgrade(
        _ upgrade: IngredientUpgrade
    ) {
        guard let inventoryState = productInventoryStates.first(
            where: { $0.id == upgrade.ingredientID }
        ) else {
            preconditionFailure(
                "Ingredient upgrade target was not found in ProductState."
            )
        }

        switch upgrade.effect {
        case .recipeAmount:
            inventoryState.recipeAmountMultiplier = 0.8

        case .lifespan:
            inventoryState.lifespanMultiplier = 1.5

        case .ingredientReplacement:
            replaceIngredient(
                inventoryState,
                withUpgradeFor: upgrade.ingredientID
            )
        }
    }

    private func replaceIngredient(
        _ replacedInventoryState: ProductInventoryState,
        withUpgradeFor inventoryID: InventoryType
    ) {
        let replacementInventoryIDs: [InventoryType]

        switch inventoryID {
        case .hotDog:
            replacementInventoryIDs = [.beef, .spices]
        case .bun:
            replacementInventoryIDs = [.flour, .yeast]
        default:
            preconditionFailure(
                "No replacement recipe exists for this ingredient."
            )
        }

        replacedInventoryState.isActive = false
        replacedInventoryState.inventoryByAge.inventoryByPurchaseDay = [:]

        for replacementInventoryID in replacementInventoryIDs {
            guard let replacementState = allProductInventoryStates.first(
                where: { $0.id == replacementInventoryID }
            ) else {
                preconditionFailure(
                    "Replacement ingredient was not found in ProductState."
                )
            }

            replacementState.isActive = true
            replacementState.inventoryByAge.inventoryByPurchaseDay = [:]
        }

    }
    
    ///calculates what revenue should be based on the difference between
    ///players price and ideal price given demand using the Gaussian function
    /// R(p)=R_max*e^{-k((p-p_i)/p_i)^2}
    func calculateBaselineRevenue() -> Double {
        let maxRevenue = currentIdealPrice * Double(product.idealUnitsSold)
        let k = -(product.priceSensitivity)
        
        let priceDifferenceRatio =
            (price - currentIdealPrice) / currentIdealPrice

        return maxRevenue * exp(k * pow(priceDifferenceRatio, 2))
    }
    
    func calculatePredictedSales(
        predictedRevenue: Double
    ) -> Int {

        return Int(floor(predictedRevenue / price))
    }
}
