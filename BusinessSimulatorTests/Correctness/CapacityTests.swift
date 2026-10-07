import Testing
@testable import BusinessSimulator

@MainActor
struct CapacityTests {}

// MARK: - Capacity Schedule

extension CapacityTests {

    @Test
    func scheduleCalculatesAndRoundsWholeUnitCapacity() {
        let upgradeID = CapacityUpgradeID.laborBaseline
        let schedule = CapacitySchedule(
            upgrades: [
                CapacityUpgrade(
                    upgradeID: upgradeID,
                    scheduledCapacity: 0.5
                )
            ]
        )

        #expect(
            schedule.capacity(
                for: upgradeID,
                idealUnitsSold: 3
            ) == 2
        )
    }

    @Test(arguments: capacityProductIDs)
    func scheduleUsesProductsIdealUnitSales(productID: ProductID) {
        let product = ProductCatalog().product(for: productID)
        let upgrade = CapacityUpgrade(
            upgradeID: .laborBaseline,
            scheduledCapacity: 0.75
        )
        let schedule = CapacitySchedule(upgrades: [upgrade])

        let capacity = schedule.capacity(
            for: upgrade.upgradeID,
            product: product
        )
        let expectedCapacity = Int(
            (
                Double(product.idealUnitsSold)
                    * upgrade.scheduledCapacity
            ).rounded()
        )

        #expect(capacity == expectedCapacity)
    }

    @Test
    func scheduleEntryOrderDoesNotChangeCapacity() {
        let upgrades = [
            CapacityUpgrade(
                upgradeID: .laborBaseline,
                scheduledCapacity: 0.75
            ),
            CapacityUpgrade(
                upgradeID: .laborSpecialist,
                scheduledCapacity: 0.5
            )
        ]
        let ordered = CapacitySchedule(upgrades: upgrades)
        let reversed = CapacitySchedule(
            upgrades: Array(upgrades.reversed())
        )

        for upgrade in upgrades {
            #expect(
                ordered.capacity(
                    for: upgrade.upgradeID,
                    idealUnitsSold: 47
                )
                    == reversed.capacity(
                        for: upgrade.upgradeID,
                        idealUnitsSold: 47
                    )
            )
        }
    }
}

// MARK: - Primary Equipment Capacity

extension CapacityTests {

    @Test(arguments: capacityProductIDs)
    func primaryEquipmentUsesSharedCapacitySchedule(productID: ProductID) throws {
        let product = ProductCatalog().product(for: productID)
        let catalog = EquipmentCatalog()
        let tiers = catalog.primaryTiers(for: product)

        for tier in tiers {
            let equipment = try #require(tier.equipment.first)
            let upgradeTier = try #require(
                UpgradeTierLevel(rawValue: tier.level)
            )
            let expectedCapacity = catalog.primaryCapacitySchedule.capacity(
                for: .tier(upgradeTier),
                product: product
            )

            #expect(equipment.capacity == expectedCapacity)
            #expect(equipment.capacityType == .total)
            #expect(!equipment.capacityDisplayText.hasPrefix("+"))
        }
    }

    @Test(arguments: capacityProductIDs)
    func primaryEquipmentCapacityStrictlyIncreases(productID: ProductID) throws {
        let product = ProductCatalog().product(for: productID)
        let tiers = EquipmentCatalog().primaryTiers(for: product)
        let capacities = try tiers.map { tier in
            try #require(tier.equipment.first).capacity
        }

        for (earlier, later) in zip(capacities, capacities.dropFirst()) {
            #expect(later > earlier)
        }
    }

    @Test(arguments: capacityProductIDs)
    func highestPrimaryTierReachesSchedulesFinalCapacity(
        productID: ProductID
    ) throws {
        let product = ProductCatalog().product(for: productID)
        let catalog = EquipmentCatalog()
        let highestTier = try #require(
            catalog.primaryTiers(for: product).max {
                $0.level < $1.level
            }
        )
        let equipment = try #require(highestTier.equipment.first)
        let upgradeTier = try #require(
            UpgradeTierLevel(rawValue: highestTier.level)
        )

        #expect(
            equipment.capacity
                == catalog.primaryCapacitySchedule.capacity(
                    for: .tier(upgradeTier),
                    product: product
                )
        )
    }

    @Test(arguments: capacityProductIDs)
    func primaryEquipmentPricingUsesScheduledCapacity(productID: ProductID) throws {
        let product = ProductCatalog().product(for: productID)
        let tiers = EquipmentCatalog().primaryTiers(for: product)

        for tier in tiers where tier.level > 0 {
            let equipment = try #require(tier.equipment.first)
            let dailyBenefit = UpgradePricing.calculateDailyBenefit(
                tierLevel: tier.level,
                product: product,
                locationDemandMultiplier:
                    tier.requiredLocationTier.demandMultiplier,
                representativeMarketSizeMultiplier:
                    tier.requiredLocationTier.pricingMarketSizeMultiplier,
                demandEffectScore: equipment.demandEffectScore,
                demandWeight: EquipmentDimension.primaryDemandWeight,
                capacityEffect: .replacement(equipment.capacity)
            )
            let expectedPrice = Equipment.cleanPrice(
                UpgradePricing.calculatePrice(
                    dailyBenefit: dailyBenefit,
                    paymentSchedule: equipment.paymentSchedule,
                    tierLevel: tier.level
                )
            )

            #expect(equipment.price == expectedPrice)
        }
    }
}

// MARK: - Secondary Equipment Capacity

extension CapacityTests {

    @Test(arguments: capacityProductIDs)
    func secondaryStrengthsUseSharedScheduleAndRemainDistinct(
        productID: ProductID
    ) throws {
        let product = ProductCatalog().product(for: productID)
        let catalog = EquipmentCatalog()
        let equipment = catalog.secondaryEquipment(for: product).equipment
        let expectedByStrength = secondaryCapacities(
            catalog: catalog,
            product: product
        )

        for item in equipment {
            guard case let .secondary(strength) = item.category else {
                Issue.record("Secondary catalog contained primary equipment.")
                continue
            }

            #expect(item.capacity == expectedByStrength[strength])
            #expect(item.capacityType == .additional)
            #expect(item.capacityDisplayText.hasPrefix("+"))
        }

        let low = try #require(expectedByStrength[.low])
        let medium = try #require(expectedByStrength[.medium])
        let high = try #require(expectedByStrength[.high])
        #expect(low < medium)
        #expect(medium < high)
    }

    @Test(arguments: capacityProductIDs)
    func configuringSecondaryCapacityDoesNotChangeManualPrice(
        productID: ProductID
    ) throws {
        let product = ProductCatalog().product(for: productID)
        let catalog = EquipmentCatalog()
        let configuredEquipment = catalog.secondaryEquipment(
            for: product
        ).equipment
        let originalByID = Dictionary(
            uniqueKeysWithValues: allCatalogSecondaryEquipment(catalog).map {
                ($0.id, $0)
            }
        )

        for equipment in configuredEquipment {
            let original = try #require(originalByID[equipment.id])
            #expect(equipment.price == original.price)
        }
    }
}

// MARK: - Labor Capacity

extension CapacityTests {

    @Test(arguments: capacityProductIDs)
    func laborUsesSharedCapacitySchedule(productID: ProductID) throws {
        let product = ProductCatalog().product(for: productID)
        let catalog = LaborCatalog()
        let labor = catalog.labor(for: product)
        let specialist = try #require(labor.first)
        let sharedWorkers = labor.dropFirst()

        #expect(
            specialist.capacity
                == catalog.capacitySchedule.capacity(
                    for: .laborSpecialist,
                    product: product
                )
        )
        for worker in sharedWorkers {
            #expect(
                worker.capacity
                    == catalog.capacitySchedule.capacity(
                        for: .sharedLabor,
                        product: product
                    )
            )
        }
    }

    @Test(arguments: capacityProductIDs)
    func laborStateUsesScheduledBaselineAndAddsWorkersCumulatively(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let catalog = LaborCatalog()
        let labor = catalog.labor(for: product)
        let state = LaborState(
            laborCatalog: LaborCollection(labor: labor),
            baseIdealUnitsSold: product.idealUnitsSold
        )
        let expectedBaseline = catalog.capacitySchedule.capacity(
            for: .laborBaseline,
            product: product
        )

        #expect(state.totalCapacity == expectedBaseline)

        var expectedCapacity = expectedBaseline
        for worker in labor {
            state.applyUpgrade(worker)
            expectedCapacity += worker.capacity
            #expect(state.totalCapacity == expectedCapacity)
            #expect(worker.capacityType == .additional)
            #expect(worker.capacityDisplayText.hasPrefix("+"))
        }
    }

    @Test(arguments: capacityProductIDs)
    func laborPricingUsesScheduledCapacity(productID: ProductID) {
        let product = ProductCatalog().product(for: productID)
        let workers = LaborCatalog().labor(for: product)

        for worker in workers {
            let dailyBenefit = UpgradePricing.calculateDailyBenefit(
                tierLevel: 1,
                product: product,
                demandEffectScore: worker.demandEffectScore,
                demandWeight: LaborDimension.demandWeight,
                capacityEffect: .additive(worker.capacity)
            )
            let expectedPrice = UpgradePricing.calculatePrice(
                dailyBenefit: dailyBenefit,
                paymentSchedule: worker.paymentSchedule,
                tierLevel: 1
            ).rounded()

            #expect(worker.price == expectedPrice)
        }
    }
}

private let capacityProductIDs: [ProductID] = [
    .pies,
    .hotDogs,
    .smoothies
]

private func secondaryCapacities(
    catalog: EquipmentCatalog,
    product: Product
) -> [SecondaryCapacityStrength: Int] {
    let low = max(
        1,
        catalog.secondaryCapacitySchedule.capacity(
            for: .secondaryEquipment(.low),
            product: product
        )
    )
    let medium = max(
        low + 1,
        catalog.secondaryCapacitySchedule.capacity(
            for: .secondaryEquipment(.medium),
            product: product
        )
    )
    let high = max(
        medium + 1,
        catalog.secondaryCapacitySchedule.capacity(
            for: .secondaryEquipment(.high),
            product: product
        )
    )

    return [
        .low: low,
        .medium: medium,
        .high: high
    ]
}

private func allCatalogSecondaryEquipment(
    _ catalog: EquipmentCatalog
) -> [Equipment] {
    [
        catalog.appleCorer,
        catalog.standMixer,
        catalog.foodProcessor,
        catalog.doughSheeter,
        catalog.piePrepStation,
        catalog.produceSlicer,
        catalog.breadMaker,
        catalog.meatGrinder,
        catalog.hotDogPrepStation,
        catalog.vacuumSealer,
        catalog.iceCrusher,
        catalog.produceCooler
    ]
}
