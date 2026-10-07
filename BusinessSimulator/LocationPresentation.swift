import Foundation

struct LocationScenePosition: Equatable {
    /// Horizontal position within the scene's logical canvas from 0 to 1.
    let x: Double

    /// Vertical position within the scene's logical canvas from 0 to 1.
    let y: Double
}

enum LocationSceneAnchor: Equatable {
    case center
    case bottom
    case bottomLeading
    case bottomTrailing
}

enum LocationSceneAssetSource: Equatable {
    case image(String)
    case seasonalDayBackground
    case seasonalNightBackground
    case seasonalSimulationBackground
    case weatherSimulationBackground(
        sunnyImageName: String,
        rainImageName: String,
        snowImageName: String?
    )
    case productStand
    case customerAnimation
    case simulationProductStand
    case playbackInterface
}

struct LocationSceneAsset: Identifiable, Equatable {
    let id: String
    let source: LocationSceneAssetSource

    /// The source image's width divided by its height. Contextual assets can
    /// defer this value until their product or seasonal image is resolved.
    let aspectRatio: Double?

    /// Width as a proportion of the scene's logical canvas width.
    let widthRatio: Double

    /// Optional height as a proportion of the scene's logical canvas height.
    /// When omitted, height is derived from the resolved image aspect ratio.
    let heightRatio: Double?

    let position: LocationScenePosition
    let anchor: LocationSceneAnchor

    /// Assets with larger values render in front of assets with smaller ones.
    let layerOrder: Int

    init(
        id: String,
        source: LocationSceneAssetSource,
        aspectRatio: Double?,
        widthRatio: Double,
        heightRatio: Double? = nil,
        position: LocationScenePosition,
        anchor: LocationSceneAnchor,
        layerOrder: Int
    ) {
        self.id = id
        self.source = source
        self.aspectRatio = aspectRatio
        self.widthRatio = widthRatio
        self.heightRatio = heightRatio
        self.position = position
        self.anchor = anchor
        self.layerOrder = layerOrder
    }
}

struct LocationSceneAssets: Equatable {
    let assets: [LocationSceneAsset]

    init(assets: [LocationSceneAsset]) {
        assert(
            !assets.isEmpty,
            "A location scene must contain at least one asset."
        )

        let assetIDs = assets.map(\.id)
        assert(
            Set(assetIDs).count == assetIDs.count,
            "A location scene cannot contain duplicate asset IDs."
        )

        self.assets = assets
    }
}

struct LocationPresentation: Equatable {
    let nightScene: LocationSceneAssets
    let dayScene: LocationSceneAssets
    let simulationScene: LocationSceneAssets
}
