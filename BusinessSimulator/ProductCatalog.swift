//
//  ProductCatalog.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/17/26.
//

import Foundation
import SwiftUI

// BALANCE-DEPENDENT: Manually maintained fields in this catalog:
// - Inventory.pricePerUnit
// - Inventory.purchaseAmount
// - Inventory.lifespan
// - ProductInventory.recipeAmount
// - ProductInventory.freshnessCoefficient
// - Product.baseIdealPrice
// - Product.idealUnitsSold
// - Product.priceSensitivity
// - Product.temperatureInterpolationFormula

struct ProductCatalog {
    
    let products: [Product]
    let food = FoodProductLine()

    func product(
        for id: ProductID
    ) -> Product {
        guard let product = products.first(where: { $0.id == id }) else {
            preconditionFailure("Product catalog is missing \(id.rawValue).")
        }

        return product
    }
    
    init(){
        let smoothieInstructions = [
            "Combine strawberries, milk, yogurt, ice, and sugar in a blender.",
            "Blend until smooth.",
            "Pour into cup and serve."
        ]

        let hotDogInstructions = [
            "Grill hot dogs.",
            "Toast the buns.",
            "Chop the onions.",
            "Place a hot dog in each bun and add the onions and desired condiments.",
            "Serve."
        ]

        let pieInstructions = [
            "Mix sugar butter and flour to prepare crust.",
            "Peel and slice the apples.",
            "Mix the apples with the sugar and cinnamon.",
            "Fill the pie crust with the apple mixture.",
            "Add the top crust.",
            "Bake until golden brown.",
            "Cool before serving."
        ]
        
        let sugar = Inventory(
            type: .sugar,
            name: "Sugar",
            smallIcon: .asset("sugar_small"),
            largeIcon: .asset("sugar_large"),
            pricePerUnit: 4.50,
            amount: 9,
            unit: "c.",
            lifespan: 730
        )
        
        let strawberry = Inventory(
            type: .strawberry,
            name: "Strawberries",
            smallIcon: .emoji("🍓"),
            largeIcon: .asset("strawberry_large"),
            pricePerUnit: 12.00,
            amount: 64,
            unit: "oz",
            lifespan: 5
        )

        let milk = Inventory(
            type: .milk,
            name: "Milk",
            smallIcon: .emoji("🥛"),
            largeIcon: .asset("milk_large"),
            pricePerUnit: 4.00,
            amount: 128,
            unit: "fl oz",
            lifespan: 7
        )
        
        let yogurt = Inventory(
            type: .yogurt,
            name: "Yogurt",
            smallIcon: .asset("yogurt_small"),
            largeIcon: .asset("yogurt_large"),
            pricePerUnit: 3.20,
            amount: 32,
            unit: "oz",
            lifespan: 14
        )
        
        let ice = Inventory(
            type: .ice,
            name: "Ice",
            smallIcon: .emoji("🧊"),
            largeIcon: .asset("ice_large"),
            pricePerUnit: 8.00,
            amount: 40,
            unit: "c",
            lifespan: 1
        )
        
        let hotDog = Inventory(
            type: .hotDog,
            name: "Hot Dog",
            smallIcon: .asset("hotdog_small"),
            largeIcon: .asset("hotdog_large"),
            pricePerUnit: 37.50,
            amount: 50,
            lifespan: 10
        )

        let beef = Inventory(
            type: .beef,
            name: "Beef",
            smallIcon: .emoji("🥩"),
            largeIcon: .asset("beef_large"),
            pricePerUnit: 30.00,
            amount: 10,
            unit: "lbs",
            lifespan: 30
        )

        let spices = Inventory(
            type: .spices,
            name: "Spices",
            smallIcon: .asset("spices_small"),
            largeIcon: .asset("spices_large"),
            pricePerUnit: 6.00,
            amount: 8,
            unit: "oz",
            lifespan: 365
        )
        
        let bun = Inventory(
            type: .bun,
            name: "Bun",
            smallIcon: .asset("bun_small"),
            largeIcon: .asset("bun_large"),
            pricePerUnit: 17.50,
            amount: 48,
            lifespan: 5
        )

        let yeast = Inventory(
            type: .yeast,
            name: "Yeast",
            smallIcon: .asset("yeast_small"),
            largeIcon: .asset("yeast_large"),
            pricePerUnit: 6.00,
            amount: 4,
            unit: "oz",
            lifespan: 90
        )
        
        let condiments = Inventory(
            type: .condiments,
            name: "Condiments",
            smallIcon: .asset("condiment_small"),
            largeIcon: .asset("condiment_large"),
            pricePerUnit: 6.25,
            amount: 48,
            unit: "tbsp",
            lifespan: 180
        )
        
        let onion = Inventory(
            type: .onion,
            name: "Onion",
            smallIcon: .asset("onion_small"),
            largeIcon: .asset("onion_large"),
            pricePerUnit: 8.00,
            amount: 10,
            lifespan: 14
        )
        
        let flour = Inventory(
            type: .flour,
            name: "Flour",
            smallIcon: .asset("flour_small"),
            largeIcon: .asset("flour_large"),
            pricePerUnit: 7.50,
            amount: 25,
            unit: "c",
            lifespan: 180
        )
        
        let butter = Inventory(
            type: .butter,
            name: "Butter",
            smallIcon: .emoji("🧈"),
            largeIcon: .asset("butter_large"),
            pricePerUnit: 8.00,
            amount: 4,
            unit: "lb",
            lifespan: 14
        )
        
        let apple = Inventory(
            type: .apple,
            name: "Apples",
            smallIcon: .emoji("🍎"),
            largeIcon: .asset("apple_large"),
            pricePerUnit: 60.00,
            amount: 100,
            lifespan: 7
        )
        
        let cinnamon = Inventory(
            type: .cinnamon,
            name: "Cinnamon",
            smallIcon: .asset("cinnamon_small"),
            largeIcon: .asset("cinnamon_large"),
            pricePerUnit: 3.00,
            amount: 30,
            unit: "tbsp",
            lifespan: 730
        )
        
        products = [
            Product(
                id: .pies,
                singularName: "Pie",
                pluralName: "Pies",
                smallIcon: .emoji("🥧"),
                accent: Color(
                    red: 0.72,
                    green: 0.32,
                    blue: 0.12
                ),
                description: "A comforting dessert enjoyed most during cooler months.",
                productLine: food,
                productInventories: [
                    ProductInventory(
                        inventory: butter,
                        amount: 0.5,
                        unit: "lbs",
                        freshnessCoefficient: 0.3
                    ),
                    ProductInventory(
                        inventory: flour,
                        amount: 2.5,
                        unit: "c",
                        freshnessCoefficient: 0
                    ),
                    ProductInventory(
                        inventory: apple,
                        amount: 5,
                        freshnessCoefficient: 0.7
                    ),
                    ProductInventory(
                        inventory: cinnamon,
                        amount: 1,
                        unit: "tbsp",
                        freshnessCoefficient: 0
                    ),
                    ProductInventory(
                        inventory: sugar,
                        amount: 0.75,
                        unit: "c",
                        freshnessCoefficient: 0
                    ),
                ],
                upgradeProductInventories: [],
                instructions: pieInstructions,
                baseIdealPrice: 12.80,
                idealUnitsSold: 38,
                priceSensitivity: 6.0,
                temperatureInterpolationFormula: .coldWeather
            ),
            Product(
                id: .smoothies,
                singularName: "Smoothie",
                pluralName: "Smoothies",
                smallIcon: .emoji("🥤"),
                accent: Color(
                    red: 0.86,
                    green: 0.24,
                    blue: 0.34
                ),
                description: "A refreshing blended fruit drink perfect for a hot summer day.",
                productLine: food,
                productInventories: [
                    ProductInventory(
                        inventory: strawberry,
                        amount: 4,
                        unit: "oz",
                        freshnessCoefficient: 0.5
                    ),
                    ProductInventory(
                        inventory: milk,
                        amount: 8,
                        unit: "fl oz",
                        freshnessCoefficient: 0.3
                    ),
                    ProductInventory(
                        inventory: ice,
                        amount: 1,
                        unit: "c",
                        freshnessCoefficient: 0
                    ),
                    ProductInventory(
                        inventory: sugar,
                        amount: 0.25,
                        unit: "c",
                        freshnessCoefficient: 0
                    ),
                    ProductInventory(
                        inventory: yogurt,
                        amount: 1,
                        unit: "oz",
                        freshnessCoefficient: 0.2
                    ),
                ],
                upgradeProductInventories: [],
                instructions: smoothieInstructions,
                baseIdealPrice: 3.40,
                idealUnitsSold: 141,
                priceSensitivity: 6.0,
                temperatureInterpolationFormula: .warmWeather
            ),
            Product(
                id: .hotDogs,
                singularName: "Hot Dog",
                pluralName: "Hot Dogs",
                smallIcon: .emoji("🌭"),
                accent: Color(
                    red: 0.34,
                    green: 0.62,
                    blue: 0.25
                ),
                description: "A classic favorite at outdoor gatherings and sporting events.",
                productLine: food,
                productInventories: [
                    ProductInventory(
                        inventory: hotDog,
                        amount: 1,
                        freshnessCoefficient: 0.5
                    ),
                    ProductInventory(
                        inventory: bun,
                        amount: 1,
                        freshnessCoefficient: 0.35
                    ),
                    ProductInventory(
                        inventory: onion,
                        amount: 0.1,
                        freshnessCoefficient: 0.15
                    ),
                    ProductInventory(
                        inventory: condiments,
                        amount: 1,
                        unit: "tbsp",
                        freshnessCoefficient: 0
                    ),
                ],
                upgradeProductInventories: [
                    ProductInventory(
                        inventory: beef,
                        amount: 0.2,
                        unit: "lbs",
                        freshnessCoefficient: 0.45
                    ),
                    ProductInventory(
                        inventory: spices,
                        amount: 0.05,
                        unit: "oz",
                        freshnessCoefficient: 0.05
                    ),
                    ProductInventory(
                        inventory: flour,
                        amount: 0.75,
                        unit: "c",
                        freshnessCoefficient: 0
                    ),
                    ProductInventory(
                        inventory: yeast,
                        amount: 1.0 / 30.0,
                        unit: "oz",
                        freshnessCoefficient: 0.35
                    )
                ],
                instructions: hotDogInstructions,
                baseIdealPrice: 3.20,
                idealUnitsSold: 150,
                priceSensitivity: 6.0,
                temperatureInterpolationFormula: .temperateWeather
            )
        ]
    }
}
