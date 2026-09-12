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
