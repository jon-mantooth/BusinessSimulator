import CoreGraphics
import Testing
@testable import BusinessSimulator

// TODO: Once multiple department scene catalogs are populated, verify that the
// merged catalog preserves every entry from each individual catalog and rejects
// duplicate dimension registrations.
@MainActor
struct DepartmentSceneCatalogTests {

    private let configuredAsset = DepartmentSceneAsset(
        imageName: "configured_asset",
        sourceWidth: 100,
        position: .zero,
        layerOrder: 1
    )

    private var assets: SceneAssetsByDimension {
        [
            .storage: [
                .pies: [
                    2: configuredAsset
                ]
            ]
        ]
    }

    @Test
    func configuredDimensionProductAndLevelReturnsAsset() throws {
        let asset = try #require(
            DepartmentSceneCatalog.asset(
                in: assets,
                for: .pies,
                dimension: .storage,
                level: 2
            )
        )

        #expect(asset.imageName == configuredAsset.imageName)
    }

    @Test
    func missingDimensionReturnsNil() {
        let asset = DepartmentSceneCatalog.asset(
            in: assets,
            for: .pies,
            dimension: .labor,
            level: 2
        )

        #expect(asset == nil)
    }

    @Test
    func missingProductReturnsNil() {
        let asset = DepartmentSceneCatalog.asset(
            in: assets,
            for: .hotDogs,
            dimension: .storage,
            level: 2
        )

        #expect(asset == nil)
    }

    @Test
    func missingLevelReturnsNil() {
        let asset = DepartmentSceneCatalog.asset(
            in: assets,
            for: .pies,
            dimension: .storage,
            level: 3
        )

        #expect(asset == nil)
    }
}
