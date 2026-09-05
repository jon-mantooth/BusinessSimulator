import SwiftUI

struct EquipmentViewPrimary: View {
    let activeTier: EquipmentTier
    let availableTier: EquipmentTier?

    private let green = Color(red: 0.05, green: 0.39, blue: 0.20)
    private let ink = Color(red: 0.20, green: 0.12, blue: 0.06)
    private let paper = Color(red: 1.00, green: 0.97, blue: 0.88)

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
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
            .padding(14)
        }
        .scrollIndicators(.hidden)
    }

    private func equipmentSection(
        title: String,
        tier: EquipmentTier,
        isActive: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .padding(.vertical, 9)
                .padding(.horizontal, 18)
                .background(green)
                .clipShape(RoundedRectangle(cornerRadius: 8))

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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                equipmentPlaceholder(equipment)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(equipment.name)
                            .font(.title3.weight(.black))
                            .foregroundStyle(ink)

                        Spacer()

                        Text("Level \(tierLevel)")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.brown.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Text(equipment.description)
                        .font(.caption)
                        .foregroundStyle(ink.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    ratingRow(
                        title: "Demand",
                        level: equipment.demandLevel,
                        totalLevels: equipment.totalLevels
                    )

                    metricRow(
                        title: "Production Capacity",
                        value: "\(equipment.capacity) / day"
                    )
                    metricRow(
                        title: "Cost (One-Time)",
                        value: isActive
                            ? "\(formattedPrice(equipment.price)) (Owned)"
                            : formattedPrice(equipment.price)
                    )
                }
            }

            if !isActive {
                Button {
                    // Purchase workflow will be connected with EquipmentState.
                } label: {
                    Text("PURCHASE")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(paper.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brown.opacity(0.25), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
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

            GameIconView(icon: equipment.smallIcon, size: 46)
        }
        .frame(width: 105, height: 125)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func ratingRow(
        title: String,
        level: Int,
        totalLevels: Int
    ) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.black))

            Spacer()

            HStack(spacing: 2) {
                ForEach(1...totalLevels, id: \.self) { star in
                    Image(systemName: star <= level ? "star.fill" : "star")
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
                .font(.caption2.weight(.black))
                .foregroundStyle(ink)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(green)
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
