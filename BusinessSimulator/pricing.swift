//
//  pricing.swift
//  BusinessSimulator
//

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

    // TODO: Adjust tier pricing for the demand and market-size multipliers
    // associated with the location active when the upgrade becomes available.
    static func setPrice(
        demandLevel: Int,
        marketSizeLevel: Int,
        totalLevels: Int,
        tierLevel: Int,
        totalTiers: Int,
        demandWeight: Double,
        marketSizeWeight: Double
    ) -> Double {
        assert(totalLevels > 0)
        assert(totalTiers > 1)
        assert((1...totalTiers).contains(tierLevel))
        assert((0...totalLevels).contains(demandLevel))
        assert((0...totalLevels).contains(marketSizeLevel))
        assert((0...1).contains(demandWeight))
        assert((0...1).contains(marketSizeWeight))

        // What is the expected value of demand and marketSize before this addition was purchased
        let precedingEffectScore =
            Double(tierLevel - 1) / Double(totalTiers - 1)

        // effect on revenue of demand before new purchase
        let precedingDemandMultiplier = SimulationBalance.demand.multiplier(
            weight: 1.0,
            effectScore: precedingEffectScore
        )
        //effect on revenue of market size before new purchase
        let precedingMarketSizeMultiplier = SimulationBalance.marketSize.multiplier(
            weight: 1.0,
            effectScore: precedingEffectScore
        )

        // difference in demand due to new purchase
        let demandEffectScore = Double(demandLevel) / Double(totalLevels)
        
        // difference in market size due to new purchase
        let marketSizeEffectScore = Double(marketSizeLevel) / Double(totalLevels)

        // change in demand multiplier due to new purhase
        let upgradedDemandEffectScore = precedingEffectScore
            + demandWeight * (demandEffectScore - precedingEffectScore)

        // change in market size multilier due to new purhase
        let upgradedMarketSizeEffectScore = precedingEffectScore
            + marketSizeWeight * (marketSizeEffectScore - precedingEffectScore)

        //change in revenue due to demand for new purchase
        let upgradedDemandMultiplier = SimulationBalance.demand.multiplier(
            weight: 1.0,
            effectScore: upgradedDemandEffectScore
        )
        //change in revenuw due to market size for new purchase
        let upgradedMarketSizeMultiplier = SimulationBalance.marketSize.multiplier(
            weight: 1.0,
            effectScore: upgradedMarketSizeEffectScore
        )

        // profict before
        let precedingProfit = expectedProfit(
            demandMultiplier: precedingDemandMultiplier,
            marketSizeMultiplier: precedingMarketSizeMultiplier
        )
        //profit after
        let upgradedProfit = expectedProfit(
            demandMultiplier: upgradedDemandMultiplier,
            marketSizeMultiplier: upgradedMarketSizeMultiplier
        )

        //given change in profit the expected extra money after n days
        return max(0, upgradedProfit - precedingProfit) * targetPaybackDays
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
}
