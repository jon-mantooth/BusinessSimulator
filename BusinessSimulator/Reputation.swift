//
//  Reputation.swift
//  BusinessSimulator
//

import Foundation
import Observation

struct BusinessReputationComment {
    let title: String
    let comments: [String]
}

enum ReputationFactor {
    case price
    case availability
    case freshness
    case overall
}

enum ReputationSentiment {
    case negative
    case neutral
    case positive
}

struct ReputationFactorScores: Codable {
    let priceScore: Double
    let availabilityScore: Double
    let freshnessScore: Double
}

struct DailyReputationResult: Codable {
    let factorScores: ReputationFactorScores
    let overallScore: Double
}

enum ReputationTrend {
    case unavailable
    case declining
    case stable
    case improving
}

/// Stores the business's current reputation and updates it from each day's
/// pricing, availability, and freshness results.
@Observable
final class BusinessReputationState {
    static let minimumReputation = 0.0
    static let neutralReputation = 75.0
    static let maximumReputation = 100.0

    static let priceWeight = 0.40
    static let availabilityWeight = 0.35
    static let freshnessWeight = 0.25

    private static let positiveAdjustmentRate = 0.20
    private static let negativeAdjustmentRate = 0.10
    private static let recentReputationCapacity = 5
    private static let stableTrendThreshold = 0.5

    private(set) var overallReputation: Double
    private(set) var overallFactorScores: ReputationFactorScores
    private(set) var recentOverallReputations: [Double]
    private(set) var hasRatings: Bool

    /// Converts the internal 0...100 reputation into a 1...5 star rating.
    var starRating: Double {
        1.0 + (overallReputation / 100.0 * 4.0)
    }

    var trend: ReputationTrend {
        guard recentOverallReputations.count == Self.recentReputationCapacity
        else {
            return .unavailable
        }

        let overallReputationChanges = zip(
            recentOverallReputations.dropFirst(),
            recentOverallReputations
        ).map { (newerScore, olderScore) in
            newerScore - olderScore
        }

        var weightedChange = 0.0
        var totalWeight = 0.0

        for (index, reputationChange) in overallReputationChanges.enumerated() {
            let weight = 1.0 + Double(index) * 0.1
            weightedChange += reputationChange * weight
            totalWeight += weight
        }

        let averageWeightedChange = weightedChange / totalWeight

        if abs(averageWeightedChange) < Self.stableTrendThreshold {
            return .stable
        }

        return averageWeightedChange > 0 ? .improving : .declining
    }

    init(
        overallReputation: Double = neutralReputation,
        overallFactorScores: ReputationFactorScores? = nil,
        recentOverallReputations: [Double] = [],
        hasRatings: Bool = false
    ) {
        assert(
            Self.minimumReputation...Self.maximumReputation
                ~= overallReputation,
            "Reputation must be between 0 and 100."
        )

        self.overallReputation = overallReputation
        self.overallFactorScores = overallFactorScores
            ?? ReputationFactorScores(
                priceScore: overallReputation,
                availabilityScore: overallReputation,
                freshnessScore: overallReputation
            )
        self.recentOverallReputations = Array(
            recentOverallReputations.suffix(Self.recentReputationCapacity)
        )
        self.hasRatings = hasRatings
    }

    /// Calculates the price score and combines all three factors into the
    /// day's 0...100 reputation.
    func calculateDailyReputation(
        price: Double,
        idealPrice: Double,
        demandFulfillmentRate: Double,
        productInventories: [ProductInventory],
        inventoryStates: [InventoryState]
    ) -> DailyReputationResult {
        let factorWeights = [
            Self.priceWeight,
            Self.availabilityWeight,
            Self.freshnessWeight
        ]

        assert(
            factorWeights.allSatisfy { $0 >= 0 },
            "Reputation factor weights cannot be negative."
        )
        assert(
            abs(factorWeights.reduce(0, +) - 1.0) < 0.000_001,
            "Reputation factor weights must add up to 1."
        )

        let priceEffectScore = calculatePriceEffectScore(
            price: price,
            idealPrice: idealPrice
        )
        let availabilityEffectScore = calculateAvailabilityEffectScore(
            demandFulfillmentRate: demandFulfillmentRate
        )
        let freshnessEffectScore = calculateFreshnessEffectScore(
            productInventories: productInventories,
            inventoryStates: inventoryStates
        )

        assert(
            Self.isNormalized(priceEffectScore)
                && Self.isNormalized(availabilityEffectScore)
                && Self.isNormalized(freshnessEffectScore),
            "Reputation effect scores must be between 0 and 1."
        )

        let priceScore = priceEffectScore * 100.0
        let availabilityScore = availabilityEffectScore * 100.0
        let freshnessScore = freshnessEffectScore * 100.0

        let overallScore =
            priceScore * Self.priceWeight
            + availabilityScore * Self.availabilityWeight
            + freshnessScore * Self.freshnessWeight

        return DailyReputationResult(
            factorScores: ReputationFactorScores(
                priceScore: priceScore,
                availabilityScore: availabilityScore,
                freshnessScore: freshnessScore
            ),
            overallScore: overallScore
        )
    }

    func calculateAvailabilityEffectScore(
        demandFulfillmentRate: Double
    ) -> Double {
        demandFulfillmentRate
    }

    // TODO: For now, recalculate freshness here rather than storing derived
    // freshness state. Revisit whether this can safely reuse freshness already
    // calculated by InventoryDimension without creating stale state.
    func calculateFreshnessEffectScore(
        productInventories: [ProductInventory],
        inventoryStates: [InventoryState]
    ) -> Double {
        var largestWeightedFreshnessPenalty = 0.0

        for productInventory in productInventories {
            guard productInventory.freshnessCoefficient > 0 else {
                continue
            }

            guard let inventoryState = inventoryStates.first(
                where: {
                    $0.inventory.id == productInventory.inventory.id
                }
            ) else {
                assertionFailure(
                    "No inventory state exists for \(productInventory.inventory.name)."
                )
                continue
            }

            let freshness = inventoryState.inventoryByAge
                .calculateFreshness(
                    lifespan: inventoryState.inventory.lifespan
                )
            let weightedFreshnessPenalty =
                (1.0 - freshness)
                * productInventory.freshnessCoefficient

            largestWeightedFreshnessPenalty = max(
                largestWeightedFreshnessPenalty,
                weightedFreshnessPenalty
            )
        }

        return 1.0 - largestWeightedFreshnessPenalty
    }

    /// Gives full credit at or below the ideal price, then applies an
    /// increasingly strong penalty until the score reaches zero at 50% above
    /// the ideal price.
    func calculatePriceEffectScore(
        price: Double,
        idealPrice: Double
    ) -> Double {
        guard price > idealPrice else {
            return 1.0
        }

        let overpricing = price / idealPrice - 1.0
        let effectScore = 1.0 - pow(overpricing / 0.50, 2)

        return max(0.0, effectScore)
    }

    /// Moves reputation toward the daily result. Positive days adjust 20% of
    /// the difference while negative days adjust 10% of the difference.
    func updateOverallReputation(
        dailyReputationResult: DailyReputationResult
    ) {
        overallReputation = Self.updatedScore(
            currentScore: overallReputation,
            dailyScore: dailyReputationResult.overallScore
        )

        overallFactorScores = ReputationFactorScores(
            priceScore: Self.updatedScore(
                currentScore: overallFactorScores.priceScore,
                dailyScore: dailyReputationResult.factorScores.priceScore
            ),
            availabilityScore: Self.updatedScore(
                currentScore: overallFactorScores.availabilityScore,
                dailyScore:
                    dailyReputationResult.factorScores.availabilityScore
            ),
            freshnessScore: Self.updatedScore(
                currentScore: overallFactorScores.freshnessScore,
                dailyScore:
                    dailyReputationResult.factorScores.freshnessScore
            )
        )

        recentOverallReputations.append(overallReputation)
        if recentOverallReputations.count > Self.recentReputationCapacity {
            recentOverallReputations.removeFirst()
        }

        hasRatings = true
    }

    private static func updatedScore(
        currentScore: Double,
        dailyScore: Double
    ) -> Double {
        let adjustmentRate = dailyScore >= currentScore
            ? positiveAdjustmentRate
            : negativeAdjustmentRate

        return currentScore + adjustmentRate * (
            dailyScore - currentScore
        )
    }

    private static func isNormalized(
        _ score: Double
    ) -> Bool {
        0.0...1.0 ~= score
    }
}

/// Converts the business's current reputation into demand and market-size
/// multipliers. Reputation is neutral at 75 and reaches its full positive
/// effect at 100.
final class BusinessReputationDimension: Dimension {
    static let demandWeight = 0.35
    static let marketSizeWeight = 0.15

    private let reputation: BusinessReputationState

    init(
        reputation: BusinessReputationState
    ) {
        self.reputation = reputation
    }

    func calculateDemand() -> Double {
        SimulationBalance.demand.multiplier(
            weight: Self.demandWeight,
            effectScore: reputationEffectScore
        )
    }

    func calculateMarketSize() -> Double {
        SimulationBalance.marketSize.multiplier(
            weight: Self.marketSizeWeight,
            effectScore: reputationEffectScore
        )
    }

    private var reputationEffectScore: Double {
        let reputationScore = reputation.overallReputation
        let neutralReputation =
            BusinessReputationState.neutralReputation

        if reputationScore >= neutralReputation {
            let positiveReputationRange =
                BusinessReputationState.maximumReputation
                - neutralReputation

            let effectScore =
                (reputationScore - neutralReputation)
                / positiveReputationRange

            assert(
                0.0...1.0 ~= effectScore,
                "Positive reputation effect score must be between 0 and 1."
            )

            return effectScore
        }

        let negativeReputationRange =
            neutralReputation
            - BusinessReputationState.minimumReputation
        let effectScore =
            (reputationScore - neutralReputation)
            / negativeReputationRange

        assert(
            -1.0...0.0 ~= effectScore,
            "Negative reputation effect score must be between -1 and 0."
        )

        return effectScore
    }
}
