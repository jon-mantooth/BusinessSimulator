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
        let home = Location(
            id: LocationID(rawValue: "home"),
            name: "Home",
            description: "Build your business from home and serve customers around the neighborhood."
        )
        self.home = home

        let ballpark = Location(
            id: LocationID(rawValue: "ballpark"),
            name: "Ballpark",
            description: "Serve hot dogs to fans throughout the baseball season."
        )
        self.ballpark = ballpark

        let farmersMarket = Location(
            id: LocationID(rawValue: "farmers-market"),
            name: "Farmers Market",
            description: "Sell fresh pies to shoppers at the local farmers market."
        )
        self.farmersMarket = farmersMarket

        let beach = Location(
            id: LocationID(rawValue: "beach"),
            name: "Beach",
            description: "Sell refreshing smoothies to beachgoers during the summer season."
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
