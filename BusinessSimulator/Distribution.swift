//
//  Distribution.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 10/7/26.
//

/// Runs dimensions associated with moving and holding products after
/// production. Transportation can join this department without changing the
/// simulation pipeline when that dimension is implemented.
final class Distribution: Department {
    private let dimensions: [any Dimension]

    init(dimensions: [any Dimension]) {
        self.dimensions = dimensions
    }

    func calculateDemand() -> Double {
        dimensions.reduce(1.0) { $0 * $1.calculateDemand() }
    }

    func calculateMarketSize() -> Double {
        dimensions.reduce(1.0) { $0 * $1.calculateMarketSize() }
    }

    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int {
        dimensions.reduce(sales) { currentSales, dimension in
            dimension.applySalesLimits(
                sales: currentSales,
                summary: summary
            )
        }
    }

    func calculateDailyCosts(
        sales: Int,
        summary: DaySummary
    ) -> Double {
        dimensions.reduce(0) {
            $0 + $1.calculateDailyCosts(sales: sales, summary: summary)
        }
    }

    func calculateWeeklyCosts(
        summary: DaySummary,
        multiplier: Double
    ) -> Double {
        dimensions.reduce(0) {
            $0 + $1.calculateWeeklyCosts(
                summary: summary,
                multiplier: multiplier
            )
        }
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
