import Testing
@testable import BusinessSimulator

struct CostsTests {}

// MARK: - Advertisements

extension CostsTests {

    @Test
    func dailyAdvertisementCreatesDailyCost() throws {
        let advertisementDimension = makeAdvertisementDimensionForCosts(
            paymentSchedule: .daily,
            price: 40
        )
        let summary = DaySummary(day: 1, startingBalance: 500)

        let cost = advertisementDimension.calculateDailyCosts(
            sales: 100,
            summary: summary
        )

        #expect(cost == 40)
        let cashFlowCost = try #require(summary.cashFlowCosts.first)
        #expect(summary.cashFlowCosts.count == 1)
        #expect(cashFlowCost.name == "Cost Test Advertisement")
        #expect(cashFlowCost.amount == 40)
    }

    @Test
    func weeklyAdvertisementCreatesWeeklyCost() throws {
        let advertisementDimension = makeAdvertisementDimensionForCosts(
            paymentSchedule: .weekly,
            price: 125
        )
        let summary = DaySummary(day: 5, startingBalance: 500)

        let cost = advertisementDimension.calculateWeeklyCosts(
            summary: summary
        )

        #expect(cost == 125)
        let cashFlowCost = try #require(summary.cashFlowCosts.first)
        #expect(summary.cashFlowCosts.count == 1)
        #expect(cashFlowCost.name == "Cost Test Advertisement")
        #expect(cashFlowCost.amount == 125)
    }

    @Test
    func weeklyAdvertisementDoesNotCreateDailyCost() {
        let advertisementDimension = makeAdvertisementDimensionForCosts(
            paymentSchedule: .weekly,
            price: 125
        )
        let summary = DaySummary(day: 1, startingBalance: 500)

        let cost = advertisementDimension.calculateDailyCosts(
            sales: 100,
            summary: summary
        )

        #expect(cost == 0)
        #expect(summary.cashFlowCosts.isEmpty)
    }

    @Test
    func dailyAdvertisementDoesNotCreateWeeklyCost() {
        let advertisementDimension = makeAdvertisementDimensionForCosts(
            paymentSchedule: .daily,
            price: 40
        )
        let summary = DaySummary(day: 5, startingBalance: 500)

        let cost = advertisementDimension.calculateWeeklyCosts(
            summary: summary
        )

        #expect(cost == 0)
        #expect(summary.cashFlowCosts.isEmpty)
    }

    @Test
    func oneTimeAdvertisementIsNotChargedAgain() {
        let advertisementDimension = makeAdvertisementDimensionForCosts(
            paymentSchedule: .oneTime,
            price: 200
        )
        let summary = DaySummary(day: 5, startingBalance: 500)

        let dailyCost = advertisementDimension.calculateDailyCosts(
            sales: 100,
            summary: summary
        )
        let weeklyCost = advertisementDimension.calculateWeeklyCosts(
            summary: summary
        )

        #expect(dailyCost == 0)
        #expect(weeklyCost == 0)
        #expect(summary.cashFlowCosts.isEmpty)
    }

    @Test
    func freeCanvassingDoesNotCreateScheduledCost() {
        let catalog = AdvertisementCatalog()
        let advertisementDimension = makeAdvertisementDimensionForCosts(
            advertisement: catalog.canvassing
        )
        let summary = DaySummary(day: 5, startingBalance: 500)

        let dailyCost = advertisementDimension.calculateDailyCosts(
            sales: 100,
            summary: summary
        )
        let weeklyCost = advertisementDimension.calculateWeeklyCosts(
            summary: summary
        )

        #expect(catalog.canvassing.price == 0)
        #expect(dailyCost == 0)
        #expect(weeklyCost == 0)
        #expect(summary.cashFlowCosts.isEmpty)
    }
}

private func makeAdvertisementDimensionForCosts(
    paymentSchedule: PaymentSchedule,
    price: Double
) -> AdvertisementDimension {
    makeAdvertisementDimensionForCosts(
        advertisement: Advertisement(
            id: AdvertisementID(rawValue: "cost-test-advertisement"),
            name: "Cost Test Advertisement",
            smallIcon: .system("megaphone.fill"),
            description: "Tests advertisement costs.",
            price: price,
            paymentSchedule: paymentSchedule,
            demandLevel: 0,
            marketSizeLevel: 0
        )
    )
}

private func makeAdvertisementDimensionForCosts(
    advertisement: Advertisement
) -> AdvertisementDimension {
    let tier = AdvertisementTier(
        id: AdvertisementTierID(rawValue: "cost-test-tier"),
        level: 0,
        advertisements: [advertisement]
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
