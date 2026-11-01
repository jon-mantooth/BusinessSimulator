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

    private let pieCar = DepartmentSceneAsset(
        id: "pie-primary-transport-1",
        imageName: "pie_car",
        type: .element(
            sourceWidth: 455,
            position: CGPoint(x: 205, y: 955)
        ),
        layerOrder: 300
    )

    private let pieVan = DepartmentSceneAsset(
        id: "pie-primary-transport-2",
        imageName: "pie_van",
        type: .element(
            sourceWidth: 546,
            position: CGPoint(x: 205, y: 955)
        ),
        layerOrder: 300
    )

    private let pieTruck = DepartmentSceneAsset(
        id: "pie-primary-transport-3",
        imageName: "pie_truck",
        type: .element(
            sourceWidth: 546,
            position: CGPoint(x: 205, y: 955)
        ),
        layerOrder: 300
    )

    private let pieSecondaryTransport1 = DepartmentSceneAsset(
        id: "pie-secondary-transport-1",
        imageName: "pie_secondary_transport_1",
        type: .element(
            sourceWidth: 312,
            position: CGPoint(x: 532, y: 895)
        ),
        layerOrder: 200
    )

    private let pieSecondaryTransport2 = DepartmentSceneAsset(
        id: "pie-secondary-transport-2",
        imageName: "pie_secondary_transport_2",
        type: .element(
            sourceWidth: 312,
            position: CGPoint(x: 532, y: 895)
        ),
        layerOrder: 200
    )

    private let hotDogCar = DepartmentSceneAsset(
        id: "hotdog-primary-transport-1",
        imageName: "hotdog_car",
        type: .element(
            sourceWidth: 455,
            position: CGPoint(x: 205, y: 955)
        ),
        layerOrder: 300
    )

    private let hotDogVan = DepartmentSceneAsset(
        id: "hotdog-primary-transport-2",
        imageName: "hotdog_van",
        type: .element(
            sourceWidth: 546,
            position: CGPoint(x: 205, y: 955)
        ),
        layerOrder: 300
    )

    private let hotDogTruck = DepartmentSceneAsset(
        id: "hotdog-primary-transport-3",
        imageName: "hotdog_truck",
        type: .element(
            sourceWidth: 546,
            position: CGPoint(x: 205, y: 955)
        ),
        layerOrder: 300
    )

    private let hotDogSecondaryTransport1 = DepartmentSceneAsset(
        id: "hotdog-secondary-transport-1",
        imageName: "vendor_tray_1",
        type: .element(
            sourceWidth: 130,
            position: CGPoint(x: 532, y: 955)
        ),
        layerOrder: 200
    )

    private let hotDogSecondaryTransport2 = DepartmentSceneAsset(
        id: "hotdog-secondary-transport-2",
        imageName: "vendor_tray_2",
        type: .element(
            sourceWidth: 130,
            position: CGPoint(x: 532, y: 955)
        ),
        layerOrder: 200
    )

    private let smoothieCar = DepartmentSceneAsset(
        id: "smoothie-primary-transport-1",
        imageName: "smoothie_car",
        type: .element(
            sourceWidth: 455,
            position: CGPoint(x: 205, y: 955)
        ),
        layerOrder: 300
    )

    private let smoothieVan = DepartmentSceneAsset(
        id: "smoothie-primary-transport-2",
        imageName: "smoothie_van",
        type: .element(
            sourceWidth: 546,
            position: CGPoint(x: 205, y: 955)
        ),
        layerOrder: 300
    )

    private let smoothieTruck = DepartmentSceneAsset(
        id: "smoothie-primary-transport-3",
        imageName: "smoothie_truck",
        type: .element(
            sourceWidth: 546,
            position: CGPoint(x: 205, y: 955)
        ),
        layerOrder: 300
    )

    private let smoothieSecondaryTransport1 = DepartmentSceneAsset(
        id: "smoothie-secondary-transport-1",
        imageName: "smoothie_secondary_transport_1",
        type: .element(
            sourceWidth: 156,
            position: CGPoint(x: 532, y: 935)
        ),
        layerOrder: 200
    )

    private let smoothieSecondaryTransport2 = DepartmentSceneAsset(
        id: "smoothie-secondary-transport-2",
        imageName: "smoothie_secondary_transport_2",
        type: .element(
            sourceWidth: 156,
            position: CGPoint(x: 532, y: 935)
        ),
        layerOrder: 200
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
            ],
            .primaryTransport: [
                1: pieCar,
                2: pieVan,
                3: pieTruck
            ],
            .secondaryTransport: [
                1: pieSecondaryTransport1,
                2: pieSecondaryTransport2
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
            ],
            .primaryTransport: [
                1: hotDogCar,
                2: hotDogVan,
                3: hotDogTruck
            ],
            .secondaryTransport: [
                1: hotDogSecondaryTransport1,
                2: hotDogSecondaryTransport2
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
            ],
            .primaryTransport: [
                1: smoothieCar,
                2: smoothieVan,
                3: smoothieTruck
            ],
            .secondaryTransport: [
                1: smoothieSecondaryTransport1,
                2: smoothieSecondaryTransport2
            ]
        ]
    ] }
}
