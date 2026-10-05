import Foundation
import Testing
@testable import BusinessSimulator

struct RelocationWorkflowTests {}

// MARK: - Dimension Availability

extension RelocationWorkflowTests {

    @Test
    func sameDayUpgradeBlocksRelocation() {
        let gameState = relocationTestGameState()
        gameState.upgradeTracker.recordUpgrade(
            on: gameState.calendar.simulationDay,
            weekStarting: gameState.calendar.currentWeekStartDate
        )

        #expect(
            relocationTestWorkflow(gameState: gameState)
                .dimensionAvailability(
                    for: RelocationDimensionAvailabilityRequest()
                ) == .upgradeMadeToday
        )
    }

    @Test
    func earlierUpgradeInSameWeekDoesNotBlockRelocation() {
        let gameState = relocationTestGameState()
        gameState.upgradeTracker.recordUpgrade(
            on: gameState.calendar.simulationDay,
            weekStarting: gameState.calendar.currentWeekStartDate
        )
        gameState.calendar.advanceDay()

        #expect(
            relocationTestWorkflow(gameState: gameState)
                .dimensionAvailability(
                    for: RelocationDimensionAvailabilityRequest()
                ) == .available
        )
    }

    @Test
    func pendingBusinessEventsBlockRelocationIndependently() {
        let gameState = relocationTestGameState()
        gameState.pendingBusinessEvents = [relocationTestBusinessEvent()]

        #expect(
            relocationTestWorkflow(gameState: gameState)
                .dimensionAvailability(
                    for: RelocationDimensionAvailabilityRequest()
                ) == .pendingBusinessEvents
        )
    }

    @Test
    func untouchedTrackerAndNoPendingEventsAllowRelocationChecks() {
        let gameState = relocationTestGameState()

        #expect(
            relocationTestWorkflow(gameState: gameState)
                .dimensionAvailability(
                    for: RelocationDimensionAvailabilityRequest()
                ) == .available
        )
    }
}

// MARK: - Item Availability

extension RelocationWorkflowTests {

    @Test
    func availabilityReportsEveryRequirementStatus() throws {
        let gameState = relocationTestGameState()
        let request = try relocationTestRequest(gameState: gameState)
        let availability = relocationTestWorkflow(gameState: gameState)
            .itemAvailability(for: request)

        #expect(
            availability.requirements.count
                == RelocationRequirement.allCases.count
        )
        #expect(
            RelocationRequirement.allCases.allSatisfy { requirement in
                availability.requirements.contains {
                    $0.requirement == requirement
                }
            }
        )

        for status in availability.requirements {
            switch status.requirement {
            case .storageLevel:
                #expect(
                    status.requiredValue
                        == Double(request.requirements.storageLevel)
                )
                #expect(status.currentValue == nil)
                #expect(status.isMet)
            case .transportationLevel:
                #expect(
                    status.requiredValue
                        == Double(request.requirements.transportationLevel)
                )
                #expect(status.currentValue == nil)
                #expect(status.isMet)
            case .equipmentLevel:
                #expect(
                    status.currentValue
                        == Double(
                            gameState.equipmentState!
                                .activePrimaryEquipment.tierLevel
                        )
                )
            case .laborLevel:
                #expect(
                    status.currentValue
                        == Double(gameState.laborState!.ownedLabor.labor.count)
                )
            case .advertisementLevel:
                #expect(
                    status.currentValue
                        == Double(gameState.advertisementState!.activeTier!.level)
                )
            case .businessReputation:
                #expect(
                    status.currentValue == gameState.reputation!.starRating
                )
            }
        }
    }

    @Test
    func newBusinessDoesNotMeetRequirements() throws {
        let gameState = relocationTestGameState()
        let request = try relocationTestRequest(gameState: gameState)
        gameState.finance.displayedBalance =
            request.relocationPrice
                + gameState.finance.minimumOperatingAllowance
        let availability = relocationTestWorkflow(gameState: gameState)
            .itemAvailability(for: request)

        #expect(!availability.canRelocate)
        #expect(!availability.unmetRequirements.isEmpty)
        #expect(availability.financialAvailability == .available)
    }

    @Test
    func satisfyingImplementedRequirementsMakesItemAvailable() throws {
        let gameState = relocationTestGameState()
        let request = try relocationTestRequest(gameState: gameState)
        try satisfyRelocationRequirements(
            request.requirements,
            gameState: gameState
        )
        gameState.finance.displayedBalance =
            request.relocationPrice
                + gameState.finance.minimumOperatingAllowance
        let availability = relocationTestWorkflow(gameState: gameState)
            .itemAvailability(for: request)

        #expect(availability.requirements.allSatisfy(\.isMet))
        #expect(availability.financialAvailability == .available)
        #expect(availability.canRelocate)
    }

    @Test(arguments: implementedRelocationRequirements)
    func eachImplementedRequirementCanIndependentlyBlockRelocation(
        requirement: RelocationRequirement
    ) throws {
        let gameState = relocationTestGameState()
        let request = try relocationTestRequest(
            gameState: gameState,
            onlyRequiring: requirement
        )
        gameState.finance.displayedBalance =
            request.relocationPrice
                + gameState.finance.minimumOperatingAllowance
        let availability = relocationTestWorkflow(gameState: gameState)
            .itemAvailability(for: request)

        #expect(
            availability.unmetRequirements.map(\.requirement)
                == [requirement]
        )
        #expect(!availability.canRelocate)
    }

    @Test
    func requirementAndFinancialFailuresAreReportedSeparately() throws {
        let gameState = relocationTestGameState()
        let request = try relocationTestRequest(gameState: gameState)
        gameState.finance.displayedBalance = 0
        let availability = relocationTestWorkflow(gameState: gameState)
            .itemAvailability(for: request)

        #expect(!availability.unmetRequirements.isEmpty)
        #expect(availability.financialAvailability == .insufficientFunds)
        #expect(!availability.canRelocate)
    }

    @Test
    func metRequirementsStillEnforceInsufficientFunds() throws {
        let gameState = relocationTestGameState()
        let request = try relocationTestRequest(gameState: gameState)
        try satisfyRelocationRequirements(
            request.requirements,
            gameState: gameState
        )
        gameState.finance.displayedBalance = request.relocationPrice - 1
        let availability = relocationTestWorkflow(gameState: gameState)
            .itemAvailability(for: request)

        #expect(availability.requirements.allSatisfy(\.isMet))
        #expect(availability.financialAvailability == .insufficientFunds)
        #expect(!availability.canRelocate)
    }

    @Test
    func metRequirementsStillEnforceOperatingReserve() throws {
        let gameState = relocationTestGameState()
        let request = try relocationTestRequest(gameState: gameState)
        try satisfyRelocationRequirements(
            request.requirements,
            gameState: gameState
        )
        gameState.finance.displayedBalance =
            request.relocationPrice
                + gameState.finance.minimumOperatingAllowance - 1
        let availability = relocationTestWorkflow(gameState: gameState)
            .itemAvailability(for: request)

        #expect(availability.requirements.allSatisfy(\.isMet))
        #expect(
            availability.financialAvailability
                == .operatingReserveRequired
        )
        #expect(!availability.canRelocate)
    }

    @Test
    func unavailableRelocationDoesNotMutateOrSaveState() throws {
        let gameState = relocationTestGameState()
        let request = try relocationTestRequest(gameState: gameState)
        let repository = RelocationTestSaveRepository()
        let workflow = RelocationWorkflow(
            gameState: gameState,
            saveRepository: repository
        )
        let snapshot = RelocationTestSnapshot(gameState: gameState)

        let result = workflow.complete(request)

        guard case .unavailable = result else {
            Issue.record("Expected relocation to remain unavailable.")
            return
        }
        snapshot.expectRestored(in: gameState)
        #expect(repository.saveCallCount == 0)
    }
}

// MARK: - Successful Transaction

extension RelocationWorkflowTests {

    @Test
    func successfulRelocationCreatesEventAndSummary() throws {
        let gameState = relocationTestGameState()
        let startingLocation = gameState.locationState!.activeLocationID
        let startingDay = gameState.calendar.simulationDay
        let startingBalance = 100_000.0
        gameState.finance.actualBalance = startingBalance
        gameState.finance.displayedBalance = startingBalance
        let request = try relocationTestRequest(
            gameState: gameState,
            requirements: emptyRelocationRequirements,
            relocationPrice: 12_345
        )

        let summary = try completedRelocationSummary(
            workflow: relocationTestWorkflow(gameState: gameState),
            request: request
        )

        #expect(summary.type == .relocation)
        #expect(summary.day == startingDay)
        #expect(summary.locationID == startingLocation)
        #expect(summary.startingBalance == startingBalance)
        #expect(summary.businessEvents.count == 1)
        #expect(
            gameState.simulationSummary.daySummaries.count == 1
        )
        #expect(gameState.simulationSummary.daySummaries.first === summary)

        let event = try #require(summary.businessEvents.first)
        guard case let .relocation(relocationEvent) = event.type else {
            Issue.record("Expected a relocation business event.")
            return
        }
        #expect(relocationEvent.previousLocationID == startingLocation)
        #expect(relocationEvent.newLocationID == request.destination.id)
        #expect(event.financialTransaction?.amount == request.relocationPrice)
        #expect(event.financialTransaction?.direction == .outflow)
    }

    @Test
    func relocationPriceAppearsExactlyOnceInCashFlowCosts() throws {
        let gameState = relocationTestGameState()
        gameState.finance.actualBalance = 100_000
        gameState.finance.displayedBalance = 100_000
        let request = try relocationTestRequest(
            gameState: gameState,
            requirements: emptyRelocationRequirements,
            relocationPrice: 12_345
        )

        let summary = try completedRelocationSummary(
            workflow: relocationTestWorkflow(gameState: gameState),
            request: request
        )
        let relocationCosts = summary.cashFlowCosts.filter {
            $0.name == "Relocation"
        }

        #expect(relocationCosts.count == 1)
        #expect(relocationCosts.first?.amount == request.relocationPrice)
    }

    @Test
    func relocationSummaryIncludesProratedWeeklyCosts() throws {
        let gameState = relocationTestGameState()
        let weeklyAdvertisement = try activateFirstWeeklyAdvertisement(
            in: gameState
        )
        gameState.finance.actualBalance = 100_000
        gameState.finance.displayedBalance = 100_000
        let request = try relocationTestRequest(
            gameState: gameState,
            requirements: emptyRelocationRequirements,
            relocationPrice: 12_345
        )
        let completedDays = Double(
            gameState.calendar.currentWeekday.rawValue
                - GameWeekday.monday.rawValue
        )
        let expectedProratedCost =
            weeklyAdvertisement.price * completedDays / 5

        let summary = try completedRelocationSummary(
            workflow: relocationTestWorkflow(gameState: gameState),
            request: request
        )

        #expect(
            summary.cashFlowCosts.contains {
                $0.name == "Relocation"
                    && $0.amount == request.relocationPrice
            }
        )
        #expect(
            summary.cashFlowCosts.contains {
                $0.name.contains("Prorated")
                    && $0.amount == expectedProratedCost
            }
        )
    }

    @Test
    func relocationDayDoesNotRecordOperations() throws {
        let gameState = relocationTestGameState()
        gameState.finance.actualBalance = 100_000
        gameState.finance.displayedBalance = 100_000
        let request = try relocationTestRequest(
            gameState: gameState,
            requirements: emptyRelocationRequirements
        )

        let summary = try completedRelocationSummary(
            workflow: relocationTestWorkflow(gameState: gameState),
            request: request
        )

        #expect(summary.demandedSales == 0)
        #expect(summary.sales == 0)
        #expect(summary.revenue == 0)
        #expect(summary.economicCosts.isEmpty)
        #expect(summary.dailyReputationResult == nil)
        #expect(
            !summary.cashFlowCosts.contains {
                $0.name == "Labor"
                    || $0.name == "Equipment"
            }
        )
    }

    @Test
    func successfulRelocationUpdatesBalancesLocationAndCalendar() throws {
        let gameState = relocationTestGameState()
        let startingDay = gameState.calendar.simulationDay
        let startingBalance = 100_000.0
        gameState.finance.actualBalance = startingBalance
        gameState.finance.displayedBalance = startingBalance
        let request = try relocationTestRequest(
            gameState: gameState,
            requirements: emptyRelocationRequirements,
            relocationPrice: 12_345
        )

        let summary = try completedRelocationSummary(
            workflow: relocationTestWorkflow(gameState: gameState),
            request: request
        )
        let recordedCosts = summary.cashFlowCosts.reduce(0.0) {
            $0 + $1.amount
        }

        #expect(summary.startingBalance == startingBalance)
        #expect(summary.balance == startingBalance - recordedCosts)
        #expect(gameState.finance.actualBalance == summary.balance)
        #expect(gameState.finance.displayedBalance == summary.balance)
        #expect(
            gameState.locationState!.activeLocationID
                == request.destination.id
        )
        #expect(gameState.calendar.simulationDay == startingDay + 1)
        #expect(gameState.calendar.operatingPeriodDay == 0)
    }
}

private let implementedRelocationRequirements: [RelocationRequirement] = [
    .equipmentLevel,
    .laborLevel,
    .advertisementLevel,
    .businessReputation
]

private let emptyRelocationRequirements = RelocationRequirements(
    storageLevel: 0,
    transportationLevel: 0,
    equipmentLevel: 0,
    laborLevel: 0,
    advertisementLevel: 0,
    businessReputation: 0
)

private func relocationTestGameState() -> GameState {
    let gameState = GameState()
    gameState.initializeBusiness(
        product: ProductCatalog().product(for: .pies)
    )
    return gameState
}

private func relocationTestWorkflow(
    gameState: GameState
) -> RelocationWorkflow {
    RelocationWorkflow(
        gameState: gameState,
        saveRepository: RelocationTestSaveRepository()
    )
}

private func relocationTestRequest(
    gameState: GameState,
    onlyRequiring requirement: RelocationRequirement? = nil,
    requirements: RelocationRequirements? = nil,
    relocationPrice: Double = 15_000
) throws -> RelocationRequest {
    let destinationTier = try #require(
        gameState.locationState?.tiers.first {
            $0.level > gameState.locationState!.activeTier.level
        }
    )
    let destination = try #require(destinationTier.locations.first)

    if let requirements {
        return RelocationRequest(
            destination: destination,
            requirements: requirements,
            relocationPrice: relocationPrice
        )
    }

    func requiredValue(
        for candidate: RelocationRequirement,
        value: Int
    ) -> Int {
        requirement == nil || requirement == candidate ? value : 0
    }

    let reputationRequirement =
        requirement == nil || requirement == .businessReputation
            ? 4.2
            : 0

    return RelocationRequest(
        destination: destination,
        requirements: RelocationRequirements(
            storageLevel: 0,
            transportationLevel: 0,
            equipmentLevel: requiredValue(
                for: .equipmentLevel,
                value: 3
            ),
            laborLevel: requiredValue(for: .laborLevel, value: 1),
            advertisementLevel: requiredValue(
                for: .advertisementLevel,
                value: 2
            ),
            businessReputation: reputationRequirement
        ),
        relocationPrice: relocationPrice
    )
}

private func satisfyRelocationRequirements(
    _ requirements: RelocationRequirements,
    gameState: GameState
) throws {
    let equipmentState = try #require(gameState.equipmentState)
    while equipmentState.activePrimaryEquipment.tierLevel
        < requirements.equipmentLevel {
        let nextTier = try #require(equipmentState.nextPrimaryTier)
        let equipment = try #require(nextTier.equipment.first)
        equipmentState.applyUpgrade(equipment)
    }

    let advertisementState = try #require(gameState.advertisementState)
    while (advertisementState.activeTier?.level ?? 0)
        < requirements.advertisementLevel {
        let nextTier = try #require(advertisementState.nextTier)
        let advertisement = try #require(nextTier.advertisements.first)
        advertisementState.applyUpgrade(advertisement)
    }

    let laborState = try #require(gameState.laborState)
    while laborState.ownedLabor.labor.count < requirements.laborLevel {
        let labor = try #require(laborState.availableLabor.labor.first)
        laborState.applyUpgrade(labor)
    }

    let requiredOverallReputation = max(
        0,
        (requirements.businessReputation - 1) / 4 * 100
    )
    gameState.reputation = BusinessReputationState(
        overallReputation: requiredOverallReputation
    )
}

private func activateFirstWeeklyAdvertisement(
    in gameState: GameState
) throws -> Advertisement {
    let advertisementState = try #require(gameState.advertisementState)

    while let nextTier = advertisementState.nextTier {
        if let weeklyAdvertisement = nextTier.advertisements.first(
            where: { $0.paymentSchedule == .weekly }
        ) {
            advertisementState.applyUpgrade(weeklyAdvertisement)
            return weeklyAdvertisement
        }

        let advertisement = try #require(nextTier.advertisements.first)
        advertisementState.applyUpgrade(advertisement)
    }

    Issue.record("Expected the advertisement catalog to contain a weekly option.")
    throw RelocationTestError.weeklyAdvertisementNotFound
}

private func completedRelocationSummary(
    workflow: RelocationWorkflow,
    request: RelocationRequest
) throws -> DaySummary {
    let result = workflow.complete(request)

    guard case let .completed(summary) = result else {
        Issue.record("Expected relocation to complete successfully.")
        throw RelocationTestError.relocationDidNotComplete
    }

    return summary
}

private func relocationTestBusinessEvent() -> BusinessEvent {
    BusinessEvent(
        simulationDay: 1,
        calendarDate: Date(),
        type: .purchase(
            PurchaseEvent(
                category: .advertisement,
                itemID: "relocation-test-purchase"
            )
        ),
        title: "Relocation Test Purchase"
    )
}

private struct RelocationTestSnapshot {
    let locationID: LocationID
    let calendarState: GameCalendar.RollbackState
    let actualBalance: Double
    let displayedBalance: Double
    let summaryCount: Int

    init(gameState: GameState) {
        locationID = gameState.locationState!.activeLocationID
        calendarState = gameState.calendar.captureRollbackState()
        actualBalance = gameState.finance.actualBalance
        displayedBalance = gameState.finance.displayedBalance
        summaryCount = gameState.simulationSummary.daySummaries.count
    }

    func expectRestored(in gameState: GameState) {
        #expect(gameState.locationState!.activeLocationID == locationID)
        #expect(
            gameState.calendar.simulationDay
                == calendarState.simulationDay
        )
        #expect(
            gameState.calendar.operatingPeriodDay
                == calendarState.operatingPeriodDay
        )
        #expect(gameState.calendar.currentDate == calendarState.currentDate)
        #expect(gameState.finance.actualBalance == actualBalance)
        #expect(gameState.finance.displayedBalance == displayedBalance)
        #expect(
            gameState.simulationSummary.daySummaries.count
                == summaryCount
        )
    }
}

private final class RelocationTestSaveRepository: GameSaveRepository {
    private(set) var saveCallCount = 0

    func save(_ gameSave: GameSave) throws {
        saveCallCount += 1
    }

    func load() throws -> GameSave? {
        nil
    }

    func hasSave() -> Bool {
        false
    }

    func deleteSave() throws {}
}

private enum RelocationTestError: Error {
    case relocationDidNotComplete
    case weeklyAdvertisementNotFound
}
