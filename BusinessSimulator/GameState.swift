//
//  GameState.swift
//  HelloSwift
//
//  Created by jon mantooth on 7/16/26.
//

import Foundation
import Observation

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
}

@Observable
final class GameState {
    var finance: Finance
    var calendar: GameCalendar
    var weather: WeatherState

    var productState: ProductState?
    var inventoryStates: [InventoryState]
    var reputation: BusinessReputationState?
    var businessHours: BusinessHours?
    var production: Production?
    var marketing: MarketingDepartment?
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
        self.reputation = nil
        self.businessHours = nil
        self.production = nil
        self.marketing = nil
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
        self.reputation = BusinessReputationState()
        self.businessHours = BusinessHours(
            openingTime: BusinessTime(hour: 9, minute: 0),
            closingTime: BusinessTime(hour: 17, minute: 0)
        )
        
        let dimensions = BusinessDimensions.create(
            gameState: self
        )

        let production = Production(
            dimensions: dimensions.production
        )

        let marketing = MarketingDepartment(
            dimensions: dimensions.marketing
        )

        let environment = EnvironmentDepartment(
            dimensions: dimensions.environment
        )

        self.production = production
        self.marketing = marketing
        self.environment = environment

        self.weather.generateWeeklyForecast(
            starting: self.calendar.currentWeekStartDate
        )
    }
}
