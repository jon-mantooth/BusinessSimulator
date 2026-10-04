import Foundation
import SwiftUI

struct LocationSelectionView: View {
    let location: Location
    let availability: RelocationItemAvailability
    let canRelocate: Bool
    let relocationCost: Double
    let onRelocate: () -> Void
    let onClose: () -> Void

    private let panelAspectRatio = 2.0 / 3.0
    private let navy = Color(red: 0.03, green: 0.22, blue: 0.38)
    private let mutedBlue = Color(red: 0.22, green: 0.35, blue: 0.45)
    private let parchment = Color(red: 0.97, green: 0.82, blue: 0.53)

    var body: some View {
        GeometryReader { geometry in
            let panelSize = fittedPanelSize(in: geometry.size)

            ZStack {
                Color.black.opacity(0.38)
                    .ignoresSafeArea()

                ZStack {
                    Image("location_selection_panel")
                        .resizable()
                        .scaledToFit()

                    locationImage(panelSize: panelSize)
                    locationIdentity(panelSize: panelSize)
                    benefits(panelSize: panelSize)
                    requirements(panelSize: panelSize)
                    relocateButton(panelSize: panelSize)
                    relocationHelp(panelSize: panelSize)
                    closeButton(panelSize: panelSize)
                }
                .frame(width: panelSize.width, height: panelSize.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func locationImage(panelSize: CGSize) -> some View {
        if let locationImageName {
            Image(locationImageName)
                .resizable()
                .scaledToFill()
                .frame(
                    width: panelSize.width * 0.953,
                    height: panelSize.height * 0.240
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: panelSize.width * 0.008
                    )
                )
                .position(
                    x: panelSize.width * 0.5,
                    y: panelSize.height * 0.132
                )
        }
    }

    private var locationImageName: String? {
        switch location.id.rawValue {
        case "ballpark":
            return "baseball_image"
        case "farmers-market":
            return "farmers_market_image"
        case "beach":
            return "beach_image"
        default:
            return nil
        }
    }

    private func locationIdentity(panelSize: CGSize) -> some View {
        VStack(spacing: 1) {
            Text(location.name.uppercased())
                .font(.system(size: 20, weight: .black, design: .serif))
                .foregroundStyle(navy)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(tagline)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .italic()
                .foregroundStyle(mutedBlue)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(width: panelSize.width * 0.58)
        .position(
            x: panelSize.width * 0.60,
            y: panelSize.height * 0.292
        )
    }

    private func benefits(panelSize: CGSize) -> some View {
        HStack(spacing: panelSize.width * 0.05) {
            benefit(
                title: benefitContent.first.title,
                description: benefitContent.first.description
            )
            benefit(
                title: benefitContent.second.title,
                description: benefitContent.second.description
            )
        }
        .frame(width: panelSize.width * 0.78)
        .position(
            x: panelSize.width * 0.51,
            y: panelSize.height * 0.445
        )
    }

    private func benefit(
        title: String,
        description: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(navy)

            Text(description)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(mutedBlue)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func requirements(panelSize: CGSize) -> some View {
        ZStack {
            ForEach(
                Array(orderedRequirements.enumerated()),
                id: \.offset
            ) { index, status in
                requirementValue(status)
                    .position(
                        x: panelSize.width * 0.75,
                        y: panelSize.height
                            * (0.5625 + Double(index) * 0.0445)
                    )

                if status.isMet {
                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(.red)
                        .position(
                            x: panelSize.width * 0.914,
                            y: panelSize.height
                                * (0.5625 + Double(index) * 0.0445)
                        )
                }
            }

            Text(relocationCost, format: .currency(code: "USD"))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(navy)
                .position(
                    x: panelSize.width * 0.75,
                    y: panelSize.height * 0.842
                )

            if availability.financialAvailability == .available {
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.red)
                    .position(
                        x: panelSize.width * 0.914,
                        y: panelSize.height * 0.842
                    )
            }
        }
        .frame(width: panelSize.width, height: panelSize.height)
    }

    private func requirementValue(
        _ status: RelocationRequirementStatus
    ) -> some View {
        let currentValue = status.currentValue ?? 0
        let text: String

        switch status.requirement {
        case .businessReputation:
            text = String(format: "%.1f / %.1f", currentValue, status.requiredValue)
        case .advertisementLevel:
            text = "Level \(Int(currentValue)) / \(Int(status.requiredValue))"
        case .equipmentLevel, .storageLevel:
            text = "Level \(Int(currentValue)) / \(Int(status.requiredValue))"
        case .laborLevel, .transportationLevel:
            text = "\(Int(currentValue)) / \(Int(status.requiredValue))"
        }

        return Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(navy)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .frame(width: 84)
    }

    private var orderedRequirements: [RelocationRequirementStatus] {
        let displayOrder: [RelocationRequirement] = [
            .businessReputation,
            .advertisementLevel,
            .equipmentLevel,
            .laborLevel,
            .storageLevel,
            .transportationLevel
        ]

        return displayOrder.compactMap { requirement in
            availability.requirements.first {
                $0.requirement == requirement
            }
        }
    }

    private func relocateButton(panelSize: CGSize) -> some View {
        Button(action: onRelocate) {
            Text("RELOCATE")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(canRelocate ? 1 : 0.62))
                .frame(
                    width: panelSize.width * 0.60,
                    height: panelSize.height * 0.052
                )
                .background(
                    canRelocate
                        ? Color(red: 0.13, green: 0.55, blue: 0.25)
                        : Color(red: 0.34, green: 0.38, blue: 0.40)
                )
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(navy.opacity(0.85), lineWidth: 3)
                        .padding(2)
                }
                .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .position(
            x: panelSize.width * 0.5,
            y: panelSize.height * 0.922
        )
    }

    private func relocationHelp(panelSize: CGSize) -> some View {
        Text("Relocation takes effect immediately.")
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .italic()
        .foregroundStyle(mutedBlue)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(width: panelSize.width * 0.72)
        .position(
            x: panelSize.width * 0.5,
            y: panelSize.height * 0.963
        )
    }

    private func closeButton(panelSize: CGSize) -> some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .frame(
                    width: panelSize.width * 0.10,
                    height: panelSize.width * 0.10
                )
                .background(Color.red.opacity(0.95))
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(parchment, lineWidth: 3)
                }
                .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .position(
            x: panelSize.width * 0.94,
            y: panelSize.height * 0.045
        )
        .accessibilityLabel("Close location details")
    }

    private func fittedPanelSize(in availableSize: CGSize) -> CGSize {
        let availableAspectRatio = availableSize.width / availableSize.height

        if availableAspectRatio > panelAspectRatio {
            return CGSize(
                width: availableSize.height * panelAspectRatio,
                height: availableSize.height
            )
        }

        return CGSize(
            width: availableSize.width,
            height: availableSize.width / panelAspectRatio
        )
    }

    private var tagline: String {
        switch location.id.rawValue {
        case "ballpark":
            return "Serve game-day crowds all season long."
        case "farmers-market":
            return "Meet shoppers looking for something fresh."
        case "beach":
            return "Build your business beside the boardwalk."
        default:
            return location.description
        }
    }

    private var benefitContent: (
        first: (title: String, description: String),
        second: (title: String, description: String)
    ) {
        switch location.id.rawValue {
        case "ballpark":
            return (
                ("Bigger Crowds", "Reach thousands of game-day visitors."),
                ("New Growth", "Unlock the next stage of your business.")
            )
        case "farmers-market":
            return (
                ("More Shoppers", "Sell to a larger seasonal market."),
                ("New Growth", "Unlock the next stage of your business.")
            )
        case "beach":
            return (
                ("Beach Traffic", "Reach busy warm-weather crowds."),
                ("New Growth", "Unlock the next stage of your business.")
            )
        default:
            return (
                ("Established", "Your business began at this location."),
                ("Neighborhood", "Serve the customers closest to home.")
            )
        }
    }
}
