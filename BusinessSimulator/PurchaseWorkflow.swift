//
//  PurchaseWorkflow.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 8/28/26.
//

import Foundation

enum PendingUpgrade: Equatable, Codable {
    case ingredient(IngredientUpgrade)
}

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

struct PurchaseDimensionAvailabilityRequest {
    let category: PurchaseCategory
}

enum PurchaseDimensionAvailability: Equatable {
    case available
    case upgradeLimitReached
}

/// Hides the concrete PurchasableState and item types while preserving the
/// state-specific operations needed to complete or revert the purchase.
struct PurchaseRequest {
    let purchaseItemID: String
    let name: String
    let description: String
    let price: Double
    let paymentSchedule: PaymentSchedule
    let purchaseCategory: PurchaseCategory
    let requiredLocationTier: LocationTierLevel?
    let pendingUpgrade: PendingUpgrade?

    private let captureDimensionRollback: () -> () -> Void
    private let applyDimensionUpgrade: () -> Void

    init<State: PurchasableState>(
        state: State,
        item: State.PurchaseItem,
        requiredLocationTier: LocationTierLevel? = nil,
        pendingUpgrade: PendingUpgrade? = nil
    ) {
        self.purchaseItemID = item.purchaseItemID
        self.name = item.name
        self.description = item.description
        self.price = item.price
        self.paymentSchedule = item.paymentSchedule
        self.purchaseCategory = state.dimensionID
        self.requiredLocationTier = requiredLocationTier
        self.pendingUpgrade = pendingUpgrade
        self.captureDimensionRollback = {
            let rollbackState = state.captureRollbackState()
            return {
                state.revertUpgrade(to: rollbackState)
            }
        }
        self.applyDimensionUpgrade = {
            state.applyUpgrade(item)
        }
    }

    func captureRollback() -> () -> Void {
        captureDimensionRollback()
    }

    func applyUpgrade() {
        applyDimensionUpgrade()
    }
}

/// Coordinates the shared purchase process used by advertisements,
/// equipment, labor, transportation, and storage.
struct PurchaseWorkflow {
    private struct RollbackSnapshot {
        let actualBalance: Double
        let displayedBalance: Double
        let upgradeTracker: UpgradeTracker
        let pendingBusinessEvents: [BusinessEvent]
        let pendingUpgrades: [PendingUpgrade]
    }

    let gameState: GameState
    let saveRepository: any GameSaveRepository

    // MARK: - Before Purchase

    func dimensionAvailability(
        for request: PurchaseDimensionAvailabilityRequest
    ) -> PurchaseDimensionAvailability {
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

    /// Location eligibility is checked before finances so the player is not
    /// encouraged to save for an upgrade that is unavailable at this level.
    func validatePurchaseAvailability(
        price: Double,
        requiredLocationTier: LocationTierLevel
    ) -> PurchaseAvailability {
        let activeLocationTier = gameState.locationState!.activeTier.level

        guard activeLocationTier >= requiredLocationTier else {
            return .locationLocked(requiredTier: requiredLocationTier)
        }

        return validateFinancialAvailability(price: price)
    }

    // MARK: - Purchase Transaction

    func completePurchase<State: PurchasableState>(
        state: State,
        item: State.PurchaseItem,
        pendingUpgrade: PendingUpgrade? = nil
    ) -> PurchaseWorkflowResult {
        // 1. Capture a rollback snapshot before mutating GameState.
        let rollbackSnapshot = RollbackSnapshot(
            actualBalance: gameState.finance!.actualBalance,
            displayedBalance: gameState.finance!.displayedBalance,
            upgradeTracker: gameState.upgradeTracker,
            pendingBusinessEvents: gameState.pendingBusinessEvents,
            pendingUpgrades: gameState.pendingUpgrades
        )

        //Capture rollback state in case we need to revert. Upgrade state
        let dimensionRollbackState = state.captureRollbackState()
        state.applyUpgrade(item)

        if let pendingUpgrade {
            gameState.pendingUpgrades.append(pendingUpgrade)
        }

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
        gameState.pendingUpgrades = snapshot.pendingUpgrades
        state.revertUpgrade(to: dimensionRollbackState)
    }
}
