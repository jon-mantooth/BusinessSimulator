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
    var calendar: Calendar

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

        self.calendar = Calendar(day: day)
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
        
        //look for a more straight forward way to do this
        let production = Production(
            dimensions: product.createDimensions(product, inventoryStates).production
        )

        self.productState = productState
        self.production = production
        self.inventoryStates = inventoryStates
    }
}
