//
//  Summary.swift
//  BusinessSimulator
//
//  Created by jon mantooth on 7/29/26.
//

struct Cost {

    let name: String

    let amount: Double
}

struct SummarySection {

    let name: String

    var notes: [String]
}

enum DaySummaryType: String, Codable {
    case operating
    case relocation
}

final class DaySummary {

    let day: Int
    let startingBalance: Double
    let type: DaySummaryType

    var demandedSales: Int = 0
    var sales: Int = 0
    var revenue: Double = 0
    var economicCosts: [Cost] = []
    var cashFlowCosts: [Cost] = []
    var businessEvents: [BusinessEvent] = []
    var dailyReputationResult: DailyReputationResult?

    private(set) var sections: [SummarySection] = []

    var netCashFlow: Double {
        revenue - cashFlowCosts.reduce(0) {
            $0 + $1.amount
        }
    }

    var balance: Double {
        startingBalance + netCashFlow
    }

    init(
        day: Int,
        startingBalance: Double,
        type: DaySummaryType = .operating
    ) {
        self.day = day
        self.startingBalance = startingBalance
        self.type = type
    }

    func addNote(
        sectionName: String,
        note: String
    ) {
        if let sectionIndex = sections.firstIndex(
            where: { $0.name == sectionName }
        ) {
            sections[sectionIndex].notes.append(note)
        } else {
            sections.append(
                SummarySection(
                    name: sectionName,
                    notes: [note]
                )
            )
        }
    }
}

final class SimulationSummary {

    var daySummaries: [DaySummary] = []
}
