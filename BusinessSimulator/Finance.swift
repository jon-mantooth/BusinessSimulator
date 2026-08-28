//
//  Finance.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/25/26.
//

import Foundation

enum CashFlowDirection: String, Codable {
    case inflow
    case outflow
}

struct FinancialTransaction: Codable {
    let amount: Double
    let direction: CashFlowDirection
}

struct Finance {
    var actualBalance: Double
    var displayedBalance: Double
}
