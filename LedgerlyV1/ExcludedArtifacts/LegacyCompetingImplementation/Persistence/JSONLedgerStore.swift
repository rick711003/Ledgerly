import Foundation

/// The v1 store is intentionally independent from every prototype namespace.
final class JSONLedgerStore: LedgerRepository {
    private struct Store: Codable { var settings: LedgerSettings; var categories: [LedgerCategory]; var transactions: [LedgerTransaction] }
    private let fileManager: FileManager
    private let url: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default, directory: URL? = nil) {
        self.fileManager = fileManager
        let base = directory ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.url = base.appendingPathComponent("LedgerlyV1", isDirectory: true).appendingPathComponent("ledger-v1.json")
        encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
    }

    func open() throws -> LedgerSnapshot {
        guard fileManager.fileExists(atPath: url.path) else { throw LedgerError.needsOnboarding }
        let store = try load()
        return LedgerSnapshot(settings: store.settings, categories: store.categories, transactions: store.transactions)
    }

    func completeOnboarding(currencyCode: String) throws {
        guard ["USD", "EUR", "GBP", "JPY", "TWD", "CAD", "AUD"].contains(currencyCode) else { throw LedgerError.validation("That currency isn’t available. Choose a supported ISO currency.") }
        let now = Date()
        let expense = ["Food", "Transport", "Home"].map { LedgerCategory(id: UUID(), name: $0, kind: .expense, isSystem: true, status: .active, createdAt: now, updatedAt: now) }
        let income = LedgerCategory(id: UUID(), name: "Income", kind: .income, isSystem: true, status: .active, createdAt: now, updatedAt: now)
        try persist(Store(settings: LedgerSettings(formatVersion: 1, onboardingCompleted: true, currencyCode: currencyCode), categories: expense + [income], transactions: []))
    }

    func save(_ draft: TransactionDraft, replacing id: UUID? = nil) throws -> LedgerTransaction {
        var store = try requireStore()
        try validate(draft, store: store)
        guard let category = store.categories.first(where: { $0.id == draft.categoryID }) else { throw LedgerError.validation("Choose an active \(draft.kind.rawValue) category.") }
        let now = Date(); let trimmed = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = LedgerTransaction(id: id ?? UUID(), kind: draft.kind, amountMinor: draft.amountMinor!, currencyCode: store.settings.currencyCode, categoryID: category.id, categoryName: category.name, occurredOn: draft.occurredOn, note: trimmed.isEmpty ? nil : trimmed, createdAt: id.flatMap { old in store.transactions.first(where: { $0.id == old })?.createdAt } ?? now, updatedAt: now)
        if let id, let index = store.transactions.firstIndex(where: { $0.id == id }) { store.transactions[index] = record }
        else if id != nil { throw LedgerError.notFound }
        else { store.transactions.append(record) }
        try persist(store); return record
    }

    func deleteTransaction(_ id: UUID) throws { var store = try requireStore(); guard let index = store.transactions.firstIndex(where: { $0.id == id }) else { throw LedgerError.notFound }; store.transactions.remove(at: index); try persist(store) }
    func categories(status: CategoryStatus, kind: TransactionKind? = nil) throws -> [LedgerCategory] { try requireStore().categories.filter { $0.status == status && (kind == nil || $0.kind == kind) }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } }
    func createCategory(name: String, kind: TransactionKind) throws {
        var store = try requireStore(); let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...40).contains(cleaned.count) else { throw LedgerError.validation("Use a category name between 1 and 40 characters.") }
        guard !store.categories.contains(where: { $0.kind == kind && $0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) == cleaned.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) }) else { throw LedgerError.validation("“\(cleaned)” already exists for \(kind.rawValue)s. Choose a different name.") }
        let now = Date(); store.categories.append(LedgerCategory(id: UUID(), name: cleaned, kind: kind, isSystem: false, status: .active, createdAt: now, updatedAt: now)); try persist(store)
    }
    func setCategory(_ id: UUID, status: CategoryStatus) throws {
        var store = try requireStore(); guard let index = store.categories.firstIndex(where: { $0.id == id }) else { throw LedgerError.notFound }
        guard !store.categories[index].isSystem || status == .active else { throw LedgerError.validation("Built-in categories can’t be archived.") }
        store.categories[index].status = status; store.categories[index].updatedAt = .now; try persist(store)
    }
    func transactions(in month: MonthKey) throws -> [LedgerTransaction] { try requireStore().transactions.filter { $0.occurredOn.monthKey == month }.sorted { $0.occurredOn == $1.occurredOn ? $0.createdAt > $1.createdAt : $0.occurredOn > $1.occurredOn } }
    func summary(in month: MonthKey) throws -> MonthlySummary { let records = try transactions(in: month); return MonthlySummary(month: month, incomeMinor: records.filter { $0.kind == .income }.reduce(0) { $0 + $1.amountMinor }, expenseMinor: records.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amountMinor }) }
    func exportCSV() throws -> URL {
        let store = try requireStore(); let header = "id,type,amount_minor,currency,category,date,note,created_at,updated_at\n"
        let rows = store.transactions.sorted { $0.createdAt < $1.createdAt }.map { tx in [tx.id.uuidString, tx.kind.rawValue, String(tx.amountMinor), tx.currencyCode, tx.categoryName, tx.occurredOn.description, tx.note ?? "", ISO8601DateFormatter().string(from: tx.createdAt), ISO8601DateFormatter().string(from: tx.updatedAt)].map(csv).joined(separator: ",") }.joined(separator: "\n")
        let output = fileManager.temporaryDirectory.appendingPathComponent("ledgerly-export-\(LocalDate()).csv")
        do { try (header + rows + "\n").data(using: .utf8)!.write(to: output, options: .atomic); return output } catch { throw LedgerError.retryable("CSV wasn’t created. Your ledger is unchanged. Try again when storage is available.") }
    }
    func clearAllData() throws { guard fileManager.fileExists(atPath: url.path) else { return }; do { try fileManager.removeItem(at: url) } catch { throw LedgerError.retryable("Data wasn’t cleared. Your ledger is unchanged.") } }

    private func requireStore() throws -> Store { let store = try load(); guard store.settings.onboardingCompleted else { throw LedgerError.needsOnboarding }; return store }
    private func load() throws -> Store { do { let data = try Data(contentsOf: url); let store = try decoder.decode(Store.self, from: data); guard store.settings.formatVersion == 1 else { throw store.settings.formatVersion > 1 ? LedgerError.unsupportedFormat : LedgerError.integrityFailure }; return store } catch let error as LedgerError { throw error } catch { throw LedgerError.integrityFailure } }
    private func persist(_ store: Store) throws { do { try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true); let data = try encoder.encode(store); try data.write(to: url, options: [.atomic, .completeFileProtection]); var values = URLResourceValues(); values.isExcludedFromBackup = true; var mutable = url; try? mutable.setResourceValues(values) } catch { throw LedgerError.retryable("Your change wasn’t saved. Check storage and try again.") } }
    private func validate(_ draft: TransactionDraft, store: Store) throws { guard let amount = draft.amountMinor, amount > 0 else { throw LedgerError.validation("Enter an amount greater than zero.") }; guard !draft.occurredOn.isFuture() else { throw LedgerError.validation("Choose today or an earlier date.") }; guard draft.note.count <= 500 else { throw LedgerError.validation("Notes can be up to 500 characters.") }; guard let id = draft.categoryID, let category = store.categories.first(where: { $0.id == id && $0.status == .active && $0.kind == draft.kind }) else { throw LedgerError.validation("Choose an active \(draft.kind.rawValue) category.") } }
}

private func csv(_ value: String) -> String { "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
