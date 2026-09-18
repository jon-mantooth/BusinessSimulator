import Foundation

struct LaborID: RawRepresentable, Hashable, Codable {
    let rawValue: String
}

struct Labor: Identifiable, Equatable, Codable, PurchasableItem {
    let id: LaborID
    let name: String
    let smallIcon: GameIcon
    let description: String
    var price: Double
    let demandLevel: Int
    let totalLevels: Int
    /// Number of daily production units this worker adds to labor capacity.
    var capacity: Int

    var paymentSchedule: PaymentSchedule {
        .daily
    }

    var demandEffectScore: Double {
        Double(demandLevel) / Double(totalLevels)
    }

    var purchaseItemID: String {
        id.rawValue
    }

    init(
        id: LaborID,
        name: String,
        smallIcon: GameIcon,
        description: String,
        price: Double = 0,
        demandLevel: Int,
        totalLevels: Int = 5,
        capacity: Int = 0
    ) {
        assert(price >= 0, "Labor price cannot be negative.")
        assert(totalLevels > 0, "Labor total levels must be positive.")
        assert(capacity >= 0, "Labor capacity cannot be negative.")
        assert(demandLevel >= 0, "Labor demand level cannot be negative.")
        assert(
            demandLevel <= totalLevels,
            "Labor demand level cannot exceed total levels."
        )

        self.id = id
        self.name = name
        self.smallIcon = smallIcon
        self.description = description
        self.price = price
        self.demandLevel = demandLevel
        self.totalLevels = totalLevels
        self.capacity = capacity
    }
}

enum LaborCapacityBalance {
    static let playerBaselineRatio = 1.20
    static let specialistRatio = 0.50
    static let sharedWorkerRatio = 0.20

    static func capacity(
        ratio: Double,
        baseIdealUnitsSold: Int
    ) -> Int {
        assert(ratio >= 0)
        assert(baseIdealUnitsSold > 0)

        return Int(
            (Double(baseIdealUnitsSold) * ratio).rounded()
        )
    }

    static func playerBaselineCapacity(
        baseIdealUnitsSold: Int
    ) -> Int {
        capacity(
            ratio: playerBaselineRatio,
            baseIdealUnitsSold: baseIdealUnitsSold
        )
    }
}

struct LaborCollection: Equatable, Codable {
    private(set) var labor: [Labor]

    var totalDemandLevel: Int {
        labor.reduce(0) { $0 + $1.demandLevel }
    }

    var totalDemandEffectScore: Double {
        labor.reduce(0) { $0 + $1.demandEffectScore }
    }

    var totalCapacity: Int {
        labor.reduce(0) { $0 + $1.capacity }
    }

    var totalCosts: [PaymentSchedule: Double] {
        labor.reduce(into: [:]) { costs, worker in
            costs[worker.paymentSchedule, default: 0] += worker.price
        }
    }

    init(
        labor: [Labor] = []
    ) {
        let laborIDs = labor.map(\.id)
        assert(
            Set(laborIDs).count == laborIDs.count,
            "A labor collection cannot contain duplicates."
        )

        self.labor = labor
    }

    func contains(
        _ candidate: Labor
    ) -> Bool {
        labor.contains { $0.id == candidate.id }
    }

    mutating func add(
        _ newLabor: Labor
    ) {
        guard !contains(newLabor) else {
            preconditionFailure("A worker cannot be hired more than once.")
        }

        labor.append(newLabor)
    }
}

struct LaborRollbackState {
    let ownedLabor: LaborCollection
}

@Observable
final class LaborState: PurchasableState {
    typealias PurchaseItem = Labor
    typealias RollbackState = LaborRollbackState

    let laborCatalog: LaborCollection
    let playerBaselineCapacity: Int

    private(set) var ownedLabor: LaborCollection

    var dimensionID: PurchaseCategory {
        .labor
    }

    var availableLabor: LaborCollection {
        LaborCollection(
            labor: laborCatalog.labor.filter {
                !ownedLabor.contains($0)
            }
        )
    }

    var totalDemandLevel: Int {
        ownedLabor.totalDemandLevel
    }

    var totalDemandEffectScore: Double {
        ownedLabor.totalDemandEffectScore
    }

    var totalCapacity: Int {
        playerBaselineCapacity + ownedLabor.totalCapacity
    }

    var totalCosts: [PaymentSchedule: Double] {
        ownedLabor.totalCosts
    }

    init(
        laborCatalog: LaborCollection,
        baseIdealUnitsSold: Int,
        ownedLabor: LaborCollection = LaborCollection()
    ) {
        let catalogIDs = Set(laborCatalog.labor.map(\.id))
        assert(
            ownedLabor.labor.allSatisfy { catalogIDs.contains($0.id) },
            "Owned labor must belong to this state's catalog."
        )

        self.laborCatalog = laborCatalog
        self.playerBaselineCapacity = LaborCapacityBalance
            .playerBaselineCapacity(
                baseIdealUnitsSold: baseIdealUnitsSold
            )
        self.ownedLabor = ownedLabor
    }

    func captureRollbackState() -> LaborRollbackState {
        LaborRollbackState(ownedLabor: ownedLabor)
    }

    func applyUpgrade(
        _ labor: Labor
    ) {
        guard laborCatalog.contains(labor) else {
            preconditionFailure(
                "Hired labor must belong to this state's catalog."
            )
        }

        ownedLabor.add(labor)
    }

    func revertUpgrade(
        to state: LaborRollbackState
    ) {
        ownedLabor = state.ownedLabor
    }
}

final class LaborDimension: Dimension {
    static let demandWeight = 0.18

    private let laborState: LaborState

    init(
        laborState: LaborState
    ) {
        self.laborState = laborState
    }

    func calculateDemand() -> Double {
        SimulationBalance.demand.multiplier(
            weight: Self.demandWeight,
            effectScore: laborState.totalDemandEffectScore
        )
    }

    func applySalesLimits(
        sales: Int,
        summary: DaySummary
    ) -> Int {
        let limitedSales = min(sales, laborState.totalCapacity)

        if limitedSales < sales {
            summary.addNote(
                sectionName: "Production",
                note: "Sales were limited by labor capacity."
            )
        }

        return limitedSales
    }

    func calculateDailyCosts(
        sales: Int,
        summary: DaySummary
    ) -> Double {
        recordCost(
            for: .daily,
            summary: summary
        )
    }

    func calculateWeeklyCosts(
        summary: DaySummary
    ) -> Double {
        recordCost(
            for: .weekly,
            summary: summary
        )
    }

    private func recordCost(
        for paymentSchedule: PaymentSchedule,
        summary: DaySummary
    ) -> Double {
        let totalCost = laborState
            .totalCosts[paymentSchedule, default: 0]

        if totalCost > 0 {
            summary.cashFlowCosts.append(
                Cost(
                    name: "Labor",
                    amount: totalCost
                )
            )
        }

        return totalCost
    }
}
