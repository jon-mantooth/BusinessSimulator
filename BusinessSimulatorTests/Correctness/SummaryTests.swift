import Foundation
import Testing
@testable import BusinessSimulator

struct SummaryTests {}

// MARK: - Structured Sales Limits

extension SummaryTests {

    @Test
    func operationalCapacityUsesInfrastructureAndExcludesIngredients() {
        let summary = makeSummary(
            demandedSales: 200,
            sales: 40,
            limits: [
                SalesLimit(
                    type: .ingredient(type: .apple, name: "Apples"),
                    units: 40
                ),
                SalesLimit(type: .equipment, units: 120),
                SalesLimit(type: .labor, units: 140),
                SalesLimit(type: .storage, units: 130)
            ]
        )

        #expect(summary.operationalCapacity == 120)
        #expect(summary.operationalCapacityLimiters.count == 1)
        guard case .equipment =
            summary.operationalCapacityLimiters.first?.type else {
            Issue.record("Expected equipment to limit operational capacity.")
            return
        }
    }

    @Test
    func operationalCapacityRetainsEveryTiedInfrastructureLimiter() {
        let summary = makeSummary(
            demandedSales: 200,
            sales: 100,
            limits: [
                SalesLimit(type: .equipment, units: 100),
                SalesLimit(type: .labor, units: 100),
                SalesLimit(type: .storage, units: 125)
            ]
        )

        #expect(summary.operationalCapacity == 100)
        #expect(summary.operationalCapacityLimiters.count == 2)
        #expect(
            summary.operationalCapacityLimiters.allSatisfy {
                $0.units == 100
            }
        )
    }
}

// MARK: - Sellout Classification

extension SummaryTests {

    @Test
    func selloutRequiresActualSalesBelowDemand() {
        #expect(
            makeSummary(demandedSales: 100, sales: 99).didSellOut
        )
        #expect(
            !makeSummary(demandedSales: 100, sales: 100).didSellOut
        )
        #expect(
            !makeSummary(demandedSales: 0, sales: 0).didSellOut
        )
    }

    @Test
    func nonSelloutHasNoBindingLimitsCauseOrDerivedNotes() {
        let summary = makeSummary(
            demandedSales: 50,
            sales: 50,
            limits: [
                SalesLimit(type: .equipment, units: 50),
                SalesLimit(type: .labor, units: 75)
            ]
        )

        #expect(summary.bindingSalesLimits.isEmpty)
        #expect(summary.selloutCause == nil)
        #expect(summary.presentedSections.isEmpty)
    }

    @Test
    func bindingLimitsIncludeEveryLimitEqualToActualSales() {
        let summary = makeSummary(
            demandedSales: 100,
            sales: 50,
            limits: [
                SalesLimit(type: .equipment, units: 50),
                SalesLimit(type: .labor, units: 50),
                SalesLimit(type: .storage, units: 60)
            ]
        )

        #expect(summary.bindingSalesLimits.count == 2)
        #expect(summary.bindingSalesLimits.allSatisfy { $0.units == 50 })
    }

    @Test
    func selloutCauseUsesDefinedPriority() {
        let allCauses = makeSummary(
            demandedSales: 100,
            sales: 50,
            limits: [
                SalesLimit(type: .storage, units: 50),
                SalesLimit(type: .equipment, units: 50),
                SalesLimit(type: .labor, units: 50),
                SalesLimit(
                    type: .ingredient(type: .apple, name: "Apples"),
                    units: 50
                )
            ]
        )
        let infrastructureCauses = makeSummary(
            demandedSales: 100,
            sales: 50,
            limits: [
                SalesLimit(type: .storage, units: 50),
                SalesLimit(type: .equipment, units: 50),
                SalesLimit(type: .labor, units: 50)
            ]
        )
        let equipmentAndStorage = makeSummary(
            demandedSales: 100,
            sales: 50,
            limits: [
                SalesLimit(type: .storage, units: 50),
                SalesLimit(type: .equipment, units: 50)
            ]
        )

        #expect(allCauses.selloutCause == .ingredients)
        #expect(infrastructureCauses.selloutCause == .labor)
        #expect(equipmentAndStorage.selloutCause == .equipment)
    }
}

// MARK: - Derived Sales Notes

extension SummaryTests {

    @Test
    func ingredientAnalyticsCauseCreatesOneDailyNotePerIngredient() {
        let summary = makeSummary(
            demandedSales: 100,
            sales: 40,
            limits: [
                SalesLimit(
                    type: .ingredient(type: .apple, name: "Apples"),
                    units: 40
                ),
                SalesLimit(
                    type: .ingredient(type: .flour, name: "Flour"),
                    units: 40
                )
            ]
        )
        let salesNotes = notes(in: "Sales", from: summary.presentedSections)

        #expect(summary.selloutCause == .ingredients)
        #expect(salesNotes.count == 2)
        #expect(salesNotes.contains { $0.contains("Apples") })
        #expect(salesNotes.contains { $0.contains("Flour") })
    }

    @Test
    func dailyNotesIncludeEveryTiedCauseButExcludeHigherLimits() {
        let summary = makeSummary(
            demandedSales: 100,
            sales: 50,
            limits: [
                SalesLimit(type: .equipment, units: 50),
                SalesLimit(type: .labor, units: 50),
                SalesLimit(type: .storage, units: 50),
                SalesLimit(
                    type: .ingredient(type: .apple, name: "Apples"),
                    units: 50
                ),
                SalesLimit(
                    type: .ingredient(type: .flour, name: "Flour"),
                    units: 60
                )
            ]
        )
        let salesNotes = notes(in: "Sales", from: summary.presentedSections)

        #expect(salesNotes.contains("Sales were limited by equipment capacity."))
        #expect(salesNotes.contains("Sales were limited by labor capacity."))
        #expect(salesNotes.contains("Sales were limited by storage capacity."))
        #expect(salesNotes.contains { $0.contains("Apples") })
        #expect(!salesNotes.contains { $0.contains("Flour") })
    }

    @Test
    func derivedSalesNotesDoNotMutatePersistedSections() {
        let summary = makeSummary(
            demandedSales: 100,
            sales: 50,
            limits: [SalesLimit(type: .equipment, units: 50)]
        )

        #expect(summary.sections.isEmpty)
        #expect(!summary.presentedSections.isEmpty)
        #expect(summary.sections.isEmpty)
    }

    @Test
    func derivedNotesMergeWithStoredSalesAndUnrelatedNotes() {
        let summary = makeSummary(
            demandedSales: 100,
            sales: 50,
            limits: [SalesLimit(type: .equipment, units: 50)]
        )
        summary.addNote(sectionName: "Sales", note: "Sold out at 1:00 PM.")
        summary.addNote(
            sectionName: "Expired Inventory",
            note: "Apples 2 pounds"
        )

        let presentedSections = summary.presentedSections
        let salesNotes = notes(in: "Sales", from: presentedSections)
        let expirationNotes = notes(
            in: "Expired Inventory",
            from: presentedSections
        )

        #expect(salesNotes.contains("Sold out at 1:00 PM."))
        #expect(salesNotes.contains("Sales were limited by equipment capacity."))
        #expect(expirationNotes == ["Apples 2 pounds"])
    }

    @Test
    func summaryNoticesOrderSelloutThenFactorsThenExpiredIngredients() {
        let summary = makeSummary(
            demandedSales: 100,
            sales: 50,
            limits: [
                SalesLimit(type: .equipment, units: 50),
                SalesLimit(
                    type: .ingredient(type: .apple, name: "Apples"),
                    units: 50
                )
            ]
        )
        summary.addNote(sectionName: "Sales", note: "Sold out at 1:00 PM.")
        summary.addNote(
            sectionName: "Expired Inventory",
            note: "Flour 2 pounds"
        )

        #expect(
            summary.summaryNotices.map(\.message) == [
                "Sold out at 1:00 PM.",
                "Sales were limited by equipment capacity.",
                "Sales were limited by a shortage of Apples.",
                "Flour 2 pounds"
            ]
        )
    }
}

private func makeSummary(
    demandedSales: Int,
    sales: Int,
    limits: [SalesLimit] = []
) -> DaySummary {
    let summary = DaySummary(day: 1, startingBalance: 500)
    summary.demandedSales = demandedSales
    summary.sales = sales
    summary.salesLimits = limits
    return summary
}

private func notes(
    in sectionName: String,
    from sections: [SummarySection]
) -> [String] {
    sections.first { $0.name == sectionName }?.notes ?? []
}
