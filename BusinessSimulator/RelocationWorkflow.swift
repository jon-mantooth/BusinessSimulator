import Foundation

struct RelocationDimensionAvailabilityRequest {}

enum RelocationDimensionAvailability: Equatable {
    case available
    case upgradeMadeToday
    case pendingBusinessEvents
}

enum RelocationWorkflowResult {
    case completed(DaySummary)
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
    let saveRepository: any GameSaveRepository

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

    /// Pro-rate weekly costs for the last week before relocation based on
    /// number of operational days (moving day is not an operational day).
    /// No daily costs will be deducted for moving day as it is not an operational day
    private func calculateProratedWeeklyCost(
        summary: DaySummary
    ) -> Double {
        let currentWeekday = gameState.calendar.currentWeekday
        guard currentWeekday != .saturday,
              currentWeekday != .sunday else {
            preconditionFailure(
                "Relocation must occur on an operating weekday."
            )
        }

        if currentWeekday == .monday {
            return 0
        }

        let completedOperatingDays = Double(
            currentWeekday.rawValue - GameWeekday.monday.rawValue
        )

        let proratedWeeklyCost = gameState.departments.reduce(0.0) {
            total, department in
            total + department.calculateWeeklyCosts(
                summary: summary,
                multiplier: completedOperatingDays / 5.0
            )
        }

        return proratedWeeklyCost
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

        let relocationEvent = BusinessEvent(
            simulationDay: gameState.calendar.simulationDay,
            calendarDate: gameState.calendar.currentDate,
            type: .relocation(
                RelocationEvent(
                    previousLocationID:
                        rollbackSnapshot.activeLocationID,
                    newLocationID: request.destination.id
                )
            ),
            title: "Relocated to \(request.destination.name)",
            details: request.destination.description,
            financialTransaction: FinancialTransaction(
                amount: request.relocationPrice,
                direction: .outflow
            )
        )

        let relocationSummary = DaySummary(
            day: gameState.calendar.simulationDay,
            startingBalance: gameState.finance.actualBalance,
            type: .relocation
        )
        relocationSummary.businessEvents.append(relocationEvent)
        relocationSummary.cashFlowCosts.append(
            Cost(
                name: "Relocation",
                amount: request.relocationPrice
            )
        )
        _ = calculateProratedWeeklyCost(
            summary: relocationSummary
        )

        gameState.finance.actualBalance = relocationSummary.balance
        gameState.finance.displayedBalance = relocationSummary.balance
        gameState.calendar.prepareForNewOperatingPeriod()
        gameState.locationState!.relocate(
            to: request.destination.id
        )
        gameState.simulationSummary.daySummaries.append(
            relocationSummary
        )

        do {
            try saveRepository.save(
                GameSave(gameState: gameState)
            )

            return .completed(relocationSummary)
        } catch {
            restoreGameState(from: rollbackSnapshot)
            return .saveFailed
        }
    }

    private func restoreGameState(
        from snapshot: RollbackSnapshot
    ) {
        gameState.locationState!.relocate(
            to: snapshot.activeLocationID
        )
        gameState.calendar.revert(to: snapshot.calendarState)
        gameState.finance.actualBalance = snapshot.actualBalance
        gameState.finance.displayedBalance = snapshot.displayedBalance

        let addedSummaryCount =
            gameState.simulationSummary.daySummaries.count
            - snapshot.summaryCount
        precondition(
            addedSummaryCount == 1,
            "Relocation must append exactly one summary before rollback."
        )
        gameState.simulationSummary.daySummaries.removeLast()
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
