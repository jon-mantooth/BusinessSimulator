//
//  PurchaseWorkflow.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 8/28/26.
//

import Foundation

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
        category: UpgradeCategory
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

    func completePurchase(
        category: UpgradeCategory,
        itemID: String,
        itemName: String,
        itemDescription: String? = nil,
        price: Double,
        paymentSchedule: PaymentSchedule,
        applyUpgrade: () -> Void,
        revertUpgrade: () -> Void
    ) -> PurchaseWorkflowResult {
        // 1. Capture a rollback snapshot before mutating GameState.
        let rollbackSnapshot = RollbackSnapshot(
            actualBalance: gameState.finance!.actualBalance,
            displayedBalance: gameState.finance!.displayedBalance,
            upgradeTracker: gameState.upgradeTracker,
            pendingBusinessEvents: gameState.pendingBusinessEvents
        )

        // 2. Apply the dimension-specific upgrade.
        // TODO: Pass in a PurchasableDimension and its purchase item directly
        // once the protocol's apply and rollback requirements are finalized.
        applyUpgrade()

        // 3. Reserve any immediate payment in displayed balance. The actual
        // balance is settled from cashFlowCosts when the day is completed.
        if paymentSchedule == .oneTime {
            gameState.finance!.displayedBalance -= price
        }

        // 4. Record the upgrade in UpgradeTracker.
        // TODO: Derive this identifier from the PurchasableDimension instead
        // of passing category separately once that protocol is finalized.
        gameState.upgradeTracker.recordUpgrade(
            category,
            on: gameState.calendar!.simulationDay
        )

        // 5. Create a BusinessEvent for the purchase.
        // TODO: Get the item ID, name, description, price, and payment schedule
        // directly from the purchase item once it is passed into this method.
        let purchaseCategory: PurchaseCategory
        switch category {
        case .advertisement:
            purchaseCategory = .advertisement
        case .equipment:
            purchaseCategory = .equipment
        case .labor:
            purchaseCategory = .labor
        case .transportation:
            purchaseCategory = .transportation
        case .storage:
            purchaseCategory = .storage
        }

        let financialTransaction = paymentSchedule == .oneTime
            ? FinancialTransaction(
                amount: price,
                direction: .outflow
            )
            : nil

        let businessEvent = BusinessEvent(
            simulationDay: gameState.calendar!.simulationDay,
            calendarDate: gameState.calendar!.currentDate,
            type: .purchase(
                PurchaseEvent(
                    category: purchaseCategory,
                    itemID: itemID
                )
            ),
            title: itemName,
            details: itemDescription,
            financialTransaction: financialTransaction
        )

        // 6. Append the BusinessEvent to pendingBusinessEvents.
        gameState.pendingBusinessEvents.append(businessEvent)

        // Save the complete GameState. If saving succeeds, return .completed so the view can return
        // to the department view. If saving fails, restore the shared rollback snapshot and the
        // dimension-specific state, then return .saveFailed so the view can present an error.
        do {
            try saveRepository.save(
                GameSave(gameState: gameState)
            )

            // 8. If saving succeeds, return .completed so the view can return
            //    to the department view.
            return .completed
        } catch {
            // 9. If saving fails, restore the shared rollback snapshot and the
            //    dimension-specific state, then return .saveFailed so the view
            //    can present an error.
            restoreGameState(
                from: rollbackSnapshot,
                revertUpgrade: revertUpgrade
            )

            return .saveFailed
        }
    }

    private func restoreGameState(
        from snapshot: RollbackSnapshot,
        revertUpgrade: () -> Void
    ) {
        gameState.finance!.actualBalance = snapshot.actualBalance
        gameState.finance!.displayedBalance = snapshot.displayedBalance
        gameState.upgradeTracker = snapshot.upgradeTracker
        gameState.pendingBusinessEvents = snapshot.pendingBusinessEvents
        revertUpgrade()
    }
}
