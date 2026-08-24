//
//  Environment.swift
//  BusinessSimulator
//

final class EnvironmentDepartment: Department {

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

    func calculateMarketSize() -> Double {
        var marketSize = 1.0

        for dimension in dimensions {
            marketSize *= dimension.calculateMarketSize()
        }

        return marketSize
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

    func prepForNextDay(
        currentDay: Int,
        summary: DaySummary
    ) {
        for dimension in dimensions {
            dimension.prepForNextDay(
                currentDay: currentDay,
                summary: summary
            )
        }
    }
}
