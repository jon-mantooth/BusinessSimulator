//
//  Product.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/17/26.
//

import Foundation

struct Product: Identifiable {
    let id: ProductID
    let name: String
    let smallIcon: GameIcon
    let description: String
    let productLine: any ProductLine
    let productInventories: [ProductInventory]
    let instructions: [String]
    let baseIdealPrice: Double
    let idealUnitsSold: Int
    let priceSensitivity: Double
    let unitsPerBatch: Int
}

enum ProductID: String {
    case pies
    case smoothies
    case hotDogs
}


final class ProductState: Identifiable {
    let product: Product

    var price: Double

    init(
        product: Product,
        price: Double = 0
    ) {
        self.product = product
        self.price = price
    }
    
    ///calculates what revenue should be based on the difference between
    ///players price and ideal price given demand using the Gaussian function
    /// R(p)=R_max*e^{-k((p-p_i)/p_i)^2}
    func calculateBaselineRevenue(
        demand: Double
    ) -> Double {
        let idealPrice = product.baseIdealPrice * demand
        let maxRevenue = idealPrice * Double(product.idealUnitsSold)
        let k = -(product.priceSensitivity)
        
        let priceDifferenceRatio =
            (price - idealPrice) / idealPrice

        return maxRevenue * exp(k * pow(priceDifferenceRatio, 2))
    }
    
    func calculatePredictedSales(
        predictedRevenue: Double
    ) -> Int {

        return Int(floor(predictedRevenue / price))
    }
}
