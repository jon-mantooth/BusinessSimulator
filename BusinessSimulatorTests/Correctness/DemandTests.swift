import Foundation
import Testing
@testable import BusinessSimulator

struct InventoryDemandCase: Sendable {
    let name: String
    let currentDay: Int
    let butterPurchaseDay: Int
    let applePurchaseDay: Int
    let expectedDemand: Double
}

private let inventoryDemandCases = [
    InventoryDemandCase(
        name: "both ingredients have intermediate freshness",
        currentDay: 3,
        butterPurchaseDay: 1,
        applePurchaseDay: 0,
        expectedDemand: 0.966555
    ),
    InventoryDemandCase(
        name: "both ingredients have zero freshness",
        currentDay: 4,
        butterPurchaseDay: 0,
        applePurchaseDay: 0,
        expectedDemand: 0.93
    ),
    InventoryDemandCase(
        name: "both ingredients are fully fresh",
        currentDay: 4,
        butterPurchaseDay: 4,
        applePurchaseDay: 4,
        expectedDemand: 1
    ),
    InventoryDemandCase(
        name: "one ingredient is partially fresh and one is fully fresh",
        currentDay: 4,
        butterPurchaseDay: 2,
        applePurchaseDay: 4,
        expectedDemand: 0.994572
    ),
    InventoryDemandCase(
        name: "one ingredient is partially fresh and one has zero freshness",
        currentDay: 4,
        butterPurchaseDay: 2,
        applePurchaseDay: 0,
        expectedDemand: 0.945310
    )
]

struct DemandTests {

    @Test(arguments: inventoryDemandCases)
    func inventoryDemandCombinesFreshnessCoefficients(
        testCase: InventoryDemandCase
    ) {
        let butter = Inventory(
            type: .butter,
            name: "Butter",
            smallIcon: .emoji("🧈"),
            pricePerUnit: 8,
            amount: 4,
            lifespan: 4
        )

        let apple = Inventory(
            type: .apple,
            name: "Apples",
            smallIcon: .emoji("🍎"),
            pricePerUnit: 60,
            amount: 100,
            lifespan: 4
        )

        let productInventories = [
            ProductInventory(
                inventory: butter,
                amount: 0.5,
                freshnessCoefficient: 0.3
            ),
            ProductInventory(
                inventory: apple,
                amount: 5,
                freshnessCoefficient: 0.7
            )
        ]

        let butterState = InventoryState(
            inventory: butter,
            currentDay: testCase.currentDay
        )
        butterState.inventoryByAge.inventoryByPurchaseDay = [
            testCase.butterPurchaseDay: 1
        ]

        let appleState = InventoryState(
            inventory: apple,
            currentDay: testCase.currentDay
        )
        appleState.inventoryByAge.inventoryByPurchaseDay = [
            testCase.applePurchaseDay: 1
        ]

        let inventoryDimension = InventoryDimension(
            productInventories: productInventories,
            inventoryStates: [butterState, appleState]
        )

        let demand = inventoryDimension.calculateDemand()

        #expect(
            abs(demand - testCase.expectedDemand) < 0.000_001
        )
    }
}
