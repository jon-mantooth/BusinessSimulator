//
//  Department.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/28/26.
//

protocol Department {

    func calculateDemand() -> Double

    func calculateMarketSize() -> Double

    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int
    
    func calculateDailyCosts(
        sales: Int,
        summary: DaySummary
    ) -> Double

    func calculateWeeklyCosts(
        summary: DaySummary
    ) -> Double
    
    func prepForNextDay(
        currentDay: Int,
        summary: DaySummary
    )
}

extension Department {

    func calculateDemand() -> Double {
        return 1.0
    }

    func calculateMarketSize() -> Double {
        return 1.0
    }

    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int {

        return sales
    }
    
    func calculateDailyCosts(
        sales: Int,
        summary: DaySummary
    ) -> Double {

        return 0
    }

    
    func calculateWeeklyCosts(
        summary: DaySummary
    ) -> Double {
        return 0
    }
    
    func prepForNextDay(
        currentDay: Int,
        summary: DaySummary
    ) {
        // Default implementation: no end-of-day work required.
    }
}
