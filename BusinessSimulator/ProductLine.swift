//
//  ProductLine.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/22/26.
//

import Foundation

protocol ProductLine: Equatable {
    var instructionLabel: String { get }
    var inputLabel: String { get }
}

struct FoodProductLine: ProductLine {
    var instructionLabel: String { "Recipe" }
    var inputLabel: String { "Ingredients" }
}
