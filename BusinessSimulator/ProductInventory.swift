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

    var id: InventoryType {
        productInventory.id
    }

    init(
        productInventory: ProductInventory,
        currentDay: Int
    ) {
        self.productInventory = productInventory
        self.inventoryByAge = InventoryByAge(currentDay: currentDay)
    }
}
