import Testing
@testable import BusinessSimulator

@MainActor
struct PendingUpgradeTests {}

// MARK: - Purchase Queueing

extension PendingUpgradeTests {

    @Test
    func purchasingEquipmentWithIngredientUpgradeQueuesItWithoutApplyingIt()
        throws {
        let gameState = try makePendingUpgradeGameState(productID: .pies)
        let equipmentState = try #require(gameState.equipmentState)
        let equipment = EquipmentCatalog().appleCorer
        let ingredientUpgrade = try #require(equipment.ingredientUpgrade)
        let appleState = try inventoryState(.apple, in: gameState)
        let workflow = PurchaseWorkflow(
            gameState: gameState,
            saveRepository: PendingUpgradeTestRepository()
        )

        let result = workflow.completePurchase(
            state: equipmentState,
            item: equipment,
            pendingUpgrade: .ingredient(ingredientUpgrade)
        )

        guard case .completed = result else {
            Issue.record("Expected equipment purchase to complete.")
            return
        }
        #expect(
            gameState.pendingUpgrades
                == [.ingredient(ingredientUpgrade)]
        )
        #expect(appleState.recipeAmountMultiplier == 1.0)
    }

    @Test
    func purchasingEquipmentWithoutIngredientUpgradeQueuesNothing() throws {
        let gameState = try makePendingUpgradeGameState(productID: .pies)
        let equipmentState = try #require(gameState.equipmentState)
        let equipment = EquipmentCatalog().foodProcessor
        let workflow = PurchaseWorkflow(
            gameState: gameState,
            saveRepository: PendingUpgradeTestRepository()
        )

        let result = workflow.completePurchase(
            state: equipmentState,
            item: equipment
        )

        guard case .completed = result else {
            Issue.record("Expected equipment purchase to complete.")
            return
        }
        #expect(gameState.pendingUpgrades.isEmpty)
    }

    @Test
    func failedPurchaseSaveRestoresPreviousPendingUpgrades() throws {
        let gameState = try makePendingUpgradeGameState(productID: .pies)
        let existingUpgrade = PendingUpgrade.ingredient(
            try #require(EquipmentCatalog().standMixer.ingredientUpgrade)
        )
        gameState.pendingUpgrades = [existingUpgrade]
        let equipmentState = try #require(gameState.equipmentState)
        let equipment = EquipmentCatalog().appleCorer
        let newUpgrade = try #require(equipment.ingredientUpgrade)
        let workflow = PurchaseWorkflow(
            gameState: gameState,
            saveRepository: PendingUpgradeTestRepository(
                shouldFailSave: true
            )
        )

        let result = workflow.completePurchase(
            state: equipmentState,
            item: equipment,
            pendingUpgrade: .ingredient(newUpgrade)
        )

        guard case .saveFailed = result else {
            Issue.record("Expected equipment purchase save to fail.")
            return
        }
        #expect(gameState.pendingUpgrades == [existingUpgrade])
        #expect(!equipmentState.ownedSecondaryEquipment.contains(equipment))
    }
}

// MARK: - Applying Pending Upgrades

extension PendingUpgradeTests {

    @Test
    func applyingPendingUpgradesProcessesEveryUpgradeAndClearsQueue() throws {
        let gameState = try makePendingUpgradeGameState(productID: .hotDogs)
        let catalog = EquipmentCatalog()
        let meatUpgrade = try #require(catalog.meatGrinder.ingredientUpgrade)
        let bunUpgrade = try #require(catalog.breadMaker.ingredientUpgrade)
        gameState.pendingUpgrades = [
            .ingredient(meatUpgrade),
            .ingredient(bunUpgrade)
        ]

        gameState.applyPendingUpgrades()

        #expect(gameState.pendingUpgrades.isEmpty)
        #expect(!(try inventoryState(.hotDog, in: gameState)).isActive)
        #expect(!(try inventoryState(.bun, in: gameState)).isActive)
        #expect((try inventoryState(.beef, in: gameState)).isActive)
        #expect((try inventoryState(.spices, in: gameState)).isActive)
        #expect((try inventoryState(.flour, in: gameState)).isActive)
        #expect((try inventoryState(.yeast, in: gameState)).isActive)
    }

    @Test
    func prepForNextDayAppliesUpgradeAfterCompletedDay() throws {
        let gameState = try makePendingUpgradeGameState(productID: .pies)
        let upgrade = try #require(
            EquipmentCatalog().appleCorer.ingredientUpgrade
        )
        let appleState = try inventoryState(.apple, in: gameState)
        gameState.pendingUpgrades = [.ingredient(upgrade)]
        gameState.productState?.price = gameState.productState?.product
            .baseIdealPrice ?? 1
        let runner = GameRunner(gameState: gameState)

        _ = runner.simulateDay()

        #expect(appleState.recipeAmountMultiplier == 1.0)
        #expect(gameState.pendingUpgrades.count == 1)

        runner.prepForNextDay()

        #expect(appleState.recipeAmountMultiplier == 0.8)
        #expect(gameState.pendingUpgrades.isEmpty)
    }
}

// MARK: - Pending Upgrade Persistence

extension PendingUpgradeTests {

    @Test
    func pendingUpgradesSurviveSaveAndRestore() throws {
        let originalState = try makePendingUpgradeGameState(
            productID: .hotDogs
        )
        let ingredientUpgrade = try #require(
            EquipmentCatalog().meatGrinder.ingredientUpgrade
        )
        originalState.pendingUpgrades = [.ingredient(ingredientUpgrade)]
        let save = GameSave(gameState: originalState)
        let restoredState = GameState()

        try restoredState.restoreBusiness(from: save)

        #expect(
            restoredState.pendingUpgrades
                == [.ingredient(ingredientUpgrade)]
        )
        #expect((try inventoryState(.hotDog, in: restoredState)).isActive)
        #expect(!(try inventoryState(.beef, in: restoredState)).isActive)

        restoredState.applyPendingUpgrades()

        #expect(!(try inventoryState(.hotDog, in: restoredState)).isActive)
        #expect((try inventoryState(.beef, in: restoredState)).isActive)
        #expect(restoredState.pendingUpgrades.isEmpty)
    }
}

private enum PendingUpgradeTestError: Error {
    case saveFailed
}

private final class PendingUpgradeTestRepository: GameSaveRepository {
    private let shouldFailSave: Bool
    private(set) var savedGame: GameSave?

    init(shouldFailSave: Bool = false) {
        self.shouldFailSave = shouldFailSave
    }

    func save(_ gameSave: GameSave) throws {
        if shouldFailSave {
            throw PendingUpgradeTestError.saveFailed
        }

        savedGame = gameSave
    }

    func load() throws -> GameSave? {
        savedGame
    }

    func hasSave() -> Bool {
        savedGame != nil
    }

    func deleteSave() throws {
        savedGame = nil
    }
}

@MainActor
private func makePendingUpgradeGameState(
    productID: ProductID
) throws -> GameState {
    let product = try #require(
        ProductCatalog().products.first { $0.id == productID }
    )
    let gameState = GameState()
    gameState.initializeBusiness(product: product)
    return gameState
}

private func inventoryState(
    _ inventoryID: InventoryType,
    in gameState: GameState
) throws -> ProductInventoryState {
    let productState = try #require(gameState.productState)
    return try #require(
        productState.allProductInventoryStates.first {
            $0.id == inventoryID
        }
    )
}
