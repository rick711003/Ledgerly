import Foundation

enum StoreError: LocalizedError, Equatable { case retryable, integrity, newerFormat
    var errorDescription: String? { switch self { case .retryable: return "Storage is temporarily unavailable."; case .integrity: return "The ledger cannot be safely opened."; case .newerFormat: return "A newer Ledgerly version is needed." } }
}

protocol LedgerStoring { func load() throws -> LedgerState; func save(_ state: LedgerState) throws; func clear() throws }

final class FileLedgerStore: LedgerStoring {
    private let url: URL
    init(url: URL = FileLedgerStore.defaultURL()) { self.url = url }
    static func defaultURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LedgerlyV1", isDirectory: true).appendingPathComponent("ledger-v1.json")
    }
    func load() throws -> LedgerState {
        guard FileManager.default.fileExists(atPath: url.path) else { return LedgerState() }
        do {
            let state = try JSONDecoder.ledgerly.decode(LedgerState.self, from: Data(contentsOf: url))
            guard state.formatVersion <= LedgerState.formatVersion else { throw StoreError.newerFormat }
            guard state.formatVersion == LedgerState.formatVersion else { throw StoreError.integrity }
            return state
        } catch let error as StoreError { throw error } catch { throw StoreError.integrity }
    }
    func save(_ state: LedgerState) throws {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder.ledgerly.encode(state)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch { throw StoreError.retryable }
    }
    func clear() throws { do { if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) } } catch { throw StoreError.retryable } }
}

extension JSONEncoder { static let ledgerly: JSONEncoder = { let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e }() }
extension JSONDecoder { static let ledgerly: JSONDecoder = { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d }() }

enum CSVExporter {
    static func data(state: LedgerState) -> Data {
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withFullDate]
        var rows = ["id,type,amount_minor,amount,currency,category,date,note,created_at,updated_at,category_status"]
        for t in state.transactions.sorted(by: { $0.occurredOn > $1.occurredOn }) {
            let status = state.categories.first(where: { $0.id == t.categoryID })?.status.rawValue ?? "archived"
            let display = String(format: "%.2f", Double(t.amountMinor) / 100)
            rows.append([t.id.uuidString, t.kind.rawValue, "\(t.amountMinor)", display, t.currencyCode, t.categoryName, formatter.string(from: t.occurredOn), t.note, formatter.string(from: t.createdAt), formatter.string(from: t.updatedAt), status].map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n").data(using: .utf8)!
    }
    private static func escape(_ value: String) -> String { "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
}
