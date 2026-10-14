import SwiftUI

struct DistributionView: View {
    let productID: ProductID
    let storageState: StorageState
    let purchaseWorkflow: PurchaseWorkflow

    @State private var showingStorage = false
    @State private var showingStorageUpgradeLimit = false
    @State private var displayedSceneLayers: [DepartmentSceneLayer]
    @State private var incomingSceneLayers: [DepartmentSceneLayer]?
    @State private var incomingSceneOpacity = 0.0
    @State private var sceneTransitionTask: Task<Void, Never>?

    private let sourceSize = CGSize(width: 852, height: 1_846)
    private let darkBrown = Color(red: 0.20, green: 0.12, blue: 0.06)
    private let warmGold = Color(red: 0.91, green: 0.65, blue: 0.25)
    private let paleGold = Color(red: 1.00, green: 0.91, blue: 0.60)

    init(
        productID: ProductID,
        storageState: StorageState,
        purchaseWorkflow: PurchaseWorkflow
    ) {
        self.productID = productID
        self.storageState = storageState
        self.purchaseWorkflow = purchaseWorkflow
        _displayedSceneLayers = State(
            initialValue: Self.resolveSceneLayers(
                productID: productID,
                storageLevel: storageState.activeStorage.tierLevel
            )
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = max(
                geometry.size.width / sourceSize.width,
                geometry.size.height / sourceSize.height
            )
            let renderedSize = CGSize(
                width: sourceSize.width * scale,
                height: sourceSize.height * scale
            )

            ZStack(alignment: .topLeading) {
                distributionScene(
                    layers: displayedSceneLayers,
                    renderedSize: renderedSize,
                    scale: scale
                )

                if let incomingSceneLayers {
                    distributionScene(
                        layers: incomingSceneLayers,
                        renderedSize: renderedSize,
                        scale: scale
                    )
                    .opacity(incomingSceneOpacity)
                }

                distributionButton(
                    title: "Storage",
                    systemImage: "shippingbox.fill",
                    scale: scale
                ) {
                    if purchaseWorkflow.dimensionAvailability(
                        for: PurchaseDimensionAvailabilityRequest()
                    ) == .available {
                        showingStorage = true
                    } else {
                        showingStorageUpgradeLimit = true
                    }
                }
                .position(x: 645 * scale, y: 745 * scale)

                distributionButton(
                    title: "Transport",
                    systemImage: "truck.box.fill",
                    scale: scale,
                    action: {}
                )
                .position(x: 245 * scale, y: 1_145 * scale)
            }
            .frame(width: renderedSize.width, height: renderedSize.height)
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
        }
        .clipped()
        .sheet(
            isPresented: $showingStorage,
            onDismiss: scheduleStorageSceneUpdate
        ) {
            StorageView(
                storageState: storageState,
                purchaseWorkflow: purchaseWorkflow
            ) {
                showingStorage = false
            }
            .presentationDetents([.fraction(0.9)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
            .presentationBackground(.clear)
        }
        .overlay {
            if showingStorageUpgradeLimit {
                GamePopupView(
                    type: .upgradeLimitReached,
                    onConfirm: {},
                    onDismiss: {
                        showingStorageUpgradeLimit = false
                    }
                )
            }
        }
        .onDisappear {
            sceneTransitionTask?.cancel()
        }
    }

    private func scheduleStorageSceneUpdate() {
        let updatedSceneLayers = Self.resolveSceneLayers(
            productID: productID,
            storageLevel: storageState.activeStorage.tierLevel
        )
        guard sceneAssetIDs(in: updatedSceneLayers)
                != sceneAssetIDs(in: displayedSceneLayers) else {
            return
        }

        sceneTransitionTask?.cancel()
        sceneTransitionTask = Task {
            incomingSceneLayers = updatedSceneLayers
            incomingSceneOpacity = 0

            withAnimation(.easeInOut(duration: 0.45)) {
                incomingSceneOpacity = 1
            }

            do {
                try await Task.sleep(for: .seconds(0.45))
            } catch {
                incomingSceneLayers = nil
                incomingSceneOpacity = 0
                return
            }

            guard !Task.isCancelled else { return }

            displayedSceneLayers = updatedSceneLayers
            incomingSceneLayers = nil
            incomingSceneOpacity = 0
        }
    }

    @ViewBuilder
    private func distributionScene(
        layers: [DepartmentSceneLayer],
        renderedSize: CGSize,
        scale: CGFloat
    ) -> some View {
        ForEach(layers) { layer in
            ForEach(layer.assets) { asset in
                sceneAsset(
                    asset,
                    renderedSize: renderedSize,
                    scale: scale
                )
            }
        }
    }

    @ViewBuilder
    private func sceneAsset(
        _ asset: DepartmentSceneAsset,
        renderedSize: CGSize,
        scale: CGFloat
    ) -> some View {
        switch asset.type {
        case .background:
            Image(asset.imageName)
                .resizable()
                .frame(
                    width: renderedSize.width,
                    height: renderedSize.height
                )

        case let .element(sourceWidth, position):
            Image(asset.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: sourceWidth * scale)
                .position(
                    x: position.x * scale,
                    y: position.y * scale
                )
        }
    }

    private func sceneAssetIDs(
        in layers: [DepartmentSceneLayer]
    ) -> [String] {
        layers.flatMap(\.assets).map(\.id)
    }

    private static func resolveSceneLayers(
        productID: ProductID,
        storageLevel: Int
    ) -> [DepartmentSceneLayer] {
        DepartmentSceneResolver.assets(
            for: productID,
            department: .distribution,
            replacementAssetLevels: [
                ReplacementSceneAssetLevel(
                    dimension: .storage,
                    level: storageLevel
                )
            ],
            cumulativeAssetItems: []
        )
    }

    private func distributionButton(
        title: String,
        systemImage: String,
        scale: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(
                    .system(
                        size: max(24 * scale, 13),
                        weight: .black,
                        design: .rounded
                    )
                )
                .textCase(.uppercase)
                .foregroundStyle(darkBrown)
                .frame(
                    width: 270 * scale,
                    height: max(68 * scale, 38)
                )
                .background(
                    LinearGradient(
                        colors: [paleGold, warmGold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: max(12 * scale, 7)))
                .overlay {
                    RoundedRectangle(cornerRadius: max(12 * scale, 7))
                        .stroke(darkBrown.opacity(0.55), lineWidth: 1.5)
                }
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
