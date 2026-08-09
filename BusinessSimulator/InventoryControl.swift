//
//  InventoryControl.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/29/26.
//

/// InventoryControl is a dimension. It affects sales based on 
/// freshness, capacity constraints and costs. This class represents
/// the way in which invnetory acts as a dimension not the physical inventory itself.
final class InventoryControl: Dimension {

    
    ///The InventoryControl class needs attributes of the inventory itself
    ///as well as the relationship between the inventory and product (ProductInventory).
    ///This struct aggregates the data from both objects into its own object.
    struct InventoryItem {

        let inventoryState: InventoryState

        let name: String
        let purchaseUnitPrice: Double
        let purchaseUnitAmount: Double
        let recipeUnitAmount: Double
        let lifespan: Int

        init(
            inventory: Inventory,
            inventoryState: InventoryState,
            recipeUnitAmount: Double
        ) {
            self.inventoryState = inventoryState

            self.name = inventory.name
            self.purchaseUnitPrice = inventory.pricePerUnit
            self.purchaseUnitAmount = Double(inventory.purchaseAmount)
            self.recipeUnitAmount = recipeUnitAmount
            self.lifespan = inventory.lifespan
        }
    }
    
    private let inventories: [InventoryItem]

    init(
        productInventories: [ProductInventory],
        inventoryStates: [InventoryState]
    ) {
        self.inventories = Self.aggregateInventoryFields(
            productInventories: productInventories,
            inventoryStates: inventoryStates
        )
    }

    /// Build the InventoryItem object
    private static func aggregateInventoryFields(
        productInventories: [ProductInventory],
        inventoryStates: [InventoryState]
    ) -> [InventoryItem] {

        productInventories.compactMap { productInventory -> InventoryItem? in

            guard let inventoryState = inventoryStates.first(
                where: {
                    $0.inventory.id ==
                    productInventory.inventory.id
                }
            ) else {
                return nil
            }

            return InventoryItem(
                inventory: productInventory.inventory,
                inventoryState: inventoryState,
                recipeUnitAmount: productInventory.recipeAmount
            )
        }
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
                inventory.inventoryState.inventoryByAge.totalInventory
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
    
    func calculateCosts(sales: Int, summary: DaySummary) -> Double {
        var totalCosts: Double = 0
        for inventory in inventories {

            //We run this to calculate costs. But since in order to do that we need 
            //to know how much inventory is consumed we will also consume the inventory here
            totalCosts += inventory.inventoryState.inventoryByAge.consumeInventory(
                productsSold: Double(sales),
                recipeUnit: inventory.recipeUnitAmount,
                purchaseUnit: inventory.purchaseUnitAmount,
                purchaseUnitPrice: inventory.purchaseUnitPrice
            )
        }
        
        if totalCosts > 0 {
            summary.costs.append(Cost(name: "Ingredients", amount: totalCosts))
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
            inventory.inventoryState.inventoryByAge.currentDay = currentDay
            let lifeSpan: Int = inventory.inventoryState.inventory.lifespan
            let expiredUnits = inventory.inventoryState.inventoryByAge.removeExpiredInventory(
                lifeSpan: lifeSpan
            )
            if expiredUnits > 0{
                
                let purchaseUnit =
                    inventory.inventoryState.inventory.purchaseUnit ?? ""
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
            summary.costs.append(
                Cost(name: "Expired Inventory", amount: totalCost)
            )
        }
    }
}
