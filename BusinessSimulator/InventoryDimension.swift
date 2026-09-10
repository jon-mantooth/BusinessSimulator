//
//  InventoryDimension.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/29/26.
//

import Foundation

/// InventoryDimension affects sales based on
/// freshness, capacity constraints and costs. This class represents
/// the way in which invnetory acts as a dimension not the physical inventory itself.
final class InventoryDimension: Dimension {

    
    ///The InventoryDimension class needs attributes of the inventory itself,
    ///its relationship to the product, and its current game state.
    ///This struct aggregates those fields from ProductInventoryState.
    struct InventoryItem {

        let productInventoryState: ProductInventoryState

        let name: String
        let purchaseUnitPrice: Double
        let purchaseUnitAmount: Double
        let recipeUnitAmount: Double
        let lifespan: Int
        let freshnessCoefficient: Double

        init(
            productInventoryState: ProductInventoryState
        ) {
            self.productInventoryState = productInventoryState

            let productInventory = productInventoryState.productInventory
            let inventory = productInventory.inventory

            self.name = inventory.name
            self.purchaseUnitPrice = inventory.pricePerUnit
            self.purchaseUnitAmount = Double(inventory.purchaseAmount)
            self.recipeUnitAmount = productInventory.recipeAmount
            self.lifespan = inventory.lifespan
            self.freshnessCoefficient =
                productInventory.freshnessCoefficient
        }
    }
    
    private let inventories: [InventoryItem]

    init(
        productInventoryStates: [ProductInventoryState]
    ) {
        self.inventories = productInventoryStates.map {
            InventoryItem(productInventoryState: $0)
        }
    }

    func calculateDemand() -> Double {
        var demand = 1.0

        for inventory in inventories {
            //calculates freshness of ingredient based on age of next used item
            //and lifespan of ingredient
            let freshness = inventory.productInventoryState.inventoryByAge
                .calculateFreshness(
                    lifespan: inventory.lifespan
                )

            //converts freshness into impact on demand
            let freshnessDemand = SimulationBalance.freshness.multiplier(
                weight: inventory.freshnessCoefficient,
                effectScore: 1.0 - freshness
            )

            demand *= freshnessDemand
        }

        return demand
    }

    ///Based on demand and variance we calculate total sales. However it is possible
    ///that the sales driven by demand are greater than the amoint we can produce
    ///This function determines the amount we can possibly produce and compares to unsure
    ///we can meet the demand
    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int {

        //maps the potential sales for each ingredient amount to the ingredient
        //for every ingredient in the product. Allows us to determine which ingredient/s
        //are the limiting factor and what that limit is
        var inventoryLimits: [
            (inventory: InventoryItem, unitsPossible: Int)
        ] = []

        for inventory in inventories {

            // Inventory is stored in purchase units.
            // Convert the total inventory into recipe units so it can
            // be compared with the amount required for one product.
            let totalRecipeUnits =
                inventory.productInventoryState.inventoryByAge.totalInventory
                * inventory.purchaseUnitAmount

            let unitsPossible = Int(
                totalRecipeUnits /
                inventory.recipeUnitAmount
            )

            inventoryLimits.append(
                (
                    inventory: inventory,
                    unitsPossible: unitsPossible
                )
            )
        }

        // Sales cannot exceed predicted demand or any inventory limit.
        let salesLimit = inventoryLimits.reduce(sales) {
            min($0, $1.unitsPossible)
        }

        // Record every inventory item that caused the final limit.
        if salesLimit < sales {

            for inventoryLimit in inventoryLimits
            where inventoryLimit.unitsPossible == salesLimit {

                summary.addNote(
                    sectionName: "Inventory",
                    note: "Sales were limited by a shortage of \(inventoryLimit.inventory.name)."
                )
            }
        }

        return salesLimit
    }
    
    func calculateDailyCosts(sales: Int, summary: DaySummary) -> Double {
        var totalCosts: Double = 0
        for inventory in inventories {

            //We run this to calculate costs. But since in order to do that we need 
            //to know how much inventory is consumed we will also consume the inventory here
            totalCosts += inventory.productInventoryState.inventoryByAge.consumeInventory(
                productsSold: Double(sales),
                recipeUnit: inventory.recipeUnitAmount,
                purchaseUnit: inventory.purchaseUnitAmount,
                purchaseUnitPrice: inventory.purchaseUnitPrice
            )
        }
        
        if totalCosts > 0 {
            summary.economicCosts.append(
                Cost(name: "Ingredients", amount: totalCosts)
            )
        }
        return totalCosts
    }
    
    ///To prep for the next day all expired inventory must be removed
    func prepForNextDay(
        currentDay: Int,
        summary: DaySummary
    ) {
        var totalCost: Double = 0
        for inventory in inventories {
            inventory.productInventoryState.inventoryByAge.currentDay = currentDay
            let lifeSpan: Int = inventory.productInventoryState
                .productInventory.inventory.lifespan
            let expiredUnits = inventory.productInventoryState.inventoryByAge.removeExpiredInventory(
                lifeSpan: lifeSpan
            )
            if expiredUnits > 0{
                
                let purchaseUnit =
                    inventory.productInventoryState.productInventory
                        .inventory.purchaseUnit ?? ""
                let amountExpired =
                    purchaseUnit.isEmpty
                        ? "\(expiredUnits * inventory.purchaseUnitAmount)"
                        : "\(expiredUnits * inventory.purchaseUnitAmount) \(purchaseUnit)"

                let note = "\(inventory.name) \(amountExpired)"
                summary.addNote(sectionName: "Expired Inventory", note: note)
                totalCost += expiredUnits * inventory.purchaseUnitPrice
            }
        }
        if totalCost > 0 {
            summary.economicCosts.append(
                Cost(name: "Expired Inventory", amount: totalCost)
            )
        }
    }
}
