import Foundation

struct LocationCatalog {
    let home: Location
    let ballpark: Location
    let farmersMarket: Location
    let beach: Location

    let tierOne: LocationTier
    let hotDogTierTwo: LocationTier
    let pieTierTwo: LocationTier
    let smoothieTierTwo: LocationTier

    var tiersByProduct: [ProductID: [LocationTier]] {
        [
            .hotDogs: [tierOne, hotDogTierTwo],
            .pies: [tierOne, pieTierTwo],
            .smoothies: [tierOne, smoothieTierTwo]
        ]
    }

    init() {
        let neighborhoodPresentation = LocationPresentation(
            nightScene: LocationSceneAssets(
                assets: [
                    LocationSceneAsset(
                        id: "night-background",
                        source: .seasonalNightBackground,
                        aspectRatio: 2.0 / 3.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    )
                ]
            ),
            dayScene: LocationSceneAssets(
                assets: [
                    LocationSceneAsset(
                        id: "day-background",
                        source: .seasonalDayBackground,
                        aspectRatio: 2.0 / 3.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    ),
                    LocationSceneAsset(
                        id: "neighborhood-product-stand",
                        source: .productStand,
                        aspectRatio: nil,
                        widthRatio: 0.37,
                        position: LocationScenePosition(
                            x: 0.84,
                            y: 0.705
                        ),
                        anchor: .center,
                        layerOrder: 200
                    )
                ]
            ),
            simulationScene: LocationSceneAssets(
                assets: [
                    LocationSceneAsset(
                        id: "simulation-background",
                        source: .seasonalSimulationBackground,
                        aspectRatio: 853.0 / 1844.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    ),
                    LocationSceneAsset(
                        id: "customer-animation",
                        source: .customerAnimation,
                        aspectRatio: nil,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 100
                    ),
                    LocationSceneAsset(
                        id: "simulation-product-stand",
                        source: .simulationProductStand,
                        aspectRatio: nil,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 200
                    ),
                    LocationSceneAsset(
                        id: "playback-interface",
                        source: .playbackInterface,
                        aspectRatio: nil,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 300
                    )
                ]
            )
        )

        let ballparkPresentation = LocationPresentation(
            nightScene: LocationSceneAssets(
                assets: [
                    LocationSceneAsset(
                        id: "night-background",
                        source: .image("ballpark_night"),
                        aspectRatio: 852.0 / 1846.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    )
                ]
            ),
            dayScene: LocationSceneAssets(
                assets: [
                    LocationSceneAsset(
                        id: "day-background",
                        source: .image("ballpark_day"),
                        aspectRatio: 852.0 / 1846.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    ),
                    LocationSceneAsset(
                        id: "product-stand",
                        source: .productStand,
                        aspectRatio: nil,
                        widthRatio: 0.62,
                        position: LocationScenePosition(
                            x: 0.68,
                            y: 0.56
                        ),
                        anchor: .center,
                        layerOrder: 200
                    )
                ]
            ),
            simulationScene: LocationSceneAssets(
                assets: [
                    LocationSceneAsset(
                        id: "simulation-background",
                        source: .weatherSimulationBackground(
                            sunnyImageName: "ballpark_sim_sunny",
                            rainImageName: "ballpark_sim_raining",
                            snowImageName: nil
                        ),
                        aspectRatio: 852.0 / 1846.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    ),
                    LocationSceneAsset(
                        id: "customer-animation",
                        source: .customerAnimation,
                        aspectRatio: nil,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 100
                    ),
                    LocationSceneAsset(
                        id: "simulation-product-stand",
                        source: .simulationProductStand,
                        aspectRatio: nil,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 200
                    ),
                    LocationSceneAsset(
                        id: "playback-interface",
                        source: .playbackInterface,
                        aspectRatio: nil,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 300
                    )
                ]
            )
        )

        let beachPresentation = LocationPresentation(
            nightScene: LocationSceneAssets(
                assets: [
                    LocationSceneAsset(
                        id: "night-background",
                        source: .image("beach_night"),
                        aspectRatio: 853.0 / 1844.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    )
                ]
            ),
            dayScene: LocationSceneAssets(
                assets: [
                    LocationSceneAsset(
                        id: "day-background",
                        source: .image("beach_day"),
                        aspectRatio: 853.0 / 1844.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    ),
                    LocationSceneAsset(
                        id: "product-stand",
                        source: .productStand,
                        aspectRatio: nil,
                        widthRatio: 0.55,
                        position: LocationScenePosition(
                            x: 0.55,
                            y: 0.57
                        ),
                        anchor: .center,
                        layerOrder: 200
                    )
                ]
            ),
            simulationScene: LocationSceneAssets(
                assets: [
                    LocationSceneAsset(
                        id: "simulation-background",
                        source: .weatherSimulationBackground(
                            sunnyImageName: "beach_sim_sunny",
                            rainImageName: "beach_sim_raining",
                            snowImageName: nil
                        ),
                        aspectRatio: 853.0 / 1844.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    ),
                    LocationSceneAsset(
                        id: "customer-animation",
                        source: .customerAnimation,
                        aspectRatio: nil,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 100
                    ),
                    LocationSceneAsset(
                        id: "simulation-product-stand",
                        source: .simulationProductStand,
                        aspectRatio: nil,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 200
                    ),
                    LocationSceneAsset(
                        id: "playback-interface",
                        source: .playbackInterface,
                        aspectRatio: nil,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 300
                    )
                ]
            )
        )

        let farmersMarketPresentation = LocationPresentation(
            nightScene: LocationSceneAssets(
                assets: [
                    LocationSceneAsset(
                        id: "night-background",
                        source: .image("market_night"),
                        aspectRatio: 853.0 / 1844.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    )
                ]
            ),
            dayScene: LocationSceneAssets(
                assets: [
                    LocationSceneAsset(
                        id: "day-background",
                        source: .image("market_day"),
                        aspectRatio: 853.0 / 1844.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    ),
                    LocationSceneAsset(
                        id: "product-stand",
                        source: .productStand,
                        aspectRatio: nil,
                        widthRatio: 0.55,
                        position: LocationScenePosition(
                            x: 0.50,
                            y: 0.45
                        ),
                        anchor: .center,
                        layerOrder: 200
                    )
                ]
            ),
            simulationScene: LocationSceneAssets(
                assets: [
                    LocationSceneAsset(
                        id: "simulation-background",
                        source: .weatherSimulationBackground(
                            sunnyImageName: "market_sim_sunny",
                            rainImageName: "market_sim_raining",
                            snowImageName: "market_sim_snowing"
                        ),
                        aspectRatio: 853.0 / 1844.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    ),
                    LocationSceneAsset(
                        id: "customer-animation",
                        source: .customerAnimation,
                        aspectRatio: nil,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 100
                    ),
                    LocationSceneAsset(
                        id: "simulation-product-stand",
                        source: .simulationProductStand,
                        aspectRatio: nil,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 200
                    ),
                    LocationSceneAsset(
                        id: "playback-interface",
                        source: .playbackInterface,
                        aspectRatio: nil,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 300
                    )
                ]
            )
        )

        let home = Location(
            id: LocationID(rawValue: "home"),
            name: "Home",
            description: "Build your business from home and serve customers around the neighborhood.",
            presentation: neighborhoodPresentation
        )
        self.home = home

        let ballpark = Location(
            id: LocationID(rawValue: "ballpark"),
            name: "Ballpark",
            description: "Serve hot dogs to fans throughout the baseball season.",
            presentation: ballparkPresentation
        )
        self.ballpark = ballpark

        let farmersMarket = Location(
            id: LocationID(rawValue: "farmers-market"),
            name: "Farmers Market",
            description: "Sell fresh pies to shoppers at the local farmers market.",
            presentation: farmersMarketPresentation
        )
        self.farmersMarket = farmersMarket

        let beach = Location(
            id: LocationID(rawValue: "beach"),
            name: "Beach",
            description: "Sell refreshing smoothies to beachgoers during the summer season.",
            presentation: beachPresentation
        )
        self.beach = beach

        tierOne = LocationTier(
            id: LocationTierID(rawValue: "tier-one"),
            level: .tierOne,
            locations: [home]
        )

        hotDogTierTwo = LocationTier(
            id: LocationTierID(rawValue: "hot-dog-tier-two"),
            level: .tierTwo,
            locations: [ballpark]
        )

        pieTierTwo = LocationTier(
            id: LocationTierID(rawValue: "pie-tier-two"),
            level: .tierTwo,
            locations: [farmersMarket]
        )

        smoothieTierTwo = LocationTier(
            id: LocationTierID(rawValue: "smoothie-tier-two"),
            level: .tierTwo,
            locations: [beach]
        )
    }
}
