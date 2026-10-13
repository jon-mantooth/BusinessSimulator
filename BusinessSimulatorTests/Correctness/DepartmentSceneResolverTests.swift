import CoreGraphics
import Testing
@testable import BusinessSimulator

@MainActor
struct DepartmentSceneResolverTests {

    private struct TestSceneCatalog: SceneCatalog {
        let productDependentAssets: ProductDependentSceneAssets
        let replacementAssets: ReplacementSceneAssets
        let cumulativeAssets: CumulativeSceneAssets
    }

    private var catalog: TestSceneCatalog {
        TestSceneCatalog(
            productDependentAssets: [
                .pies: [asset(id: "product", layer: 200)]
            ],
            replacementAssets: [
                .pies: [
                    .primaryEquipment: [
                        1: asset(id: "replacement", layer: 100)
                    ]
                ]
            ],
            cumulativeAssets: [
                .pies: [
                    .secondaryEquipment: [
                        "owned-secondary": asset(
                            id: "owned-secondary",
                            layer: 200
                        ),
                        "unowned-secondary": asset(
                            id: "unowned-secondary",
                            layer: 300
                        )
                    ],
                    .labor: [
                        "owned-labor": asset(
                            id: "owned-labor",
                            layer: 300
                        )
                    ]
                ]
            ]
        )
    }

    @Test
    func productDependentAssetsUseRequestedProduct() {
        let pieLayers = resolve(productID: .pies)
        let hotDogLayers = resolve(productID: .hotDogs)

        #expect(assetIDs(in: pieLayers).contains("product"))
        #expect(!assetIDs(in: hotDogLayers).contains("product"))
    }

    @Test
    func replacementAssetsUseRequestedDimensionAndLevel() {
        let layers = resolve(
            replacementAssetLevels: [
                ReplacementSceneAssetLevel(
                    dimension: .primaryEquipment,
                    level: 1
                )
            ]
        )

        #expect(assetIDs(in: layers).contains("replacement"))
    }

    @Test
    func missingReplacementAssetIsOmitted() {
        let layers = resolve(
            replacementAssetLevels: [
                ReplacementSceneAssetLevel(
                    dimension: .primaryEquipment,
                    level: 2
                )
            ]
        )

        #expect(!assetIDs(in: layers).contains("replacement"))
    }

    @Test
    func cumulativeAssetsIncludeOwnedAndExcludeUnownedItems() {
        let layers = resolve(
            cumulativeAssetItems: [
                CumulativeSceneAssetItems(
                    dimension: .secondaryEquipment,
                    itemIDs: ["owned-secondary"]
                )
            ]
        )
        let ids = assetIDs(in: layers)

        #expect(ids.contains("owned-secondary"))
        #expect(!ids.contains("unowned-secondary"))
    }

    @Test
    func resolverCombinesAllAssetCategories() {
        let layers = resolve(
            replacementAssetLevels: [
                ReplacementSceneAssetLevel(
                    dimension: .primaryEquipment,
                    level: 1
                )
            ],
            cumulativeAssetItems: [
                CumulativeSceneAssetItems(
                    dimension: .labor,
                    itemIDs: ["owned-labor"]
                )
            ]
        )

        #expect(
            Set(assetIDs(in: layers)) == [
                "product",
                "replacement",
                "owned-labor"
            ]
        )
    }

    @Test
    func assetsWithMatchingLayerOrdersShareLayer() throws {
        let layers = resolve(
            cumulativeAssetItems: [
                CumulativeSceneAssetItems(
                    dimension: .secondaryEquipment,
                    itemIDs: ["owned-secondary"]
                )
            ]
        )
        let layer = try #require(
            layers.first { $0.layerOrder == 200 }
        )

        #expect(Set(layer.assets.map(\.id)) == ["product", "owned-secondary"])
    }

    @Test
    func layersAreReturnedInAscendingOrder() {
        let layers = resolve(
            replacementAssetLevels: [
                ReplacementSceneAssetLevel(
                    dimension: .primaryEquipment,
                    level: 1
                )
            ],
            cumulativeAssetItems: [
                CumulativeSceneAssetItems(
                    dimension: .labor,
                    itemIDs: ["owned-labor"]
                )
            ]
        )

        #expect(layers.map(\.layerOrder) == [100, 200, 300])
    }

    @Test
    func emptyCatalogAndInputsReturnNoLayers() {
        let emptyCatalog = TestSceneCatalog(
            productDependentAssets: [:],
            replacementAssets: [:],
            cumulativeAssets: [:]
        )

        let layers = DepartmentSceneResolver.assets(
            for: .pies,
            sceneCatalog: emptyCatalog,
            replacementAssetLevels: [],
            cumulativeAssetItems: []
        )

        #expect(layers.isEmpty)
    }

    @Test
    func departmentSelectsCorrespondingCatalog() {
        let request = [
            ReplacementSceneAssetLevel(
                dimension: .primaryEquipment,
                level: 0
            )
        ]

        let routedLayers = DepartmentSceneResolver.assets(
            for: .pies,
            department: .production,
            replacementAssetLevels: request,
            cumulativeAssetItems: []
        )
        let directLayers = DepartmentSceneResolver.assets(
            for: .pies,
            sceneCatalog: ProductionSceneCatalog(),
            replacementAssetLevels: request,
            cumulativeAssetItems: []
        )

        #expect(assetIDs(in: routedLayers) == assetIDs(in: directLayers))
    }

    private func resolve(
        productID: ProductID = .pies,
        replacementAssetLevels: [ReplacementSceneAssetLevel] = [],
        cumulativeAssetItems: [CumulativeSceneAssetItems] = []
    ) -> [DepartmentSceneLayer] {
        DepartmentSceneResolver.assets(
            for: productID,
            sceneCatalog: catalog,
            replacementAssetLevels: replacementAssetLevels,
            cumulativeAssetItems: cumulativeAssetItems
        )
    }

    private func asset(
        id: String,
        layer: Int
    ) -> DepartmentSceneAsset {
        DepartmentSceneAsset(
            id: id,
            imageName: id,
            type: .element(
                sourceWidth: 100,
                position: .zero
            ),
            layerOrder: layer
        )
    }

    private func assetIDs(
        in layers: [DepartmentSceneLayer]
    ) -> [String] {
        layers.flatMap(\.assets).map(\.id)
    }
}
