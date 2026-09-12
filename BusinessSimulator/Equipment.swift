import Foundation
import Observation

// TODO: After equipment, labor, storage, transportation, and other purchasable
// systems are implemented, review their shared models and behavior for possible
// abstraction. In particular, compare active-item snapshots, owned-item
// collections, cost aggregation, validation, and rollback behavior. Wait until
// the concrete implementations reveal which similarities are truly semantic
// rather than merely structural.

struct EquipmentID: RawRepresentable, Hashable, Codable {
    let rawValue: String
}

struct EquipmentTierID: RawRepresentable, Hashable, Codable {
    let rawValue: String
}

enum IngredientUpgradeEffect: String, Equatable, Codable {
    case recipeAmount
    case lifespan
    case ingredientReplacement
}

/// Describes a product-inventory change unlocked by an equipment purchase.
/// The value can be persisted while the upgrade waits to be applied at the
/// end of the current day.
struct IngredientUpgrade: Equatable, Codable {
    let effect: IngredientUpgradeEffect
    let ingredientID: InventoryType
    let description: String
}

enum SecondaryCapacityStrength: String, Equatable, Codable {
    case low
    case medium
    case high

    // Calculate capacity based on CapacityStrength. Low will be 3% of ideal units sold,
    // medium 5% and high 7%
    func capacity(
        for idealUnitsSold: Int
    ) -> Int {
        assert(idealUnitsSold > 0)

        let lowCapacity = max(
            1,
            Int((Double(idealUnitsSold) * 0.03).rounded())
        )
        let mediumCapacity = max(
            lowCapacity + 1,
            Int((Double(idealUnitsSold) * 0.05).rounded())
        )
        let highCapacity = max(
            mediumCapacity + 1,
            Int((Double(idealUnitsSold) * 0.07).rounded())
        )

        switch self {
        case .low:
            return lowCapacity
        case .medium:
            return mediumCapacity
        case .high:
            return highCapacity
        }
    }
}

enum EquipmentCategory: Equatable, Codable {
    case primary
    case secondary(
        capacityStrength: SecondaryCapacityStrength
    )
}

struct Equipment: Identifiable, Equatable, Codable, PurchasableItem {
    let id: EquipmentID
    let name: String
    let smallIcon: GameIcon
    let description: String
    let equipmentBenefit: String?
    var price: Double
    let category: EquipmentCategory
    let ingredientUpgrade: IngredientUpgrade?
    let demandLevel: Int
    let totalLevels: Int
    /// Primary equipment stores its total daily production capacity. Secondary
    /// equipment stores the number of daily units it adds to primary capacity.
    var capacity: Int

    var paymentSchedule: PaymentSchedule {
        .oneTime
    }

    var demandEffectScore: Double {
        Double(demandLevel) / Double(totalLevels)
    }

    var purchaseItemID: String {
        id.rawValue
    }

    /// Rounds primary equipment to a retail-style price ending in 49 or 99.
    static func cleanPrice(
        _ calculatedPrice: Double
    ) -> Double {
        guard calculatedPrice > 0 else {
            return 0
        }

        return (calculatedPrice / 50).rounded() * 50 - 1
    }

    init(
        id: EquipmentID,
        name: String,
        smallIcon: GameIcon,
        description: String,
        equipmentBenefit: String? = nil,
        price: Double = 0.00,
        category: EquipmentCategory,
        ingredientUpgrade: IngredientUpgrade? = nil,
        demandLevel: Int,
        totalLevels: Int = 5,
        capacity: Int = 0
    ) {
        assert(price >= 0, "Equipment price cannot be negative.")
        assert(totalLevels > 0, "Equipment total levels must be positive.")
        assert(capacity >= 0, "Equipment capacity cannot be negative.")
        assert(
            demandLevel >= 0,
            "Equipment demand level cannot be negative."
        )
        assert(
            totalLevels >= demandLevel,
            "Equipment demand level cannot exceed total levels."
        )

        self.id = id
        self.name = name
        self.smallIcon = smallIcon
        self.description = description
        self.equipmentBenefit = equipmentBenefit
        self.price = price
        self.category = category
        self.ingredientUpgrade = ingredientUpgrade
        self.demandLevel = demandLevel
        self.totalLevels = totalLevels
        self.capacity = capacity
    }
}

/// A snapshot of a piece of equipment at the moment it becomes active. Unlike
/// catalog equipment, these values do not change when catalog balancing is
/// updated in a later version of the game.
struct ActivePrimaryEquipment: Identifiable, Equatable, Codable {
    let equipment: Equipment
    let tierLevel: Int

    var id: EquipmentID {
        equipment.id
    }

    init(
        equipment: Equipment,
        tierLevel: Int
    ) {
        self.equipment = equipment
        self.tierLevel = tierLevel
    }
}

struct SecondaryEquipmentCollection: Equatable, Codable {
    private(set) var equipment: [Equipment]

    var totalDemandLevel: Int {
        equipment.reduce(0) { total, equipment in
            total + equipment.demandLevel
        }
    }

    var totalDemandEffectScore: Double {
        equipment.reduce(0.0) { total, equipment in
            total + equipment.demandEffectScore
        }
    }

    var totalCapacity: Int {
        equipment.reduce(0) { total, equipment in
            total + equipment.capacity
        }
    }

    var totalCosts: [PaymentSchedule: Double] {
        var costsByPaymentSchedule: [PaymentSchedule: Double] = [:]

        for equipment in equipment {
            costsByPaymentSchedule[equipment.paymentSchedule, default: 0] +=
                equipment.price
        }

        return costsByPaymentSchedule
    }

    init(
        equipment: [Equipment] = []
    ) {
        let equipmentIDs = equipment.map(\.id)
        assert(
            Set(equipmentIDs).count == equipmentIDs.count,
            "A secondary equipment collection cannot contain duplicates."
        )
        assert(
            equipment.allSatisfy { item in
                if case .secondary = item.category {
                    return true
                }
                return false
            },
            "A secondary equipment collection can contain only secondary equipment."
        )

        self.equipment = equipment
    }

    func contains(
        _ candidate: Equipment
    ) -> Bool {
        equipment.contains { $0.id == candidate.id }
    }

    mutating func add(
        _ newEquipment: Equipment
    ) {
        guard case .secondary = newEquipment.category else {
            preconditionFailure(
                "Only secondary equipment can be added to this collection."
            )
        }
        guard !contains(newEquipment) else {
            preconditionFailure(
                "Secondary equipment cannot be purchased more than once."
            )
        }

        equipment.append(newEquipment)
    }

    mutating func remove(
        _ removedEquipment: Equipment
    ) {
        equipment.removeAll { $0.id == removedEquipment.id }
    }
}

struct EquipmentTier: Identifiable, Equatable {
    let id: EquipmentTierID
    let level: Int
    let equipment: [Equipment]

    init(
        id: EquipmentTierID,
        level: Int,
        equipment: [Equipment],
        product: Product
    ) {
        assert(level >= 0, "Equipment tier level cannot be negative.")
        assert(
            !equipment.isEmpty,
            "An equipment tier must contain at least one equipment option."
        )
        assert(
            equipment.allSatisfy { $0.category == .primary },
            "An equipment tier can contain only primary equipment."
        )

        let equipmentIDs = equipment.map(\.id)
        assert(
            Set(equipmentIDs).count == equipmentIDs.count,
            "An equipment tier cannot contain duplicate equipment."
        )

        self.id = id
        self.level = level
        self.equipment = equipment.map { equipment in
            var configuredEquipment = equipment
            let baseCapacity = ProductionCapacityBalance.baseCapacity(
                baseIdealUnitsSold: product.idealUnitsSold
            )
            let expectedCapacityIncrease = ProductionCapacityBalance
                .expectedCapacityIncrease(
                    baseIdealUnitsSold: product.idealUnitsSold,
                    tierLevel: level
                )
            configuredEquipment.capacity =
                baseCapacity + expectedCapacityIncrease

            guard level > 0 else {
                configuredEquipment.price = 0
                return configuredEquipment
            }

            let capacityPrice = UpgradePricing.setCapacityPrice(
                baseIdealUnitsSold: product.idealUnitsSold,
                upgradedCapacity: configuredEquipment.capacity,
                baseIdealPrice: product.baseIdealPrice
            )
            let demandPrice = UpgradePricing.setStandaloneDemandPrice(
                baseIdealUnitsSold: product.idealUnitsSold,
                baseIdealPrice: product.baseIdealPrice,
                demandLevel: configuredEquipment.demandLevel,
                totalLevels: configuredEquipment.totalLevels,
                demandWeight: EquipmentDimension.primaryDemandWeight
            )
            configuredEquipment.price = Equipment.cleanPrice(
                capacityPrice + demandPrice
            )
            return configuredEquipment
        }
    }
}

final class EquipmentDimension: Dimension {
    // Equipment's portion of permanent demand growth is divided between the
    // primary production equipment and the cumulative secondary equipment.
    // Together these retain equipment's total 25% demand allocation.
    static let primaryDemandWeight = 0.10
    static let secondaryDemandWeight = 0.15

    private let equipmentState: EquipmentState

    init(
        equipmentState: EquipmentState
    ) {
        self.equipmentState = equipmentState
    }

    func calculateDemand() -> Double {
        let primaryEffectScore = equipmentState
            .activePrimaryEquipment
            .equipment
            .demandEffectScore
        let secondaryEffectScore = equipmentState
            .ownedSecondaryEquipment
            .totalDemandEffectScore

        assert(
            (0.0...1.0).contains(primaryEffectScore),
            "Primary equipment demand effect must be normalized."
        )
        assert(
            (0.0...1.0).contains(secondaryEffectScore),
            "Secondary equipment demand effect must be normalized."
        )

        let primaryMultiplier = SimulationBalance.demand.multiplier(
            weight: Self.primaryDemandWeight,
            effectScore: primaryEffectScore
        )
        let secondaryMultiplier = SimulationBalance.demand.multiplier(
            weight: Self.secondaryDemandWeight,
            effectScore: secondaryEffectScore
        )

        return primaryMultiplier * secondaryMultiplier
    }

    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int {
        let limitedSales = min(sales, equipmentState.totalCapacity)

        if limitedSales < sales {
            summary.addNote(
                sectionName: "Production",
                note: "Sales were limited by equipment capacity."
            )
        }

        return limitedSales
    }

    func calculateDailyCosts(
        sales: Int,
        summary: DaySummary
    ) -> Double {
        recordCost(
            for: .daily,
            summary: summary
        )
    }

    func calculateWeeklyCosts(
        summary: DaySummary
    ) -> Double {
        recordCost(
            for: .weekly,
            summary: summary
        )
    }

    private func recordCost(
        for paymentSchedule: PaymentSchedule,
        summary: DaySummary
    ) -> Double {
        let primaryEquipment = equipmentState.activePrimaryEquipment.equipment
        let primaryCost = primaryEquipment.paymentSchedule == paymentSchedule
            ? primaryEquipment.price
            : 0.0
        let secondaryCost = equipmentState
            .ownedSecondaryEquipment
            .totalCosts[paymentSchedule, default: 0.0]
        let totalCost = primaryCost + secondaryCost

        if totalCost > 0 {
            summary.cashFlowCosts.append(
                Cost(
                    name: "Equipment",
                    amount: totalCost
                )
            )
        }

        return totalCost
    }
}

struct EquipmentRollbackState {
    let activePrimaryEquipment: ActivePrimaryEquipment
    let ownedSecondaryEquipment: SecondaryEquipmentCollection
}

@Observable
final class EquipmentState: PurchasableState {
    typealias PurchaseItem = Equipment
    typealias RollbackState = EquipmentRollbackState

    let primaryTiers: [EquipmentTier]
    let secondaryEquipmentCatalog: SecondaryEquipmentCollection

    private(set) var activePrimaryEquipment: ActivePrimaryEquipment
    private(set) var ownedSecondaryEquipment: SecondaryEquipmentCollection

    var dimensionID: PurchaseCategory {
        .equipment
    }

    var activePrimaryTier: EquipmentTier {
        guard let tier = primaryTiers.first(
            where: { $0.level == activePrimaryEquipment.tierLevel }
        ) else {
            preconditionFailure(
                "Active primary equipment must belong to this state."
            )
        }

        return tier
    }

    var nextPrimaryTier: EquipmentTier? {
        primaryTiers.first {
            $0.level == activePrimaryEquipment.tierLevel + 1
        }
    }

    var availableSecondaryEquipment: SecondaryEquipmentCollection {
        SecondaryEquipmentCollection(
            equipment: secondaryEquipmentCatalog.equipment.filter {
                !ownedSecondaryEquipment.contains($0)
            }
        )
    }

    var totalCapacity: Int {
        activePrimaryEquipment.equipment.capacity
            + ownedSecondaryEquipment.totalCapacity
    }

    init(
        primaryTiers: [EquipmentTier],
        secondaryEquipmentCatalog: SecondaryEquipmentCollection,
        activePrimaryEquipment: ActivePrimaryEquipment? = nil,
        ownedSecondaryEquipment: SecondaryEquipmentCollection =
            SecondaryEquipmentCollection()
    ) {
        let tierIDs = primaryTiers.map(\.id)
        assert(
            Set(tierIDs).count == tierIDs.count,
            "Equipment state cannot contain duplicate primary tiers."
        )

        let tierLevels = primaryTiers.map(\.level)
        assert(
            Set(tierLevels).count == tierLevels.count,
            "Equipment state must contain only one primary tier per level."
        )

        guard let startingTier = primaryTiers.first(
            where: { $0.level == 0 }
        ) else {
            preconditionFailure(
                "Equipment state requires a tier-zero primary equipment."
            )
        }

        let resolvedActiveEquipment: ActivePrimaryEquipment
        if let activePrimaryEquipment {
            guard primaryTiers.contains(where: { tier in
                tier.level == activePrimaryEquipment.tierLevel
                    && tier.equipment.contains {
                        $0.id == activePrimaryEquipment.id
                    }
            }) else {
                preconditionFailure(
                    "Active primary equipment must belong to this state."
                )
            }
            resolvedActiveEquipment = activePrimaryEquipment
        } else {
            guard let startingEquipment = startingTier.equipment.first else {
                preconditionFailure(
                    "Equipment tier zero requires primary equipment."
                )
            }
            resolvedActiveEquipment = ActivePrimaryEquipment(
                equipment: startingEquipment,
                tierLevel: startingTier.level
            )
        }

        let secondaryCatalogIDs = Set(
            secondaryEquipmentCatalog.equipment.map(\.id)
        )
        assert(
            ownedSecondaryEquipment.equipment.allSatisfy {
                secondaryCatalogIDs.contains($0.id)
            },
            "Owned secondary equipment must belong to this state's catalog."
        )

        self.primaryTiers = primaryTiers.sorted { $0.level < $1.level }
        self.secondaryEquipmentCatalog = secondaryEquipmentCatalog
        self.activePrimaryEquipment = resolvedActiveEquipment
        self.ownedSecondaryEquipment = ownedSecondaryEquipment
    }

    func captureRollbackState() -> EquipmentRollbackState {
        EquipmentRollbackState(
            activePrimaryEquipment: activePrimaryEquipment,
            ownedSecondaryEquipment: ownedSecondaryEquipment
        )
    }

    func applyUpgrade(
        _ equipment: Equipment
    ) {
        switch equipment.category {
        case .primary:
            guard let nextPrimaryTier,
                  nextPrimaryTier.equipment.contains(
                    where: { $0.id == equipment.id }
                  ) else {
                preconditionFailure(
                    "A primary equipment upgrade must come from the next tier."
                )
            }

            activePrimaryEquipment = ActivePrimaryEquipment(
                equipment: equipment,
                tierLevel: nextPrimaryTier.level
            )

        case .secondary:
            guard secondaryEquipmentCatalog.contains(equipment) else {
                preconditionFailure(
                    "Secondary equipment must belong to this state's catalog."
                )
            }

            ownedSecondaryEquipment.add(equipment)

            // TODO: Add this equipment's ingredientUpgrade to the persisted
            // pending-upgrade collection as part of the purchase workflow.
        }
    }

    func revertUpgrade(
        to state: EquipmentRollbackState
    ) {
        activePrimaryEquipment = state.activePrimaryEquipment
        ownedSecondaryEquipment = state.ownedSecondaryEquipment
    }
}
