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

    private let pieCenterCounter = DepartmentSceneAsset(
        id: "pie-center-counter",
        imageName: "center_counter",
        type: .element(
            sourceWidth: 840,
            position: CGPoint(x: 425, y: 1_145)
        ),
        layerOrder: 100
    )

    /// Assets that always appear for a specific product whenever its Production
    /// scene is open, independent of the player's owned upgrades.
    var productDependentAssets: ProductDependentSceneAssets { [
        .pies: [pieCenterCounter]
    ] }

    var replacementAssets: ReplacementSceneAssets { [
        .pies: [
            .primaryEquipment: [
                0: pieOvenLevelZeroBackground,
                1: pieOvenLevelOneBackground,
                2: pieOvenLevelOneBackground,
                3: pieOvenLevelOneBackground,
                4: pieOvenLevelOneBackground,
                5: pieOvenLevelOneBackground
            ]
        ],
        .hotDogs: [
            .primaryEquipment: [
                0: genericProductionBackground,
                1: genericProductionBackground,
                2: genericProductionBackground,
                3: genericProductionBackground,
                4: genericProductionBackground,
                5: genericProductionBackground
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

    /// Cumulative production assets will be added here as secondary equipment
    /// and labor scene elements are created.
    let cumulativeAssets: CumulativeSceneAssets = [:]
}
