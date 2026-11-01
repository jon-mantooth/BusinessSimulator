import Foundation
import Testing
@testable import BusinessSimulator

@MainActor
struct TransportTests {

    @Test(arguments: transportProductIDs)
    func catalogBuildsCompleteSequentialTracks(productID: ProductID) {
        let tiers = transportTiers(for: productID)
        let primaryTiers = tiers.filter { $0.track == .primary }
        let secondaryTiers = tiers.filter { $0.track == .secondary }

        #expect(primaryTiers.map(\.level) == [1, 2, 3])
        #expect(secondaryTiers.map(\.level) == [1, 2])
        #expect(Set(tiers.map(\.id)).count == tiers.count)
        #expect(Set(tiers.map { $0.transport.id }).count == tiers.count)
    }

    @Test(arguments: transportProductIDs)
    func locationRequirementsFollowProgressionContract(productID: ProductID) {
        let tiers = transportTiers(for: productID)
        let primaryTiers = tiers.filter { $0.track == .primary }
        let secondaryTiers = tiers.filter { $0.track == .secondary }

        #expect(primaryTiers.first?.requiredLocationTier == .tierOne)
        #expect(
            primaryTiers.dropFirst().allSatisfy {
                $0.requiredLocationTier == .tierTwo
            }
        )
        #expect(
            secondaryTiers.allSatisfy {
                $0.requiredLocationTier == .tierTwo
            }
        )
    }

    @Test
    func primaryTransportIsSharedWhileSecondaryTransportIsProductSpecific() {
        let tiersByProduct = Dictionary(
            uniqueKeysWithValues: transportProductIDs.map {
                ($0, transportTiers(for: $0))
            }
        )
        let primaryIDs = tiersByProduct.mapValues { tiers in
            tiers.filter { $0.track == .primary }.map { $0.transport.id }
        }
        let secondaryIDs = tiersByProduct.mapValues { tiers in
            Set(
                tiers.filter { $0.track == .secondary }
                    .map { $0.transport.id }
            )
        }

        #expect(primaryIDs[.pies] == primaryIDs[.hotDogs])
        #expect(primaryIDs[.pies] == primaryIDs[.smoothies])
        #expect(secondaryIDs[.pies]!.isDisjoint(with: secondaryIDs[.hotDogs]!))
        #expect(secondaryIDs[.pies]!.isDisjoint(with: secondaryIDs[.smoothies]!))
        #expect(
            secondaryIDs[.hotDogs]!.isDisjoint(
                with: secondaryIDs[.smoothies]!
            )
        )
    }

    @Test
    func initialStateOffersOnlyFirstPrimaryTier() throws {
        let state = transportState()
        let nextTier = try #require(state.nextTiers.first)

        #expect(state.activeTransport.items.isEmpty)
        #expect(state.activePrimaryTier == nil)
        #expect(state.activeSecondaryTier == nil)
        #expect(state.nextTiers.count == 1)
        #expect(nextTier.track == .primary)
        #expect(nextTier.level == 1)
    }

    @Test
    func firstPrimaryUnlocksNextLevelOnBothTracks() throws {
        let state = transportState()
        try apply(track: .primary, level: 1, to: state)

        #expect(
            Set(state.nextTiers.map { TrackLevel($0) }) == [
                TrackLevel(track: .primary, level: 2),
                TrackLevel(track: .secondary, level: 1)
            ]
        )
    }

    @Test
    func replacingPrimaryDoesNotChangeSecondary() throws {
        let state = transportState()
        try apply(track: .primary, level: 1, to: state)
        try apply(track: .secondary, level: 1, to: state)
        let secondaryBeforeUpgrade = state.activeTransport.secondary

        try apply(track: .primary, level: 2, to: state)

        #expect(state.activePrimaryTier?.level == 2)
        #expect(state.activeTransport.secondary == secondaryBeforeUpgrade)
    }

    @Test
    func replacingSecondaryDoesNotChangePrimary() throws {
        let state = transportState()
        try apply(track: .primary, level: 1, to: state)
        try apply(track: .secondary, level: 1, to: state)
        let primaryBeforeUpgrade = state.activeTransport.primary

        try apply(track: .secondary, level: 2, to: state)

        #expect(state.activeSecondaryTier?.level == 2)
        #expect(state.activeTransport.primary == primaryBeforeUpgrade)
    }

    @Test
    func rollbackRestoresBothTracks() throws {
        let state = transportState()
        try apply(track: .primary, level: 1, to: state)
        try apply(track: .secondary, level: 1, to: state)
        let snapshot = state.captureRollbackState()

        try apply(track: .primary, level: 2, to: state)
        try apply(track: .secondary, level: 2, to: state)
        state.revertUpgrade(to: snapshot)

        #expect(state.activePrimaryTier?.level == 1)
        #expect(state.activeSecondaryTier?.level == 1)
    }

    @Test
    func progressAndStarsFollowTransportBalancingContract() {
        let tiers = transportTiers(for: .pies)
        let primary = tiers.filter { $0.track == .primary }
        let secondary = tiers.filter { $0.track == .secondary }

        #expect(primary.map(\.trackProgress) == [0.40, 0.55, 0.70])
        #expect(secondary.map(\.trackProgress) == [0.15, 0.30])
        #expect(primary.map(\.marketSizeStars) == [3.0, 3.5, 4.0])
        #expect(secondary.map(\.marketSizeStars) == [0.5, 1.0])
    }

    @Test
    func totalStarsCombinePrimaryTotalWithSecondaryAddition() throws {
        let state = transportState()
        try apply(track: .primary, level: 2, to: state)
        try apply(track: .secondary, level: 1, to: state)

        #expect(state.totalMarketSizeStars == 4.0)
    }
}

private struct TrackLevel: Hashable {
    let track: TransportTrack
    let level: Int

    init(track: TransportTrack, level: Int) {
        self.track = track
        self.level = level
    }

    init(_ tier: TransportTier) {
        self.init(track: tier.track, level: tier.level)
    }
}

private let transportProductIDs: [ProductID] = [
    .pies,
    .hotDogs,
    .smoothies
]

@MainActor
private func transportTiers(
    for productID: ProductID
) -> [TransportTier] {
    let product = ProductCatalog().product(for: productID)
    return TransportCatalog().tiers(for: product)
}

@MainActor
private func transportState(
    productID: ProductID = .pies
) -> TransportState {
    TransportState(tiers: transportTiers(for: productID))
}

@MainActor
private func apply(
    track: TransportTrack,
    level: Int,
    to state: TransportState
) throws {
    while activeLevel(on: track, in: state) < level {
        let nextLevel = activeLevel(on: track, in: state) + 1
        let tier = try #require(
            state.nextTiers.first {
                $0.track == track && $0.level == nextLevel
            }
        )
        state.applyUpgrade(tier.transport)
    }
}

@MainActor
private func activeLevel(
    on track: TransportTrack,
    in state: TransportState
) -> Int {
    switch track {
    case .primary:
        state.activePrimaryTier?.level ?? 0
    case .secondary:
        state.activeSecondaryTier?.level ?? 0
    }
}
