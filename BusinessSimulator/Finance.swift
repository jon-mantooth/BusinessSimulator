//
//  Finance.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/25/26.
//

import Foundation

struct FinancialTransaction {
    let simulationDay: Int
    let calendarDate: Date
    let category: String
    let description: String
    let amount: Double
}

struct Finance {
    var actualBalance: Double
    var displayedBalance: Double
}
