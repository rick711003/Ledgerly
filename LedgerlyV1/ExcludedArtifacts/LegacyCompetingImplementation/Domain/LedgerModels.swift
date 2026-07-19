import Foundation

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case expense, income
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum CategoryStatus: String, Codable { case active, archived }

struct LocalDate: Codable, Hashable, Comparable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) { self.year = year; self.month = month; self.day = day }
    init(_ date: Date = .now, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year!, month: parts.month!, day: parts.day!)
    }
    var description: String { String(format: "%04d-%02d-%02d", year, month, day) }
    static func < (lhs: LocalDate, rhs: LocalDate) -> Bool { lhs.description < rhs.description }
    func isFuture(calendar: Calendar = .current) -> Bool { self > LocalDate(calendar: calendar) }
    var monthKey: MonthKey { MonthKey(year: year, month: month) }
}

struct MonthKey: Codable, Hashable, Comparable, CustomStringConvertible {
    let year: Int
    let month: Int
    init(year: Int, month: Int) { self.year = year; self.month = month }
    init(_ date: Date = .now, calendar: Calendar = .current) { self.init(year: calendar.component(.year, from: date), month: calendar.component(.month, from: date)) }
    var description: String { String(format: "%04d-%02d", year, month) }
    static func < (lhs: MonthKey, rhs: MonthKey) -> Bool { lhs.description < rhs.description }
    func offset(by value: Int) -> MonthKey {
        var calendar = Calendar.current; calendar.timeZone = .current
        let date = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        return MonthKey(calendar.date(byAdding: .month, value: value, to: date)!, calendar: calendar)
    }
    var title: String {
        let formatter = DateFormatter(); formatter.locale = .current; formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))!)
    }
}

struct LedgerSettings: Codable { var formatVersion = 1; var onboardingCompleted = false; var currencyCode = "USD" }
struct LedgerCategory: Codable, Identifiable, Hashable {
    let id: UUID; var name: String; let kind: TransactionKind; let isSystem: Bool; var status: CategoryStatus
    let createdAt: Date; var updatedAt: Date
}
struct LedgerTransaction: Codable, Identifiable, Hashable {
    let id: UUID; var kind: TransactionKind; var amountMinor: Int64; var currencyCode: String; var categoryID: UUID
    var categoryName: String; var occurredOn: LocalDate; var note: String?; let createdAt: Date; var updatedAt: Date
}
struct TransactionDraft { var kind: TransactionKind = .expense; var amountMinor: Int64?; var categoryID: UUID?; var occurredOn = LocalDate(); var note = "" }
struct MonthlySummary { let month: MonthKey; let incomeMinor: Int64; let expenseMinor: Int64; var netMinor: Int64 { incomeMinor - expenseMinor } }

enum LedgerError: LocalizedError, Equatable {
    case needsOnboarding, validation(String), retryable(String), integrityFailure, unsupportedFormat, notFound
    var errorDescription: String? {
        switch self {
        case .needsOnboarding: return "Ledger setup is needed."
        case .validation(let text), .retryable(let text): return text
        case .integrityFailure: return "Ledgerly can’t safely read this data. It has been preserved and nothing was replaced."
        case .unsupportedFormat: return "This ledger was created by a newer version. It has not been changed."
        case .notFound: return "This record is no longer available."
        }
    }
}
