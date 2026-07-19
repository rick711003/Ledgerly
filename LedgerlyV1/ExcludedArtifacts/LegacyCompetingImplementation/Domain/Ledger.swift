import Foundation

enum EntryType: String, Codable, CaseIterable, Identifiable { case expense, income; var id: String { rawValue } }

struct Category: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var type: EntryType
    var isBuiltIn: Bool
    var isArchived: Bool
    init(id: UUID = UUID(), name: String, type: EntryType, isBuiltIn: Bool = false, isArchived: Bool = false) {
        self.id = id; self.name = name; self.type = type; self.isBuiltIn = isBuiltIn; self.isArchived = isArchived
    }
}

struct LedgerEntry: Codable, Identifiable, Equatable {
    let id: UUID
    var type: EntryType
    var amountMinor: Int
    var categoryID: UUID
    var occurredOn: Date
    var note: String
    let createdAt: Date
    var updatedAt: Date
    init(id: UUID = UUID(), type: EntryType, amountMinor: Int, categoryID: UUID, occurredOn: Date, note: String, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id; self.type = type; self.amountMinor = amountMinor; self.categoryID = categoryID; self.occurredOn = occurredOn; self.note = note; self.createdAt = createdAt; self.updatedAt = updatedAt
    }
}

struct Ledger: Codable, Equatable {
    static let schemaVersion = 1
    var schemaVersion: Int = Ledger.schemaVersion
    var currencyCode: String
    var categories: [Category]
    var entries: [LedgerEntry]
    static func new(currencyCode: String) -> Ledger {
        Ledger(currencyCode: currencyCode, categories: [
            Category(name: "Food", type: .expense, isBuiltIn: true),
            Category(name: "Transport", type: .expense, isBuiltIn: true),
            Category(name: "Home", type: .expense, isBuiltIn: true),
            Category(name: "Salary", type: .income, isBuiltIn: true),
            Category(name: "Freelance", type: .income, isBuiltIn: true)
        ], entries: [])
    }
}

struct EntryDraft: Equatable {
    var type: EntryType = .expense
    var amountText = ""
    var categoryID: UUID?
    var occurredOn = Date()
    var note = ""
}

enum LedgerError: Error, Equatable, LocalizedError {
    case amountRequired, amountInvalid, categoryRequired, categoryUnavailable, futureDate, noteTooLong
    case categoryNameRequired, categoryNameTooLong, categoryNameDuplicate, builtInCategory
    case currencyLocked, retryableStorage, corruptedStore, newerStore
    var errorDescription: String? {
        switch self {
        case .amountRequired, .amountInvalid: return "Enter an amount greater than zero."
        case .categoryRequired: return "Choose a category."
        case .categoryUnavailable: return "Choose an active category for this transaction type."
        case .futureDate: return "Choose today or an earlier date."
        case .noteTooLong: return "Notes can contain up to 500 characters."
        case .categoryNameRequired: return "Enter a category name."
        case .categoryNameTooLong: return "Category names can contain up to 40 characters."
        case .categoryNameDuplicate: return "That category already exists for this type."
        case .builtInCategory: return "Built-in categories cannot be archived."
        case .currencyLocked: return "Currency is locked after the first transaction."
        case .retryableStorage: return "Storage is temporarily unavailable."
        case .corruptedStore: return "Ledgerly can’t safely read this data. It has been preserved."
        case .newerStore: return "This ledger was created by a newer version."
        }
    }
}

struct MonthSummary: Equatable { var income = 0; var expenses = 0; var net: Int { income - expenses } }

extension Ledger {
    func category(for id: UUID) -> Category? { categories.first { $0.id == id } }
    func summary(for month: Date, calendar: Calendar = .current) -> MonthSummary {
        entries.filter { calendar.isDate($0.occurredOn, equalTo: month, toGranularity: .month) }.reduce(into: MonthSummary()) { result, entry in
            if entry.type == .income { result.income += entry.amountMinor } else { result.expenses += entry.amountMinor }
        }
    }
}
