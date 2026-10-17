//
//  Summary.swift
//  BusinessSimulator
//

import Foundation
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

enum SalesLimitType: Codable {
    case equipment
    case labor
    case storage
    case transportation
    case ingredient(type: InventoryType, name: String)

    var isOperationalCapacity: Bool {
        switch self {
        case .ingredient:
            return false
        case .equipment, .labor, .storage, .transportation:
            return true
        }
    }

    var selloutCause: SelloutCause {
        switch self {
        case .equipment:
            return .equipment
        case .labor:
            return .labor
        case .storage:
            return .storage
        case .transportation:
            return .transportation
        case .ingredient:
            return .ingredients
        }
    }
}

struct SalesLimit: Codable {
    let type: SalesLimitType
    let units: Int

    init(
        type: SalesLimitType,
        units: Int
    ) {
        precondition(units >= 0, "A sales limit cannot be negative.")
        self.type = type
        self.units = units
    }
}

enum SelloutCause: String, Codable, Hashable {
    case equipment
    case labor
    case storage
    case transportation
    case ingredients
    case multipleConstraints
}

enum DaySummaryType: String, Codable {
    case operating
    case relocation
}

final class DaySummary {

    let day: Int
    let locationID: LocationID
    let startingBalance: Double
    let type: DaySummaryType

    var demandedSales: Int = 0
    var sales: Int = 0
    var revenue: Double = 0
    var price: Double?
    var idealPrice: Double?
    var highTemperature: Int?
    var lowTemperature: Int?
    var weatherDemandMultiplier: Double?
    var businessReputation: Double?
    var equipmentLevel: Int?
    var advertisementLevel: Int?
    var salesLimits: [SalesLimit] = []
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

    var didSellOut: Bool {
        sales < demandedSales
    }

    var operationalCapacity: Int? {
        salesLimits
            .filter { $0.type.isOperationalCapacity }
            .map(\.units)
            .min()
    }

    var bindingSalesLimits: [SalesLimit] {
        guard didSellOut else { return [] }
        return salesLimits.filter { $0.units == sales }
    }

    var selloutCause: SelloutCause? {
        let causes = Set(
            bindingSalesLimits.map { $0.type.selloutCause }
        )

        guard let onlyCause = causes.first else {
            return nil
        }

        return causes.count == 1 ? onlyCause : .multipleConstraints
    }

    /// Combines persisted notes with notes derived from structured sales-limit
    /// data. Derived notes are presentation data and are never saved.
    var presentedSections: [SummarySection] {
        var presentedSections = sections

        for salesLimitSection in salesLimitSections {
            if let existingIndex = presentedSections.firstIndex(
                where: { $0.name == salesLimitSection.name }
            ) {
                presentedSections[existingIndex].notes.append(
                    contentsOf: salesLimitSection.notes
                )
            } else {
                presentedSections.append(salesLimitSection)
            }
        }

        return presentedSections
    }

    private var salesLimitSections: [SummarySection] {
        guard didSellOut else { return [] }

        var generatedSections: [SummarySection] = []
        var ingredientNames: [String] = []

        func addGeneratedNote(sectionName: String, note: String) {
            if let sectionIndex = generatedSections.firstIndex(
                where: { $0.name == sectionName }
            ) {
                generatedSections[sectionIndex].notes.append(note)
            } else {
                generatedSections.append(
                    SummarySection(name: sectionName, notes: [note])
                )
            }
        }

        for limit in bindingSalesLimits {
            switch limit.type {
            case .equipment:
                addGeneratedNote(
                    sectionName: "Sales",
                    note: "Sales were limited by equipment capacity."
                )
            case .labor:
                addGeneratedNote(
                    sectionName: "Sales",
                    note: "Sales were limited by labor capacity."
                )
            case .storage:
                addGeneratedNote(
                    sectionName: "Sales",
                    note: "Sales were limited by storage capacity."
                )
            case .transportation:
                addGeneratedNote(
                    sectionName: "Sales",
                    note: "Sales were limited by transportation capacity."
                )
            case let .ingredient(_, name):
                guard !ingredientNames.contains(name) else { continue }
                ingredientNames.append(name)
            }
        }

        if !ingredientNames.isEmpty {
            addGeneratedNote(
                sectionName: "Sales",
                note: "Sales were limited by a shortage of \(ingredientNames.formatted(.list(type: .and)))."
            )
        }

        return generatedSections
    }

    init(
        day: Int,
        locationID: LocationID = LocationID(rawValue: "home"),
        startingBalance: Double,
        type: DaySummaryType = .operating
    ) {
        self.day = day
        self.locationID = locationID
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
