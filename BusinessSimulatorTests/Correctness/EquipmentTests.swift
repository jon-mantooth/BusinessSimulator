import Testing
@testable import BusinessSimulator

@MainActor
struct EquipmentTests {}

// MARK: - Equipment Models and Catalog

extension EquipmentTests {

    @Test
    func everyProductHasPrimaryEquipmentTiersZeroThroughFive() throws {
        let catalog = EquipmentCatalog()

        for product in ProductCatalog().products {
            let tiers = catalog.primaryTiers(for: product)

            #expect(tiers.map(\.level) == [0, 1, 2, 3, 4, 5])
            #expect(tiers.allSatisfy { $0.equipment.count == 1 })
        }
    }

    @Test
    func primaryTiersContainExpectedEquipment() throws {
        let productCatalog = ProductCatalog()
        let equipmentCatalog = EquipmentCatalog()

        let expectedEquipment: [ProductID: [EquipmentID]] = [
            .pies: [
                equipmentCatalog.basicHomeOven.id,
                equipmentCatalog.doubleRangeOven.id,
                equipmentCatalog.convectionOven.id,
                equipmentCatalog.doubleConvectionOven.id,
                equipmentCatalog.commercialDeckOven.id,
                equipmentCatalog.commercialRackOven.id
            ],
            .hotDogs: [
                equipmentCatalog.smallCharcoalGrill.id,
                equipmentCatalog.largeCharcoalGrill.id,
                equipmentCatalog.smallGasGrill.id,
                equipmentCatalog.largeGasGrill.id,
                equipmentCatalog.commercialFlatTop.id,
                equipmentCatalog.commercialGrillStation.id
            ],
            .smoothies: [
                equipmentCatalog.handMixer.id,
                equipmentCatalog.basicBlender.id,
                equipmentCatalog.highPowerBlender.id,
                equipmentCatalog.professionalBlender.id,
                equipmentCatalog.commercialBlendingStation.id,
                equipmentCatalog.highCapacityCommercialBlendingStation.id
            ]
        ]

        for product in productCatalog.products {
            let equipmentIDs = equipmentCatalog.primaryTiers(for: product)
                .flatMap(\.equipment)
                .map(\.id)

            #expect(equipmentIDs == expectedEquipment[product.id])
        }
    }

    @Test
    func tierZeroPrimaryEquipmentIsFree() {
        let equipmentCatalog = EquipmentCatalog()

        for product in ProductCatalog().products {
            let tierZero = equipmentCatalog.primaryTiers(for: product)[0]

            #expect(tierZero.equipment[0].price == 0)
        }
    }

    @Test
    func primaryCapacityIncreasesAcrossTiers() {
        let equipmentCatalog = EquipmentCatalog()

        for product in ProductCatalog().products {
            let capacities = equipmentCatalog.primaryTiers(for: product)
                .flatMap(\.equipment)
                .map(\.capacity)

            for (previousCapacity, nextCapacity) in zip(
                capacities,
                capacities.dropFirst()
            ) {
                #expect(nextCapacity > previousCapacity)
            }
        }
    }

    @Test
    func purchasablePrimaryEquipmentHasCleanedPositivePrices() {
        let equipmentCatalog = EquipmentCatalog()

        for product in ProductCatalog().products {
            for tier in equipmentCatalog.primaryTiers(for: product) {
                let equipment = tier.equipment[0]

                guard tier.level > 0 else {
                    #expect(equipment.price == 0)
                    continue
                }

                #expect(equipment.price > 0)
                #expect(
                    equipment.price.truncatingRemainder(dividingBy: 50)
                        == 49
                )
            }
        }
    }

    @Test
    func everyProductHasFiveExpectedSecondaryEquipmentOptions() {
        let productCatalog = ProductCatalog()
        let equipmentCatalog = EquipmentCatalog()
        let expectedEquipment: [ProductID: [EquipmentID]] = [
            .pies: [
                equipmentCatalog.appleCorer.id,
                equipmentCatalog.standMixer.id,
                equipmentCatalog.foodProcessor.id,
                equipmentCatalog.doughSheeter.id,
                equipmentCatalog.piePrepStation.id
            ],
            .hotDogs: [
                equipmentCatalog.produceSlicer.id,
                equipmentCatalog.foodProcessor.id,
                equipmentCatalog.breadMaker.id,
                equipmentCatalog.meatGrinder.id,
                equipmentCatalog.hotDogPrepStation.id
            ],
            .smoothies: [
                equipmentCatalog.foodProcessor.id,
                equipmentCatalog.produceSlicer.id,
                equipmentCatalog.vacuumSealer.id,
                equipmentCatalog.iceCrusher.id,
                equipmentCatalog.produceCooler.id
            ]
        ]

        for product in productCatalog.products {
            let equipment = equipmentCatalog.secondaryEquipment(for: product)
                .equipment

            #expect(equipment.count == 5)
            #expect(equipment.map(\.id) == expectedEquipment[product.id])
        }
    }

    @Test
    func equipmentIDsAreUniqueWithinEachProductCatalog() {
        let equipmentCatalog = EquipmentCatalog()

        for product in ProductCatalog().products {
            let equipment = equipmentCatalog.primaryTiers(for: product)
                .flatMap(\.equipment)
                + equipmentCatalog.secondaryEquipment(for: product).equipment
            let ids = equipment.map(\.id)

            #expect(Set(ids).count == ids.count)
        }
    }
}

// MARK: - Equipment State

extension EquipmentTests {

    @Test
    func newStateStartsWithTierZeroPrimaryEquipment() throws {
        let context = try makeEquipmentTestContext()

        #expect(context.state.activePrimaryEquipment.tierLevel == 0)
        #expect(
            context.state.activePrimaryEquipment.equipment
                == context.primaryTiers[0].equipment[0]
        )
        #expect(context.state.activePrimaryTier == context.primaryTiers[0])
    }

    @Test
    func nextPrimaryTierIsImmediatelyAfterActiveTier() throws {
        let context = try makeEquipmentTestContext()

        #expect(context.state.activePrimaryTier.level == 0)
        #expect(context.state.nextPrimaryTier?.level == 1)
    }

    @Test
    func highestPrimaryTierHasNoNextTier() throws {
        let context = try makeEquipmentTestContext(
            activeTierLevel: ProductionCapacityBalance.totalTiers
        )

        #expect(
            context.state.activePrimaryTier.level
                == ProductionCapacityBalance.totalTiers
        )
        #expect(context.state.nextPrimaryTier == nil)
    }

    @Test
    func applyingPrimaryUpgradeReplacesActiveEquipment() throws {
        let context = try makeEquipmentTestContext()
        let nextTier = try #require(context.state.nextPrimaryTier)
        let nextEquipment = try #require(nextTier.equipment.first)

        context.state.applyUpgrade(nextEquipment)

        #expect(context.state.activePrimaryEquipment.equipment == nextEquipment)
        #expect(context.state.activePrimaryEquipment.tierLevel == nextTier.level)
        #expect(context.state.activePrimaryTier == nextTier)
    }

    @Test
    func applyingSecondaryUpgradeMovesEquipmentFromAvailableToOwned() throws {
        let context = try makeEquipmentTestContext()
        let equipment = try #require(
            context.state.availableSecondaryEquipment.equipment.first
        )

        context.state.applyUpgrade(equipment)

        #expect(context.state.ownedSecondaryEquipment.contains(equipment))
        #expect(!context.state.availableSecondaryEquipment.contains(equipment))
    }

    @Test
    func capturedRollbackStateContainsPrimaryAndSecondaryEquipment() throws {
        let context = try makeEquipmentTestContext(activeTierLevel: 1)
        let secondaryEquipment = try #require(
            context.secondaryCatalog.equipment.first
        )
        context.state.applyUpgrade(secondaryEquipment)

        let rollbackState = context.state.captureRollbackState()

        #expect(
            rollbackState.activePrimaryEquipment
                == context.state.activePrimaryEquipment
        )
        #expect(
            rollbackState.ownedSecondaryEquipment
                == context.state.ownedSecondaryEquipment
        )
    }

    @Test
    func revertingUpgradeRestoresPrimaryAndSecondaryEquipment() throws {
        let context = try makeEquipmentTestContext()
        let existingSecondary = try #require(
            context.secondaryCatalog.equipment.first
        )
        context.state.applyUpgrade(existingSecondary)
        let rollbackState = context.state.captureRollbackState()

        let nextPrimary = try #require(
            context.state.nextPrimaryTier?.equipment.first
        )
        let addedSecondary = context.secondaryCatalog.equipment[1]
        context.state.applyUpgrade(nextPrimary)
        context.state.applyUpgrade(addedSecondary)

        context.state.revertUpgrade(to: rollbackState)

        #expect(
            context.state.activePrimaryEquipment
                == rollbackState.activePrimaryEquipment
        )
        #expect(
            context.state.ownedSecondaryEquipment
                == rollbackState.ownedSecondaryEquipment
        )
        #expect(!context.state.ownedSecondaryEquipment.contains(addedSecondary))
    }

    @Test
    func secondaryCollectionCombinesDemandCapacityAndCosts() throws {
        let context = try makeEquipmentTestContext()
        let equipment = Array(context.secondaryCatalog.equipment.prefix(3))
        let collection = SecondaryEquipmentCollection(equipment: equipment)

        #expect(
            collection.totalDemandLevel
                == equipment.reduce(0) { $0 + $1.demandLevel }
        )
        #expect(
            abs(
                collection.totalDemandEffectScore
                    - equipment.reduce(0) { $0 + $1.demandEffectScore }
            ) < 0.000_001
        )
        #expect(
            collection.totalCapacity
                == equipment.reduce(0) { $0 + $1.capacity }
        )
        #expect(
            collection.totalCosts[.oneTime]
                == equipment.reduce(0) { $0 + $1.price }
        )
        #expect(collection.totalCosts[.daily] == nil)
        #expect(collection.totalCosts[.weekly] == nil)
    }
}

private struct EquipmentTestContext {
    let primaryTiers: [EquipmentTier]
    let secondaryCatalog: SecondaryEquipmentCollection
    let state: EquipmentState
}

@MainActor
private func makeEquipmentTestContext(
    productID: ProductID = .pies,
    activeTierLevel: Int? = nil
) throws -> EquipmentTestContext {
    let product = try #require(
        ProductCatalog().products.first { $0.id == productID }
    )
    let catalog = EquipmentCatalog()
    let primaryTiers = catalog.primaryTiers(for: product)
    let secondaryCatalog = catalog.secondaryEquipment(for: product)

    let activePrimaryEquipment: ActivePrimaryEquipment?
    if let activeTierLevel {
        let tier = try #require(
            primaryTiers.first { $0.level == activeTierLevel }
        )
        activePrimaryEquipment = ActivePrimaryEquipment(
            equipment: try #require(tier.equipment.first),
            tierLevel: tier.level
        )
    } else {
        activePrimaryEquipment = nil
    }

    return EquipmentTestContext(
        primaryTiers: primaryTiers,
        secondaryCatalog: secondaryCatalog,
        state: EquipmentState(
            primaryTiers: primaryTiers,
            secondaryEquipmentCatalog: secondaryCatalog,
            activePrimaryEquipment: activePrimaryEquipment
        )
    )
}
