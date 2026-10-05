import Foundation
import Testing
@testable import BusinessSimulator

struct LocationTests {}

// MARK: - Location Model and Catalog

extension LocationTests {

    @Test
    func laterLocationTierHasStrongerDemandThanStartingTier() {
        #expect(
            LocationTierLevel.tierTwo.demandMultiplier
                > LocationTierLevel.tierOne.demandMultiplier
        )
    }

    @Test
    func locationTierLevelsSortInProgressionOrder() {
        let levels: [LocationTierLevel] = [.tierTwo, .tierOne]

        #expect(levels.sorted() == [.tierOne, .tierTwo])
    }

    @Test
    func everyProductLocationPathHasStartingAndDestinationTiers() throws {
        let catalog = LocationCatalog()

        for tiers in catalog.tiersByProduct.values {
            let startingTier = try #require(
                tiers.first { $0.level == .tierOne }
            )
            let destinationTier = try #require(
                tiers.first { $0.level == .tierTwo }
            )

            #expect(!startingTier.locations.isEmpty)
            #expect(!destinationTier.locations.isEmpty)
        }
    }

    @Test
    func everyProductLocationPathHasUniqueTierAndLocationIDs() {
        let catalog = LocationCatalog()

        for tiers in catalog.tiersByProduct.values {
            let tierIDs = tiers.map(\.id)
            let locationIDs = tiers.flatMap(\.locations).map(\.id)

            #expect(Set(tierIDs).count == tierIDs.count)
            #expect(Set(locationIDs).count == locationIDs.count)
        }
    }

    @Test
    func locationStateUsesTheSelectedProductsCatalogPath() throws {
        let catalog = LocationCatalog()

        for tiers in catalog.tiersByProduct.values {
            let startingTier = try #require(tiers.first)
            let startingLocation = try #require(startingTier.locations.first)
            let state = LocationState(
                tiers: tiers,
                activeLocationID: startingLocation.id
            )

            #expect(state.tiers == tiers)
            #expect(state.locations == tiers.flatMap(\.locations))
            #expect(state.activeLocation == startingLocation)
            #expect(state.activeTier == startingTier)
        }
    }

    @Test
    func relocatingWithinCatalogUpdatesActiveLocationAndTier() throws {
        let tiers = try #require(
            LocationCatalog().tiersByProduct.values.first
        )
        let startingLocation = try #require(tiers.first?.locations.first)
        let destinationTier = try #require(
            tiers.first { $0.level == .tierTwo }
        )
        let destination = try #require(destinationTier.locations.first)
        let state = LocationState(
            tiers: tiers,
            activeLocationID: startingLocation.id
        )

        state.relocate(to: destination.id)

        #expect(state.activeLocation == destination)
        #expect(state.activeTier == destinationTier)
    }

    @Test
    func locationDemandUsesActiveTierMultiplier() throws {
        let tiers = try #require(
            LocationCatalog().tiersByProduct.values.first
        )
        let startingLocation = try #require(tiers.first?.locations.first)
        let destinationTier = try #require(
            tiers.first { $0.level == .tierTwo }
        )
        let destination = try #require(destinationTier.locations.first)
        let state = LocationState(
            tiers: tiers,
            activeLocationID: startingLocation.id
        )
        let dimension = LocationDimension(locationState: state)

        #expect(
            dimension.calculateDemand()
                == state.activeTier.demandMultiplier
        )

        let startingDemand = dimension.calculateDemand()
        state.relocate(to: destination.id)

        #expect(
            dimension.calculateDemand()
                == state.activeTier.demandMultiplier
        )
        #expect(dimension.calculateDemand() > startingDemand)
    }

    @Test
    func locationHasNeutralMarketSizeAndNoOperatingCosts() throws {
        let tiers = try #require(
            LocationCatalog().tiersByProduct.values.first
        )
        let startingLocation = try #require(tiers.first?.locations.first)
        let dimension = LocationDimension(
            locationState: LocationState(
                tiers: tiers,
                activeLocationID: startingLocation.id
            )
        )
        let summary = DaySummary(day: 1, startingBalance: 500)

        #expect(dimension.calculateMarketSize() == 1)
        #expect(
            dimension.calculateDailyCosts(
                sales: 100,
                summary: summary
            ) == 0
        )
        #expect(dimension.calculateWeeklyCosts(summary: summary) == 0)
        #expect(summary.economicCosts.isEmpty)
        #expect(summary.cashFlowCosts.isEmpty)
    }
}

// MARK: - Upgrade Location Requirements

extension LocationTests {

    @Test(arguments: locationTestProductIDs)
    func advertisementLocationRequirementsDoNotMoveBackward(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let tiers = AdvertisementCatalog(product: product)
            .tiersByProduct[productID]!
            .sorted { $0.level < $1.level }
        let requirements = tiers.map(\.requiredLocationTier)

        for (earlier, later) in zip(
            requirements,
            requirements.dropFirst()
        ) {
            #expect(later >= earlier)
        }
        #expect(requirements.first == .tierOne)
        #expect(requirements.contains { $0 > requirements[0] })
    }

    @Test(arguments: locationTestProductIDs)
    func primaryEquipmentLocationRequirementsDoNotMoveBackward(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let tiers = EquipmentCatalog().primaryTiers(for: product)
            .sorted { $0.level < $1.level }
        let requirements = tiers.map(\.requiredLocationTier)

        for (earlier, later) in zip(
            requirements,
            requirements.dropFirst()
        ) {
            #expect(later >= earlier)
        }
        #expect(requirements.first == .tierOne)
        #expect(requirements.contains { $0 > requirements[0] })
    }

    @Test(arguments: locationTestProductIDs)
    func primaryEquipmentResolvesContainingTiersLocationRequirement(
        productID: ProductID
    ) throws {
        let gameState = locationTestGameState(productID: productID)
        let equipmentState = try #require(gameState.equipmentState)

        for tier in equipmentState.primaryTiers {
            for equipment in tier.equipment {
                #expect(
                    equipmentState.requiredLocationTier(for: equipment)
                        == tier.requiredLocationTier
                )
            }
        }
    }

    @Test(arguments: locationTestProductIDs)
    func secondaryEquipmentIsLocationAgnostic(productID: ProductID) throws {
        let gameState = locationTestGameState(productID: productID)
        let equipmentState = try #require(gameState.equipmentState)

        for equipment in equipmentState.secondaryEquipmentCatalog.equipment {
            #expect(
                equipmentState.requiredLocationTier(for: equipment) == nil
            )
        }
    }

    @Test(arguments: locationTestProductIDs)
    func laborPurchaseRequestsAreLocationAgnostic(productID: ProductID) throws {
        let gameState = locationTestGameState(productID: productID)
        let laborState = try #require(gameState.laborState)
        let labor = try #require(laborState.availableLabor.labor.first)
        let request = PurchaseRequest(state: laborState, item: labor)

        #expect(request.requiredLocationTier == nil)
    }
}

// MARK: - Location-Locked Purchase Availability

extension LocationTests {

    @Test(arguments: locationTestProductIDs)
    func declaredRequirementControlsAdvertisementAvailability(
        productID: ProductID
    ) throws {
        let gameState = locationTestGameState(productID: productID)
        let workflow = locationTestPurchaseWorkflow(gameState: gameState)
        let advertisementState = try #require(gameState.advertisementState)
        let startingTier = gameState.locationState!.activeTier.level

        for tier in advertisementState.tiers {
            let expected: PurchaseAvailability =
                startingTier >= tier.requiredLocationTier
                    ? .available
                    : .locationLocked(
                        requiredTier: tier.requiredLocationTier
                    )

            #expect(
                workflow.locationAvailability(
                    requiredTier: tier.requiredLocationTier
                ) == expected
            )
        }
    }

    @Test(arguments: locationTestProductIDs)
    func declaredRequirementControlsPrimaryEquipmentAvailability(
        productID: ProductID
    ) throws {
        let gameState = locationTestGameState(productID: productID)
        let workflow = locationTestPurchaseWorkflow(gameState: gameState)
        let equipmentState = try #require(gameState.equipmentState)
        let startingTier = gameState.locationState!.activeTier.level

        for tier in equipmentState.primaryTiers {
            let expected: PurchaseAvailability =
                startingTier >= tier.requiredLocationTier
                    ? .available
                    : .locationLocked(
                        requiredTier: tier.requiredLocationTier
                    )

            #expect(
                workflow.locationAvailability(
                    requiredTier: tier.requiredLocationTier
                ) == expected
            )
        }
    }

    @Test(arguments: locationTestProductIDs)
    func reachingLaterLocationUnlocksDeclaredRequirements(
        productID: ProductID
    ) throws {
        let gameState = locationTestGameState(productID: productID)
        let destinationTier = try #require(
            gameState.locationState?.tiers.first {
                $0.level > gameState.locationState!.activeTier.level
            }
        )
        let destination = try #require(destinationTier.locations.first)
        gameState.locationState!.relocate(to: destination.id)
        let workflow = locationTestPurchaseWorkflow(gameState: gameState)

        for requirement in gameState.advertisementState!.tiers.map(
            \.requiredLocationTier
        ) {
            #expect(
                workflow.locationAvailability(requiredTier: requirement)
                    == .available
            )
        }
        for requirement in gameState.equipmentState!.primaryTiers.map(
            \.requiredLocationTier
        ) {
            #expect(
                workflow.locationAvailability(requiredTier: requirement)
                    == .available
            )
        }
    }

    @Test
    func locationLockTakesPriorityOverFinancialFailure() throws {
        let gameState = locationTestGameState(productID: .pies)
        let request = try lockedAdvertisementRequest(gameState: gameState)
        gameState.finance.displayedBalance = 0
        let workflow = locationTestPurchaseWorkflow(gameState: gameState)

        #expect(
            workflow.itemAvailability(for: request)
                == .locationLocked(
                    requiredTier: request.requiredLocationTier!
                )
        )
    }

    @Test
    func freeItemAtAvailableLocationIgnoresFinancialRestrictions() throws {
        let gameState = locationTestGameState(productID: .pies)
        let advertisementState = try #require(gameState.advertisementState)
        let startingTier = try #require(advertisementState.tiers.first)
        let freeAdvertisement = try #require(
            startingTier.advertisements.first { $0.price == 0 }
        )
        gameState.finance.displayedBalance = 0
        let request = PurchaseRequest(
            state: advertisementState,
            item: freeAdvertisement,
            requiredLocationTier: startingTier.requiredLocationTier
        )

        #expect(
            locationTestPurchaseWorkflow(gameState: gameState)
                .itemAvailability(for: request) == .available
        )
    }

    @Test
    func unlockedItemReturnsToOrdinaryFinancialValidation() throws {
        let gameState = locationTestGameState(productID: .pies)
        let request = try lockedAdvertisementRequest(gameState: gameState)
        let destinationTier = try #require(
            gameState.locationState?.tiers.first {
                $0.level == request.requiredLocationTier
            }
        )
        let destination = try #require(destinationTier.locations.first)
        gameState.locationState!.relocate(to: destination.id)
        gameState.finance.displayedBalance = 0
        let workflow = locationTestPurchaseWorkflow(gameState: gameState)

        #expect(
            workflow.itemAvailability(for: request) == .insufficientFunds
        )
    }

    @Test
    func unlockedItemStillEnforcesOperatingReserve() throws {
        let gameState = locationTestGameState(productID: .pies)
        let request = try lockedAdvertisementRequest(gameState: gameState)
        let destinationTier = try #require(
            gameState.locationState?.tiers.first {
                $0.level == request.requiredLocationTier
            }
        )
        let destination = try #require(destinationTier.locations.first)
        gameState.locationState!.relocate(to: destination.id)
        gameState.finance.displayedBalance =
            request.price + gameState.finance.minimumOperatingAllowance - 1
        let workflow = locationTestPurchaseWorkflow(gameState: gameState)

        #expect(
            workflow.itemAvailability(for: request)
                == .operatingReserveRequired
        )
    }

    @Test
    func completingLockedPurchaseRechecksAvailabilityWithoutMutation() throws {
        let gameState = locationTestGameState(productID: .pies)
        let request = try lockedAdvertisementRequest(gameState: gameState)
        let startingAdvertisement =
            gameState.advertisementState!.activeAdvertisement
        let startingActualBalance = gameState.finance.actualBalance
        let startingDisplayedBalance = gameState.finance.displayedBalance
        let startingUpgradeTracker = gameState.upgradeTracker
        let startingBusinessEventIDs = gameState.pendingBusinessEvents.map(\.id)
        let startingPendingUpgrades = gameState.pendingUpgrades
        let repository = LocationTestSaveRepository()
        let workflow = PurchaseWorkflow(
            gameState: gameState,
            saveRepository: repository
        )

        let result = workflow.complete(request)

        guard case let .unavailable(availability) = result else {
            Issue.record("Expected the location-locked purchase to fail.")
            return
        }
        #expect(
            availability == .locationLocked(
                requiredTier: request.requiredLocationTier!
            )
        )
        #expect(
            gameState.advertisementState!.activeAdvertisement
                == startingAdvertisement
        )
        #expect(gameState.finance.actualBalance == startingActualBalance)
        #expect(gameState.finance.displayedBalance == startingDisplayedBalance)
        #expect(
            gameState.upgradeTracker.lastUpgradeSimulationDay
                == startingUpgradeTracker.lastUpgradeSimulationDay
        )
        #expect(
            gameState.upgradeTracker.lastUpgradeWeekStartDate
                == startingUpgradeTracker.lastUpgradeWeekStartDate
        )
        #expect(
            gameState.pendingBusinessEvents.map(\.id)
                == startingBusinessEventIDs
        )
        #expect(gameState.pendingUpgrades == startingPendingUpgrades)
        #expect(repository.saveCallCount == 0)
    }
}

private let locationTestProductIDs: [ProductID] = [
    .pies,
    .hotDogs,
    .smoothies
]

private func locationTestGameState(productID: ProductID) -> GameState {
    let gameState = GameState()
    gameState.initializeBusiness(
        product: ProductCatalog().product(for: productID)
    )
    return gameState
}

private func locationTestPurchaseWorkflow(
    gameState: GameState
) -> PurchaseWorkflow {
    PurchaseWorkflow(
        gameState: gameState,
        saveRepository: LocationTestSaveRepository()
    )
}

private func lockedAdvertisementRequest(
    gameState: GameState
) throws -> PurchaseRequest {
    let advertisementState = try #require(gameState.advertisementState)
    let activeLocationTier = try #require(
        gameState.locationState?.activeTier.level
    )
    let lockedTier = try #require(
        advertisementState.tiers.first {
            $0.requiredLocationTier > activeLocationTier
        }
    )
    let advertisement = try #require(lockedTier.advertisements.first)

    return PurchaseRequest(
        state: advertisementState,
        item: advertisement,
        requiredLocationTier: lockedTier.requiredLocationTier
    )
}

private final class LocationTestSaveRepository: GameSaveRepository {
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

// MARK: - Global Upgrade Timing

extension LocationTests {

    @Test
    func newUpgradeTrackerAllowsUpgrade() {
        let tracker = UpgradeTracker()
        let weekStart = locationTestDate(
            year: 2026,
            month: 4,
            day: 6
        )

        #expect(tracker.canUpgrade(during: weekStart))
        #expect(!tracker.hasUpgrade(on: 1))
    }

    @Test
    func recordedUpgradeBlocksEntireCalendarWeek() {
        let calendar = GameCalendar(
            simulationDay: 1,
            currentDate: locationTestDate(
                year: 2026,
                month: 4,
                day: 6
            )
        )
        var tracker = UpgradeTracker()
        let recordedWeek = calendar.currentWeekStartDate
        tracker.recordUpgrade(
            on: calendar.simulationDay,
            weekStarting: recordedWeek
        )

        while calendar.currentWeekday != .friday {
            #expect(!tracker.canUpgrade(during: calendar.currentWeekStartDate))
            calendar.advanceDay()
        }

        #expect(!tracker.canUpgrade(during: calendar.currentWeekStartDate))
        calendar.advanceDay()
        #expect(calendar.currentWeekday == .monday)
        #expect(tracker.canUpgrade(during: calendar.currentWeekStartDate))
    }

    @Test
    func hasUpgradeMatchesOnlyRecordedSimulationDay() {
        var tracker = UpgradeTracker()
        tracker.recordUpgrade(
            on: 12,
            weekStarting: locationTestDate(
                year: 2026,
                month: 4,
                day: 6
            )
        )

        #expect(!tracker.hasUpgrade(on: 11))
        #expect(tracker.hasUpgrade(on: 12))
        #expect(!tracker.hasUpgrade(on: 13))
    }

    @Test
    func recordingLaterUpgradeReplacesPreviousTiming() {
        var tracker = UpgradeTracker()
        let firstWeek = locationTestDate(
            year: 2026,
            month: 4,
            day: 6
        )
        let laterWeek = locationTestDate(
            year: 2026,
            month: 4,
            day: 13
        )

        tracker.recordUpgrade(on: 4, weekStarting: firstWeek)
        tracker.recordUpgrade(on: 9, weekStarting: laterWeek)

        #expect(tracker.lastUpgradeSimulationDay == 9)
        #expect(tracker.lastUpgradeWeekStartDate == laterWeek)
        #expect(tracker.canUpgrade(during: firstWeek))
        #expect(!tracker.canUpgrade(during: laterWeek))
    }

    @Test
    func resettingTrackerClearsTimingAndReopensUpgradeWindow() {
        var tracker = UpgradeTracker()
        let weekStart = locationTestDate(
            year: 2026,
            month: 4,
            day: 6
        )
        tracker.recordUpgrade(on: 4, weekStarting: weekStart)

        tracker.reset()

        #expect(tracker.lastUpgradeSimulationDay == nil)
        #expect(tracker.lastUpgradeWeekStartDate == nil)
        #expect(tracker.canUpgrade(during: weekStart))
        #expect(!tracker.hasUpgrade(on: 4))
    }

    @Test
    func upgradeWindowUsesCalendarWeekRatherThanSimulationDayDistance() {
        var tracker = UpgradeTracker()
        let originalWeek = locationTestDate(
            year: 2026,
            month: 4,
            day: 6
        )
        let laterWeek = locationTestDate(
            year: 2026,
            month: 6,
            day: 1
        )
        tracker.recordUpgrade(on: 20, weekStarting: originalWeek)

        #expect(tracker.canUpgrade(during: laterWeek))
        #expect(tracker.hasUpgrade(on: 20))
    }
}

// MARK: - Relocation Upgrade Timing

extension LocationTests {

    @Test
    func sameDayUpgradeBlocksRelocation() {
        let gameState = locationTestGameState(productID: .pies)
        gameState.upgradeTracker.recordUpgrade(
            on: gameState.calendar.simulationDay,
            weekStarting: gameState.calendar.currentWeekStartDate
        )
        let workflow = RelocationWorkflow(
            gameState: gameState,
            saveRepository: LocationTestSaveRepository()
        )

        #expect(
            workflow.dimensionAvailability(
                for: RelocationDimensionAvailabilityRequest()
            ) == .upgradeMadeToday
        )
    }

    @Test
    func earlierUpgradeInSameWeekDoesNotBlockRelocation() {
        let gameState = locationTestGameState(productID: .pies)
        gameState.upgradeTracker.recordUpgrade(
            on: gameState.calendar.simulationDay,
            weekStarting: gameState.calendar.currentWeekStartDate
        )
        gameState.calendar.advanceDay()
        let workflow = RelocationWorkflow(
            gameState: gameState,
            saveRepository: LocationTestSaveRepository()
        )

        #expect(
            workflow.dimensionAvailability(
                for: RelocationDimensionAvailabilityRequest()
            ) == .available
        )
    }

    @Test
    func pendingBusinessEventsBlockRelocationIndependently() {
        let gameState = locationTestGameState(productID: .pies)
        gameState.pendingBusinessEvents = [locationTestBusinessEvent()]
        let workflow = RelocationWorkflow(
            gameState: gameState,
            saveRepository: LocationTestSaveRepository()
        )

        #expect(
            workflow.dimensionAvailability(
                for: RelocationDimensionAvailabilityRequest()
            ) == .pendingBusinessEvents
        )
    }

    @Test
    func untouchedTrackerAndNoPendingEventsAllowRelocationChecks() {
        let gameState = locationTestGameState(productID: .pies)
        let workflow = RelocationWorkflow(
            gameState: gameState,
            saveRepository: LocationTestSaveRepository()
        )

        #expect(
            workflow.dimensionAvailability(
                for: RelocationDimensionAvailabilityRequest()
            ) == .available
        )
    }
}

private func locationTestDate(
    year: Int,
    month: Int,
    day: Int
) -> Date {
    Foundation.Calendar(identifier: .gregorian).date(
        from: DateComponents(
            year: year,
            month: month,
            day: day
        )
    )!
}

private func locationTestBusinessEvent() -> BusinessEvent {
    BusinessEvent(
        simulationDay: 1,
        calendarDate: locationTestDate(
            year: 2026,
            month: 4,
            day: 1
        ),
        type: .purchase(
            PurchaseEvent(
                category: .advertisement,
                itemID: "location-test-purchase"
            )
        ),
        title: "Location Test Purchase"
    )
}

// MARK: - Relocation Availability

extension LocationTests {

    @Test
    func relocationAvailabilityReportsEveryRequirementStatus() throws {
        let gameState = locationTestGameState(productID: .pies)
        let request = try locationTestRelocationRequest(gameState: gameState)
        let availability = RelocationWorkflow(
            gameState: gameState,
            saveRepository: LocationTestSaveRepository()
        ).itemAvailability(for: request)

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
    func newBusinessDoesNotMeetRelocationRequirements() throws {
        let gameState = locationTestGameState(productID: .pies)
        let request = try locationTestRelocationRequest(gameState: gameState)
        gameState.finance.displayedBalance =
            request.relocationPrice
                + gameState.finance.minimumOperatingAllowance
        let availability = RelocationWorkflow(
            gameState: gameState,
            saveRepository: LocationTestSaveRepository()
        ).itemAvailability(for: request)

        #expect(!availability.canRelocate)
        #expect(!availability.unmetRequirements.isEmpty)
        #expect(availability.financialAvailability == .available)
    }

    @Test
    func satisfyingImplementedRequirementsMakesRequirementsAvailable() throws {
        let gameState = locationTestGameState(productID: .pies)
        let request = try locationTestRelocationRequest(gameState: gameState)
        try satisfyRelocationRequirements(
            request.requirements,
            gameState: gameState
        )
        gameState.finance.displayedBalance =
            request.relocationPrice
                + gameState.finance.minimumOperatingAllowance
        let availability = RelocationWorkflow(
            gameState: gameState,
            saveRepository: LocationTestSaveRepository()
        ).itemAvailability(for: request)

        #expect(availability.requirements.allSatisfy(\.isMet))
        #expect(availability.financialAvailability == .available)
        #expect(availability.canRelocate)
    }

    @Test(arguments: implementedRelocationRequirements)
    func eachImplementedRequirementCanIndependentlyBlockRelocation(
        requirement: RelocationRequirement
    ) throws {
        let gameState = locationTestGameState(productID: .pies)
        let request = try locationTestRelocationRequest(
            gameState: gameState,
            onlyRequiring: requirement
        )
        gameState.finance.displayedBalance =
            request.relocationPrice
                + gameState.finance.minimumOperatingAllowance
        let availability = RelocationWorkflow(
            gameState: gameState,
            saveRepository: LocationTestSaveRepository()
        ).itemAvailability(for: request)

        #expect(
            availability.unmetRequirements.map(\.requirement)
                == [requirement]
        )
        #expect(!availability.canRelocate)
    }

    @Test
    func unmetRequirementsRemainPrimaryEvenWhenFinancesFail() throws {
        let gameState = locationTestGameState(productID: .pies)
        let request = try locationTestRelocationRequest(gameState: gameState)
        gameState.finance.displayedBalance = 0
        let availability = RelocationWorkflow(
            gameState: gameState,
            saveRepository: LocationTestSaveRepository()
        ).itemAvailability(for: request)

        #expect(!availability.unmetRequirements.isEmpty)
        #expect(availability.financialAvailability == .insufficientFunds)
        #expect(!availability.canRelocate)
    }

    @Test
    func metRequirementsStillEnforceInsufficientFunds() throws {
        let gameState = locationTestGameState(productID: .pies)
        let request = try locationTestRelocationRequest(gameState: gameState)
        try satisfyRelocationRequirements(
            request.requirements,
            gameState: gameState
        )
        gameState.finance.displayedBalance = request.relocationPrice - 1
        let availability = RelocationWorkflow(
            gameState: gameState,
            saveRepository: LocationTestSaveRepository()
        ).itemAvailability(for: request)

        #expect(availability.requirements.allSatisfy(\.isMet))
        #expect(availability.financialAvailability == .insufficientFunds)
        #expect(!availability.canRelocate)
    }

    @Test
    func metRequirementsStillEnforceOperatingReserve() throws {
        let gameState = locationTestGameState(productID: .pies)
        let request = try locationTestRelocationRequest(gameState: gameState)
        try satisfyRelocationRequirements(
            request.requirements,
            gameState: gameState
        )
        gameState.finance.displayedBalance =
            request.relocationPrice
                + gameState.finance.minimumOperatingAllowance - 1
        let availability = RelocationWorkflow(
            gameState: gameState,
            saveRepository: LocationTestSaveRepository()
        ).itemAvailability(for: request)

        #expect(availability.requirements.allSatisfy(\.isMet))
        #expect(
            availability.financialAvailability
                == .operatingReserveRequired
        )
        #expect(!availability.canRelocate)
    }

    @Test
    func unavailableRelocationDoesNotMutateOrSaveState() throws {
        let gameState = locationTestGameState(productID: .pies)
        let request = try locationTestRelocationRequest(gameState: gameState)
        let repository = LocationTestSaveRepository()
        let workflow = RelocationWorkflow(
            gameState: gameState,
            saveRepository: repository
        )
        let startingLocation = gameState.locationState!.activeLocationID
        let startingCalendar = gameState.calendar.captureRollbackState()
        let startingActualBalance = gameState.finance.actualBalance
        let startingDisplayedBalance = gameState.finance.displayedBalance
        let startingSummaryCount =
            gameState.simulationSummary.daySummaries.count

        let result = workflow.complete(request)

        guard case .unavailable = result else {
            Issue.record("Expected relocation to remain unavailable.")
            return
        }
        #expect(gameState.locationState!.activeLocationID == startingLocation)
        #expect(
            gameState.calendar.simulationDay
                == startingCalendar.simulationDay
        )
        #expect(
            gameState.calendar.operatingPeriodDay
                == startingCalendar.operatingPeriodDay
        )
        #expect(gameState.calendar.currentDate == startingCalendar.currentDate)
        #expect(gameState.finance.actualBalance == startingActualBalance)
        #expect(gameState.finance.displayedBalance == startingDisplayedBalance)
        #expect(
            gameState.simulationSummary.daySummaries.count
                == startingSummaryCount
        )
        #expect(repository.saveCallCount == 0)
    }
}

private let implementedRelocationRequirements: [RelocationRequirement] = [
    .equipmentLevel,
    .laborLevel,
    .advertisementLevel,
    .businessReputation
]

private func locationTestRelocationRequest(
    gameState: GameState,
    onlyRequiring requirement: RelocationRequirement? = nil
) throws -> RelocationRequest {
    let destinationTier = try #require(
        gameState.locationState?.tiers.first {
            $0.level > gameState.locationState!.activeTier.level
        }
    )
    let destination = try #require(destinationTier.locations.first)

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
        relocationPrice: 15_000
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
