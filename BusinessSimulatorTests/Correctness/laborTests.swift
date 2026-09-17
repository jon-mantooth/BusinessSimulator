import Testing
@testable import BusinessSimulator

@MainActor
struct LaborTests {}

// MARK: - Labor Price Calculations

extension LaborTests {

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

    @Test(arguments: laborProductIDs)
    func tierOneLaborBenefitUsesProductBaseState(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let demandEffectScore = 2.0 / 5.0
        let addedCapacity = LaborCapacityBalance.capacity(
            ratio: LaborCapacityBalance.specialistRatio,
            baseIdealUnitsSold: product.idealUnitsSold
        )
        let ingredientCostPerUnit = product.baseIdealPrice
            * UpgradePricing.ingredientCostRatio
        let initialProfit = Double(product.idealUnitsSold)
            * (product.baseIdealPrice - ingredientCostPerUnit)
        let purchasedDemandMultiplier = SimulationBalance.demand.multiplier(
            weight: LaborDimension.demandWeight,
            effectScore: demandEffectScore
        )
        let demandProfit = Double(product.idealUnitsSold)
            * (
                product.baseIdealPrice * purchasedDemandMultiplier
                    - ingredientCostPerUnit
            )
        let expectedBenefit = demandProfit - initialProfit
            + Double(addedCapacity)
                * (product.baseIdealPrice - ingredientCostPerUnit)

        let benefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            demandEffectScore: demandEffectScore,
            demandWeight: LaborDimension.demandWeight,
            capacityEffect: .additive(addedCapacity)
        )

        #expect(abs(benefit - expectedBenefit) < 0.000_001)
    }

    @Test(arguments: laborProductIDs)
    func equivalentUpgradeBenefitsIncreaseInLaterTiers(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let tierOneBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 1,
            product: product,
            demandEffectScore: 0.2,
            demandWeight: LaborDimension.demandWeight,
            capacityEffect: .additive(10)
        )
        let tierFiveBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: 5,
            product: product,
            demandEffectScore: 0.2,
            demandWeight: LaborDimension.demandWeight,
            capacityEffect: .additive(10)
        )

        #expect(tierFiveBenefit > tierOneBenefit)
    }

    @Test(arguments: laborProductIDs)
    func laborWagesUseDemandCapacityAndDailyPricing(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let labor = LaborCatalog().labor(for: product)

        for worker in labor {
            let dailyBenefit = UpgradePricing.calculateDailyBenefit(
                tierLevel: 1,
                product: product,
                demandEffectScore: worker.demandEffectScore,
                demandWeight: LaborDimension.demandWeight,
                capacityEffect: .additive(worker.capacity)
            )
            let expectedWage = UpgradePricing.calculatePrice(
                dailyBenefit: dailyBenefit,
                paymentSchedule: .daily,
                tierLevel: 1
            ).rounded()

            #expect(worker.price == expectedWage)
            #expect(worker.price.rounded() == worker.price)
        }
    }

    @Test(arguments: laborProductIDs)
    func specialistAndSharedWorkersUseIntendedPricingInputs(
        productID: ProductID
    ) throws {
        let product = ProductCatalog().product(for: productID)
        let labor = LaborCatalog().labor(for: product)
        let specialist = try #require(labor.first)
        let sharedWorkers = Array(labor.dropFirst())

        #expect(specialist.demandLevel == 2)
        #expect(specialist.totalLevels == 5)
        #expect(
            specialist.capacity
                == LaborCapacityBalance.capacity(
                    ratio: LaborCapacityBalance.specialistRatio,
                    baseIdealUnitsSold: product.idealUnitsSold
                )
        )

        for worker in sharedWorkers {
            #expect(worker.demandLevel == 1)
            #expect(worker.totalLevels == 5)
            #expect(
                worker.capacity
                    == LaborCapacityBalance.capacity(
                        ratio: LaborCapacityBalance.sharedWorkerRatio,
                        baseIdealUnitsSold: product.idealUnitsSold
                    )
            )
        }
    }

    @Test(arguments: laborProductIDs)
    func laborPricingIsIndependentOfHiringOrder(
        productID: ProductID
    ) throws {
        let product = ProductCatalog().product(for: productID)
        let catalogLabor = LaborCatalog().labor(for: product)
        let firstWorker = try #require(catalogLabor.first)
        let secondWorker = try #require(catalogLabor.dropFirst().first)
        let state = LaborState(
            laborCatalog: LaborCollection(labor: catalogLabor),
            baseIdealUnitsSold: product.idealUnitsSold
        )
        let pricesBeforeHiring = Dictionary(
            uniqueKeysWithValues: catalogLabor.map { ($0.id, $0.price) }
        )

        state.applyUpgrade(secondWorker)
        state.applyUpgrade(firstWorker)

        for worker in state.ownedLabor.labor {
            #expect(worker.price == pricesBeforeHiring[worker.id])
        }
        for worker in state.availableLabor.labor {
            #expect(worker.price == pricesBeforeHiring[worker.id])
        }
    }
}

private let laborProductIDs: [ProductID] = [
    .pies,
    .hotDogs,
    .smoothies
]
