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
    
    var id: InventoryType {
        inventory.type
    }

    init(
        inventory: Inventory,
        amount: Double,
        unit: String? = nil
    ) {
        self.inventory = inventory
        self.recipeAmount = amount
        self.recipeUnit = unit

        if let unit {
            self.recipeAmountLabel = "\(amount) \(unit)"
        } else {
            self.recipeAmountLabel = "\(amount)"
        }
    }
}
