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

    @Test
    func productionCatalogProvidesOneBackgroundForEveryPrimaryLevel() throws {
        let productIDs: [ProductID] = [.pies, .hotDogs, .smoothies]

        for productID in productIDs {
            for level in 0...5 {
                let layers = DepartmentSceneResolver.assets(
                    for: productID,
                    sceneCatalog: ProductionSceneCatalog(),
                    replacementAssetLevels: [
                        ReplacementSceneAssetLevel(
                            dimension: .primaryEquipment,
                            level: level
                        )
                    ],
                    cumulativeAssetItems: []
                )
                let backgroundLayer = try #require(
                    layers.first { $0.layerOrder == 0 }
                )

                #expect(backgroundLayer.assets.count == 1)

                let background = try #require(backgroundLayer.assets.first)
                guard case .background = background.type else {
                    Issue.record(
                        "Expected a background for \(productID) level \(level)."
                    )
                    continue
                }
            }
        }
    }

    // MARK: - Marketing Scene

    @Test
    func everyPurchasableAdvertisementHasApplicableMarketingSceneAsset() throws {
        let sceneCatalog = MarketingSceneCatalog()

        for productID in productIDs {
            let advertisementIDs = Set(
                try advertisementTiers(for: productID)
                    .filter { $0.level > 0 }
                    .flatMap(\.advertisements)
                    .map { $0.id.rawValue }
            )
            let assetsByAdvertisementID =
                sceneCatalog.cumulativeAssets[productID]?[.advertisement]
                    ?? [:]
            let sceneAssetIDs = Set(assetsByAdvertisementID.keys)

            #expect(advertisementIDs.isSubset(of: sceneAssetIDs))
        }
    }

    @Test
    func marketingResolverReturnsPurchasedAssetsWithProductBackground() throws {
        let expectedBackgroundIDs: [ProductID: String] = [
            .pies: "marketing-background-pies",
            .hotDogs: "marketing-background-hotdogs",
            .smoothies: "marketing-background-smoothies"
        ]

        for productID in productIDs {
            let purchasedAdvertisementIDs = try advertisementTiers(
                for: productID
            )
                .filter { $0.level > 0 }
                .compactMap { $0.advertisements.first?.id.rawValue }
            let layers = DepartmentSceneResolver.assets(
                for: productID,
                department: .marketing,
                replacementAssetLevels: [],
                cumulativeAssetItems: [
                    CumulativeSceneAssetItems(
                        dimension: .advertisement,
                        itemIDs: purchasedAdvertisementIDs
                    )
                ]
            )
            let backgroundLayer = try #require(
                layers.first { $0.layerOrder == 0 }
            )
            let resolvedAdvertisementIDs = Set(
                layers
                    .filter { $0.layerOrder > 0 }
                    .flatMap(\.assets)
                    .map(\.id)
            )

            #expect(
                backgroundLayer.assets.map(\.id)
                    == [expectedBackgroundIDs[productID]!]
            )
            #expect(
                resolvedAdvertisementIDs
                    == Set(purchasedAdvertisementIDs)
            )
        }
    }

    @Test
    func levelFiveMarketingAssetSortsAboveEarlierLevels() throws {
        let tiers = try advertisementTiers(for: .pies)
        let levelOneAdvertisementID = try #require(
            tiers.first { $0.level == 1 }?.advertisements.first?.id.rawValue
        )
        let levelFiveAdvertisementID = try #require(
            tiers.first { $0.level == 5 }?.advertisements.first?.id.rawValue
        )
        let layers = DepartmentSceneResolver.assets(
            for: .pies,
            department: .marketing,
            replacementAssetLevels: [],
            cumulativeAssetItems: [
                CumulativeSceneAssetItems(
                    dimension: .advertisement,
                    itemIDs: [
                        levelOneAdvertisementID,
                        levelFiveAdvertisementID
                    ]
                )
            ]
        )

        #expect(layers.map(\.layerOrder) == [0, 100, 200])
        #expect(
            layers.first { $0.layerOrder == 100 }?.assets.map(\.id)
                == [levelOneAdvertisementID]
        )
        #expect(
            layers.first { $0.layerOrder == 200 }?.assets.map(\.id)
                == [levelFiveAdvertisementID]
        )
    }

    private var productIDs: [ProductID] {
        [.pies, .hotDogs, .smoothies]
    }

    private func advertisementTiers(
        for productID: ProductID
    ) throws -> [AdvertisementTier] {
        let catalog = AdvertisementCatalog(productID: productID)
        return try #require(catalog.tiersByProduct[productID])
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
