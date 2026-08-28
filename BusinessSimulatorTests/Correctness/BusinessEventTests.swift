import Foundation
import Testing
@testable import BusinessSimulator

struct BusinessEventTests {}

// MARK: - Pending Event Transfer

struct BusinessEventTransferCase: Sendable {
    let name: String
    let existingEventCount: Int
    let pendingEventCount: Int
}

private let businessEventTransferCases = [
    BusinessEventTransferCase(
        name: "no pending events",
        existingEventCount: 0,
        pendingEventCount: 0
    ),
    BusinessEventTransferCase(
        name: "one pending event",
        existingEventCount: 0,
        pendingEventCount: 1
    ),
    BusinessEventTransferCase(
        name: "multiple pending events",
        existingEventCount: 0,
        pendingEventCount: 3
    ),
    BusinessEventTransferCase(
        name: "pending events append after existing events",
        existingEventCount: 2,
        pendingEventCount: 3
    )
]

extension BusinessEventTests {

    @Test(arguments: businessEventTransferCases)
    func pendingEventsMoveToSummaryInOrder(
        testCase: BusinessEventTransferCase
    ) {
        let gameState = GameState()
        let summary = DaySummary(day: 1, startingBalance: 150)
        let existingEvents = makeEvents(
            count: testCase.existingEventCount,
            startingAt: 0
        )
        let pendingEvents = makeEvents(
            count: testCase.pendingEventCount,
            startingAt: testCase.existingEventCount
        )

        summary.businessEvents = existingEvents
        gameState.pendingBusinessEvents = pendingEvents

        gameState.movePendingBusinessEvents(to: summary)

        #expect(
            summary.businessEvents.map(\.id)
                == (existingEvents + pendingEvents).map(\.id)
        )
        #expect(gameState.pendingBusinessEvents.isEmpty)
    }

    @Test
    func movingPendingEventsTwiceDoesNotDuplicateEvents() {
        let gameState = GameState()
        let summary = DaySummary(day: 1, startingBalance: 150)
        let pendingEvent = makeEvent(index: 0)
        gameState.pendingBusinessEvents = [pendingEvent]

        gameState.movePendingBusinessEvents(to: summary)
        gameState.movePendingBusinessEvents(to: summary)

        #expect(summary.businessEvents.map(\.id) == [pendingEvent.id])
        #expect(gameState.pendingBusinessEvents.isEmpty)
    }

    @Test
    func movingPendingEventPreservesAllEventData() throws {
        let gameState = GameState()
        let summary = DaySummary(day: 4, startingBalance: 150)
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let event = BusinessEvent(
            id: id,
            simulationDay: 4,
            calendarDate: date,
            type: .purchase(
                PurchaseEvent(
                    category: .advertisement,
                    itemID: "neighborhoodFlyers"
                )
            ),
            title: "Neighborhood Flyers Activated",
            details: "A new advertising campaign was selected.",
            financialTransaction: FinancialTransaction(
                amount: 125,
                direction: .outflow
            )
        )
        gameState.pendingBusinessEvents = [event]

        gameState.movePendingBusinessEvents(to: summary)

        let transferredEvent = try #require(summary.businessEvents.first)
        let transaction = try #require(
            transferredEvent.financialTransaction
        )

        #expect(transferredEvent.id == id)
        #expect(transferredEvent.simulationDay == 4)
        #expect(transferredEvent.calendarDate == date)
        #expect(transferredEvent.title == "Neighborhood Flyers Activated")
        #expect(
            transferredEvent.details
                == "A new advertising campaign was selected."
        )
        #expect(transaction.amount == 125)
        #expect(transaction.direction == .outflow)

        guard case let .purchase(purchaseEvent) = transferredEvent.type else {
            Issue.record("Expected a purchase business event.")
            return
        }

        #expect(purchaseEvent.category == .advertisement)
        #expect(purchaseEvent.itemID == "neighborhoodFlyers")
        #expect(gameState.pendingBusinessEvents.isEmpty)
    }
}

private func makeEvents(
    count: Int,
    startingAt startIndex: Int
) -> [BusinessEvent] {
    (0..<count).map { offset in
        makeEvent(index: startIndex + offset)
    }
}

private func makeEvent(
    index: Int
) -> BusinessEvent {
    BusinessEvent(
        id: UUID(),
        simulationDay: 1,
        calendarDate: Date(timeIntervalSince1970: Double(index)),
        type: .purchase(
            PurchaseEvent(
                category: .advertisement,
                itemID: "advertisement-\(index)"
            )
        ),
        title: "Advertisement \(index)"
    )
}
