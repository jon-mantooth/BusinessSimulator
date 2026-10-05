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
