import SwiftUI

struct DistributionView: View {
    let storageState: StorageState
    let purchaseWorkflow: PurchaseWorkflow

    @State private var showingStorage = false
    @State private var showingStorageUpgradeLimit = false

    private let sourceSize = CGSize(width: 852, height: 1_846)
    private let darkBrown = Color(red: 0.20, green: 0.12, blue: 0.06)
    private let warmGold = Color(red: 0.91, green: 0.65, blue: 0.25)
    private let paleGold = Color(red: 1.00, green: 0.91, blue: 0.60)

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
                .position(x: 615 * scale, y: 635 * scale)

                distributionButton(
                    title: "Transport",
                    systemImage: "truck.box.fill",
                    scale: scale,
                    action: {}
                )
                .position(x: 245 * scale, y: 915 * scale)
            }
            .frame(width: renderedSize.width, height: renderedSize.height)
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
        }
        .clipped()
        .sheet(isPresented: $showingStorage) {
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
