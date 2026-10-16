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
    case fairOrWorse
    case good
    case great
}

struct WeatherPriceAnalysisResult: Identifiable {
    let group: WeatherAnalysisGroup
    let averagePriceRatio: Double?
    let observationCount: Int

    var id: WeatherAnalysisGroup { group }
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
struct FinancialAnalytics {
    private(set) var priceAnalytics: [PriceAnalyticsRow] = []

    init(
        summaries: [DaySummary] = []
    ) {
        for summary in summaries.sorted(by: { $0.day < $1.day }) {
            appendPriceAnalytics(from: summary)
        }
    }

    func weatherAnalysis(
        for period: PriceAnalysisPeriod
    ) -> [WeatherPriceAnalysisResult] {
        let rowsForPeriod = period.rows(from: priceAnalytics)
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

    mutating func appendPriceAnalytics(
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
            priceAnalytics.last.map {
                $0.simulationDay < summary.day
            } ?? true,
            "Price-analysis rows must be appended in chronological order."
        )

        priceAnalytics.append(
            PriceAnalyticsRow(
                simulationDay: summary.day,
                operatingDay: priceAnalytics.count + 1,
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
