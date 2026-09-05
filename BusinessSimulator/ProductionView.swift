import SwiftUI

struct ProductionView: View {
    let product: Product
    let equipmentState: EquipmentState

    @State private var showingEquipment = false
    @State private var selectedEquipmentTab: EquipmentViewTab = .primary
    @State private var selectedSecondaryEquipmentID: EquipmentID?

    private let sourceSize = CGSize(width: 851, height: 1_849)
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
                Image("production_background")
                    .resizable()
                    .frame(
                        width: renderedSize.width,
                        height: renderedSize.height
                    )

                productionButton(
                    title: "Equipment",
                    systemImage: "gearshape.fill",
                    scale: scale,
                    action: {
                        selectedEquipmentTab = .primary
                        showingEquipment = true
                    }
                )
                .position(
                    x: 650 * scale,
                    y: 550 * scale
                )

                productionButton(
                    title: "Labor",
                    systemImage: "person.2.fill",
                    scale: scale
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
        .sheet(isPresented: $showingEquipment) {
            equipmentSheet
                .presentationDetents([.fraction(0.9)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
        }
    }

    private var equipmentSheet: some View {
        return ZStack(alignment: .topTrailing) {
            Color(red: 0.97, green: 0.90, blue: 0.75)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                equipmentTabs

                Group {
                    switch selectedEquipmentTab {
                    case .primary:
                        EquipmentViewPrimary(
                            activeTier: equipmentState.activePrimaryTier,
                            availableTier: equipmentState.nextPrimaryTier
                        )
                    case .secondary:
                        EquipmentViewSecondary(
                            ownedEquipment:
                                equipmentState.ownedSecondaryEquipment,
                            availableEquipment:
                                equipmentState.availableSecondaryEquipment,
                            selectedEquipmentID:
                                selectedSecondaryEquipmentID,
                            onEquipmentTapped: { equipment in
                                // The equipment-detail popup will be connected
                                // after its design is finalized.
                                selectedSecondaryEquipmentID = equipment.id
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Button {
                showingEquipment = false
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.78))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .padding(.trailing, 14)
            .accessibilityLabel("Close equipment")
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
        .padding(.horizontal, 8)
        .padding(.trailing, 42)
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
            Text(title.uppercased())
                .font(.subheadline.weight(.black))
                .foregroundStyle(
                    selectedEquipmentTab == tab ? .white : Color.brown
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    selectedEquipmentTab == tab
                        ? Color(red: 0.05, green: 0.39, blue: 0.20)
                        : Color.white.opacity(0.35)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brown.opacity(0.55), lineWidth: 1.5)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
