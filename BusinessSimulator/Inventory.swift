//
//  RawMaterial.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/20/26.
//

import Foundation

enum InventoryType {
    case sugar
    case lemon
    case cup
    case ice
    case hotDog
    case bun
    case condiments
    case onion
    case butter
    case flour
    case apple
    case cinnamon
}

typealias Days = Int

struct Inventory: Identifiable, Equatable {
    let type: InventoryType
    let name: String
    let pricePerUnit: Double
    let purchaseAmount: Int
    let purchaseUnit: String?
    let purchaseAmountLabel: String
    let lifespan: Days

    var id: InventoryType {
        type
    }
    
    init(
        type: InventoryType,
        name: String,
        pricePerUnit: Double,
        amount: Int,
        unit: String? = nil,
        lifespan: Days
    )
    {
        self.type = type
        self.name = name
        self.pricePerUnit = pricePerUnit
        self.purchaseAmount = amount
        self.purchaseUnit = unit
        self.lifespan = lifespan
        
        if let unit {
            self.purchaseAmountLabel = "\(amount) \(unit)"
        } else {
            self.purchaseAmountLabel = "\(amount)"
        }
    }
}


final class InventoryState: Identifiable {
    let inventory: Inventory

    /// Key = inventory age (days)
    /// Value = quantity at that age
    var inventoryByAge: InventoryByAge

    init(
        inventory: Inventory,
        currentDay: Int
    ) {
        self.inventory = inventory
        self.inventoryByAge = InventoryByAge(currentDay: currentDay)
    }
}

struct InventoryByAge {

    // Stored Data
    var currentDay: Int
    var inventoryByPurchaseDay: [Int: Double] = [:]

    // Queries
    var totalInventory: Double {
        inventoryByPurchaseDay.values.reduce(0, +)
    }
    
    var newInventory: Double {
        inventoryByPurchaseDay[currentDay] ?? 0
    }

    // Mutations

    /// Consumes inventory using FIFO.
    ///
    /// Inventory is stored internally in purchase units.
    /// This method converts the required recipe units into purchase units,
    /// consumes the oldest inventory first, updates the inventory dictionary,
    /// and returns the total cost of the consumed inventory.
    ///
    /// Parameters:
    /// - productsSold: Number of finished products sold.
    /// - recipeUnits: Amount of this ingredient required for one product.
    /// - purchaseUnits: Amount of ingredient contained in one purchased unit.
    /// - purchaseUnitPrice: Cost of one purchased unit.
    ///
    /// Returns:
    /// Total cost of the inventory consumed.
    mutating func consumeInventory(
        productsSold: Double,
        recipeUnits: Double,
        purchaseUnits: Double,
        purchaseUnitPrice: Double
    ) -> Double {

        //----------------------------------------------------------
        // Convert recipe units into purchase units.
        //----------------------------------------------------------

        let purchaseUnitsNeeded =
            (productsSold * recipeUnits) / purchaseUnits

        var purchaseUnitsRemaining = purchaseUnitsNeeded
        var totalCost = 0.0

        //----------------------------------------------------------
        // Consume inventory using FIFO.
        //----------------------------------------------------------

        for purchaseDay in inventoryByPurchaseDay.keys.sorted() {

            guard purchaseUnitsRemaining > 0 else {
                break
            }

            guard let availablePurchaseUnits =
                inventoryByPurchaseDay[purchaseDay] else {
                continue
            }

            //------------------------------------------------------
            // Consume as much as possible from this purchase day.
            //------------------------------------------------------

            let purchaseUnitsConsumed =
                min(availablePurchaseUnits, purchaseUnitsRemaining)

            //------------------------------------------------------
            // Update remaining inventory.
            //------------------------------------------------------

            let remainingPurchaseUnits =
                availablePurchaseUnits - purchaseUnitsConsumed

            if remainingPurchaseUnits == 0 {
                inventoryByPurchaseDay.removeValue(forKey: purchaseDay)
            } else {
                inventoryByPurchaseDay[purchaseDay] = remainingPurchaseUnits
            }

            //------------------------------------------------------
            // Update totals.
            //------------------------------------------------------

            purchaseUnitsRemaining -= purchaseUnitsConsumed

            totalCost += purchaseUnitsConsumed * purchaseUnitPrice
        }

        return totalCost
    }
    
    /// Removes all expired inventory.
    ///
    /// Inventory is considered expired if its age is greater than or
    /// equal to the inventory lifespan.
    ///
    /// Parameters:
    /// - lifespan: Number of days the inventory remains usable.
    /// - purchaseUnitPrice: Cost of one purchased unit.
    ///
    /// Returns:
    /// The total cost of all expired inventory.
    mutating func removeExpiredInventory(
        lifeSpan: Int,
    ) -> Double {
        
        var totalExpiredUnits: Double = 0.0

        for purchaseDay in inventoryByPurchaseDay.keys {

            let age = currentDay - purchaseDay

            if age >= lifeSpan {

                guard let expiredAmount =
                    inventoryByPurchaseDay[purchaseDay] else {
                    continue
                }

                totalExpiredUnits += expiredAmount
                inventoryByPurchaseDay.removeValue(
                    forKey: purchaseDay
                )
            }
        }

        return totalExpiredUnits
    }
}
