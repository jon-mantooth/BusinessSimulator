import Testing
@testable import BusinessSimulator

struct CostsTests {}

// MARK: - Advertisements

extension CostsTests {

    @Test
    func dailyAdvertisementCreatesDailyCost() throws {
        let advertisementDimension = makeAdvertisementDimensionForCosts(
            paymentSchedule: .daily,
            price: 40
        )
        let summary = DaySummary(day: 1, startingBalance: 500)

        let cost = advertisementDimension.calculateDailyCosts(
            sales: 100,
            summary: summary
        )

        #expect(cost == 40)
        let cashFlowCost = try #require(summary.cashFlowCosts.first)
        #expect(summary.cashFlowCosts.count == 1)
        #expect(cashFlowCost.name == "Cost Test Advertisement")
        #expect(cashFlowCost.amount == 40)
    }

    @Test
    func weeklyAdvertisementCreatesWeeklyCost() throws {
        let advertisementDimension = makeAdvertisementDimensionForCosts(
            paymentSchedule: .weekly,
            price: 125
        )
        let summary = DaySummary(day: 5, startingBalance: 500)

        let cost = advertisementDimension.calculateWeeklyCosts(
            summary: summary
        )

        #expect(cost == 125)
        let cashFlowCost = try #require(summary.cashFlowCosts.first)
        #expect(summary.cashFlowCosts.count == 1)
        #expect(cashFlowCost.name == "Cost Test Advertisement")
        #expect(cashFlowCost.amount == 125)
    }

    @Test
    func weeklyAdvertisementDoesNotCreateDailyCost() {
        let advertisementDimension = makeAdvertisementDimensionForCosts(
            paymentSchedule: .weekly,
            price: 125
        )
        let summary = DaySummary(day: 1, startingBalance: 500)

        let cost = advertisementDimension.calculateDailyCosts(
            sales: 100,
            summary: summary
        )

        #expect(cost == 0)
        #expect(summary.cashFlowCosts.isEmpty)
    }

    @Test
    func dailyAdvertisementDoesNotCreateWeeklyCost() {
        let advertisementDimension = makeAdvertisementDimensionForCosts(
            paymentSchedule: .daily,
            price: 40
        )
        let summary = DaySummary(day: 5, startingBalance: 500)

        let cost = advertisementDimension.calculateWeeklyCosts(
            summary: summary
        )

        #expect(cost == 0)
        #expect(summary.cashFlowCosts.isEmpty)
    }

    @Test
    func oneTimeAdvertisementIsNotChargedAgain() {
        let advertisementDimension = makeAdvertisementDimensionForCosts(
            paymentSchedule: .oneTime,
            price: 200
        )
        let summary = DaySummary(day: 5, startingBalance: 500)

        let dailyCost = advertisementDimension.calculateDailyCosts(
            sales: 100,
            summary: summary
        )
        let weeklyCost = advertisementDimension.calculateWeeklyCosts(
            summary: summary
        )

        #expect(dailyCost == 0)
        #expect(weeklyCost == 0)
        #expect(summary.cashFlowCosts.isEmpty)
    }

    @Test
    func freeCanvassingDoesNotCreateScheduledCost() {
        let catalog = AdvertisementCatalog(productID: .pies)
        let advertisementDimension = makeAdvertisementDimensionForCosts(
            advertisement: catalog.canvassing
        )
        let summary = DaySummary(day: 5, startingBalance: 500)

        let dailyCost = advertisementDimension.calculateDailyCosts(
            sales: 100,
            summary: summary
        )
        let weeklyCost = advertisementDimension.calculateWeeklyCosts(
            summary: summary
        )

        #expect(catalog.canvassing.price == 0)
        #expect(dailyCost == 0)
        #expect(weeklyCost == 0)
        #expect(summary.cashFlowCosts.isEmpty)
    }
}

// MARK: - Transport

extension CostsTests {

    @MainActor
    @Test
    func activeTransportTracksCreateNamedWeeklyCosts() throws {
        let context = try makeTransportDimensionForCosts(
            primaryLevel: 1,
            secondaryLevel: 1
        )
        let summary = DaySummary(day: 5, startingBalance: 10_000)
        let activeItems = context.state.activeTransport.items
        let expectedCost = activeItems.reduce(0.0) {
            $0 + $1.transport.price
        }

        let cost = context.dimension.calculateWeeklyCosts(summary: summary)

        #expect(cost == expectedCost)
        #expect(summary.cashFlowCosts.count == 2)
        #expect(
            Set(summary.cashFlowCosts.map(\.name))
                == Set(activeItems.map { $0.transport.name })
        )
        #expect(
            summary.cashFlowCosts.allSatisfy {
                $0.category == .transport && $0.displaySuffix == nil
            }
        )
    }

    @MainActor
    @Test
    func replacingTrackChargesOnlyItsActiveTransport() throws {
        let context = try makeTransportDimensionForCosts(primaryLevel: 2)
        let summary = DaySummary(day: 5, startingBalance: 10_000)
        let activePrimary = try #require(
            context.state.activeTransport.primary?.transport
        )

        let cost = context.dimension.calculateWeeklyCosts(summary: summary)

        #expect(cost == activePrimary.price)
        #expect(summary.cashFlowCosts.map(\.name) == [activePrimary.name])
    }

    @MainActor
    @Test
    func proratedTransportCostsApplyMultiplierAndSuffix() throws {
        let context = try makeTransportDimensionForCosts(
            primaryLevel: 1,
            secondaryLevel: 1
        )
        let summary = DaySummary(day: 3, startingBalance: 10_000)
        let multiplier = 0.4
        let fullWeeklyCost = context.state.activeTransport.items.reduce(0.0) {
            $0 + $1.transport.price
        }

        let cost = context.dimension.calculateWeeklyCosts(
            summary: summary,
            multiplier: multiplier
        )

        #expect(abs(cost - fullWeeklyCost * multiplier) < 0.000_001)
        #expect(
            summary.cashFlowCosts.allSatisfy {
                $0.category == .transport
                    && $0.displaySuffix == "Prorated"
            }
        )
    }

    @MainActor
    @Test
    func noActiveTransportCreatesNoScheduledCost() throws {
        let context = try makeTransportDimensionForCosts()
        let summary = DaySummary(day: 5, startingBalance: 10_000)

        let cost = context.dimension.calculateWeeklyCosts(summary: summary)

        #expect(cost == 0)
        #expect(summary.cashFlowCosts.isEmpty)
    }
}

// MARK: - Labor

extension CostsTests {

    @MainActor
    @Test
    func dailyLaborCostIsRecordedInCashFlowCosts() throws {
        let context = makeLaborDimensionForCosts(ownedWorkerCount: 2)
        let summary = DaySummary(day: 1, startingBalance: 500)
        let expectedCost = try #require(
            context.state.totalCosts[.daily]
        )

        let cost = context.dimension.calculateDailyCosts(
            sales: 100,
            summary: summary
        )

        #expect(cost == expectedCost)
        #expect(summary.cashFlowCosts.count == 2)
        #expect(
            summary.cashFlowCosts.map(\.name)
                == Array(context.state.ownedLabor.labor.prefix(2)).map(\.name)
        )
        #expect(
            summary.cashFlowCosts.allSatisfy {
                $0.category == .labor
            }
        )
        #expect(
            summary.cashFlowCosts.reduce(0.0) { $0 + $1.amount }
                == expectedCost
        )
    }

    @MainActor
    @Test
    func noHiredLaborDoesNotCreateCashFlowCost() {
        let context = makeLaborDimensionForCosts()
        let summary = DaySummary(day: 1, startingBalance: 500)

        let cost = context.dimension.calculateDailyCosts(
            sales: 100,
            summary: summary
        )

        #expect(cost == 0)
        #expect(summary.cashFlowCosts.isEmpty)
    }

    @MainActor
    @Test
    func dailyLaborDoesNotCreateWeeklyCost() {
        let context = makeLaborDimensionForCosts(ownedWorkerCount: 4)
        let summary = DaySummary(day: 5, startingBalance: 500)

        let cost = context.dimension.calculateWeeklyCosts(
            summary: summary
        )

        #expect(cost == 0)
        #expect(summary.cashFlowCosts.isEmpty)
    }
}

// MARK: - Equipment

extension CostsTests {

    @MainActor
    @Test
    func oneTimeEquipmentDoesNotCreateDailyOrWeeklyCosts() throws {
        let product = try #require(
            ProductCatalog().products.first { $0.id == .pies }
        )
        let catalog = EquipmentCatalog()
        let primaryTiers = catalog.primaryTiers(for: product)
        let secondaryCatalog = catalog.secondaryEquipment(for: product)
        let ownedSecondary = SecondaryEquipmentCollection(
            equipment: Array(secondaryCatalog.equipment.prefix(2))
        )
        let equipmentState = EquipmentState(
            primaryTiers: primaryTiers,
            secondaryEquipmentCatalog: secondaryCatalog,
            ownedSecondaryEquipment: ownedSecondary
        )
        let dimension = EquipmentDimension(equipmentState: equipmentState)
        let summary = DaySummary(day: 1, startingBalance: 500)

        let dailyCost = dimension.calculateDailyCosts(
            sales: 100,
            summary: summary
        )
        let weeklyCost = dimension.calculateWeeklyCosts(summary: summary)

        #expect(dailyCost == 0)
        #expect(weeklyCost == 0)
        #expect(summary.cashFlowCosts.isEmpty)
    }
}

private func makeAdvertisementDimensionForCosts(
    paymentSchedule: PaymentSchedule,
    price: Double
) -> AdvertisementDimension {
    makeAdvertisementDimensionForCosts(
        advertisement: Advertisement(
            id: AdvertisementID(rawValue: "cost-test-advertisement"),
            name: "Cost Test Advertisement",
            smallIcon: .system("megaphone.fill"),
            description: "Tests advertisement costs.",
            price: price,
            paymentSchedule: paymentSchedule,
            demandLevel: 0,
            marketSizeLevel: 0
        )
    )
}

private struct LaborCostContext {
    let state: LaborState
    let dimension: LaborDimension
}

private struct TransportCostContext {
    let state: TransportState
    let dimension: TransportDimension
}

@MainActor
private func makeTransportDimensionForCosts(
    primaryLevel: Int = 0,
    secondaryLevel: Int = 0
) throws -> TransportCostContext {
    let gameState = GameState()
    gameState.initializeBusiness(
        product: ProductCatalog().product(for: .pies)
    )
    let state = try #require(gameState.transportState)
    let locationState = try #require(gameState.locationState)

    if primaryLevel > 0 {
        for level in 1...primaryLevel {
            let tier = try #require(
                state.nextTiers.first {
                    $0.track == .primary && $0.level == level
                }
            )
            state.applyUpgrade(tier.transport)
        }
    }
    if secondaryLevel > 0 {
        for level in 1...secondaryLevel {
            let tier = try #require(
                state.nextTiers.first {
                    $0.track == .secondary && $0.level == level
                }
            )
            state.applyUpgrade(tier.transport)
        }
    }

    return TransportCostContext(
        state: state,
        dimension: TransportDimension(
            transportState: state,
            locationState: locationState
        )
    )
}

@MainActor
private func makeLaborDimensionForCosts(
    ownedWorkerCount: Int = 0
) -> LaborCostContext {
    let product = ProductCatalog().product(for: .pies)
    let labor = LaborCatalog().labor(for: product)
    let state = LaborState(
        laborCatalog: LaborCollection(labor: labor),
        baseIdealUnitsSold: product.idealUnitsSold
    )

    for worker in labor.prefix(ownedWorkerCount) {
        state.applyUpgrade(worker)
    }

    return LaborCostContext(
        state: state,
        dimension: LaborDimension(laborState: state)
    )
}

private func makeAdvertisementDimensionForCosts(
    advertisement: Advertisement
) -> AdvertisementDimension {
    let tier = AdvertisementTier(
        id: AdvertisementTierID(rawValue: "cost-test-tier"),
        level: 0,
        advertisements: [advertisement],
        product: ProductCatalog().product(for: .pies),
        requiredLocationTier: .tierOne
    )
    let advertisementState = AdvertisementState(
        tiers: [tier],
        activeAdvertisement: ActiveAdvertisement(
            advertisement: advertisement,
            tierLevel: tier.level
        )
    )

    return AdvertisementDimension(
        advertisementState: advertisementState,
        businessHours: BusinessHours(
            openingTime: BusinessTime(hour: 9, minute: 0),
            closingTime: BusinessTime(hour: 17, minute: 0)
        )
    )
}
