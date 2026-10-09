import SwiftUI

enum DepartmentSceneDimension: Hashable {
    case advertisement
    case primaryEquipment
    case secondaryEquipment
    case labor
    case storage
    case primaryTransportation
    case secondaryTransportation
}

struct DepartmentSceneAsset {
    let imageName: String
    let sourceWidth: CGFloat
    let position: CGPoint
    let layerOrder: Int
}

typealias SceneAssetsByLevel = [Int: DepartmentSceneAsset]
typealias SceneAssetsByProduct = [ProductID: SceneAssetsByLevel]
typealias SceneAssetsByDimension = [
    DepartmentSceneDimension: SceneAssetsByProduct
]

enum DepartmentSceneCatalog {
    private static let departmentCatalogs: [SceneAssetsByDimension] = [
        DistributionSceneCatalog.assets
    ]

    private static let assets: SceneAssetsByDimension = {
        var mergedAssets: SceneAssetsByDimension = [:]

        for departmentCatalog in departmentCatalogs {
            mergedAssets.merge(departmentCatalog) { _, _ in
                preconditionFailure(
                    "A scene dimension was registered by multiple department catalogs."
                )
            }
        }

        return mergedAssets
    }()

    static func asset(
        for productID: ProductID,
        dimension: DepartmentSceneDimension,
        level: Int
    ) -> DepartmentSceneAsset? {
        asset(
            in: assets,
            for: productID,
            dimension: dimension,
            level: level
        )
    }

    static func asset(
        in assets: SceneAssetsByDimension,
        for productID: ProductID,
        dimension: DepartmentSceneDimension,
        level: Int
    ) -> DepartmentSceneAsset? {
        assets[dimension]?[productID]?[level]
    }
}
