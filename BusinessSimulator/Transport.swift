import Foundation
import Observation

struct TransportID: RawRepresentable, Hashable, Codable {
    let rawValue: String
}

struct TransportTierID: RawRepresentable, Hashable {
    let rawValue: String
}

enum TransportTrack: String, CaseIterable, Codable {
    case primary
    case secondary
}

struct Transport: Identifiable, Equatable, Codable, PurchasableItem {
    let id: TransportID
    let name: String
    let smallIcon: GameIcon
    let description: String
    var price: Double

    var paymentSchedule: PaymentSchedule {
        .weekly
    }

    var purchaseItemID: String {
        id.rawValue
    }

    init(
        id: TransportID,
        name: String,
        smallIcon: GameIcon,
        description: String,
        price: Double = 0
    ) {
        assert(price >= 0, "Transport price cannot be negative.")

        self.id = id
        self.name = name
        self.smallIcon = smallIcon
        self.description = description
        self.price = price
    }

    static func cleanPrice(_ calculatedPrice: Double) -> Double {
        Advertisement.cleanPrice(calculatedPrice)
    }
}

struct TransportTier: Identifiable, Equatable {
    let id: TransportTierID
    let track: TransportTrack
    let level: Int
    let requiredLocationTier: LocationTierLevel
    let transport: Transport

    /// Cumulative progress supplied by this active item on its own track.
    var trackProgress: Double {
        switch track {
        case .primary:
            return 0.40 + Double(level - 1) * 0.15
        case .secondary:
            return Double(level) * 0.15
        }
    }

    /// Player-facing market-size rating. Primary Transport establishes the
    /// total base rating; Secondary Transport contributes additional stars.
    var marketSizeStars: Double {
        switch track {
        case .primary:
            return 2.5 + Double(level) * 0.5
        case .secondary:
            return Double(level) * 0.5
        }
    }

    init(
        id: TransportTierID,
        track: TransportTrack,
        level: Int,
        requiredLocationTier: LocationTierLevel,
        transport: Transport,
        product: Product
    ) {
        switch track {
        case .primary:
            assert(
                (1...3).contains(level),
                "Primary Transport tier must be 1 through 3."
            )
        case .secondary:
            assert(
                (1...2).contains(level),
                "Secondary Transport tier must be 1 through 2."
            )
        }

        var configuredTransport = transport
        let pricingTargetMultiplier: Double
        switch track {
        case .primary:
            pricingTargetMultiplier = 1.0
                + TransportState.locationTwoBaseIncrease
                + (0.40 + Double(level - 1) * 0.15)
        case .secondary:
            pricingTargetMultiplier = 1.0 + Double(level) * 0.15
        }

        let pricingLocation = LocationTierLevel.tierTwo
        let dailyBenefit = UpgradePricing.calculateDailyBenefit(
            tierLevel: level,
            product: product,
            locationDemandMultiplier: pricingLocation.demandMultiplier,
            representativeMarketSizeMultiplier:
                pricingLocation.pricingMarketSizeMultiplier,
            marketSizeEndingTargetMultiplier: pricingTargetMultiplier,
            marketSizeWeight: TransportDimension.marketSizeWeight
        )
        configuredTransport.price = Transport.cleanPrice(
            UpgradePricing.calculatePrice(
                dailyBenefit: dailyBenefit,
                paymentSchedule: configuredTransport.paymentSchedule,
                tierLevel: level
            )
        )

        self.id = id
        self.track = track
        self.level = level
        self.requiredLocationTier = requiredLocationTier
        self.transport = configuredTransport
    }
}

/// A purchased Transport item whose calculated price is preserved with the
/// save rather than recalculated when future balancing changes the catalog.
struct ActiveTransportItem: Identifiable, Equatable, Codable {
    let transport: Transport
    let tierLevel: Int

    var id: TransportID {
        transport.id
    }
}

struct ActiveTransport: Equatable, Codable {
    var primary: ActiveTransportItem?
    var secondary: ActiveTransportItem?

    init(
        primary: ActiveTransportItem? = nil,
        secondary: ActiveTransportItem? = nil
    ) {
        self.primary = primary
        self.secondary = secondary
    }

    var items: [ActiveTransportItem] {
        [primary, secondary].compactMap { $0 }
    }
}

struct TransportRollbackState {
    let activeTransport: ActiveTransport
}

@Observable
final class TransportState: PurchasableState {
    typealias PurchaseItem = Transport
    typealias RollbackState = TransportRollbackState

    static let locationTwoBaseIncrease = 1.00

    let tiers: [TransportTier]
    private(set) var activeTransport: ActiveTransport

    var dimensionID: PurchaseCategory {
        .transport
    }

    var primaryTiers: [TransportTier] {
        tiers.filter { $0.track == .primary }
    }

    var secondaryTiers: [TransportTier] {
        tiers.filter { $0.track == .secondary }
    }

    var activePrimaryTier: TransportTier? {
        tier(for: activeTransport.primary, on: .primary)
    }

    var activeSecondaryTier: TransportTier? {
        tier(for: activeTransport.secondary, on: .secondary)
    }

    var nextPrimaryTier: TransportTier? {
        let nextLevel = (activePrimaryTier?.level ?? 0) + 1
        return primaryTiers.first { $0.level == nextLevel }
    }

    var nextSecondaryTier: TransportTier? {
        guard activePrimaryTier != nil else { return nil }

        let nextLevel = (activeSecondaryTier?.level ?? 0) + 1
        return secondaryTiers.first { $0.level == nextLevel }
    }

    var nextTiers: [TransportTier] {
        guard activePrimaryTier != nil else {
            return nextPrimaryTier.map { [$0] } ?? []
        }

        return [nextPrimaryTier, nextSecondaryTier].compactMap { $0 }
    }

    var combinedTrackProgress: Double {
        (activePrimaryTier?.trackProgress ?? 0)
            + (activeSecondaryTier?.trackProgress ?? 0)
    }

    var totalMarketSizeStars: Double {
        (activePrimaryTier?.marketSizeStars ?? 0)
            + (activeSecondaryTier?.marketSizeStars ?? 0)
    }

    /// The first active primary tier carries the location-two base increase;
    /// every later primary or secondary tier adds its track progress.
    var marketSizeTargetMultiplier: Double {
        guard activePrimaryTier != nil else { return 1.0 }

        return 1.0
            + Self.locationTwoBaseIncrease
            + combinedTrackProgress
    }

    init(
        tiers: [TransportTier],
        activeTransport: ActiveTransport = ActiveTransport()
    ) {
        let tierIDs = tiers.map(\.id)
        assert(
            Set(tierIDs).count == tierIDs.count,
            "Transport state cannot contain duplicate tier IDs."
        )

        let transportIDs = tiers.map { $0.transport.id }
        assert(
            Set(transportIDs).count == transportIDs.count,
            "Transport state cannot contain duplicate item IDs."
        )

        let primaryLevels = tiers
            .filter { $0.track == .primary }
            .map(\.level)
        let secondaryLevels = tiers
            .filter { $0.track == .secondary }
            .map(\.level)
        assert(
            Set(primaryLevels) == Set(1...3),
            "Transport state requires primary tiers 1 through 3."
        )
        assert(
            Set(secondaryLevels) == Set(1...2),
            "Transport state requires secondary tiers 1 through 2."
        )

        self.tiers = tiers.sorted {
            if $0.track == $1.track {
                return $0.level < $1.level
            }
            return $0.track == .primary
        }
        self.activeTransport = activeTransport

        validateActiveItem(activeTransport.primary, on: .primary)
        validateActiveItem(activeTransport.secondary, on: .secondary)
        assert(
            activeTransport.secondary == nil
                || activeTransport.primary != nil,
            "Secondary Transport requires active primary Transport."
        )
    }

    func requiredLocationTier(
        for transport: Transport
    ) -> LocationTierLevel {
        tier(containing: transport).requiredLocationTier
    }

    func captureRollbackState() -> TransportRollbackState {
        TransportRollbackState(activeTransport: activeTransport)
    }

    func applyUpgrade(_ transport: Transport) {
        let purchasedTier = tier(containing: transport)
        guard nextTiers.contains(where: { $0.id == purchasedTier.id }) else {
            preconditionFailure(
                "A Transport upgrade must be an available next tier."
            )
        }

        let activeItem = ActiveTransportItem(
            transport: transport,
            tierLevel: purchasedTier.level
        )

        switch purchasedTier.track {
        case .primary:
            activeTransport.primary = activeItem
        case .secondary:
            activeTransport.secondary = activeItem
        }
    }

    func revertUpgrade(to state: TransportRollbackState) {
        activeTransport = state.activeTransport
    }

    private func tier(
        containing transport: Transport
    ) -> TransportTier {
        guard let tier = tiers.first(
            where: { $0.transport.id == transport.id }
        ) else {
            preconditionFailure("Transport item must belong to its state.")
        }
        return tier
    }

    private func tier(
        for item: ActiveTransportItem?,
        on track: TransportTrack
    ) -> TransportTier? {
        guard let item else { return nil }

        return tiers.first {
            $0.track == track
                && $0.level == item.tierLevel
                && $0.transport.id == item.id
        }
    }

    private func validateActiveItem(
        _ item: ActiveTransportItem?,
        on track: TransportTrack
    ) {
        guard item != nil else { return }
        assert(
            tier(for: item, on: track) != nil,
            "Active Transport item must belong to its track and state."
        )
    }
}

final class TransportDimension: Dimension {
    static let marketSizeWeight = 0.45

    private let transportState: TransportState
    private let locationState: LocationState

    init(
        transportState: TransportState,
        locationState: LocationState
    ) {
        self.transportState = transportState
        self.locationState = locationState
    }

    func calculateMarketSize() -> Double {
        guard locationState.activeTier.level >= .tierTwo,
              transportState.activePrimaryTier != nil else {
            return 1.0
        }

        return SimulationBalance.marketSize.multiplier(
            weight: Self.marketSizeWeight,
            targetMultiplier: transportState.marketSizeTargetMultiplier
        )
    }

    func calculateWeeklyCosts(
        summary: DaySummary,
        multiplier: Double
    ) -> Double {
        transportState.activeTransport.items.reduce(0) { total, activeItem in
            let proratedCost = activeItem.transport.price * multiplier
            guard proratedCost > 0 else { return total }

            summary.cashFlowCosts.append(
                Cost(
                    category: .transport,
                    displaySuffix: multiplier == 1.0 ? nil : "Prorated",
                    name: activeItem.transport.name,
                    amount: proratedCost
                )
            )

            return total + proratedCost
        }
    }
}
