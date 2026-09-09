import SwiftUI

struct EquipmentViewSecondary: View {
    let ownedEquipment: SecondaryEquipmentCollection
    let availableEquipment: SecondaryEquipmentCollection
    let selectedEquipmentID: EquipmentID?
    let onEquipmentTapped: (Equipment) -> Void

    private let green = Color(red: 0.05, green: 0.39, blue: 0.20)
    private let ink = Color(red: 0.20, green: 0.12, blue: 0.06)
    private let paper = Color(red: 1.00, green: 0.97, blue: 0.88)

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 10) {
                equipmentColumn(
                    title: "Owned Equipment",
                    equipment: ownedEquipment.equipment,
                    isOwned: true
                )

                equipmentColumn(
                    title: "Available Equipment",
                    equipment: availableEquipment.equipment,
                    isOwned: false
                )
            }
            .padding(12)
        }
        .scrollIndicators(.hidden)
    }

    private func equipmentColumn(
        title: String,
        equipment: [Equipment],
        isOwned: Bool
    ) -> some View {
        VStack(spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(green)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            summaryCard(
                capacity: equipment.reduce(0) { $0 + $1.capacity },
                demand: equipment.reduce(0) { $0 + $1.demandLevel }
            )

            if equipment.isEmpty {
                Text(isOwned ? "No prep equipment owned yet." : "No equipment available.")
                    .font(.caption)
                    .foregroundStyle(ink.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(paper.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            ForEach(equipment) { item in
                Button {
                    onEquipmentTapped(item)
                } label: {
                    equipmentCard(item, isOwned: isOwned)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func summaryCard(
        capacity: Int,
        demand: Int
    ) -> some View {
        VStack(spacing: 7) {
            Text("TOTAL CAPACITY")
                .font(.caption2.weight(.black))
            Text("+\(capacity) / day")
                .font(.headline.weight(.black))
                .foregroundStyle(green)

            HStack(spacing: 1) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= demand ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(star <= demand ? .orange : .brown)
                }
            }
        }
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(paper.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func equipmentCard(
        _ equipment: Equipment,
        isOwned: Bool
    ) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brown.opacity(0.10))

                GameIconView(icon: equipment.smallIcon, size: 36)
            }
            .frame(height: 78)

            Text(equipment.name)
                .font(.caption.weight(.bold))
                .foregroundStyle(ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            HStack(spacing: 4) {
                if isOwned {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Owned")
                } else {
                    Text("View")
                    Image(systemName: "chevron.right")
                }
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(green)
        }
        .frame(maxWidth: .infinity)
        .padding(9)
        .background(
            selectedEquipmentID == equipment.id
                ? Color.green.opacity(0.16)
                : paper.opacity(0.9)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    selectedEquipmentID == equipment.id
                        ? green
                        : Color.brown.opacity(0.24),
                    lineWidth: selectedEquipmentID == equipment.id ? 2 : 1
                )
        }
    }
}

struct SecondaryEquipmentDetailCard: View {
    let equipment: Equipment
    let isOwned: Bool
    let purchaseAvailability: PurchaseAvailability
    let onPurchase: () -> Void
    let onClose: () -> Void

    @State private var purchaseWarning: GamePopupType?

    private let green = Color(red: 0.05, green: 0.39, blue: 0.20)
    private let ink = Color(red: 0.20, green: 0.12, blue: 0.06)
    private let paper = Color(red: 1.00, green: 0.97, blue: 0.88)

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    Text(equipment.name.uppercased())
                        .font(.title2.weight(.black))
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(ink.opacity(0.84))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close equipment details")
                }

                equipmentPlaceholder

                Text(equipment.description)
                    .font(.subheadline)
                    .foregroundStyle(ink.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                detailRow(title: "Demand") {
                    HStack(spacing: 3) {
                        ForEach(1...equipment.totalLevels, id: \.self) {
                            star in
                            Image(
                                systemName: star <= equipment.demandLevel
                                    ? "star.fill"
                                    : "star"
                            )
                            .foregroundStyle(
                                star <= equipment.demandLevel
                                    ? .orange
                                    : .brown
                            )
                        }
                    }
                }

                detailRow(title: "Capacity Increase") {
                    Text("+\(equipment.capacity) / day")
                        .font(.headline.weight(.black))
                        .foregroundStyle(green)
                }

                if let equipmentBenefit = equipment.equipmentBenefit {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.orange)

                        Text(equipmentBenefit)
                            .font(.caption)
                            .foregroundStyle(ink.opacity(0.78))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                HStack {
                    Text("ONE-TIME COST")
                        .font(.caption.weight(.black))
                        .foregroundStyle(ink)

                    Spacer()

                    Text(formattedPrice)
                        .font(.title3.weight(.black))
                        .foregroundStyle(green)
                }

                purchaseButton
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [paper, Color(red: 0.94, green: 0.84, blue: 0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.brown.opacity(0.45), lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.35), radius: 16, y: 8)

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

    private var equipmentPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.brown.opacity(0.10))

            GameIconView(icon: equipment.smallIcon, size: 64)
        }
        .frame(height: 145)
    }

    private var formattedPrice: String {
        equipment.price.formatted(
            .currency(code: "USD")
                .precision(.fractionLength(0))
        )
    }

    @ViewBuilder
    private var purchaseButton: some View {
        if isOwned {
            Label("OWNED", systemImage: "checkmark.circle.fill")
                .font(.headline.weight(.black))
                .foregroundStyle(green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 13))
        } else {
            Button(action: handlePurchaseTap) {
                Text(purchaseButtonTitle)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(purchaseButtonColor)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }
            .buttonStyle(.plain)
        }
    }

    private var purchaseButtonTitle: String {
        switch purchaseAvailability {
        case .available:
            return "PURCHASE"
        case .insufficientFunds:
            return "NOT ENOUGH MONEY"
        case .operatingReserveRequired:
            return "KEEP FUNDS FOR INGREDIENTS"
        }
    }

    private var purchaseButtonColor: Color {
        switch purchaseAvailability {
        case .available:
            return green
        case .insufficientFunds, .operatingReserveRequired:
            return .gray
        }
    }

    private func handlePurchaseTap() {
        switch purchaseAvailability {
        case .available:
            onPurchase()
        case .insufficientFunds:
            purchaseWarning = .insufficientFunds
        case .operatingReserveRequired:
            purchaseWarning = .operatingReserveRequired
        }
    }

    private func detailRow<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.black))
                .foregroundStyle(ink)

            Spacer()

            content()
        }
    }
}
