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

final class DaySummary {

    let day: Int
    let startingBalance: Double

    var sales: Int = 0
    var revenue: Double = 0
    var costs: [Cost] = []

    private(set) var sections: [SummarySection] = []

    var totalCosts: Double {
        costs.reduce(0) { $0 + $1.amount }
    }

    var profit: Double {
        revenue - totalCosts
    }

    var balance: Double {
        startingBalance + profit
    }

    init(
        day: Int,
        startingBalance: Double
    ) {
        self.day = day
        self.startingBalance = startingBalance
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
