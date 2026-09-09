import Foundation

// BALANCE-DEPENDENT: Manually maintained fields in this catalog:
// - Secondary Equipment.price
// - Secondary Equipment.capacity

struct EquipmentCatalog {
    let basicHomeOven: Equipment
    let doubleRangeOven: Equipment
    let convectionOven: Equipment
    let doubleConvectionOven: Equipment
    let commercialDeckOven: Equipment
    let commercialRackOven: Equipment
    let appleCorer: Equipment
    let standMixer: Equipment
    let foodProcessor: Equipment
    let doughSheeter: Equipment
    let piePrepStation: Equipment
    let smallCharcoalGrill: Equipment
    let largeCharcoalGrill: Equipment
    let smallGasGrill: Equipment
    let largeGasGrill: Equipment
    let commercialFlatTop: Equipment
    let commercialGrillStation: Equipment
    let produceSlicer: Equipment
    let breadMaker: Equipment
    let meatGrinder: Equipment
    let hotDogPrepStation: Equipment
    let handMixer: Equipment
    let basicBlender: Equipment
    let highPowerBlender: Equipment
    let professionalBlender: Equipment
    let commercialBlendingStation: Equipment
    let highCapacityCommercialBlendingStation: Equipment
    let vacuumSealer: Equipment
    let iceCrusher: Equipment
    let produceCooler: Equipment

    func secondaryEquipment(
        for product: Product
    ) -> SecondaryEquipmentCollection {
        let equipment: [Equipment]

        switch product.id {
        case .pies:
            equipment = [
                appleCorer,
                standMixer,
                foodProcessor,
                doughSheeter,
                piePrepStation
            ]
        case .hotDogs:
            equipment = [
                produceSlicer,
                foodProcessor,
                breadMaker,
                meatGrinder,
                hotDogPrepStation
            ]
        case .smoothies:
            equipment = [
                foodProcessor,
                produceSlicer,
                vacuumSealer,
                iceCrusher,
                produceCooler
            ]
        }

        return SecondaryEquipmentCollection(
            equipment: equipment.map { equipment in
                guard case let .secondary(capacityStrength, _) =
                    equipment.category else {
                    preconditionFailure(
                        "Secondary equipment catalogs can contain only secondary equipment."
                    )
                }

                var configuredEquipment = equipment
                configuredEquipment.capacity = capacityStrength.capacity(
                    for: product.idealUnitsSold
                )
                return configuredEquipment
            }
        )
    }

    func primaryTiers(
        for product: Product
    ) -> [EquipmentTier] {
        let primaryEquipment: [Equipment]

        switch product.id {
        case .pies:
            primaryEquipment = [
                basicHomeOven,
                doubleRangeOven,
                convectionOven,
                doubleConvectionOven,
                commercialDeckOven,
                commercialRackOven
            ]
        case .hotDogs:
            primaryEquipment = [
                smallCharcoalGrill,
                largeCharcoalGrill,
                smallGasGrill,
                largeGasGrill,
                commercialFlatTop,
                commercialGrillStation
            ]
        case .smoothies:
            primaryEquipment = [
                handMixer,
                basicBlender,
                highPowerBlender,
                professionalBlender,
                commercialBlendingStation,
                highCapacityCommercialBlendingStation
            ]
        }

        return primaryEquipment.enumerated().map { level, equipment in
            EquipmentTier(
                id: EquipmentTierID(
                    rawValue: "\(product.id.rawValue)-tier-\(level)"
                ),
                level: level,
                equipment: [equipment],
                product: product
            )
        }
    }

    init() {
        basicHomeOven = Equipment(
            id: EquipmentID(rawValue: "basic-home-oven"),
            name: "Basic Home Oven",
            smallIcon: .system("oven.fill"),
            description: "A dependable household oven with enough capacity to get your pie business started.",
            category: .primary,
            demandLevel: 0,
            totalLevels: 3
        )

        doubleRangeOven = Equipment(
            id: EquipmentID(rawValue: "double-range-oven"),
            name: "Double Range Oven",
            smallIcon: .system("oven.fill"),
            description: "A double-oven range that lets you bake more pies at the same time.",
            category: .primary,
            demandLevel: 1,
            totalLevels: 3
        )

        convectionOven = Equipment(
            id: EquipmentID(rawValue: "convection-oven"),
            name: "Convection Oven",
            smallIcon: .system("oven.fill"),
            description: "Circulating heat delivers faster, more consistent bakes with evenly browned crusts.",
            category: .primary,
            demandLevel: 2,
            totalLevels: 3
        )

        doubleConvectionOven = Equipment(
            id: EquipmentID(rawValue: "double-convection-oven"),
            name: "Double Convection Oven",
            smallIcon: .system("oven.fill"),
            description: "Dual convection chambers expand production while preserving an even, reliable bake.",
            category: .primary,
            demandLevel: 2,
            totalLevels: 3
        )

        commercialDeckOven = Equipment(
            id: EquipmentID(rawValue: "commercial-deck-oven"),
            name: "Commercial Deck Oven",
            smallIcon: .system("oven.fill"),
            description: "A professional deck oven built for high-volume production and consistently crisp crusts.",
            category: .primary,
            demandLevel: 3,
            totalLevels: 3
        )

        commercialRackOven = Equipment(
            id: EquipmentID(rawValue: "commercial-rack-oven"),
            name: "Commercial Rack Oven",
            smallIcon: .system("oven.fill"),
            description: "A high-capacity rotating rack oven designed for efficient, uniform commercial baking.",
            category: .primary,
            demandLevel: 3,
            totalLevels: 3
        )

        appleCorer = Equipment(
            id: EquipmentID(rawValue: "apple-corer"),
            name: "Apple Corer",
            smallIcon: .emoji("🍎"),
            description: "Core apples quickly and keep pie preparation moving smoothly.",
            category: .secondary(
                capacityStrength: .medium,
                ingredientUpgradeID: nil
            ),
            demandLevel: 1,
            capacity: 2
        )

        standMixer = Equipment(
            id: EquipmentID(rawValue: "stand-mixer"),
            name: "Stand Mixer",
            smallIcon: .system("dial.medium.fill"),
            description: "Mix dough and fillings consistently while freeing time for other preparation work.",
            category: .secondary(
                capacityStrength: .medium,
                ingredientUpgradeID: nil
            ),
            demandLevel: 1,
            capacity: 2
        )

        foodProcessor = Equipment(
            id: EquipmentID(rawValue: "food-processor"),
            name: "Food Processor",
            smallIcon: .system("gearshape.2.fill"),
            description: "Speed up repetitive preparation tasks and produce more consistent ingredients.",
            category: .secondary(
                capacityStrength: .medium,
                ingredientUpgradeID: nil
            ),
            demandLevel: 1,
            capacity: 2
        )

        doughSheeter = Equipment(
            id: EquipmentID(rawValue: "dough-sheeter"),
            name: "Dough Sheeter",
            smallIcon: .system("rectangle.compress.vertical"),
            description: "Roll uniform sheets of dough quickly for dependable crust thickness and texture.",
            category: .secondary(
                capacityStrength: .medium,
                ingredientUpgradeID: nil
            ),
            demandLevel: 1,
            capacity: 2
        )

        piePrepStation = Equipment(
            id: EquipmentID(rawValue: "pie-prep-station"),
            name: "Pie Prep Station",
            smallIcon: .system("table.furniture.fill"),
            description: "Organize ingredients and tools in a dedicated workspace built for efficient pie assembly.",
            category: .secondary(
                capacityStrength: .medium,
                ingredientUpgradeID: nil
            ),
            demandLevel: 1,
            capacity: 2
        )

        smallCharcoalGrill = Equipment(
            id: EquipmentID(rawValue: "small-charcoal-grill"),
            name: "Small Charcoal Grill",
            smallIcon: .system("flame.fill"),
            description: "A compact charcoal grill with enough cooking space to get your hot dog business started.",
            category: .primary,
            demandLevel: 0,
            totalLevels: 3
        )

        largeCharcoalGrill = Equipment(
            id: EquipmentID(rawValue: "large-charcoal-grill"),
            name: "Large Charcoal Grill",
            smallIcon: .system("flame.fill"),
            description: "A roomier charcoal grill that cooks more hot dogs while preserving a classic grilled flavor.",
            category: .primary,
            demandLevel: 1,
            totalLevels: 3
        )

        smallGasGrill = Equipment(
            id: EquipmentID(rawValue: "small-gas-grill"),
            name: "Small Gas Grill",
            smallIcon: .system("flame.fill"),
            description: "A compact gas grill offering faster heat-up times and dependable temperature control.",
            category: .primary,
            demandLevel: 2,
            totalLevels: 3
        )

        largeGasGrill = Equipment(
            id: EquipmentID(rawValue: "large-gas-grill"),
            name: "Large Gas Grill",
            smallIcon: .system("flame.fill"),
            description: "A high-capacity gas grill that handles larger crowds with steady, even cooking.",
            category: .primary,
            demandLevel: 2,
            totalLevels: 3
        )

        commercialFlatTop = Equipment(
            id: EquipmentID(rawValue: "commercial-flat-top"),
            name: "Commercial Flat Top",
            smallIcon: .system("flame.fill"),
            description: "A professional flat-top griddle built for quick service and consistently cooked hot dogs.",
            category: .primary,
            demandLevel: 3,
            totalLevels: 3
        )

        commercialGrillStation = Equipment(
            id: EquipmentID(rawValue: "commercial-grill-station"),
            name: "Commercial Grill Station",
            smallIcon: .system("flame.fill"),
            description: "A complete commercial grilling station designed for continuous, high-volume production.",
            category: .primary,
            demandLevel: 3,
            totalLevels: 3
        )

        produceSlicer = Equipment(
            id: EquipmentID(rawValue: "produce-slicer"),
            name: "Produce Slicer",
            smallIcon: .system("square.grid.3x3.fill"),
            description: "Slice fruits, vegetables, and toppings quickly for consistent portions and faster preparation.",
            category: .secondary(
                capacityStrength: .medium,
                ingredientUpgradeID: nil
            ),
            demandLevel: 1,
            capacity: 2
        )

        breadMaker = Equipment(
            id: EquipmentID(rawValue: "bread-maker"),
            name: "Bread Maker",
            smallIcon: .system("takeoutbag.and.cup.and.straw.fill"),
            description: "Prepare fresh, consistent buns in-house while streamlining the bread-making process.",
            category: .secondary(
                capacityStrength: .medium,
                ingredientUpgradeID: nil
            ),
            demandLevel: 1,
            capacity: 2
        )

        meatGrinder = Equipment(
            id: EquipmentID(rawValue: "meat-grinder"),
            name: "Meat Grinder",
            smallIcon: .system("gearshape.fill"),
            description: "Grind and prepare custom hot dog blends for better control over flavor and production.",
            category: .secondary(
                capacityStrength: .medium,
                ingredientUpgradeID: nil
            ),
            demandLevel: 1,
            capacity: 2
        )

        hotDogPrepStation = Equipment(
            id: EquipmentID(rawValue: "hot-dog-prep-station"),
            name: "Hot Dog Prep Station",
            smallIcon: .system("table.furniture.fill"),
            description: "Keep buns, toppings, and tools organized in a dedicated station built for fast assembly.",
            category: .secondary(
                capacityStrength: .medium,
                ingredientUpgradeID: nil
            ),
            demandLevel: 1,
            capacity: 2
        )

        handMixer = Equipment(
            id: EquipmentID(rawValue: "hand-mixer"),
            name: "Hand Mixer",
            smallIcon: .system("dial.medium.fill"),
            description: "A simple handheld mixer with enough output to get your smoothie business started.",
            category: .primary,
            demandLevel: 0,
            totalLevels: 3
        )

        basicBlender = Equipment(
            id: EquipmentID(rawValue: "basic-blender"),
            name: "Basic Blender",
            smallIcon: .system("dial.medium.fill"),
            description: "A dependable countertop blender that improves speed and smoothie consistency.",
            category: .primary,
            demandLevel: 1,
            totalLevels: 3
        )

        highPowerBlender = Equipment(
            id: EquipmentID(rawValue: "high-power-blender"),
            name: "High-Power Blender",
            smallIcon: .system("dial.medium.fill"),
            description: "A powerful blender that handles tougher ingredients and larger workloads with ease.",
            category: .primary,
            demandLevel: 1,
            totalLevels: 3
        )

        professionalBlender = Equipment(
            id: EquipmentID(rawValue: "professional-blender"),
            name: "Professional Blender",
            smallIcon: .system("dial.medium.fill"),
            description: "A professional-grade blender delivering smoother texture and dependable performance.",
            category: .primary,
            demandLevel: 2,
            totalLevels: 3
        )

        commercialBlendingStation = Equipment(
            id: EquipmentID(rawValue: "commercial-blending-station"),
            name: "Commercial Blending Station",
            smallIcon: .system("dial.medium.fill"),
            description: "A commercial workstation designed for fast, consistent, high-volume smoothie production.",
            category: .primary,
            demandLevel: 3,
            totalLevels: 3
        )

        highCapacityCommercialBlendingStation = Equipment(
            id: EquipmentID(
                rawValue: "high-capacity-commercial-blending-station"
            ),
            name: "High-Capacity Commercial Blending Station",
            smallIcon: .system("dial.medium.fill"),
            description: "A multi-blender commercial station built to serve the largest crowds without slowing down.",
            category: .primary,
            demandLevel: 3,
            totalLevels: 3
        )

        vacuumSealer = Equipment(
            id: EquipmentID(rawValue: "vacuum-sealer"),
            name: "Vacuum Sealer",
            smallIcon: .system("shippingbox.fill"),
            description: "Seal prepared ingredients against air to preserve their quality and freshness longer.",
            category: .secondary(
                capacityStrength: .medium,
                ingredientUpgradeID: nil
            ),
            demandLevel: 1,
            capacity: 2
        )

        iceCrusher = Equipment(
            id: EquipmentID(rawValue: "ice-crusher"),
            name: "Ice Crusher",
            smallIcon: .system("snowflake"),
            description: "Crush ice quickly and consistently for smoother drinks and faster preparation.",
            category: .secondary(
                capacityStrength: .medium,
                ingredientUpgradeID: nil
            ),
            demandLevel: 1,
            capacity: 2
        )

        produceCooler = Equipment(
            id: EquipmentID(rawValue: "produce-cooler"),
            name: "Produce Cooler",
            smallIcon: .system("refrigerator.fill"),
            description: "Keep fruit and other perishable ingredients chilled, organized, and ready for service.",
            category: .secondary(
                capacityStrength: .medium,
                ingredientUpgradeID: nil
            ),
            demandLevel: 1,
            capacity: 2
        )
    }
}
