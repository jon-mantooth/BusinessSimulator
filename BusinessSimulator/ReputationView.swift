import SwiftUI

struct ReputationView: View {
    let product: Product
    let reputation: BusinessReputationState
    let simulationDay: Int
    let onClose: () -> Void

    private let darkBrown = Color(red: 0.23, green: 0.12, blue: 0.06)
    private let gold = Color(red: 0.82, green: 0.54, blue: 0.20)
    private let reviewRed = Color(red: 0.72, green: 0.16, blue: 0.12)
    private let positiveGreen = Color(red: 0.18, green: 0.48, blue: 0.17)
    private let warningOrange = Color(red: 0.88, green: 0.53, blue: 0.05)

    var body: some View {
        VStack(spacing: 10) {
            header
            productHeader

            ScrollView {
                VStack(spacing: 10) {
                    ratingSummary

                    if reputation.hasRatings {
                        customerReviews
                        reputationFactors
                        customerSentiment
                    }
                }
                .padding(.bottom, 1)
            }
            .scrollIndicators(.hidden)
        }
        .padding(14)
        .frame(maxWidth: 440)
        .frame(maxHeight: 650)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.98, blue: 0.92),
                    Color(red: 1.0, green: 0.91, blue: 0.70)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(gold.opacity(0.9), lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.3), radius: 14, y: 7)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.title2)

            Text("Business Reputation")
                .font(.system(.title2, design: .serif))
                .fontWeight(.bold)

            Spacer(minLength: 6)

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(darkBrown.opacity(0.7))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close business reputation")
        }
        .foregroundStyle(darkBrown)
    }

    private var productHeader: some View {
        HStack(spacing: 10) {
            GameIconView(icon: product.smallIcon, size: 46)
                .background(Color.white.opacity(0.55))
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(gold.opacity(0.45), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(product.pluralName)
                    .font(.headline)
                    .foregroundStyle(reviewRed)
            }

            Spacer()
        }
    }

    private var ratingSummary: some View {
        VStack(spacing: 7) {
            if reputation.hasRatings {
                HStack(spacing: 14) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(
                            reputation.starRating,
                            format: .number.precision(.fractionLength(1))
                        )
                        .font(.system(size: 43, weight: .bold, design: .rounded))

                        Text("/ 5")
                            .font(.headline)
                            .foregroundStyle(darkBrown.opacity(0.55))
                    }

                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { index in
                            ratingStar(
                                fill: min(
                                    max(
                                        reputation.starRating - Double(index),
                                        0
                                    ),
                                    1
                                )
                            )
                        }
                    }
                    .frame(height: 26)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        "Rated \(reputation.starRating) out of 5 stars"
                    )
                }

                Label(trendTitle, systemImage: trendSystemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(trendColor)

                Text(trendDescription)
                    .font(.caption2)
                    .foregroundStyle(darkBrown.opacity(0.58))
            } else {
                Text("No Ratings Yet")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)

                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        ratingStar(fill: 0)
                    }
                }
                .frame(height: 26)
                .accessibilityHidden(true)

                Text(
                    "Complete your first business day to receive customer feedback."
                )
                .font(.caption)
                .foregroundStyle(darkBrown.opacity(0.65))
                .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(gold.opacity(0.3), lineWidth: 1)
        }
    }

    private var trendTitle: String {
        switch reputation.trend {
        case .unavailable:
            return "Not Enough Data"
        case .declining:
            return "Declining"
        case .stable:
            return "Stable"
        case .improving:
            return "Improving"
        }
    }

    private var trendSystemImage: String {
        switch reputation.trend {
        case .unavailable:
            return "clock.fill"
        case .declining:
            return "chart.line.downtrend.xyaxis"
        case .stable:
            return "arrow.right"
        case .improving:
            return "chart.line.uptrend.xyaxis"
        }
    }

    private var trendColor: Color {
        switch reputation.trend {
        case .unavailable, .stable:
            return darkBrown.opacity(0.65)
        case .declining:
            return reviewRed
        case .improving:
            return positiveGreen
        }
    }

    private var trendDescription: String {
        switch reputation.trend {
        case .unavailable:
            return "Trend available after five rated days"
        case .declining, .stable, .improving:
            return "Based on your five most recent ratings"
        }
    }

    private var customerReviews: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(
                "What Customers Are Saying",
                systemImage: "quote.bubble.fill",
                color: reviewRed
            )

            HStack(alignment: .top, spacing: 6) {
                reviewCard(
                    starRating: reputation.factorStarRating(
                        for: reputation.overallFactorScores.freshnessScore
                    ),
                    avatar: "🙂",
                    quote: reviewText(
                        for: .freshness,
                        sentiment: reputation.freshnessSentiment,
                        variationOffset: 0
                    )
                )
                reviewCard(
                    starRating: reputation.factorStarRating(
                        for: reputation.overallFactorScores.priceScore
                    ),
                    avatar: "👩🏽",
                    quote: reviewText(
                        for: .price,
                        sentiment: reputation.priceSentiment,
                        variationOffset: 1
                    )
                )
                reviewCard(
                    starRating: reputation.factorStarRating(
                        for: reputation.overallFactorScores.availabilityScore
                    ),
                    avatar: "🧔🏾",
                    quote: reviewText(
                        for: .availability,
                        sentiment: reputation.availabilitySentiment,
                        variationOffset: 2
                    )
                )
            }
        }
        .dashboardSection()
    }

    private var reputationFactors: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionHeader(
                "What's Affecting Your Reputation",
                systemImage: "clipboard.fill",
                color: Color(red: 0.10, green: 0.48, blue: 0.62)
            )

            factorRow(
                icon: "hand.thumbsup.fill",
                title: "Product Quality",
                comment: factorComment(
                    for: .freshness,
                    sentiment: reputation.freshnessSentiment
                ),
                statusColor: sentimentColor(reputation.freshnessSentiment)
            )

            Divider()

            factorRow(
                icon: "shippingbox.fill",
                title: "Availability",
                comment: factorComment(
                    for: .availability,
                    sentiment: reputation.availabilitySentiment
                ),
                statusColor: sentimentColor(reputation.availabilitySentiment)
            )

            Divider()

            factorRow(
                icon: "tag.fill",
                title: "Pricing",
                comment: factorComment(
                    for: .price,
                    sentiment: reputation.priceSentiment
                ),
                statusColor: sentimentColor(reputation.priceSentiment)
            )
        }
        .dashboardSection()
    }

    private var customerSentiment: some View {
        let comment = BusinessReputationCatalog.overallComment(
            for: reputation.overallSentiment
        )
        let commentIndex = simulationDay % comment.comments.count

        return HStack(spacing: 12) {
            Image(systemName: sentimentIcon(reputation.overallSentiment))
                .font(.system(size: 42))
                .foregroundStyle(sentimentColor(reputation.overallSentiment))

            VStack(alignment: .leading, spacing: 3) {
                Text(comment.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(darkBrown)

                Text(comment.comments[commentIndex])
                .font(.caption)
                .foregroundStyle(darkBrown.opacity(0.72))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(gold.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(gold.opacity(0.5), lineWidth: 1)
        }
    }

    private func sectionHeader(
        _ title: String,
        systemImage: String,
        color: Color
    ) -> some View {
        Label(title.uppercased(), systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
    }

    private func reviewCard(
        starRating: Int,
        avatar: String,
        quote: String
    ) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { index in
                    ratingStar(fill: index < starRating ? 1 : 0)
                    .frame(width: 8, height: 8)
                }
            }

            Text(avatar)
                .font(.system(size: 25))

            Text("“" + quote + "”")
                .font(.system(size: 9, design: .rounded))
                .italic()
                .foregroundStyle(darkBrown.opacity(0.82))
                .multilineTextAlignment(.center)
                .lineLimit(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.48))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(gold.opacity(0.22), lineWidth: 1)
        }
    }

    private func reviewText(
        for factor: ReputationFactor,
        sentiment: ReputationSentiment,
        variationOffset: Int
    ) -> String {
        let review = BusinessReputationCatalog.customerReview(
            for: factor,
            sentiment: sentiment,
            product: product
        )
        let index = (simulationDay + variationOffset) % review.comments.count

        return review.comments[index]
    }

    private func factorRow(
        icon: String,
        title: String,
        comment: BusinessReputationComment,
        statusColor: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(statusColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text(title)
                        .font(.caption.weight(.bold))

                    Spacer()

                    Text(comment.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(statusColor)
                }

                Text(comment.comments[0])
                    .font(.system(size: 9.5))
                    .foregroundStyle(darkBrown.opacity(0.68))
                    .lineLimit(2)
            }
        }
        .foregroundStyle(darkBrown)
    }

    private func factorComment(
        for factor: ReputationFactor,
        sentiment: ReputationSentiment
    ) -> BusinessReputationComment {
        BusinessReputationCatalog.factorComment(
            for: factor,
            sentiment: sentiment
        )
    }

    private func sentimentColor(
        _ sentiment: ReputationSentiment
    ) -> Color {
        switch sentiment {
        case .needsImprovement:
            return reviewRed
        case .good:
            return warningOrange
        case .excellent:
            return positiveGreen
        }
    }

    private func sentimentIcon(
        _ sentiment: ReputationSentiment
    ) -> String {
        switch sentiment {
        case .needsImprovement:
            return "exclamationmark.circle.fill"
        case .good:
            return "hand.thumbsup.circle.fill"
        case .excellent:
            return "heart.circle.fill"
        }
    }

    private func ratingStar(
        fill: Double
    ) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(darkBrown.opacity(0.16))

                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(gold)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width * fill)
                    }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private extension View {
    func dashboardSection() -> some View {
        padding(10)
            .background(Color.white.opacity(0.42))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color(red: 0.82, green: 0.54, blue: 0.20)
                            .opacity(0.25),
                        lineWidth: 1
                    )
            }
    }
}
