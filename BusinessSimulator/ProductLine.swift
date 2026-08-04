//
//  ProductLine.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/22/26.
//

import Foundation

//Added file to allow for different product lines to use different terminology
//ie instructions vs recipe, inventory vs ingredients. We may only use a food
//product line for this project and remove this file
protocol ProductLine: Equatable {
    var instructionLabel: String { get }
    var inputLabel: String { get }
}

struct FoodProductLine: ProductLine {
    var instructionLabel: String { "Recipe" }
    var inputLabel: String { "Ingredients" }
}
