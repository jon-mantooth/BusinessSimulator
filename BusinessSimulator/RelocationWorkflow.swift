import Foundation

struct RelocationDimensionAvailabilityRequest {}

enum RelocationDimensionAvailability: Equatable {
    case available
    case upgradeMadeToday
    case pendingBusinessEvents
}

enum RelocationWorkflowResult {
    case completed
    case unavailable(RelocationItemAvailability)
    case saveFailed
}

enum RelocationRequirement: CaseIterable, Equatable {
    case storageLevel
    case transportationLevel
    case equipmentLevel
    case laborLevel
    case advertisementLevel
    case businessReputation
}

/// The minimum business progress required to relocate to a destination.
struct RelocationRequirements: Equatable {
    let storageLevel: Int
    let transportationLevel: Int
    let equipmentLevel: Int
    let laborLevel: Int
    let advertisementLevel: Int
    let businessReputation: Double
}

struct RelocationRequirementStatus: Equatable {
    let requirement: RelocationRequirement
    let requiredValue: Double
    let currentValue: Double?

    var isMet: Bool {
        guard let currentValue else {
            return false
        }

        return currentValue >= requiredValue
    }
}

struct RelocationItemAvailability: Equatable {
    let requirements: [RelocationRequirementStatus]
    let financialAvailability: PurchaseAvailability

    var canRelocate: Bool {
        requirements.allSatisfy(\.isMet)
            && financialAvailability == .available
    }

    var unmetRequirements: [RelocationRequirementStatus] {
        requirements.filter { !$0.isMet }
    }
}

struct RelocationRequest {
    let destination: Location
    let requirements: RelocationRequirements
    let relocationPrice: Double
}

/// Evaluates whether the business is ready to relocate. Transaction behavior
/// will be added once the immediate and recurring relocation effects have
/// been defined.
struct RelocationWorkflow {
    private struct RollbackSnapshot {
        let activeLocationID: LocationID
        let calendarState: GameCalendar.RollbackState
        let actualBalance: Double
        let displayedBalance: Double
        let summaryCount: Int
    }

    let gameState: GameState

    private func captureRollbackSnapshot() -> RollbackSnapshot {
        RollbackSnapshot(
            activeLocationID: gameState.locationState!.activeLocationID,
            calendarState: gameState.calendar.captureRollbackState(),
            actualBalance: gameState.finance.actualBalance,
            displayedBalance: gameState.finance.displayedBalance,
            summaryCount:
                gameState.simulationSummary.daySummaries.count
        )
    }

    func dimensionAvailability(
        for request: RelocationDimensionAvailabilityRequest
    ) -> RelocationDimensionAvailability {
        if gameState.upgradeTracker.hasUpgrade(
            on: gameState.calendar.simulationDay
        ) {
            return .upgradeMadeToday
        }

        guard gameState.pendingBusinessEvents.isEmpty else {
            return .pendingBusinessEvents
        }

        return .available
    }

    func itemAvailability(
        for request: RelocationRequest
    ) -> RelocationItemAvailability {
        RelocationItemAvailability(
            requirements: requirementStatuses(for: request),
            financialAvailability: gameState.finance.purchaseAvailability(
                for: request.relocationPrice
            )
        )
    }

    func complete(
        _ request: RelocationRequest
    ) -> RelocationWorkflowResult {
        let availability = itemAvailability(for: request)
        guard availability.canRelocate else {
            return .unavailable(availability)
        }

        let rollbackSnapshot = captureRollbackSnapshot()

        gameState.finance.displayedBalance -= request.relocationPrice
        gameState.calendar.prepareForNewSeason()
        gameState.locationState!.relocate(
            to: request.destination.id
        )

        // The remaining relocation transaction will use this snapshot to
        // restore GameState if persistence fails.
        _ = rollbackSnapshot
        preconditionFailure(
            "The relocation transaction has not been implemented yet."
        )
    }

    private func requirementStatuses(
        for request: RelocationRequest
    ) -> [RelocationRequirementStatus] {
        let required = request.requirements

        return [
            RelocationRequirementStatus(
                requirement: .storageLevel,
                requiredValue: Double(required.storageLevel),
                currentValue: nil
            ),
            RelocationRequirementStatus(
                requirement: .transportationLevel,
                requiredValue: Double(required.transportationLevel),
                currentValue: nil
            ),
            RelocationRequirementStatus(
                requirement: .equipmentLevel,
                requiredValue: Double(required.equipmentLevel),
                currentValue: gameState.equipmentState.map {
                    Double($0.activePrimaryEquipment.tierLevel)
                }
            ),
            RelocationRequirementStatus(
                requirement: .laborLevel,
                requiredValue: Double(required.laborLevel),
                currentValue: gameState.laborState.map {
                    Double($0.ownedLabor.labor.count)
                }
            ),
            RelocationRequirementStatus(
                requirement: .advertisementLevel,
                requiredValue: Double(required.advertisementLevel),
                currentValue: gameState.advertisementState?.activeTier.map {
                    Double($0.level)
                }
            ),
            RelocationRequirementStatus(
                requirement: .businessReputation,
                requiredValue: required.businessReputation,
                currentValue: gameState.reputation?.starRating
            )
        ]
    }
}
