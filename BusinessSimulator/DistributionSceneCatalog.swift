import SwiftUI

enum DistributionSceneCatalog {
    private static let pieStorage0 = DepartmentSceneAsset(
        imageName: "pie_storage_0",
        sourceWidth: 120,
        position: CGPoint(x: 695, y: 905),
        layerOrder: 100
    )

    private static let hotDogStorage0 = DepartmentSceneAsset(
        imageName: "hotdog_storage_0",
        sourceWidth: 120,
        position: CGPoint(x: 695, y: 905),
        layerOrder: 100
    )

    private static let smoothieStorage0 = DepartmentSceneAsset(
        imageName: "smoothie_storage_0",
        sourceWidth: 120,
        position: CGPoint(x: 695, y: 905),
        layerOrder: 100
    )

    private static let pieStorage1 = DepartmentSceneAsset(
        imageName: "pie_storage_1",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 935),
        layerOrder: 100
    )

    private static let hotDogStorage1 = DepartmentSceneAsset(
        imageName: "hotdog_storage_1",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 935),
        layerOrder: 100
    )

    private static let smoothieStorage1 = DepartmentSceneAsset(
        imageName: "smoothie_storage_1",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 935),
        layerOrder: 100
    )

    private static let pieStorage2 = DepartmentSceneAsset(
        imageName: "pie_storage_2",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 935),
        layerOrder: 100
    )

    private static let hotDogStorage2 = DepartmentSceneAsset(
        imageName: "hotdog_storage_2",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 935),
        layerOrder: 100
    )

    private static let smoothieStorage2 = DepartmentSceneAsset(
        imageName: "smoothie_storage_2",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 935),
        layerOrder: 100
    )

    private static let pieStorage3 = DepartmentSceneAsset(
        imageName: "pie_storage_3",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 905),
        layerOrder: 100
    )

    private static let hotDogStorage3 = DepartmentSceneAsset(
        imageName: "hotdog_storage_3",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 905),
        layerOrder: 100
    )

    private static let smoothieStorage3 = DepartmentSceneAsset(
        imageName: "smoothie_storage_3",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 905),
        layerOrder: 100
    )

    private static let pieStorage4 = DepartmentSceneAsset(
        imageName: "pie_storage_4",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 905),
        layerOrder: 100
    )

    private static let hotDogStorage4 = DepartmentSceneAsset(
        imageName: "hotdog_storage_4",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 905),
        layerOrder: 100
    )

    private static let smoothieStorage4 = DepartmentSceneAsset(
        imageName: "smoothie_storage_4",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 905),
        layerOrder: 100
    )

    private static let pieStorage5 = DepartmentSceneAsset(
        imageName: "pie_storage_5",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 905),
        layerOrder: 100
    )

    private static let hotDogStorage5 = DepartmentSceneAsset(
        imageName: "hotdog_storage_5",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 905),
        layerOrder: 100
    )

    private static let smoothieStorage5 = DepartmentSceneAsset(
        imageName: "smoothie_storage_5",
        sourceWidth: 120,
        position: CGPoint(x: 685, y: 905),
        layerOrder: 100
    )

    static let assets: SceneAssetsByDimension = [
        .storage: [
            .pies: [
                0: pieStorage0,
                1: pieStorage1,
                2: pieStorage2,
                3: pieStorage3,
                4: pieStorage4,
                5: pieStorage5
            ],
            .hotDogs: [
                0: hotDogStorage0,
                1: hotDogStorage1,
                2: hotDogStorage2,
                3: hotDogStorage3,
                4: hotDogStorage4,
                5: hotDogStorage5
            ],
            .smoothies: [
                0: smoothieStorage0,
                1: smoothieStorage1,
                2: smoothieStorage2,
                3: smoothieStorage3,
                4: smoothieStorage4,
                5: smoothieStorage5
            ]
        ]
    ]
}
