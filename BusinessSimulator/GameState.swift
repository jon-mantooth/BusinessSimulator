//
//  GameState.swift
//  HelloSwift
//
//  Created by jon mantooth on 7/16/26.
//

import Foundation
import Observation


@Observable
final class GameState {
    var finance: Finance
    var calendar: GameCalendar
    var weather: WeatherState

    var productState: ProductState?
    var inventoryStates: [InventoryState]
    var production: Production?
    var environment: EnvironmentDepartment?
    var simulationSummary : SimulationSummary = SimulationSummary()

    init(
        balance: Double = 10_000,
        day: Int = 1
    ) {
        self.finance = Finance(
            actualBalance: balance,
            displayedBalance: balance
        )

        self.calendar = GameCalendar(day: day)
        self.weather = WeatherState()
        self.productState = nil
        self.inventoryStates = []
        self.production = nil
        self.environment = nil
    }
    
    func initializeBusiness(
        product: Product
    ) {

        let productState = ProductState(
            product: product
        )
        
        let inventoryStates = product.productInventories.map {
            InventoryState(
                inventory: $0.inventory,
                currentDay: self.calendar.day
            )
        }

        self.productState = productState
        self.inventoryStates = inventoryStates
        
        let dimensions = BusinessDimensions.create(
            gameState: self
        )

        let production = Production(
            dimensions: dimensions.production
        )

        let environment = EnvironmentDepartment(
            dimensions: dimensions.environment
        )

        self.production = production
        self.environment = environment

        self.weather.generateWeeklyForecast(
            starting: self.calendar.currentWeekStartDate
        )
    }
}
