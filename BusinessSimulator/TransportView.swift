import SwiftUI

struct TransportView: View {
    let transportState: TransportState
    let purchaseWorkflow: PurchaseWorkflow
    let onClose: () -> Void

    @State private var pendingConfirmation: Transport?
    @State private var purchaseWarning: GamePopupType?

    private let sourceSize = CGSize(width: 887, height: 1_774)
    private let ink = Color(red: 0.14, green: 0.19, blue: 0.22)
    private let navy = Color(red: 0.05, green: 0.22, blue: 0.34)
    private let green = Color(red: 0.05, green: 0.47, blue: 0.13)
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
                    Image("transport_view")
                        .resizable()
                        .frame(
                            width: renderedSize.width,
                            height: renderedSize.height
                        )

                    activeTransportArtwork(
                        renderedSize: renderedSize,
                        scale: scale
                    )

                    currentTransportInformation(
                        renderedSize: renderedSize,
                        scale: scale
                    )

                    availableUpgradeCards(
                        renderedSize: renderedSize,
                        scale: scale
                    )

                    Button(action: onClose) {
                        Color.clear
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .transportPlace(
                        in: TransportLayout.closeButton,
                        canvasSize: renderedSize,
                        showsGuide: showsLayoutGuides
                    )
                    .accessibilityLabel("Close Transport")
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

    @ViewBuilder
    private func activeTransportArtwork(
        renderedSize: CGSize,
        scale: CGFloat
    ) -> some View {
        if let primary = transportState.activePrimaryTier {
            GameIconView(
                icon: primary.transport.smallIcon,
                size: 380 * scale
            )
            .transportPlace(
                in: TransportLayout.primaryArtwork,
                canvasSize: renderedSize,
                showsGuide: showsLayoutGuides
            )
        }

        if let secondary = transportState.activeSecondaryTier {
            GameIconView(
                icon: secondary.transport.smallIcon,
                size: 270 * scale
            )
            .transportPlace(
                in: TransportLayout.secondaryArtwork,
                canvasSize: renderedSize,
                showsGuide: showsLayoutGuides
            )
        }

        if transportState.activePrimaryTier == nil {
            Text("NO ACTIVE TRANSPORT")
                .font(.system(size: 31 * scale, weight: .black))
                .foregroundStyle(navy.opacity(0.75))
                .transportPlace(
                    in: TransportLayout.emptyArtwork,
                    canvasSize: renderedSize,
                    showsGuide: showsLayoutGuides
                )
        }
    }

    private func currentTransportInformation(
        renderedSize: CGSize,
        scale: CGFloat
    ) -> some View {
        Group {
            currentTransportPanel(
                tier: transportState.activePrimaryTier,
                track: .primary,
                scale: scale
            )
            .transportPlace(
                in: TransportLayout.currentPrimary,
                canvasSize: renderedSize,
                showsGuide: showsLayoutGuides
            )

            currentTransportPanel(
                tier: transportState.activeSecondaryTier,
                track: .secondary,
                scale: scale
            )
            .transportPlace(
                in: TransportLayout.currentSecondary,
                canvasSize: renderedSize,
                showsGuide: showsLayoutGuides
            )
        }
    }

    private func currentTransportPanel(
        tier: TransportTier?,
        track: TransportTrack,
        scale: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 10 * scale) {
            Text(track.displayName.uppercased())
                .font(.system(size: 22 * scale, weight: .black))
                .foregroundStyle(Color(red: 0.62, green: 0.18, blue: 0.12))

            if let tier {
                Text(tier.transport.name)
                    .font(
                        .system(
                            size: 35 * scale,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(navy)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)

                Text("Level \(tier.level)")
                    .font(.system(size: 25 * scale, weight: .bold))
                    .foregroundStyle(ink)

                Text(
                    "Market-size contribution: \(marketSizePercent(for: tier))%"
                )
                .font(.system(size: 22 * scale, weight: .semibold))
                .foregroundStyle(ink.opacity(0.82))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            } else {
                Text("No \(track.displayName) Transport")
                    .font(
                        .system(
                            size: 29 * scale,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(navy.opacity(0.68))
                    .lineLimit(2)
                    .minimumScaleFactor(0.70)

                Text(track.emptyDescription)
                    .font(.system(size: 21 * scale, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.72))
                    .lineLimit(3)
            }
        }
        .padding(16 * scale)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }

    @ViewBuilder
    private func availableUpgradeCards(
        renderedSize: CGSize,
        scale: CGFloat
    ) -> some View {
        let nextTiers = transportState.nextTiers

        if nextTiers.isEmpty {
            Text("ALL TRANSPORT UPGRADES COMPLETE")
                .font(.system(size: 28 * scale, weight: .black))
                .foregroundStyle(navy)
                .transportPlace(
                    in: TransportLayout.maximumTransport,
                    canvasSize: renderedSize,
                    showsGuide: showsLayoutGuides
                )
        } else {
            ForEach(Array(nextTiers.enumerated()), id: \.element.id) {
                index, tier in
                upgradeCard(tier, scale: scale)
                    .transportPlace(
                        in: TransportLayout.upgradeCard(at: index),
                        canvasSize: renderedSize,
                        showsGuide: showsLayoutGuides
                    )
            }
        }
    }

    private func upgradeCard(
        _ tier: TransportTier,
        scale: CGFloat
    ) -> some View {
        ZStack {
            Image("transport_purchase_card")
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            GeometryReader { geometry in
                let size = geometry.size

                GameIconView(
                    icon: tier.transport.smallIcon,
                    size: min(size.width * 0.30, size.height * 0.88)
                )
                .frame(
                    width: size.width * 0.32,
                    height: size.height * 0.84
                )
                .position(x: size.width * 0.18, y: size.height * 0.52)

                VStack(alignment: .leading, spacing: 4 * scale) {
                    HStack(alignment: .firstTextBaseline, spacing: 7 * scale) {
                        Text(tier.transport.name)
                            .font(
                                .system(
                                    size: 29 * scale,
                                    weight: .black,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(navy)
                            .lineLimit(2)
                            .minimumScaleFactor(0.60)

                        Text(tier.track.displayName)
                            .font(.system(size: 17 * scale, weight: .black))
                            .foregroundStyle(ink.opacity(0.82))
                            .padding(.horizontal, 7 * scale)
                            .padding(.vertical, 3 * scale)
                            .background(Color(red: 0.88, green: 0.77, blue: 0.59))
                            .clipShape(RoundedRectangle(cornerRadius: 5 * scale))
                    }

                    Text("Level \(tier.level) · +\(marketSizePercent(for: tier))% market-size progress")
                        .font(.system(size: 20 * scale, weight: .black))
                        .foregroundStyle(ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    Text(tier.transport.description)
                        .font(.system(size: 18 * scale, weight: .semibold))
                        .foregroundStyle(ink.opacity(0.82))
                        .lineLimit(3)
                        .minimumScaleFactor(0.72)
                }
                .frame(
                    width: size.width * 0.39,
                    height: size.height * 0.76,
                    alignment: .topLeading
                )
                .position(x: size.width * 0.56, y: size.height * 0.51)

                VStack(spacing: 10 * scale) {
                    Text(priceLabel(for: tier.transport))
                        .font(.system(size: 27 * scale, weight: .black))
                        .foregroundStyle(Color(red: 0.62, green: 0.10, blue: 0.08))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)

                    Button {
                        attemptPurchase(tier.transport)
                    } label: {
                        Text("PURCHASE")
                            .font(.system(size: 23 * scale, weight: .black))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(green)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12 * scale)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 12 * scale)
                                    .stroke(
                                        ink.opacity(0.75),
                                        lineWidth: max(2 * scale, 1)
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .frame(height: size.height * 0.30)
                    .accessibilityLabel(
                        "Purchase \(tier.transport.name)"
                    )
                }
                .frame(
                    width: size.width * 0.20,
                    height: size.height * 0.68
                )
                .position(x: size.width * 0.86, y: size.height * 0.52)
            }
        }
    }

    private func marketSizePercent(for tier: TransportTier) -> Int {
        Int((tier.trackProgress * 100).rounded())
    }

    private func priceLabel(for transport: Transport) -> String {
        guard transport.price > 0 else { return "PRICE TBD" }

        return transport.price.formatted(
            .currency(code: "USD")
                .precision(.fractionLength(0))
        ) + "/WK"
    }

    private func purchaseRequest(for transport: Transport) -> PurchaseRequest {
        PurchaseRequest(
            state: transportState,
            item: transport,
            requiredLocationTier: transportState.requiredLocationTier(
                for: transport
            )
        )
    }

    private func attemptPurchase(_ transport: Transport) {
        switch purchaseWorkflow.itemAvailability(
            for: purchaseRequest(for: transport)
        ) {
        case .available:
            pendingConfirmation = transport
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

    private func confirmPurchase(_ transport: Transport) {
        let result = purchaseWorkflow.complete(
            purchaseRequest(for: transport)
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
}

private extension TransportTrack {
    var displayName: String {
        switch self {
        case .primary:
            return "Primary"
        case .secondary:
            return "Secondary"
        }
    }

    var emptyDescription: String {
        switch self {
        case .primary:
            return "Purchase a primary vehicle to begin delivering products."
        case .secondary:
            return "Secondary Transport becomes available after Primary Level 1."
        }
    }
}

/// Normalized regions measured against the 887 x 1774 Transport background.
/// Text and controls live inside these invisible containers so dynamic content
/// retains the spacing and visual structure supplied by the artwork.
private enum TransportLayout {
    static let closeButton = region(0.86, 0.012, 0.105, 0.060)

    static let primaryArtwork = region(0.10, 0.105, 0.52, 0.215)
    static let secondaryArtwork = region(0.59, 0.145, 0.32, 0.165)
    static let emptyArtwork = region(0.22, 0.19, 0.56, 0.07)

    static let currentPrimary = region(0.055, 0.365, 0.43, 0.142)
    static let currentSecondary = region(0.515, 0.365, 0.43, 0.142)

    static let maximumTransport = region(0.13, 0.64, 0.74, 0.10)

    static func upgradeCard(at index: Int) -> CGRect {
        index == 0
            ? region(0.025, 0.575, 0.95, 0.145)
            : region(0.025, 0.730, 0.95, 0.145)
    }

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
    func transportPlace(
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
                        .fill(.red.opacity(0.12))
                        .overlay {
                            Rectangle().stroke(.red, lineWidth: 1)
                        }
                }
            }
            .position(x: centerX, y: centerY)
    }
}
