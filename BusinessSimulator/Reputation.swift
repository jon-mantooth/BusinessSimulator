//
//  Reputation.swift
//  BusinessSimulator
//

import Foundation
import Observation

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

    private(set) var overallReputation: Double
    private(set) var hasRatings: Bool

    /// Converts the internal 0...100 reputation into a 1...5 star rating.
    var starRating: Double {
        1.0 + (overallReputation / 100.0 * 4.0)
    }

    init(
        overallReputation: Double = neutralReputation,
        hasRatings: Bool = false
    ) {
        assert(
            Self.minimumReputation...Self.maximumReputation
                ~= overallReputation,
            "Reputation must be between 0 and 100."
        )

        self.overallReputation = overallReputation
        self.hasRatings = hasRatings
    }

    /// Calculates the price score and combines all three factors into the
    /// day's 0...100 reputation.
    func calculateDailyReputation(
        price: Double,
        idealPrice: Double,
        availabilityEffectScore: Double,
        freshnessEffectScore: Double
    ) -> Double {
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

        assert(
            Self.isNormalized(priceEffectScore)
                && Self.isNormalized(availabilityEffectScore)
                && Self.isNormalized(freshnessEffectScore),
            "Reputation effect scores must be between 0 and 1."
        )

        return 100.0 * (
            priceEffectScore * Self.priceWeight
            + availabilityEffectScore * Self.availabilityWeight
            + freshnessEffectScore * Self.freshnessWeight
        )
    }

    /// Gives full credit at or below the ideal price, then applies an
    /// increasingly strong penalty until the score reaches zero at 50% above
    /// the ideal price.
    private func calculatePriceEffectScore(
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
        dailyReputation: Double
    ) {
        let adjustmentRate = dailyReputation >= overallReputation
            ? Self.positiveAdjustmentRate
            : Self.negativeAdjustmentRate

        overallReputation += adjustmentRate * (
            dailyReputation - overallReputation
        )
        hasRatings = true
    }

    private static func isNormalized(
        _ score: Double
    ) -> Bool {
        0.0...1.0 ~= score
    }
}
