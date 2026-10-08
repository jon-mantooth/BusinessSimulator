import Testing
@testable import BusinessSimulator

@MainActor
struct StorageTests {}

// MARK: - Catalog and Capacity

extension StorageTests {

    @Test(arguments: storageProductIDs)
    func catalogHasOneOptionForEveryTier(productID: ProductID) {
        let product = ProductCatalog().product(for: productID)
        let tiers = StorageCatalog().tiers(for: product)

        #expect(tiers.map(\.level) == Array(0...5))
        #expect(Set(tiers.map { $0.storage.id }).count == 6)
        #expect(tiers[0].storage.price == 0)
        #expect(tiers[0].storage.capacity == 0)
    }

    @Test(arguments: storageProductIDs)
    func catalogUsesStorageCapacitySchedule(productID: ProductID) throws {
        let product = ProductCatalog().product(for: productID)
        let catalog = StorageCatalog()
        let tiers = catalog.tiers(for: product)

        for tier in tiers {
            let upgradeTier = try #require(
                UpgradeTierLevel(rawValue: tier.level)
            )
            #expect(
                tier.storage.capacity
                    == catalog.capacitySchedule.capacity(
                        for: .tier(upgradeTier),
                        product: product
                    )
            )
            #expect(tier.storage.capacityType == .total)
            #expect(!tier.storage.capacityDisplayText.hasPrefix("+"))
        }
    }

    @Test(arguments: storageProductIDs)
    func capacityStrictlyIncreasesAfterTierZero(productID: ProductID) {
        let product = ProductCatalog().product(for: productID)
        let capacities = StorageCatalog().tiers(for: product).map {
            $0.storage.capacity
        }

        for (earlier, later) in zip(capacities, capacities.dropFirst()) {
            #expect(later > earlier)
        }
    }
}

// MARK: - State

extension StorageTests {

    @Test
    func stateStartsAtZeroAndUpgradesSequentially() throws {
        let product = ProductCatalog().product(for: .pies)
        let state = StorageState(tiers: StorageCatalog().tiers(for: product))

        #expect(state.activeStorage.tierLevel == 0)
        #expect(state.totalCapacity == 0)

        let firstTier = try #require(state.nextTier)
        state.applyUpgrade(firstTier.storage)

        #expect(state.activeStorage.tierLevel == 1)
        #expect(state.totalCapacity == firstTier.storage.capacity)
        #expect(state.nextTier?.level == 2)
    }

    @Test
    func rollbackRestoresPreviousTier() throws {
        let product = ProductCatalog().product(for: .pies)
        let state = StorageState(tiers: StorageCatalog().tiers(for: product))
        let snapshot = state.captureRollbackState()
        let firstTier = try #require(state.nextTier)

        state.applyUpgrade(firstTier.storage)
        state.revertUpgrade(to: snapshot)

        #expect(state.activeStorage == snapshot.activeStorage)
        #expect(state.activeStorage.tierLevel == 0)
    }

    @Test
    func noUpgradeRemainsAfterTierFive() throws {
        let product = ProductCatalog().product(for: .pies)
        let state = StorageState(tiers: StorageCatalog().tiers(for: product))

        while let nextTier = state.nextTier {
            state.applyUpgrade(nextTier.storage)
        }

        #expect(state.activeStorage.tierLevel == 5)
        #expect(state.nextTier == nil)
    }
}

// MARK: - Dimension

extension StorageTests {

    @Test
    func doesNotLimitSalesAtLocationLevelOne() {
        let product = ProductCatalog().product(for: .pies)
        let locationState = makeLocationState(product: product)
        let storageState = StorageState(
            tiers: StorageCatalog().tiers(for: product)
        )
        let summary = DaySummary(day: 1, startingBalance: 0)

        let sales = StorageDimension(
            storageState: storageState,
            locationState: locationState
        ).applySalesLimits(sales: 500, summary: summary)

        #expect(sales == 500)
        #expect(summary.sections.isEmpty)
    }

    @Test
    func limitsSalesAtLocationLevelTwo() throws {
        let product = ProductCatalog().product(for: .pies)
        let locationState = makeLocationState(product: product)
        let storageState = StorageState(
            tiers: StorageCatalog().tiers(for: product)
        )
        let firstTier = try #require(storageState.nextTier)
        storageState.applyUpgrade(firstTier.storage)
        relocateToLevelTwo(locationState)
        let summary = DaySummary(day: 1, startingBalance: 0)

        let sales = StorageDimension(
            storageState: storageState,
            locationState: locationState
        ).applySalesLimits(
            sales: storageState.totalCapacity + 10,
            summary: summary
        )

        #expect(sales == storageState.totalCapacity)
        #expect(
            summary.sections.contains { section in
                section.name == "Distribution"
                    && section.notes.contains(
                        "Sales were limited by storage capacity."
                    )
            }
        )
    }

    @Test
    func doesNotChangeSalesAtOrBelowCapacity() throws {
        let product = ProductCatalog().product(for: .pies)
        let locationState = makeLocationState(product: product)
        let storageState = StorageState(
            tiers: StorageCatalog().tiers(for: product)
        )
        let firstTier = try #require(storageState.nextTier)
        storageState.applyUpgrade(firstTier.storage)
        relocateToLevelTwo(locationState)
        let dimension = StorageDimension(
            storageState: storageState,
            locationState: locationState
        )

        for sales in [storageState.totalCapacity - 1, storageState.totalCapacity] {
            let summary = DaySummary(day: 1, startingBalance: 0)
            #expect(
                dimension.applySalesLimits(sales: sales, summary: summary)
                    == sales
            )
            #expect(summary.sections.isEmpty)
        }
    }

    @Test
    func hasNoDemandMarketSizeOrOperatingCosts() {
        let product = ProductCatalog().product(for: .pies)
        let dimension = StorageDimension(
            storageState: StorageState(
                tiers: StorageCatalog().tiers(for: product)
            ),
            locationState: makeLocationState(product: product)
        )
        let summary = DaySummary(day: 1, startingBalance: 0)

        #expect(dimension.calculateDemand() == 1)
        #expect(dimension.calculateMarketSize() == 1)
        #expect(dimension.calculateDailyCosts(sales: 100, summary: summary) == 0)
        #expect(dimension.calculateWeeklyCosts(summary: summary) == 0)
    }
}

private let storageProductIDs: [ProductID] = [
    .pies,
    .hotDogs,
    .smoothies
]

private func makeLocationState(product: Product) -> LocationState {
    let tiers = LocationCatalog().tiersByProduct[product.id]!
    return LocationState(
        tiers: tiers,
        activeLocationID: tiers[0].locations[0].id
    )
}

private func relocateToLevelTwo(_ locationState: LocationState) {
    let destination = locationState.tiers.first {
        $0.level == .tierTwo
    }!.locations[0]
    locationState.relocate(to: destination.id)
}
