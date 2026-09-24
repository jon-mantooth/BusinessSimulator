//
//  CustomerVisitAnimation.swift
//  BusinessSimulator
//

import Foundation

enum CustomerVisitPhase: Equatable {
    case waiting
    case arriving
    case receivingService
    case departing
    case completed
}

struct CustomerVisitState: Equatable {
    let phase: CustomerVisitPhase
    let phaseProgress: Double
}

struct CustomerVisitPlan {
    let appearanceTime: TimeInterval
    let arrivalDuration: TimeInterval
    let serviceDuration: TimeInterval
    let departureDuration: TimeInterval

    func state(at elapsedTime: TimeInterval) -> CustomerVisitState {
        let elapsedTime = max(elapsedTime, 0.0)
        let arrivalEnd = appearanceTime + arrivalDuration
        let serviceEnd = arrivalEnd + serviceDuration
        let departureEnd = serviceEnd + departureDuration

        if elapsedTime < appearanceTime {
            return CustomerVisitState(
                phase: .waiting,
                phaseProgress: 0.0
            )
        }

        if elapsedTime < arrivalEnd {
            return CustomerVisitState(
                phase: .arriving,
                phaseProgress: normalizedProgress(
                    elapsedTime - appearanceTime,
                    duration: arrivalDuration
                )
            )
        }

        if elapsedTime < serviceEnd {
            return CustomerVisitState(
                phase: .receivingService,
                phaseProgress: normalizedProgress(
                    elapsedTime - arrivalEnd,
                    duration: serviceDuration
                )
            )
        }

        if elapsedTime < departureEnd {
            return CustomerVisitState(
                phase: .departing,
                phaseProgress: normalizedProgress(
                    elapsedTime - serviceEnd,
                    duration: departureDuration
                )
            )
        }

        return CustomerVisitState(
            phase: .completed,
            phaseProgress: 1.0
        )
    }

    private func normalizedProgress(
        _ elapsedTime: TimeInterval,
        duration: TimeInterval
    ) -> Double {
        guard duration > 0 else { return 1.0 }
        return min(max(elapsedTime / duration, 0.0), 1.0)
    }
}

enum CustomerVisitPosition: Equatable {
    case left
    case center
    case right
}

struct ScheduledCustomerVisit {
    let assetName: String
    let position: CustomerVisitPosition
    let plan: CustomerVisitPlan
}

struct ActiveCustomerVisit {
    let assetName: String
    let position: CustomerVisitPosition
    let state: CustomerVisitState
}

struct CustomerVisitSchedule {
    let visits: [ScheduledCustomerVisit]

    static let prototype = CustomerVisitSchedule(
        visits: [
            ScheduledCustomerVisit(
                assetName: "customer_01",
                position: .center,
                plan: CustomerVisitPlan(
                    appearanceTime: 1.0,
                    arrivalDuration: 0.4,
                    serviceDuration: 1.5,
                    departureDuration: 0.4
                )
            ),
            ScheduledCustomerVisit(
                assetName: "customer_02",
                position: .left,
                plan: CustomerVisitPlan(
                    appearanceTime: 5.0,
                    arrivalDuration: 0.4,
                    serviceDuration: 1.5,
                    departureDuration: 0.4
                )
            ),
            ScheduledCustomerVisit(
                assetName: "customer_03",
                position: .right,
                plan: CustomerVisitPlan(
                    appearanceTime: 9.0,
                    arrivalDuration: 0.4,
                    serviceDuration: 1.5,
                    departureDuration: 0.4
                )
            ),
            ScheduledCustomerVisit(
                assetName: "customer_04",
                position: .center,
                plan: CustomerVisitPlan(
                    appearanceTime: 13.0,
                    arrivalDuration: 0.4,
                    serviceDuration: 1.5,
                    departureDuration: 0.4
                )
            )
        ]
    )

    func activeVisit(at elapsedTime: TimeInterval) -> ActiveCustomerVisit? {
        for visit in visits {
            let state = visit.plan.state(at: elapsedTime)

            if state.phase != .waiting && state.phase != .completed {
                return ActiveCustomerVisit(
                    assetName: visit.assetName,
                    position: visit.position,
                    state: state
                )
            }
        }

        return nil
    }
}
