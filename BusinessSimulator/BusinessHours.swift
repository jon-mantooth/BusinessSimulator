//
//  BusinessHours.swift
//  BusinessSimulator
//

import Foundation

struct BusinessTime {
    let hour: Int
    let minute: Int

    var totalMinutes: Int {
        hour * 60 + minute
    }

    var formatted: String {
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"

        return String(
            format: "%d:%02d %@",
            displayHour,
            minute,
            period
        )
    }
}

struct BusinessHours {
    let openingTime: BusinessTime
    let closingTime: BusinessTime

    func calculateSelloutTime(
        demandFulfillmentRate: Double
    ) -> BusinessTime {
        // Assume demand is distributed evenly throughout the business day.
        let operatingMinutes =
            closingTime.totalMinutes - openingTime.totalMinutes
        let minutesUntilSellout = Int(
            (
                Double(operatingMinutes)
                * demandFulfillmentRate
            ).rounded()
        )
        let selloutMinutes =
            openingTime.totalMinutes + minutesUntilSellout

        return BusinessTime(
            hour: selloutMinutes / 60,
            minute: selloutMinutes % 60
        )
    }
}
