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
    let icon: String
    let description: String
    let productLine: any ProductLine
    let productInventories: [ProductInventory]
    let instructions: [String]
    let baseIdealPrice: Double
    let idealUnitsSold: Int
    let priceSensitivity: Double
}

enum ProductID: String {
    case pies
    case lemonade
    case hotDogs
}


final class ProductState: Identifiable {
    let product: Product

    var price: Double
    var productionQuantity: Int
    var unitsSold: Int

    init(
        product: Product,
        price: Double = 0,
        productionQuantity: Int = 0,
        unitsSold: Int = 0,
    ) {
        self.product = product
        self.price = price
        self.productionQuantity = productionQuantity
        self.unitsSold = unitsSold
    }
    
    func calculateBaselineRevenue() -> Double {
        let idealPrice = product.baseIdealPrice
        let maxRevenue = idealPrice * Double(product.idealUnitsSold)
        let k = -(product.priceSensitivity)
        
        let priceDifferenceRatio =
            (price - idealPrice) / idealPrice

        return maxRevenue * exp(-k * pow(priceDifferenceRatio, 2))
    }
    
    func calculatePredictedSales(
        predictedRevenue: Double
    ) -> Int {

        return Int(floor(predictedRevenue / price))
    }
}
