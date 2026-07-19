import Foundation

public enum LedgerStoreError: Error, Equatable { case retryable, integrity, unsupportedFormat }

public protocol LedgerStoring: Sendable {
    func load() throws -> LedgerData
    func save(_ data: LedgerData) throws
    func clear() throws
}

/// A distinct v1 namespace. Writes replace a staged file atomically; corrupt and newer data is never overwritten.
public final class FileLedgerStore: LedgerStoring, @unchecked Sendable {
    private let url: URL
    public init(fileManager: FileManager = .default) {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        url = base.appendingPathComponent("LedgerlyV1", isDirectory: true).appendingPathComponent("ledger-v1.json")
    }
    public init(url: URL) { self.url = url }
    public func load() throws -> LedgerData {
        guard FileManager.default.fileExists(atPath: url.path) else { return .empty }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(LedgerData.self, from: data)
            guard decoded.formatVersion <= LedgerData.formatVersion else { throw LedgerStoreError.unsupportedFormat }
            guard decoded.formatVersion == LedgerData.formatVersion else { throw LedgerStoreError.integrity }
            return decoded
        } catch let error as LedgerStoreError { throw error } catch { throw LedgerStoreError.integrity }
    }
    public func save(_ data: LedgerData) throws {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: url, options: .atomic)
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
        } catch { throw LedgerStoreError.retryable }
    }
    public func clear() throws { do { if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) } } catch { throw LedgerStoreError.retryable } }
}

public enum CSVExporter {
    public static func makeCSV(_ ledger: LedgerData) -> String {
        let header = "id,type,amount_minor,currency,category,date,note,created_at,updated_at,category_status"
        let iso = ISO8601DateFormatter(); let rows = ledger.transactions.map { item in
            let status = ledger.categories.first(where: { $0.id == item.categoryID })?.status.rawValue ?? "archived"
            return [item.id.uuidString, item.kind.rawValue, String(item.amountMinor), item.currency, item.categoryName, date(item.occurredOn), item.note, iso.string(from: item.createdAt), iso.string(from: item.updatedAt), status].map(escape).joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n") + "\n"
    }
    private static func date(_ value: DateComponents) -> String { String(format: "%04d-%02d-%02d", value.year ?? 0, value.month ?? 0, value.day ?? 0) }
    private static func escape(_ value: String) -> String { "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
}
