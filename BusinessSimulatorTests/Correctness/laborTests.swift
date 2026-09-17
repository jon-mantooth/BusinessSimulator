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

// MARK: - Labor Capacity Calculations

extension LaborTests {

    @Test(arguments: laborProductIDs)
    func capacityCalculatesAndRoundsProductPercentages(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let ratios = [
            LaborCapacityBalance.playerBaselineRatio,
            LaborCapacityBalance.specialistRatio,
            LaborCapacityBalance.sharedWorkerRatio
        ]

        for ratio in ratios {
            let expectedCapacity = Int(
                (Double(product.idealUnitsSold) * ratio).rounded()
            )

            #expect(
                LaborCapacityBalance.capacity(
                    ratio: ratio,
                    baseIdealUnitsSold: product.idealUnitsSold
                ) == expectedCapacity
            )
        }
    }

    @Test(arguments: laborProductIDs)
    func playerBaselineCapacityUsesConfiguredRatio(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let expectedCapacity = LaborCapacityBalance.capacity(
            ratio: LaborCapacityBalance.playerBaselineRatio,
            baseIdealUnitsSold: product.idealUnitsSold
        )

        #expect(
            LaborCapacityBalance.playerBaselineCapacity(
                baseIdealUnitsSold: product.idealUnitsSold
            ) == expectedCapacity
        )
    }

    @Test(arguments: laborProductIDs)
    func catalogWorkersUseSpecialistAndSharedCapacityRatios(
        productID: ProductID
    ) throws {
        let product = ProductCatalog().product(for: productID)
        let labor = LaborCatalog().labor(for: product)
        let specialist = try #require(labor.first)
        let sharedWorkers = labor.dropFirst()
        let expectedSpecialistCapacity = LaborCapacityBalance.capacity(
            ratio: LaborCapacityBalance.specialistRatio,
            baseIdealUnitsSold: product.idealUnitsSold
        )
        let expectedSharedCapacity = LaborCapacityBalance.capacity(
            ratio: LaborCapacityBalance.sharedWorkerRatio,
            baseIdealUnitsSold: product.idealUnitsSold
        )

        #expect(specialist.capacity == expectedSpecialistCapacity)
        #expect(
            sharedWorkers.allSatisfy {
                $0.capacity == expectedSharedCapacity
            }
        )
    }

    @Test(arguments: laborProductIDs)
    func totalCapacityIncludesBaselineAndEveryHiredWorker(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let catalogLabor = LaborCatalog().labor(for: product)
        let state = LaborState(
            laborCatalog: LaborCollection(labor: catalogLabor),
            baseIdealUnitsSold: product.idealUnitsSold
        )
        let baseline = LaborCapacityBalance.playerBaselineCapacity(
            baseIdealUnitsSold: product.idealUnitsSold
        )

        for worker in catalogLabor {
            state.applyUpgrade(worker)
        }

        #expect(
            state.totalCapacity
                == baseline + catalogLabor.reduce(0) {
                    $0 + $1.capacity
                }
        )
    }

    @Test(arguments: laborProductIDs)
    func hiringProgressesThroughIntendedCapacityCurve(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let catalogLabor = LaborCatalog().labor(for: product)
        let state = LaborState(
            laborCatalog: LaborCollection(labor: catalogLabor),
            baseIdealUnitsSold: product.idealUnitsSold
        )
        let baseline = LaborCapacityBalance.capacity(
            ratio: LaborCapacityBalance.playerBaselineRatio,
            baseIdealUnitsSold: product.idealUnitsSold
        )
        let specialistIncrease = LaborCapacityBalance.capacity(
            ratio: LaborCapacityBalance.specialistRatio,
            baseIdealUnitsSold: product.idealUnitsSold
        )
        let sharedIncrease = LaborCapacityBalance.capacity(
            ratio: LaborCapacityBalance.sharedWorkerRatio,
            baseIdealUnitsSold: product.idealUnitsSold
        )
        let expectedProgression = [
            baseline,
            baseline + specialistIncrease,
            baseline + specialistIncrease + sharedIncrease,
            baseline + specialistIncrease + 2 * sharedIncrease,
            baseline + specialistIncrease + 3 * sharedIncrease
        ]
        var actualProgression = [state.totalCapacity]

        for worker in catalogLabor {
            state.applyUpgrade(worker)
            actualProgression.append(state.totalCapacity)
        }

        #expect(actualProgression == expectedProgression)
    }
}

// MARK: - Labor Catalog

extension LaborTests {

    @Test
    func eachProductReceivesItsCorrectSpecialist() throws {
        let productCatalog = ProductCatalog()
        let laborCatalog = LaborCatalog()
        let expectedSpecialists: [ProductID: LaborID] = [
            .pies: laborCatalog.baker.id,
            .hotDogs: laborCatalog.grillMaster.id,
            .smoothies: laborCatalog.mixologist.id
        ]

        for product in productCatalog.products {
            let labor = laborCatalog.labor(for: product)
            let specialist = try #require(labor.first)

            #expect(specialist.id == expectedSpecialists[product.id])
        }
    }

    @Test(arguments: laborProductIDs)
    func everyProductReceivesAllSharedWorkers(
        productID: ProductID
    ) {
        let product = ProductCatalog().product(for: productID)
        let laborCatalog = LaborCatalog()
        let laborIDs = Set(
            laborCatalog.labor(for: product).map(\.id)
        )
        let expectedSharedIDs: Set<LaborID> = [
            laborCatalog.prepCook.id,
            laborCatalog.lineCook.id,
            laborCatalog.cleanupWorker.id
        ]

        #expect(expectedSharedIDs.isSubset(of: laborIDs))
    }

    @Test(arguments: laborProductIDs)
    func productsDoNotReceiveAnotherProductsSpecialist(
        productID: ProductID
    ) throws {
        let product = ProductCatalog().product(for: productID)
        let laborCatalog = LaborCatalog()
        let labor = laborCatalog.labor(for: product)
        let specialist = try #require(labor.first)
        let allSpecialistIDs: Set<LaborID> = [
            laborCatalog.baker.id,
            laborCatalog.grillMaster.id,
            laborCatalog.mixologist.id
        ]

        #expect(labor.count == 4)
        #expect(
            Set(labor.map(\.id)).intersection(allSpecialistIDs)
                == [specialist.id]
        )
    }

    @Test
    func laborCatalogIDsAreUnique() {
        let catalog = LaborCatalog()
        let labor = [
            catalog.grillMaster,
            catalog.baker,
            catalog.mixologist,
            catalog.prepCook,
            catalog.lineCook,
            catalog.cleanupWorker
        ]

        #expect(Set(labor.map(\.id)).count == labor.count)
    }

    @Test
    func everyLaborOptionUsesDailyPaymentSchedule() {
        let catalog = LaborCatalog()
        let labor = [
            catalog.grillMaster,
            catalog.baker,
            catalog.mixologist,
            catalog.prepCook,
            catalog.lineCook,
            catalog.cleanupWorker
        ]

        #expect(
            labor.allSatisfy { $0.paymentSchedule == .daily }
        )
    }

    @Test
    func laborOptionsUseIntendedPortraitAssets() {
        let catalog = LaborCatalog()
        let labor = [
            catalog.grillMaster,
            catalog.baker,
            catalog.mixologist,
            catalog.prepCook,
            catalog.lineCook,
            catalog.cleanupWorker
        ]
        let expectedIcons: [LaborID: GameIcon] = [
            catalog.grillMaster.id: .asset("grill_master"),
            catalog.baker.id: .asset("head_baker"),
            catalog.mixologist.id: .asset("mixologist"),
            catalog.prepCook.id: .asset("prep_specialist"),
            catalog.lineCook.id: .asset("line_cook"),
            catalog.cleanupWorker.id: .asset("clean_up_specialist")
        ]

        for worker in labor {
            #expect(worker.smallIcon == expectedIcons[worker.id])
        }
    }
}

// MARK: - Labor Collection

extension LaborTests {

    @Test
    func emptyLaborCollectionHasZeroAggregates() {
        let collection = LaborCollection()

        #expect(collection.labor.isEmpty)
        #expect(collection.totalDemandLevel == 0)
        #expect(collection.totalDemandEffectScore == 0)
        #expect(collection.totalCapacity == 0)
        #expect(collection.totalCosts.isEmpty)
    }

    @Test
    func collectionAddsDemandLevelsAndNormalizedEffectScores() throws {
        let labor = try makeConfiguredLabor()
        let selectedLabor = Array(labor.prefix(3))
        let collection = LaborCollection(labor: selectedLabor)
        let expectedDemandLevel = selectedLabor.reduce(0) {
            $0 + $1.demandLevel
        }
        let expectedEffectScore = selectedLabor.reduce(0.0) {
            $0 + Double($1.demandLevel) / Double($1.totalLevels)
        }

        #expect(collection.totalDemandLevel == expectedDemandLevel)
        #expect(
            abs(collection.totalDemandEffectScore - expectedEffectScore)
                < 0.000_001
        )
    }

    @Test
    func collectionAddsCapacityAndDailyWages() throws {
        let labor = try makeConfiguredLabor()
        let collection = LaborCollection(labor: labor)
        let expectedCapacity = labor.reduce(0) { $0 + $1.capacity }
        let expectedDailyCost = labor.reduce(0.0) { $0 + $1.price }

        #expect(collection.totalCapacity == expectedCapacity)
        #expect(collection.totalCosts[.daily] == expectedDailyCost)
        #expect(collection.totalCosts[.oneTime] == nil)
        #expect(collection.totalCosts[.weekly] == nil)
    }

    @Test
    func containsIdentifiesWorkerByID() throws {
        let labor = try makeConfiguredLabor()
        let ownedWorker = try #require(labor.first)
        var matchingWorker = ownedWorker
        matchingWorker.price += 1
        let unownedWorker = try #require(labor.dropFirst().first)
        let collection = LaborCollection(labor: [ownedWorker])

        #expect(collection.contains(ownedWorker))
        #expect(collection.contains(matchingWorker))
        #expect(!collection.contains(unownedWorker))
    }

    @Test
    func addingWorkerUpdatesEveryAggregate() throws {
        let labor = try makeConfiguredLabor()
        let firstWorker = try #require(labor.first)
        let secondWorker = try #require(labor.dropFirst().first)
        var collection = LaborCollection(labor: [firstWorker])

        collection.add(secondWorker)

        #expect(collection.labor.map(\.id) == [
            firstWorker.id,
            secondWorker.id
        ])
        #expect(
            collection.totalDemandLevel
                == firstWorker.demandLevel + secondWorker.demandLevel
        )
        #expect(
            abs(
                collection.totalDemandEffectScore
                    - firstWorker.demandEffectScore
                    - secondWorker.demandEffectScore
            ) < 0.000_001
        )
        #expect(
            collection.totalCapacity
                == firstWorker.capacity + secondWorker.capacity
        )
        #expect(
            collection.totalCosts[.daily]
                == firstWorker.price + secondWorker.price
        )
    }

    @Test
    func hiredWorkerIsExcludedFromAvailableCollection() throws {
        let product = ProductCatalog().product(for: .pies)
        let labor = LaborCatalog().labor(for: product)
        let hiredWorker = try #require(labor.first)
        let state = LaborState(
            laborCatalog: LaborCollection(labor: labor),
            baseIdealUnitsSold: product.idealUnitsSold
        )

        state.applyUpgrade(hiredWorker)

        #expect(state.ownedLabor.contains(hiredWorker))
        #expect(!state.availableLabor.contains(hiredWorker))
        #expect(
            state.ownedLabor.labor.count
                + state.availableLabor.labor.count == labor.count
        )
    }
}

// MARK: - Labor State

extension LaborTests {

    @Test(arguments: laborProductIDs)
    func newStateStartsEmptyWithFourAvailableWorkers(
        productID: ProductID
    ) {
        let context = makeLaborStateContext(productID: productID)

        #expect(context.state.ownedLabor.labor.isEmpty)
        #expect(context.state.availableLabor.labor.count == 4)
        #expect(
            Set(context.state.availableLabor.labor.map(\.id))
                == Set(context.catalogLabor.map(\.id))
        )
    }

    @Test
    func hiringMovesWorkerFromAvailableToOwned() throws {
        let context = makeLaborStateContext()
        let worker = try #require(context.catalogLabor.first)

        context.state.applyUpgrade(worker)

        #expect(context.state.ownedLabor.contains(worker))
        #expect(!context.state.availableLabor.contains(worker))
        #expect(context.state.ownedLabor.labor.count == 1)
        #expect(context.state.availableLabor.labor.count == 3)
    }

    @Test
    func hiringAdditionalWorkerPreservesEarlierHire() throws {
        let context = makeLaborStateContext()
        let firstWorker = try #require(context.catalogLabor.first)
        let secondWorker = try #require(
            context.catalogLabor.dropFirst().first
        )

        context.state.applyUpgrade(firstWorker)
        context.state.applyUpgrade(secondWorker)

        #expect(context.state.ownedLabor.contains(firstWorker))
        #expect(context.state.ownedLabor.contains(secondWorker))
        #expect(
            context.state.ownedLabor.labor.map(\.id)
                == [firstWorker.id, secondWorker.id]
        )
    }

    @Test(arguments: laborProductIDs)
    func fullyStaffedDemandEffectScoreIsOne(
        productID: ProductID
    ) {
        let context = makeLaborStateContext(productID: productID)

        for worker in context.catalogLabor {
            context.state.applyUpgrade(worker)
        }

        #expect(
            abs(context.state.totalDemandEffectScore - 1.0)
                < 0.000_001
        )
    }

    @Test(arguments: laborProductIDs)
    func fullyStaffedDailyCostsIncludeEveryWorker(
        productID: ProductID
    ) {
        let context = makeLaborStateContext(productID: productID)
        let expectedDailyCost = context.catalogLabor.reduce(0.0) {
            $0 + $1.price
        }

        for worker in context.catalogLabor {
            context.state.applyUpgrade(worker)
        }

        #expect(
            context.state.totalCosts[.daily] == expectedDailyCost
        )
        #expect(context.state.totalCosts[.weekly] == nil)
        #expect(context.state.totalCosts[.oneTime] == nil)
    }

    @Test
    func rollbackRestoresOwnedAndAvailableLabor() throws {
        let context = makeLaborStateContext()
        let firstWorker = try #require(context.catalogLabor.first)
        let secondWorker = try #require(
            context.catalogLabor.dropFirst().first
        )
        context.state.applyUpgrade(firstWorker)
        let rollbackState = context.state.captureRollbackState()
        let expectedAvailableIDs = context.state.availableLabor.labor.map(\.id)

        context.state.applyUpgrade(secondWorker)
        context.state.revertUpgrade(to: rollbackState)

        #expect(context.state.ownedLabor.labor.map(\.id) == [firstWorker.id])
        #expect(
            context.state.availableLabor.labor.map(\.id)
                == expectedAvailableIDs
        )
    }

    @Test
    func laborStateUsesLaborDimensionID() {
        let context = makeLaborStateContext()

        #expect(context.state.dimensionID == .labor)
    }
}

private let laborProductIDs: [ProductID] = [
    .pies,
    .hotDogs,
    .smoothies
]

@MainActor
private func makeConfiguredLabor(
    productID: ProductID = .pies
) throws -> [Labor] {
    let product = ProductCatalog().product(for: productID)
    return LaborCatalog().labor(for: product)
}

@MainActor
private struct LaborStateTestContext {
    let catalogLabor: [Labor]
    let state: LaborState
}

@MainActor
private func makeLaborStateContext(
    productID: ProductID = .pies
) -> LaborStateTestContext {
    let product = ProductCatalog().product(for: productID)
    let catalogLabor = LaborCatalog().labor(for: product)

    return LaborStateTestContext(
        catalogLabor: catalogLabor,
        state: LaborState(
            laborCatalog: LaborCollection(labor: catalogLabor),
            baseIdealUnitsSold: product.idealUnitsSold
        )
    )
}
