import Testing
@testable import BusinessSimulator

@MainActor
struct ProductionCapacityTests {}

// MARK: - Primary Capacity Progression

extension ProductionCapacityTests {

    @Test
    func baseCapacityIsNinetyPercentRoundedUp() {
        #expect(
            ProductionCapacityBalance.baseCapacity(
                baseIdealUnitsSold: 100
            ) == 90
        )
        #expect(
            ProductionCapacityBalance.baseCapacity(
                baseIdealUnitsSold: 38
            ) == 35
        )
    }

    @Test
    func tierZeroHasNoCapacityIncrease() {
        #expect(
            ProductionCapacityBalance.expectedCapacityIncrease(
                baseIdealUnitsSold: 100,
                tierLevel: 0
            ) == 0
        )
    }

    @Test
    func expectedCapacityIncreasesAcrossTiers() {
        let increases = (0...ProductionCapacityBalance.totalTiers).map {
            ProductionCapacityBalance.expectedCapacityIncrease(
                baseIdealUnitsSold: 100,
                tierLevel: $0
            )
        }

        for (previousIncrease, nextIncrease) in zip(
            increases,
            increases.dropFirst()
        ) {
            #expect(nextIncrease > previousIncrease)
        }
    }

    @Test
    func finalTierReachesTwoHundredPercentCapacity() {
        let idealUnitsSold = 101
        let baseCapacity = ProductionCapacityBalance.baseCapacity(
            baseIdealUnitsSold: idealUnitsSold
        )
        let finalIncrease = ProductionCapacityBalance
            .expectedCapacityIncrease(
                baseIdealUnitsSold: idealUnitsSold,
                tierLevel: ProductionCapacityBalance.totalTiers
            )
        let expectedTarget = Int(
            (Double(idealUnitsSold) * ProductionCapacityBalance.targetRatio)
                .rounded()
        )

        #expect(baseCapacity + finalIncrease == expectedTarget)
    }
}

// MARK: - Equipment Capacity Limits

extension ProductionCapacityTests {

    @Test
    func equipmentCapacityLimitsSalesAndAddsProductionNote() throws {
        let context = try makeCapacityLimitContext()
        let capacity = context.state.totalCapacity
        let summary = DaySummary(day: 1, startingBalance: 500)

        let limitedSales = context.dimension.applySalesLimits(
            sales: capacity + 10,
            summary: summary
        )

        #expect(limitedSales == capacity)
        #expect(
            summary.sections.contains { section in
                section.name == "Production"
                    && section.notes.contains(
                        "Sales were limited by equipment capacity."
                    )
            }
        )
    }

    @Test
    func equipmentCapacityDoesNotChangeSalesAtOrBelowLimit() throws {
        let context = try makeCapacityLimitContext()
        let capacity = context.state.totalCapacity

        for sales in [capacity - 1, capacity] {
            let summary = DaySummary(day: 1, startingBalance: 500)

            let limitedSales = context.dimension.applySalesLimits(
                sales: sales,
                summary: summary
            )

            #expect(limitedSales == sales)
            #expect(
                !summary.sections.contains { $0.name == "Production" }
            )
        }
    }
}

private struct CapacityLimitContext {
    let state: EquipmentState
    let dimension: EquipmentDimension
}

@MainActor
private func makeCapacityLimitContext() throws -> CapacityLimitContext {
    let product = try #require(
        ProductCatalog().products.first { $0.id == .pies }
    )
    let catalog = EquipmentCatalog()
    let primaryTiers = catalog.primaryTiers(for: product)
    let secondaryCatalog = catalog.secondaryEquipment(for: product)
    let state = EquipmentState(
        primaryTiers: primaryTiers,
        secondaryEquipmentCatalog: secondaryCatalog
    )

    return CapacityLimitContext(
        state: state,
        dimension: EquipmentDimension(equipmentState: state)
    )
}

// MARK: - Labor Capacity Limits

extension ProductionCapacityTests {

    @Test
    func laborCapacityLimitsSalesAndAddsProductionNote() {
        let context = makeLaborCapacityLimitContext()
        let capacity = context.state.totalCapacity
        let summary = DaySummary(day: 1, startingBalance: 500)

        let limitedSales = context.dimension.applySalesLimits(
            sales: capacity + 10,
            summary: summary
        )

        #expect(limitedSales == capacity)
        #expect(
            summary.sections.contains { section in
                section.name == "Production"
                    && section.notes.contains(
                        "Sales were limited by labor capacity."
                    )
            }
        )
    }

    @Test
    func laborCapacityDoesNotChangeSalesAtOrBelowLimit() {
        let context = makeLaborCapacityLimitContext()
        let capacity = context.state.totalCapacity

        for sales in [capacity - 1, capacity] {
            let summary = DaySummary(day: 1, startingBalance: 500)

            let limitedSales = context.dimension.applySalesLimits(
                sales: sales,
                summary: summary
            )

            #expect(limitedSales == sales)
            #expect(
                !summary.sections.contains { $0.name == "Production" }
            )
        }
    }
}

private struct LaborCapacityLimitContext {
    let state: LaborState
    let dimension: LaborDimension
}

@MainActor
private func makeLaborCapacityLimitContext() -> LaborCapacityLimitContext {
    let product = ProductCatalog().product(for: .pies)
    let catalogLabor = LaborCatalog().labor(for: product)
    let state = LaborState(
        laborCatalog: LaborCollection(labor: catalogLabor),
        baseIdealUnitsSold: product.idealUnitsSold
    )

    return LaborCapacityLimitContext(
        state: state,
        dimension: LaborDimension(laborState: state)
    )
}

// MARK: - Secondary Capacity Strength

extension ProductionCapacityTests {

    @Test
    func secondaryStrengthUsesExpectedPercentOfIdealSales() {
        #expect(SecondaryCapacityStrength.low.capacity(for: 100) == 3)
        #expect(SecondaryCapacityStrength.medium.capacity(for: 100) == 5)
        #expect(SecondaryCapacityStrength.high.capacity(for: 100) == 7)
    }

    @Test
    func secondaryStrengthsRemainDistinctAfterRounding() {
        let low = SecondaryCapacityStrength.low.capacity(for: 10)
        let medium = SecondaryCapacityStrength.medium.capacity(for: 10)
        let high = SecondaryCapacityStrength.high.capacity(for: 10)

        #expect(low < medium)
        #expect(medium < high)
    }
}

// MARK: - Total Equipment Capacity

extension ProductionCapacityTests {

    @Test
    func totalCapacityCombinesPrimaryAndOwnedSecondaryEquipment() throws {
        let product = try #require(
            ProductCatalog().products.first { $0.id == .pies }
        )
        let equipmentCatalog = EquipmentCatalog()
        let primaryTiers = equipmentCatalog.primaryTiers(for: product)
        let activeTier = primaryTiers[2]
        let activeEquipment = try #require(activeTier.equipment.first)
        let secondaryCatalog = equipmentCatalog.secondaryEquipment(
            for: product
        )
        let ownedEquipment = Array(
            secondaryCatalog.equipment.prefix(2)
        )
        let equipmentState = EquipmentState(
            primaryTiers: primaryTiers,
            secondaryEquipmentCatalog: secondaryCatalog,
            activePrimaryEquipment: ActivePrimaryEquipment(
                equipment: activeEquipment,
                tierLevel: activeTier.level
            ),
            ownedSecondaryEquipment: SecondaryEquipmentCollection(
                equipment: ownedEquipment
            )
        )

        #expect(
            equipmentState.totalCapacity
                == activeEquipment.capacity
                    + ownedEquipment.reduce(0) { $0 + $1.capacity }
        )
    }
}
