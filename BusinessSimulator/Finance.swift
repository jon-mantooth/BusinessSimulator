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

extension CostCategory {
    /// Best-effort categorization for saves written before `Cost` persisted a
    /// category. All newly recorded costs carry an explicit category.
    static func legacyCategory(
        for name: String
    ) -> CostCategory {
        let normalizedName = name.lowercased()

        if normalizedName.contains("labor") {
            return .labor
        }
        if normalizedName.contains("equipment") {
            return .equipment
        }
        if normalizedName.contains("relocation") {
            return .relocation
        }
        if normalizedName.contains("ingredient") {
            return .ingredients
        }

        return .other
    }
}

/// One simulation day's cash-flow inputs for financial reporting.
struct FinancialSummaryRow {
    let day: Int
    let locationID: LocationID
    let startingBalance: Double
    let revenue: Double
    let costs: [Cost]

    var endingBalance: Double {
        startingBalance + revenue - costs.reduce(0.0) {
            $0 + $1.amount
        }
    }
}

/// One itemized cost total within a financial-report category.
struct FinancialCostItem: Identifiable {
    var id: String { name }

    let name: String
    let total: Double
}

/// All itemized costs and their combined total for one cost category.
struct FinancialCostCategory: Identifiable {
    var id: CostCategory { category }

    let category: CostCategory
    let items: [FinancialCostItem]
    let total: Double
}

/// One chronological point used by the revenue-trend graph.
struct FinancialRevenuePoint: Identifiable {
    var id: Int { day }

    let day: Int
    let revenue: Double
}

/// Display-ready financial results for all locations or one selected location.
struct FinancialReport {
    let locationID: LocationID?
    let totalDays: Int
    let startingBalance: Double?
    let endingBalance: Double?
    let totalRevenue: Double
    let revenuePerDay: Double
    let revenueByDay: [FinancialRevenuePoint]
    let costCategories: [FinancialCostCategory]
    let totalCosts: Double
    let netProfit: Double
}

/// Derived, in-memory financial reporting data rebuilt from persisted day
/// summaries. It includes both operating and non-operating days because costs
/// such as relocation remain financially meaningful when revenue is zero.
struct FinancialSummary {
    private(set) var rows: [FinancialSummaryRow] = []

    init(
        summaries: [DaySummary] = []
    ) {
        for summary in summaries.sorted(by: { $0.day < $1.day }) {
            append(from: summary)
        }
    }

    mutating func append(
        from summary: DaySummary
    ) {
        precondition(
            rows.last.map { $0.day < summary.day } ?? true,
            "Financial-summary rows must be appended in chronological order."
        )

        rows.append(
            FinancialSummaryRow(
                day: summary.day,
                locationID: summary.locationID,
                startingBalance: summary.startingBalance,
                revenue: summary.revenue,
                costs: summary.cashFlowCosts
            )
        )
    }

    /// Builds a report from all rows when `locationID` is nil, or only rows
    /// belonging to the requested location otherwise.
    func report(
        for locationID: LocationID?
    ) -> FinancialReport {
        let filteredRows = rows.filter { row in
            locationID.map { row.locationID == $0 } ?? true
        }
        let totalRevenue = filteredRows.reduce(0.0) {
            $0 + $1.revenue
        }
        let allCosts = filteredRows.flatMap(\.costs)

        let costsByCategory = Dictionary(
            grouping: allCosts,
            by: \.category
        )
        let costCategories = CostCategory.allCases.map { category in
            let categoryCosts = costsByCategory[category, default: []]
            let itemTotals = categoryCosts.reduce(into: [String: Double]()) {
                totals,
                cost in
                totals[cost.name, default: 0] += cost.amount
            }
            let items = itemTotals.map { name, total in
                FinancialCostItem(name: name, total: total)
            }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name)
                    == .orderedAscending
            }

            return FinancialCostCategory(
                category: category,
                items: items,
                total: categoryCosts.reduce(0.0) {
                    $0 + $1.amount
                }
            )
        }
        let totalCosts = allCosts.reduce(0.0) {
            $0 + $1.amount
        }
        let totalDays = filteredRows.count

        return FinancialReport(
            locationID: locationID,
            totalDays: totalDays,
            startingBalance: filteredRows.first?.startingBalance,
            endingBalance: filteredRows.last?.endingBalance,
            totalRevenue: totalRevenue,
            revenuePerDay: totalDays == 0
                ? 0
                : totalRevenue / Double(totalDays),
            revenueByDay: filteredRows.map {
                FinancialRevenuePoint(day: $0.day, revenue: $0.revenue)
            },
            costCategories: costCategories,
            totalCosts: totalCosts,
            netProfit: totalRevenue - totalCosts
        )
    }
}

enum AnalysisPeriod: String, CaseIterable, Identifiable {
    case tenDays
    case thirtyDays
    case allTime

    var id: Self { self }

    func rows<Row>(from rows: [Row]) -> [Row] {
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

enum FinanceLocationNames {
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
        for period: AnalysisPeriod
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
        for period: AnalysisPeriod
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
        for period: AnalysisPeriod
    ) -> [LevelPriceAnalysisResult] {
        levelAnalysis(
            for: period,
            level: \PriceAnalyticsRow.equipmentLevel
        )
    }

    func advertisementLevelAnalysis(
        for period: AnalysisPeriod
    ) -> [LevelPriceAnalysisResult] {
        levelAnalysis(
            for: period,
            level: \PriceAnalyticsRow.advertisementLevel
        )
    }

    func locationAnalysis(
        for period: AnalysisPeriod
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
        for period: AnalysisPeriod,
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

/// One operating day's normalized inputs for sales analysis.
struct SalesAnalyticsRow {
    /// The actual simulation day retained for historical traceability.
    let simulationDay: Int
    /// Consecutive position among operating days. Charts use this value so
    /// relocation and other non-operating days do not create visual gaps.
    let operatingDay: Int
    let actualSales: Int
    let operationalCapacity: Int
    let operationalCapacityLimiters: [SalesLimit]
    let didSellOut: Bool
    let selloutCause: SelloutCause?
    let consumedIngredientCost: Double
    let expiredIngredientCost: Double
}

struct SalesCapacityAnalysisPoint: Identifiable {
    let operatingDay: Int
    let actualSales: Int
    let potentialSalesCapacity: Int

    var id: Int { operatingDay }
}

enum SalesOutcome: String, CaseIterable, Identifiable {
    case didNotSellOut
    case ingredients
    case labor
    case equipment
    case storage

    var id: Self { self }
}

struct SelloutAnalysisResult: Identifiable {
    let outcome: SalesOutcome
    let dayCount: Int
    let percentage: Double?

    var id: SalesOutcome { outcome }
}

struct IngredientUsageAnalysisResult {
    let consumedCost: Double
    let expiredCost: Double

    var totalCost: Double {
        consumedCost + expiredCost
    }

    var consumedPercentage: Double? {
        guard totalCost > 0 else { return nil }
        return consumedCost / totalCost
    }

    var expiredPercentage: Double? {
        guard totalCost > 0 else { return nil }
        return expiredCost / totalCost
    }
}

/// Derived, in-memory reporting data rebuilt from persisted day summaries.
struct SalesAnalytics {
    private(set) var rows: [SalesAnalyticsRow] = []
    let maximumOperationalCapacity: Int

    var currentOperationalCapacity: Int? {
        rows.last?.operationalCapacity
    }

    var currentOperationalCapacityLimiters: [SalesLimit] {
        rows.last?.operationalCapacityLimiters ?? []
    }

    init(
        product: Product,
        summaries: [DaySummary] = []
    ) {
        maximumOperationalCapacity = ProductionCapacityBalance.schedule
            .capacity(
                for: .tier(.tierFive),
                product: product
            )

        for summary in summaries.sorted(by: { $0.day < $1.day }) {
            append(from: summary)
        }
    }

    func salesCapacityAnalysis(
        for period: AnalysisPeriod
    ) -> [SalesCapacityAnalysisPoint] {
        period.rows(from: rows).map { row in
            SalesCapacityAnalysisPoint(
                operatingDay: row.operatingDay,
                actualSales: row.actualSales,
                potentialSalesCapacity: row.operationalCapacity
            )
        }
    }

    func selloutAnalysis(
        for period: AnalysisPeriod
    ) -> [SelloutAnalysisResult] {
        let rowsForPeriod = period.rows(from: rows)
        let rowsByOutcome = Dictionary(grouping: rowsForPeriod) {
            salesOutcome(for: $0)
        }

        return SalesOutcome.allCases.map { outcome in
            let dayCount = rowsByOutcome[outcome]?.count ?? 0
            let percentage = rowsForPeriod.isEmpty
                ? nil
                : Double(dayCount) / Double(rowsForPeriod.count)

            return SelloutAnalysisResult(
                outcome: outcome,
                dayCount: dayCount,
                percentage: percentage
            )
        }
    }

    func ingredientUsageAnalysis(
        for period: AnalysisPeriod
    ) -> IngredientUsageAnalysisResult {
        let rowsForPeriod = period.rows(from: rows)

        return IngredientUsageAnalysisResult(
            consumedCost: rowsForPeriod.reduce(0.0) {
                $0 + $1.consumedIngredientCost
            },
            expiredCost: rowsForPeriod.reduce(0.0) {
                $0 + $1.expiredIngredientCost
            }
        )
    }

    mutating func append(
        from summary: DaySummary
    ) {
        guard summary.type == .operating else {
            return
        }

        guard let operationalCapacity = summary.operationalCapacity else {
            preconditionFailure(
                "An operating summary must contain operational capacity."
            )
        }
        precondition(
            rows.last.map {
                $0.simulationDay < summary.day
            } ?? true,
            "Sales-analytics rows must be appended in chronological order."
        )

        rows.append(
            SalesAnalyticsRow(
                simulationDay: summary.day,
                operatingDay: rows.count + 1,
                actualSales: summary.sales,
                operationalCapacity: operationalCapacity,
                operationalCapacityLimiters:
                    summary.operationalCapacityLimiters,
                didSellOut: summary.didSellOut,
                selloutCause: summary.selloutCause,
                consumedIngredientCost: summary.consumedIngredientCost,
                expiredIngredientCost: summary.expiredIngredientCost
            )
        )
    }

    private func salesOutcome(
        for row: SalesAnalyticsRow
    ) -> SalesOutcome {
        guard row.didSellOut else {
            return .didNotSellOut
        }

        switch row.selloutCause {
        case .ingredients:
            return .ingredients
        case .labor:
            return .labor
        case .equipment:
            return .equipment
        case .storage:
            return .storage
        case nil:
            preconditionFailure(
                "A sellout must have a binding sales-limit cause."
            )
        }
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
