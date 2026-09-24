import Testing
@testable import BusinessSimulator

struct CustomerVisitTests {}

// MARK: - Visit Phases

extension CustomerVisitTests {

    @Test
    func customerWaitsBeforeAppearanceTime() {
        let state = makeVisitPlan().state(at: 0.99)

        #expect(state.phase == .waiting)
        #expect(state.phaseProgress == 0.0)
    }

    @Test
    func arrivalProgressUsesArrivalDuration() {
        let state = makeVisitPlan().state(at: 1.2)

        #expect(state.phase == .arriving)
        #expect(abs(state.phaseProgress - 0.5) < 0.000_001)
    }

    @Test
    func serviceBeginsWhenArrivalEnds() {
        let state = makeVisitPlan().state(at: 1.4)

        #expect(state.phase == .receivingService)
        #expect(state.phaseProgress == 0.0)
    }

    @Test
    func serviceProgressUsesServiceDuration() {
        let state = makeVisitPlan().state(at: 2.15)

        #expect(state.phase == .receivingService)
        #expect(abs(state.phaseProgress - 0.5) < 0.000_001)
    }

    @Test
    func departureBeginsWhenServiceEnds() {
        let state = makeVisitPlan().state(at: 2.9)

        #expect(state.phase == .departing)
        #expect(state.phaseProgress == 0.0)
    }

    @Test
    func departureProgressUsesDepartureDuration() {
        let state = makeVisitPlan().state(at: 3.1)

        #expect(state.phase == .departing)
        #expect(abs(state.phaseProgress - 0.5) < 0.000_001)
    }

    @Test
    func customerCompletesWhenDepartureEnds() {
        let state = makeVisitPlan().state(at: 3.3)

        #expect(state.phase == .completed)
        #expect(state.phaseProgress == 1.0)
    }

    @Test(arguments: [-1.0, 0.0, 1.0, 1.2, 2.15, 3.1, 20.0])
    func phaseProgressAlwaysRemainsWithinValidRange(elapsedTime: Double) {
        let state = makeVisitPlan().state(at: elapsedTime)

        #expect(state.phaseProgress >= 0.0)
        #expect(state.phaseProgress <= 1.0)
    }
}

// MARK: - Prototype Schedule

extension CustomerVisitTests {

    @Test
    func prototypeSchedulesAllFourCustomerAssets() {
        let visits = CustomerVisitSchedule.prototype.visits

        #expect(visits.count == 4)
        #expect(
            visits.map(\.assetName)
                == [
                    "customer_01",
                    "customer_02",
                    "customer_03",
                    "customer_04"
                ]
        )
    }

    @Test
    func prototypeUsesThreeServicePositions() {
        let positions = CustomerVisitSchedule.prototype.visits.map(\.position)

        #expect(positions == [.center, .left, .right, .center])
    }

    @Test
    func scheduleReturnsOnlyCurrentlyActiveCustomer() {
        let schedule = CustomerVisitSchedule.prototype

        #expect(schedule.activeVisit(at: 0.5) == nil)
        #expect(schedule.activeVisit(at: 1.2)?.assetName == "customer_01")
        #expect(schedule.activeVisit(at: 5.2)?.assetName == "customer_02")
        #expect(schedule.activeVisit(at: 9.2)?.assetName == "customer_03")
        #expect(schedule.activeVisit(at: 13.2)?.assetName == "customer_04")
        #expect(schedule.activeVisit(at: 15.5) == nil)
    }
}

private func makeVisitPlan() -> CustomerVisitPlan {
    CustomerVisitPlan(
        appearanceTime: 1.0,
        arrivalDuration: 0.4,
        serviceDuration: 1.5,
        departureDuration: 0.4
    )
}
