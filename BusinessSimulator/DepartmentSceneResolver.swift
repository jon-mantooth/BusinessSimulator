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

enum DepartmentSceneAssetType {
    case background
    case element(
        sourceWidth: CGFloat,
        position: CGPoint
    )
}

struct DepartmentSceneAsset: Identifiable {
    let id: String
    let imageName: String
    let type: DepartmentSceneAssetType
    let layerOrder: Int

    init(
        id: String,
        imageName: String,
        type: DepartmentSceneAssetType,
        layerOrder: Int
    ) {
        precondition(!id.isEmpty, "A department scene asset requires an ID.")
        precondition(
            !imageName.isEmpty,
            "A department scene asset requires an image name."
        )

        switch type {
        case .background:
            precondition(
                layerOrder == 0,
                "A department background must use layer zero."
            )

        case let .element(sourceWidth, _):
            precondition(
                layerOrder > 0,
                "A department scene element must render above layer zero."
            )
            precondition(
                sourceWidth > 0,
                "A department scene element requires a positive width."
            )
        }

        self.id = id
        self.imageName = imageName
        self.type = type
        self.layerOrder = layerOrder
    }

}

typealias ReplacementSceneAssets = [
    ProductID: [DepartmentSceneDimension: [Int: DepartmentSceneAsset]]
]

typealias ProductDependentSceneAssets = [
    ProductID: [DepartmentSceneAsset]
]

typealias CumulativeSceneAssets = [
    ProductID: [
        DepartmentSceneDimension: [String: DepartmentSceneAsset]
    ]
]

struct ReplacementSceneAssetLevel {
    let dimension: DepartmentSceneDimension
    let level: Int
}

struct CumulativeSceneAssetItems {
    let dimension: DepartmentSceneDimension
    let itemIDs: [String]
}

struct DepartmentSceneLayer: Identifiable {
    let layerOrder: Int
    let assets: [DepartmentSceneAsset]

    var id: Int { layerOrder }
}

protocol SceneCatalog {
    var productDependentAssets: ProductDependentSceneAssets { get }
    var replacementAssets: ReplacementSceneAssets { get }
    var cumulativeAssets: CumulativeSceneAssets { get }
}

enum DepartmentSceneResolver {
    static func assets(
        for productID: ProductID,
        department: GameArea,
        replacementAssetLevels: [ReplacementSceneAssetLevel],
        cumulativeAssetItems: [CumulativeSceneAssetItems]
    ) -> [DepartmentSceneLayer] {
        assets(
            for: productID,
            sceneCatalog: sceneCatalog(for: department),
            replacementAssetLevels: replacementAssetLevels,
            cumulativeAssetItems: cumulativeAssetItems
        )
    }

    static func assets(
        for productID: ProductID,
        sceneCatalog: any SceneCatalog,
        replacementAssetLevels: [ReplacementSceneAssetLevel],
        cumulativeAssetItems: [CumulativeSceneAssetItems]
    ) -> [DepartmentSceneLayer] {
        let productDependentAssets =
            sceneCatalog.productDependentAssets[productID] ?? []
        let replacementAssets = replacementAssetLevels.compactMap {
            replacementAssetLevel in
            sceneCatalog.replacementAssets[productID]?[
                replacementAssetLevel.dimension
            ]?[replacementAssetLevel.level]
        }
        let cumulativeAssets = cumulativeAssets(
            for: productID,
            in: sceneCatalog,
            matching: cumulativeAssetItems
        )
        let allAssets =
            productDependentAssets + replacementAssets + cumulativeAssets

        return layers(from: allAssets)
    }

    private static func layers(
        from assets: [DepartmentSceneAsset]
    ) -> [DepartmentSceneLayer] {
        Dictionary(grouping: assets, by: \.layerOrder)
            .map { layerOrder, assets in
                DepartmentSceneLayer(
                    layerOrder: layerOrder,
                    assets: assets
                )
            }
            .sorted { $0.layerOrder < $1.layerOrder }
    }

    private static func cumulativeAssets(
        for productID: ProductID,
        in sceneCatalog: any SceneCatalog,
        matching cumulativeAssetItems: [CumulativeSceneAssetItems]
    ) -> [DepartmentSceneAsset] {
        cumulativeAssetItems.flatMap {
            cumulativeAssetItem -> [DepartmentSceneAsset] in
            guard let assetsByItemID = sceneCatalog.cumulativeAssets[productID]?[
                cumulativeAssetItem.dimension
            ] else {
                return []
            }

            return cumulativeAssetItem.itemIDs.compactMap {
                assetsByItemID[$0]
            }
        }
    }

    private static func sceneCatalog(
        for department: GameArea
    ) -> any SceneCatalog {
        switch department {
        case .production:
            ProductionSceneCatalog()

        case .distribution:
            DistributionSceneCatalog()

        case .marketing:
            MarketingSceneCatalog()

        case .gameMode, .finance:
            preconditionFailure(
                "The selected game area does not have a department scene catalog."
            )
        }
    }
}
