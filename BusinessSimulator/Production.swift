//
//  Production.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/28/26.
//

final class Production: Department {

    private let dimensions: [any Dimension]

    init(
        dimensions: [any Dimension]
    ) {
        self.dimensions = dimensions
    }

    func calculateDemand() -> Double {
        var demand = 1.0

        for dimension in dimensions {
            demand *= dimension.calculateDemand()
        }

        return demand
    }

    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int {

        var sales = sales

        for dimension in dimensions {
            sales = dimension.applySalesLimits(
                sales: sales,
                summary: summary
            )
        }

        return sales
    }
    
    func calculateDailyCosts(sales: Int, summary: DaySummary) -> Double {
        var totalCosts: Double = 0
        for dimension in dimensions {
            totalCosts += dimension.calculateDailyCosts(sales: sales, summary: summary)
        }
        
        return totalCosts
    }
    
    func prepForNextDay(
        currentDay: Int,
        summary: DaySummary
    ) {
        for dimension in dimensions {
            dimension.prepForNextDay(currentDay: currentDay, summary: summary)
        }
    }
}
