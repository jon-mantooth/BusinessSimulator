import Foundation

struct TransportCatalog {
    // Primary Transport is mechanically identical for every product. Product-
    // specific decals belong to the department-scene presentation rather than
    // creating separate business upgrades for each product.
    let car: Transport
    let van: Transport
    let pickupTruck: Transport

    let vendorBasket: Transport
    let highCapacityVendorBasket: Transport
    let marinaJetSki: Transport
    let highCapacityMarinaJetSki: Transport
    let farmersMarketCart: Transport
    let highCapacityFarmersMarketCart: Transport

    init() {
        car = Transport(
            id: TransportID(rawValue: "car"),
            name: "Car",
            smallIcon: .asset("car"),
            description: "Lease a car to carry products to the new location."
        )

        van = Transport(
            id: TransportID(rawValue: "van"),
            name: "Van",
            smallIcon: .asset("van"),
            description: "Lease a van with more room for daily deliveries."
        )

        pickupTruck = Transport(
            id: TransportID(rawValue: "pickup-truck"),
            name: "Pickup Truck",
            smallIcon: .asset("truck"),
            description: "Lease a pickup truck for the largest deliveries."
        )

        vendorBasket = Transport(
            id: TransportID(rawValue: "vendor-basket"),
            name: "Vendor Basket and License",
            smallIcon: .asset("vendor_tray_1"),
            description: "Sell hot dogs throughout the ballpark stands."
        )

        highCapacityVendorBasket = Transport(
            id: TransportID(rawValue: "high-capacity-vendor-basket"),
            name: "High-Capacity Vendor Basket",
            smallIcon: .asset("vendor_tray_2"),
            description: "Carry more hot dogs while selling in the stands."
        )

        marinaJetSki = Transport(
            id: TransportID(rawValue: "marina-jet-ski"),
            name: "Marina Jet Ski",
            smallIcon: .asset("jetski_1"),
            description: "Take smoothies to customers around the marina."
        )

        highCapacityMarinaJetSki = Transport(
            id: TransportID(rawValue: "high-capacity-marina-jet-ski"),
            name: "High-Capacity Marina Jet Ski",
            smallIcon: .asset("jetski_2"),
            description: "Carry more smoothies in an expanded compartment."
        )

        farmersMarketCart = Transport(
            id: TransportID(rawValue: "farmers-market-cart"),
            name: "Farmers Market Cart",
            smallIcon: .asset("cart_1"),
            description: "Sell pies throughout the farmers market."
        )

        highCapacityFarmersMarketCart = Transport(
            id: TransportID(rawValue: "high-capacity-farmers-market-cart"),
            name: "High-Capacity Farmers Market Cart",
            smallIcon: .asset("cart_2"),
            description: "Carry more pies while moving through the market."
        )
    }

    func tiers(for product: Product) -> [TransportTier] {
        let secondaryTransport: [Transport]

        switch product.id {
        case .hotDogs:
            secondaryTransport = [
                vendorBasket,
                highCapacityVendorBasket
            ]
        case .smoothies:
            secondaryTransport = [
                marinaJetSki,
                highCapacityMarinaJetSki
            ]
        case .pies:
            secondaryTransport = [
                farmersMarketCart,
                highCapacityFarmersMarketCart
            ]
        }

        let primaryTransport = [car, van, pickupTruck]
        let primaryTiers = primaryTransport.enumerated().map {
            index, transport in
            TransportTier(
                id: TransportTierID(
                    rawValue:
                        "\(product.id.rawValue)-primary-\(index + 1)"
                ),
                track: .primary,
                level: index + 1,
                requiredLocationTier:
                    index == 0 ? .tierOne : .tierTwo,
                transport: transport,
                product: product
            )
        }
        let secondaryTiers = secondaryTransport.enumerated().map {
            index, transport in
            TransportTier(
                id: TransportTierID(
                    rawValue:
                        "\(product.id.rawValue)-secondary-\(index + 1)"
                ),
                track: .secondary,
                level: index + 1,
                requiredLocationTier: .tierTwo,
                transport: transport,
                product: product
            )
        }

        return primaryTiers + secondaryTiers
    }
}
