import SwiftUI

struct AdvertisementView: View {
    let advertisementState: AdvertisementState
    let finance: Finance
    let onClose: () -> Void

    @State private var purchaseWarning: GamePopupType?
    @State private var advertisementPendingConfirmation: Advertisement?

    private let ink = Color(red: 0.18, green: 0.14, blue: 0.11)
    private let navy = Color(red: 0.10, green: 0.25, blue: 0.34)
    private let fadedRed = Color(red: 0.63, green: 0.19, blue: 0.17)
    private let paper = Color(red: 0.96, green: 0.90, blue: 0.76)
    private let palePaper = Color(red: 1.00, green: 0.97, blue: 0.88)

    private var nextTier: AdvertisementTier? {
        guard let activeLevel = advertisementState.activeTier?.level else {
            return nil
        }

        return advertisementState.tiers.first {
            $0.level == activeLevel + 1
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image("advertisement_background")
                .resizable()
                .scaledToFill()

            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 12) {
                        currentAdvertisement

                        if let nextTier {
                            VStack(spacing: 10) {
                                nextTierBanner(level: nextTier.level)

                                ForEach(nextTier.advertisements) {
                                    advertisement in
                                    upgradeCard(advertisement: advertisement)
                                }
                            }
                            .padding(8)
                            .background(palePaper.opacity(0.72))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        fadedRed.opacity(0.55),
                                        lineWidth: 1.5
                                    )
                            }
                            .shadow(
                                color: .black.opacity(0.1),
                                radius: 3,
                                y: 2
                            )
                        } else {
                            maximumTierMessage
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(fadedRed)

                            Text("Each campaign has different strengths. Choose the one that fits your strategy.")
                                .font(.caption)
                                .foregroundStyle(ink.opacity(0.78))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(palePaper.opacity(0.84))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.bottom, 12)
                    .scaleEffect(0.8, anchor: .top)
                }
                .scrollIndicators(.hidden)
                .padding(.top, geometry.size.height * 0.19)
                .padding(.horizontal, geometry.size.width * 0.07)
                .padding(.bottom, geometry.size.height * 0.025)
                .clipped()
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.black))
                    .foregroundStyle(palePaper)
                    .frame(width: 34, height: 34)
                    .background(ink.opacity(0.88))
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(paper, lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .padding(.trailing, 28)
            .accessibilityLabel("Close advertisement")

            if let advertisementPendingConfirmation {
                GamePopupView(
                    type: .upgradeConfirmation(
                        itemName: advertisementPendingConfirmation.name,
                        icon: advertisementPendingConfirmation.smallIcon
                    ),
                    onConfirm: onClose,
                    onDismiss: {
                        self.advertisementPendingConfirmation = nil
                    }
                )
            }

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.34), radius: 16, y: 8)
    }

    private var currentAdvertisement: some View {
        let advertisement = advertisementState.activeAdvertisement!

        return VStack(alignment: .leading, spacing: 8) {
            sectionBanner("CURRENT ADVERTISEMENT")

            HStack(spacing: 12) {
                GameIconView(icon: advertisement.smallIcon, size: 25)
                    .frame(width: 46, height: 46)
                    .background(paper.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(advertisement.name)
                            .font(.subheadline.weight(.bold))

                        Spacer()

                        Text("ACTIVE")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(palePaper)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(fadedRed)
                            .rotationEffect(.degrees(-2))
                    }

                    Text(advertisement.description)
                        .font(.system(size: 10))
                        .foregroundStyle(ink.opacity(0.72))

                    ratingRow(
                        title: "Demand",
                        level: advertisement.demandLevel
                    )
                    ratingRow(
                        title: "Market Size",
                        level: advertisement.marketSizeLevel
                    )
                }
            }
        }
        .paperCard(borderColor: navy)
    }

    private func upgradeCard(
        advertisement: Advertisement
    ) -> some View {
        let actionColor = actionColor(for: advertisement)
        let canSelectAdvertisement: Bool = {
            if case .available = finance.purchaseAvailability(
                for: advertisement.price
            ) {
                return true
            }

            return false
        }()

        return HStack(spacing: 10) {
            GameIconView(icon: advertisement.smallIcon, size: 30)
                .frame(width: 62, height: 76)
                .background(paper.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text(advertisement.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ink)

                ratingRow(
                    title: "Demand",
                    level: advertisement.demandLevel
                )
                ratingRow(
                    title: "Market Size",
                    level: advertisement.marketSizeLevel
                )

                Text(advertisement.description)
                    .font(.system(size: 10))
                    .foregroundStyle(ink.opacity(0.7))
                    .lineLimit(2)
            }

            Spacer(minLength: 2)

            VStack(spacing: 5) {
                Text(displayedPrice(for: advertisement))
                    .font(.headline.weight(.black))
                    .foregroundStyle(actionColor)

                Text(displayedSchedule(for: advertisement))
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(ink.opacity(0.6))

                Button("SELECT") {
                    attemptSelection(of: advertisement)
                }
                    .font(.caption.weight(.black))
                    .foregroundStyle(palePaper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(actionColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .buttonStyle(.plain)
            }
            .frame(width: 84)
            .padding(7)
            .background(actionColor.opacity(0.11))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(actionColor.opacity(0.38), lineWidth: 1)
            }
        }
        .paperCard(borderColor: fadedRed.opacity(0.65))
        .saturation(canSelectAdvertisement ? 1 : 0)
        .opacity(canSelectAdvertisement ? 1 : 0.5)
    }

    private func attemptSelection(
        of advertisement: Advertisement
    ) {
        switch finance.purchaseAvailability(for: advertisement.price) {
        case .available:
            advertisementPendingConfirmation = advertisement
        case .insufficientFunds:
            purchaseWarning = .insufficientFunds
        case .operatingReserveRequired:
            purchaseWarning = .operatingReserveRequired
        }
    }

    private func sectionBanner(
        _ title: String
    ) -> some View {
        Text(title)
            .font(.caption.weight(.black))
            .foregroundStyle(palePaper)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(navy)
            .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    private func nextTierBanner(
        level: Int
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundStyle(fadedRed)

            Text("TIER \(level)")
                .foregroundStyle(fadedRed)

            Text("— CHOOSE YOUR NEXT CAMPAIGN")
                .foregroundStyle(navy)

            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundStyle(fadedRed)
        }
        .font(.system(size: 15, weight: .black, design: .serif))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(palePaper)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(fadedRed.opacity(0.5), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.14), radius: 2, y: 2)
        .rotationEffect(.degrees(-0.5))
    }

    private var maximumTierMessage: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.circle.fill")
                .font(.title)
                .foregroundStyle(fadedRed)

            Text("TOP ADVERTISEMENT TIER")
                .font(.headline.weight(.black))
                .foregroundStyle(navy)

            Text("You have reached the strongest advertising option currently available.")
                .font(.caption)
                .foregroundStyle(ink.opacity(0.72))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(palePaper.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(fadedRed.opacity(0.45), lineWidth: 1.5)
        }
    }

    private func displayedPrice(
        for advertisement: Advertisement
    ) -> String {
        if advertisement.dailyTimeRequired > 0 {
            return "Free"
        }

        return advertisement.price.formatted(
            .currency(code: "USD").precision(.fractionLength(0))
        )
    }

    private func displayedSchedule(
        for advertisement: Advertisement
    ) -> String {
        if advertisement.dailyTimeRequired > 0 {
            return "Time required"
        }

        switch advertisement.paymentSchedule {
        case .oneTime:
            return "One-time"
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        }
    }

    private func actionColor(
        for advertisement: Advertisement
    ) -> Color {
        if advertisement.dailyTimeRequired > 0 {
            return Color(red: 0.22, green: 0.43, blue: 0.18)
        }

        switch advertisement.paymentSchedule {
        case .oneTime:
            return Color(red: 0.08, green: 0.36, blue: 0.55)
        case .daily, .weekly:
            return Color(red: 0.78, green: 0.31, blue: 0.04)
        }
    }

    private func ratingRow(
        title: String,
        level: Int
    ) -> some View {
        HStack(spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 8, weight: .bold))
                .frame(width: 55, alignment: .leading)

            ForEach(1...5, id: \.self) { rating in
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(
                        rating <= level ? fadedRed : ink.opacity(0.16)
                    )
            }
        }
        .foregroundStyle(ink)
    }
}

private extension View {
    func paperCard(
        borderColor: Color
    ) -> some View {
        padding(10)
            .background(Color.white.opacity(0.42))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor.opacity(0.55), lineWidth: 1.5)
            }
            .shadow(color: .black.opacity(0.08), radius: 2, y: 2)
    }
}
