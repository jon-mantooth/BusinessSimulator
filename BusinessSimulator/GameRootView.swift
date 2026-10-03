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
    case neighborhood
    case prep
    case playback
    case summary
}

struct GameRootView: View {
    private let saveRepository: any GameSaveRepository

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentScreen: Screen = .home
    @State private var gameState = GameState()
    @State private var dayPlaybackState = DayPlaybackState()
    @State private var dayTransitionState = DayTransitionState()
    @State private var currentSummary: DaySummary?
    @State private var previewedProduct: Product?
    @State private var showingCalendar = false
    @State private var showingWeather = false
    @State private var showingLocationMap = false
    @State private var selectedMapLocation: Location?
    @State private var relocationWarning: GamePopupType?
    @State private var hasSavedGame = false
    @State private var showingNewJourneyConfirmation = false
    @State private var showingLoadError = false
    @State private var showingSaveError = false
    @State private var selectedArea: GameArea = .gameMode
    @State private var isEditingPrice = false

    let productCatalog = ProductCatalog()
    let locationCatalog = LocationCatalog()
    let locationSceneResolver = LocationSceneResolver()

    private var purchaseWorkflow: PurchaseWorkflow {
        PurchaseWorkflow(
            gameState: gameState,
            saveRepository: saveRepository
        )
    }

    private var relocationWorkflow: RelocationWorkflow {
        RelocationWorkflow(
            gameState: gameState,
            saveRepository: saveRepository
        )
    }

    private func relocationRequest(
        for location: Location
    ) -> RelocationRequest {
        RelocationRequest(
            destination: location,
            requirements: RelocationRequirements(
                storageLevel: 0,
                transportationLevel: 0,
                equipmentLevel: 3,
                laborLevel: 1,
                advertisementLevel: 2,
                businessReputation: 3.0
            ),
            relocationPrice: 15_000
        )
    }

    private func attemptRelocation(
        request: RelocationRequest,
        availability: RelocationItemAvailability,
        dimensionAvailability: RelocationDimensionAvailability
    ) {
        switch dimensionAvailability {
        case .upgradeMadeToday:
            relocationWarning = .relocationUnavailable(
                message: "You cannot relocate on the same day as a business upgrade."
            )
            return
        case .pendingBusinessEvents:
            relocationWarning = .relocationUnavailable(
                message: "Finish the current day's purchases before relocating."
            )
            return
        case .available:
            break
        }

        guard availability.unmetRequirements.isEmpty else {
            relocationWarning = .relocationUnavailable(
                message: "Meet the highlighted business requirements before relocating."
            )
            return
        }

        switch availability.financialAvailability {
        case .insufficientFunds:
            relocationWarning = .insufficientFunds
            return
        case .operatingReserveRequired:
            relocationWarning = .operatingReserveRequired
            return
        case .locationLocked:
            relocationWarning = .relocationUnavailable(
                message: "This location is not available yet."
            )
            return
        case .available:
            break
        }

        switch relocationWorkflow.complete(request) {
        case .completed(let summary):
            currentSummary = summary
            selectedMapLocation = nil
            showingLocationMap = false
            selectedArea = .gameMode
            currentScreen = .summary
        case let .unavailable(updatedAvailability):
            if updatedAvailability.unmetRequirements.isEmpty {
                relocationWarning = .insufficientFunds
            } else {
                relocationWarning = .relocationUnavailable(
                    message: "Meet the highlighted business requirements before relocating."
                )
            }
        case .saveFailed:
            showingSaveError = true
        }
    }

    private var calendarSheetHeight: CGFloat {
        UIScreen.main.bounds.width * 1.5
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
            showNewDayBackground()
        } catch {
            showingLoadError = true
        }
    }
    
    private func onContinue(product: Product){
        gameState.initializeBusiness(product: product)
        previewedProduct = nil
        showNewDayBackground()
    }
    
    private func onNextDay() {
        dayPlaybackState.reset()
        showNewDayBackground()
    }

    private func showNewDayBackground() {
        gameState.beginOperatingPeriodIfNeeded()
        selectedArea = .gameMode
        currentScreen = .neighborhood
        dayTransitionState.beginSunrise(
            date: gameState.calendar.currentDate,
            reduceMotion: reduceMotion
        )
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
        case .gameMode:
            selectedArea = area

            if currentScreen == .neighborhood {
                currentScreen = .prep
            }
        case .production, .marketing:
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
        for item in gameState.productState!.productInventoryStates {

            let inventoryType = item.productInventory.inventory.type

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
            currentScreen = .playback
            dayTransitionState.beginOpening(
                reduceMotion: reduceMotion,
                onPlaybackReady: {
                    guard currentScreen == .playback else { return }
                    dayPlaybackState.start()
                }
            )
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
        ZStack {
            LocationSceneView(scene: resolvedNightScene)
                .opacity(dayTransitionState.nightSceneOpacity)

            LocationSceneView(scene: resolvedDayScene)
                .opacity(dayTransitionState.daylightSceneOpacity)
        }
        .ignoresSafeArea()
    }

    private func transitionFromPlaybackToSummary() {
        dayTransitionState.beginClosing(
            reduceMotion: reduceMotion,
            onNightReady: {
                guard currentScreen == .playback else { return }
                currentScreen = .summary
            }
        )
    }

    private var displayedProduct: Product? {
        if currentScreen == .productSelection {
            return previewedProduct
        }

        return gameState.productState?.product
    }

    private var activeLocationPresentation: LocationPresentation {
        gameState.locationState?.activePresentation
            ?? locationCatalog.home.presentation
    }

    private var locationSceneContext: LocationSceneContext {
        LocationSceneContext(
            productID: displayedProduct?.id,
            seasonOfYear: gameState.calendar?.seasonOfYear ?? .fall,
            weatherCondition: currentWeatherCondition
        )
    }

    private var currentWeatherCondition: WeatherCondition {
        guard let calendar = gameState.calendar,
              let weather = gameState.weather else {
            return .sunny
        }

        let foundationCalendar = Foundation.Calendar(
            identifier: .gregorian
        )
        return weather.weeklyForecast.first {
            foundationCalendar.isDate(
                $0.date,
                inSameDayAs: calendar.currentDate
            )
        }?.condition ?? .sunny
    }

    private var resolvedNightScene: ResolvedLocationScene {
        locationSceneResolver.resolve(
            activeLocationPresentation.nightScene,
            context: locationSceneContext
        )
    }

    private var resolvedDayScene: ResolvedLocationScene {
        locationSceneResolver.resolve(
            activeLocationPresentation.dayScene,
            context: locationSceneContext
        )
    }

    private var resolvedSimulationScene: ResolvedLocationScene {
        locationSceneResolver.resolve(
            activeLocationPresentation.simulationScene,
            context: locationSceneContext
        )
    }

    var body: some View {
        let productInventoryStates =
            gameState.productState?.productInventoryStates ?? []
        let currentAmounts = Dictionary(
            uniqueKeysWithValues: productInventoryStates.map {
                (
                    $0.productInventory.inventory.type,
                    $0.inventoryByAge.totalInventory *
                        Double($0.productInventory.inventory.purchaseAmount)
                )
            }
        )
        ZStack {
            gameBackground

            if selectedArea == .production,
                let product = gameState.productState?.product,
                let equipmentState = gameState.equipmentState,
                let laborState = gameState.laborState {
                ProductionView(
                    product: product,
                    equipmentState: equipmentState,
                    laborState: laborState,
                    purchaseWorkflow: purchaseWorkflow
                )
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
                if currentScreen != .home
                    && currentScreen != .productSelection
                    && currentScreen != .playback {
                    HeaderView(
                        gameState: gameState,
                        onCalendarTapped: {
                            showingCalendar = true
                        },
                        onWeatherTapped: {
                            showingWeather = true
                        },
                        onMapTapped: {
                            showingLocationMap = true
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

                        case .neighborhood:
                            EmptyView()

                        case .prep:
                            if let productState = gameState.productState {
                                PrepView(
                                    product: productState.product,
                                    productInventoryStates:
                                        productState.productInventoryStates,
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

                        case .playback:
                            PlaybackView(
                                progress: dayPlaybackState.progress,
                                elapsedTime: dayPlaybackState.elapsedTime,
                                businessHours: gameState.businessHours!,
                                scene: resolvedSimulationScene,
                                onSkip: dayPlaybackState.skip
                            )
                            .opacity(dayTransitionState.playbackSceneOpacity)
                            .allowsHitTesting(
                                dayTransitionState.playbackIsInteractive
                            )

                        case .summary:
                            SummaryView(
                                summary: currentSummary!,
                                onNextDay: onNextDay
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if currentScreen != .home
                    && currentScreen != .productSelection
                    && currentScreen != .playback
                    && !isEditingPrice {
                    FooterView(
                        selectedArea: selectedArea,
                        onAreaTapped: selectGameArea
                    )
                }
            }

            DayTransitionOverlay(message: dayTransitionState.message)

            if showingLocationMap,
               let locationState = gameState.locationState {
                LocationMapView(
                    locations: [
                        locationCatalog.home,
                        locationCatalog.ballpark,
                        locationCatalog.farmersMarket,
                        locationCatalog.beach
                    ],
                    activeLocationID: locationState.activeLocationID,
                    onLocationSelected: { location in
                        selectedMapLocation = location
                    },
                    onClose: {
                        showingLocationMap = false
                        selectedMapLocation = nil
                    }
                )
                .zIndex(10)
            }

            if let selectedMapLocation {
                let request = relocationRequest(for: selectedMapLocation)
                let availability = relocationWorkflow.itemAvailability(
                    for: request
                )
                let dimensionAvailability = relocationWorkflow
                    .dimensionAvailability(
                        for: RelocationDimensionAvailabilityRequest()
                    )

                LocationSelectionView(
                    location: selectedMapLocation,
                    availability: availability,
                    canRelocate: availability.canRelocate
                        && dimensionAvailability == .available,
                    relocationCost: request.relocationPrice,
                    onRelocate: {
                        attemptRelocation(
                            request: request,
                            availability: availability,
                            dimensionAvailability: dimensionAvailability
                        )
                    },
                    onClose: {
                        self.selectedMapLocation = nil
                    }
                )
                .overlay {
                    if let relocationWarning {
                        GamePopupView(
                            type: relocationWarning,
                            onConfirm: {
                                self.relocationWarning = nil
                            },
                            onDismiss: {
                                self.relocationWarning = nil
                            }
                        )
                    }
                }
                .zIndex(11)
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
                .presentationDetents([.height(calendarSheetHeight)])
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
        .onChange(of: dayPlaybackState.phase) { _, newPhase in
            if newPhase == .completed {
                transitionFromPlaybackToSummary()
            }
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
