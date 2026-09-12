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
