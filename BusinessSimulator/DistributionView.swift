import SwiftUI

struct DistributionView: View {
    let productID: ProductID
    let storageState: StorageState
    let purchaseWorkflow: PurchaseWorkflow

    @State private var showingStorage = false
    @State private var showingStorageUpgradeLimit = false
    @State private var displayedStorageLevel: Int
    @State private var storageAssetOpacity = 1.0
    @State private var storageTransitionTask: Task<Void, Never>?

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
        _displayedStorageLevel = State(
            initialValue: storageState.activeStorage.tierLevel
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
                Image("distribution_background")
                    .resizable()
                    .frame(
                        width: renderedSize.width,
                        height: renderedSize.height
                    )

                if let storageAsset = DepartmentSceneCatalog.asset(
                    for: productID,
                    dimension: .storage,
                    level: displayedStorageLevel
                ) {
                    distributionSceneAsset(
                        named: storageAsset.imageName,
                        sourceWidth: storageAsset.sourceWidth,
                        scale: scale
                    )
                    .position(
                        x: storageAsset.position.x * scale,
                        y: storageAsset.position.y * scale
                    )
                    .opacity(storageAssetOpacity)
                }

                // Visual-only transport prototypes remain static until the
                // transport state and its scene catalog entries are built.
                distributionSceneAsset(
                    named: "smoothie_secondary_transport_1",
                    sourceWidth: 195,
                    scale: scale
                )
                .position(x: 522 * scale, y: 955 * scale)

                distributionSceneAsset(
                    named: "smoothie_truck",
                    sourceWidth: 455,
                    scale: scale
                )
                .position(x: 205 * scale, y: 955 * scale)

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
            storageTransitionTask?.cancel()
        }
    }

    private func scheduleStorageSceneUpdate() {
        let actualLevel = storageState.activeStorage.tierLevel
        guard actualLevel != displayedStorageLevel else { return }

        storageTransitionTask?.cancel()
        storageTransitionTask = Task {
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }

            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.6)) {
                storageAssetOpacity = 0
            }

            do {
                try await Task.sleep(for: .seconds(0.6))
            } catch {
                return
            }

            guard !Task.isCancelled else { return }

            displayedStorageLevel = actualLevel

            withAnimation(.easeIn(duration: 0.6)) {
                storageAssetOpacity = 1
            }
        }
    }

    private func distributionSceneAsset(
        named imageName: String,
        sourceWidth: CGFloat,
        scale: CGFloat
    ) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: sourceWidth * scale)
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
