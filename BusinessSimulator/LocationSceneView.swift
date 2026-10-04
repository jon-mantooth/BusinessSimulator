import SwiftUI

struct LocationSceneView<DynamicContent: View>: View {
    let scene: ResolvedLocationScene
    private let dynamicContent:
        (ResolvedLocationSceneContent, CGSize) -> DynamicContent

    init(
        scene: ResolvedLocationScene,
        @ViewBuilder dynamicContent: @escaping (
            ResolvedLocationSceneContent,
            CGSize
        ) -> DynamicContent
    ) {
        self.scene = scene
        self.dynamicContent = dynamicContent
    }

    var body: some View {
        GeometryReader { geometry in
            let canvasSize = sceneCanvasSize(in: geometry.size)

            ZStack {
                ZStack {
                    ForEach(scene.assets) { asset in
                        content(
                            for: asset,
                            canvasSize: canvasSize
                        )
                        .zIndex(Double(asset.layout.layerOrder))
                    }
                }
                .frame(
                    width: canvasSize.width,
                    height: canvasSize.height
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
        }
    }

    @ViewBuilder
    private func content(
        for asset: ResolvedLocationSceneAsset,
        canvasSize: CGSize
    ) -> some View {
        switch asset.content {
        case .empty:
            EmptyView()

        case .image(let name, let aspectRatio):
            image(
                named: name,
                aspectRatio: aspectRatio,
                layout: asset.layout,
                position: asset.position,
                canvasSize: canvasSize
            )

        case .customerAnimation, .playbackInterface:
            dynamicContent(asset.content, canvasSize)
        }
    }

    @ViewBuilder
    private func image(
        named name: String,
        aspectRatio: Double,
        layout: LocationSceneAsset,
        position: LocationScenePosition,
        canvasSize: CGSize
    ) -> some View {
        if layout.layerOrder == 0 && layout.widthRatio == 1.0 {
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(
                    width: canvasSize.width,
                    height: canvasSize.height
                )
        } else {
            let width = canvasSize.width * layout.widthRatio
            let height = layout.heightRatio.map {
                canvasSize.height * $0
            } ?? width / aspectRatio
            let center = centerPosition(
                layout: layout,
                position: position,
                assetSize: CGSize(width: width, height: height),
                canvasSize: canvasSize
            )

            Image(name)
                .resizable()
                .scaledToFit()
                .frame(
                    width: width,
                    height: height,
                    alignment: .bottom
                )
                .position(center)
        }
    }

    private func sceneCanvasSize(in availableSize: CGSize) -> CGSize {
        guard let background = scene.assets.first(where: {
            $0.layout.layerOrder == 0
        }) else {
            return availableSize
        }

        switch background.layout.source {
        case .seasonalDayBackground, .seasonalNightBackground:
            let backgroundAspectRatio = 2.0 / 3.0
            let availableAspectRatio = availableSize.width / availableSize.height

            if availableAspectRatio > backgroundAspectRatio {
                return CGSize(
                    width: availableSize.height * backgroundAspectRatio,
                    height: availableSize.height
                )
            }

            return CGSize(
                width: availableSize.width,
                height: availableSize.width / backgroundAspectRatio
            )

        case .image, .seasonalSimulationBackground,
             .weatherSimulationBackground, .productStand, .customerAnimation,
             .simulationProductStand, .playbackInterface:
            return availableSize
        }
    }

    private func centerPosition(
        layout: LocationSceneAsset,
        position: LocationScenePosition,
        assetSize: CGSize,
        canvasSize: CGSize
    ) -> CGPoint {
        var x = canvasSize.width * position.x
        var y = canvasSize.height * position.y

        switch layout.anchor {
        case .center:
            break
        case .bottom:
            y -= assetSize.height / 2
        case .bottomLeading:
            x += assetSize.width / 2
            y -= assetSize.height / 2
        case .bottomTrailing:
            x -= assetSize.width / 2
            y -= assetSize.height / 2
        }

        return CGPoint(x: x, y: y)
    }
}

extension LocationSceneView where DynamicContent == EmptyView {
    init(scene: ResolvedLocationScene) {
        self.init(scene: scene) { _, _ in
            EmptyView()
        }
    }
}
