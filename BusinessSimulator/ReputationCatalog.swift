//
//  ReputationCatalog.swift
//  BusinessSimulator
//

enum BusinessReputationCatalog {

    static func customerReview(
        for factor: ReputationFactor,
        sentiment: ReputationSentiment,
        product: Product
    ) -> BusinessReputationComment {
        let singularName = product.singularName.lowercased()
        let pluralName = product.pluralName.lowercased()

        switch (factor, sentiment) {
        case (.price, .needsImprovement):
            return BusinessReputationComment(
                title: "Review",
                comments: [
                    "The \(pluralName) are good, but the price is too high.",
                    "I liked the \(singularName), but I cannot justify paying that much.",
                    "I can find similar treats nearby for less money."
                ]
            )
        case (.price, .good):
            return BusinessReputationComment(
                title: "Review",
                comments: [
                    "The \(pluralName) are ok, nothing special.",
                    "The price seems fair for what you get.",
                    "The \(pluralName) are not cheap but not terribly priced."
                ]
            )
        case (.price, .excellent):
            return BusinessReputationComment(
                title: "Review",
                comments: [
                    "These \(pluralName) are absolutely worth the price!",
                    "You get a lot of quality for such a reasonable price.",
                    "It is hard to find \(pluralName) this good at this price."
                ]
            )

        case (.availability, .needsImprovement):
            return BusinessReputationComment(
                title: "Review",
                comments: [
                    "I really want to try a \(singularName), but they are always sold out!",
                    "I made the trip over, but there were no \(pluralName) left.",
                    "They always seem to run out of \(pluralName) before I arrive."
                ]
            )
        case (.availability, .good):
            return BusinessReputationComment(
                title: "Review",
                comments: [
                    "The \(pluralName) are popular, so they do not always last all day.",
                    "The \(pluralName) are great, but make sure to get there early.",
                    "The \(pluralName) are available most days if you do not wait too long."
                ]
            )
        case (.availability, .excellent):
            return BusinessReputationComment(
                title: "Review",
                comments: [
                    "They had plenty of \(pluralName) available when I stopped by.",
                    "I can count on them to have \(pluralName) whenever I visit.",
                    "Even the late customers could still get a \(singularName)."
                ]
            )

        case (.freshness, .needsImprovement):
            return BusinessReputationComment(
                title: "Review",
                comments: [
                    "The \(pluralName) did not taste as fresh as I expected.",
                    "The ingredients in my \(singularName) seemed past their best.",
                    "My \(singularName) did not have the fresh flavor I remembered."
                ]
            )
        case (.freshness, .good):
            return BusinessReputationComment(
                title: "Review",
                comments: [
                    "The \(pluralName) were fine, but they could have been fresher.",
                    "The \(pluralName) were enjoyable, though nothing really stood out.",
                    "The ingredients seemed fine, but you can get better \(pluralName) elsewhere."
                ]
            )
        case (.freshness, .excellent):
            return BusinessReputationComment(
                title: "Review",
                comments: [
                    "You can really taste the fresh ingredients in these \(pluralName)!",
                    "My \(singularName) tasted like it was made with excellent ingredients.",
                    "The bright, fresh flavor makes these \(pluralName) special."
                ]
            )

        case (.overall, let overallSentiment):
            return overallComment(for: overallSentiment)
        }
    }

    static func factorComment(
        for factor: ReputationFactor,
        sentiment: ReputationSentiment
    ) -> BusinessReputationComment {
        switch (factor, sentiment) {
        case (.price, .needsImprovement):
            return BusinessReputationComment(
                title: "Could Improve",
                comments: [
                    "Customers feel your prices are too high for what they receive."
                ]
            )
        case (.price, .good):
            return BusinessReputationComment(
                title: "Good",
                comments: [
                    "Your prices feel reasonable, but customers are not excited by the value."
                ]
            )
        case (.price, .excellent):
            return BusinessReputationComment(
                title: "Excellent",
                comments: [
                    "Customers believe your products provide strong value for the price."
                ]
            )

        case (.availability, .needsImprovement):
            return BusinessReputationComment(
                title: "Could Improve",
                comments: [
                    "Customers are leaving disappointed because you cannot meet demand."
                ]
            )
        case (.availability, .good):
            return BusinessReputationComment(
                title: "Good",
                comments: [
                    "You usually meet demand, but some customers still miss out."
                ]
            )
        case (.availability, .excellent):
            return BusinessReputationComment(
                title: "Excellent",
                comments: [
                    "Customers can count on you to have enough product throughout the day."
                ]
            )

        case (.freshness, .needsImprovement):
            return BusinessReputationComment(
                title: "Could Improve",
                comments: [
                    "Older ingredients are noticeably affecting product quality. Try to hold less inventory so it stays fresh."
                ]
            )
        case (.freshness, .good):
            return BusinessReputationComment(
                title: "Good",
                comments: [
                    "Ingredient freshness is acceptable, with some room to improve."
                ]
            )
        case (.freshness, .excellent):
            return BusinessReputationComment(
                title: "Excellent",
                comments: [
                    "Fresh ingredients are helping your products make a great impression."
                ]
            )

        case (.overall, let overallSentiment):
            return overallComment(for: overallSentiment)
        }
    }

    static func overallComment(
        for sentiment: ReputationSentiment
    ) -> BusinessReputationComment {
        switch sentiment {
        case .needsImprovement:
            return BusinessReputationComment(
                title: "Customers Are Losing Confidence",
                comments: [
                    "Your business has disappointed customers lately, but a few strong days can begin rebuilding their trust.",
                    "Customers have concerns about their recent experiences. Focus on consistency to win them back.",
                    "Your reputation has taken a hit, but thoughtful decisions can turn customer opinion around."
                ]
            )
        case .good:
            return BusinessReputationComment(
                title: "Customers See Potential",
                comments: [
                    "Your business is making a fair impression. Consistent decisions can turn satisfied customers into loyal ones.",
                    "Customers generally like what you offer, but your business has not fully won them over yet.",
                    "Your reputation is holding steady. A few improvements could make your business a local favorite."
                ]
            )
        case .excellent:
            return BusinessReputationComment(
                title: "Customers Are Cheering You On",
                comments: [
                    "Customers are excited about your business. Keep delivering the experience that earned their support!",
                    "Customers trust your business and are eager to tell others about their experience.",
                    "Strong decisions and consistent quality have earned enthusiastic customer support."
                ]
            )
        }
    }
}
