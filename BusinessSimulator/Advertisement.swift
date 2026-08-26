import Foundation
import Observation

struct AdvertisementID: RawRepresentable, Hashable, Codable {
    let rawValue: String
}

struct AdvertisementTierID: RawRepresentable, Hashable, Codable {
    let rawValue: String
}

struct Advertisement: Identifiable, Equatable {
    let id: AdvertisementID
    let name: String
    let smallIcon: GameIcon
    let description: String
    var price: Double
    let paymentSchedule: PaymentSchedule
    let demandLevel: Int
    let marketSizeLevel: Int
    let totalLevels: Int
    let dailyTimeRequired: Double

    var demandEffectScore: Double {
        Double(demandLevel) / Double(totalLevels)
    }

    var marketSizeEffectScore: Double {
        Double(marketSizeLevel) / Double(totalLevels)
    }

    static func cleanPrice(
        _ calculatedPrice: Double
    ) -> Double {
        let roundingIncrement: Double

        switch calculatedPrice {
        case ..<100:
            roundingIncrement = 5
        case ..<1_000:
            roundingIncrement = 25
        case ..<5_000:
            roundingIncrement = 50
        default:
            roundingIncrement = 100
        }

        return (
            calculatedPrice / roundingIncrement
        ).rounded() * roundingIncrement
    }

    init(
        id: AdvertisementID,
        name: String,
        smallIcon: GameIcon,
        description: String,
        price: Double = 0.00,
        paymentSchedule: PaymentSchedule,
        demandLevel: Int,
        marketSizeLevel: Int,
        totalLevels: Int = 5,
        dailyTimeRequired: Double = 0
    ) {
        assert(price >= 0, "Advertisement price cannot be negative.")
        assert(
            dailyTimeRequired >= 0,
            "Advertisement daily time requirement cannot be negative."
        )
        assert(totalLevels > 0, "Advertisement total levels must be positive.")
        assert(
            demandLevel >= 0 && marketSizeLevel >= 0,
            "Advertisement effect levels cannot be negative."
        )
        assert(
            totalLevels >= demandLevel && totalLevels >= marketSizeLevel,
            "Advertisement effect levels cannot exceed total levels."
        )

        self.id = id
        self.name = name
        self.smallIcon = smallIcon
        self.description = description
        self.price = price
        self.paymentSchedule = paymentSchedule
        self.demandLevel = demandLevel
        self.marketSizeLevel = marketSizeLevel
        self.totalLevels = totalLevels
        self.dailyTimeRequired = dailyTimeRequired
    }
}

struct AdvertisementTier: Identifiable, Equatable {
    private static let totalTiers = 5

    let id: AdvertisementTierID
    let level: Int
    let advertisements: [Advertisement]

    init(
        id: AdvertisementTierID,
        level: Int,
        advertisements: [Advertisement]
    ) {
        assert(level >= 0, "Advertisement tier level cannot be negative.")
        assert(
            !advertisements.isEmpty,
            "An advertisement tier must contain at least one advertisement."
        )

        let advertisementIDs = advertisements.map(\.id)
        assert(
            Set(advertisementIDs).count == advertisementIDs.count,
            "An advertisement tier cannot contain duplicate advertisements."
        )

        self.id = id
        self.level = level
        self.advertisements = level == 0
            ? advertisements
            : Self.setPrices(
                advertisements,
                tierLevel: level
            )
    }

    private static func setPrices(
        _ advertisements: [Advertisement],
        tierLevel: Int
    ) -> [Advertisement] {
        advertisements.map { advertisement in
            var pricedAdvertisement = advertisement

            if advertisement.dailyTimeRequired > 0 {
                pricedAdvertisement.price = 0.0
                return pricedAdvertisement
            }

            let isOneTime = advertisement.paymentSchedule == .oneTime
            let precedingLevel = tierLevel - 1

            let paymentPrice = UpgradePricing.setPrice(
                tierLevel: tierLevel,
                totalTiers: Self.totalTiers,
                precedingDemandWeight: isOneTime
                    ? 1.0
                    : 1.0 - AdvertisementDimension.demandWeight,
                precedingMarketSizeWeight: isOneTime
                    ? 1.0
                    : 1.0 - AdvertisementDimension.marketSizeWeight,
                demandLevelChange: isOneTime
                    ? advertisement.demandLevel - precedingLevel
                    : advertisement.demandLevel,
                marketSizeLevelChange: isOneTime
                    ? advertisement.marketSizeLevel - precedingLevel
                    : advertisement.marketSizeLevel,
                totalLevels: advertisement.totalLevels,
                demandWeight: AdvertisementDimension.demandWeight,
                marketSizeWeight: AdvertisementDimension.marketSizeWeight,
                paymentSchedule: advertisement.paymentSchedule
            )
            pricedAdvertisement.price = Advertisement.cleanPrice(
                paymentPrice
            )

            return pricedAdvertisement
        }
    }
}

final class AdvertisementDimension: Dimension {
    // Advertisement's portion of permanent demand and market-size growth.
    // All permanent dimension weights for each simulation factor must total 1.0.
    static let demandWeight = 0.10
    static let marketSizeWeight = 0.40

    private let advertisementState: AdvertisementState
    private let businessHours: BusinessHours

    init(
        advertisementState: AdvertisementState,
        businessHours: BusinessHours
    ) {
        self.advertisementState = advertisementState
        self.businessHours = businessHours
    }

    func calculateDemand() -> Double {
        let effectScore = advertisementState.activeAdvertisement?
            .demandEffectScore ?? 0.0

        return SimulationBalance.demand.multiplier(
            weight: Self.demandWeight,
            effectScore: effectScore
        )
    }

    func calculateMarketSize() -> Double {
        let activeAdvertisement = advertisementState.activeAdvertisement
        let effectScore = activeAdvertisement?.marketSizeEffectScore ?? 0.0
        let advertisementMultiplier = SimulationBalance.marketSize.multiplier(
            weight: Self.marketSizeWeight,
            effectScore: effectScore
        )

        // Time spent advertising is time the player cannot spend selling, so reduce
        // the entire reachable market by the portion of the business day that remains.
        let operatingHours = Double(
            businessHours.closingTime.totalMinutes
                - businessHours.openingTime.totalMinutes
        ) / 60.0
        let dailyTimeRequired = activeAdvertisement?.dailyTimeRequired ?? 0.0
        let availableSellingTimeMultiplier =
            (operatingHours - dailyTimeRequired) / operatingHours

        return advertisementMultiplier * availableSellingTimeMultiplier
    }

    func calculateWeeklyCosts(
        summary: DaySummary
    ) -> Double {
        guard
            let activeAdvertisement = advertisementState.activeAdvertisement,
            activeAdvertisement.paymentSchedule == .weekly
        else {
            return 0.0
        }

        summary.cashFlowCosts.append(
            Cost(
                name: activeAdvertisement.name,
                amount: activeAdvertisement.price
            )
        )

        return activeAdvertisement.price
    }
}

@Observable
final class AdvertisementState {
    let tiers: [AdvertisementTier]
    private(set) var activeAdvertisementID: AdvertisementID?

    var activeAdvertisement: Advertisement? {
        tiers
            .flatMap(\.advertisements)
            .first(where: { $0.id == activeAdvertisementID })
    }

    var activeTier: AdvertisementTier? {
        tiers.first { tier in
            tier.advertisements.contains {
                $0.id == activeAdvertisementID
            }
        }
    }

    init(
        tiers: [AdvertisementTier],
        activeAdvertisementID: AdvertisementID? = nil
    ) {
        let tierIDs = tiers.map(\.id)
        assert(
            Set(tierIDs).count == tierIDs.count,
            "Advertisement state cannot contain duplicate tiers."
        )

        let tierLevels = tiers.map(\.level)
        assert(
            Set(tierLevels).count == tierLevels.count,
            "Advertisement state must contain only one tier per level."
        )

        if let activeAdvertisementID {
            assert(
                tiers.contains { tier in
                    tier.advertisements.contains {
                        $0.id == activeAdvertisementID
                    }
                },
                "The active advertisement must belong to this state."
            )
        }

        self.tiers = tiers.sorted { $0.level < $1.level }
        self.activeAdvertisementID = activeAdvertisementID
    }

    func activateAdvertisement(
        id: AdvertisementID
    ) {
        guard tiers.contains(where: { tier in
            tier.advertisements.contains { $0.id == id }
        }) else {
            preconditionFailure(
                "Cannot activate an advertisement outside this state."
            )
        }

        activeAdvertisementID = id
    }
}
