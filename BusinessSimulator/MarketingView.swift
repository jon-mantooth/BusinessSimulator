import SwiftUI

struct MarketingView: View {
    let product: Product
    let reputation: BusinessReputationState
    let advertisementState: AdvertisementState
    let finance: Finance
    let upgradeTracker: UpgradeTracker
    let simulationDay: Int

    @State private var showingBusinessReputation = false
    @State private var showingAdvertisement = false
    @State private var showingAdvertisementUpgradeLimit = false

    private let sourceSize = CGSize(width: 1024, height: 1536)

    private var flyerImageName: String {
        switch product.id {
        case .hotDogs:
            return "hot_dog_flyer"
        case .smoothies:
            return "smoothie_flyer"
        case .pies:
            return "pie_flyer"
        }
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
                    Image("marketing_background")
                        .resizable()
                        .frame(
                            width: renderedSize.width,
                            height: renderedSize.height
                        )

                    Image(flyerImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 192 * scale)
                        .position(
                            x: 390 * scale,
                            y: 475 * scale
                        )

                    marketingButton(
                        title: "Advertisement",
                        systemImage: "megaphone.fill",
                        scale: scale,
                        action: {
                            if upgradeTracker.canUpgrade(
                                .advertisement,
                                on: simulationDay
                            ) {
                                showingAdvertisement = true
                            } else {
                                showingAdvertisementUpgradeLimit = true
                            }
                        }
                    )
                    .position(
                        x: 380 * scale,
                        y: 690 * scale
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
                        x: 700 * scale,
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
                    type: .upgradeLimitReached(
                        upgradeName: "advertising"
                    ),
                    onConfirm: {},
                    onDismiss: {
                        showingAdvertisementUpgradeLimit = false
                    }
                )
            }

        }
        .animation(.easeInOut(duration: 0.2), value: showingBusinessReputation)
        .sheet(isPresented: $showingAdvertisement) {
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
