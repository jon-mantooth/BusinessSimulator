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
