import Foundation
import Observation

struct LocationID: RawRepresentable, Hashable, Codable {
    let rawValue: String
}

struct LocationTierID: RawRepresentable, Hashable, Codable {
    let rawValue: String
}

enum LocationTierLevel: Int, Codable, Comparable {
    case tierOne = 1
    case tierTwo = 2

    static func < (
        lhs: LocationTierLevel,
        rhs: LocationTierLevel
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var demandMultiplier: Double {
        switch self {
        case .tierOne:
            return 1.0
        case .tierTwo:
            return 1.3
        }
    }

    /// Representative market size used to price upgrades that become
    /// available in this location tier. This is a balancing estimate, not the
    /// player's actual market-size multiplier.
    var pricingMarketSizeMultiplier: Double {
        switch self {
        case .tierOne:
            return 1.0
        case .tierTwo:
            return 1.5
        }
    }
}

/// Static catalog data describing one place where the business can operate.
struct Location: Identifiable, Equatable {
    let id: LocationID
    let name: String
    let description: String

    init(
        id: LocationID,
        name: String,
        description: String
    ) {
        self.id = id
        self.name = name
        self.description = description
    }
}

struct LocationTier: Identifiable, Equatable {
    let id: LocationTierID
    let level: LocationTierLevel
    let locations: [Location]

    /// The immediate demand adjustment shared by every location in this tier.
    /// Market-size growth is provided by the upgrades unlocked at the tier,
    /// rather than by the locations themselves.
    var demandMultiplier: Double {
        level.demandMultiplier
    }

    init(
        id: LocationTierID,
        level: LocationTierLevel,
        locations: [Location]
    ) {
        assert(
            !locations.isEmpty,
            "A location tier must contain at least one location."
        )

        let locationIDs = locations.map(\.id)
        assert(
            Set(locationIDs).count == locationIDs.count,
            "A location tier cannot contain duplicate locations."
        )

        self.id = id
        self.level = level
        self.locations = locations
    }
}

@Observable
final class LocationState {
    let tiers: [LocationTier]
    private(set) var activeLocationID: LocationID

    var locations: [Location] {
        tiers.flatMap(\.locations)
    }

    var activeLocation: Location {
        guard let location = locations.first(
            where: { $0.id == activeLocationID }
        ) else {
            preconditionFailure(
                "The active location must belong to LocationState."
            )
        }

        return location
    }

    var activeTier: LocationTier {
        guard let tier = tiers.first(
            where: { tier in
                tier.locations.contains {
                    $0.id == activeLocationID
                }
            }
        ) else {
            preconditionFailure(
                "The active location must belong to a location tier."
            )
        }

        return tier
    }

    init(
        tiers: [LocationTier],
        activeLocationID: LocationID
    ) {
        assert(
            !tiers.isEmpty,
            "LocationState must contain at least one location tier."
        )

        let tierIDs = tiers.map(\.id)
        assert(
            Set(tierIDs).count == tierIDs.count,
            "LocationState cannot contain duplicate location tiers."
        )

        let tierLevels = tiers.map(\.level)
        assert(
            Set(tierLevels).count == tierLevels.count,
            "LocationState cannot contain duplicate location tier levels."
        )

        let locationIDs = tiers.flatMap(\.locations).map(\.id)
        assert(
            Set(locationIDs).count == locationIDs.count,
            "LocationState cannot contain duplicate locations."
        )
        assert(
            locationIDs.contains(activeLocationID),
            "The active location must belong to LocationState."
        )

        self.tiers = tiers
        self.activeLocationID = activeLocationID
    }

    func relocate(
        to locationID: LocationID
    ) {
        guard locations.contains(where: { $0.id == locationID }) else {
            preconditionFailure(
                "A business cannot relocate to a location outside its catalog."
            )
        }

        activeLocationID = locationID
    }
}

/// Applies the active location's immediate demand benefit. Location does not
/// directly add market size or operating costs; those Dimension requirements
/// use their neutral default implementations.
final class LocationDimension: Dimension {
    private let locationState: LocationState

    init(
        locationState: LocationState
    ) {
        self.locationState = locationState
    }

    func calculateDemand() -> Double {
        locationState.activeTier.demandMultiplier
    }
}
