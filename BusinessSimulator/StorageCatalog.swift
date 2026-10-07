import Foundation

struct StorageCatalog {
    let capacitySchedule: CapacitySchedule

    private let pieStorage: [Storage]
    private let hotDogStorage: [Storage]
    private let smoothieStorage: [Storage]

    init() {
        capacitySchedule = CapacitySchedule(
            upgrades: [
                CapacityUpgrade(upgradeID: .tier(.tierZero), scheduledCapacity: 0),
                CapacityUpgrade(upgradeID: .tier(.tierOne), scheduledCapacity: 2.30),
                CapacityUpgrade(upgradeID: .tier(.tierTwo), scheduledCapacity: 2.55),
                CapacityUpgrade(upgradeID: .tier(.tierThree), scheduledCapacity: 2.80),
                CapacityUpgrade(upgradeID: .tier(.tierFour), scheduledCapacity: 3.05),
                CapacityUpgrade(upgradeID: .tier(.tierFive), scheduledCapacity: 3.30)
            ]
        )

        pieStorage = [
            Storage(
                id: StorageID(rawValue: "pie-no-storage"),
                name: "No Storage",
                smallIcon: .system("shippingbox"),
                description: "No dedicated pie storage."
            ),
            Storage(
                id: StorageID(rawValue: "insulated-pie-holding-rack"),
                name: "Insulated Pie Holding Rack",
                smallIcon: .system("shippingbox.fill"),
                description:
                    "A portable, insulated rack that protects finished pies and keeps them warm during transport and farmers-market service."
            ),
            Storage(
                id: StorageID(rawValue: "heated-pie-display-cabinet"),
                name: "Heated Pie Display Cabinet",
                smallIcon: .system("cabinet.fill"),
                description:
                    "A compact powered cabinet that keeps more pies warm, organized, and ready for customers throughout market service."
            ),
            Storage(
                id: StorageID(rawValue: "commercial-pie-warming-cabinet"),
                name: "Commercial Pie Warming Cabinet",
                smallIcon: .system("cabinet.fill"),
                description:
                    "A full-size heated cabinet with adjustable shelving that keeps a larger supply of pies consistently warm and ready for busy market days."
            ),
            Storage(
                id: StorageID(rawValue: "dual-zone-pie-holding-cabinet"),
                name: "Dual-Zone Pie Holding Cabinet",
                smallIcon: .system("cabinet.fill"),
                description:
                    "A high-capacity cabinet with independently controlled warming zones, allowing different pie varieties to remain at their ideal serving temperatures during peak service."
            ),
            Storage(
                id: StorageID(rawValue: "commercial-roll-in-pie-warmer"),
                name: "Commercial Roll-In Pie Warmer",
                smallIcon: .system("cabinet.fill"),
                description:
                    "A premium roll-in warming system that holds full racks of finished pies with precise temperature control and rapid access during the busiest market service."
            )
        ]

        hotDogStorage = [
            Storage(
                id: StorageID(rawValue: "hot-dog-no-storage"),
                name: "No Storage",
                smallIcon: .system("shippingbox"),
                description: "No dedicated hot dog storage."
            ),
            Storage(
                id: StorageID(rawValue: "insulated-hot-dog-carrier"),
                name: "Insulated Hot Dog Carrier",
                smallIcon: .system("shippingbox.fill"),
                description:
                    "A portable insulated carrier that keeps prepared hot dogs warm and protected during transport to the ballpark."
            ),
            Storage(
                id: StorageID(rawValue: "hot-dog-and-bun-steamer"),
                name: "Hot Dog and Bun Steamer",
                smallIcon: .system("cabinet.fill"),
                description:
                    "A countertop steamer with separate compartments that keeps hot dogs hot and buns soft throughout service."
            ),
            Storage(
                id: StorageID(rawValue: "heated-hot-dog-holding-cabinet"),
                name: "Heated Hot Dog Holding Cabinet",
                smallIcon: .system("cabinet.fill"),
                description:
                    "A commercial heated cabinet that stores a larger supply at a consistent serving temperature during busy games."
            ),
            Storage(
                id: StorageID(rawValue: "dual-zone-hot-dog-holding-station"),
                name: "Dual-Zone Hot Dog Holding Station",
                smallIcon: .system("cabinet.fill"),
                description:
                    "A high-capacity station with independently controlled sections for hot dogs and buns, improving organization and temperature control."
            ),
            Storage(
                id: StorageID(rawValue: "commercial-ballpark-holding-system"),
                name: "Commercial Ballpark Holding System",
                smallIcon: .system("cabinet.fill"),
                description:
                    "A premium high-volume holding system designed for rapid access and continuous service during the largest crowds."
            )
        ]

        smoothieStorage = [
            Storage(
                id: StorageID(rawValue: "smoothie-no-storage"),
                name: "No Storage",
                smallIcon: .system("shippingbox"),
                description: "No dedicated smoothie storage."
            ),
            Storage(
                id: StorageID(rawValue: "insulated-smoothie-cooler"),
                name: "Insulated Smoothie Cooler",
                smallIcon: .system("snowflake"),
                description:
                    "A portable insulated cooler that keeps prepared smoothies cold and protected during transport to the beach."
            ),
            Storage(
                id: StorageID(rawValue: "portable-electric-cooler"),
                name: "Portable Electric Cooler",
                smallIcon: .system("snowflake"),
                description:
                    "A powered portable cooler that maintains a reliable cold temperature throughout beach service."
            ),
            Storage(
                id: StorageID(rawValue: "glass-door-beverage-refrigerator"),
                name: "Glass-Door Beverage Refrigerator",
                smallIcon: .system("refrigerator.fill"),
                description:
                    "A commercial refrigerator that keeps a larger smoothie supply cold, organized, and visible for quick service."
            ),
            Storage(
                id: StorageID(rawValue: "dual-zone-refrigerated-cabinet"),
                name: "Dual-Zone Refrigerated Cabinet",
                smallIcon: .system("refrigerator.fill"),
                description:
                    "A high-capacity cabinet with independently controlled cooling zones for maintaining different smoothie varieties."
            ),
            Storage(
                id: StorageID(rawValue: "commercial-roll-in-refrigerator"),
                name: "Commercial Roll-In Refrigerator",
                smallIcon: .system("refrigerator.fill"),
                description:
                    "A premium high-volume refrigerator that accommodates full racks of prepared smoothies for the busiest beach days."
            )
        ]
    }

    func tiers(for product: Product) -> [StorageTier] {
        let items: [Storage]
        switch product.id {
        case .pies:
            items = pieStorage
        case .hotDogs:
            items = hotDogStorage
        case .smoothies:
            items = smoothieStorage
        }

        return items.enumerated().map { level, storage in
            StorageTier(
                id: StorageTierID(
                    rawValue: "\(product.id.rawValue)-storage-tier-\(level)"
                ),
                level: level,
                storage: storage,
                product: product,
                capacitySchedule: capacitySchedule,
                requiredLocationTier: level <= 1 ? .tierOne : .tierTwo
            )
        }
    }

}
