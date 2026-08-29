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
        self.departments = [
            gameState.production!,
            gameState.marketing!,
            gameState.environment!
        ]
        self.summary = DaySummary(
            day: self.gameState.calendar.simulationDay,
            startingBalance: self.gameState.finance.actualBalance
        )
    }
    
    func simulateDay() -> DaySummary {
        var demand = 1.0
        var marketSize = 1.0

        for department in departments {
            demand *= department.calculateDemand()
            marketSize *= department.calculateMarketSize()
        }

        gameState.productState!.updateCurrentIdealPrice(
            demand: demand
        )

        let baselineRevenue =
            gameState.productState!.calculateBaselineRevenue()

        let marketAdjustedRevenue = baselineRevenue * marketSize
        let predictedRevenue = calculatePredictedRevenue(
            baselineRevenue: marketAdjustedRevenue
        )
        
        let predictedSales = gameState.productState!.calculatePredictedSales(
            predictedRevenue: predictedRevenue)
        summary.demandedSales = predictedSales

        let demandedBatches =
            predictedSales / gameState.productState!.product.unitsPerBatch

        var actualBatches = demandedBatches
        
        for department in departments{
            actualBatches = department.applySalesLimits(
                sales: actualBatches,
                summary: summary
            )
        }

        let demandFulfillmentRate = Self.calculateDemandFulfillmentRate(
            demandedBatches: demandedBatches,
            actualBatches: actualBatches
        )

        if demandFulfillmentRate < 1.0 {
            let selloutTime = gameState.businessHours!
                .calculateSelloutTime(
                    demandFulfillmentRate: demandFulfillmentRate
                )
            summary.addNote(
                sectionName: "Sales",
                note: "Sold out at \(selloutTime.formatted)."
            )
        }

        let dailyReputationResult =
            gameState.reputation!.calculateDailyReputation(
                price: gameState.productState!.price,
                idealPrice: gameState.productState!.currentIdealPrice,
                demandFulfillmentRate: demandFulfillmentRate,
                productInventories:
                    gameState.productState!.product.productInventories,
                inventoryStates: gameState.inventoryStates
            )
        summary.dailyReputationResult = dailyReputationResult
        
        var totalCosts: Double = 0
        for department in departments{
            totalCosts += department.calculateDailyCosts(
                sales: actualBatches,
                summary: summary
            )
        }

        if gameState.calendar.currentWeekday == .friday {
            for department in departments {
                totalCosts += department.calculateWeeklyCosts(
                    summary: summary
                )
            }
        }

        let actualSales = actualBatches * gameState.productState!.product.unitsPerBatch
        let actualRevenue = Double(actualSales) * gameState.productState!.price
        summary.sales = actualSales
        summary.revenue = actualRevenue
        
        return summary
    }

    func prepForNextDay() {
        gameState.movePendingBusinessEvents(to: summary)

        gameState.reputation!.updateOverallReputation(
            dailyReputationResult: summary.dailyReputationResult!
        )

        // Update Balance
        gameState.finance.actualBalance = summary.balance
        gameState.finance.displayedBalance = summary.balance
        
        //add summary for previous day
        gameState.simulationSummary.daySummaries.append(summary)
        
        //increment day
        gameState.calendar.simulationDay += 1

        if gameState.calendar.currentWeekday == .monday {
            prepForNextWeek()
        }
        
        for department in departments {
            department.prepForNextDay(
                currentDay: gameState.calendar.simulationDay,
                summary: summary
            )
        }
        
        
    }

    private func prepForNextWeek() {
        gameState.weather.generateWeeklyForecast(
            starting: gameState.calendar.currentDate
        )
    }

    static func calculateDemandFulfillmentRate(
        demandedBatches: Int,
        actualBatches: Int
    ) -> Double {
        demandedBatches > 0
            ? Double(actualBatches) / Double(demandedBatches)
            : 1.0
    }

    /// Applies natural daily variance to baseline revenue using a normal
    /// (Gaussian) distribution with the baseline as its expected value.
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
