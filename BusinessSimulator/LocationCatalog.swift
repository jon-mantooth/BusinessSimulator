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
                        source: .image("neighborhood_night"),
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
                        source: .image("neighborhood_background"),
                        aspectRatio: 2.0 / 3.0,
                        widthRatio: 1.0,
                        position: LocationScenePosition(x: 0.5, y: 0.5),
                        anchor: .center,
                        layerOrder: 0
                    ),
                    LocationSceneAsset(
                        id: "seasonal-house",
                        source: .seasonalHouse,
                        aspectRatio: nil,
                        widthRatio: 0.92,
                        position: LocationScenePosition(
                            x: 0.71,
                            y: 0.535
                        ),
                        anchor: .center,
                        layerOrder: 100
                    ),
                    LocationSceneAsset(
                        id: "product-stand",
                        source: .productStand,
                        aspectRatio: nil,
                        widthRatio: 0.48,
                        position: LocationScenePosition(
                            x: 1.13,
                            y: 0.64
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
                        source: .image("animation_background"),
                        aspectRatio: 2.0 / 3.0,
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
            presentation: neighborhoodPresentation
        )
        self.ballpark = ballpark

        let farmersMarket = Location(
            id: LocationID(rawValue: "farmers-market"),
            name: "Farmers Market",
            description: "Sell fresh pies to shoppers at the local farmers market.",
            presentation: neighborhoodPresentation
        )
        self.farmersMarket = farmersMarket

        let beach = Location(
            id: LocationID(rawValue: "beach"),
            name: "Beach",
            description: "Sell refreshing smoothies to beachgoers during the summer season.",
            presentation: neighborhoodPresentation
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
