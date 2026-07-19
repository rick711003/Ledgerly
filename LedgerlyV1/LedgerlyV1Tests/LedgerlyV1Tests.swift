import XCTest

@testable import LedgerlyV1

final class LedgerlyV1Tests: XCTestCase {
  override func tearDown() {
    UserDefaults.standard.removeObject(forKey: "appLanguage")
    super.tearDown()
  }
  func testLanguageChoicesResolveToExpectedLocales() {
    XCTAssertEqual(AppLanguage.english.locale.identifier, "en")
    XCTAssertEqual(AppLanguage.traditionalChinese.locale.identifier, "zh-Hant")
  }

  func testMoneyFormattingKeepsStoredMinorUnitsAcrossLocales() {
    XCTAssertEqual(minorUnits("42", currency: "TWD", locale: Locale(identifier: "zh-Hant")), 42)
    XCTAssertEqual(minorUnits("42.60", currency: "USD", locale: Locale(identifier: "en")), 4260)
    XCTAssertFalse(money(4260, currency: "USD", locale: Locale(identifier: "en")).isEmpty)
    XCTAssertFalse(money(4260, currency: "USD", locale: Locale(identifier: "zh-Hant")).isEmpty)
  }

  private final class ThrowingStore: LedgerStoring, @unchecked Sendable {
    var data: LedgerData
    var shouldFail = true
    init(_ data: LedgerData = .empty) { self.data = data }
    func load() throws -> LedgerData { data }
    func save(_ data: LedgerData) throws {
      if shouldFail { throw LedgerStoreError.retryable }
      self.data = data
    }
    func clear() throws {
      if shouldFail { throw LedgerStoreError.retryable }
      data = .empty
    }
  }
  private final class FailingStore: LedgerStoring, @unchecked Sendable {
    var data: LedgerData
    var shouldFailSave = true
    var shouldFailClear = true
    init(_ data: LedgerData = .empty) { self.data = data }
    func load() throws -> LedgerData { data }
    func save(_ data: LedgerData) throws {
      if shouldFailSave { throw LedgerStoreError.retryable }
      self.data = data
    }
    func clear() throws {
      if shouldFailClear { throw LedgerStoreError.retryable }
      data = .empty
    }
  }
  private func temporaryStore() -> FileLedgerStore {
    FileLedgerStore(
      url: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("ledger.json"))
  }

  private func category(status: CategoryStatus = .active) -> LedgerCategory {
    LedgerCategory(id: UUID(), kind: .expense, name: "Food", isBuiltIn: false, status: status)
  }

  private func transaction(category: LedgerCategory, note: String = "") -> LedgerTransaction {
    let now = Date()
    return LedgerTransaction(
      id: UUID(), kind: .expense, amountMinor: 4260, currency: "USD", categoryID: category.id,
      categoryName: category.name,
      occurredOn: Calendar.current.dateComponents([.year, .month, .day], from: now), note: note,
      createdAt: now, updatedAt: now)
  }

  func testNewStoreLoadsEmptyLedger() throws {
    let ledger = try temporaryStore().load()
    XCTAssertEqual(ledger.formatVersion, LedgerData.formatVersion)
    XCTAssertNil(ledger.currency)
    XCTAssertTrue(ledger.categories.isEmpty)
    XCTAssertTrue(ledger.transactions.isEmpty)
  }

  func testStoreRoundTripPreservesTransactionIdentity() throws {
    let store = temporaryStore()
    let food = category()
    let entry = transaction(category: food, note: "Cedar Market")
    let ledger = LedgerData(
      formatVersion: LedgerData.formatVersion, currency: "USD", categories: [food],
      transactions: [entry])
    try store.save(ledger)
    let loaded = try store.load()
    XCTAssertEqual(loaded.transactions.first?.id, entry.id)
    XCTAssertEqual(loaded.transactions.first?.createdAt, entry.createdAt)
    XCTAssertEqual(loaded.transactions.first?.note, "Cedar Market")
  }

  func testArchivedCategoryCannotValidateNewTransactionButHistoryRemains() throws {
    let archived = category(status: .archived)
    XCTAssertThrowsError(
      try LedgerValidator.validate(
        kind: .expense, amountMinor: 350, category: archived,
        date: Calendar.current.dateComponents([.year, .month, .day], from: Date()), note: "")
    ) { error in
      XCTAssertEqual(error as? LedgerValidationError, .categoryUnavailable)
    }
    let ledger = LedgerData(
      formatVersion: LedgerData.formatVersion, currency: "USD", categories: [archived],
      transactions: [transaction(category: archived)])
    XCTAssertEqual(ledger.transactions.count, 1)
  }

  func testMonthlySummarySeparatesIncomeAndExpense() {
    let food = category()
    let incomeCategory = LedgerCategory(
      id: UUID(), kind: .income, name: "Salary", isBuiltIn: false, status: .active)
    let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    let now = Date()
    let income = LedgerTransaction(
      id: UUID(), kind: .income, amountMinor: 10000, currency: "USD", categoryID: incomeCategory.id,
      categoryName: incomeCategory.name, occurredOn: today, note: "", createdAt: now, updatedAt: now
    )
    let expense = transaction(category: food)
    let ledger = LedgerData(
      formatVersion: LedgerData.formatVersion, currency: "USD", categories: [food, incomeCategory],
      transactions: [income, expense])
    let summary = ledger.summary(in: today)
    XCTAssertEqual(summary.income, 10000)
    XCTAssertEqual(summary.expense, 4260)
    XCTAssertEqual(summary.net, 5740)
  }

  func testCSVQuotesCommasAndQuotes() {
    let food = category()
    let ledger = LedgerData(
      formatVersion: LedgerData.formatVersion, currency: "USD", categories: [food],
      transactions: [transaction(category: food, note: "A, \"quoted\" note")])
    XCTAssertTrue(CSVExporter.makeCSV(ledger).contains("\"A, \"\"quoted\"\" note\""))
  }

  func testFutureDatesAreRejected() {
    let food = category()
    let future = Calendar.current.dateComponents(
      [.year, .month, .day], from: Date().addingTimeInterval(86_400))
    XCTAssertThrowsError(
      try LedgerValidator.validate(
        kind: .expense, amountMinor: 100, category: food, date: future, note: "")
    ) { error in
      XCTAssertEqual(error as? LedgerValidationError, .futureDate)
    }
  }

  func testCategoryNormalizationIgnoresWhitespaceCaseAndDiacritics() {
    XCTAssertEqual(
      LedgerValidator.normalizedCategoryName("  Café  "),
      LedgerValidator.normalizedCategoryName("cafe")
    )
  }

  func testTransactionOrderingUsesNewestDateThenCreationTime() {
    let food = category()
    let calendar = Calendar(identifier: .gregorian)
    let month = DateComponents(calendar: calendar, year: 2026, month: 7)
    let older = LedgerTransaction(
      id: UUID(), kind: .expense, amountMinor: 100, currency: "USD", categoryID: food.id,
      categoryName: food.name,
      occurredOn: DateComponents(calendar: calendar, year: 2026, month: 7, day: 2), note: "older",
      createdAt: Date(timeIntervalSince1970: 1), updatedAt: Date(timeIntervalSince1970: 1))
    let newerSameDay = LedgerTransaction(
      id: UUID(), kind: .expense, amountMinor: 200, currency: "USD", categoryID: food.id,
      categoryName: food.name,
      occurredOn: DateComponents(calendar: calendar, year: 2026, month: 7, day: 2), note: "newer",
      createdAt: Date(timeIntervalSince1970: 2), updatedAt: Date(timeIntervalSince1970: 2))
    let latestDay = LedgerTransaction(
      id: UUID(), kind: .expense, amountMinor: 300, currency: "USD", categoryID: food.id,
      categoryName: food.name,
      occurredOn: DateComponents(calendar: calendar, year: 2026, month: 7, day: 3), note: "latest",
      createdAt: Date(timeIntervalSince1970: 0), updatedAt: Date(timeIntervalSince1970: 0))
    let ledger = LedgerData(
      formatVersion: LedgerData.formatVersion, currency: "USD", categories: [food],
      transactions: [older, latestDay, newerSameDay])

    XCTAssertEqual(
      ledger.transactions(in: month).map(\.id), [latestDay.id, newerSameDay.id, older.id])
  }

  func testOverlongNotesAreRejected() {
    let food = category()
    let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    XCTAssertThrowsError(
      try LedgerValidator.validate(
        kind: .expense, amountMinor: 100, category: food, date: today,
        note: String(repeating: "x", count: 501))
    ) { error in
      XCTAssertEqual(error as? LedgerValidationError, .noteTooLong)
    }
  }

  func testCorruptStoreIsReportedAndItsBytesArePreserved() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
      .appendingPathComponent("ledger.json")
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let original = Data("not a Ledgerly ledger".utf8)
    try original.write(to: url)

    XCTAssertThrowsError(try FileLedgerStore(url: url).load()) { error in
      XCTAssertEqual(error as? LedgerStoreError, .integrity)
    }
    XCTAssertEqual(try Data(contentsOf: url), original)
  }

  func testNewerFormatIsReportedAndItsBytesArePreserved() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
      .appendingPathComponent("ledger.json")
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    let original = try JSONEncoder().encode(
      LedgerData(
        formatVersion: LedgerData.formatVersion + 1, currency: "USD", categories: [],
        transactions: []))
    try original.write(to: url)

    XCTAssertThrowsError(try FileLedgerStore(url: url).load()) { error in
      XCTAssertEqual(error as? LedgerStoreError, .unsupportedFormat)
    }
    XCTAssertEqual(try Data(contentsOf: url), original)
  }

  @MainActor
  func testFailedMutationDoesNotPublishAndRetryPublishesStagedChange() {
    let store = FailingStore()
    let model = LedgerViewModel(store: store)
    XCTAssertFalse(model.finishSetup(currency: "USD"))
    XCTAssertNil(model.ledger.currency)
    XCTAssertEqual(model.state, .onboarding)

    store.shouldFailSave = false
    XCTAssertTrue(model.finishSetup(currency: "USD"))
    XCTAssertEqual(model.ledger.currency, "USD")
    XCTAssertEqual(store.data.currency, "USD")
    XCTAssertEqual(model.state, .ready)
  }

  @MainActor
  func testFailedClearRetainsPublishedLedgerUntilStoreSucceeds() {
    let category = category()
    let initial = LedgerData(
      formatVersion: LedgerData.formatVersion, currency: "USD", categories: [category],
      transactions: [transaction(category: category)])
    let store = FailingStore(initial)
    let model = LedgerViewModel(store: store)
    XCTAssertFalse(model.clearLedger())
    XCTAssertEqual(model.ledger.transactions.count, 1)
    XCTAssertEqual(model.state, .ready)

    store.shouldFailClear = false
    XCTAssertTrue(model.clearLedger())
    XCTAssertTrue(model.ledger.transactions.isEmpty)
    XCTAssertEqual(model.state, .onboarding)
  }

  @MainActor
  func testCurrencyCannotChangeAfterFirstTransactionAndTWDUsesZeroMinorDigits() {
    let category = category()
    let ledger = LedgerData(
      formatVersion: LedgerData.formatVersion, currency: "TWD", categories: [category],
      transactions: [transaction(category: category)])
    let store = FailingStore(ledger)
    store.shouldFailSave = false
    let model = LedgerViewModel(store: store)
    XCTAssertFalse(model.changeCurrency("USD"))
    XCTAssertEqual(model.ledger.currency, "TWD")
    XCTAssertEqual(minorUnits("42", currency: "TWD"), 42)
    XCTAssertEqual(amountText(42, currency: "TWD"), "42")
  }

  @MainActor
  func testFailedMutationDoesNotPublishAndRetryPublishesStagedCandidate() {
    let store = ThrowingStore()
    let model = LedgerViewModel(store: store)
    XCTAssertFalse(model.finishSetup(currency: "USD"))
    XCTAssertNil(model.ledger.currency)
    XCTAssertTrue(model.ledger.categories.isEmpty)

    store.shouldFail = false
    XCTAssertTrue(model.finishSetup(currency: "USD"))
    XCTAssertEqual(model.ledger.currency, "USD")
    XCTAssertEqual(store.data.currency, "USD")
    XCTAssertFalse(model.ledger.categories.isEmpty)
  }

  @MainActor
  func testFailedDeleteAndClearLeavePublishedLedgerUnchanged() {
    let food = category()
    let record = transaction(category: food)
    let initial = LedgerData(
      formatVersion: LedgerData.formatVersion, currency: "USD", categories: [food],
      transactions: [record])
    let store = ThrowingStore(initial)
    let model = LedgerViewModel(store: store)
    XCTAssertFalse(
      model.mutate(success: .transactionDeleted, failure: .transactionDeleteFailed) {
        $0.transactions.removeAll()
      })
    XCTAssertEqual(model.ledger.transactions.map(\.id), [record.id])
    XCTAssertFalse(model.clearLedger())
    XCTAssertEqual(model.ledger.transactions.map(\.id), [record.id])
  }

  func testTWDUsesZeroFractionDigits() {
    XCTAssertEqual(
      money(42, currency: "TWD"),
      money(42, currency: "TWD").replacingOccurrences(of: ".00", with: ""))
    XCTAssertEqual(amountText(42, currency: "TWD"), "42")
  }

  @MainActor
  func testFailedSetupDoesNotPublishAndCanRetry() {
    let store = FailingStore()
    let model = LedgerViewModel(store: store)
    XCTAssertFalse(model.finishSetup(currency: "USD"))
    XCTAssertNil(model.ledger.currency)
    XCTAssertNil(store.data.currency)
    XCTAssertTrue(store.data.transactions.isEmpty)
    store.shouldFailSave = false
    XCTAssertTrue(model.finishSetup(currency: "USD"))
    XCTAssertEqual(model.ledger.currency, "USD")
    XCTAssertEqual(store.data.currency, "USD")
  }

  @MainActor
  func testFailedTransactionMutationDoesNotPublish() {
    let store = FailingStore()
    let model = LedgerViewModel(store: store)
    let item = transaction(category: category())
    XCTAssertFalse(
      model.mutate(success: .transactionSaved, failure: .transactionSaveFailed) {
        $0.transactions.append(item)
      })
    XCTAssertTrue(model.ledger.transactions.isEmpty)
    XCTAssertTrue(store.data.transactions.isEmpty)
  }

  @MainActor
  func testFailedClearRetainsPublishedLedger() {
    let store = FailingStore()
    store.shouldFailSave = false
    let model = LedgerViewModel(store: store)
    XCTAssertTrue(model.finishSetup(currency: "USD"))
    store.shouldFailClear = true
    XCTAssertFalse(model.clearLedger())
    XCTAssertEqual(model.ledger.currency, "USD")
  }

  func testTWDUsesZeroDecimalMinorUnits() {
    XCTAssertEqual(minorAmount("42", currency: "TWD"), 42)
    XCTAssertNil(minorAmount("42.5", currency: "TWD"))
    XCTAssertEqual(minorAmount("42.50", currency: "USD"), 4250)
  }

  func testLocalizedCurrencyParsingAndPresentationDoNotChangeMinorUnits() {
    XCTAssertEqual(
      minorAmount("1,234.50", currency: "USD", locale: Locale(identifier: "en_US")), 123_450)
    XCTAssertEqual(
      minorAmount("1,234.50", currency: "USD", locale: Locale(identifier: "zh_Hant_TW")), 123_450)
    XCTAssertEqual(
      minorAmount("1,234", currency: "TWD", locale: Locale(identifier: "zh_Hant_TW")), 1_234)
    XCTAssertEqual(
      amountText(123_450, currency: "USD", locale: Locale(identifier: "en_US")), "1,234.5")
  }

  func testExplicitLanguageResolvesTraditionalChineseWithoutMutatingBuiltInData() {
    UserDefaults.standard.set(AppLanguage.traditionalChinese.rawValue, forKey: "appLanguage")
    XCTAssertEqual(L10n.text(.home), "首頁")
    let stored = LedgerCategory(
      id: UUID(), kind: .expense, name: "Food", isBuiltIn: true, status: .active)
    XCTAssertEqual(L10n.categoryName(stored), "餐飲")
    XCTAssertEqual(stored.name, "Food")
    UserDefaults.standard.set(AppLanguage.english.rawValue, forKey: "appLanguage")
    XCTAssertEqual(L10n.text(.home), "Home")
  }
}
