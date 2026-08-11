import Testing
@testable import BusinessSimulator

struct InventoryQueryCase: Sendable {
    let name: String
    let currentDay: Int
    let inventoryByPurchaseDay: [Int: Double]
    let expectedTotal: Double
    let expectedNewInventory: Double
}

struct InventoryConsumptionCase: Sendable {
    let name: String
    let startingInventory: [Int: Double]
    let productsSold: Double
    let expectedInventory: [Int: Double]
    let expectedCost: Double
}

struct InventoryConversionCase: Sendable {
    let name: String
    let startingInventory: [Int: Double]
    let productsSold: Double
    let recipeUnit: Double
    let purchaseUnit: Double
    let purchaseUnitPrice: Double
    let expectedInventory: [Int: Double]
    let expectedCost: Double
}

struct InventoryExpirationCase: Sendable {
    let name: String
    let currentDay: Int
    let lifeSpan: Int
    let startingInventory: [Int: Double]
    let expectedInventory: [Int: Double]
    let expectedExpiredUnits: Double
}

struct InventoryFreshnessCase: Sendable {
    let name: String
    let currentDay: Int
    let lifespan: Days
    let inventoryByPurchaseDay: [Int: Double]
    let expectedFreshness: Double
}

private let inventoryQueryCases = [
    InventoryQueryCase(
        name: "empty inventory",
        currentDay: 3,
        inventoryByPurchaseDay: [:],
        expectedTotal: 0,
        expectedNewInventory: 0
    ),
    InventoryQueryCase(
        name: "one purchase day",
        currentDay: 1,
        inventoryByPurchaseDay: [1: 2],
        expectedTotal: 2,
        expectedNewInventory: 2
    ),
    InventoryQueryCase(
        name: "multiple purchase days",
        currentDay: 3,
        inventoryByPurchaseDay: [
            1: 2,
            2: 1.5,
            3: 3
        ],
        expectedTotal: 6.5,
        expectedNewInventory: 3
    ),
    InventoryQueryCase(
        name: "fractional packages",
        currentDay: 2,
        inventoryByPurchaseDay: [
            1: 0.25,
            2: 0.5
        ],
        expectedTotal: 0.75,
        expectedNewInventory: 0.5
    ),
    InventoryQueryCase(
        name: "only older inventory",
        currentDay: 3,
        inventoryByPurchaseDay: [
            1: 2,
            2: 1.5
        ],
        expectedTotal: 3.5,
        expectedNewInventory: 0
    )
]

private let inventoryConsumptionCases = [
    InventoryConsumptionCase(
        name: "zero products sold",
        startingInventory: [
            1: 2,
            2: 1
        ],
        productsSold: 0,
        expectedInventory: [
            1: 2,
            2: 1
        ],
        expectedCost: 0
    ),
    InventoryConsumptionCase(
        name: "partial purchase unit consumed",
        startingInventory: [1: 2],
        productsSold: 10,
        expectedInventory: [1: 1.5],
        expectedCost: 10
    ),
    InventoryConsumptionCase(
        name: "purchase day fully consumed",
        startingInventory: [1: 1],
        productsSold: 20,
        expectedInventory: [:],
        expectedCost: 20
    ),
    InventoryConsumptionCase(
        name: "oldest inventory consumed first",
        startingInventory: [
            1: 1,
            2: 2,
            3: 3
        ],
        productsSold: 30,
        expectedInventory: [
            2: 1.5,
            3: 3
        ],
        expectedCost: 30
    )
]

private let inventoryConversionCases = [
    InventoryConversionCase(
        name: "fractional recipe amount",
        startingInventory: [1: 2],
        productsSold: 4,
        recipeUnit: 0.5,
        purchaseUnit: 4,
        purchaseUnitPrice: 8,
        expectedInventory: [1: 1.5],
        expectedCost: 4
    ),
    InventoryConversionCase(
        name: "individual recipe units",
        startingInventory: [1: 2],
        productsSold: 25,
        recipeUnit: 1,
        purchaseUnit: 50,
        purchaseUnitPrice: 37.5,
        expectedInventory: [1: 1.5],
        expectedCost: 18.75
    )
]

private let inventoryExpirationCases = [
    InventoryExpirationCase(
        name: "no inventory",
        currentDay: 3,
        lifeSpan: 3,
        startingInventory: [:],
        expectedInventory: [:],
        expectedExpiredUnits: 0
    ),
    InventoryExpirationCase(
        name: "all inventory is fresh",
        currentDay: 3,
        lifeSpan: 3,
        startingInventory: [
            1: 2,
            2: 1
        ],
        expectedInventory: [
            1: 2,
            2: 1
        ],
        expectedExpiredUnits: 0
    ),
    InventoryExpirationCase(
        name: "inventory reaches lifespan",
        currentDay: 4,
        lifeSpan: 3,
        startingInventory: [
            1: 2,
            2: 1
        ],
        expectedInventory: [
            2: 1
        ],
        expectedExpiredUnits: 2
    ),
    InventoryExpirationCase(
        name: "inventory is older than lifespan",
        currentDay: 6,
        lifeSpan: 3,
        startingInventory: [
            1: 2,
            4: 1
        ],
        expectedInventory: [
            4: 1
        ],
        expectedExpiredUnits: 2
    ),
    InventoryExpirationCase(
        name: "fresh and expired inventory are mixed",
        currentDay: 5,
        lifeSpan: 3,
        startingInventory: [
            1: 2,
            2: 1.5,
            3: 3,
            5: 1
        ],
        expectedInventory: [
            3: 3,
            5: 1
        ],
        expectedExpiredUnits: 3.5
    ),
    InventoryExpirationCase(
        name: "one-day lifespan",
        currentDay: 2,
        lifeSpan: 1,
        startingInventory: [
            1: 2,
            2: 1
        ],
        expectedInventory: [
            2: 1
        ],
        expectedExpiredUnits: 2
    )
]

private let inventoryFreshnessCases = [
    InventoryFreshnessCase(
        name: "new inventory is fully fresh",
        currentDay: 3,
        lifespan: 4,
        inventoryByPurchaseDay: [3: 1],
        expectedFreshness: 1
    ),
    InventoryFreshnessCase(
        name: "freshness declines quadratically",
        currentDay: 3,
        lifespan: 4,
        inventoryByPurchaseDay: [1: 1],
        expectedFreshness: 0.75
    ),
    InventoryFreshnessCase(
        name: "oldest available inventory determines freshness",
        currentDay: 3,
        lifespan: 4,
        inventoryByPurchaseDay: [1: 1, 3: 2],
        expectedFreshness: 0.75
    ),
    InventoryFreshnessCase(
        name: "empty inventory is fully fresh",
        currentDay: 3,
        lifespan: 4,
        inventoryByPurchaseDay: [:],
        expectedFreshness: 1
    ),
    InventoryFreshnessCase(
        name: "long-lasting inventory does not lose freshness",
        currentDay: 100,
        lifespan: 180,
        inventoryByPurchaseDay: [1: 1],
        expectedFreshness: 1
    ),
    InventoryFreshnessCase(
        name: "inventory beyond its lifespan has no freshness",
        currentDay: 6,
        lifespan: 4,
        inventoryByPurchaseDay: [1: 1],
        expectedFreshness: 0
    ),
    InventoryFreshnessCase(
        name: "invalid lifespan has no freshness",
        currentDay: 3,
        lifespan: 0,
        inventoryByPurchaseDay: [3: 1],
        expectedFreshness: 0
    )
]

struct InventoryByAgeTests {

    @Test(arguments: inventoryQueryCases)
    func totalInventorySumsAllPurchaseDays(
        testCase: InventoryQueryCase
    ) {
        let inventory = InventoryByAge(
            currentDay: testCase.currentDay,
            inventoryByPurchaseDay:
                testCase.inventoryByPurchaseDay
        )

        #expect(
            inventory.totalInventory ==
                testCase.expectedTotal
        )
    }

    @Test(arguments: inventoryQueryCases)
    func newInventoryReturnsCurrentDayPurchase(
        testCase: InventoryQueryCase
    ) {
        let inventory = InventoryByAge(
            currentDay: testCase.currentDay,
            inventoryByPurchaseDay:
                testCase.inventoryByPurchaseDay
        )

        #expect(
            inventory.newInventory ==
                testCase.expectedNewInventory
        )
    }

    @Test(arguments: inventoryFreshnessCases)
    func calculateFreshnessReturnsExpectedFreshness(
        testCase: InventoryFreshnessCase
    ) {
        let inventory = InventoryByAge(
            currentDay: testCase.currentDay,
            inventoryByPurchaseDay:
                testCase.inventoryByPurchaseDay
        )

        let freshness = inventory.calculateFreshness(
            lifespan: testCase.lifespan
        )

        #expect(freshness == testCase.expectedFreshness)
    }

    @Test(arguments: inventoryConsumptionCases)
    func consumeInventoryUpdatesInventoryAndCost(
        testCase: InventoryConsumptionCase
    ) {
        var inventory = InventoryByAge(
            currentDay: 3,
            inventoryByPurchaseDay:
                testCase.startingInventory
        )

        let cost = inventory.consumeInventory(
            productsSold: testCase.productsSold,
            recipeUnit: 5,
            purchaseUnit: 100,
            purchaseUnitPrice: 20
        )

        #expect(
            inventory.inventoryByPurchaseDay ==
                testCase.expectedInventory
        )
        #expect(cost == testCase.expectedCost)
    }

    @Test(arguments: inventoryConversionCases)
    func consumeInventoryConvertsRecipeToPurchaseUnits(
        testCase: InventoryConversionCase
    ) {
        var inventory = InventoryByAge(
            currentDay: 1,
            inventoryByPurchaseDay:
                testCase.startingInventory
        )

        let cost = inventory.consumeInventory(
            productsSold: testCase.productsSold,
            recipeUnit: testCase.recipeUnit,
            purchaseUnit: testCase.purchaseUnit,
            purchaseUnitPrice:
                testCase.purchaseUnitPrice
        )

        #expect(
            inventory.inventoryByPurchaseDay ==
                testCase.expectedInventory
        )
        #expect(cost == testCase.expectedCost)
    }

    @Test(arguments: inventoryExpirationCases)
    func removeExpiredInventoryRemovesExpiredPurchaseDays(
        testCase: InventoryExpirationCase
    ) {
        var inventory = InventoryByAge(
            currentDay: testCase.currentDay,
            inventoryByPurchaseDay:
                testCase.startingInventory
        )

        let expiredUnits = inventory.removeExpiredInventory(
            lifeSpan: testCase.lifeSpan
        )

        #expect(
            inventory.inventoryByPurchaseDay ==
                testCase.expectedInventory
        )
        #expect(
            expiredUnits ==
                testCase.expectedExpiredUnits
        )
    }
}
