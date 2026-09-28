import Foundation

enum CapacityType: Equatable {
    case total
    case additional
}

protocol CapacityProviding {
    var capacity: Int { get }
    var capacityType: CapacityType { get }
}

extension CapacityProviding {
    var capacityDisplayText: String {
        let prefix = capacityType == .additional ? "+" : ""
        return "\(prefix)\(capacity) / day"
    }
}

enum UpgradeTierLevel: Int, CaseIterable, Codable {
    case tierZero = 0
    case tierOne = 1
    case tierTwo = 2
    case tierThree = 3
    case tierFour = 4
    case tierFive = 5
}

enum CapacityUpgradeID: Hashable, Codable {
    case tier(UpgradeTierLevel)
    case secondaryEquipment(SecondaryCapacityStrength)
    case laborBaseline
    case laborSpecialist
    case sharedLabor
}

/// Connects an upgrade to its capacity as a percentage of ideal unit sales.
/// The caller determines whether the value is a total replacement capacity or
/// an additive contribution.
struct CapacityUpgrade {
    let upgradeID: CapacityUpgradeID
    let scheduledCapacity: Double

    init(
        upgradeID: CapacityUpgradeID,
        scheduledCapacity: Double
    ) {
        assert(scheduledCapacity >= 0)

        self.upgradeID = upgradeID
        self.scheduledCapacity = scheduledCapacity
    }
}

/// Converts the scheduled percentage for an upgrade into whole production
/// units for a specific product.
struct CapacitySchedule {
    let upgrades: [CapacityUpgrade]

    init(
        upgrades: [CapacityUpgrade]
    ) {
        assert(!upgrades.isEmpty)

        let upgradeIDs = upgrades.map(\.upgradeID)
        assert(
            Set(upgradeIDs).count == upgradeIDs.count,
            "A capacity schedule cannot contain duplicate upgrade IDs."
        )

        self.upgrades = upgrades
    }

    func capacity(
        for upgradeID: CapacityUpgradeID,
        product: Product
    ) -> Int {
        capacity(
            for: upgradeID,
            idealUnitsSold: product.idealUnitsSold
        )
    }

    func capacity(
        for upgradeID: CapacityUpgradeID,
        idealUnitsSold: Int
    ) -> Int {
        guard let upgrade = upgrades.first(
            where: { $0.upgradeID == upgradeID }
        ) else {
            preconditionFailure(
                "Capacity schedule does not contain \(upgradeID)."
            )
        }

        return Int(
            (
                Double(idealUnitsSold)
                    * upgrade.scheduledCapacity
            ).rounded()
        )
    }

    func scheduledCapacity(
        for upgradeID: CapacityUpgradeID
    ) -> Double {
        guard let upgrade = upgrades.first(
            where: { $0.upgradeID == upgradeID }
        ) else {
            preconditionFailure(
                "Capacity schedule does not contain \(upgradeID)."
            )
        }

        return upgrade.scheduledCapacity
    }
}
