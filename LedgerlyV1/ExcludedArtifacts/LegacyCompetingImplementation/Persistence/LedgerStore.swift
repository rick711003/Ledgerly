import Foundation

protocol LedgerStore: Sendable {
    func open() async throws -> Ledger?
    func save(_ ledger: Ledger) async throws
    func clear() async throws
}

actor JSONLedgerStore: LedgerStore {
    // This filename deliberately has no relationship to the discarded prototype's storage.
    private let url: URL
    init(fileManager: FileManager = .default) {
        let folder = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LedgerlyV1.PrivateLedger", isDirectory: true)
        url = folder.appendingPathComponent("ledger-v1.json")
    }
    init(url: URL) { self.url = url }
    func open() async throws -> Ledger? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let ledger = try JSONDecoder().decode(Ledger.self, from: Data(contentsOf: url))
            guard ledger.schemaVersion <= Ledger.schemaVersion else { throw LedgerError.newerStore }
            guard ledger.schemaVersion == Ledger.schemaVersion else { throw LedgerError.corruptedStore }
            return ledger
        } catch let error as LedgerError { throw error }
        catch { throw LedgerError.corruptedStore }
    }
    func save(_ ledger: Ledger) async throws {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(ledger)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch { throw LedgerError.retryableStorage }
    }
    func clear() async throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do { try FileManager.default.removeItem(at: url) } catch { throw LedgerError.retryableStorage }
    }
}

actor LedgerRepository {
    private let store: LedgerStore
    private(set) var ledger: Ledger?
    init(store: LedgerStore) { self.store = store }
    func open() async throws -> Ledger? { let value = try await store.open(); ledger = value; return value }
    func setup(currencyCode: String) async throws -> Ledger {
        let clean = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard clean.range(of: "^[A-Z]{3}$", options: .regularExpression) != nil else { throw LedgerError.amountInvalid }
        let value = Ledger.new(currencyCode: clean); try await store.save(value); ledger = value; return value
    }
    func updateCurrency(_ code: String) async throws {
        guard var value = ledger else { throw LedgerError.corruptedStore }
        guard value.entries.isEmpty else { throw LedgerError.currencyLocked }
        value.currencyCode = code; try await commit(value)
    }
    func save(draft: EntryDraft, editingID: UUID? = nil, now: Date = .now) async throws -> LedgerEntry {
        guard var value = ledger else { throw LedgerError.corruptedStore }
        let minor = try Self.minorAmount(draft.amountText)
        guard draft.note.count <= 500 else { throw LedgerError.noteTooLong }
        guard draft.occurredOn <= now else { throw LedgerError.futureDate }
        guard let categoryID = draft.categoryID else { throw LedgerError.categoryRequired }
        guard let category = value.category(for: categoryID), !category.isArchived, category.type == draft.type else { throw LedgerError.categoryUnavailable }
        let entry: LedgerEntry
        if let editingID, let index = value.entries.firstIndex(where: { $0.id == editingID }) {
            entry = LedgerEntry(id: editingID, type: draft.type, amountMinor: minor, categoryID: categoryID, occurredOn: draft.occurredOn, note: draft.note, createdAt: value.entries[index].createdAt, updatedAt: now)
            value.entries[index] = entry
        } else { entry = LedgerEntry(type: draft.type, amountMinor: minor, categoryID: categoryID, occurredOn: draft.occurredOn, note: draft.note, createdAt: now, updatedAt: now); value.entries.append(entry) }
        try await commit(value); return entry
    }
    func delete(id: UUID) async throws { guard var value = ledger else { throw LedgerError.corruptedStore }; value.entries.removeAll { $0.id == id }; try await commit(value) }
    func addCategory(name: String, type: EntryType) async throws {
        guard var value = ledger else { throw LedgerError.corruptedStore }; let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LedgerError.categoryNameRequired }; guard trimmed.count <= 40 else { throw LedgerError.categoryNameTooLong }
        guard !value.categories.contains(where: { $0.type == type && $0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) == trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) }) else { throw LedgerError.categoryNameDuplicate }
        value.categories.append(Category(name: trimmed, type: type)); try await commit(value)
    }
    func setArchived(id: UUID, archived: Bool) async throws {
        guard var value = ledger, let index = value.categories.firstIndex(where: { $0.id == id }) else { throw LedgerError.categoryUnavailable }
        guard !value.categories[index].isBuiltIn else { throw LedgerError.builtInCategory }; value.categories[index].isArchived = archived; try await commit(value)
    }
    func clear() async throws { try await store.clear(); ledger = nil }
    private func commit(_ value: Ledger) async throws { try await store.save(value); ledger = value }
    static func minorAmount(_ text: String) throws -> Int {
        let cleaned = text.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)
        guard let decimal = Decimal(string: cleaned), decimal > 0 else { throw LedgerError.amountInvalid }
        let value = NSDecimalNumber(decimal: decimal * 100).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: true, raiseOnUnderflow: true, raiseOnDivideByZero: true))
        guard value != .notANumber, value.intValue > 0 else { throw LedgerError.amountInvalid }; return value.intValue
    }
}
