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
                description: "A portable insulated rack for finished pies."
            ),
            Storage(
                id: StorageID(rawValue: "heated-pie-display-cabinet"),
                name: "Heated Pie Display Cabinet",
                smallIcon: .system("cabinet.fill"),
                description: "A compact heated cabinet for displaying pies."
            ),
            Storage(
                id: StorageID(rawValue: "commercial-pie-warming-cabinet"),
                name: "Commercial Pie Warming Cabinet",
                smallIcon: .system("cabinet.fill"),
                description: "A full-size warming cabinet with adjustable shelves."
            ),
            Storage(
                id: StorageID(rawValue: "dual-zone-pie-holding-cabinet"),
                name: "Dual-Zone Pie Holding Cabinet",
                smallIcon: .system("cabinet.fill"),
                description: "A warming cabinet with two temperature zones."
            ),
            Storage(
                id: StorageID(rawValue: "commercial-roll-in-pie-warmer"),
                name: "Commercial Roll-In Pie Warmer",
                smallIcon: .system("cabinet.fill"),
                description: "A commercial warmer built for full rolling racks."
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
                description: "A portable insulated carrier for prepared hot dogs."
            ),
            Storage(
                id: StorageID(rawValue: "hot-dog-and-bun-steamer"),
                name: "Hot Dog and Bun Steamer",
                smallIcon: .system("cabinet.fill"),
                description: "A countertop steamer with separate bun storage."
            ),
            Storage(
                id: StorageID(rawValue: "heated-hot-dog-holding-cabinet"),
                name: "Heated Hot Dog Holding Cabinet",
                smallIcon: .system("cabinet.fill"),
                description: "A commercial heated cabinet for prepared hot dogs."
            ),
            Storage(
                id: StorageID(rawValue: "dual-zone-hot-dog-holding-station"),
                name: "Dual-Zone Hot Dog Holding Station",
                smallIcon: .system("cabinet.fill"),
                description: "A holding station with separate hot dog and bun zones."
            ),
            Storage(
                id: StorageID(rawValue: "commercial-ballpark-holding-system"),
                name: "Commercial Ballpark Holding System",
                smallIcon: .system("cabinet.fill"),
                description: "A high-volume holding system for ballpark service."
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
                description: "A portable insulated cooler for prepared smoothies."
            ),
            Storage(
                id: StorageID(rawValue: "portable-electric-cooler"),
                name: "Portable Electric Cooler",
                smallIcon: .system("snowflake"),
                description: "A powered cooler for mobile beach service."
            ),
            Storage(
                id: StorageID(rawValue: "glass-door-beverage-refrigerator"),
                name: "Glass-Door Beverage Refrigerator",
                smallIcon: .system("refrigerator.fill"),
                description: "A commercial refrigerator with visible shelving."
            ),
            Storage(
                id: StorageID(rawValue: "dual-zone-refrigerated-cabinet"),
                name: "Dual-Zone Refrigerated Cabinet",
                smallIcon: .system("refrigerator.fill"),
                description: "A refrigerated cabinet with two cooling zones."
            ),
            Storage(
                id: StorageID(rawValue: "commercial-roll-in-refrigerator"),
                name: "Commercial Roll-In Refrigerator",
                smallIcon: .system("refrigerator.fill"),
                description: "A commercial refrigerator built for rolling racks."
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
