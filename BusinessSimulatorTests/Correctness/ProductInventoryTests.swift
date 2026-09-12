import SwiftUI
import Testing
@testable import BusinessSimulator

@MainActor
struct ProductInventoryTests {}

// MARK: - Effective Ingredient Values

extension ProductInventoryTests {

    @Test
    func defaultRecipeMultiplierPreservesBaseRecipeAmount() {
        let state = makeProductInventoryState(
            recipeAmount: 5,
            lifespan: 7
        )

        #expect(state.recipeAmountMultiplier == 1.0)
        #expect(state.effectiveRecipeAmount == 5)
    }

    @Test
    func effectiveRecipeAmountAppliesRecipeMultiplier() {
        let state = makeProductInventoryState(
            recipeAmount: 5,
            lifespan: 7,
            recipeAmountMultiplier: 0.8
        )

        #expect(abs(state.effectiveRecipeAmount - 4.0) < 0.000_001)
    }

    @Test
    func defaultLifespanMultiplierPreservesBaseLifespan() {
        let state = makeProductInventoryState(
            recipeAmount: 1,
            lifespan: 7
        )

        #expect(state.lifespanMultiplier == 1.0)
        #expect(state.effectiveLifespan == 7)
    }

    @Test
    func effectiveLifespanAppliesMultiplierAndRoundsUp() {
        let state = makeProductInventoryState(
            recipeAmount: 1,
            lifespan: 5,
            lifespanMultiplier: 1.5
        )

        #expect(state.effectiveLifespan == 8)
    }
}

// MARK: - Inventory Integration Regressions

extension ProductInventoryTests {

    @Test
    func inventorySalesLimitUsesEffectiveRecipeAmount() {
        let productState = makeSingleIngredientProductState(
            recipeAmount: 2,
            purchaseAmount: 10
        )
        let ingredientState = productState.productInventoryStates[0]
        ingredientState.recipeAmountMultiplier = 0.5
        ingredientState.inventoryByAge.inventoryByPurchaseDay = [1: 1]
        let dimension = InventoryDimension(productState: productState)
        let summary = DaySummary(day: 1, startingBalance: 100)

        let sales = dimension.applySalesLimits(
            sales: 10,
            summary: summary
        )

        #expect(sales == 10)
        #expect(summary.sections.isEmpty)
    }

    @Test
    func inventoryConsumptionUsesEffectiveRecipeAmount() {
        let productState = makeSingleIngredientProductState(
            recipeAmount: 2,
            purchaseAmount: 10,
            purchasePrice: 10
        )
        let ingredientState = productState.productInventoryStates[0]
        ingredientState.recipeAmountMultiplier = 0.5
        ingredientState.inventoryByAge.inventoryByPurchaseDay = [1: 1]
        let dimension = InventoryDimension(productState: productState)
        let summary = DaySummary(day: 1, startingBalance: 100)

        let cost = dimension.calculateDailyCosts(
            sales: 4,
            summary: summary
        )

        #expect(abs(cost - 4.0) < 0.000_001)
        #expect(
            abs(ingredientState.inventoryByAge.totalInventory - 0.6)
                < 0.000_001
        )
    }

    @Test
    func inventoryFreshnessDemandUsesEffectiveLifespan() {
        let productState = makeSingleIngredientProductState(
            recipeAmount: 1,
            purchaseAmount: 1,
            lifespan: 5
        )
        let ingredientState = productState.productInventoryStates[0]
        ingredientState.lifespanMultiplier = 2.0
        ingredientState.inventoryByAge.currentDay = 6
        ingredientState.inventoryByAge.inventoryByPurchaseDay = [1: 1]
        let expectedFreshness = 0.75
        let expectedDemand = SimulationBalance.freshness.multiplier(
            weight: 1.0,
            effectScore: 1.0 - expectedFreshness
        )

        let demand = InventoryDimension(
            productState: productState
        ).calculateDemand()

        #expect(abs(demand - expectedDemand) < 0.000_001)
    }

    @Test
    func minimumOperatingReserveUsesEffectiveRecipeAmount() {
        let productState = makeSingleIngredientProductState(
            recipeAmount: 2,
            purchaseAmount: 10,
            purchasePrice: 40,
            idealUnitsSold: 100
        )
        let ingredientState = productState.productInventoryStates[0]
        let originalReserve = Finance.minimumOperatingReserve(
            for: productState.product,
            productInventoryStates: productState.productInventoryStates
        )

        ingredientState.recipeAmountMultiplier = 0.5

        let upgradedReserve = Finance.minimumOperatingReserve(
            for: productState.product,
            productInventoryStates: productState.productInventoryStates
        )

        #expect(originalReserve == 400)
        #expect(upgradedReserve == 200)
        #expect(upgradedReserve < originalReserve)
    }

    @Test
    func inventoryExpirationUsesEffectiveLifespan() {
        let baseProductState = makeSingleIngredientProductState(
            recipeAmount: 1,
            purchaseAmount: 1,
            lifespan: 5
        )
        let upgradedProductState = makeSingleIngredientProductState(
            recipeAmount: 1,
            purchaseAmount: 1,
            lifespan: 5
        )
        let baseState = baseProductState.productInventoryStates[0]
        let upgradedState = upgradedProductState.productInventoryStates[0]
        baseState.inventoryByAge.inventoryByPurchaseDay = [1: 1]
        upgradedState.inventoryByAge.inventoryByPurchaseDay = [1: 1]
        upgradedState.lifespanMultiplier = 2.0

        InventoryDimension(productState: baseProductState).prepForNextDay(
            currentDay: 7,
            summary: DaySummary(day: 6, startingBalance: 100)
        )
        InventoryDimension(productState: upgradedProductState).prepForNextDay(
            currentDay: 7,
            summary: DaySummary(day: 6, startingBalance: 100)
        )

        #expect(baseState.inventoryByAge.totalInventory == 0)
        #expect(upgradedState.inventoryByAge.totalInventory == 1)
    }

    @Test
    func reputationFreshnessReceivesOnlyActiveIngredients() {
        let productState = makeProductStateWithUpgradeIngredient()
        let baseState = productState.productInventoryStates[0]
        let inactiveState = productState.allProductInventoryStates.first {
            !$0.isActive
        }!
        baseState.inventoryByAge.currentDay = 10
        baseState.inventoryByAge.inventoryByPurchaseDay = [10: 1]
        inactiveState.inventoryByAge.currentDay = 10
        inactiveState.inventoryByAge.inventoryByPurchaseDay = [1: 1]

        let score = BusinessReputationState()
            .calculateFreshnessEffectScore(
                productInventoryStates: productState.productInventoryStates
            )

        #expect(score == 1.0)
    }

    @Test
    func inventoryDimensionUsesReplacementIngredientsAfterUpgrade() throws {
        let productState = try makeCatalogProductState(productID: .hotDogs)
        let dimension = InventoryDimension(productState: productState)

        for state in productState.productInventoryStates {
            state.inventoryByAge.inventoryByPurchaseDay = [1: 100]
        }

        let upgrade = try #require(
            EquipmentCatalog().meatGrinder.ingredientUpgrade
        )
        productState.applyIngredientUpgrade(upgrade)
        let summary = DaySummary(day: 1, startingBalance: 100)

        let sales = dimension.applySalesLimits(
            sales: 10,
            summary: summary
        )

        #expect(sales == 0)
        #expect(
            summary.sections.contains { section in
                section.name == "Inventory"
                    && section.notes.contains {
                        $0.contains("Beef")
                    }
                    && section.notes.contains {
                        $0.contains("Spices")
                    }
            }
        )
    }
}

// MARK: - Ingredient Upgrades

extension ProductInventoryTests {

    @Test
    func recipeAmountUpgradeSetsMultiplierWithoutCompounding() throws {
        let productState = try makeCatalogProductState(productID: .pies)
        let upgrade = try #require(
            EquipmentCatalog().appleCorer.ingredientUpgrade
        )

        productState.applyIngredientUpgrade(upgrade)
        productState.applyIngredientUpgrade(upgrade)

        let appleState = try #require(
            productState.productInventoryStates.first { $0.id == .apple }
        )
        #expect(appleState.recipeAmountMultiplier == 0.8)
        #expect(
            abs(
                appleState.effectiveRecipeAmount
                    - appleState.productInventory.recipeAmount * 0.8
            ) < 0.000_001
        )
    }

    @Test
    func lifespanUpgradeSetsMultiplierWithoutCompounding() throws {
        let productState = try makeCatalogProductState(productID: .smoothies)
        let upgrade = try #require(
            EquipmentCatalog().vacuumSealer.ingredientUpgrade
        )

        productState.applyIngredientUpgrade(upgrade)
        productState.applyIngredientUpgrade(upgrade)

        let strawberryState = try #require(
            productState.productInventoryStates.first {
                $0.id == .strawberry
            }
        )
        #expect(strawberryState.lifespanMultiplier == 1.5)
    }

    @Test
    func meatGrinderReplacesHotDogsWithEmptyBeefAndSpices() throws {
        let productState = try makeCatalogProductState(productID: .hotDogs)
        let upgrade = try #require(
            EquipmentCatalog().meatGrinder.ingredientUpgrade
        )
        let hotDogState = try inventoryState(.hotDog, in: productState)
        let beefState = try inventoryState(.beef, in: productState)
        let spicesState = try inventoryState(.spices, in: productState)
        let onionState = try inventoryState(.onion, in: productState)
        hotDogState.inventoryByAge.inventoryByPurchaseDay = [1: 3]
        beefState.inventoryByAge.inventoryByPurchaseDay = [1: 4]
        spicesState.inventoryByAge.inventoryByPurchaseDay = [1: 5]
        onionState.inventoryByAge.inventoryByPurchaseDay = [1: 6]

        productState.applyIngredientUpgrade(upgrade)

        #expect(!hotDogState.isActive)
        #expect(hotDogState.inventoryByAge.inventoryByPurchaseDay.isEmpty)
        #expect(beefState.isActive)
        #expect(spicesState.isActive)
        #expect(beefState.inventoryByAge.inventoryByPurchaseDay.isEmpty)
        #expect(spicesState.inventoryByAge.inventoryByPurchaseDay.isEmpty)
        #expect(onionState.isActive)
        #expect(onionState.inventoryByAge.inventoryByPurchaseDay == [1: 6])
        #expect(
            Set(productState.productInventoryStates.map(\.id)).contains(.beef)
        )
        #expect(
            Set(productState.productInventoryStates.map(\.id)).contains(.spices)
        )
        #expect(
            !Set(productState.productInventoryStates.map(\.id))
                .contains(.hotDog)
        )
    }

    @Test
    func breadMakerReplacesBunsWithEmptyFlourAndYeast() throws {
        let productState = try makeCatalogProductState(productID: .hotDogs)
        let upgrade = try #require(
            EquipmentCatalog().breadMaker.ingredientUpgrade
        )
        let bunState = try inventoryState(.bun, in: productState)
        let flourState = try inventoryState(.flour, in: productState)
        let yeastState = try inventoryState(.yeast, in: productState)
        let condimentState = try inventoryState(.condiments, in: productState)
        bunState.inventoryByAge.inventoryByPurchaseDay = [1: 3]
        flourState.inventoryByAge.inventoryByPurchaseDay = [1: 4]
        yeastState.inventoryByAge.inventoryByPurchaseDay = [1: 5]
        condimentState.inventoryByAge.inventoryByPurchaseDay = [1: 6]

        productState.applyIngredientUpgrade(upgrade)

        #expect(!bunState.isActive)
        #expect(bunState.inventoryByAge.inventoryByPurchaseDay.isEmpty)
        #expect(flourState.isActive)
        #expect(yeastState.isActive)
        #expect(flourState.inventoryByAge.inventoryByPurchaseDay.isEmpty)
        #expect(yeastState.inventoryByAge.inventoryByPurchaseDay.isEmpty)
        #expect(condimentState.isActive)
        #expect(
            condimentState.inventoryByAge.inventoryByPurchaseDay == [1: 6]
        )
        #expect(
            Set(productState.productInventoryStates.map(\.id)).contains(.flour)
        )
        #expect(
            Set(productState.productInventoryStates.map(\.id)).contains(.yeast)
        )
        #expect(
            !Set(productState.productInventoryStates.map(\.id)).contains(.bun)
        )
    }

    @Test
    func replacementIngredientsReceiveReplacedIngredientsCurrentDay() throws {
        let productState = try makeCatalogProductState(productID: .hotDogs)
        let upgrade = try #require(
            EquipmentCatalog().meatGrinder.ingredientUpgrade
        )
        let hotDogState = try inventoryState(.hotDog, in: productState)
        hotDogState.inventoryByAge.currentDay = 12

        productState.applyIngredientUpgrade(upgrade)

        let beefState = try inventoryState(.beef, in: productState)
        let spicesState = try inventoryState(.spices, in: productState)

        #expect(beefState.inventoryByAge.currentDay == 12)
        #expect(spicesState.inventoryByAge.currentDay == 12)
    }
}

// MARK: - Product Ingredient Activation

extension ProductInventoryTests {

    @Test
    func baseIngredientsInitializeActiveAndUpgradeIngredientsInactive() {
        let productState = makeProductStateWithUpgradeIngredient()
        let baseState = productState.allProductInventoryStates.first {
            $0.id == .apple
        }
        let upgradeState = productState.allProductInventoryStates.first {
            $0.id == .beef
        }

        #expect(baseState?.isActive == true)
        #expect(upgradeState?.isActive == false)
    }

    @Test
    func activeProductInventoryStatesExcludeInactiveUpgradeIngredients() {
        let productState = makeProductStateWithUpgradeIngredient()

        #expect(productState.productInventoryStates.map(\.id) == [.apple])
    }

    @Test
    func allProductInventoryStatesContainBaseAndUpgradeIngredients() {
        let productState = makeProductStateWithUpgradeIngredient()

        #expect(
            Set(productState.allProductInventoryStates.map(\.id))
                == Set([InventoryType.apple, .beef])
        )
        #expect(productState.allProductInventoryStates.count == 2)
    }
}

private func makeProductInventoryState(
    recipeAmount: Double,
    lifespan: Int,
    recipeAmountMultiplier: Double = 1.0,
    lifespanMultiplier: Double = 1.0
) -> ProductInventoryState {
    ProductInventoryState(
        productInventory: ProductInventory(
            inventory: Inventory(
                type: .apple,
                name: "Test Ingredient",
                smallIcon: .emoji("🧪"),
                pricePerUnit: 1,
                amount: 1,
                lifespan: lifespan
            ),
            amount: recipeAmount,
            freshnessCoefficient: 1
        ),
        currentDay: 1,
        recipeAmountMultiplier: recipeAmountMultiplier,
        lifespanMultiplier: lifespanMultiplier
    )
}

@MainActor
private func makeSingleIngredientProductState(
    recipeAmount: Double,
    purchaseAmount: Int,
    purchasePrice: Double = 1,
    lifespan: Int = 10,
    idealUnitsSold: Int = 1
) -> ProductState {
    let productInventory = ProductInventory(
        inventory: Inventory(
            type: .apple,
            name: "Test Ingredient",
            smallIcon: .emoji("🍎"),
            pricePerUnit: purchasePrice,
            amount: purchaseAmount,
            lifespan: lifespan
        ),
        amount: recipeAmount,
        freshnessCoefficient: 1
    )
    let product = Product(
        id: .pies,
        singularName: "Test Product",
        pluralName: "Test Products",
        smallIcon: .emoji("🧪"),
        accent: .brown,
        description: "Tests inventory integration.",
        productLine: FoodProductLine(),
        productInventories: [productInventory],
        upgradeProductInventories: [],
        instructions: [],
        baseIdealPrice: 1,
        idealUnitsSold: idealUnitsSold,
        priceSensitivity: 1,
        temperatureInterpolationFormula: .coldWeather
    )

    return ProductState(product: product, currentDay: 1)
}

@MainActor
private func makeCatalogProductState(
    productID: ProductID,
    currentDay: Int = 1
) throws -> ProductState {
    let product = try #require(
        ProductCatalog().products.first { $0.id == productID }
    )

    return ProductState(product: product, currentDay: currentDay)
}

private func inventoryState(
    _ inventoryID: InventoryType,
    in productState: ProductState
) throws -> ProductInventoryState {
    try #require(
        productState.allProductInventoryStates.first {
            $0.id == inventoryID
        }
    )
}

@MainActor
private func makeProductStateWithUpgradeIngredient() -> ProductState {
    let baseInventory = ProductInventory(
        inventory: Inventory(
            type: .apple,
            name: "Base Ingredient",
            smallIcon: .emoji("🍎"),
            pricePerUnit: 1,
            amount: 1,
            lifespan: 7
        ),
        amount: 1,
        freshnessCoefficient: 1
    )
    let upgradeInventory = ProductInventory(
        inventory: Inventory(
            type: .beef,
            name: "Upgrade Ingredient",
            smallIcon: .emoji("🥩"),
            pricePerUnit: 1,
            amount: 1,
            lifespan: 14
        ),
        amount: 1,
        freshnessCoefficient: 1
    )
    let product = Product(
        id: .pies,
        singularName: "Test Product",
        pluralName: "Test Products",
        smallIcon: .emoji("🧪"),
        accent: .brown,
        description: "Tests product inventory state.",
        productLine: FoodProductLine(),
        productInventories: [baseInventory],
        upgradeProductInventories: [upgradeInventory],
        instructions: [],
        baseIdealPrice: 1,
        idealUnitsSold: 1,
        priceSensitivity: 1,
        temperatureInterpolationFormula: .coldWeather
    )

    return ProductState(product: product, currentDay: 1)
}
