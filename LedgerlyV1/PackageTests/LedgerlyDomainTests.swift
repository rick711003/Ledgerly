import XCTest
@testable import LedgerlyDomain

final class LedgerlyDomainTests: XCTestCase {
    func testCSVQuotesCommasAndQuotes() {
        let category = LedgerCategory(id: UUID(), kind: .expense, name: "Food", isBuiltIn: false, status: .active)
        let now = Date()
        let transaction = LedgerTransaction(id: UUID(), kind: .expense, amountMinor: 425, currency: "USD", categoryID: category.id, categoryName: category.name, occurredOn: Calendar.current.dateComponents([.year, .month, .day], from: now), note: "A, \"quoted\" note", createdAt: now, updatedAt: now)
        let ledger = LedgerData(formatVersion: LedgerData.formatVersion, currency: "USD", categories: [category], transactions: [transaction])
        XCTAssertTrue(CSVExporter.makeCSV(ledger).contains("\"A, \"\"quoted\"\" note\""))
    }
}
