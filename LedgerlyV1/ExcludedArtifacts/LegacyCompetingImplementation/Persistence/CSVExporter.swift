import Foundation

enum CSVExporter {
    static func data(from ledger: Ledger) -> Data {
        let iso = ISO8601DateFormatter(); let date = DateFormatter(); date.calendar = .current; date.dateFormat = "yyyy-MM-dd"
        let header = ["id", "type", "amount_minor", "display_amount", "currency", "category", "category_status", "date", "note", "created_at", "updated_at"]
        let rows = ledger.entries.sorted { $0.occurredOn > $1.occurredOn }.map { entry -> [String] in
            let category = ledger.category(for: entry.categoryID)
            return [entry.id.uuidString, entry.type.rawValue, "\(entry.amountMinor)", String(format: "%.2f", Double(entry.amountMinor) / 100), ledger.currencyCode, category?.name ?? "Unknown", category?.isArchived == true ? "archived" : "active", date.string(from: entry.occurredOn), entry.note, iso.string(from: entry.createdAt), iso.string(from: entry.updatedAt)]
        }
        return (header + rows).map { $0.map(escape).joined(separator: ",") }.joined(separator: "\n").data(using: .utf8)!
    }
    private static func escape(_ value: String) -> String { "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\"" }
}
