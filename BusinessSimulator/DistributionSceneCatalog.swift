import SwiftUI

struct DistributionSceneCatalog: SceneCatalog {
    let cumulativeAssets: CumulativeSceneAssets = [:]

    private let distributionBackground = DepartmentSceneAsset(
        id: "distribution-background",
        imageName: "distribution_background",
        type: .background,
        layerOrder: 0
    )

    var productDependentAssets: ProductDependentSceneAssets { [
        .pies: [distributionBackground],
        .hotDogs: [distributionBackground],
        .smoothies: [distributionBackground]
    ] }

    private let pieStorage0 = DepartmentSceneAsset(
        id: "pie_storage_0",
        imageName: "pie_storage_0",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 695, y: 905)
        ),
        layerOrder: 100
    )

    private let hotDogStorage0 = DepartmentSceneAsset(
        id: "hotdog_storage_0",
        imageName: "hotdog_storage_0",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 695, y: 905)
        ),
        layerOrder: 100
    )

    private let smoothieStorage0 = DepartmentSceneAsset(
        id: "smoothie_storage_0",
        imageName: "smoothie_storage_0",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 695, y: 905)
        ),
        layerOrder: 100
    )

    private let pieStorage1 = DepartmentSceneAsset(
        id: "pie_storage_1",
        imageName: "pie_storage_1",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 935)
        ),
        layerOrder: 100
    )

    private let hotDogStorage1 = DepartmentSceneAsset(
        id: "hotdog_storage_1",
        imageName: "hotdog_storage_1",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 935)
        ),
        layerOrder: 100
    )

    private let smoothieStorage1 = DepartmentSceneAsset(
        id: "smoothie_storage_1",
        imageName: "smoothie_storage_1",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 935)
        ),
        layerOrder: 100
    )

    private let pieStorage2 = DepartmentSceneAsset(
        id: "pie_storage_2",
        imageName: "pie_storage_2",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 935)
        ),
        layerOrder: 100
    )

    private let hotDogStorage2 = DepartmentSceneAsset(
        id: "hotdog_storage_2",
        imageName: "hotdog_storage_2",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 935)
        ),
        layerOrder: 100
    )

    private let smoothieStorage2 = DepartmentSceneAsset(
        id: "smoothie_storage_2",
        imageName: "smoothie_storage_2",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 935)
        ),
        layerOrder: 100
    )

    private let pieStorage3 = DepartmentSceneAsset(
        id: "pie_storage_3",
        imageName: "pie_storage_3",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 905)
        ),
        layerOrder: 100
    )

    private let hotDogStorage3 = DepartmentSceneAsset(
        id: "hotdog_storage_3",
        imageName: "hotdog_storage_3",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 905)
        ),
        layerOrder: 100
    )

    private let smoothieStorage3 = DepartmentSceneAsset(
        id: "smoothie_storage_3",
        imageName: "smoothie_storage_3",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 905)
        ),
        layerOrder: 100
    )

    private let pieStorage4 = DepartmentSceneAsset(
        id: "pie_storage_4",
        imageName: "pie_storage_4",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 905)
        ),
        layerOrder: 100
    )

    private let hotDogStorage4 = DepartmentSceneAsset(
        id: "hotdog_storage_4",
        imageName: "hotdog_storage_4",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 905)
        ),
        layerOrder: 100
    )

    private let smoothieStorage4 = DepartmentSceneAsset(
        id: "smoothie_storage_4",
        imageName: "smoothie_storage_4",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 905)
        ),
        layerOrder: 100
    )

    private let pieStorage5 = DepartmentSceneAsset(
        id: "pie_storage_5",
        imageName: "pie_storage_5",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 905)
        ),
        layerOrder: 100
    )

    private let hotDogStorage5 = DepartmentSceneAsset(
        id: "hotdog_storage_5",
        imageName: "hotdog_storage_5",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 905)
        ),
        layerOrder: 100
    )

    private let smoothieStorage5 = DepartmentSceneAsset(
        id: "smoothie_storage_5",
        imageName: "smoothie_storage_5",
        type: .element(
            sourceWidth: 120,
            position: CGPoint(x: 685, y: 905)
        ),
        layerOrder: 100
    )

    var replacementAssets: ReplacementSceneAssets { [
        .pies: [
            .storage: [
                0: pieStorage0,
                1: pieStorage1,
                2: pieStorage2,
                3: pieStorage3,
                4: pieStorage4,
                5: pieStorage5
            ]
        ],
        .hotDogs: [
            .storage: [
                0: hotDogStorage0,
                1: hotDogStorage1,
                2: hotDogStorage2,
                3: hotDogStorage3,
                4: hotDogStorage4,
                5: hotDogStorage5
            ]
        ],
        .smoothies: [
            .storage: [
                0: smoothieStorage0,
                1: smoothieStorage1,
                2: smoothieStorage2,
                3: smoothieStorage3,
                4: smoothieStorage4,
                5: smoothieStorage5
            ]
        ]
    ] }
}
