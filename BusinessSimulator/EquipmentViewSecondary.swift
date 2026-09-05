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
