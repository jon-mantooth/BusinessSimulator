import Testing
@testable import BusinessSimulator

@MainActor
struct PricingTests {}

// MARK: - Storage Pricing

extension PricingTests {

    @Test(arguments: pricingProductIDs)
    func storagePricesUseCapacityAndLocationPricing(productID: ProductID) {
        let product = ProductCatalog().product(for: productID)
        let tiers = StorageCatalog().tiers(for: product)

        for tier in tiers where tier.level > 0 {
            let dailyBenefit = UpgradePricing.calculateDailyBenefit(
                tierLevel: tier.level,
                product: product,
                locationDemandMultiplier:
                    tier.requiredLocationTier.demandMultiplier,
                representativeMarketSizeMultiplier:
                    tier.requiredLocationTier.pricingMarketSizeMultiplier,
                capacityEffect: .replacement(tier.storage.capacity)
            )
            let expectedPrice = Storage.cleanPrice(
                UpgradePricing.calculatePrice(
                    dailyBenefit: dailyBenefit,
                    paymentSchedule: .oneTime,
                    tierLevel: tier.level,
                    capacityEffect: .replacement(tier.storage.capacity)
                )
            )

            #expect(tier.storage.price == expectedPrice)
        }
    }

    @Test
    func laterStorageTiersUseLocationLevelTwoPricing() {
        let product = ProductCatalog().product(for: .pies)
        let tiers = StorageCatalog().tiers(for: product)

        #expect(tiers[1].requiredLocationTier == .tierOne)
        for tier in tiers.dropFirst(2) {
            #expect(tier.requiredLocationTier == .tierTwo)
        }
    }
}

// MARK: - Price Calculations

extension PricingTests {

    @Test
    func oneTimeAdditivePriceUsesAdditiveTargetPaybackDays() {
        let dailyBenefit = 37.50

        let price = UpgradePricing.calculatePrice(
            dailyBenefit: dailyBenefit,
            paymentSchedule: .oneTime,
            tierLevel: 1,
            capacityEffect: .additive(10)
        )

        #expect(
            price
                == dailyBenefit
                    * UpgradePricing.additiveTargetPaybackDays
        )
    }

    @Test
    func oneTimeReplacementPriceUsesReplacementTargetPaybackDays() {
        let dailyBenefit = 37.50

        let price = UpgradePricing.calculatePrice(
            dailyBenefit: dailyBenefit,
            paymentSchedule: .oneTime,
            tierLevel: 1,
            capacityEffect: .replacement(100)
        )

        #expect(
            price
                == dailyBenefit
                    * UpgradePricing.replacementTargetPaybackDays
        )
    }

    @Test
    func recurringBenefitMultiplierInterpolatesAcrossTiers() {
        let multipliers = (1...UpgradePricing.totalUpgradeTiers).map {
            UpgradePricing.recurringBenefitMultiplier(tierLevel: $0)
        }
        let expectedStep = (
            UpgradePricing.maximumRecurringBenefitMultiplier
                - UpgradePricing.minimumRecurringBenefitMultiplier
        ) / Double(UpgradePricing.totalUpgradeTiers - 1)

        #expect(
            multipliers.first
                == UpgradePricing.maximumRecurringBenefitMultiplier
        )
        #expect(
            multipliers.last
                == UpgradePricing.minimumRecurringBenefitMultiplier
        )

        for (earlier, later) in zip(
            multipliers,
            multipliers.dropFirst()
        ) {
            #expect(abs((earlier - later) - expectedStep) < 0.000_001)
        }
    }

    @Test
    func dailyRecurringPriceUsesTierMultiplier() {
        let dailyBenefit = 80.0
        let tierLevel = 3
        let expectedPrice = dailyBenefit
            * UpgradePricing.recurringBenefitMultiplier(
                tierLevel: tierLevel
            )

        let price = UpgradePricing.calculatePrice(
            dailyBenefit: dailyBenefit,
            paymentSchedule: .daily,
            tierLevel: tierLevel
        )

        #expect(abs(price - expectedPrice) < 0.000_001)
    }

    @Test
    func weeklyRecurringPriceUsesFiveBusinessDays() {
        let dailyBenefit = 80.0
        let tierLevel = 3
        let expectedPrice = dailyBenefit
            * UpgradePricing.businessDaysPerWeek
            * UpgradePricing.recurringBenefitMultiplier(
                tierLevel: tierLevel
            )

        let price = UpgradePricing.calculatePrice(
            dailyBenefit: dailyBenefit,
            paymentSchedule: .weekly,
            tierLevel: tierLevel
        )

        #expect(abs(price - expectedPrice) < 0.000_001)
    }

    @Test(arguments: pricingPaymentSchedules)
    func zeroDailyBenefitProducesZeroPrice(
        paymentSchedule: PaymentSchedule
    ) {
        let price = UpgradePricing.calculatePrice(
            dailyBenefit: 0,
            paymentSchedule: paymentSchedule,
            tierLevel: 3
        )

        #expect(price == 0)
    }
}

// MARK: - Location Pricing

// MARK: Location Demand

extension PricingTests {

    @Test
    func laterLocationDemandProducesGreaterDemandBenefit() {
        let product = ProductCatalog().product(for: .pies)
        let startingBenefit = locationDemandBenefit(
            product: product,
            locationTier: .tierOne
        )
        let laterBenefit = locationDemandBenefit(
            product: product,
            locationTier: .tierTwo
        )

        #expect(laterBenefit > startingBenefit)
    }

    @Test
    func locationDemandMultiplierIsAppliedExactlyOnce() {
        let product = ProductCatalog().product(for: .pies)
        let startingBenefit = locationDemandBenefit(
            product: product,
            locationTier: .tierOne
        )
        let laterBenefit = locationDemandBenefit(
            product: product,
            locationTier: .tierTwo
        )
        let expectedRatio = LocationTierLevel.tierTwo.demandMultiplier
            / LocationTierLevel.tierOne.demandMultiplier

        #expect(
            abs(laterBenefit / startingBenefit - expectedRatio)
                < 0.000_001
        )
    }

    @Test
    func laterLocationDemandIncreasesCapacityBenefit() {
        let product = ProductCatalog().product(for: .pies)
        let addedCapacity = 10
        let startingBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            locationDemandMultiplier:
                LocationTierLevel.tierOne.demandMultiplier,
            capacityEffect: .additive(addedCapacity)
        )
        let laterBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            locationDemandMultiplier:
                LocationTierLevel.tierTwo.demandMultiplier,
            capacityEffect: .additive(addedCapacity)
        )

        #expect(laterBenefit > startingBenefit)
    }

    @Test
    func advertisementTierUsesRequiredLocationsPricingContext() throws {
        let product = ProductCatalog().product(for: .pies)

        for locationTier in locationPricingTiers {
            let tier = makeLocationPricedAdvertisementTier(
                product: product,
                requiredLocationTier: locationTier
            )
            let advertisement = try #require(tier.advertisements.first)
            let expectedPrice = expectedAdvertisementPrice(
                advertisement: advertisement,
                product: product,
                tierLevel: tier.level,
                locationTier: locationTier
            )

            #expect(advertisement.price == expectedPrice)
        }
    }

    @Test
    func equipmentTierUsesRequiredLocationsPricingContext() throws {
        let product = ProductCatalog().product(for: .pies)

        for locationTier in locationPricingTiers {
            let tier = makeLocationPricedEquipmentTier(
                product: product,
                requiredLocationTier: locationTier
            )
            let equipment = try #require(tier.equipment.first)
            let expectedPrice = expectedEquipmentPrice(
                equipment: equipment,
                product: product,
                tierLevel: tier.level,
                locationTier: locationTier
            )

            #expect(equipment.price == expectedPrice)
        }
    }
}

// MARK: Location Market Size

extension PricingTests {

    @Test
    func omittedRepresentativeMarketSizeUsesDefaultPricingContext() {
        let product = ProductCatalog().product(for: .pies)
        let defaultBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            demandEffectScore: 0.2,
            demandWeight: 0.2
        )
        let explicitDefaultBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            representativeMarketSizeMultiplier: 1,
            demandEffectScore: 0.2,
            demandWeight: 0.2
        )

        #expect(defaultBenefit == explicitDefaultBenefit)
    }

    @Test
    func laterRepresentativeMarketSizeIncreasesDemandBenefit() {
        let product = ProductCatalog().product(for: .pies)
        let startingBenefit = representativeMarketSizeDemandBenefit(
            product: product,
            locationTier: .tierOne
        )
        let laterBenefit = representativeMarketSizeDemandBenefit(
            product: product,
            locationTier: .tierTwo
        )

        #expect(laterBenefit > startingBenefit)
    }

    @Test
    func representativeMarketSizeMultiplierIsAppliedExactlyOnce() {
        let product = ProductCatalog().product(for: .pies)
        let startingBenefit = representativeMarketSizeDemandBenefit(
            product: product,
            locationTier: .tierOne
        )
        let laterBenefit = representativeMarketSizeDemandBenefit(
            product: product,
            locationTier: .tierTwo
        )
        let expectedRatio = LocationTierLevel.tierTwo
            .pricingMarketSizeMultiplier
            / LocationTierLevel.tierOne.pricingMarketSizeMultiplier

        #expect(
            abs(laterBenefit / startingBenefit - expectedRatio)
                < 0.000_001
        )
    }

    @Test
    func representativeMarketSizeDoesNotChangePureMarketSizeBenefit() {
        let product = ProductCatalog().product(for: .pies)
        let startingBenefit = pureMarketSizeBenefit(
            product: product,
            representativeLocationTier: .tierOne
        )
        let laterBenefit = pureMarketSizeBenefit(
            product: product,
            representativeLocationTier: .tierTwo
        )

        #expect(abs(startingBenefit - laterBenefit) < 0.000_001)
    }

    @Test
    func representativeMarketSizeChangesOnlyDemandPartOfCombinedBenefit() {
        let product = ProductCatalog().product(for: .pies)
        let demandStarting = representativeMarketSizeDemandBenefit(
            product: product,
            locationTier: .tierOne
        )
        let demandLater = representativeMarketSizeDemandBenefit(
            product: product,
            locationTier: .tierTwo
        )
        let combinedStarting = combinedLocationMarketSizeBenefit(
            product: product,
            representativeLocationTier: .tierOne
        )
        let combinedLater = combinedLocationMarketSizeBenefit(
            product: product,
            representativeLocationTier: .tierTwo
        )

        #expect(
            abs(
                (combinedLater - combinedStarting)
                    - (demandLater - demandStarting)
            ) < 0.000_001
        )
    }
}

// MARK: - Daily Benefit Calculations

extension PricingTests {

    @Test(arguments: pricingProductIDs)
    func zeroEffectsProduceZeroDailyBenefit(productID: ProductID) {
        let product = ProductCatalog().product(for: productID)

        let benefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product
        )

        #expect(benefit == 0)
    }

    @Test(arguments: pricingProductIDs)
    func demandOnlyDailyBenefitUsesDemandEffect(productID: ProductID) {
        let product = ProductCatalog().product(for: productID)
        let demandEffectScore = 0.2
        let demandWeight = 0.18
        let demandMultiplier = SimulationBalance.demand.multiplier(
            weight: demandWeight,
            effectScore: demandEffectScore
        )
        let expectedBenefit = Double(product.idealUnitsSold)
            * product.baseIdealPrice
            * (demandMultiplier - 1.0)

        let benefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            demandEffectScore: demandEffectScore,
            demandWeight: demandWeight
        )

        #expect(abs(benefit - expectedBenefit) < 0.000_001)
    }

    @Test(arguments: pricingProductIDs)
    func laterTierDemandBenefitUsesExpectedTierState(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let tierLevel = 4
        let tierProgress = Double(tierLevel - 1)
            / Double(UpgradePricing.totalUpgradeTiers)
        let initialDemandMultiplier = SimulationBalance.demand.multiplier(
            weight: 1.0,
            effectScore: tierProgress
        )
        let demandEffectScore = 0.2
        let demandWeight = 0.18
        let purchasedDemandMultiplier =
            SimulationBalance.demand.multiplier(
                weight: demandWeight,
                effectScore: demandEffectScore
            )
        let expectedSales = Double(product.idealUnitsSold)
        let expectedBenefit = expectedSales
            * product.baseIdealPrice
            * initialDemandMultiplier
            * (purchasedDemandMultiplier - 1.0)

        let benefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: tierLevel,
            product: product,
            demandEffectScore: demandEffectScore,
            demandWeight: demandWeight
        )

        #expect(abs(benefit - expectedBenefit) < 0.000_001)
    }

    @Test(arguments: pricingProductIDs)
    func demandBenefitUsesRepresentativeMarketSize(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let representativeMarketSizeMultiplier = 1.5
        let demandEffectScore = 0.2
        let demandWeight = 0.18
        let purchasedDemandMultiplier =
            SimulationBalance.demand.multiplier(
                weight: demandWeight,
                effectScore: demandEffectScore
            )
        let expectedBenefit = Double(product.idealUnitsSold)
            * representativeMarketSizeMultiplier
            * product.baseIdealPrice
            * (purchasedDemandMultiplier - 1.0)

        let benefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            representativeMarketSizeMultiplier:
                representativeMarketSizeMultiplier,
            demandEffectScore: demandEffectScore,
            demandWeight: demandWeight
        )

        #expect(abs(benefit - expectedBenefit) < 0.000_001)
    }

    @Test(arguments: pricingProductIDs)
    func marketSizeOnlyDailyBenefitUsesMarketSizeTarget(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let marketSizeTargetMultiplier = 1.2
        let marketSizeWeight = 0.25
        let marketSizeMultiplier = SimulationBalance.marketSize.multiplier(
            weight: marketSizeWeight,
            targetMultiplier: marketSizeTargetMultiplier
        )
        let profitPerUnit = product.baseIdealPrice
            * (1.0 - UpgradePricing.ingredientCostRatio)
        let expectedBenefit = Double(product.idealUnitsSold)
            * (marketSizeMultiplier - 1.0)
            * profitPerUnit

        let benefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            marketSizeEndingTargetMultiplier:
                marketSizeTargetMultiplier,
            marketSizeWeight: marketSizeWeight
        )

        #expect(abs(benefit - expectedBenefit) < 0.000_001)
    }

    @Test(arguments: pricingProductIDs)
    func laterTierMarketSizeBenefitUsesActualMarketSizeChange(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let tierLevel = 4
        let tierProgress = Double(tierLevel - 1)
            / Double(UpgradePricing.totalUpgradeTiers)
        let initialDemandMultiplier = SimulationBalance.demand.multiplier(
            weight: 1.0,
            effectScore: tierProgress
        )
        let marketSizeTargetMultiplier = 1.2
        let marketSizeWeight = 0.25
        let purchasedMarketSizeMultiplier =
            SimulationBalance.marketSize.multiplier(
                weight: marketSizeWeight,
                targetMultiplier: marketSizeTargetMultiplier
            )
        let profitPerUnit = product.baseIdealPrice
            * (
                initialDemandMultiplier
                    - UpgradePricing.ingredientCostRatio
            )
        let expectedBenefit = Double(product.idealUnitsSold)
            * (purchasedMarketSizeMultiplier - 1.0)
            * profitPerUnit

        let benefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: tierLevel,
            product: product,
            marketSizeEndingTargetMultiplier:
                marketSizeTargetMultiplier,
            marketSizeWeight: marketSizeWeight
        )

        #expect(abs(benefit - expectedBenefit) < 0.000_001)
    }

    @Test(arguments: pricingProductIDs)
    func capacityOnlyDailyBenefitUsesAddedUnitProfit(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let addedCapacity = 10
        let profitPerUnit = product.baseIdealPrice
            * (1.0 - UpgradePricing.ingredientCostRatio)
        let expectedBenefit = Double(addedCapacity) * profitPerUnit

        let benefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            capacityEffect: .additive(addedCapacity)
        )

        #expect(abs(benefit - expectedBenefit) < 0.000_001)
    }

    @Test(arguments: pricingProductIDs)
    func replacementCapacityPricesTheItemsTotalCapacity(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let tierLevel = 3
        let precedingLevel = tierLevel - 1
        let totalCapacity = 100
        let tierProgress = Double(precedingLevel)
            / Double(UpgradePricing.totalUpgradeTiers)
        let expectedPricePerUnit = product.baseIdealPrice
            * SimulationBalance.demand.multiplier(
                weight: 1.0,
                effectScore: tierProgress
            )
        let ingredientCostPerUnit = product.baseIdealPrice
            * UpgradePricing.ingredientCostRatio
        let expectedBenefit = Double(totalCapacity)
            * (expectedPricePerUnit - ingredientCostPerUnit)

        let benefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: tierLevel,
            product: product,
            capacityEffect: .replacement(totalCapacity)
        )

        #expect(abs(benefit - expectedBenefit) < 0.000_001)
    }

    @Test(arguments: pricingProductIDs)
    func combinedDailyBenefitAddsIndependentBenefits(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let demandEffectScore = 0.2
        let demandWeight = 0.18
        let marketSizeTargetMultiplier = 1.2
        let marketSizeWeight = 0.25
        let addedCapacity = 10
        let demandBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            demandEffectScore: demandEffectScore,
            demandWeight: demandWeight
        )
        let capacityBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            capacityEffect: .additive(addedCapacity)
        )
        let marketSizeBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            marketSizeEndingTargetMultiplier:
                marketSizeTargetMultiplier,
            marketSizeWeight: marketSizeWeight
        )

        let combinedBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            demandEffectScore: demandEffectScore,
            demandWeight: demandWeight,
            marketSizeEndingTargetMultiplier:
                marketSizeTargetMultiplier,
            marketSizeWeight: marketSizeWeight,
            capacityEffect: .additive(addedCapacity)
        )

        #expect(
            abs(
                combinedBenefit
                    - demandBenefit
                    - marketSizeBenefit
                    - capacityBenefit
            )
                < 0.000_001
        )
    }
}

private let pricingProductIDs: [ProductID] = [
    .pies,
    .hotDogs,
    .smoothies
]

private let pricingPaymentSchedules: [PaymentSchedule] = [
    .oneTime,
    .daily,
    .weekly
]

private let locationPricingTiers: [LocationTierLevel] = [
    .tierOne,
    .tierTwo
]

private func locationDemandBenefit(
    product: Product,
    locationTier: LocationTierLevel
) -> Double {
    UpgradePricing.calculateDailyBenefit(
        tierLevel: 1,
        product: product,
        locationDemandMultiplier: locationTier.demandMultiplier,
        demandEffectScore: 0.2,
        demandWeight: 0.2
    )
}

private func representativeMarketSizeDemandBenefit(
    product: Product,
    locationTier: LocationTierLevel
) -> Double {
    UpgradePricing.calculateDailyBenefit(
        tierLevel: 1,
        product: product,
        representativeMarketSizeMultiplier:
            locationTier.pricingMarketSizeMultiplier,
        demandEffectScore: 0.2,
        demandWeight: 0.2
    )
}

private func pureMarketSizeBenefit(
    product: Product,
    representativeLocationTier: LocationTierLevel
) -> Double {
    UpgradePricing.calculateDailyBenefit(
        tierLevel: 1,
        product: product,
        representativeMarketSizeMultiplier:
            representativeLocationTier.pricingMarketSizeMultiplier,
        marketSizeStartingTargetMultiplier:
            Advertisement.marketSizeTargetMultiplier(for: 0),
        marketSizeEndingTargetMultiplier:
            Advertisement.marketSizeTargetMultiplier(for: 1),
        marketSizeWeight: AdvertisementDimension.marketSizeWeight
    )
}

private func combinedLocationMarketSizeBenefit(
    product: Product,
    representativeLocationTier: LocationTierLevel
) -> Double {
    UpgradePricing.calculateDailyBenefit(
        tierLevel: 1,
        product: product,
        representativeMarketSizeMultiplier:
            representativeLocationTier.pricingMarketSizeMultiplier,
        demandEffectScore: 0.2,
        demandWeight: 0.2,
        marketSizeStartingTargetMultiplier:
            Advertisement.marketSizeTargetMultiplier(for: 0),
        marketSizeEndingTargetMultiplier:
            Advertisement.marketSizeTargetMultiplier(for: 1),
        marketSizeWeight: AdvertisementDimension.marketSizeWeight
    )
}

private func makeLocationPricedAdvertisementTier(
    product: Product,
    requiredLocationTier: LocationTierLevel
) -> AdvertisementTier {
    AdvertisementTier(
        id: AdvertisementTierID(
            rawValue: "location-pricing-\(requiredLocationTier.rawValue)"
        ),
        level: 1,
        advertisements: [
            Advertisement(
                id: AdvertisementID(
                    rawValue: "location-pricing-advertisement"
                ),
                name: "Location Pricing Advertisement",
                smallIcon: .system("megaphone.fill"),
                description: "Tests location-aware pricing.",
                paymentSchedule: .oneTime,
                demandLevel: 1,
                marketSizeLevel: 1
            )
        ],
        product: product,
        requiredLocationTier: requiredLocationTier
    )
}

private func expectedAdvertisementPrice(
    advertisement: Advertisement,
    product: Product,
    tierLevel: Int,
    locationTier: LocationTierLevel
) -> Double {
    let dailyBenefit = UpgradePricing.calculateDailyBenefit(
        tierLevel: tierLevel,
        product: product,
        locationDemandMultiplier: locationTier.demandMultiplier,
        representativeMarketSizeMultiplier:
            locationTier.pricingMarketSizeMultiplier,
        demandEffectScore: advertisement.demandEffectScore,
        demandWeight: AdvertisementDimension.demandWeight,
        marketSizeEndingTargetMultiplier:
            advertisement.marketSizeTargetMultiplier,
        marketSizeWeight: AdvertisementDimension.marketSizeWeight
    )
    let weeklyEquivalentPrice = Advertisement.cleanPrice(
        UpgradePricing.calculatePrice(
            dailyBenefit: dailyBenefit,
            paymentSchedule: .weekly,
            tierLevel: tierLevel
        )
    )

    switch advertisement.paymentSchedule {
    case .oneTime:
        return weeklyEquivalentPrice * Advertisement.oneTimeEquivalentWeeks
    case .weekly:
        return weeklyEquivalentPrice
    case .daily:
        return Advertisement.cleanPrice(
            UpgradePricing.calculatePrice(
                dailyBenefit: dailyBenefit,
                paymentSchedule: .daily,
                tierLevel: tierLevel
            )
        )
    }
}

private func makeLocationPricedEquipmentTier(
    product: Product,
    requiredLocationTier: LocationTierLevel
) -> EquipmentTier {
    EquipmentTier(
        id: EquipmentTierID(
            rawValue: "location-pricing-\(requiredLocationTier.rawValue)"
        ),
        level: 1,
        equipment: [
            Equipment(
                id: EquipmentID(rawValue: "location-pricing-equipment"),
                name: "Location Pricing Equipment",
                smallIcon: .system("oven"),
                description: "Tests location-aware pricing.",
                category: .primary,
                demandLevel: 1
            )
        ],
        product: product,
        capacitySchedule: ProductionCapacityBalance.schedule,
        requiredLocationTier: requiredLocationTier
    )
}

private func expectedEquipmentPrice(
    equipment: Equipment,
    product: Product,
    tierLevel: Int,
    locationTier: LocationTierLevel
) -> Double {
    let dailyBenefit = UpgradePricing.calculateDailyBenefit(
        tierLevel: tierLevel,
        product: product,
        locationDemandMultiplier: locationTier.demandMultiplier,
        representativeMarketSizeMultiplier:
            locationTier.pricingMarketSizeMultiplier,
        demandEffectScore: equipment.demandEffectScore,
        demandWeight: EquipmentDimension.primaryDemandWeight,
        capacityEffect: .replacement(equipment.capacity)
    )
    let price = UpgradePricing.calculatePrice(
        dailyBenefit: dailyBenefit,
        paymentSchedule: equipment.paymentSchedule,
        tierLevel: tierLevel,
        capacityEffect: .replacement(equipment.capacity)
    )

    return Equipment.cleanPrice(price)
}
