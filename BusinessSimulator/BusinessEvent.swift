import Foundation

enum PurchaseCategory: String, Codable {
    case advertisement
    case equipment
    case labor
    case transportation
    case storage
}

struct PurchaseEvent: Codable {
    let category: PurchaseCategory
    let itemID: String
}

enum BusinessEventType: Codable {
    case purchase(PurchaseEvent)
}

struct BusinessEvent: Identifiable, Codable {
    let id: UUID
    let simulationDay: Int
    let calendarDate: Date
    let type: BusinessEventType
    let title: String
    let details: String?
    let financialTransaction: FinancialTransaction?

    init(
        id: UUID = UUID(),
        simulationDay: Int,
        calendarDate: Date,
        type: BusinessEventType,
        title: String,
        details: String? = nil,
        financialTransaction: FinancialTransaction? = nil
    ) {
        self.id = id
        self.simulationDay = simulationDay
        self.calendarDate = calendarDate
        self.type = type
        self.title = title
        self.details = details
        self.financialTransaction = financialTransaction
    }
}
