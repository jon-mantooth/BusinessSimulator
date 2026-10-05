import Foundation
import Testing
@testable import BusinessSimulator

struct MarketSizeTests {}

// MARK: - Market Size Progression

extension MarketSizeTests {

    @Test
    func zeroStarsReturnsStartingMarketSizeMultiplier() {
        let multiplier = MarketSizeProgression.targetMultiplier(
            marketSizeStars: 0,
            allocations: progressionTestAllocations
        )

        #expect(multiplier == 1)
    }

    @Test
    func finalStarReachesFinalLocationTierTarget() throws {
        let finalTier = try #require(
            progressionTestAllocations.map(\.locationTier).max()
        )
        let totalStars = progressionTestAllocations.reduce(0) {
            $0 + $1.totalStars
        }

        let multiplier = MarketSizeProgression.targetMultiplier(
            marketSizeStars: totalStars,
            allocations: progressionTestAllocations
        )

        #expect(multiplier == Double(finalTier.rawValue + 1))
    }

    @Test
    func starsWithinLocationTierAddEqualMarketSizeGrowth() {
        let tierOneStars = progressionTestAllocations[0].totalStars
        let multipliers = (0...tierOneStars).map { stars in
            MarketSizeProgression.targetMultiplier(
                marketSizeStars: stars,
                allocations: progressionTestAllocations
            )
        }
        let increases = zip(
            multipliers.dropFirst(),
            multipliers
        ).map { later, earlier in
            later - earlier
        }
        let firstIncrease = increases[0]

        for increase in increases.dropFirst() {
            #expect(abs(increase - firstIncrease) < 0.000_001)
        }
    }

    @Test
    func laterLocationTierContinuesFromCompletedEarlierTier() {
        let tierOneStars = progressionTestAllocations[0].totalStars
        let completedTierOne = MarketSizeProgression.targetMultiplier(
            marketSizeStars: tierOneStars,
            allocations: progressionTestAllocations
        )
        let firstTierTwoStar = MarketSizeProgression.targetMultiplier(
            marketSizeStars: tierOneStars + 1,
            allocations: progressionTestAllocations
        )

        #expect(firstTierTwoStar > completedTierOne)
    }

    @Test
    func zeroStarTierCarriesGrowthIntoNextTier() {
        let starsInLaterTier = progressionTestAllocations[1].totalStars
        let allocationWithEmptyStartingTier = [
            MarketSizeLevelAllocation(
                locationTier: progressionTestAllocations[0].locationTier,
                totalStars: 0
            ),
            MarketSizeLevelAllocation(
                locationTier: progressionTestAllocations[1].locationTier,
                totalStars: starsInLaterTier
            )
        ]
        let multiplier = MarketSizeProgression.targetMultiplier(
            marketSizeStars: starsInLaterTier,
            allocations: allocationWithEmptyStartingTier
        )
        let finalTier = progressionTestAllocations[1].locationTier

        #expect(multiplier == Double(finalTier.rawValue + 1))
    }

    @Test
    func allocationOrderDoesNotChangeProgression() {
        let totalStars = progressionTestAllocations.reduce(0) {
            $0 + $1.totalStars
        }

        for stars in 0...totalStars {
            let ordered = MarketSizeProgression.targetMultiplier(
                marketSizeStars: stars,
                allocations: progressionTestAllocations
            )
            let reversed = MarketSizeProgression.targetMultiplier(
                marketSizeStars: stars,
                allocations: Array(progressionTestAllocations.reversed())
            )

            #expect(abs(ordered - reversed) < 0.000_001)
        }
    }

    @Test
    func marketSizeProgressionNeverDecreases() {
        let totalStars = progressionTestAllocations.reduce(0) {
            $0 + $1.totalStars
        }
        let multipliers = (0...totalStars).map { stars in
            MarketSizeProgression.targetMultiplier(
                marketSizeStars: stars,
                allocations: progressionTestAllocations
            )
        }

        for (earlier, later) in zip(multipliers, multipliers.dropFirst()) {
            #expect(later >= earlier)
        }
    }
}

private let progressionTestAllocations = [
    MarketSizeLevelAllocation(
        locationTier: .tierOne,
        totalStars: 2
    ),
    MarketSizeLevelAllocation(
        locationTier: .tierTwo,
        totalStars: 3
    )
]

// MARK: - Total Market Size Allocation

// TODO: Enable once every permanent market size dimension has been implemented.
// Weather is excluded because its market size effect is transient.
// @Test
// func marketSizeDimensionWeightsAddUpToOne() {
//     let totalMarketSizeWeight =
//         AdvertisingDimension.marketSizeWeight
//         + DistributionDimension.marketSizeWeight
//         + ReputationDimension.marketSizeWeight
//
//     #expect(abs(totalMarketSizeWeight - 1.0) < 0.000_001)
// }

// MARK: - Advertisements

struct AdvertisementMarketSizeCase: Sendable {
    let name: String
    let marketSizeLevel: Int
}

private let advertisementMarketSizeCases = (0...5).map { marketSizeLevel in
    AdvertisementMarketSizeCase(
        name: "market size level \(marketSizeLevel)",
        marketSizeLevel: marketSizeLevel
    )
}

extension MarketSizeTests {

    @Test(arguments: advertisementMarketSizeCases)
    func advertisementReturnsExpectedMarketSize(
        testCase: AdvertisementMarketSizeCase
    ) {
        let totalLevels = 5
        let advertisementDimension = makeAdvertisementDimension(
            demandLevel: 0,
            marketSizeLevel: testCase.marketSizeLevel,
            totalLevels: totalLevels
        )
        let expectedMarketSize = SimulationBalance.marketSize.multiplier(
            weight: AdvertisementDimension.marketSizeWeight,
            targetMultiplier:
                Advertisement.marketSizeTargetMultiplier(
                    for: testCase.marketSizeLevel
                )
        )

        let marketSize = advertisementDimension.calculateMarketSize()

        #expect(
            abs(marketSize - expectedMarketSize) < 0.000_001,
            Comment(rawValue: testCase.name)
        )
    }

    @Test
    func advertisementDemandLevelDoesNotAffectMarketSize() {
        let lowDemandMarketSize = makeAdvertisementDimension(
            demandLevel: 0,
            marketSizeLevel: 3
        ).calculateMarketSize()
        let highDemandMarketSize = makeAdvertisementDimension(
            demandLevel: 5,
            marketSizeLevel: 3
        ).calculateMarketSize()

        #expect(
            abs(lowDemandMarketSize - highDemandMarketSize) < 0.000_001
        )
    }

    @Test
    func advertisementMarketSizeNeverDecreasesAsLevelsIncrease() {
        let totalLevels = Advertisement.marketSizeLevelAllocations.reduce(0) {
            $0 + $1.totalStars
        }
        let marketSizes = (0...totalLevels).map { level in
            makeAdvertisementDimension(
                demandLevel: 0,
                marketSizeLevel: level,
                totalLevels: totalLevels
            ).calculateMarketSize()
        }

        for (earlier, later) in zip(marketSizes, marketSizes.dropFirst()) {
            #expect(later >= earlier)
        }
    }

    @Test
    func advertisementUsesSharedMarketSizeProgression() {
        let totalLevels = Advertisement.marketSizeLevelAllocations.reduce(0) {
            $0 + $1.totalStars
        }

        for level in 0...totalLevels {
            #expect(
                Advertisement.marketSizeTargetMultiplier(for: level)
                    == MarketSizeProgression.targetMultiplier(
                        marketSizeStars: level,
                        allocations: Advertisement.marketSizeLevelAllocations
                    )
            )
        }
    }

    @Test
    func canvassingTimeReducesEntireReachableMarket() {
        let catalog = AdvertisementCatalog(productID: .pies)
        let canvassing = catalog.canvassing
        let advertisementDimension = makeAdvertisementDimension(
            advertisement: canvassing
        )
        let advertisementMultiplier =
            SimulationBalance.marketSize.multiplier(
                weight: AdvertisementDimension.marketSizeWeight,
                targetMultiplier:
                    canvassing.marketSizeTargetMultiplier
            )
        let expectedSellingTimeMultiplier = 7.5 / 8.0
        let expectedMarketSize =
            advertisementMultiplier * expectedSellingTimeMultiplier

        let marketSize = advertisementDimension.calculateMarketSize()

        #expect(abs(marketSize - expectedMarketSize) < 0.000_001)
    }
}

// MARK: - Business Reputation Market Size

struct ReputationMarketSizeCase: Sendable {
    let name: String
    let overallReputation: Double
    let expectedEffectScore: Double
}

private let reputationMarketSizeCases = [
    ReputationMarketSizeCase(
        name: "minimum reputation has maximum negative effect",
        overallReputation: 0.0,
        expectedEffectScore: -1.0
    ),
    ReputationMarketSizeCase(
        name: "reputation halfway below neutral has half negative effect",
        overallReputation: 37.5,
        expectedEffectScore: -0.5
    ),
    ReputationMarketSizeCase(
        name: "neutral reputation does not affect market size",
        overallReputation: 75.0,
        expectedEffectScore: 0.0
    ),
    ReputationMarketSizeCase(
        name: "reputation halfway above neutral has half positive effect",
        overallReputation: 87.5,
        expectedEffectScore: 0.5
    ),
    ReputationMarketSizeCase(
        name: "maximum reputation has maximum positive effect",
        overallReputation: 100.0,
        expectedEffectScore: 1.0
    )
]

extension MarketSizeTests {

    @Test(arguments: reputationMarketSizeCases)
    func reputationReturnsExpectedMarketSize(
        testCase: ReputationMarketSizeCase
    ) {
        let reputation = BusinessReputationState(
            overallReputation: testCase.overallReputation
        )
        let reputationDimension = BusinessReputationDimension(
            reputation: reputation
        )
        let expectedMarketSize = SimulationBalance.marketSize.multiplier(
            weight: BusinessReputationDimension.marketSizeWeight,
            effectScore: testCase.expectedEffectScore
        )

        let marketSize = reputationDimension.calculateMarketSize()

        #expect(
            abs(marketSize - expectedMarketSize) < 0.000_001,
            Comment(rawValue: testCase.name)
        )
    }
}

private func makeAdvertisementDimension(
    demandLevel: Int,
    marketSizeLevel: Int,
    totalLevels: Int = 5
) -> AdvertisementDimension {
    makeAdvertisementDimension(
        advertisement: Advertisement(
            id: AdvertisementID(rawValue: "market-size-test-advertisement"),
            name: "Market Size Test Advertisement",
            smallIcon: .system("megaphone.fill"),
            description: "Tests advertisement market size.",
            paymentSchedule: .oneTime,
            demandLevel: demandLevel,
            marketSizeLevel: marketSizeLevel,
            totalLevels: totalLevels
        )
    )
}

private func makeAdvertisementDimension(
    advertisement: Advertisement
) -> AdvertisementDimension {
    let tier = AdvertisementTier(
        id: AdvertisementTierID(rawValue: "market-size-test-tier"),
        level: 0,
        advertisements: [advertisement],
        product: ProductCatalog().product(for: .pies),
        requiredLocationTier: .tierOne
    )
    let advertisementState = AdvertisementState(
        tiers: [tier],
        activeAdvertisement: ActiveAdvertisement(
            advertisement: advertisement,
            tierLevel: tier.level
        )
    )

    return AdvertisementDimension(
        advertisementState: advertisementState,
        businessHours: BusinessHours(
            openingTime: BusinessTime(hour: 9, minute: 0),
            closingTime: BusinessTime(hour: 17, minute: 0)
        )
    )
}

// MARK: - Weather Market Size

struct WeatherMarketSizeCase: Sendable {
    let condition: String
    let expectedMarketSize: Double
}

private let weatherMarketSizeCases = [
    WeatherMarketSizeCase(
        condition: "sunny",
        expectedMarketSize: 1.10
    ),
    WeatherMarketSizeCase(
        condition: "cloudy",
        expectedMarketSize: 1.00
    ),
    WeatherMarketSizeCase(
        condition: "rain",
        expectedMarketSize: 0.85
    ),
    WeatherMarketSizeCase(
        condition: "snow",
        expectedMarketSize: 0.85
    )
]

extension MarketSizeTests {

    @Test(arguments: weatherMarketSizeCases)
    func weatherConditionReturnsExpectedMarketSize(
        testCase: WeatherMarketSizeCase
    ) {
        let marketSize = weatherMarketSize(
            condition: weatherCondition(named: testCase.condition)
        )

        #expect(
            abs(marketSize - testCase.expectedMarketSize) < 0.000_001
        )
    }

    @Test
    func temperatureDoesNotAffectWeatherMarketSize() {
        let coldWeatherMarketSize = weatherMarketSize(
            highTemperature: 25,
            lowTemperature: 5,
            condition: .sunny
        )
        let hotWeatherMarketSize = weatherMarketSize(
            highTemperature: 106,
            lowTemperature: 89,
            condition: .sunny
        )

        #expect(
            abs(coldWeatherMarketSize - hotWeatherMarketSize) < 0.000_001
        )
    }

    private func weatherMarketSize(
        highTemperature: Int = 70,
        lowTemperature: Int = 50,
        condition: WeatherCondition
    ) -> Double {
        let calendar = GameCalendar()
        let weatherState = WeatherState(
            weeklyForecast: [
                DailyWeather(
                    date: calendar.currentDate,
                    highTemperature: highTemperature,
                    lowTemperature: lowTemperature,
                    condition: condition
                )
            ]
        )
        let product = ProductCatalog().products.first {
            $0.id == .smoothies
        }!
        let weatherDimension = WeatherDimension(
            weatherState: weatherState,
            product: product,
            calendar: calendar
        )

        return weatherDimension.calculateMarketSize()
    }

    private func weatherCondition(
        named name: String
    ) -> WeatherCondition {
        switch name {
        case "sunny":
            return .sunny
        case "cloudy":
            return .cloudy
        case "rain":
            return .rain
        case "snow":
            return .snow
        default:
            preconditionFailure("Unknown weather condition.")
        }
    }
}
