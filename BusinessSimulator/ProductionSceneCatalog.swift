import SwiftUI

struct ProductionSceneCatalog: SceneCatalog {
    private let genericProductionBackground = DepartmentSceneAsset(
        id: "generic-production-background",
        imageName: "production_background",
        type: .background,
        layerOrder: 0
    )

    private let pieOvenLevelZeroBackground = DepartmentSceneAsset(
        id: "pie-oven-level-zero-background",
        imageName: "oven_level_0",
        type: .background,
        layerOrder: 0
    )

    private let pieOvenLevelOneBackground = DepartmentSceneAsset(
        id: "pie-oven-level-one-background",
        imageName: "oven_level_1",
        type: .background,
        layerOrder: 0
    )

    private let pieOvenLevelTwoBackground = DepartmentSceneAsset(
        id: "pie-oven-level-two-background",
        imageName: "oven_level_2",
        type: .background,
        layerOrder: 0
    )

    private let pieOvenLevelThreeBackground = DepartmentSceneAsset(
        id: "pie-oven-level-three-background",
        imageName: "oven_level_3",
        type: .background,
        layerOrder: 0
    )

    private let pieOvenLevelFourBackground = DepartmentSceneAsset(
        id: "pie-oven-level-four-background",
        imageName: "oven_level_4",
        type: .background,
        layerOrder: 0
    )

    private let pieOvenLevelFiveBackground = DepartmentSceneAsset(
        id: "pie-oven-level-five-background",
        imageName: "oven_level_5",
        type: .background,
        layerOrder: 0
    )

    private let hotDogGrillLevelZeroBackground = DepartmentSceneAsset(
        id: "hot-dog-grill-level-zero-background",
        imageName: "grill_level_0",
        type: .background,
        layerOrder: 0
    )

    private let hotDogGrillLevelOneBackground = DepartmentSceneAsset(
        id: "hot-dog-grill-level-one-background",
        imageName: "grill_level_1",
        type: .background,
        layerOrder: 0
    )

    private let hotDogGrillLevelTwoBackground = DepartmentSceneAsset(
        id: "hot-dog-grill-level-two-background",
        imageName: "grill_level_2",
        type: .background,
        layerOrder: 0
    )

    private let hotDogGrillLevelThreeBackground = DepartmentSceneAsset(
        id: "hot-dog-grill-level-three-background",
        imageName: "grill_level_3",
        type: .background,
        layerOrder: 0
    )

    private let hotDogGrillLevelFourBackground = DepartmentSceneAsset(
        id: "hot-dog-grill-level-four-background",
        imageName: "grill_level_4",
        type: .background,
        layerOrder: 0
    )

    private let hotDogGrillLevelFiveBackground = DepartmentSceneAsset(
        id: "hot-dog-grill-level-five-background",
        imageName: "grill_level_5",
        type: .background,
        layerOrder: 0
    )

    private let pieCenterCounter = DepartmentSceneAsset(
        id: "pie-center-counter",
        imageName: "center_counter",
        type: .element(
            sourceWidth: 840,
            position: CGPoint(x: 425, y: 1_245)
        ),
        layerOrder: 400
    )

    private let hotDogCenterIsland = DepartmentSceneAsset(
        id: "hot-dog-center-island",
        imageName: "center_island_hotdogs",
        type: .element(
            sourceWidth: 840,
            position: CGPoint(x: 425, y: 1_245)
        ),
        layerOrder: 400
    )

    private let pieFoodProcessor = DepartmentSceneAsset(
        id: "pie-food-processor",
        imageName: "food_processor_asset",
        type: .element(
            sourceWidth: 77,
            position: CGPoint(x: 570, y: 470)
        ),
        layerOrder: 100
    )

    private let pieStandMixer = DepartmentSceneAsset(
        id: "pie-stand-mixer",
        imageName: "stand_mixer_asset",
        type: .element(
            sourceWidth: 85,
            position: CGPoint(x: 565, y: 375)
        ),
        layerOrder: 100
    )

    private let hotDogFoodProcessor = DepartmentSceneAsset(
        id: "hot-dog-food-processor",
        imageName: "food_processor_asset",
        type: .element(
            sourceWidth: 70,
            position: CGPoint(x: 650, y: 610)
        ),
        layerOrder: 100
    )

    private let hotDogProduceSlicer = DepartmentSceneAsset(
        id: "hot-dog-produce-slicer",
        imageName: "produce_slicer_asset",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 550, y: 1410)
        ),
        layerOrder: 500
    )

    private let hotDogPrepStation = DepartmentSceneAsset(
        id: "hot-dog-prep-station",
        imageName: "hotdog_prep_station_asset",
        type: .element(
            sourceWidth: 290,
            position: CGPoint(x: 640, y: 750)
        ),
        layerOrder: 100
    )

    private let hotDogMeatGrinder = DepartmentSceneAsset(
        id: "hot-dog-meat-grinder",
        imageName: "meat_grinder_asset",
        type: .element(
            sourceWidth: 170,
            position: CGPoint(x: 200, y: 1_080)
        ),
        layerOrder: 500
    )

    private let hotDogBreadMaker = DepartmentSceneAsset(
        id: "hot-dog-bread-maker",
        imageName: "bread_maker_asset",
        type: .element(
            sourceWidth: 170,
            position: CGPoint(x: 450, y: 1_080)
        ),
        layerOrder: 500
    )

    private let hotDogGrillMaster = DepartmentSceneAsset(
        id: "hot-dog-grill-master",
        imageName: "grill_master_asset",
        type: .element(
            sourceWidth: 320,
            position: CGPoint(x: 100, y: 800)
        ),
        layerOrder: 200
    )

    private let hotDogPrepSpecialist = DepartmentSceneAsset(
        id: "hot-dog-prep-specialist",
        imageName: "prep_specialist_asset",
        type: .element(
            sourceWidth: 220,
            position: CGPoint(x: 660, y: 800)
        ),
        layerOrder: 200
    )

    private let hotDogCleanupSpecialist = DepartmentSceneAsset(
        id: "hot-dog-cleanup-specialist",
        imageName: "cleanup_specialist_hotdog",
        type: .element(
            sourceWidth: 360,
            position: CGPoint(x: 700, y: 950)
        ),
        layerOrder: 300
    )

    private let hotDogLineCook = DepartmentSceneAsset(
        id: "hot-dog-line-cook",
        imageName: "line_cook_asset",
        type: .element(
            sourceWidth: 385,
            position: CGPoint(x: 475, y: 1_050)
        ),
        layerOrder: 300
    )

    private let piePrepStation = DepartmentSceneAsset(
        id: "pie-prep-station",
        imageName: "pie_prep_station_asset",
        type: .element(
            sourceWidth: 250,
            position: CGPoint(x: 400, y: 603)
        ),
        layerOrder: 100
    )

    private let pieDoughSheeter = DepartmentSceneAsset(
        id: "pie-dough-sheeter",
        imageName: "dough_sheeter_asset",
        type: .element(
            sourceWidth: 278,
            position: CGPoint(x: 674, y: 1_075)
        ),
        layerOrder: 500
    )

    private let pieAppleCorer = DepartmentSceneAsset(
        id: "pie-apple-corer",
        imageName: "apple_corer_asset",
        type: .element(
            sourceWidth: 180,
            position: CGPoint(x: 425, y: 1_305)
        ),
        layerOrder: 500
    )

    private let pieHeadChef = DepartmentSceneAsset(
        id: "pie-head-chef",
        imageName: "head_chef_asset",
        type: .element(
            sourceWidth: 500,
            position: CGPoint(x: 535, y: 1_050)
        ),
        layerOrder: 300
    )

    private let pieLineCook = DepartmentSceneAsset(
        id: "pie-line-cook",
        imageName: "line_cook_asset",
        type: .element(
            sourceWidth: 450,
            position: CGPoint(x: 300, y: 1_050)
        ),
        layerOrder: 300
    )

    private let piePrepSpecialist = DepartmentSceneAsset(
        id: "pie-prep-specialist",
        imageName: "prep_specialist_asset",
        type: .element(
            sourceWidth: 220,
            position: CGPoint(x: 400, y: 700)
        ),
        layerOrder: 200
    )

    private let pieCleanupSpecialist = DepartmentSceneAsset(
        id: "pie-cleanup-specialist",
        imageName: "clean_up_specialist_asset",
        type: .element(
            sourceWidth: 220,
            position: CGPoint(x: 625, y: 700)
        ),
        layerOrder: 200
    )

    /// Assets that always appear for a specific product whenever its Production
    /// scene is open, independent of the player's owned upgrades.
    var productDependentAssets: ProductDependentSceneAssets { [
        .pies: [pieCenterCounter],
        .hotDogs: [hotDogCenterIsland]
    ] }

    var replacementAssets: ReplacementSceneAssets { [
        .pies: [
            .primaryEquipment: [
                0: pieOvenLevelZeroBackground,
                1: pieOvenLevelOneBackground,
                2: pieOvenLevelTwoBackground,
                3: pieOvenLevelThreeBackground,
                4: pieOvenLevelFourBackground,
                5: pieOvenLevelFiveBackground
            ]
        ],
        .hotDogs: [
            .primaryEquipment: [
                0: hotDogGrillLevelZeroBackground,
                1: hotDogGrillLevelOneBackground,
                2: hotDogGrillLevelTwoBackground,
                3: hotDogGrillLevelThreeBackground,
                4: hotDogGrillLevelFourBackground,
                5: hotDogGrillLevelFiveBackground
            ]
        ],
        .smoothies: [
            .primaryEquipment: [
                0: genericProductionBackground,
                1: genericProductionBackground,
                2: genericProductionBackground,
                3: genericProductionBackground,
                4: genericProductionBackground,
                5: genericProductionBackground
            ]
        ]
    ] }

    var cumulativeAssets: CumulativeSceneAssets { [
        .pies: [
            .secondaryEquipment: [
                "food-processor": pieFoodProcessor,
                "stand-mixer": pieStandMixer,
                "pie-prep-station": piePrepStation,
                "dough-sheeter": pieDoughSheeter,
                "apple-corer": pieAppleCorer
            ],
            .labor: [
                "baker": pieHeadChef,
                "line-cook": pieLineCook,
                "prep-cook": piePrepSpecialist,
                "cleanup-worker": pieCleanupSpecialist
            ]
        ],
        .hotDogs: [
            .secondaryEquipment: [
                "food-processor": hotDogFoodProcessor,
                "produce-slicer": hotDogProduceSlicer,
                "hot-dog-prep-station": hotDogPrepStation,
                "meat-grinder": hotDogMeatGrinder,
                "bread-maker": hotDogBreadMaker
            ],
            .labor: [
                "grill-master": hotDogGrillMaster,
                "prep-cook": hotDogPrepSpecialist,
                "cleanup-worker": hotDogCleanupSpecialist,
                "line-cook": hotDogLineCook
            ]
        ]
    ] }
}
