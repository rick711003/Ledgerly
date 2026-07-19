import Foundation

enum TransactionKind: String, Codable, CaseIterable, Identifiable { case expense, income; var id: String { rawValue } }

struct LedgerCategory: Codable, Identifiable, Hashable {
    var id: UUID = UUID(); var name: String; var kind: TransactionKind; var isBuiltIn = false; var isArchived = false
    var normalizedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) }
}

struct LedgerTransaction: Codable, Identifiable, Hashable {
    var id: UUID = UUID(); var kind: TransactionKind; var amountMinor: Int; var categoryID: UUID; var date: Date; var note: String; var createdAt = Date(); var updatedAt = Date()
}

struct Ledger: Codable {
    static let currentSchema = 1
    var schemaVersion = currentSchema; var currencyCode: String; var categories: [LedgerCategory]; var transactions: [LedgerTransaction]
    static func fresh(currency: String) -> Ledger { Ledger(currencyCode: currency, categories: defaultCategories, transactions: []) }
    static let defaultCategories = [
        LedgerCategory(name: "Food", kind: .expense, isBuiltIn: true), LedgerCategory(name: "Transport", kind: .expense, isBuiltIn: true),
        LedgerCategory(name: "Home", kind: .expense, isBuiltIn: true), LedgerCategory(name: "Freelance", kind: .income, isBuiltIn: true), LedgerCategory(name: "Salary", kind: .income, isBuiltIn: true)
    ]
}

struct TransactionDraft: Equatable {
    var kind: TransactionKind = .expense; var amount = ""; var categoryID: UUID?; var date = Date(); var note = ""
    func validation(in ledger: Ledger, calendar: Calendar = .current) -> [String: String] {
        var errors: [String: String] = [:]
        let cleaned = amount.replacingOccurrences(of: ",", with: "")
        let value = Decimal(string: cleaned) ?? 0
        let validFormat = cleaned.range(of: "^[0-9]+(\\.[0-9]{1,2})?$", options: .regularExpression) != nil
        if value <= 0 || !validFormat { errors["amount"] = "Enter an amount greater than zero." }
        if categoryID == nil || !ledger.categories.contains(where: { $0.id == categoryID && $0.kind == kind && !$0.isArchived }) { errors["category"] = "Choose an active \(kind.rawValue) category." }
        if date > calendar.startOfDay(for: Date()).addingTimeInterval(86_400) { errors["date"] = "Choose today or an earlier date." }
        if note.count > 500 { errors["note"] = "Keep the note to 500 characters or fewer." }
        return errors
    }
    func transaction(id: UUID = UUID(), createdAt: Date = Date()) -> LedgerTransaction? {
        guard let categoryID, let decimal = Decimal(string: amount.replacingOccurrences(of: ",", with: "")) else { return nil }
        let minor = NSDecimalNumber(decimal: decimal * 100).intValue
        return LedgerTransaction(id: id, kind: kind, amountMinor: minor, categoryID: categoryID, date: date, note: note.trimmingCharacters(in: .whitespacesAndNewlines), createdAt: createdAt, updatedAt: Date())
    }
}

enum LedgerError: Error, Equatable { case retryable(String), unsafe(String) }

extension Ledger {
    func totals(in month: Date, calendar: Calendar = .current) -> (income: Int, expense: Int) {
        transactions.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }.reduce((0, 0)) { partial, item in
            item.kind == .income ? (partial.0 + item.amountMinor, partial.1) : (partial.0, partial.1 + item.amountMinor)
        }
    }
}
