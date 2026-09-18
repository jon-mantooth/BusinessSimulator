import Testing
@testable import BusinessSimulator

@MainActor
struct PricingTests {}

// MARK: - Price Calculations

extension PricingTests {

    @Test
    func oneTimePriceUsesTargetPaybackDays() {
        let dailyBenefit = 37.50

        let price = UpgradePricing.calculatePrice(
            dailyBenefit: dailyBenefit,
            paymentSchedule: .oneTime,
            tierLevel: 1
        )

        #expect(
            price == dailyBenefit * UpgradePricing.targetPaybackDays
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
        let initialMarketSizeMultiplier =
            SimulationBalance.marketSize.multiplier(
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
            * initialMarketSizeMultiplier
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
    func marketSizeOnlyDailyBenefitUsesMarketSizeEffect(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let marketSizeEffectScore = 0.2
        let marketSizeWeight = 0.25
        let marketSizeMultiplier = SimulationBalance.marketSize.multiplier(
            weight: marketSizeWeight,
            effectScore: marketSizeEffectScore
        )
        let profitPerUnit = product.baseIdealPrice
            * (1.0 - UpgradePricing.ingredientCostRatio)
        let expectedBenefit = Double(product.idealUnitsSold)
            * (marketSizeMultiplier - 1.0)
            * profitPerUnit

        let benefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            marketSizeEffectScore: marketSizeEffectScore,
            marketSizeWeight: marketSizeWeight
        )

        #expect(abs(benefit - expectedBenefit) < 0.000_001)
    }

    @Test(arguments: pricingProductIDs)
    func laterTierMarketSizeBenefitUsesExpectedTierState(
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
        let initialMarketSizeMultiplier =
            SimulationBalance.marketSize.multiplier(
                weight: 1.0,
                effectScore: tierProgress
            )
        let marketSizeEffectScore = 0.2
        let marketSizeWeight = 0.25
        let purchasedMarketSizeMultiplier =
            SimulationBalance.marketSize.multiplier(
                weight: marketSizeWeight,
                effectScore: marketSizeEffectScore
            )
        let profitPerUnit = product.baseIdealPrice
            * (
                initialDemandMultiplier
                    - UpgradePricing.ingredientCostRatio
            )
        let expectedBenefit = Double(product.idealUnitsSold)
            * initialMarketSizeMultiplier
            * (purchasedMarketSizeMultiplier - 1.0)
            * profitPerUnit

        let benefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: tierLevel,
            product: product,
            marketSizeEffectScore: marketSizeEffectScore,
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
    func replacementCapacityUsesOnlyCapacityAboveExpectedTierCapacity(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let tierLevel = 3
        let precedingLevel = tierLevel - 1
        let expectedTierCapacity = ProductionCapacityBalance.baseCapacity(
            baseIdealUnitsSold: product.idealUnitsSold
        ) + ProductionCapacityBalance.expectedCapacityIncrease(
            baseIdealUnitsSold: product.idealUnitsSold,
            tierLevel: precedingLevel
        )
        let addedCapacity = 10
        let tierProgress = Double(precedingLevel)
            / Double(UpgradePricing.totalUpgradeTiers)
        let expectedPricePerUnit = product.baseIdealPrice
            * SimulationBalance.demand.multiplier(
                weight: 1.0,
                effectScore: tierProgress
            )
        let ingredientCostPerUnit = product.baseIdealPrice
            * UpgradePricing.ingredientCostRatio
        let expectedBenefit = Double(addedCapacity)
            * (expectedPricePerUnit - ingredientCostPerUnit)

        let benefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: tierLevel,
            product: product,
            capacityEffect: .replacement(
                expectedTierCapacity + addedCapacity
            )
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
        let marketSizeEffectScore = 0.2
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
            marketSizeEffectScore: marketSizeEffectScore,
            marketSizeWeight: marketSizeWeight
        )

        let combinedBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            demandEffectScore: demandEffectScore,
            demandWeight: demandWeight,
            marketSizeEffectScore: marketSizeEffectScore,
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
