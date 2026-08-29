//
//  PurchaseWorkflow.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 8/28/26.
//

import Foundation

protocol PurchasableItem {
    var purchaseItemID: String { get }
    var name: String { get }
    var description: String { get }
    var price: Double { get }
    var paymentSchedule: PaymentSchedule { get }
}

protocol PurchasableState: AnyObject {
    associatedtype PurchaseItem: PurchasableItem
    associatedtype RollbackState

    var dimensionID: PurchaseCategory { get }

    func captureRollbackState() -> RollbackState

    func applyUpgrade(_ item: PurchaseItem)

    func revertUpgrade(to state: RollbackState)
}

enum PurchaseWorkflowResult {
    case completed
    case saveFailed
}

/// Coordinates the shared purchase process used by advertisements,
/// equipment, labor, transportation, and storage.
struct PurchaseWorkflow {
    private struct RollbackSnapshot {
        let actualBalance: Double
        let displayedBalance: Double
        let upgradeTracker: UpgradeTracker
        let pendingBusinessEvents: [BusinessEvent]
    }

    let gameState: GameState
    let saveRepository: any GameSaveRepository

    // MARK: - Before Purchase

    func validateUpgradeAvailability(
        category: PurchaseCategory
    ) -> Bool {
        gameState.upgradeTracker.canUpgrade(
            category,
            on: gameState.calendar!.simulationDay
        )
    }

    func validateFinancialAvailability(
        price: Double
    ) -> PurchaseAvailability {
        gameState.finance!.purchaseAvailability(for: price)
    }

    // MARK: - Purchase Transaction

    func completePurchase<State: PurchasableState>(
        state: State,
        item: State.PurchaseItem
    ) -> PurchaseWorkflowResult {
        // 1. Capture a rollback snapshot before mutating GameState.
        let rollbackSnapshot = RollbackSnapshot(
            actualBalance: gameState.finance!.actualBalance,
            displayedBalance: gameState.finance!.displayedBalance,
            upgradeTracker: gameState.upgradeTracker,
            pendingBusinessEvents: gameState.pendingBusinessEvents
        )

        //Capture rollback state in case we need to revert. Upgrade state
        let dimensionRollbackState = state.captureRollbackState()
        state.applyUpgrade(item)

        // Reserve any immediate payment in displayed balance. The actual
        // balance is settled from cashFlowCosts when the day is completed.
        if item.paymentSchedule == .oneTime {
            gameState.finance!.displayedBalance -= item.price
        }

        // Record the upgrade in UpgradeTracker.
        gameState.upgradeTracker.recordUpgrade(
            state.dimensionID,
            on: gameState.calendar!.simulationDay
        )

        // Create a BusinessEvent for the purchase.
        let purchaseCategory = state.dimensionID

        let financialTransaction = item.paymentSchedule == .oneTime
            ? FinancialTransaction(
                amount: item.price,
                direction: .outflow
            )
            : nil

        let businessEvent = BusinessEvent(
            simulationDay: gameState.calendar!.simulationDay,
            calendarDate: gameState.calendar!.currentDate,
            type: .purchase(
                PurchaseEvent(
                    category: purchaseCategory,
                    itemID: item.purchaseItemID
                )
            ),
            title: item.name,
            details: item.description,
            financialTransaction: financialTransaction
        )

        // Append the BusinessEvent to pendingBusinessEvents.
        gameState.pendingBusinessEvents.append(businessEvent)

        // Save the complete GameState. If saving succeeds, return .completed so the view can return
        // to the department view. If saving fails, restore the shared rollback snapshot and the
        // dimension-specific state, then return .saveFailed so the view can present an error.
        do {
            try saveRepository.save(
                GameSave(gameState: gameState)
            )

            return .completed
        } catch {
            restoreGameState(
                from: rollbackSnapshot,
                state: state,
                dimensionRollbackState: dimensionRollbackState
            )

            return .saveFailed
        }
    }

    private func restoreGameState<State: PurchasableState>(
        from snapshot: RollbackSnapshot,
        state: State,
        dimensionRollbackState: State.RollbackState
    ) {
        gameState.finance!.actualBalance = snapshot.actualBalance
        gameState.finance!.displayedBalance = snapshot.displayedBalance
        gameState.upgradeTracker = snapshot.upgradeTracker
        gameState.pendingBusinessEvents = snapshot.pendingBusinessEvents
        state.revertUpgrade(to: dimensionRollbackState)
    }
}
