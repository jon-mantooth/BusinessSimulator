import SwiftUI

struct ProductionView: View {
    let product: Product
    let equipmentState: EquipmentState
    let laborState: LaborState
    let purchaseWorkflow: PurchaseWorkflow

    @State private var showingEquipment = false
    @State private var showingLabor = false
    @State private var showingEquipmentUpgradeLimit = false
    @State private var showingLaborUpgradeLimit = false
    @State private var selectedEquipmentTab: EquipmentViewTab = .primary
    @State private var selectedSecondaryEquipment: Equipment?
    @State private var equipmentPendingConfirmation: Equipment?
    @State private var purchaseWarning: GamePopupType?
    @State private var displayedSceneLayers: [DepartmentSceneLayer]
    @State private var incomingSceneLayers: [DepartmentSceneLayer]?
    @State private var incomingProductionSceneOpacity = 0.0
    @State private var productionSceneTransitionTask: Task<Void, Never>?

    private let sourceSize = CGSize(width: 851, height: 1_849)
    private let darkBrown = Color(red: 0.20, green: 0.12, blue: 0.06)
    private let warmGold = Color(red: 0.91, green: 0.65, blue: 0.25)
    private let paleGold = Color(red: 1.00, green: 0.91, blue: 0.60)

    init(
        product: Product,
        equipmentState: EquipmentState,
        laborState: LaborState,
        purchaseWorkflow: PurchaseWorkflow
    ) {
        self.product = product
        self.equipmentState = equipmentState
        self.laborState = laborState
        self.purchaseWorkflow = purchaseWorkflow
        _displayedSceneLayers = State(
            initialValue: Self.resolveSceneLayers(
                productID: product.id,
                equipmentState: equipmentState,
                laborState: laborState
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
                productionScene(
                    layers: displayedSceneLayers,
                    renderedSize: renderedSize,
                    scale: scale
                )

                if let incomingSceneLayers {
                    productionScene(
                        layers: incomingSceneLayers,
                        renderedSize: renderedSize,
                        scale: scale
                    )
                    .opacity(incomingProductionSceneOpacity)
                }

                productionButton(
                    title: "Equipment",
                    systemImage: "gearshape.fill",
                    scale: scale,
                    action: {
                        if purchaseWorkflow.dimensionAvailability(
                            for: PurchaseDimensionAvailabilityRequest()
                        ) == .available {
                            selectedEquipmentTab = .primary
                            showingEquipment = true
                        } else {
                            showingEquipmentUpgradeLimit = true
                        }
                    }
                )
                .position(
                    x: 650 * scale,
                    y: 550 * scale
                )

                productionButton(
                    title: "Labor",
                    systemImage: "person.2.fill",
                    scale: scale,
                    action: {
                        if purchaseWorkflow.dimensionAvailability(
                            for: PurchaseDimensionAvailabilityRequest()
                        ) == .available {
                            showingLabor = true
                        } else {
                            showingLaborUpgradeLimit = true
                        }
                    }
                )
                .position(
                    x: 555 * scale,
                    y: 790 * scale
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
        .sheet(
            isPresented: $showingEquipment,
            onDismiss: scheduleProductionSceneUpdate
        ) {
            equipmentSheet
                .presentationDetents([.fraction(0.9)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
        }
        .sheet(
            isPresented: $showingLabor,
            onDismiss: scheduleProductionSceneUpdate
        ) {
            LaborView(
                laborState: laborState,
                purchaseWorkflow: purchaseWorkflow
            ) {
                showingLabor = false
            }
            .presentationDetents([.fraction(0.9)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
        }
        .overlay {
            if showingEquipmentUpgradeLimit {
                GamePopupView(
                    type: .upgradeLimitReached,
                    onConfirm: {},
                    onDismiss: {
                        showingEquipmentUpgradeLimit = false
                    }
                )
            }

            if showingLaborUpgradeLimit {
                GamePopupView(
                    type: .upgradeLimitReached,
                    onConfirm: {},
                    onDismiss: {
                        showingLaborUpgradeLimit = false
                    }
                )
            }
        }
        .onDisappear {
            productionSceneTransitionTask?.cancel()
        }
    }

    @ViewBuilder
    private func productionScene(
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

    private func scheduleProductionSceneUpdate() {
        let updatedSceneLayers = Self.resolveSceneLayers(
            productID: product.id,
            equipmentState: equipmentState,
            laborState: laborState
        )
        guard sceneAssetIDs(in: updatedSceneLayers)
                != sceneAssetIDs(in: displayedSceneLayers) else {
            return
        }

        productionSceneTransitionTask?.cancel()
        productionSceneTransitionTask = Task {
            incomingSceneLayers = updatedSceneLayers
            incomingProductionSceneOpacity = 0

            withAnimation(.easeInOut(duration: 0.45)) {
                incomingProductionSceneOpacity = 1
            }

            do {
                try await Task.sleep(for: .seconds(0.45))
            } catch {
                incomingSceneLayers = nil
                incomingProductionSceneOpacity = 0
                return
            }

            guard !Task.isCancelled else { return }

            displayedSceneLayers = updatedSceneLayers
            incomingSceneLayers = nil
            incomingProductionSceneOpacity = 0
        }
    }

    private func sceneAssetIDs(
        in layers: [DepartmentSceneLayer]
    ) -> [String] {
        layers.flatMap(\.assets).map(\.id)
    }

    private static func resolveSceneLayers(
        productID: ProductID,
        equipmentState: EquipmentState,
        laborState: LaborState
    ) -> [DepartmentSceneLayer] {
        let replacementAssetLevels = [
            ReplacementSceneAssetLevel(
                dimension: .primaryEquipment,
                level: equipmentState.activePrimaryEquipment.tierLevel
            )
        ]
        let cumulativeAssetItems = [
            CumulativeSceneAssetItems(
                dimension: .secondaryEquipment,
                itemIDs: equipmentState.ownedSecondaryEquipment.equipment
                    .map { $0.id.rawValue }
            ),
            CumulativeSceneAssetItems(
                dimension: .labor,
                itemIDs: laborState.ownedLabor.labor.map { $0.id.rawValue }
            )
        ]

        return DepartmentSceneResolver.assets(
            for: productID,
            department: .production,
            replacementAssetLevels: replacementAssetLevels,
            cumulativeAssetItems: cumulativeAssetItems
        )
    }

    private var equipmentSheet: some View {
        return ZStack(alignment: .topTrailing) {
            Color(red: 0.17, green: 0.09, blue: 0.04)
                .ignoresSafeArea()

            GeometryReader { geometry in
                Image("equipment_background")
                    .resizable()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                equipmentTabs

                Group {
                    switch selectedEquipmentTab {
                    case .primary:
                        EquipmentViewPrimary(
                            activeTier: equipmentState.activePrimaryTier,
                            availableTier: equipmentState.nextPrimaryTier,
                            purchaseAvailability: { equipment in
                                purchaseWorkflow.itemAvailability(
                                    for: purchaseRequest(for: equipment)
                                )
                            },
                            onPurchase: attemptPurchase
                        )
                    case .secondary:
                        EquipmentViewSecondary(
                            ownedEquipment:
                                equipmentState.ownedSecondaryEquipment,
                            availableEquipment:
                                equipmentState.availableSecondaryEquipment,
                            selectedEquipmentID:
                                selectedSecondaryEquipment?.id,
                            onEquipmentTapped: { equipment in
                                selectedSecondaryEquipment = equipment
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Button {
                showingEquipment = false
            } label: {
                Image("equipment_x")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .padding(.trailing, 8)
            .accessibilityLabel("Close equipment")

            if let selectedSecondaryEquipment {
                Color.black.opacity(0.42)
                    .ignoresSafeArea()

                SecondaryEquipmentDetailCard(
                    equipment: selectedSecondaryEquipment,
                    isOwned: equipmentState.ownedSecondaryEquipment.contains(
                        selectedSecondaryEquipment
                    ),
                    purchaseAvailability: purchaseWorkflow
                        .itemAvailability(
                            for: purchaseRequest(
                                for: selectedSecondaryEquipment
                            )
                        ),
                    onPurchase: {
                        attemptPurchase(selectedSecondaryEquipment)
                    },
                    onClose: {
                        self.selectedSecondaryEquipment = nil
                    }
                )
                .padding(.horizontal, 22)
                .transition(.scale.combined(with: .opacity))
            }

            if let equipmentPendingConfirmation {
                GamePopupView(
                    type: .upgradeConfirmation(
                        itemName: equipmentPendingConfirmation.name,
                        icon: equipmentPendingConfirmation.smallIcon
                    ),
                    onConfirm: {
                        confirmPurchase(equipmentPendingConfirmation)
                    },
                    onDismiss: {
                        self.equipmentPendingConfirmation = nil
                    }
                )
            }

            if let purchaseWarning {
                GamePopupView(
                    type: purchaseWarning,
                    onConfirm: {},
                    onDismiss: {
                        self.purchaseWarning = nil
                    }
                )
            }
        }
        .animation(
            .easeInOut(duration: 0.2),
            value: selectedSecondaryEquipment?.id
        )
    }

    private func attemptPurchase(
        _ equipment: Equipment
    ) {
        switch purchaseWorkflow.itemAvailability(
            for: purchaseRequest(for: equipment)
        ) {
        case .available:
            equipmentPendingConfirmation = equipment
        case let .locationLocked(requiredTier):
            purchaseWarning = .locationLocked(
                requiredLevel: requiredTier.rawValue
            )
        case .insufficientFunds:
            purchaseWarning = .insufficientFunds
        case .operatingReserveRequired:
            purchaseWarning = .operatingReserveRequired
        }
    }

    private func purchaseRequest(
        for equipment: Equipment
    ) -> PurchaseRequest {
        PurchaseRequest(
            state: equipmentState,
            item: equipment,
            requiredLocationTier: equipmentState.requiredLocationTier(
                for: equipment
            ),
            pendingUpgrade: equipment.ingredientUpgrade.map {
                .ingredient($0)
            }
        )
    }

    private func confirmPurchase(
        _ equipment: Equipment
    ) {
        let result = purchaseWorkflow.complete(
            purchaseRequest(for: equipment)
        )

        equipmentPendingConfirmation = nil

        switch result {
        case .completed:
            selectedSecondaryEquipment = nil
            showingEquipment = false
        case let .unavailable(availability):
            showPurchaseWarning(for: availability)
        case .saveFailed:
            purchaseWarning = .purchaseSaveFailed
        }
    }

    private func showPurchaseWarning(
        for availability: PurchaseAvailability
    ) {
        switch availability {
        case .available:
            break
        case let .locationLocked(requiredTier):
            purchaseWarning = .locationLocked(
                requiredLevel: requiredTier.rawValue
            )
        case .insufficientFunds:
            purchaseWarning = .insufficientFunds
        case .operatingReserveRequired:
            purchaseWarning = .operatingReserveRequired
        }
    }

    private var equipmentTabs: some View {
        HStack(spacing: 0) {
            equipmentTab(
                title: primaryEquipmentTitle,
                tab: .primary
            )
            equipmentTab(
                title: "Prep Equipment",
                tab: .secondary
            )
        }
        .padding(.top, 8)
        .padding(.horizontal, 12)
        .padding(.trailing, 38)
    }

    private var primaryEquipmentTitle: String {
        switch product.id {
        case .pies:
            return "Ovens"
        case .hotDogs:
            return "Grills"
        case .smoothies:
            return "Blenders"
        }
    }

    private func equipmentTab(
        title: String,
        tab: EquipmentViewTab
    ) -> some View {
        Button {
            selectedEquipmentTab = tab
        } label: {
            ZStack {
                Image(
                    selectedEquipmentTab == tab
                        ? "equipment_tab_green"
                        : "equipment_tab"
                )
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(title.uppercased())
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(
                        selectedEquipmentTab == tab ? .white : darkBrown
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 12)
            }
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }

    private func productionButton(
        title: String,
        systemImage: String,
        scale: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(
                    .system(
                        size: max(26 * scale, 13),
                        weight: .black,
                        design: .rounded
                    )
                )
                .textCase(.uppercase)
                .foregroundStyle(darkBrown)
                .frame(
                    width: 250 * scale,
                    height: max(68 * scale, 38)
                )
                .background(
                    LinearGradient(
                        colors: [paleGold, warmGold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: max(12 * scale, 7))
                )
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

private enum EquipmentViewTab {
    case primary
    case secondary
}
