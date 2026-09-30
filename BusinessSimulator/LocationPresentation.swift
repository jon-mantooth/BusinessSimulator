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

struct LocationSceneAsset: Identifiable, Equatable {
    let id: String
    let imageName: String

    /// The source image's width divided by its height.
    let aspectRatio: Double

    /// Width as a proportion of the scene's logical canvas width.
    let widthRatio: Double

    let position: LocationScenePosition
    let anchor: LocationSceneAnchor

    /// Assets with larger values render in front of assets with smaller ones.
    let layerOrder: Int
}

struct LocationSceneAssets: Equatable {
    let assets: [LocationSceneAsset]

    init(
        assets: [LocationSceneAsset]
    ) {
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
