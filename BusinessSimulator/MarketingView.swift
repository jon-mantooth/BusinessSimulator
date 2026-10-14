import SwiftUI

struct MarketingView: View {
    let product: Product
    let reputation: BusinessReputationState
    let advertisementState: AdvertisementState
    let purchaseWorkflow: PurchaseWorkflow
    let simulationDay: Int

    @State private var showingBusinessReputation = false
    @State private var showingAdvertisement = false
    @State private var showingAdvertisementUpgradeLimit = false
    @State private var displayedSceneLayers: [DepartmentSceneLayer]
    @State private var incomingSceneLayers: [DepartmentSceneLayer]?
    @State private var incomingMarketingSceneOpacity = 0.0
    @State private var marketingSceneTransitionTask: Task<Void, Never>?

    private let sourceSize = CGSize(width: 852, height: 1_846)

    init(
        product: Product,
        reputation: BusinessReputationState,
        advertisementState: AdvertisementState,
        purchaseWorkflow: PurchaseWorkflow,
        simulationDay: Int
    ) {
        self.product = product
        self.reputation = reputation
        self.advertisementState = advertisementState
        self.purchaseWorkflow = purchaseWorkflow
        self.simulationDay = simulationDay
        _displayedSceneLayers = State(
            initialValue: Self.resolveSceneLayers(
                productID: product.id,
                purchasedAdvertisementIDs:
                    advertisementState.purchasedAdvertisementIDs
            )
        )
    }

    var body: some View {
        ZStack {
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
                    marketingScene(
                        layers: displayedSceneLayers,
                        renderedSize: renderedSize,
                        scale: scale
                    )

                    if let incomingSceneLayers {
                        marketingScene(
                            layers: incomingSceneLayers,
                            renderedSize: renderedSize,
                            scale: scale
                        )
                        .opacity(incomingMarketingSceneOpacity)
                    }

                    marketingButton(
                        title: "Advertisement",
                        systemImage: "megaphone.fill",
                        scale: scale,
                        action: {
                            if purchaseWorkflow.dimensionAvailability(
                                for: PurchaseDimensionAvailabilityRequest()
                            ) == .available {
                                showingAdvertisement = true
                            } else {
                                showingAdvertisementUpgradeLimit = true
                            }
                        }
                    )
                    .position(
                        x: 380 * scale,
                        y: 850 * scale
                    )

                    marketingButton(
                        title: "Business Reputation",
                        systemImage: "star.fill",
                        scale: scale,
                        action: {
                            showingBusinessReputation = true
                        }
                    )
                    .position(
                        x: 450 * scale,
                        y: 1_145 * scale
                    )
                }
                .frame(
                    width: renderedSize.width,
                    height: renderedSize.height
                )
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
            }
            .clipped()

            if showingBusinessReputation {
                Color.black.opacity(0.38)
                    .ignoresSafeArea()

                ReputationView(
                    product: product,
                    reputation: reputation,
                    simulationDay: simulationDay
                ) {
                    showingBusinessReputation = false
                }
                .padding(20)
                .transition(.scale.combined(with: .opacity))
            }

            if showingAdvertisementUpgradeLimit {
                GamePopupView(
                    type: .upgradeLimitReached,
                    onConfirm: {},
                    onDismiss: {
                        showingAdvertisementUpgradeLimit = false
                    }
                )
            }

        }
        .animation(.easeInOut(duration: 0.2), value: showingBusinessReputation)
        .sheet(
            isPresented: $showingAdvertisement,
            onDismiss: scheduleMarketingSceneUpdate
        ) {
            AdvertisementView(
                advertisementState: advertisementState,
                purchaseWorkflow: purchaseWorkflow
            ) {
                showingAdvertisement = false
            }
            .presentationDetents([.fraction(0.9)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
        }
        .onDisappear {
            marketingSceneTransitionTask?.cancel()
        }
    }

    @ViewBuilder
    private func marketingScene(
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

    private func scheduleMarketingSceneUpdate() {
        let updatedSceneLayers = Self.resolveSceneLayers(
            productID: product.id,
            purchasedAdvertisementIDs:
                advertisementState.purchasedAdvertisementIDs
        )
        guard sceneAssetIDs(in: updatedSceneLayers)
                != sceneAssetIDs(in: displayedSceneLayers) else {
            return
        }

        marketingSceneTransitionTask?.cancel()
        marketingSceneTransitionTask = Task {
            incomingSceneLayers = updatedSceneLayers
            incomingMarketingSceneOpacity = 0

            withAnimation(.easeInOut(duration: 0.45)) {
                incomingMarketingSceneOpacity = 1
            }

            do {
                try await Task.sleep(for: .seconds(0.45))
            } catch {
                incomingSceneLayers = nil
                incomingMarketingSceneOpacity = 0
                return
            }

            guard !Task.isCancelled else { return }

            displayedSceneLayers = updatedSceneLayers
            incomingSceneLayers = nil
            incomingMarketingSceneOpacity = 0
        }
    }

    private func sceneAssetIDs(
        in layers: [DepartmentSceneLayer]
    ) -> [String] {
        layers.flatMap(\.assets).map(\.id)
    }

    private static func resolveSceneLayers(
        productID: ProductID,
        purchasedAdvertisementIDs: [String]
    ) -> [DepartmentSceneLayer] {
        DepartmentSceneResolver.assets(
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
    }

    private func marketingButton(
        title: String,
        systemImage: String,
        scale: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 32 * scale, weight: .bold))
                .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.07))
                .frame(
                    width: 320 * scale,
                    height: 78 * scale
                )
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.98, blue: 0.88),
                            Color(red: 1.0, green: 0.84, blue: 0.46)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 20 * scale)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20 * scale)
                        .stroke(
                            Color(red: 0.95, green: 0.63, blue: 0.13),
                            lineWidth: 3 * scale
                        )
                }
                .shadow(
                    color: Color.orange.opacity(0.45),
                    radius: 10 * scale
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
