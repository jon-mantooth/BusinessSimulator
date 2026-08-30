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
    private let saveRepository: any GameSaveRepository

    @State private var currentScreen: Screen = .home
    @State private var gameState = GameState()
    @State private var currentSummary: DaySummary?
    @State private var previewedProduct: Product?
    @State private var showingCalendar = false
    @State private var showingWeather = false
    @State private var hasSavedGame = false
    @State private var showingNewJourneyConfirmation = false
    @State private var showingLoadError = false
    @State private var showingSaveError = false
    @State private var selectedArea: GameArea = .gameMode
    @State private var isEditingPrice = false

    let productCatalog = ProductCatalog()

    private var purchaseWorkflow: PurchaseWorkflow {
        PurchaseWorkflow(
            gameState: gameState,
            saveRepository: saveRepository
        )
    }

    init(
        saveRepository: any GameSaveRepository
    ) {
        self.saveRepository = saveRepository
    }
    
    private func onBeginJourney(){
        if hasSavedGame {
            showingNewJourneyConfirmation = true
        } else {
            currentScreen = .productSelection
        }
    }

    private func onContinueSavedGame() {
        do {
            guard let gameSave = try saveRepository.load() else {
                hasSavedGame = false
                return
            }

            try gameState.restoreBusiness(from: gameSave)
            previewedProduct = nil
            currentSummary = nil
            currentScreen = .prep
        } catch {
            showingLoadError = true
        }
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
            gameState.finance.actualBalance
            - gameState.pendingOutflowTotal
            - projectedCost
    }

    private func canAffordPurchase(projectedCost: Double) -> Bool {
        projectedCost <= gameState.finance.actualBalance
            - gameState.pendingOutflowTotal
    }

    private func selectGameArea(_ area: GameArea) {
        switch area {
        case .gameMode, .production, .marketing:
            selectedArea = area
        case .distribution, .finance:
            // These areas will be enabled when their views are implemented.
            return
        }
    }

    private func handleStartDay(
        purchaseAmounts: [InventoryType: Int],
        price: String,
        inventoryPurchaseCost: Double
    ) {
        isEditingPrice = false
        let stateBeforeDay = GameSave(gameState: gameState)

        // Adds the current days inventory purchased to our inventoryByPurchaseDay object
        // in inventoryByAge
        for item in gameState.inventoryStates{

            let inventoryType = item.inventory.type

            let purchasedAmount =
                purchaseAmounts[inventoryType, default: 0]

            item.inventoryByAge.inventoryByPurchaseDay[
                gameState.calendar.simulationDay
            ] = Double(purchasedAmount)
        }

        //updates price to type double bc everything on for is string
        if let product = gameState.productState{
            product.price = Double(price) ?? 0.0
        }

        //simulate the day
        let gameRunner = GameRunner(gameState: gameState)
        let summary = gameRunner.simulateDay()

        if inventoryPurchaseCost > 0 {
            gameState.pendingBusinessEvents.append(
                BusinessEvent(
                    simulationDay: gameState.calendar.simulationDay,
                    calendarDate: gameState.calendar.currentDate,
                    type: .purchase(
                        PurchaseEvent(
                            category: .inventory,
                            itemID: "inventory-purchase"
                        )
                    ),
                    title: "Inventory Purchases",
                    financialTransaction: FinancialTransaction(
                        amount: inventoryPurchaseCost,
                        direction: .outflow
                    )
                )
            )
        }

        gameRunner.prepForNextDay()

        // TODO: Persist a game-progress phase before adding a passage-of-time
        // delay. Save this completed day as awaiting summary, then show the
        // summary after the delay. On restore, an awaiting summary should be
        // shown instead of returning directly to PrepView. After the player
        // acknowledges it, persist the phase for preparing the next day.
        do {
            let gameSave = GameSave(gameState: gameState)
            try saveRepository.save(gameSave)

            currentSummary = summary
            hasSavedGame = true
            currentScreen = .summary
        } catch {
            do {
                try gameState.restoreBusiness(from: stateBeforeDay)
            } catch {
                preconditionFailure(
                    "Unable to restore the valid pre-simulation game state."
                )
            }

            currentSummary = nil
            showingSaveError = true
        }
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

            if selectedArea == .production {
                ProductionView()
                    .ignoresSafeArea()
            }

            if selectedArea == .marketing,
                let product = gameState.productState?.product,
                let reputation = gameState.reputation,
                let advertisementState = gameState.advertisementState {
                MarketingView(
                    product: product,
                    reputation: reputation,
                    advertisementState: advertisementState,
                    purchaseWorkflow: purchaseWorkflow,
                    simulationDay: gameState.calendar.simulationDay
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                if currentScreen != .home && currentScreen != .productSelection {
                    HeaderView(
                        gameState: gameState,
                        onCalendarTapped: {
                            showingCalendar = true
                        },
                        onWeatherTapped: {
                            showingWeather = true
                        }
                    )
                }

                if selectedArea != .gameMode {
                    Spacer()
                } else {
                    ZStack {
                        switch currentScreen {
                        case .home:
                            HomeView(
                                hasSavedGame: hasSavedGame,
                                onBeginJourney: onBeginJourney,
                                onContinue: onContinueSavedGame
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
                                PrepView(
                                    product: productState.product,
                                    initialPrice: productState.price,
                                    currentAmounts: currentAmounts,
                                    handleStartDay: handleStartDay,
                                    updateDisplayedBalance: updateDisplayedBalance,
                                    canAffordPurchase: canAffordPurchase,
                                    onPriceEditingChanged: { isEditing in
                                        isEditingPrice = isEditing
                                    }
                                )
                            }

                        case .summary:
                            SummaryView(
                                summary: currentSummary!,
                                onNextDay: onNextDay
                            )
                        }
                    }
                }

                if currentScreen != .home
                    && currentScreen != .productSelection
                    && !isEditingPrice {
                    FooterView(
                        selectedArea: selectedArea,
                        onAreaTapped: selectGameArea
                    )
                }
            }

            if showingNewJourneyConfirmation {
                GamePopupView(
                    type: .newJourneyConfirmation,
                    onConfirm: {
                        showingNewJourneyConfirmation = false
                        currentScreen = .productSelection
                    },
                    onDismiss: {
                        showingNewJourneyConfirmation = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingCalendar) {
            CalendarView(currentDate: gameState.calendar.currentDate)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingWeather) {
            WeatherForecastView(
                forecast: gameState.weather.weeklyForecast
            )
            .presentationDetents([.fraction(0.55)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
        }
        .onAppear {
            hasSavedGame = saveRepository.hasSave()
        }
        .alert(
            "Unable to Continue",
            isPresented: $showingLoadError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "Your saved game could not be loaded. Your save file has not been changed."
            )
        }
        .alert(
            "Unable to Save Day",
            isPresented: $showingSaveError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "The day was not completed because your game could not be saved. Please try again."
            )
        }
    }
    
}
