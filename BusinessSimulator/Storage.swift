import Foundation
import Observation

struct StorageID: RawRepresentable, Hashable, Codable {
    let rawValue: String
}

struct StorageTierID: RawRepresentable, Hashable {
    let rawValue: String
}

struct Storage: Identifiable, Equatable, Codable, PurchasableItem,
    CapacityProviding
{
    let id: StorageID
    let name: String
    let smallIcon: GameIcon
    let description: String
    var price: Double
    var capacity: Int

    var paymentSchedule: PaymentSchedule {
        .oneTime
    }

    var purchaseItemID: String {
        id.rawValue
    }

    var capacityType: CapacityType {
        .total
    }

    init(
        id: StorageID,
        name: String,
        smallIcon: GameIcon,
        description: String
    ) {
        self.id = id
        self.name = name
        self.smallIcon = smallIcon
        self.description = description
        self.price = 0
        self.capacity = 0
    }

    /// Rounds calculated storage prices to the same retail-style amounts used
    /// by other one-time capacity purchases.
    static func cleanPrice(_ calculatedPrice: Double) -> Double {
        guard calculatedPrice > 0 else { return 0 }
        return (calculatedPrice / 50).rounded() * 50 - 1
    }
}

struct ActiveStorage: Identifiable, Equatable, Codable {
    let storage: Storage
    let tierLevel: Int

    var id: StorageID {
        storage.id
    }
}

struct StorageTier: Identifiable, Equatable {
    let id: StorageTierID
    let level: Int
    let requiredLocationTier: LocationTierLevel
    let storage: Storage

    init(
        id: StorageTierID,
        level: Int,
        storage: Storage,
        product: Product,
        capacitySchedule: CapacitySchedule,
        requiredLocationTier: LocationTierLevel
    ) {
        assert((0...5).contains(level), "Storage tier must be 0 through 5.")

        guard let upgradeTier = UpgradeTierLevel(rawValue: level) else {
            preconditionFailure("Storage tier \(level) has no capacity tier.")
        }

        var configuredStorage = storage
        configuredStorage.capacity = capacitySchedule.capacity(
            for: .tier(upgradeTier),
            product: product
        )

        if level == 0 {
            configuredStorage.price = 0
        } else {
            let dailyBenefit = UpgradePricing.calculateDailyBenefit(
                tierLevel: level,
                product: product,
                locationDemandMultiplier:
                    requiredLocationTier.demandMultiplier,
                representativeMarketSizeMultiplier:
                    requiredLocationTier.pricingMarketSizeMultiplier,
                capacityEffect: .replacement(configuredStorage.capacity)
            )
            configuredStorage.price = Storage.cleanPrice(
                UpgradePricing.calculatePrice(
                    dailyBenefit: dailyBenefit,
                    paymentSchedule: configuredStorage.paymentSchedule,
                    tierLevel: level,
                    capacityEffect: .replacement(configuredStorage.capacity)
                )
            )
        }

        self.id = id
        self.level = level
        self.requiredLocationTier = requiredLocationTier
        self.storage = configuredStorage
    }
}

struct StorageRollbackState {
    let activeStorage: ActiveStorage
}

@Observable
final class StorageState: PurchasableState {
    typealias PurchaseItem = Storage
    typealias RollbackState = StorageRollbackState

    let tiers: [StorageTier]
    private(set) var activeStorage: ActiveStorage

    var dimensionID: PurchaseCategory {
        .storage
    }

    var activeTier: StorageTier {
        guard
            let tier = tiers.first(
                where: { $0.level == activeStorage.tierLevel }
            )
        else {
            preconditionFailure("Active storage must belong to its state.")
        }
        return tier
    }

    var nextTier: StorageTier? {
        tiers.first { $0.level == activeStorage.tierLevel + 1 }
    }

    var totalCapacity: Int {
        activeStorage.storage.capacity
    }

    func capacityProgress(for capacity: Int) -> Double {
        guard let maximumCapacity = tiers.last?.storage.capacity,
              maximumCapacity > 0 else {
            return 0
        }

        return min(
            max(Double(capacity) / Double(maximumCapacity), 0),
            1
        )
    }

    init(
        tiers: [StorageTier],
        activeStorage: ActiveStorage? = nil
    ) {
        let levels = tiers.map(\.level)
        assert(
            Set(levels).count == levels.count,
            "Storage state must contain only one tier per level."
        )
        assert(
            Set(levels) == Set(0...5),
            "Storage state requires every tier from 0 through 5."
        )

        let orderedTiers = tiers.sorted { $0.level < $1.level }
        let resolvedActiveStorage: ActiveStorage

        if let activeStorage {
            guard
                orderedTiers.contains(where: {
                    $0.level == activeStorage.tierLevel
                        && $0.storage.id == activeStorage.id
                })
            else {
                preconditionFailure("Active storage must belong to its state.")
            }
            resolvedActiveStorage = activeStorage
        } else {
            let startingTier = orderedTiers[0]
            resolvedActiveStorage = ActiveStorage(
                storage: startingTier.storage,
                tierLevel: startingTier.level
            )
        }

        self.tiers = orderedTiers
        self.activeStorage = resolvedActiveStorage
    }

    func requiredLocationTier(for storage: Storage) -> LocationTierLevel {
        guard let tier = tiers.first(where: { $0.storage.id == storage.id }) else {
            preconditionFailure("Storage must belong to a storage tier.")
        }
        return tier.requiredLocationTier
    }

    func captureRollbackState() -> StorageRollbackState {
        StorageRollbackState(activeStorage: activeStorage)
    }

    func applyUpgrade(_ storage: Storage) {
        guard let nextTier,
            nextTier.storage.id == storage.id
        else {
            preconditionFailure(
                "A storage upgrade must come from the next tier."
            )
        }

        activeStorage = ActiveStorage(
            storage: storage,
            tierLevel: nextTier.level
        )
    }

    func revertUpgrade(to state: StorageRollbackState) {
        activeStorage = state.activeStorage
    }
}

final class StorageDimension: Dimension {
    private let storageState: StorageState
    private let locationState: LocationState

    init(
        storageState: StorageState,
        locationState: LocationState
    ) {
        self.storageState = storageState
        self.locationState = locationState
    }

    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int {
        guard locationState.activeTier.level >= .tierTwo else {
            return sales
        }

        let limitedSales = min(sales, storageState.totalCapacity)
        if limitedSales < sales {
            summary.addNote(
                sectionName: "Distribution",
                note: "Sales were limited by storage capacity."
            )
        }
        return limitedSales
    }
}
