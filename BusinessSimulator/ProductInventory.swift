//
//  MaterialRequirements.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/22/26.
//

import Foundation

struct ProductInventory: Equatable, Identifiable {
    let inventory: Inventory
    let recipeAmount: Double  //quantity of inventory item for a single product
    let recipeUnit: String?
    let recipeAmountLabel: String
    let freshnessCoefficient: Double //percent impact the freshness of this ingredient has on the freshness of full product
    
    var id: InventoryType {
        inventory.type
    }

    init(
        inventory: Inventory,
        amount: Double,
        unit: String? = nil,
        freshnessCoefficient: Double
    ) {
        self.inventory = inventory
        self.recipeAmount = amount
        self.recipeUnit = unit
        self.freshnessCoefficient = freshnessCoefficient

        if let unit {
            self.recipeAmountLabel = "\(amount) \(unit)"
        } else {
            self.recipeAmountLabel = "\(amount)"
        }
    }
}

/// The state of one product ingredient within the current game.
///
/// `ProductInventory` remains the immutable catalog definition of the
/// ingredient's relationship to its product. This object adds the inventory
/// quantities and ages that change as the player operates the business.
final class ProductInventoryState: Identifiable {
    let productInventory: ProductInventory
    var inventoryByAge: InventoryByAge
    var recipeAmountMultiplier: Double
    var lifespanMultiplier: Double

    var id: InventoryType {
        productInventory.id
    }

    var effectiveRecipeAmount: Double {
        productInventory.recipeAmount * recipeAmountMultiplier
    }

    var effectiveRecipeAmountLabel: String {
        let amount = effectiveRecipeAmount.formatted(
            .number.precision(.fractionLength(0...2))
        )

        if let unit = productInventory.recipeUnit {
            return "\(amount) \(unit)"
        }

        return amount
    }

    var effectiveLifespan: Days {
        Int(
            (
                Double(productInventory.inventory.lifespan)
                    * lifespanMultiplier
            ).rounded(.up)
        )
    }

    init(
        productInventory: ProductInventory,
        currentDay: Int,
        recipeAmountMultiplier: Double = 1.0,
        lifespanMultiplier: Double = 1.0
    ) {
        assert(
            recipeAmountMultiplier > 0,
            "Recipe amount multiplier must be positive."
        )
        assert(
            lifespanMultiplier > 0,
            "Lifespan multiplier must be positive."
        )

        self.productInventory = productInventory
        self.inventoryByAge = InventoryByAge(currentDay: currentDay)
        self.recipeAmountMultiplier = recipeAmountMultiplier
        self.lifespanMultiplier = lifespanMultiplier
    }
}
