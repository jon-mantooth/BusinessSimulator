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

    var productState: ProductState?
    var inventoryStates: [InventoryState]
    var production: Production?
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
        self.productState = nil
        self.inventoryStates = []
        self.production = nil
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
        
        let dimensions = BusinessDimensions.create(
            product: product,
            inventoryStates: inventoryStates
        )

        let production = Production(
            dimensions: dimensions.production
        )

        self.productState = productState
        self.production = production
        self.inventoryStates = inventoryStates
    }
}
