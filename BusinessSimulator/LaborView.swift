import SwiftUI

struct LaborView: View {
    let laborState: LaborState
    let onClose: () -> Void

    private let ink = Color(red: 0.20, green: 0.12, blue: 0.06)
    private let green = Color(red: 0.06, green: 0.36, blue: 0.18)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image("labor_background")
                .resizable()
                .ignoresSafeArea()

            ScrollView {
                HStack(alignment: .top, spacing: 10) {
                    employeeColumn(
                        title: "Your Team",
                        subtitle: "Owned",
                        employees: laborState.ownedLabor.labor,
                        capacity: laborState.totalCapacity,
                        demandLevel: laborState.totalDemandLevel,
                        isOwned: true
                    )

                    employeeColumn(
                        title: "Available",
                        subtitle: "To Hire",
                        employees: laborState.availableLabor.labor,
                        capacity: laborState.availableLabor.totalCapacity,
                        demandLevel: laborState.availableLabor.totalDemandLevel,
                        isOwned: false
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 42)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(ink.opacity(0.9))
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(.white.opacity(0.8), lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .padding(.trailing, 12)
            .accessibilityLabel("Close labor")
        }
    }

    private func employeeColumn(
        title: String,
        subtitle: String,
        employees: [Labor],
        capacity: Int,
        demandLevel: Int,
        isOwned: Bool
    ) -> some View {
        VStack(spacing: 0) {
            summaryCard(
                title: title,
                subtitle: subtitle,
                capacity: capacity,
                demandLevel: demandLevel,
                isOwned: isOwned
            )

            ForEach(employees) { employee in
                employeeCard(employee, isOwned: isOwned)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func summaryCard(
        title: String,
        subtitle: String,
        capacity: Int,
        demandLevel: Int,
        isOwned: Bool
    ) -> some View {
        ZStack {
            Image(isOwned ? "header_card_green" : "header_card_yellow")
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 7) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(ink.opacity(0.82))

                Text(title)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitle.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ink.opacity(0.65))

                Divider()
                    .overlay(ink.opacity(0.35))

                Text(isOwned ? "TOTAL CAPACITY" : "CAPACITY AVAILABLE")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(ink.opacity(0.75))

                Text("\(isOwned ? "" : "+")\(capacity) / day")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(green)

                demandStars(level: demandLevel)
            }
            .padding(.horizontal, 18)
            .padding(.top, 21)
            .padding(.bottom, 14)
        }
        .frame(height: 165)
    }

    private func employeeCard(_ employee: Labor, isOwned: Bool) -> some View {
        ZStack {
            Image(cardAsset(for: employee))
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 5) {
                HStack(alignment: .center, spacing: 7) {
                    GameIconView(icon: employee.smallIcon, size: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 7))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(employee.name)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)

                        Text("+\(employee.capacity) capacity")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(green)

                        demandStars(level: employee.demandLevel)
                    }

                    Spacer(minLength: 0)
                }

                if isOwned {
                    Text("HIRED")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(green, lineWidth: 2)
                        }
                        .rotationEffect(.degrees(-5))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    HStack(spacing: 5) {
                        Text("$\(Int(employee.price)) / day")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(ink)

                        Spacer(minLength: 0)

                        Button("HIRE") {}
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(green)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 17)
            .padding(.bottom, 8)
        }
        .frame(height: 125)
    }

    private func cardAsset(for employee: Labor) -> String {
        let cardAssets = [
            "employee_card_red",
            "employee_card_green",
            "employee_card_yellow"
        ]
        let characterTotal = employee.id.rawValue.unicodeScalars.reduce(0) {
            $0 + Int($1.value)
        }
        return cardAssets[characterTotal % cardAssets.count]
    }

    private func demandStars(level: Int) -> some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= min(level, 5) ? "star.fill" : "star")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(star <= min(level, 5) ? .orange : .brown)
            }
        }
    }
}
