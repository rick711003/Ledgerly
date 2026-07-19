import Foundation

public enum TransactionKind: String, Codable, CaseIterable, Sendable { case expense, income }
public enum CategoryStatus: String, Codable, Sendable { case active, archived }

public struct LedgerCategory: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var kind: TransactionKind
    public var name: String
    public var isBuiltIn: Bool
    public var status: CategoryStatus
}

public struct LedgerTransaction: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var kind: TransactionKind
    /// Positive, integer minor units. The kind determines the sign in presentation.
    public var amountMinor: Int64
    public var currency: String
    public var categoryID: UUID
    public var categoryName: String
    public var occurredOn: DateComponents
    public var note: String
    public var createdAt: Date
    public var updatedAt: Date
}

public struct LedgerData: Codable, Sendable {
    public static let formatVersion = 1
    public var formatVersion: Int
    public var currency: String?
    public var categories: [LedgerCategory]
    public var transactions: [LedgerTransaction]

    public static let empty = LedgerData(formatVersion: formatVersion, currency: nil, categories: [], transactions: [])
}

public enum LedgerValidationError: Error, Equatable {
    case currencyRequired, invalidAmount, categoryUnavailable, futureDate, noteTooLong, categoryNameInvalid, duplicateCategory, currencyLocked
}

public enum LedgerValidator {
    public static func validate(kind: TransactionKind, amountMinor: Int64, category: LedgerCategory?, date: DateComponents, note: String, calendar: Calendar = .current) throws {
        guard amountMinor > 0 else { throw LedgerValidationError.invalidAmount }
        guard let category, category.status == .active, category.kind == kind else { throw LedgerValidationError.categoryUnavailable }
        guard note.count <= 500 else { throw LedgerValidationError.noteTooLong }
        let today = calendar.dateComponents([.year, .month, .day], from: Date())
        guard let selected = calendar.date(from: date), let current = calendar.date(from: today), selected <= current else { throw LedgerValidationError.futureDate }
    }
    public static func normalizedCategoryName(_ value: String) -> String { value.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) }
}

public struct MonthlySummary: Sendable { public var income: Int64; public var expense: Int64; public var net: Int64 { income - expense } }
public extension LedgerData {
    func transactions(in month: DateComponents) -> [LedgerTransaction] {
        transactions.filter { $0.occurredOn.year == month.year && $0.occurredOn.month == month.month }
            .sorted {
                let lhs = Calendar.current.date(from: $0.occurredOn) ?? .distantPast
                let rhs = Calendar.current.date(from: $1.occurredOn) ?? .distantPast
                return lhs > rhs || (lhs == rhs && $0.createdAt > $1.createdAt)
            }
    }
    func summary(in month: DateComponents) -> MonthlySummary {
        transactions(in: month).reduce(MonthlySummary(income: 0, expense: 0)) { result, transaction in
            var copy = result
            if transaction.kind == .income { copy.income += transaction.amountMinor } else { copy.expense += transaction.amountMinor }
            return copy
        }
    }
}
