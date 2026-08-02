//
//  Department.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/28/26.
//

protocol Department {

    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int
    
    func calculateCosts(
        sales: Int,
        summary: DaySummary
    ) -> Double
    
    func prepForNextDay(
        currentDay: Int,
        summary: DaySummary
    )
}

extension Department {

    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int {

        return sales
    }
    
    func calculateCosts(
        sales: Int,
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
