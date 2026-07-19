import SwiftUI

@main struct LedgerlyApp: App { var body: some Scene { WindowGroup { RootView(model: LedgerViewModel()) } } }

@MainActor final class LedgerViewModel: ObservableObject {
    @Published private(set) var ledger: Ledger?; @Published var recovery: String?; @Published var message: String?
    let store: LedgerStore
    init(store: LedgerStore = FileLedgerStore()) { self.store = store; open() }
    func open() { do { ledger = try store.load(); recovery = nil } catch LedgerError.unsafe(let text) { recovery = text } catch { message = "We couldn’t open your ledger. Try again." } }
    func setup(currency: String) { mutate(Ledger.fresh(currency: currency)) }
    func mutate(_ next: Ledger) { guard recovery == nil else { return }; if let existing = ledger, !existing.transactions.isEmpty, existing.currencyCode != next.currencyCode { message = "Currency is locked after the first transaction."; return }; do { try store.save(next); ledger = next } catch LedgerError.unsafe(let text) { recovery = text } catch LedgerError.retryable(let text) { message = text } catch { message = "Your ledger is unchanged." } }
    func add(_ draft: TransactionDraft) { guard var ledger, let tx = draft.transaction() else { return }; ledger.transactions.append(tx); mutate(ledger) }
    func update(_ id: UUID, draft: TransactionDraft) { guard var ledger, let index = ledger.transactions.firstIndex(where: { $0.id == id }), let tx = draft.transaction(id: id, createdAt: ledger.transactions[index].createdAt) else { return }; ledger.transactions[index] = tx; mutate(ledger) }
    func delete(_ id: UUID) { guard var ledger else { return }; ledger.transactions.removeAll { $0.id == id }; mutate(ledger) }
    func addCategory(name: String, kind: TransactionKind) -> String? { guard var ledger else { return "Ledger is unavailable." }; let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines); guard (1...40).contains(trimmed.count) else { return "Enter a name from 1 to 40 characters." }; guard !ledger.categories.contains(where: { $0.kind == kind && $0.normalizedName == trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) }) else { return "“\(trimmed)” already exists for \(kind == .expense ? "expenses" : "income")." }; ledger.categories.append(LedgerCategory(name: trimmed, kind: kind)); mutate(ledger); return nil }
    func archive(_ category: LedgerCategory, archived: Bool) { guard var ledger, let i = ledger.categories.firstIndex(of: category) else { return }; ledger.categories[i].isArchived = archived; mutate(ledger) }
    func clear() { do { try store.clear(); ledger = nil; message = nil } catch { message = "Data wasn’t cleared. Your ledger is unchanged." } }
}
