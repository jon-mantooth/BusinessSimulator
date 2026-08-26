import Foundation
import Testing
@testable import BusinessSimulator

struct BusinessReputationTests {}

// MARK: - Reputation Factor Allocation

extension BusinessReputationTests {

    @Test
    func reputationFactorWeightsAddUpToOne() {
        let totalWeight =
            BusinessReputationState.priceWeight
            + BusinessReputationState.availabilityWeight
            + BusinessReputationState.freshnessWeight

        #expect(abs(totalWeight - 1.0) < 0.000_001)
    }
}

// MARK: - Reputation Sentiment Classification

private enum ExpectedReputationSentiment: Sendable {
    case needsImprovement
    case good
    case excellent
}

private struct ReputationSentimentCase: Sendable {
    let name: String
    let score: Double
    let expectedSentiment: ExpectedReputationSentiment
}

private let reputationSentimentCases = [
    ReputationSentimentCase(
        name: "minimum score needs improvement",
        score: 0.0,
        expectedSentiment: .needsImprovement
    ),
    ReputationSentimentCase(
        name: "score just below good needs improvement",
        score: 69.999,
        expectedSentiment: .needsImprovement
    ),
    ReputationSentimentCase(
        name: "lower good boundary is good",
        score: 70.0,
        expectedSentiment: .good
    ),
    ReputationSentimentCase(
        name: "score just below excellent is good",
        score: 89.999,
        expectedSentiment: .good
    ),
    ReputationSentimentCase(
        name: "lower excellent boundary is excellent",
        score: 90.0,
        expectedSentiment: .excellent
    ),
    ReputationSentimentCase(
        name: "maximum score is excellent",
        score: 100.0,
        expectedSentiment: .excellent
    )
]

extension BusinessReputationTests {

    @Test(arguments: reputationSentimentCases)
    func factorScoresUseExpectedSentimentBoundaries(
        testCase: ReputationSentimentCase
    ) {
        let factorScores = ReputationFactorScores(
            priceScore: testCase.score,
            availabilityScore: testCase.score,
            freshnessScore: testCase.score
        )
        let reputation = BusinessReputationState(
            overallReputation: testCase.score,
            overallFactorScores: factorScores
        )

        let expectedSentiment: ReputationSentiment = switch testCase.expectedSentiment {
        case .needsImprovement:
            .needsImprovement
        case .good:
            .good
        case .excellent:
            .excellent
        }

        #expect(
            reputation.priceSentiment == expectedSentiment,
            Comment(rawValue: testCase.name + " for price")
        )
        #expect(
            reputation.availabilitySentiment == expectedSentiment,
            Comment(rawValue: testCase.name + " for availability")
        )
        #expect(
            reputation.freshnessSentiment == expectedSentiment,
            Comment(rawValue: testCase.name + " for freshness")
        )
        #expect(
            reputation.overallSentiment == expectedSentiment,
            Comment(rawValue: testCase.name + " overall")
        )
    }
}

// MARK: - Star Rating

struct StarRatingCase: Sendable {
    let name: String
    let overallReputation: Double
    let expectedStarRating: Double
}

private let starRatingCases = [
    StarRatingCase(
        name: "minimum reputation is one star",
        overallReputation: 0.0,
        expectedStarRating: 1.0
    ),
    StarRatingCase(
        name: "midpoint reputation is three stars",
        overallReputation: 50.0,
        expectedStarRating: 3.0
    ),
    StarRatingCase(
        name: "neutral reputation is four stars",
        overallReputation: 75.0,
        expectedStarRating: 4.0
    ),
    StarRatingCase(
        name: "maximum reputation is five stars",
        overallReputation: 100.0,
        expectedStarRating: 5.0
    )
]

extension BusinessReputationTests {

    @Test(arguments: starRatingCases)
    func overallReputationConvertsToStarRating(
        testCase: StarRatingCase
    ) {
        let reputation = BusinessReputationState(
            overallReputation: testCase.overallReputation
        )

        #expect(
            abs(reputation.starRating - testCase.expectedStarRating)
                < 0.000_001,
            Comment(rawValue: testCase.name)
        )
    }
}

// MARK: - Price Effect

struct PriceEffectCase: Sendable {
    let name: String
    let price: Double
    let idealPrice: Double
    let expectedEffectScore: Double
}

private let priceEffectCases = [
    PriceEffectCase(
        name: "price below ideal",
        price: 8.00,
        idealPrice: 10.00,
        expectedEffectScore: 1.00
    ),
    PriceEffectCase(
        name: "price equals ideal",
        price: 10.00,
        idealPrice: 10.00,
        expectedEffectScore: 1.00
    ),
    PriceEffectCase(
        name: "price is slightly above ideal",
        price: 11.00,
        idealPrice: 10.00,
        expectedEffectScore: 0.96
    ),
    PriceEffectCase(
        name: "price is 25 percent above ideal",
        price: 12.50,
        idealPrice: 10.00,
        expectedEffectScore: 0.75
    ),
    PriceEffectCase(
        name: "price is 50 percent above ideal",
        price: 15.00,
        idealPrice: 10.00,
        expectedEffectScore: 0.00
    ),
    PriceEffectCase(
        name: "price is more than 50 percent above ideal",
        price: 20.00,
        idealPrice: 10.00,
        expectedEffectScore: 0.00
    )
]

extension BusinessReputationTests {

    @Test(arguments: priceEffectCases)
    func priceEffectScoreFollowsOverpricingCurve(
        testCase: PriceEffectCase
    ) {
        let reputation = BusinessReputationState()

        let priceEffectScore = reputation.calculatePriceEffectScore(
            price: testCase.price,
            idealPrice: testCase.idealPrice
        )

        #expect(
            abs(priceEffectScore - testCase.expectedEffectScore)
                < 0.000_001
        )
    }
}

// MARK: - Overall Reputation Update

struct OverallReputationUpdateCase: Sendable {
    let name: String
    let startingReputation: Double
    let dailyReputations: [Double]
    let expectedOverallReputation: Double
}

private let overallReputationUpdateCases = [
    OverallReputationUpdateCase(
        name: "positive result uses positive adjustment rate",
        startingReputation: 75.0,
        dailyReputations: [100.0],
        expectedOverallReputation: 80.0
    ),
    OverallReputationUpdateCase(
        name: "negative result uses negative adjustment rate",
        startingReputation: 75.0,
        dailyReputations: [0.0],
        expectedOverallReputation: 67.5
    ),
    OverallReputationUpdateCase(
        name: "equal result does not change reputation",
        startingReputation: 75.0,
        dailyReputations: [75.0],
        expectedOverallReputation: 75.0
    ),
    OverallReputationUpdateCase(
        name: "repeated positive results use updated reputation",
        startingReputation: 75.0,
        dailyReputations: [100.0, 100.0],
        expectedOverallReputation: 84.0
    ),
    OverallReputationUpdateCase(
        name: "repeated negative results use updated reputation",
        startingReputation: 75.0,
        dailyReputations: [0.0, 0.0],
        expectedOverallReputation: 60.75
    )
]

extension BusinessReputationTests {

    @Test(arguments: overallReputationUpdateCases)
    func overallReputationMovesTowardDailyResults(
        testCase: OverallReputationUpdateCase
    ) {
        let reputation = BusinessReputationState(
            overallReputation: testCase.startingReputation
        )

        for dailyReputation in testCase.dailyReputations {
            reputation.updateOverallReputation(
                dailyReputationResult: DailyReputationResult(
                    factorScores: ReputationFactorScores(
                        priceScore: dailyReputation,
                        availabilityScore: dailyReputation,
                        freshnessScore: dailyReputation
                    ),
                    overallScore: dailyReputation
                )
            )
        }

        #expect(
            abs(
                reputation.overallReputation
                - testCase.expectedOverallReputation
            ) < 0.000_001,
            Comment(rawValue: testCase.name)
        )
    }

    @Test
    func firstReputationUpdateMarksBusinessAsRated() {
        let reputation = BusinessReputationState()
        #expect(reputation.hasRatings == false)

        reputation.updateOverallReputation(
            dailyReputationResult: DailyReputationResult(
                factorScores: ReputationFactorScores(
                    priceScore: 75.0,
                    availabilityScore: 75.0,
                    freshnessScore: 75.0
                ),
                overallScore: 75.0
            )
        )

        #expect(reputation.hasRatings == true)
    }

    @Test
    func reputationFactorsMoveTowardTheirOwnDailyScores() {
        let reputation = BusinessReputationState()

        reputation.updateOverallReputation(
            dailyReputationResult: DailyReputationResult(
                factorScores: ReputationFactorScores(
                    priceScore: 100.0,
                    availabilityScore: 0.0,
                    freshnessScore: 50.0
                ),
                overallScore: 52.5
            )
        )

        #expect(
            abs(reputation.overallFactorScores.priceScore - 80.0)
                < 0.000_001
        )
        #expect(
            abs(reputation.overallFactorScores.availabilityScore - 67.5)
                < 0.000_001
        )
        #expect(
            abs(reputation.overallFactorScores.freshnessScore - 72.5)
                < 0.000_001
        )
    }
}

// MARK: - Recent Overall Reputation History

extension BusinessReputationTests {

    @Test
    func reputationHistoryStoresNewestFiveUpdatesInOrder() {
        let reputation = BusinessReputationState(overallReputation: 0.0)
        let perfectResult = DailyReputationResult(
            factorScores: ReputationFactorScores(
                priceScore: 100.0,
                availabilityScore: 100.0,
                freshnessScore: 100.0
            ),
            overallScore: 100.0
        )

        reputation.updateOverallReputation(
            dailyReputationResult: perfectResult
        )
        #expect(reputation.recentOverallReputations == [20.0])

        for _ in 0..<5 {
            reputation.updateOverallReputation(
                dailyReputationResult: perfectResult
            )
        }

        let expectedHistory = [
            36.0,
            48.8,
            59.04,
            67.232,
            73.7856
        ]

        #expect(reputation.recentOverallReputations.count == 5)
        for (actual, expected) in zip(
            reputation.recentOverallReputations,
            expectedHistory
        ) {
            #expect(abs(actual - expected) < 0.000_001)
        }
    }

    @Test
    func restoredReputationHistoryKeepsNewestFiveValues() {
        let reputation = BusinessReputationState(
            recentOverallReputations: [10, 20, 30, 40, 50, 60, 70]
        )

        #expect(
            reputation.recentOverallReputations
                == [30, 40, 50, 60, 70]
        )
    }
}

// MARK: - Reputation Trend

private struct ReputationTrendCase: Sendable {
    let name: String
    let reputationHistory: [Double]
    let expectedTrend: String
}

private let reputationTrendCases = [
    ReputationTrendCase(
        name: "fewer than five ratings has no trend",
        reputationHistory: [80, 81, 82, 83],
        expectedTrend: "unavailable"
    ),
    ReputationTrendCase(
        name: "clearly increasing ratings are improving",
        reputationHistory: [80, 81, 82, 83, 84],
        expectedTrend: "improving"
    ),
    ReputationTrendCase(
        name: "clearly decreasing ratings are declining",
        reputationHistory: [84, 83, 82, 81, 80],
        expectedTrend: "declining"
    ),
    ReputationTrendCase(
        name: "minor movement is stable",
        reputationHistory: [80, 80.1, 79.9, 80.2, 80.1],
        expectedTrend: "stable"
    ),
    ReputationTrendCase(
        name: "mixed ratings with positive momentum are improving",
        reputationHistory: [80, 78, 79, 81, 84],
        expectedTrend: "improving"
    ),
    ReputationTrendCase(
        name: "mixed ratings with negative momentum are declining",
        reputationHistory: [80, 82, 81, 79, 76],
        expectedTrend: "declining"
    ),
    ReputationTrendCase(
        name: "recent recovery interrupts a longer decline",
        reputationHistory: [84, 82, 80, 82.5, 85],
        expectedTrend: "stable"
    ),
    ReputationTrendCase(
        name: "recent decline interrupts longer improvement",
        reputationHistory: [80, 82, 84, 81.5, 79],
        expectedTrend: "stable"
    ),
    ReputationTrendCase(
        name: "positive stability boundary is improving",
        reputationHistory: [80, 80.5, 81, 81.5, 82],
        expectedTrend: "improving"
    ),
    ReputationTrendCase(
        name: "negative stability boundary is declining",
        reputationHistory: [82, 81.5, 81, 80.5, 80],
        expectedTrend: "declining"
    )
]

extension BusinessReputationTests {

    @Test(arguments: reputationTrendCases)
    func reputationTrendUsesRecentOverallReputations(
        testCase: ReputationTrendCase
    ) {
        let reputation = BusinessReputationState(
            recentOverallReputations: testCase.reputationHistory
        )

        let actualTrend = switch reputation.trend {
        case .unavailable:
            "unavailable"
        case .declining:
            "declining"
        case .stable:
            "stable"
        case .improving:
            "improving"
        }

        #expect(
            actualTrend == testCase.expectedTrend,
            Comment(rawValue: testCase.name)
        )
    }
}

// MARK: - Combined Daily Reputation

struct DailyReputationCase: Sendable {
    let name: String
    let price: Double
    let idealPrice: Double
    let demandFulfillmentRate: Double
    let inventoryAge: Int
    let inventoryLifespan: Int
    let freshnessCoefficient: Double
    let expectedDailyReputation: Double
}

private let dailyReputationCases = [
    DailyReputationCase(
        name: "perfect day",
        price: 10.00,
        idealPrice: 10.00,
        demandFulfillmentRate: 1.0,
        inventoryAge: 0,
        inventoryLifespan: 4,
        freshnessCoefficient: 0.40,
        expectedDailyReputation: 100.0
    ),
    DailyReputationCase(
        name: "mixed realistic day",
        price: 11.00,
        idealPrice: 10.00,
        demandFulfillmentRate: 0.80,
        inventoryAge: 2,
        inventoryLifespan: 4,
        freshnessCoefficient: 0.40,
        expectedDailyReputation: 88.9
    ),
    DailyReputationCase(
        name: "poor day",
        price: 15.00,
        idealPrice: 10.00,
        demandFulfillmentRate: 0.0,
        inventoryAge: 3,
        inventoryLifespan: 4,
        freshnessCoefficient: 0.40,
        expectedDailyReputation: 19.375
    )
]

extension BusinessReputationTests {

    @Test(arguments: dailyReputationCases)
    func dailyReputationCombinesAllFactors(
        testCase: DailyReputationCase
    ) {
        let currentDay = 10
        let inventory = Inventory(
            type: .apple,
            name: "Apples",
            smallIcon: .emoji("🍎"),
            pricePerUnit: 10,
            amount: 10,
            lifespan: testCase.inventoryLifespan
        )
        let productInventory = ProductInventory(
            inventory: inventory,
            amount: 1,
            freshnessCoefficient: testCase.freshnessCoefficient
        )
        let inventoryState = InventoryState(
            inventory: inventory,
            currentDay: currentDay
        )
        inventoryState.inventoryByAge.inventoryByPurchaseDay = [
            currentDay - testCase.inventoryAge: 1
        ]

        let reputation = BusinessReputationState()
        let dailyReputationResult = reputation.calculateDailyReputation(
            price: testCase.price,
            idealPrice: testCase.idealPrice,
            demandFulfillmentRate: testCase.demandFulfillmentRate,
            productInventories: [productInventory],
            inventoryStates: [inventoryState]
        )

        #expect(
            abs(
                dailyReputationResult.overallScore
                    - testCase.expectedDailyReputation
            )
                < 0.000_001
        )
    }
}

// MARK: - Freshness Effect

struct ReputationFreshnessIngredient: Sendable {
    let age: Int
    let lifespan: Int
    let freshnessCoefficient: Double
}

struct FreshnessEffectCase: Sendable {
    let name: String
    let ingredients: [ReputationFreshnessIngredient]
    let expectedEffectScore: Double
}

private let freshnessEffectCases = [
    FreshnessEffectCase(
        name: "all ingredients are fully fresh",
        ingredients: [
            ReputationFreshnessIngredient(
                age: 0,
                lifespan: 4,
                freshnessCoefficient: 0.70
            )
        ],
        expectedEffectScore: 1.0
    ),
    FreshnessEffectCase(
        name: "one ingredient is partially fresh",
        ingredients: [
            ReputationFreshnessIngredient(
                age: 2,
                lifespan: 4,
                freshnessCoefficient: 0.40
            )
        ],
        expectedEffectScore: 0.90
    ),
    FreshnessEffectCase(
        name: "one ingredient is on its oldest usable day",
        ingredients: [
            ReputationFreshnessIngredient(
                age: 3,
                lifespan: 4,
                freshnessCoefficient: 0.40
            )
        ],
        expectedEffectScore: 0.775
    ),
    FreshnessEffectCase(
        name: "largest weighted penalty determines freshness effect",
        ingredients: [
            ReputationFreshnessIngredient(
                age: 3,
                lifespan: 4,
                freshnessCoefficient: 0.20
            ),
            ReputationFreshnessIngredient(
                age: 2,
                lifespan: 4,
                freshnessCoefficient: 0.70
            )
        ],
        expectedEffectScore: 0.825
    ),
    FreshnessEffectCase(
        name: "no freshness-sensitive ingredients",
        ingredients: [],
        expectedEffectScore: 1.0
    )
]

extension BusinessReputationTests {

    @Test(arguments: freshnessEffectCases)
    func freshnessEffectScoreUsesLargestWeightedPenalty(
        testCase: FreshnessEffectCase
    ) {
        let currentDay = 10
        var productInventories: [ProductInventory] = []
        var inventoryStates: [InventoryState] = []

        for (index, ingredient) in testCase.ingredients.enumerated() {
            let inventory = Inventory(
                type: index == 0 ? .apple : .butter,
                name: index == 0 ? "Apples" : "Butter",
                smallIcon: .emoji(index == 0 ? "🍎" : "🧈"),
                pricePerUnit: 10,
                amount: 10,
                lifespan: ingredient.lifespan
            )
            let productInventory = ProductInventory(
                inventory: inventory,
                amount: 1,
                freshnessCoefficient: ingredient.freshnessCoefficient
            )
            let inventoryState = InventoryState(
                inventory: inventory,
                currentDay: currentDay
            )
            inventoryState.inventoryByAge.inventoryByPurchaseDay = [
                currentDay - ingredient.age: 1
            ]

            productInventories.append(productInventory)
            inventoryStates.append(inventoryState)
        }

        let freshnessEffectScore =
            BusinessReputationState().calculateFreshnessEffectScore(
            productInventories: productInventories,
            inventoryStates: inventoryStates
        )

        #expect(
            abs(freshnessEffectScore - testCase.expectedEffectScore)
                < 0.000_001
        )
    }
}

// MARK: - Availability Effect

struct AvailabilityEffectCase: Sendable {
    let name: String
    let demandFulfillmentRate: Double
    let expectedEffectScore: Double
}

private let availabilityEffectCases = [
    AvailabilityEffectCase(
        name: "all demand is fulfilled",
        demandFulfillmentRate: 1.0,
        expectedEffectScore: 1.0
    ),
    AvailabilityEffectCase(
        name: "three quarters of demand is fulfilled",
        demandFulfillmentRate: 0.75,
        expectedEffectScore: 0.75
    ),
    AvailabilityEffectCase(
        name: "half of demand is fulfilled",
        demandFulfillmentRate: 0.50,
        expectedEffectScore: 0.50
    ),
    AvailabilityEffectCase(
        name: "fractional fulfillment is preserved",
        demandFulfillmentRate: 0.73,
        expectedEffectScore: 0.73
    ),
    AvailabilityEffectCase(
        name: "very little demand is fulfilled",
        demandFulfillmentRate: 0.10,
        expectedEffectScore: 0.10
    ),
    AvailabilityEffectCase(
        name: "none of the demand is fulfilled",
        demandFulfillmentRate: 0.0,
        expectedEffectScore: 0.0
    )
]

extension BusinessReputationTests {

    @Test(arguments: availabilityEffectCases)
    func availabilityEffectScoreFollowsDemandFulfillment(
        testCase: AvailabilityEffectCase
    ) {
        let availabilityEffectScore =
            BusinessReputationState().calculateAvailabilityEffectScore(
                demandFulfillmentRate: testCase.demandFulfillmentRate
            )

        #expect(
            abs(
                availabilityEffectScore
                - testCase.expectedEffectScore
            ) < 0.000_001
        )
    }
}
