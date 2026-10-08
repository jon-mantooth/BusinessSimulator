import SwiftUI

struct StorageView: View {
    let storageState: StorageState
    let purchaseWorkflow: PurchaseWorkflow
    let onClose: () -> Void

    @State private var pendingConfirmation: Storage?
    @State private var purchaseWarning: GamePopupType?

    private let sourceSize = CGSize(width: 887, height: 1_774)
    private let ink = Color(red: 0.20, green: 0.12, blue: 0.07)
    private let green = Color(red: 0.08, green: 0.49, blue: 0.15)
    private let showsLayoutGuides = false

    var body: some View {
        GeometryReader { geometry in
            let scale = min(
                geometry.size.width / sourceSize.width,
                geometry.size.height / sourceSize.height
            )
            let renderedSize = CGSize(
                width: sourceSize.width * scale,
                height: sourceSize.height * scale
            )

            ZStack {
                ZStack(alignment: .topLeading) {
                    Image("storage_background")
                        .resizable()
                        .frame(
                            width: renderedSize.width,
                            height: renderedSize.height
                        )

                    currentStorageContent(
                        renderedSize: renderedSize,
                        scale: scale
                    )

                    if let nextTier = storageState.nextTier {
                        nextStorageContent(
                            nextTier,
                            renderedSize: renderedSize,
                            scale: scale
                        )
                    } else {
                        maximumStorageContent(
                            renderedSize: renderedSize,
                            scale: scale
                        )
                    }

                    Button(action: onClose) {
                        Color.clear
                            .frame(width: 76 * scale, height: 76 * scale)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .place(
                        in: StorageLayout.closeButton,
                        canvasSize: renderedSize,
                        showsGuide: showsLayoutGuides
                    )
                    .accessibilityLabel("Close storage")
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
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .overlay {
            if let pendingConfirmation {
                GamePopupView(
                    type: .upgradeConfirmation(
                        itemName: pendingConfirmation.name,
                        icon: pendingConfirmation.smallIcon
                    ),
                    onConfirm: {
                        confirmPurchase(pendingConfirmation)
                    },
                    onDismiss: {
                        self.pendingConfirmation = nil
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
    }

    private func currentStorageContent(
        renderedSize: CGSize,
        scale: CGFloat
    ) -> some View {
        let active = storageState.activeStorage
        return Group {
            itemArtwork(active.storage, scale: scale)
                .place(
                    in: StorageLayout.currentArtwork,
                    canvasSize: renderedSize,
                    showsGuide: showsLayoutGuides
                )

            itemInformation(
                name: active.storage.name,
                level: active.tierLevel,
                description: active.storage.description,
                scale: scale
            )
                .place(
                    in: StorageLayout.currentInformation,
                    canvasSize: renderedSize,
                    showsGuide: showsLayoutGuides
                )

            capacityText(active.storage.capacity, scale: scale)
                .place(
                    in: StorageLayout.currentCapacity,
                    canvasSize: renderedSize,
                    showsGuide: showsLayoutGuides
                )

            capacityBar(
                capacity: active.storage.capacity,
                scale: scale
            )
            .place(
                in: StorageLayout.currentProgress,
                canvasSize: renderedSize,
                showsGuide: showsLayoutGuides
            )
        }
    }

    private func nextStorageContent(
        _ tier: StorageTier,
        renderedSize: CGSize,
        scale: CGFloat
    ) -> some View {
        Group {
            itemArtwork(tier.storage, scale: scale)
                .place(
                    in: StorageLayout.nextArtwork,
                    canvasSize: renderedSize,
                    showsGuide: showsLayoutGuides
                )

            itemInformation(
                name: tier.storage.name,
                level: tier.level,
                description: tier.storage.description,
                scale: scale
            )
                .place(
                    in: StorageLayout.nextInformation,
                    canvasSize: renderedSize,
                    showsGuide: showsLayoutGuides
                )

            capacityText(tier.storage.capacity, scale: scale)
                .place(
                    in: StorageLayout.nextCapacity,
                    canvasSize: renderedSize,
                    showsGuide: showsLayoutGuides
                )

            capacityBar(capacity: tier.storage.capacity, scale: scale)
                .place(
                    in: StorageLayout.nextProgress,
                    canvasSize: renderedSize,
                    showsGuide: showsLayoutGuides
                )

            Button {
                attemptPurchase(tier.storage)
            } label: {
                HStack(spacing: 22 * scale) {
                    Text(currency(tier.storage.price))
                    Text("PURCHASE")
                }
                .font(.system(size: 36 * scale, weight: .black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(green)
                .clipShape(RoundedRectangle(cornerRadius: 22 * scale))
                .overlay {
                    RoundedRectangle(cornerRadius: 22 * scale)
                        .stroke(ink, lineWidth: max(2 * scale, 1))
                }
            }
            .buttonStyle(.plain)
            .place(
                in: StorageLayout.purchaseButton,
                canvasSize: renderedSize,
                showsGuide: showsLayoutGuides
            )
            .accessibilityLabel(
                "Purchase \(tier.storage.name) for \(currency(tier.storage.price))"
            )
        }
    }

    private func maximumStorageContent(
        renderedSize: CGSize,
        scale: CGFloat
    ) -> some View {
        Text("MAXIMUM STORAGE REACHED")
            .font(.system(size: 30 * scale, weight: .black))
            .foregroundStyle(ink)
            .place(
                in: StorageLayout.maximumStorage,
                canvasSize: renderedSize,
                showsGuide: showsLayoutGuides
            )
    }

    private func itemArtwork(
        _ storage: Storage,
        scale: CGFloat
    ) -> some View {
        GameIconView(icon: storage.smallIcon, size: 145 * scale)
            .foregroundStyle(Color(red: 0.20, green: 0.35, blue: 0.42))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func itemInformation(
        name: String,
        level: Int,
        description: String,
        scale: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 10 * scale) {
            HStack(alignment: .top, spacing: 9 * scale) {
                Text(name)
                    .font(.system(size: 34 * scale, weight: .black))
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(ink)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .topLeading
                    )

                Text("Level \(level)")
                    .font(.system(size: 24 * scale, weight: .black))
                    .foregroundStyle(ink.opacity(0.95))
                    .frame(width: 105 * scale, height: 45 * scale)
                    .background(Color(red: 0.88, green: 0.77, blue: 0.59))
                    .clipShape(RoundedRectangle(cornerRadius: 8 * scale))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8 * scale)
                            .stroke(
                                ink.opacity(0.25),
                                lineWidth: max(scale, 0.5)
                            )
                    }
            }

            Divider()
                .overlay(ink.opacity(0.18))

            Text(description)
                .font(.system(size: 24 * scale, weight: .black))
                .lineLimit(3)
                .foregroundStyle(
                    Color(red: 0.20, green: 0.27, blue: 0.29)
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 14 * scale)
        .padding(.vertical, 11 * scale)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.91, blue: 0.79),
                    Color(red: 0.90, green: 0.82, blue: 0.68)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14 * scale))
        .overlay {
            RoundedRectangle(cornerRadius: 14 * scale)
                .stroke(ink.opacity(0.25), lineWidth: max(1.5 * scale, 0.75))
        }
        .shadow(color: .black.opacity(0.12), radius: 2 * scale, y: scale)
    }

    private func capacityText(
        _ capacity: Int,
        scale: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 2 * scale) {
            Text("STORAGE CAPACITY")
                .font(.system(size: 24 * scale, weight: .black))
            Text("\(capacity) units")
                .font(.system(size: 38 * scale, weight: .black))
        }
        .foregroundStyle(Color(red: 0.20, green: 0.27, blue: 0.29))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 14 * scale)
        .padding(.vertical, 8 * scale)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.83, green: 0.91, blue: 0.75),
                    Color(red: 0.72, green: 0.84, blue: 0.65)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14 * scale))
        .overlay {
            RoundedRectangle(cornerRadius: 14 * scale)
                .stroke(
                    Color(red: 0.20, green: 0.35, blue: 0.20).opacity(0.35),
                    lineWidth: max(1.5 * scale, 0.75)
                )
        }
        .shadow(color: .black.opacity(0.12), radius: 2 * scale, y: scale)
    }

    private func capacityBar(
        capacity: Int,
        scale: CGFloat
    ) -> some View {
        let progress = storageState.capacityProgress(for: capacity)

        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.60))
                Capsule()
                    .fill(green.opacity(0.85))
                    .frame(width: geometry.size.width * progress)
            }
            .overlay {
                Capsule()
                    .stroke(ink.opacity(0.35), lineWidth: max(scale, 0.5))
            }
        }
    }

    private func purchaseRequest(for storage: Storage) -> PurchaseRequest {
        PurchaseRequest(
            state: storageState,
            item: storage,
            requiredLocationTier: storageState.requiredLocationTier(
                for: storage
            )
        )
    }

    private func attemptPurchase(_ storage: Storage) {
        switch purchaseWorkflow.itemAvailability(
            for: purchaseRequest(for: storage)
        ) {
        case .available:
            pendingConfirmation = storage
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

    private func confirmPurchase(_ storage: Storage) {
        let result = purchaseWorkflow.complete(
            purchaseRequest(for: storage)
        )
        pendingConfirmation = nil

        switch result {
        case .completed:
            onClose()
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

    private func currency(_ value: Double) -> String {
        value.formatted(
            .currency(code: "USD")
                .precision(.fractionLength(0))
        )
    }
}

/// Normalized regions measured against the storage background. Keeping the
/// geometry here makes visual calibration independent of view behavior and
/// prevents one dynamic field from moving another.
private enum StorageLayout {
    static let closeButton = region(0.87, 0.042, 0.095, 0.055)

    static let currentArtwork = region(0.09, 0.215, 0.35, 0.22)
    static let currentInformation = region(0.47, 0.205, 0.45, 0.11325)
    static let currentCapacity = region(0.47, 0.323, 0.45, 0.075)
    static let currentProgress = region(0.49, 0.404, 0.41, 0.032)

    static let nextArtwork = region(0.09, 0.535, 0.35, 0.225)
    static let nextInformation = region(0.47, 0.526, 0.45, 0.11325)
    static let nextCapacity = region(0.47, 0.644, 0.45, 0.075)
    static let nextProgress = region(0.49, 0.725, 0.41, 0.032)
    static let purchaseButton = region(0.18, 0.775, 0.60, 0.0624)
    static let maximumStorage = region(0.13, 0.57, 0.74, 0.10)

    private static func region(
        _ x: CGFloat,
        _ y: CGFloat,
        _ width: CGFloat,
        _ height: CGFloat
    ) -> CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

private extension View {
    func place(
        in normalizedRegion: CGRect,
        canvasSize: CGSize,
        showsGuide: Bool
    ) -> some View {
        let width = normalizedRegion.width * canvasSize.width
        let height = normalizedRegion.height * canvasSize.height
        let centerX = normalizedRegion.midX * canvasSize.width
        let centerY = normalizedRegion.midY * canvasSize.height

        return frame(width: width, height: height)
            .overlay {
                if showsGuide {
                    Rectangle()
                        .stroke(.red, lineWidth: 1)
                }
            }
            .position(x: centerX, y: centerY)
    }
}
