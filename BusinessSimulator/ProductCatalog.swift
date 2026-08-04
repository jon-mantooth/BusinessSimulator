//
//  ProductCatalog.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/17/26.
//

import Foundation

struct ProductCatalog {
    
    let products: [Product]
    let food = FoodProductLine()
    
    init(){
        let lemonadeInstructions = [
            "Combine sugar and water until dissolved.",
            "Add lemon juice and mix thoroughly.",
            "Chill the lemonade with ice.",
            "Divide evenly into 8 cups and serve."
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
            pricePerUnit: 4.50,
            amount: 9,
            unit: "c.",
            lifespan: 730
        )
        
        let lemon = Inventory(
            type: .lemon,
            name: "Lemons",
            pricePerUnit: 75.00,
            amount: 100,
            lifespan: 7
        )
        
        let cup = Inventory(
            type: .cup,
            name: "Cups",
            pricePerUnit: 5.00,
            amount: 50,
            lifespan: 3650
        )
        
        let ice = Inventory(
            type: .ice,
            name: "Ice",
            pricePerUnit: 8.00,
            amount: 40,
            unit: "c",
            lifespan: 1
        )
        
        let hotDog = Inventory(
            type: .hotDog,
            name: "Hot Dog",
            pricePerUnit: 37.50,
            amount: 50,
            lifespan: 10
        )
        
        let bun = Inventory(
            type: .bun,
            name: "Bun",
            pricePerUnit: 17.50,
            amount: 48,
            lifespan: 5
        )
        
        let condiments = Inventory(
            type: .condiments,
            name: "Condiments",
            pricePerUnit: 6.25,
            amount: 48,
            unit: "tbsp",
            lifespan: 180
        )
        
        let onion = Inventory(
            type: .onion,
            name: "Onion",
            pricePerUnit: 8.00,
            amount: 10,
            lifespan: 14
        )
        
        let flour = Inventory(
            type: .flour,
            name: "Flour",
            pricePerUnit: 7.50,
            amount: 25,
            unit: "c",
            lifespan: 180
        )
        
        let butter = Inventory(
            type: .butter,
            name: "Butter",
            pricePerUnit: 8.00,
            amount: 4,
            unit: "lb",
            lifespan: 14
        )
        
        let apple = Inventory(
            type: .apple,
            name: "Apples",
            pricePerUnit: 60.00,
            amount: 100,
            lifespan: 7
        )
        
        let cinnamon = Inventory(
            type: .cinnamon,
            name: "Cinnamon",
            pricePerUnit: 3.00,
            amount: 30,
            unit: "tbsp",
            lifespan: 730
        )
        
        products = [
            Product(
                id: .pies,
                name: "Pies",
                icon: "🥧",
                description: "A comforting dessert enjoyed most during cooler months.",
                productLine: food,
                productInventories: [
                    ProductInventory(inventory: butter, amount: 0.5, unit: "lbs"),
                    ProductInventory(inventory: flour, amount: 2.5, unit: "c"),
                    ProductInventory(inventory: apple, amount: 5),
                    ProductInventory(inventory: cinnamon, amount: 1, unit: "tbsp"),
                    ProductInventory(inventory: sugar, amount: 0.75, unit: "c"),
                ],
                instructions: pieInstructions,
                baseIdealPrice: 16.00,
                idealUnitsSold: 38,
                priceSensitivity: 6.0
            ),
            Product(
                id: .lemonade,
                name: "Lemonade",
                icon: "🍋",
                description: "A refreshing drink that thrives in warm weather.",
                productLine: food,
                productInventories: [
                    ProductInventory(inventory: lemon, amount: 5),
                    ProductInventory(inventory: ice, amount: 8, unit: "c"),
                    ProductInventory(inventory: sugar, amount: 1, unit: "c"),
                    ProductInventory(inventory: cup, amount: 8),
                ],
                instructions: lemonadeInstructions,
                baseIdealPrice: 2.50,
                idealUnitsSold: 240,
                priceSensitivity: 6.0
            ),
            Product(
                id: .hotDogs,
                name: "Hot Dogs",
                icon: "🌭",
                description: "A classic favorite at outdoor gatherings and sporting events.",
                productLine: food,
                productInventories: [
                    ProductInventory(inventory: hotDog, amount: 1),
                    ProductInventory(inventory: bun, amount: 1),
                    ProductInventory(inventory: onion, amount: 0.1),
                    ProductInventory(inventory: condiments, amount: 1, unit: "tbsp"),
                ],
                instructions: hotDogInstructions,
                baseIdealPrice: 4.00,
                idealUnitsSold: 150,
                priceSensitivity: 6.0
            )
        ]
    }
}
