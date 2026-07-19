import Foundation

protocol LedgerRepository {
    func open() throws -> LedgerSnapshot
    func completeOnboarding(currencyCode: String) throws
    func save(_ draft: TransactionDraft, replacing id: UUID?) throws -> LedgerTransaction
    func deleteTransaction(_ id: UUID) throws
    func categories(status: CategoryStatus, kind: TransactionKind?) throws -> [LedgerCategory]
    func createCategory(name: String, kind: TransactionKind) throws
    func setCategory(_ id: UUID, status: CategoryStatus) throws
    func transactions(in month: MonthKey) throws -> [LedgerTransaction]
    func summary(in month: MonthKey) throws -> MonthlySummary
    func exportCSV() throws -> URL
    func clearAllData() throws
}

struct LedgerSnapshot { let settings: LedgerSettings; let categories: [LedgerCategory]; let transactions: [LedgerTransaction] }
