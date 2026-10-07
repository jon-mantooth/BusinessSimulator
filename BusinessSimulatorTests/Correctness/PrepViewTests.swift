import Foundation
import Testing
@testable import BusinessSimulator

@MainActor
struct PrepViewTests {

    @Test
    func productsPossibleIncludesExistingAndPurchasedInventory() throws {
        let state = try pieInventoryState(for: .apple)
        let recipeAmount = state.effectiveRecipeAmount
        let purchaseAmount = state.productInventory.inventory.purchaseAmount

        let result = PrepInventoryProjection.productsPossible(
            for: state,
            currentAmount: recipeAmount * 2.5,
            purchaseQuantity: 1
        )

        let expected = Int(
            floor(
                (recipeAmount * 2.5 + Double(purchaseAmount))
                    / recipeAmount
            )
        )
        #expect(result == expected)
    }

    @Test
    func productsPossibleUsesEffectiveRecipeAmount() throws {
        let state = try pieInventoryState(for: .apple)
        let availableAmount = state.productInventory.recipeAmount * 4

        state.recipeAmountMultiplier = 0.8

        let result = PrepInventoryProjection.productsPossible(
            for: state,
            currentAmount: availableAmount,
            purchaseQuantity: 0
        )

        #expect(result == 5)
    }

    @Test
    func productsPossibleRoundsFractionalProductsDown() throws {
        let state = try pieInventoryState(for: .apple)

        let result = PrepInventoryProjection.productsPossible(
            for: state,
            currentAmount: state.effectiveRecipeAmount * 2.99,
            purchaseQuantity: 0
        )

        #expect(result == 2)
    }

    @Test
    func zeroInventoryMakesZeroProducts() throws {
        let state = try pieInventoryState(for: .apple)

        let result = PrepInventoryProjection.productsPossible(
            for: state,
            currentAmount: 0,
            purchaseQuantity: 0
        )

        #expect(result == 0)
    }

    @Test
    func overallProductCountUsesSmallestIngredientCapacity() throws {
        let states = pieInventoryStates()
        let currentAmounts = Dictionary(
            uniqueKeysWithValues: states.map { state in
                let productCount = state.id == .apple ? 3.0 : 7.0
                return (
                    state.id,
                    state.effectiveRecipeAmount * productCount
                )
            }
        )

        let result = PrepInventoryProjection.limitingProductCount(
            productInventoryStates: states,
            currentAmounts: currentAmounts,
            purchaseAmounts: [:]
        )

        #expect(result == 3)
    }

    @Test
    func allIngredientsTiedForMinimumAreLimiting() {
        let states = pieInventoryStates()
        let currentAmounts = Dictionary(
            uniqueKeysWithValues: states.map { state in
                let productCount = state.id == .apple || state.id == .butter
                    ? 3.0
                    : 7.0
                return (
                    state.id,
                    state.effectiveRecipeAmount * productCount
                )
            }
        )

        let result = PrepInventoryProjection.limitingIngredientIDs(
            productInventoryStates: states,
            currentAmounts: currentAmounts,
            purchaseAmounts: [:]
        )

        #expect(result == Set([.apple, .butter]))
    }

    @Test
    func inactiveReplacementIngredientsAreExcluded() throws {
        let productState = ProductState(
            product: ProductCatalog().product(for: .hotDogs),
            currentDay: 1
        )
        let allStates = productState.allProductInventoryStates
        let inactiveIDs = Set(
            allStates.filter { !$0.isActive }.map(\.id)
        )
        let currentAmounts = Dictionary(
            uniqueKeysWithValues: allStates.map { state in
                (
                    state.id,
                    state.isActive ? state.effectiveRecipeAmount * 4 : 0
                )
            }
        )

        let count = PrepInventoryProjection.limitingProductCount(
            productInventoryStates: allStates,
            currentAmounts: currentAmounts,
            purchaseAmounts: [:]
        )
        let limitingIDs = PrepInventoryProjection.limitingIngredientIDs(
            productInventoryStates: allStates,
            currentAmounts: currentAmounts,
            purchaseAmounts: [:]
        )

        #expect(count == 4)
        #expect(limitingIDs.isDisjoint(with: inactiveIDs))
    }

    private func pieInventoryState(
        for inventoryType: InventoryType
    ) throws -> ProductInventoryState {
        try #require(
            pieInventoryStates().first { $0.id == inventoryType }
        )
    }

    private func pieInventoryStates() -> [ProductInventoryState] {
        ProductState(
            product: ProductCatalog().product(for: .pies),
            currentDay: 1
        ).productInventoryStates
    }
}
