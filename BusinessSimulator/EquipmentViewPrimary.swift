import SwiftUI

struct EquipmentViewPrimary: View {
    let activeTier: EquipmentTier
    let availableTier: EquipmentTier?
    let purchaseAvailability: (Equipment) -> PurchaseAvailability
    let onPurchase: (Equipment) -> Void

    private let green = Color(red: 0.05, green: 0.39, blue: 0.20)
    private let ink = Color(red: 0.20, green: 0.12, blue: 0.06)
    private let paper = Color(red: 1.00, green: 0.97, blue: 0.88)

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                equipmentSection(
                    title: "Active Equipment",
                    tier: activeTier,
                    isActive: true
                )

                if let availableTier {
                    equipmentSection(
                        title: "Available Equipment",
                        tier: availableTier,
                        isActive: false
                    )
                } else {
                    Text("All primary equipment upgrades are complete.")
                        .font(.headline)
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(paper.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 34)
        }
        .scrollIndicators(.hidden)
    }

    private func equipmentSection(
        title: String,
        tier: EquipmentTier,
        isActive: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: -8) {
            ZStack {
                Image("equipment_section_placard")
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(title.uppercased())
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(paper)
                    .shadow(color: .black.opacity(0.65), radius: 1, y: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 28)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .zIndex(1)

            ForEach(tier.equipment) { equipment in
                equipmentCard(
                    equipment,
                    tierLevel: tier.level,
                    isActive: isActive
                )
            }
        }
    }

    private func equipmentCard(
        _ equipment: Equipment,
        tierLevel: Int,
        isActive: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                equipmentPlaceholder(equipment)

                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(equipment.name)
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.68)
                            .allowsTightening(true)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 36,
                                maxHeight: 36,
                                alignment: .topLeading
                            )
                            .padding(.trailing, 54)

                        Text(equipment.description)
                            .font(.system(size: 10.5))
                            .foregroundStyle(ink.opacity(0.75))
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 44,
                                maxHeight: 44,
                                alignment: .topLeading
                            )

                        Divider()
                            .padding(.bottom, 5)

                        ratingRow(
                            title: "Demand",
                            level: equipment.demandLevel,
                            totalLevels: equipment.totalLevels
                        )
                        .frame(height: 18)

                        metricRow(
                            title: "Production Capacity",
                            value: "\(equipment.capacity) / day"
                        )
                        .frame(height: 24)

                        metricRow(
                            title: "Cost (One-Time)",
                            value: isActive
                                ? "\(formattedPrice(equipment.price)) (Owned)"
                                : formattedPrice(equipment.price)
                        )
                        .frame(height: 24)
                    }

                    Text("Level \(tierLevel)")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.brown.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(height: 152, alignment: .top)
            }
            .frame(height: 152, alignment: .top)

            if !isActive {
                Button {
                    onPurchase(equipment)
                } label: {
                    ZStack {
                        Image("equipment_button")
                            .resizable()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .saturation(
                                purchaseButtonSaturation(for: equipment)
                            )

                        Text(purchaseButtonTitle(for: equipment))
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .padding(.horizontal, 18)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .frame(height: 40)
                .padding(.horizontal, 28)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 28)
        .background {
            Image("equipment_card")
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func purchaseButtonTitle(
        for equipment: Equipment
    ) -> String {
        switch purchaseAvailability(equipment) {
        case .available:
            return "PURCHASE"
        case .insufficientFunds:
            return "NOT ENOUGH MONEY"
        case .operatingReserveRequired:
            return "KEEP FUNDS FOR INGREDIENTS"
        }
    }

    private func purchaseButtonSaturation(
        for equipment: Equipment
    ) -> Double {
        switch purchaseAvailability(equipment) {
        case .available:
            return 1
        case .insufficientFunds, .operatingReserveRequired:
            return 0
        }
    }

    private func equipmentPlaceholder(
        _ equipment: Equipment
    ) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color.brown.opacity(0.12), Color.orange.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GameIconView(icon: equipment.smallIcon, size: 100)
        }
        .frame(width: 118, height: 142)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func ratingRow(
        title: String,
        level: Int,
        totalLevels: Int
    ) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 9.5, weight: .black))

            Spacer()

            HStack(spacing: 2) {
                ForEach(1...totalLevels, id: \.self) { star in
                    Image(systemName: star <= level ? "star.fill" : "star")
                        .font(.system(size: 13))
                        .foregroundStyle(star <= level ? .orange : .brown)
                }
            }
        }
        .foregroundStyle(ink)
    }

    private func metricRow(
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.system(size: 8.5, weight: .black))
                .foregroundStyle(ink)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(green)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.trailing)
        }
    }

    private func formattedPrice(
        _ price: Double
    ) -> String {
        price.formatted(
            .currency(code: "USD")
                .precision(.fractionLength(0))
        )
    }
}
