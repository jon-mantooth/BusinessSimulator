//
//  GameRunner.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/27/26.
//

import Foundation

struct GameRunner {

    private let gameState: GameState
    private let revenueStandardDeviationRate = 0.05
    private let departments: [any Department]
    private var summary: DaySummary
    
    init(
        gameState: GameState
    ) {
        self.gameState = gameState
        self.departments = gameState.departments
        self.summary = DaySummary(
            day: self.gameState.calendar.day,
            startingBalance: self.gameState.finance.actualBalance
        )
    }
    
    func simulateDay() -> DaySummary {
        var demand = 1.0

        for department in departments {
            demand *= department.calculateDemand()
        }

        let baselineRevenue =
        gameState.productState!.calculateBaselineRevenue(
            demand: demand
        )
        
        let predictedRevenue = calculatePredictedRevenue(baselineRevenue: baselineRevenue)
        
        let predictedSales = gameState.productState!.calculatePredictedSales(
            predictedRevenue: predictedRevenue)

        var predictedBatches =
            predictedSales / gameState.productState!.product.unitsPerBatch
        
        for department in departments{
            predictedBatches = department.applySalesLimits(
                sales: predictedBatches,
                summary: summary
            )
        }
        
        var totalCosts: Double = 0
        for department in departments{
            totalCosts += department.calculateCosts(
                sales: predictedBatches,
                summary: summary
            )
        }

        let actualSales = predictedBatches * gameState.productState!.product.unitsPerBatch
        let actualRevenue = Double(actualSales) * gameState.productState!.price
        summary.sales = actualSales
        summary.revenue = actualRevenue
        
        return summary
    }

    func prepForNextDay() {
        // Update Balance
        gameState.finance.actualBalance = summary.balance
        gameState.finance.displayedBalance = summary.balance
        
        //add summary for previous day
        gameState.simulationSummary.daySummaries.append(summary)
        
        //increment day
        gameState.calendar.day += 1
        
        for department in departments {
            department.prepForNextDay(
                currentDay: gameState.calendar.day,
                summary: summary
            )
        }
        
        
    }
    
    ///uses a standard distribution to turn a baseline revenue
    ///into an actual predictedRevenue given expected value and std dev
    private func calculatePredictedRevenue(
        baselineRevenue: Double
    ) -> Double {

        let standardDeviation =
            baselineRevenue * revenueStandardDeviationRate

        //find predicted revenue using a standard probability distribution
        let u1 = Double.random(in: 0..<1)
        let u2 = Double.random(in: 0..<1)

        let z =
            sqrt(-2.0 * log(u1)) *
            cos(2.0 * .pi * u2)

        let predictedRevenue =
            baselineRevenue + z * standardDeviation

        let minRevenue =
            baselineRevenue - 3 * standardDeviation

        let maxRevenue =
            baselineRevenue + 3 * standardDeviation

        return min(max(predictedRevenue, minRevenue), maxRevenue)
    }
}
