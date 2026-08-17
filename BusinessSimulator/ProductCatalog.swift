//
//  ProductCatalog.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/17/26.
//

import Foundation
import SwiftUI

struct ProductCatalog {
    
    let products: [Product]
    let food = FoodProductLine()
    
    init(){
        let smoothieInstructions = [
            "Combine strawberries, milk, ice, and sugar in a blender.",
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
            smallIcon: .system("cube.fill"),
            pricePerUnit: 4.50,
            amount: 9,
            unit: "c.",
            lifespan: 730
        )
        
        let strawberry = Inventory(
            type: .strawberry,
            name: "Strawberries",
            smallIcon: .emoji("🍓"),
            pricePerUnit: 12.00,
            amount: 64,
            unit: "oz",
            lifespan: 5
        )

        let milk = Inventory(
            type: .milk,
            name: "Milk",
            smallIcon: .emoji("🥛"),
            pricePerUnit: 4.00,
            amount: 128,
            unit: "fl oz",
            lifespan: 7
        )
        
        let cup = Inventory(
            type: .cup,
            name: "Cups",
            smallIcon: .emoji("🥤"),
            pricePerUnit: 5.00,
            amount: 50,
            lifespan: 3650
        )
        
        let ice = Inventory(
            type: .ice,
            name: "Ice",
            smallIcon: .emoji("🧊"),
            pricePerUnit: 8.00,
            amount: 40,
            unit: "c",
            lifespan: 1
        )
        
        let hotDog = Inventory(
            type: .hotDog,
            name: "Hot Dog",
            smallIcon: .emoji("🌭"),
            pricePerUnit: 37.50,
            amount: 50,
            lifespan: 10
        )
        
        let bun = Inventory(
            type: .bun,
            name: "Bun",
            smallIcon: .emoji("🥖"),
            pricePerUnit: 17.50,
            amount: 48,
            lifespan: 5
        )
        
        let condiments = Inventory(
            type: .condiments,
            name: "Condiments",
            smallIcon: .emoji("🧴"),
            pricePerUnit: 6.25,
            amount: 48,
            unit: "tbsp",
            lifespan: 180
        )
        
        let onion = Inventory(
            type: .onion,
            name: "Onion",
            smallIcon: .emoji("🧅"),
            pricePerUnit: 8.00,
            amount: 10,
            lifespan: 14
        )
        
        let flour = Inventory(
            type: .flour,
            name: "Flour",
            smallIcon: .emoji("🌾"),
            pricePerUnit: 7.50,
            amount: 25,
            unit: "c",
            lifespan: 180
        )
        
        let butter = Inventory(
            type: .butter,
            name: "Butter",
            smallIcon: .emoji("🧈"),
            pricePerUnit: 8.00,
            amount: 4,
            unit: "lb",
            lifespan: 14
        )
        
        let apple = Inventory(
            type: .apple,
            name: "Apples",
            smallIcon: .emoji("🍎"),
            pricePerUnit: 60.00,
            amount: 100,
            lifespan: 7
        )
        
        let cinnamon = Inventory(
            type: .cinnamon,
            name: "Cinnamon",
            smallIcon: .emoji("🪵"),
            pricePerUnit: 3.00,
            amount: 30,
            unit: "tbsp",
            lifespan: 730
        )
        
        products = [
            Product(
                id: .pies,
                name: "Pies",
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
                instructions: pieInstructions,
                baseIdealPrice: 16.00,
                idealUnitsSold: 38,
                priceSensitivity: 6.0,
                unitsPerBatch: 1,
                temperatureInterpolationFormula: .coldWeather
            ),
            Product(
                id: .smoothies,
                name: "Smoothies",
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
                        freshnessCoefficient: 0.6
                    ),
                    ProductInventory(
                        inventory: milk,
                        amount: 8,
                        unit: "fl oz",
                        freshnessCoefficient: 0.4
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
                        inventory: cup,
                        amount: 1,
                        freshnessCoefficient: 0
                    ),
                ],
                instructions: smoothieInstructions,
                baseIdealPrice: 4.25,
                idealUnitsSold: 141,
                priceSensitivity: 6.0,
                unitsPerBatch: 1,
                temperatureInterpolationFormula: .warmWeather
            ),
            Product(
                id: .hotDogs,
                name: "Hot Dogs",
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
                instructions: hotDogInstructions,
                baseIdealPrice: 4.00,
                idealUnitsSold: 150,
                priceSensitivity: 6.0,
                unitsPerBatch: 1,
                temperatureInterpolationFormula: .temperateWeather
            )
        ]
    }
}
