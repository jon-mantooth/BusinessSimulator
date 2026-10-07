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
    case unavailable(PurchaseAvailability)
    case saveFailed
}

struct PurchaseDimensionAvailabilityRequest {}

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
struct PurchaseWorkflow: Workflow {
    typealias DimensionAvailabilityRequest =
        PurchaseDimensionAvailabilityRequest
    typealias DimensionAvailability = PurchaseDimensionAvailability
    typealias ItemRequest = PurchaseRequest
    typealias ItemAvailability = PurchaseAvailability
    typealias CompletionResult = PurchaseWorkflowResult

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
            during: gameState.calendar.currentWeekStartDate
        ) ? .available : .upgradeLimitReached
    }

    func itemAvailability(
        for request: PurchaseRequest
    ) -> PurchaseAvailability {
        let locationAvailability = locationAvailability(
            requiredTier: request.requiredLocationTier
        )

        guard case .available = locationAvailability else {
            return locationAvailability
        }

        return financialAvailability(price: request.price)
    }

    func locationAvailability(
        requiredTier: LocationTierLevel?
    ) -> PurchaseAvailability {
        guard let requiredTier else {
            return .available
        }

        let activeLocationTier = gameState.locationState!.activeTier.level

        guard activeLocationTier >= requiredTier else {
            return .locationLocked(requiredTier: requiredTier)
        }

        return .available
    }

    func financialAvailability(
        price: Double
    ) -> PurchaseAvailability {
        gameState.finance!.purchaseAvailability(for: price)
    }

    // MARK: - Purchase Transaction

    func completePurchase<State: PurchasableState>(
        state: State,
        item: State.PurchaseItem,
        pendingUpgrade: PendingUpgrade? = nil
    ) -> PurchaseWorkflowResult {
        complete(
            PurchaseRequest(
                state: state,
                item: item,
                pendingUpgrade: pendingUpgrade
            )
        )
    }

    func complete(
        _ request: PurchaseRequest
    ) -> PurchaseWorkflowResult {
        let availability = itemAvailability(for: request)
        guard case .available = availability else {
            return .unavailable(availability)
        }

        // 1. Capture a rollback snapshot before mutating GameState.
        let rollbackSnapshot = RollbackSnapshot(
            actualBalance: gameState.finance!.actualBalance,
            displayedBalance: gameState.finance!.displayedBalance,
            upgradeTracker: gameState.upgradeTracker,
            pendingBusinessEvents: gameState.pendingBusinessEvents,
            pendingUpgrades: gameState.pendingUpgrades
        )

        // Capture the concrete dimension's rollback operation before applying
        // its type-erased upgrade.
        let revertDimension = request.captureRollback()
        request.applyUpgrade()

        if let pendingUpgrade = request.pendingUpgrade {
            gameState.pendingUpgrades.append(pendingUpgrade)
        }

        // Reserve any immediate payment in displayed balance. The actual
        // balance is settled from cashFlowCosts when the day is completed.
        if request.paymentSchedule == .oneTime {
            gameState.finance!.displayedBalance -= request.price
        }

        // Record the upgrade in UpgradeTracker.
        gameState.upgradeTracker.recordUpgrade(
            on: gameState.calendar.simulationDay,
            weekStarting: gameState.calendar.currentWeekStartDate
        )

        // Create a BusinessEvent for the purchase.
        let financialTransaction = request.paymentSchedule == .oneTime
            ? FinancialTransaction(
                amount: request.price,
                direction: .outflow
            )
            : nil

        let businessEvent = BusinessEvent(
            simulationDay: gameState.calendar!.simulationDay,
            calendarDate: gameState.calendar!.currentDate,
            type: .purchase(
                PurchaseEvent(
                    category: request.purchaseCategory,
                    itemID: request.purchaseItemID
                )
            ),
            title: request.name,
            details: request.description,
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
                revertDimension: revertDimension
            )

            return .saveFailed
        }
    }

    private func restoreGameState(
        from snapshot: RollbackSnapshot,
        revertDimension: () -> Void
    ) {
        gameState.finance!.actualBalance = snapshot.actualBalance
        gameState.finance!.displayedBalance = snapshot.displayedBalance
        gameState.upgradeTracker = snapshot.upgradeTracker
        gameState.pendingBusinessEvents = snapshot.pendingBusinessEvents
        gameState.pendingUpgrades = snapshot.pendingUpgrades
        revertDimension()
    }
}
