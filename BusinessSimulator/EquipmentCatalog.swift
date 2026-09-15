import Foundation

// BALANCE-DEPENDENT: Manually maintained fields in this catalog:
// - Secondary Equipment.price
// - Secondary Equipment.capacityStrength

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
                guard case let .secondary(capacityStrength) =
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
            smallIcon: .asset("tier0_oven"),
            description: "A dependable household oven with enough capacity to get your pie business started.",
            category: .primary,
            demandLevel: 0,
            totalLevels: 3
        )

        doubleRangeOven = Equipment(
            id: EquipmentID(rawValue: "double-range-oven"),
            name: "Double Range Oven",
            smallIcon: .asset("tier1_oven"),
            description: "A double-oven range that lets you bake more pies at the same time.",
            category: .primary,
            demandLevel: 1,
            totalLevels: 3
        )

        convectionOven = Equipment(
            id: EquipmentID(rawValue: "convection-oven"),
            name: "Convection Oven",
            smallIcon: .asset("tier2_oven"),
            description: "Circulating heat delivers faster, more consistent bakes with evenly browned crusts.",
            category: .primary,
            demandLevel: 2,
            totalLevels: 3
        )

        doubleConvectionOven = Equipment(
            id: EquipmentID(rawValue: "double-convection-oven"),
            name: "Double Convection Oven",
            smallIcon: .asset("tier3_oven"),
            description: "Dual convection chambers expand production while preserving an even, reliable bake.",
            category: .primary,
            demandLevel: 2,
            totalLevels: 3
        )

        commercialDeckOven = Equipment(
            id: EquipmentID(rawValue: "commercial-deck-oven"),
            name: "Commercial Deck Oven",
            smallIcon: .asset("tier4_oven"),
            description: "A professional deck oven built for high-volume production and consistently crisp crusts.",
            category: .primary,
            demandLevel: 3,
            totalLevels: 3
        )

        commercialRackOven = Equipment(
            id: EquipmentID(rawValue: "commercial-rack-oven"),
            name: "Commercial Rack Oven",
            smallIcon: .asset("tier5_oven"),
            description: "A high-capacity rotating rack oven designed for efficient, uniform commercial baking.",
            category: .primary,
            demandLevel: 3,
            totalLevels: 3
        )

        appleCorer = Equipment(
            id: EquipmentID(rawValue: "apple-corer"),
            name: "Apple Corer",
            smallIcon: .asset("apple_corer"),
            description: "Core apples quickly and keep pie preparation moving smoothly.",
            price: 99,
            category: .secondary(
                capacityStrength: .low
            ),
            ingredientUpgrade: IngredientUpgrade(
                effect: .recipeAmount,
                ingredientID: .apple,
                description: "Uses more of each apple, reducing the number needed for every pie."
            ),
            demandLevel: 1
        )

        standMixer = Equipment(
            id: EquipmentID(rawValue: "stand-mixer"),
            name: "Stand Mixer",
            smallIcon: .asset("stand_mixer"),
            description: "Mix dough and fillings consistently while freeing time for other preparation work.",
            price: 349,
            category: .secondary(
                capacityStrength: .medium
            ),
            ingredientUpgrade: IngredientUpgrade(
                effect: .recipeAmount,
                ingredientID: .butter,
                description: "Mixes dough more efficiently, reducing the butter needed for every pie."
            ),
            demandLevel: 1
        )

        foodProcessor = Equipment(
            id: EquipmentID(rawValue: "food-processor"),
            name: "Food Processor",
            smallIcon: .asset("food_processor"),
            description: "Speed up repetitive preparation tasks and produce more consistent ingredients.",
            price: 249,
            category: .secondary(
                capacityStrength: .medium
            ),
            demandLevel: 1
        )

        doughSheeter = Equipment(
            id: EquipmentID(rawValue: "dough-sheeter"),
            name: "Dough Sheeter",
            smallIcon: .asset("dough_sheeter"),
            description: "Roll uniform sheets of dough quickly for dependable crust thickness and texture.",
            price: 499,
            category: .secondary(
                capacityStrength: .high
            ),
            ingredientUpgrade: IngredientUpgrade(
                effect: .recipeAmount,
                ingredientID: .flour,
                description: "Rolls dough evenly, reducing the flour needed for every pie."
            ),
            demandLevel: 1
        )

        piePrepStation = Equipment(
            id: EquipmentID(rawValue: "pie-prep-station"),
            name: "Pie Prep Station",
            smallIcon: .asset("pie_prep_station"),
            description: "Organize ingredients and tools in a dedicated workspace built for efficient pie assembly.",
            price: 699,
            category: .secondary(
                capacityStrength: .high
            ),
            demandLevel: 1
        )

        smallCharcoalGrill = Equipment(
            id: EquipmentID(rawValue: "small-charcoal-grill"),
            name: "Small Charcoal Grill",
            smallIcon: .asset("tier0_grill"),
            description: "A compact charcoal grill with enough cooking space to get your hot dog business started.",
            category: .primary,
            demandLevel: 0,
            totalLevels: 3
        )

        largeCharcoalGrill = Equipment(
            id: EquipmentID(rawValue: "large-charcoal-grill"),
            name: "Large Charcoal Grill",
            smallIcon: .asset("tier1_grill"),
            description: "A roomier charcoal grill that cooks more hot dogs while preserving a classic grilled flavor.",
            category: .primary,
            demandLevel: 1,
            totalLevels: 3
        )

        smallGasGrill = Equipment(
            id: EquipmentID(rawValue: "small-gas-grill"),
            name: "Small Gas Grill",
            smallIcon: .asset("tier2_grill"),
            description: "A compact gas grill offering faster heat-up times and dependable temperature control.",
            category: .primary,
            demandLevel: 2,
            totalLevels: 3
        )

        largeGasGrill = Equipment(
            id: EquipmentID(rawValue: "large-gas-grill"),
            name: "Large Gas Grill",
            smallIcon: .asset("tier3_grill"),
            description: "A high-capacity gas grill that handles larger crowds with steady, even cooking.",
            category: .primary,
            demandLevel: 2,
            totalLevels: 3
        )

        commercialFlatTop = Equipment(
            id: EquipmentID(rawValue: "commercial-flat-top"),
            name: "Commercial Flat Top",
            smallIcon: .asset("tier4_grill"),
            description: "A professional flat-top griddle built for quick service and consistently cooked hot dogs.",
            category: .primary,
            demandLevel: 3,
            totalLevels: 3
        )

        commercialGrillStation = Equipment(
            id: EquipmentID(rawValue: "commercial-grill-station"),
            name: "Commercial Grill Station",
            smallIcon: .asset("tier5_grill"),
            description: "A complete commercial grilling station designed for continuous, high-volume production.",
            category: .primary,
            demandLevel: 3,
            totalLevels: 3
        )

        produceSlicer = Equipment(
            id: EquipmentID(rawValue: "produce-slicer"),
            name: "Produce Slicer",
            smallIcon: .asset("produce_slicer"),
            description: "Slice fruits, vegetables, and toppings quickly for consistent portions and faster preparation.",
            price: 99,
            category: .secondary(
                capacityStrength: .low
            ),
            demandLevel: 1
        )

        breadMaker = Equipment(
            id: EquipmentID(rawValue: "bread-maker"),
            name: "Bread Maker",
            smallIcon: .asset("bread_maker"),
            description: "Prepare fresh, consistent buns in-house while streamlining the bread-making process.",
            price: 349,
            category: .secondary(
                capacityStrength: .medium
            ),
            ingredientUpgrade: IngredientUpgrade(
                effect: .ingredientReplacement,
                ingredientID: .bun,
                description: "Replaces purchased buns with ingredients for making fresh buns in-house."
            ),
            demandLevel: 1
        )

        meatGrinder = Equipment(
            id: EquipmentID(rawValue: "meat-grinder"),
            name: "Meat Grinder",
            smallIcon: .asset("meat_grinder"),
            description: "Grind and prepare custom hot dog blends for better control over flavor and production.",
            price: 499,
            category: .secondary(
                capacityStrength: .medium
            ),
            ingredientUpgrade: IngredientUpgrade(
                effect: .ingredientReplacement,
                ingredientID: .hotDog,
                description: "Replaces purchased hot dogs with ingredients for producing a custom blend in-house."
            ),
            demandLevel: 1
        )

        hotDogPrepStation = Equipment(
            id: EquipmentID(rawValue: "hot-dog-prep-station"),
            name: "Hot Dog Prep Station",
            smallIcon: .asset("hotdog_prep_station"),
            description: "Keep buns, toppings, and tools organized in a dedicated station built for fast assembly.",
            price: 699,
            category: .secondary(
                capacityStrength: .high
            ),
            demandLevel: 1
        )

        handMixer = Equipment(
            id: EquipmentID(rawValue: "hand-mixer"),
            name: "Hand Mixer",
            smallIcon: .asset("tier0_blender"),
            description: "A simple handheld mixer with enough output to get your smoothie business started.",
            category: .primary,
            demandLevel: 0,
            totalLevels: 3
        )

        basicBlender = Equipment(
            id: EquipmentID(rawValue: "basic-blender"),
            name: "Basic Blender",
            smallIcon: .asset("tier1_blender"),
            description: "A dependable countertop blender that improves speed and smoothie consistency.",
            category: .primary,
            demandLevel: 1,
            totalLevels: 3
        )

        highPowerBlender = Equipment(
            id: EquipmentID(rawValue: "high-power-blender"),
            name: "High-Power Blender",
            smallIcon: .asset("tier2_blender"),
            description: "A powerful blender that handles tougher ingredients and larger workloads with ease.",
            category: .primary,
            demandLevel: 1,
            totalLevels: 3
        )

        professionalBlender = Equipment(
            id: EquipmentID(rawValue: "professional-blender"),
            name: "Professional Blender",
            smallIcon: .asset("tier3_blender"),
            description: "A professional-grade blender delivering smoother texture and dependable performance.",
            category: .primary,
            demandLevel: 2,
            totalLevels: 3
        )

        commercialBlendingStation = Equipment(
            id: EquipmentID(rawValue: "commercial-blending-station"),
            name: "Commercial Blending Station",
            smallIcon: .asset("tier4_blender"),
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
            smallIcon: .asset("tier5_blender"),
            description: "A multi-blender commercial station built to serve the largest crowds without slowing down.",
            category: .primary,
            demandLevel: 3,
            totalLevels: 3
        )

        vacuumSealer = Equipment(
            id: EquipmentID(rawValue: "vacuum-sealer"),
            name: "Vacuum Sealer",
            smallIcon: .asset("vacuum_sealer"),
            description: "Seal prepared ingredients against air to preserve their quality and freshness longer.",
            price: 349,
            category: .secondary(
                capacityStrength: .medium
            ),
            ingredientUpgrade: IngredientUpgrade(
                effect: .lifespan,
                ingredientID: .strawberry,
                description: "Keeps strawberries fresh longer by protecting them from air."
            ),
            demandLevel: 1
        )

        iceCrusher = Equipment(
            id: EquipmentID(rawValue: "ice-crusher"),
            name: "Ice Crusher",
            smallIcon: .asset("ice_crusher"),
            description: "Crush ice quickly and consistently for smoother drinks and faster preparation.",
            price: 499,
            category: .secondary(
                capacityStrength: .high
            ),
            demandLevel: 1
        )

        produceCooler = Equipment(
            id: EquipmentID(rawValue: "produce-cooler"),
            name: "Produce Cooler",
            smallIcon: .asset("produce_cooler"),
            description: "Keep fruit and other perishable ingredients chilled, organized, and ready for service.",
            price: 699,
            category: .secondary(
                capacityStrength: .medium
            ),
            ingredientUpgrade: IngredientUpgrade(
                effect: .lifespan,
                ingredientID: .milk,
                description: "Keeps milk properly chilled so it remains fresh longer."
            ),
            demandLevel: 1
        )
    }
}
