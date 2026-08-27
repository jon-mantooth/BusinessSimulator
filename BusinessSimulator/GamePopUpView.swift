import SwiftUI

enum GamePopupType {
    case newJourneyConfirmation
    case upgradeConfirmation(
        itemName: String,
        icon: GameIcon
    )
    case insufficientFunds
    case operatingReserveRequired

    var title: String {
        switch self {
        case .newJourneyConfirmation:
            return "BEGIN A NEW JOURNEY?"
        case .upgradeConfirmation:
            return "CONFIRM UPGRADE"
        case .insufficientFunds,
             .operatingReserveRequired:
            return "PURCHASE UNAVAILABLE"
        }
    }

    var message: String {
        switch self {
        case .newJourneyConfirmation:
            return "Starting a new journey will replace your current saved game."
        case let .upgradeConfirmation(itemName, _):
            return "Select \(itemName) as your new upgrade?"
        case .insufficientFunds:
            return "You do not have enough money for this purchase."
        case .operatingReserveRequired:
            return "You must have enough money remaining to purchase ingredients."
        }
    }

    var icon: GameIcon {
        switch self {
        case .newJourneyConfirmation:
            return .system("exclamationmark.triangle.fill")
        case let .upgradeConfirmation(_, icon):
            return icon
        case .insufficientFunds:
            return .system("dollarsign.circle.fill")
        case .operatingReserveRequired:
            return .system("basket.fill")
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .newJourneyConfirmation:
            return "NEW JOURNEY"
        case .upgradeConfirmation:
            return "CONFIRM"
        case .insufficientFunds,
             .operatingReserveRequired:
            return "OK"
        }
    }

    var showsCancelButton: Bool {
        switch self {
        case .newJourneyConfirmation,
             .upgradeConfirmation:
            return true
        case .insufficientFunds,
             .operatingReserveRequired:
            return false
        }
    }

    var isDestructive: Bool {
        if case .newJourneyConfirmation = self {
            return true
        }

        return false
    }
}

struct GamePopupView: View {
    let type: GamePopupType
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    private let ink = Color(red: 0.18, green: 0.14, blue: 0.11)
    private let navy = Color(red: 0.10, green: 0.25, blue: 0.34)
    private let fadedRed = Color(red: 0.63, green: 0.19, blue: 0.17)
    private let paper = Color(red: 0.96, green: 0.90, blue: 0.76)
    private let palePaper = Color(red: 1.00, green: 0.97, blue: 0.88)

    var body: some View {
        ZStack {
            Color.black.opacity(0.52)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                GameIconView(icon: type.icon, size: 38)

                Text(type.title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(navy)

                Text(type.message)
                    .font(.subheadline)
                    .foregroundStyle(ink.opacity(0.82))
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    if type.showsCancelButton {
                        popupButton(
                            title: "CANCEL",
                            foregroundColor: fadedRed,
                            backgroundColor: palePaper,
                            borderColor: fadedRed,
                            action: onDismiss
                        )
                    }

                    popupButton(
                        title: type.primaryButtonTitle,
                        foregroundColor: palePaper,
                        backgroundColor:
                            type.isDestructive ? fadedRed : navy,
                        borderColor: .clear,
                        action: type.showsCancelButton
                            ? onConfirm
                            : onDismiss
                    )
                }
                .font(.caption.weight(.black))
            }
            .padding(22)
            .frame(maxWidth: 310)
            .background(paper)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(fadedRed, lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
            .padding(.horizontal, 28)
        }
        .transition(.scale.combined(with: .opacity))
        .zIndex(10)
    }

    private func popupButton(
        title: String,
        foregroundColor: Color,
        backgroundColor: Color,
        borderColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(borderColor, lineWidth: 1.5)
            }
            .buttonStyle(.plain)
    }
}
