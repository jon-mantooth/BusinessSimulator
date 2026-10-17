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

enum PurchaseAvailability: Equatable {
    case available
    case locationLocked(requiredTier: LocationTierLevel)
    case insufficientFunds
    case operatingReserveRequired
}

struct FinancialTransaction: Codable {
    let amount: Double
    let direction: CashFlowDirection
}

enum PriceAnalysisPeriod: String, CaseIterable, Identifiable {
    case tenDays
    case thirtyDays
    case allTime

    var id: Self { self }

    func rows(
        from rows: [PriceAnalyticsRow]
    ) -> [PriceAnalyticsRow] {
        switch self {
        case .tenDays:
            return Array(rows.suffix(10))
        case .thirtyDays:
            return Array(rows.suffix(30))
        case .allTime:
            return rows
        }
    }
}

enum WeatherAnalysisGroup: String, CaseIterable {
    case great
    case good
    case fairOrWorse
}

struct WeatherPriceAnalysisResult: Identifiable {
    let group: WeatherAnalysisGroup
    let averagePriceRatio: Double?
    let observationCount: Int

    var id: WeatherAnalysisGroup { group }
}

enum BusinessReputationAnalysisGroup: String, CaseIterable {
    case great
    case good
    case fairOrBelow
}

struct BusinessReputationPriceAnalysisResult: Identifiable {
    let group: BusinessReputationAnalysisGroup
    let averagePriceRatio: Double?
    let observationCount: Int

    var id: BusinessReputationAnalysisGroup { group }
}

struct LevelPriceAnalysisResult: Identifiable {
    let level: Int
    let averagePriceRatio: Double?
    let observationCount: Int

    var id: Int { level }
}

struct LocationPriceAnalysisResult: Identifiable {
    let locationID: LocationID
    let locationName: String
    let averagePriceRatio: Double
    let observationCount: Int

    var id: LocationID { locationID }
}

private enum FinanceLocationNames {
    static let byID: [LocationID: String] = [
        LocationID(rawValue: "home"): "Neighborhood",
        LocationID(rawValue: "ballpark"): "Ballpark",
        LocationID(rawValue: "beach"): "Beach",
        LocationID(rawValue: "farmers-market"): "Farmer's Market"
    ]

    static func name(for locationID: LocationID) -> String {
        byID[locationID] ?? locationID.rawValue
    }
}

/// Finance owns these boundaries because they describe how reports group the
/// historical weather effect, not how weather affects gameplay.
struct WeatherAnalysisClassifier {
    func analysisGroup(
        for demandMultiplier: Double
    ) -> WeatherAnalysisGroup {
        switch demandMultiplier {
        case ...1.01:
            return .fairOrWorse
        case ...1.05:
            return .good
        default:
            return .great
        }
    }
}

struct BusinessReputationAnalysisClassifier {
    func analysisGroup(
        for reputation: Double
    ) -> BusinessReputationAnalysisGroup {
        // Raw scores of 90 and 75 correspond to the player-facing
        // 4.6- and 4.0-star boundaries, respectively.
        switch reputation {
        case 90...:
            return .great
        case 75..<90:
            return .good
        default:
            return .fairOrBelow
        }
    }
}

/// One operating day's normalized inputs for price analysis.
struct PriceAnalyticsRow {
    /// The actual simulation day retained for historical traceability.
    let simulationDay: Int
    /// Consecutive position among operating days. Charts use this value so
    /// relocation and other non-operating days do not create visual gaps.
    let operatingDay: Int
    let locationID: LocationID
    let price: Double
    let idealPrice: Double
    let highTemperature: Int
    let lowTemperature: Int
    let weatherDemandMultiplier: Double
    let businessReputation: Double
    let equipmentLevel: Int
    let advertisementLevel: Int

    var priceDeviation: Double {
        (price / idealPrice) - 1.0
    }
}

/// Derived, in-memory reporting data rebuilt from persisted day summaries.
struct PriceAnalytics {
    private(set) var rows: [PriceAnalyticsRow] = []

    init(
        summaries: [DaySummary] = []
    ) {
        for summary in summaries.sorted(by: { $0.day < $1.day }) {
            append(from: summary)
        }
    }

    func weatherAnalysis(
        for period: PriceAnalysisPeriod
    ) -> [WeatherPriceAnalysisResult] {
        let rowsForPeriod = period.rows(from: rows)
        let classifier = WeatherAnalysisClassifier()
        let rowsByGroup = Dictionary(grouping: rowsForPeriod) {
            classifier.analysisGroup(
                for: $0.weatherDemandMultiplier
            )
        }

        return WeatherAnalysisGroup.allCases.map { group in
            let groupRows = rowsByGroup[group] ?? []
            let averagePriceRatio = groupRows.isEmpty
                ? nil
                : groupRows.reduce(0.0) {
                    $0 + $1.priceDeviation
                } / Double(groupRows.count)

            return WeatherPriceAnalysisResult(
                group: group,
                averagePriceRatio: averagePriceRatio,
                observationCount: groupRows.count
            )
        }
    }

    func businessReputationAnalysis(
        for period: PriceAnalysisPeriod
    ) -> [BusinessReputationPriceAnalysisResult] {
        let rowsForPeriod = period.rows(from: rows)
        let classifier = BusinessReputationAnalysisClassifier()
        let rowsByGroup = Dictionary(grouping: rowsForPeriod) {
            classifier.analysisGroup(
                for: $0.businessReputation
            )
        }

        return BusinessReputationAnalysisGroup.allCases.map { group in
            let groupRows = rowsByGroup[group] ?? []
            let averagePriceRatio = groupRows.isEmpty
                ? nil
                : groupRows.reduce(0.0) {
                    $0 + $1.priceDeviation
                } / Double(groupRows.count)

            return BusinessReputationPriceAnalysisResult(
                group: group,
                averagePriceRatio: averagePriceRatio,
                observationCount: groupRows.count
            )
        }
    }

    func equipmentLevelAnalysis(
        for period: PriceAnalysisPeriod
    ) -> [LevelPriceAnalysisResult] {
        levelAnalysis(
            for: period,
            level: \PriceAnalyticsRow.equipmentLevel
        )
    }

    func advertisementLevelAnalysis(
        for period: PriceAnalysisPeriod
    ) -> [LevelPriceAnalysisResult] {
        levelAnalysis(
            for: period,
            level: \PriceAnalyticsRow.advertisementLevel
        )
    }

    func locationAnalysis(
        for period: PriceAnalysisPeriod
    ) -> [LocationPriceAnalysisResult] {
        let rowsForPeriod = period.rows(from: rows)
        let rowsByLocation = Dictionary(grouping: rowsForPeriod) {
            $0.locationID
        }
        let orderedLocationIDs = rowsForPeriod.reduce(
            into: [LocationID]()
        ) { locationIDs, row in
            guard !locationIDs.contains(row.locationID) else {
                return
            }
            locationIDs.append(row.locationID)
        }

        return orderedLocationIDs.compactMap { locationID in
            guard let locationRows = rowsByLocation[locationID],
                  !locationRows.isEmpty else {
                return nil
            }

            let averagePriceRatio = locationRows.reduce(0.0) {
                $0 + $1.priceDeviation
            } / Double(locationRows.count)

            return LocationPriceAnalysisResult(
                locationID: locationID,
                locationName: FinanceLocationNames.name(for: locationID),
                averagePriceRatio: averagePriceRatio,
                observationCount: locationRows.count
            )
        }
    }

    private func levelAnalysis(
        for period: PriceAnalysisPeriod,
        level: KeyPath<PriceAnalyticsRow, Int>
    ) -> [LevelPriceAnalysisResult] {
        let rowsForPeriod = period.rows(from: rows)
        let rowsByLevel = Dictionary(grouping: rowsForPeriod) {
            $0[keyPath: level]
        }

        return UpgradeTierLevel.allCases.map { tier in
            let level = tier.rawValue
            let levelRows = rowsByLevel[level] ?? []
            let averagePriceRatio = levelRows.isEmpty
                ? nil
                : levelRows.reduce(0.0) {
                    $0 + $1.priceDeviation
                } / Double(levelRows.count)

            return LevelPriceAnalysisResult(
                level: level,
                averagePriceRatio: averagePriceRatio,
                observationCount: levelRows.count
            )
        }
    }

    mutating func append(
        from summary: DaySummary
    ) {
        guard summary.type == .operating else {
            return
        }

        guard let price = summary.price,
              let idealPrice = summary.idealPrice,
              let highTemperature = summary.highTemperature,
              let lowTemperature = summary.lowTemperature,
              let weatherDemandMultiplier =
                summary.weatherDemandMultiplier,
              let businessReputation = summary.businessReputation,
              let equipmentLevel = summary.equipmentLevel,
              let advertisementLevel = summary.advertisementLevel else {
            preconditionFailure(
                "An operating summary must contain all price-analysis factors."
            )
        }

        precondition(
            idealPrice > 0,
            "Ideal price must be greater than zero for price analysis."
        )
        precondition(
            rows.last.map {
                $0.simulationDay < summary.day
            } ?? true,
            "Price-analysis rows must be appended in chronological order."
        )

        rows.append(
            PriceAnalyticsRow(
                simulationDay: summary.day,
                operatingDay: rows.count + 1,
                locationID: summary.locationID,
                price: price,
                idealPrice: idealPrice,
                highTemperature: highTemperature,
                lowTemperature: lowTemperature,
                weatherDemandMultiplier: weatherDemandMultiplier,
                businessReputation: businessReputation,
                equipmentLevel: equipmentLevel,
                advertisementLevel: advertisementLevel
            )
        )
    }
}

struct Finance {
    var actualBalance: Double
    var displayedBalance: Double
    let minimumOperatingAllowance: Double

    init(
        product: Product,
        productInventoryStates: [ProductInventoryState],
        balance: Double? = nil
    ) {
        let minimumOperatingAllowance =
            Self.minimumOperatingReserve(
                for: product,
                productInventoryStates: productInventoryStates
            )
        let initialBalance = max(
            balance ?? minimumOperatingAllowance,
            minimumOperatingAllowance
        )

        self.actualBalance = initialBalance
        self.displayedBalance = initialBalance
        self.minimumOperatingAllowance = minimumOperatingAllowance
    }

    /// Calculates the cash needed to purchase enough whole inventory packages
    /// to produce half of the product's ideal daily sales, then rounds that cost
    /// up to the next $50. New games use this amount as both their starting
    /// balance and minimum operating reserve.
    static func minimumOperatingReserve(
        for product: Product,
        productInventoryStates: [ProductInventoryState]
    ) -> Double {
        let idealRevenue =
            product.baseIdealPrice * Double(product.idealUnitsSold)
        let idealSales = idealRevenue / product.baseIdealPrice
        let targetSales = idealSales / 2.0

        var inventoryCost = 0.0
        for productInventoryState in productInventoryStates {
            let productInventory =
                productInventoryState.productInventory
            let requiredIngredientAmount =
                targetSales
                    * productInventoryState.effectiveRecipeAmount
            let purchasePackagesNeeded = ceil(
                requiredIngredientAmount
                    / Double(productInventory.inventory.purchaseAmount)
            )

            inventoryCost += purchasePackagesNeeded
                * productInventory.inventory.pricePerUnit
        }

        return ceil(inventoryCost / 50.0) * 50.0
    }

    func purchaseAvailability(
        for price: Double
    ) -> PurchaseAvailability {
        if price == 0 {
            return .available
        }

        if price > displayedBalance {
            return .insufficientFunds
        }

        if price + minimumOperatingAllowance > displayedBalance {
            return .operatingReserveRequired
        }

        return .available
    }
}
