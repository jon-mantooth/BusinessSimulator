//
//  InventoryControl.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/29/26.
//

final class InventoryControl: Dimension {

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

    /// Combines ProductInventory and InventoryState objects into a single
    /// InventoryItem for each ingredient.
    ///
    /// ProductInventory contains the static information about an ingredient
    /// (recipe amount, inventory definition, etc.).
    ///
    /// InventoryState contains the current game state for that ingredient
    /// (current inventory, purchase history, etc.).
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

    //check if we can refactor
    func applySalesLimits(
        predictedSales: Int,
        summary: DaySummary
    ) -> Int {

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

            // Determine how many products this inventory can support.
            //
            // Example:
            // 1 purchase unit = 100 lemons
            // 1 pitcher requires 5 lemons
            // 100 / 5 = 20 pitchers possible
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
        let salesLimit = inventoryLimits.reduce(predictedSales) {
            min($0, $1.unitsPossible)
        }

        // Record every inventory item that caused the final limit.
        if salesLimit < predictedSales {

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
            totalCosts += inventory.inventoryState.inventoryByAge.consumeInventory(
                productsSold: Double(sales),
                recipeUnits: inventory.recipeUnitAmount,
                purchaseUnits: inventory.purchaseUnitAmount,
                purchaseUnitPrice: inventory.purchaseUnitPrice
            )
        }
        
        if totalCosts > 0 {
            summary.costs.append(Cost(name: "Ingredients", amount: totalCosts))
        }
        return totalCosts
    }
    
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
                        ? "\(expiredUnits)"
                        : "\(expiredUnits) \(purchaseUnit)"

                let note = "\(inventory.name) \(amountExpired)"
                summary.addNote(sectionName: "Expired Inventory", note: note)
                totalCost += expiredUnits*inventory.purchaseUnitPrice
            }
        }
        if totalCost > 0 {
            summary.costs.append(
                Cost(name: "Expired Inventory", amount: totalCost)
            )
        }
    }
}
