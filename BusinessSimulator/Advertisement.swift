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
    let price: Double
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

    init(
        id: AdvertisementID,
        name: String,
        smallIcon: GameIcon,
        description: String,
        price: Double,
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
    let id: AdvertisementTierID
    let level: Int
    let productID: ProductID?
    let advertisements: [Advertisement]

    init(
        id: AdvertisementTierID,
        level: Int,
        productID: ProductID? = nil,
        advertisements: [Advertisement]
    ) {
        assert(level > 0, "Advertisement tier level must be positive.")
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
        self.productID = productID
        self.advertisements = advertisements
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
