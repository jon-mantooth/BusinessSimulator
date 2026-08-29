import Foundation
import Testing
@testable import BusinessSimulator

struct PurchaseWorkflowTests {}

// MARK: - Purchase Validation

extension PurchaseWorkflowTests {

    @Test
    func upgradeAvailabilityUsesCategoryAndSimulationDay() {
        let gameState = makeGameState()
        let workflow = makeWorkflow(gameState: gameState)

        #expect(
            workflow.validateUpgradeAvailability(category: .advertisement)
        )

        gameState.upgradeTracker.recordUpgrade(
            .advertisement,
            on: gameState.calendar.simulationDay
        )

        #expect(
            !workflow.validateUpgradeAvailability(category: .advertisement)
        )
        #expect(
            workflow.validateUpgradeAvailability(category: .equipment)
        )

        gameState.calendar.simulationDay += 1

        #expect(
            workflow.validateUpgradeAvailability(category: .advertisement)
        )
    }

    @Test
    func financialAvailabilityUsesFinanceRules() {
        let gameState = makeGameState()
        let workflow = makeWorkflow(gameState: gameState)
        let reserve = gameState.finance.minimumOperatingAllowance
        gameState.finance.displayedBalance = reserve - 1

        guard case .available = workflow.validateFinancialAvailability(
            price: 0
        ) else {
            Issue.record(
                "A free purchase should remain available below the reserve."
            )
            return
        }

        gameState.finance.displayedBalance = reserve + 100

        guard case .available = workflow.validateFinancialAvailability(
            price: 100
        ) else {
            Issue.record("A purchase that preserves the reserve should pass.")
            return
        }

        guard case .operatingReserveRequired =
            workflow.validateFinancialAvailability(price: 101)
        else {
            Issue.record("A purchase that enters the reserve should be blocked.")
            return
        }

        guard case .insufficientFunds =
            workflow.validateFinancialAvailability(price: reserve + 101)
        else {
            Issue.record("A purchase above displayed balance should be blocked.")
            return
        }
    }
}

// MARK: - Successful Purchase

extension PurchaseWorkflowTests {

    @Test
    func oneTimePurchaseUpdatesStateAndSaves() throws {
        let gameState = makeGameState()
        let repository = TestGameSaveRepository()
        let workflow = PurchaseWorkflow(
            gameState: gameState,
            saveRepository: repository
        )
        let startingActualBalance = gameState.finance.actualBalance
        let startingDisplayedBalance = gameState.finance.displayedBalance
        let purchaseState = TestPurchasableState()
        let item = TestPurchaseItem(
            id: "neighborhood-flyers",
            name: "Neighborhood Flyers",
            description: "Post flyers throughout the neighborhood.",
            price: 25,
            paymentSchedule: .oneTime
        )

        let result = workflow.completePurchase(
            state: purchaseState,
            item: item
        )

        guard case .completed = result else {
            Issue.record("Expected the purchase to complete.")
            return
        }

        #expect(purchaseState.upgradeIsActive)
        #expect(!purchaseState.didRevertUpgrade)
        #expect(gameState.finance.actualBalance == startingActualBalance)
        #expect(
            gameState.finance.displayedBalance
                == startingDisplayedBalance - 25
        )
        #expect(
            !gameState.upgradeTracker.canUpgrade(
                .advertisement,
                on: gameState.calendar.simulationDay
            )
        )
        #expect(gameState.pendingBusinessEvents.count == 1)

        let event = try #require(gameState.pendingBusinessEvents.first)
        let transaction = try #require(event.financialTransaction)
        #expect(event.simulationDay == gameState.calendar.simulationDay)
        #expect(event.calendarDate == gameState.calendar.currentDate)
        #expect(event.title == "Neighborhood Flyers")
        #expect(
            event.details == "Post flyers throughout the neighborhood."
        )
        #expect(transaction.amount == 25)
        #expect(transaction.direction == .outflow)

        guard case let .purchase(purchaseEvent) = event.type else {
            Issue.record("Expected a purchase event.")
            return
        }
        #expect(purchaseEvent.category == .advertisement)
        #expect(purchaseEvent.itemID == "neighborhood-flyers")

        let savedGame = try #require(repository.savedGame)
        #expect(savedGame.finance.actualBalance == startingActualBalance)
        #expect(savedGame.pendingBusinessEvents.count == 1)
    }

    @Test
    func scheduledPurchasesDoNotCreateImmediateOutflows() {
        for schedule in [PaymentSchedule.daily, .weekly] {
            let gameState = makeGameState()
            let repository = TestGameSaveRepository()
            let workflow = PurchaseWorkflow(
                gameState: gameState,
                saveRepository: repository
            )
            let startingDisplayedBalance =
                gameState.finance.displayedBalance
            let purchaseState = TestPurchasableState()
            let item = TestPurchaseItem(
                id: "scheduled-ad",
                name: "Scheduled Advertisement",
                price: 40,
                paymentSchedule: schedule
            )

            let result = workflow.completePurchase(
                state: purchaseState,
                item: item
            )

            guard case .completed = result else {
                Issue.record("Expected the scheduled purchase to complete.")
                continue
            }

            #expect(
                gameState.finance.displayedBalance
                    == startingDisplayedBalance
            )
            #expect(
                gameState.pendingBusinessEvents.last?.financialTransaction
                    == nil
            )
            #expect(repository.savedGame != nil)
        }
    }
}

// MARK: - Failed Purchase Rollback

extension PurchaseWorkflowTests {

    @Test
    func failedSaveRestoresAllPurchaseState() {
        let gameState = makeGameState()
        let existingEvent = makeBusinessEvent(
            itemID: "existing-event",
            amount: 10
        )
        gameState.pendingBusinessEvents = [existingEvent]
        let startingActualBalance = gameState.finance.actualBalance
        let startingDisplayedBalance = gameState.finance.displayedBalance
        let repository = TestGameSaveRepository(shouldFailSave: true)
        let workflow = PurchaseWorkflow(
            gameState: gameState,
            saveRepository: repository
        )
        let purchaseState = TestPurchasableState()
        let item = TestPurchaseItem(
            id: "failed-purchase",
            name: "Failed Purchase",
            price: 25,
            paymentSchedule: .oneTime
        )

        let result = workflow.completePurchase(
            state: purchaseState,
            item: item
        )

        guard case .saveFailed = result else {
            Issue.record("Expected the purchase save to fail.")
            return
        }

        #expect(!purchaseState.upgradeIsActive)
        #expect(purchaseState.didRevertUpgrade)
        #expect(gameState.finance.actualBalance == startingActualBalance)
        #expect(gameState.finance.displayedBalance == startingDisplayedBalance)
        #expect(
            gameState.upgradeTracker.canUpgrade(
                .advertisement,
                on: gameState.calendar.simulationDay
            )
        )
        #expect(gameState.pendingBusinessEvents.map(\.id) == [existingEvent.id])
    }
}

// MARK: - Pending Events and Cash Flow

extension PurchaseWorkflowTests {

    @Test
    func pendingOutflowTotalIncludesOnlyOutflows() {
        let gameState = GameState()
        gameState.pendingBusinessEvents = [
            makeBusinessEvent(itemID: "outflow-one", amount: 25),
            makeBusinessEvent(itemID: "outflow-two", amount: 15),
            makeBusinessEvent(
                itemID: "inflow",
                amount: 100,
                direction: .inflow
            ),
            makeBusinessEvent(itemID: "no-transaction")
        ]

        #expect(gameState.pendingOutflowTotal == 40)
    }

    @Test
    func movingEventsCreatesCostsOnlyForOutflowsAndClearsPending() {
        let gameState = GameState()
        let summary = DaySummary(day: 1, startingBalance: 200)
        let outflow = makeBusinessEvent(
            itemID: "outflow",
            title: "Purchased Oven",
            amount: 75
        )
        let inflow = makeBusinessEvent(
            itemID: "inflow",
            amount: 20,
            direction: .inflow
        )
        let scheduled = makeBusinessEvent(itemID: "scheduled")
        gameState.pendingBusinessEvents = [outflow, inflow, scheduled]

        gameState.movePendingBusinessEvents(to: summary)
        gameState.movePendingBusinessEvents(to: summary)

        #expect(
            summary.businessEvents.map(\.id)
                == [outflow.id, inflow.id, scheduled.id]
        )
        #expect(summary.cashFlowCosts.count == 1)
        #expect(summary.cashFlowCosts.first?.name == "Purchased Oven")
        #expect(summary.cashFlowCosts.first?.amount == 75)
        #expect(gameState.pendingBusinessEvents.isEmpty)
    }
}

// MARK: - Restore Pending Outflows

extension PurchaseWorkflowTests {

    @Test
    func restoreRebuildsDisplayedBalanceFromPendingOutflows() throws {
        let originalState = makeGameState()
        originalState.finance.actualBalance = 500
        originalState.finance.displayedBalance = 999
        originalState.pendingBusinessEvents = [
            makeBusinessEvent(itemID: "outflow-one", amount: 50),
            makeBusinessEvent(itemID: "outflow-two", amount: 30),
            makeBusinessEvent(
                itemID: "inflow",
                amount: 200,
                direction: .inflow
            ),
            makeBusinessEvent(itemID: "scheduled")
        ]
        let save = GameSave(gameState: originalState)
        let restoredState = GameState()

        try restoredState.restoreBusiness(from: save)

        #expect(restoredState.finance.actualBalance == 500)
        #expect(restoredState.finance.displayedBalance == 420)
        #expect(restoredState.pendingOutflowTotal == 80)
    }
}

private enum TestSaveError: Error {
    case failed
}

private struct TestPurchaseItem: PurchasableItem {
    let id: String
    let name: String
    var description: String = ""
    let price: Double
    let paymentSchedule: PaymentSchedule

    var purchaseItemID: String {
        id
    }
}

private final class TestPurchasableState: PurchasableState {
    var dimensionID: UpgradeCategory {
        .advertisement
    }

    private(set) var upgradeIsActive = false
    private(set) var didRevertUpgrade = false

    func captureRollbackState() -> Bool {
        upgradeIsActive
    }

    func applyUpgrade(_ item: TestPurchaseItem) {
        upgradeIsActive = true
    }

    func revertUpgrade(to state: Bool) {
        upgradeIsActive = state
        didRevertUpgrade = true
    }
}

private final class TestGameSaveRepository: GameSaveRepository {
    private let shouldFailSave: Bool
    private(set) var savedGame: GameSave?

    init(shouldFailSave: Bool = false) {
        self.shouldFailSave = shouldFailSave
    }

    func save(_ gameSave: GameSave) throws {
        if shouldFailSave {
            throw TestSaveError.failed
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

private func makeWorkflow(
    gameState: GameState
) -> PurchaseWorkflow {
    PurchaseWorkflow(
        gameState: gameState,
        saveRepository: TestGameSaveRepository()
    )
}

private func makeGameState() -> GameState {
    let product = ProductCatalog().products.first {
        $0.id == .smoothies
    }!
    let gameState = GameState()
    gameState.initializeBusiness(product: product)
    return gameState
}

private func makeBusinessEvent(
    itemID: String,
    title: String = "Business Event",
    amount: Double? = nil,
    direction: CashFlowDirection = .outflow
) -> BusinessEvent {
    BusinessEvent(
        simulationDay: 1,
        calendarDate: GameCalendar.defaultStartDate,
        type: .purchase(
            PurchaseEvent(
                category: .advertisement,
                itemID: itemID
            )
        ),
        title: title,
        financialTransaction: amount.map {
            FinancialTransaction(
                amount: $0,
                direction: direction
            )
        }
    )
}
