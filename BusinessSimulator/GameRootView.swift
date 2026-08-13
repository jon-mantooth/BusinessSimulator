//
//  GameRootView.swift
//  HelloSwift
//
//  Created by jon mantooth on 7/16/26.
//

import SwiftUI

enum Screen {
    case home
    case productSelection
    case prep
    case summary
}

struct GameRootView: View {
    @State private var currentScreen: Screen = .home
    @State private var gameState = GameState()
    @State private var currentSummary: DaySummary?
    @State private var previewedProduct: Product?

    let productCatalog = ProductCatalog()
    
    private func onBeginJourney(){
        currentScreen = .productSelection
    }
    
    private func onContinue(product: Product){
        gameState.initializeBusiness(product: product)
        previewedProduct = nil
        currentScreen = .prep
    }
    
    private func onNextDay() {
        currentScreen = .prep
    }
    
    private func updateDisplayedBalance(projectedCost: Double) {
        gameState.finance.displayedBalance =
        gameState.finance.actualBalance - projectedCost
    }

    private func canAffordPurchase(projectedCost: Double) -> Bool {
        projectedCost <= gameState.finance.actualBalance
    }

    private func handleStartDay(
        purchaseAmounts: [InventoryType: Int],
        price: String,
        inventoryPurchaseCost: Double
    ) {
        // Adds the current days inventory purchased to our inventoryByPurchaseDay object
        // in inventoryByAge
        for item in gameState.inventoryStates{

            let inventoryType = item.inventory.type

            let purchasedAmount =
                purchaseAmounts[inventoryType, default: 0]

            item.inventoryByAge.inventoryByPurchaseDay[gameState.calendar.day] = Double(purchasedAmount)
        }

        currentScreen = .summary
        
        //updates price to type double bc everything on for is string
        if let product = gameState.productState{
            product.price = Double(price) ?? 0.0
        }

        //simulate the day
        let gameRunner = GameRunner(gameState: gameState)
        let summary = gameRunner.simulateDay()

        if inventoryPurchaseCost > 0 {
            summary.cashFlowCosts.append(
                Cost(
                    name: "Inventory Purchases",
                    amount: inventoryPurchaseCost
                )
            )
        }

        currentSummary = summary
        gameRunner.prepForNextDay()
    }
    
    private func onNavigate(screen: Screen){
        currentScreen = screen
    }
    
    private func resetDisplayedBalance(){
        gameState.finance.displayedBalance = gameState.finance.actualBalance
    }

    private var gameBackground: some View {
        GeometryReader { geometry in
            ZStack {
                Image("neighborhood_background")
                    .resizable()
                    .scaledToFill()

                Image("default_house")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width * 0.92)
                    .position(
                        x: geometry.size.width * 0.71,
                        y: geometry.size.height * 0.535
                    )

                if let standImageName {
                    Image(standImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geometry.size.width * 0.48,
                            height: geometry.size.height * 0.40,
                            alignment: .bottom
                        )
                        .position(
                            x: geometry.size.width * 1.13,
                            y: geometry.size.height * 0.64
                        )
                }

                // Seasonal and holiday layers will be added here as transparent
                // overlays when those parts of game state are introduced.
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
        }
        .ignoresSafeArea()
    }

    private var displayedProduct: Product? {
        if currentScreen == .productSelection {
            return previewedProduct
        }

        return gameState.productState?.product
    }

    private var standImageName: String? {
        switch displayedProduct?.id {
        case .pies:
            return "stand_pies"
        case .smoothies:
            return "stand_smoothies"
        case .hotDogs:
            return "stand_hotdogs"
        case nil:
            return nil
        }
    }

    var body: some View {
        let currentAmounts = Dictionary(
            uniqueKeysWithValues: gameState.inventoryStates.map {
                (
                    $0.inventory.type,
                    $0.inventoryByAge.totalInventory *
                        Double($0.inventory.purchaseAmount)
                )
            }
        )
        ZStack {
            gameBackground

            VStack(spacing: 0) {
                HeaderView(gameState: gameState)

                switch currentScreen {
                case .home:
                    HomeView(
                        onBeginJourney: onBeginJourney
                    )

                case .productSelection:
                    ProductSelectionView(
                        products: productCatalog.products,
                        onSelectionChanged: { product in
                            previewedProduct = product
                        },
                        onContinue: onContinue
                    )

                case .prep:
                    if let productState = gameState.productState {
                        PrepView(product: productState.product,
                                 currentAmounts: currentAmounts,
                                 handleStartDay: handleStartDay,
                                 updateDisplayedBalance: updateDisplayedBalance,
                                 canAffordPurchase: canAffordPurchase
                        )
                    }

                case .summary:
                    SummaryView(
                        summary: currentSummary!,
                        onNextDay: onNextDay
                    )
                }

                FooterView(
                    onNavigate: onNavigate,
                    resetDisplayedBalance: resetDisplayedBalance
                )
            }
        }
    }
    
}
