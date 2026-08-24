//
//  pricing.swift
//  BusinessSimulator
//

struct PricingState {
    let demandMultiplier: Double
    let marketSizeMultiplier: Double
}

/// Estimates upgrade prices from the maximum benefit an upgrade is expected to provide.
/// These calculations are balancing guidelines rather than exact valuations; final prices
/// will be refined through testing. Keeping the pricing model centralized provides a
/// consistent starting point and makes it easy to adjust related prices together.
enum UpgradePricing {

    // Approximate starting ideal daily revenue shared by all products:
    // pies: $12.80 * 38 = $486.40
    // smoothies: $3.40 * 141 = $479.40
    // hot dogs: $3.20 * 150 = $480.00
    static let baseIdealRevenue = 480.00

    // Ingredient cost is approximately 5/12 of a product's starting ideal price.
    static let ingredientCostRatio = 5.0 / 12.0
    static let baseIdealProfit = baseIdealRevenue * (1.0 - ingredientCostRatio)

    static let targetPaybackDays = 12.0
    static let businessDaysPerWeek = 5.0
    static let maximumScheduledProfitShare = 0.90
    static let minimumScheduledProfitShare = 0.60

    // TODO: Adjust tier pricing for the demand and market-size multipliers
    // associated with the location active when the upgrade becomes available.
    static func setPrice(
        tierLevel: Int,
        totalTiers: Int,
        precedingDemandWeight: Double,
        precedingMarketSizeWeight: Double,
        demandLevelChange: Int,
        marketSizeLevelChange: Int,
        totalLevels: Int,
        demandWeight: Double,
        marketSizeWeight: Double,
        paymentSchedule: PaymentSchedule
    ) -> Double {
        assert(totalLevels > 0)
        assert(totalTiers > 1)
        assert((1...totalTiers).contains(tierLevel))
        assert((-totalLevels...totalLevels).contains(demandLevelChange))
        assert((-totalLevels...totalLevels).contains(marketSizeLevelChange))
        assert((0...1).contains(precedingDemandWeight))
        assert((0...1).contains(precedingMarketSizeWeight))
        assert((0...1).contains(demandWeight))
        assert((0...1).contains(marketSizeWeight))

        let precedingState = findPrecedingState(
            tierLevel: tierLevel,
            totalTiers: totalTiers,
            demandWeight: precedingDemandWeight,
            marketSizeWeight: precedingMarketSizeWeight
        )
        let upgradedState = findUpgradedState(
            precedingState: precedingState,
            demandLevelChange: demandLevelChange,
            marketSizeLevelChange: marketSizeLevelChange,
            totalLevels: totalLevels,
            demandWeight: demandWeight,
            marketSizeWeight: marketSizeWeight
        )

        let precedingProfit = expectedProfit(
            demandMultiplier: precedingState.demandMultiplier,
            marketSizeMultiplier: precedingState.marketSizeMultiplier
        )
        let upgradedProfit = expectedProfit(
            demandMultiplier: upgradedState.demandMultiplier,
            marketSizeMultiplier: upgradedState.marketSizeMultiplier
        )

        let additionalDailyProfit = max(
            0,
            upgradedProfit - precedingProfit
        )

        return findPricePerPayment(
            additionalDailyProfit: additionalDailyProfit,
            paymentSchedule: paymentSchedule,
            tierLevel: tierLevel,
            totalTiers: totalTiers
        )
    }

    static func setCapacityPrice() -> Double {
        // TODO: Calculate the additional profit enabled by increased capacity
        // once equipment, labor, and their capacity constraints are implemented.
        return 0
    }

    private static func expectedProfit(
        demandMultiplier: Double,
        marketSizeMultiplier: Double
    ) -> Double {
        //demand and market size increase revenue
        let revenue = baseIdealRevenue
            * demandMultiplier
            * marketSizeMultiplier

        //market size increases production which increases ingredient cost proportionally
        let ingredientCost = baseIdealRevenue
            * ingredientCostRatio
            * marketSizeMultiplier

        return revenue - ingredientCost
    }

    /// Determines the representative business state before a purchase so its value
    /// can be compared with the projected state after the purchase.
    ///
    /// Cases:
    ///   Case 1: For One-time payment schedule where the preceding item is replaced
    ///    by the new item (like equipment) use the preceding level because the earlier
    ///   payment is complete, so only the new item's incremental value is priced.
    ///  So demandWeight/marketSizeWeight for preceding State include the entire business
    ///   so they would be 1.0
    ///
    ///   Case 2: For scheduled payments (weekly or daily) where one item is being
    ///   replaced by the new item (like with advertising) remove the current factor
    ///   because its recurring payment stops, so the demandWeight/marketSizeWeight for preceding State
    ///   would not include the factor being replaced. The new factors price has to include its own
    ///  impact as well as the impact of its precendent since the precedent payment will stop.
    ///   Therefore demandWeight/marketSizeWeight will be 1 - the factors portion of the weight
    ///
    ///   Case 3: For scheduled payments (weekly or daily) where the newly purchase item
    ///   will be added and the previous item will remain (like labor), the price 
    ///   of the newly purchased item should only cover the added revenue if
    ///   the newly purchased item. So it would be the exact case of Case 1 above and
    ///   demandWeight/marketSizeWeight for preceding State would include the entire business
    ///   so they would be 1.0
    static func findPrecedingState(
        tierLevel: Int,
        totalTiers: Int,
        demandWeight: Double,
        marketSizeWeight: Double
    ) -> PricingState {
        let expectedLevel = tierLevel - 1
        let expectedEffectScore =
            Double(expectedLevel) / Double(totalTiers)

        let demandMultiplier = SimulationBalance.demand.multiplier(
            weight: demandWeight,
            effectScore: expectedEffectScore
        )
        let marketSizeMultiplier = SimulationBalance.marketSize.multiplier(
            weight: marketSizeWeight,
            effectScore: expectedEffectScore
        )

        return PricingState(
            demandMultiplier: demandMultiplier,
            marketSizeMultiplier: marketSizeMultiplier
        )
    }

    /// Determines the representative business state after a purchase so its value
    /// can be compared with the state before the purchase.
    ///
    /// Cases:
    ///   Case 1: For a one-time payment where the preceding item is replaced by the
    ///   new item (like equipment), demandLevelChange/marketSizeLevelChange should be
    ///   the new item's level minus the preceding item's level. This prices only the
    ///   incremental value added by the new item.
    ///
    ///   Case 2: For a scheduled payment where the preceding item is replaced by the
    ///   new item (like advertising), the preceding factor was removed when finding
    ///   the preceding state. Therefore demandLevelChange/marketSizeLevelChange should
    ///   include the new item's entire level so its payment covers the factor's total
    ///   active value.
    ///
    ///   Case 3: For a scheduled payment where the new item is added and the previous
    ///   items remain (like labor), demandLevelChange/marketSizeLevelChange should be
    ///   only the new item's individual contribution. The previous items' effects and
    ///   payments are already included in the preceding state.
    static func findUpgradedState(
        precedingState: PricingState,
        demandLevelChange: Int,
        marketSizeLevelChange: Int,
        totalLevels: Int,
        demandWeight: Double,
        marketSizeWeight: Double
    ) -> PricingState {
        let demandEffectScore =
            Double(demandLevelChange) / Double(totalLevels)
        let marketSizeEffectScore =
            Double(marketSizeLevelChange) / Double(totalLevels)

        let purchasedDemandMultiplier =
            SimulationBalance.demand.multiplier(
                weight: demandWeight,
                effectScore: demandEffectScore
            )
        let purchasedMarketSizeMultiplier =
            SimulationBalance.marketSize.multiplier(
                weight: marketSizeWeight,
                effectScore: marketSizeEffectScore
            )

        return PricingState(
            demandMultiplier: precedingState.demandMultiplier
                * purchasedDemandMultiplier,
            marketSizeMultiplier: precedingState.marketSizeMultiplier
                * purchasedMarketSizeMultiplier
        )
    }

    /// Converts an item's total economic value into the amount due per payment.
    /// One-time purchases are priced at 12 days of added profit. Scheduled payments
    /// capture a larger portion of projected profit in early tiers because the item
    /// becomes more valuable as the business grows. The scheduled share decreases
    /// from 90% in tier one to 60% in the final tier, where less future growth remains.
    /// Daily payments use one day's added profit, while weekly payments use five days.
    static func findPricePerPayment(
        additionalDailyProfit: Double,
        paymentSchedule: PaymentSchedule,
        tierLevel: Int,
        totalTiers: Int
    ) -> Double {
        let tierProgress =
            Double(tierLevel - 1) / Double(totalTiers - 1)
        let scheduledProfitShare = maximumScheduledProfitShare
            - tierProgress * (
                maximumScheduledProfitShare
                    - minimumScheduledProfitShare
            )

        switch paymentSchedule {
        case .oneTime:
            return additionalDailyProfit * targetPaybackDays
        case .daily:
            return additionalDailyProfit * scheduledProfitShare
        case .weekly:
            return additionalDailyProfit
                * businessDaysPerWeek
                * scheduledProfitShare
        }
    }
}
