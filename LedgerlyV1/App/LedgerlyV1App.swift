import SwiftUI
import UIKit

@main
struct LedgerlyV1App: App {
  @StateObject private var model = LedgerViewModel()
  @AppStorage("appLanguage") private var language = AppLanguage.system.rawValue
  var body: some Scene {
    WindowGroup {
      RootView().environmentObject(model).environment(
        \.locale, (AppLanguage(rawValue: language) ?? .system).locale)
    }
  }
}

@MainActor
final class LedgerViewModel: ObservableObject {
  enum Recovery: Equatable { case retryable, integrity, unsupportedFormat }
  enum State: Equatable {
    case loading, onboarding, ready
    case recovery(Recovery)
  }

  @Published var state: State = .loading
  @Published private(set) var ledger = LedgerData.empty
  @Published private(set) var isSaving = false
  @Published var notice: L10n.Key?
  @Published var selectedMonth = Calendar.current.dateComponents([.year, .month], from: Date())
  let store: LedgerStoring

  init(store: LedgerStoring = FileLedgerStore()) {
    self.store = store
    open()
  }

  func open() {
    do {
      ledger = try store.load()
      state = ledger.currency == nil ? .onboarding : .ready
    } catch let error as LedgerStoreError {
      state = .recovery(
        error == .retryable ? .retryable : error == .integrity ? .integrity : .unsupportedFormat)
    } catch { state = .recovery(.retryable) }
  }

  func retryOpen() { open() }

  /// The only ledger write boundary: stage, persist, then publish exactly once.
  @discardableResult
  func mutate(success: L10n.Key, failure: L10n.Key, _ change: (inout LedgerData) throws -> Void)
    -> Bool
  {
    guard !isSaving else { return false }
    isSaving = true
    defer { isSaving = false }
    do {
      var staged = ledger
      try change(&staged)
      try store.save(staged)
      ledger = staged
      notice = success
      UIAccessibility.post(notification: .announcement, argument: L10n.text(success))
      return true
    } catch {
      notice = failure
      UIAccessibility.post(notification: .announcement, argument: L10n.text(failure))
      return false
    }
  }

  @discardableResult
  func finishSetup(currency: String) -> Bool {
    mutate(success: .transactionSaved, failure: .transactionSaveFailed) { staged in
      staged.currency = currency
      staged.categories = Defaults.categories
    }.also { if $0 { self.state = .ready } }
  }

  @discardableResult
  func changeCurrency(_ currency: String) -> Bool {
    mutate(success: .transactionSaved, failure: .transactionSaveFailed) { staged in
      guard staged.transactions.isEmpty else { throw LedgerValidationError.currencyLocked }
      staged.currency = currency
    }
  }

  @discardableResult
  func clearLedger() -> Bool {
    guard !isSaving else { return false }
    isSaving = true
    defer { isSaving = false }
    do {
      try store.clear()
      ledger = .empty
      state = .onboarding
      notice = .cleared
      UIAccessibility.post(notification: .announcement, argument: L10n.text(.cleared))
      return true
    } catch {
      notice = .clearFailed
      UIAccessibility.post(notification: .announcement, argument: L10n.text(.clearFailed))
      return false
    }
  }

  func moveMonth(by offset: Int) {
    let date = Calendar.current.date(from: selectedMonth) ?? Date()
    let candidate = Calendar.current.date(byAdding: .month, value: offset, to: date) ?? date
    guard candidate <= (Calendar.current.date(from: currentMonth()) ?? Date()) else { return }
    selectedMonth = Calendar.current.dateComponents([.year, .month], from: candidate)
  }
}

extension Bool {
  fileprivate func also(_ action: (Bool) -> Void) -> Bool {
    action(self)
    return self
  }
}

enum Defaults {
  static var categories: [LedgerCategory] {
    [
      .init(id: UUID(), kind: .expense, name: "Food", isBuiltIn: true, status: .active),
      .init(id: UUID(), kind: .expense, name: "Transport", isBuiltIn: true, status: .active),
      .init(id: UUID(), kind: .expense, name: "Home", isBuiltIn: true, status: .active),
      .init(id: UUID(), kind: .income, name: "Salary", isBuiltIn: true, status: .active),
      .init(id: UUID(), kind: .income, name: "Freelance", isBuiltIn: true, status: .active),
    ]
  }
}
