//
//  pricing.swift
//  BusinessSimulator
//

enum CapacityPricingEffect {
    case none
    case additive(Int)
    case replacement(Int)
}

/// Estimates upgrade prices from the maximum benefit an upgrade is expected to provide.
/// These calculations are balancing guidelines rather than exact valuations; final prices
/// will be refined through testing. Keeping the pricing model centralized provides a
/// consistent starting point and makes it easy to adjust related prices together.
enum UpgradePricing {

    static let totalUpgradeTiers = 5

    // Ingredient cost is approximately 5/12 of a product's starting ideal price.
    static let ingredientCostRatio = 5.0 / 12.0

    static let targetPaybackDays = 12.0
    static let businessDaysPerWeek = 5.0
    static let maximumRecurringBenefitMultiplier = 1.20
    static let minimumRecurringBenefitMultiplier = 0.60

    /// Calculates an upgrade's expected daily benefit by applying each of its
    /// effects independently to the representative business state at the start
    /// of the supplied tier. The individual profit changes are added so one
    /// dimension's upgrade does not increase the priced value of another. The
    /// expected location multipliers establish the demand and market-size
    /// environment in which the upgrade becomes available, without pricing
    /// those existing benefits as part of the upgrade.
    static func calculateDailyBenefit(
        tierLevel: Int,
        product: Product,
        locationDemandMultiplier: Double = 1.0,
        representativeMarketSizeMultiplier: Double = 1.0,
        demandEffectScore: Double = 0,
        demandWeight: Double = 0,
        marketSizeStartingTargetMultiplier: Double = 1.0,
        marketSizeEndingTargetMultiplier: Double = 1.0,
        marketSizeWeight: Double = 0,
        capacityEffect: CapacityPricingEffect = .none
    ) -> Double {
        assert(
            (1...totalUpgradeTiers).contains(tierLevel),
            "Pricing tier must be tier 1 through 5."
        )
        assert(locationDemandMultiplier > 0)
        assert(representativeMarketSizeMultiplier > 0)
        assert((0.0...1.0).contains(demandEffectScore))
        assert((0.0...1.0).contains(demandWeight))
        assert(marketSizeStartingTargetMultiplier > 0)
        assert(
            marketSizeEndingTargetMultiplier
                >= marketSizeStartingTargetMultiplier
        )
        assert((0.0...1.0).contains(marketSizeWeight))

        let precedingLevel = tierLevel - 1
        let tierProgress = Double(precedingLevel)
            / Double(totalUpgradeTiers)
        let initialDemandMultiplier =
            SimulationBalance.demand.multiplier(
                weight: 1.0,
                effectScore: tierProgress
            )
            * locationDemandMultiplier
        let initialMarketSizeMultiplier =
            representativeMarketSizeMultiplier
        let initialProfit = expectedDailyProfit(
            product: product,
            demandMultiplier: initialDemandMultiplier,
            marketSizeMultiplier: initialMarketSizeMultiplier
        )

        let purchasedDemandMultiplier =
            SimulationBalance.demand.multiplier(
                weight: demandWeight,
                effectScore: demandEffectScore
            )
        let demandProfit = expectedDailyProfit(
            product: product,
            demandMultiplier: initialDemandMultiplier
                * purchasedDemandMultiplier,
            marketSizeMultiplier: initialMarketSizeMultiplier
        )
        let demandBenefit = max(0, demandProfit - initialProfit)

        let startingMarketSizeMultiplier =
            SimulationBalance.marketSize.multiplier(
                weight: marketSizeWeight,
                targetMultiplier: marketSizeStartingTargetMultiplier
            )
        let endingMarketSizeMultiplier =
            SimulationBalance.marketSize.multiplier(
                weight: marketSizeWeight,
                targetMultiplier: marketSizeEndingTargetMultiplier
            )
        let marketSizeStartingProfit = expectedDailyProfit(
            product: product,
            demandMultiplier: initialDemandMultiplier,
            marketSizeMultiplier: startingMarketSizeMultiplier
        )
        let marketSizeEndingProfit = expectedDailyProfit(
            product: product,
            demandMultiplier: initialDemandMultiplier,
            marketSizeMultiplier: endingMarketSizeMultiplier
        )
        let marketSizeBenefit = max(
            0,
            marketSizeEndingProfit - marketSizeStartingProfit
        )

        let initialCapacity = ProductionCapacityBalance.baseCapacity(
            baseIdealUnitsSold: product.idealUnitsSold
        )
            + ProductionCapacityBalance.expectedCapacityIncrease(
                baseIdealUnitsSold: product.idealUnitsSold,
                tierLevel: precedingLevel
            )
        let newCapacity: Int
        switch capacityEffect {
        case .none:
            newCapacity = initialCapacity
        case .additive(let addedCapacity):
            assert(addedCapacity >= 0)
            newCapacity = initialCapacity + addedCapacity
        case .replacement(let totalCapacity):
            assert(totalCapacity >= initialCapacity)
            newCapacity = totalCapacity
        }

        let addedCapacity = newCapacity - initialCapacity
        let expectedPricePerUnit = product.baseIdealPrice
            * initialDemandMultiplier
        let ingredientCostPerUnit = product.baseIdealPrice
            * ingredientCostRatio
        let capacityBenefit = Double(addedCapacity)
            * (expectedPricePerUnit - ingredientCostPerUnit)

        return demandBenefit + marketSizeBenefit + capacityBenefit
    }

    /// Converts an upgrade's independently calculated daily benefit into its
    /// purchase price or recurring payment. Recurring payments use a linear
    /// multiplier that begins above immediate benefit for untiered/cumulative
    /// purchases and falls as less future growth remains in later tiers.
    static func calculatePrice(
        dailyBenefit: Double,
        paymentSchedule: PaymentSchedule,
        tierLevel: Int
    ) -> Double {
        assert(dailyBenefit >= 0)
        assert((1...totalUpgradeTiers).contains(tierLevel))

        switch paymentSchedule {
        case .oneTime:
            return dailyBenefit * targetPaybackDays

        case .daily:
            return dailyBenefit * recurringBenefitMultiplier(
                tierLevel: tierLevel
            )

        case .weekly:
            return dailyBenefit
                * businessDaysPerWeek
                * recurringBenefitMultiplier(tierLevel: tierLevel)
        }
    }

    static func recurringBenefitMultiplier(
        tierLevel: Int
    ) -> Double {
        assert((1...totalUpgradeTiers).contains(tierLevel))

        let tierProgress = Double(tierLevel - 1)
            / Double(totalUpgradeTiers - 1)

        return maximumRecurringBenefitMultiplier
            - tierProgress * (
                maximumRecurringBenefitMultiplier
                    - minimumRecurringBenefitMultiplier
            )
    }

    private static func expectedDailyProfit(
        product: Product,
        demandMultiplier: Double,
        marketSizeMultiplier: Double
    ) -> Double {
        let expectedSales = Double(product.idealUnitsSold)
            * marketSizeMultiplier
        let expectedPrice = product.baseIdealPrice * demandMultiplier
        let ingredientCostPerUnit = product.baseIdealPrice
            * ingredientCostRatio

        return expectedSales
            * (expectedPrice - ingredientCostPerUnit)
    }

}
