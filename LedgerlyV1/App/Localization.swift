import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
  case system, english, traditionalChinese
  var id: String { rawValue }
  var locale: Locale {
    switch self {
    case .system: .autoupdatingCurrent
    case .english: Locale(identifier: "en")
    case .traditionalChinese: Locale(identifier: "zh-Hant")
    }
  }
  var title: String {
    switch self {
    case .system: L10n.text(.systemDefault)
    case .english: L10n.text(.english)
    case .traditionalChinese: L10n.text(.traditionalChinese)
    }
  }
}

@MainActor
final class AppSettings: ObservableObject {
  @Published var language: String {
    willSet { UserDefaults.standard.set(newValue, forKey: "appLanguage") }
  }

  init(defaults: UserDefaults = .standard) {
    language = defaults.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue
  }
}

/// The only presentation-string API. Keep semantic keys here so views never own copy.
enum L10n {
  enum Key: String {
    case appName, ok, cancel, done, save, saving, add, continueAction, retry, retrySetup,
      retryDelete, retryClear, retryOpening
    case home, history, insights, settings, categories, currency, language, languageDetail,
      systemDefault, english,
      traditionalChinese
    case onboardingTitleOne, onboardingBodyOne, onboardingTitleTwo, onboardingBodyTwo,
      onboardingTitleThree, onboardingBodyThree, createLedger, savingSetup
    case usd, eur, twd, type, expense, income, amount, amountHint, category, chooseCategory, date,
      noteOptional, noNote
    case addTransaction, editTransaction, saveChanges, transactionSaved, transactionSaveFailed,
      transactionDeleted, transactionDeleteFailed
    case noTransactions, transactionsDescription, transaction, editTransactionAction,
      deleteTransaction, deleting, deleteTransactionTitle, deletePermanently,
      deleteTransactionMessage
    case previousMonth, nextMonth, monthlyOverview, monthSummaryTitle, recentActivity, incomeLabel, expensesLabel,
      netLabel, nothingRecorded, nothingRecordedDescription
    case monthlyTotals, expensesByCategory, noExpenseData, monthlyInsights, insightsAccessibility
    case dataPrivacy, privacySummary, exportCSV, clearAllData, clearSummary, about, aboutDetail, aboutVersion,
      changeCurrencyHint,
      currencyLockedHint
    case status, active, archived, noArchivedCategories, noActiveCategories, archivedDescription,
      builtIn, custom, restore, archive, archiveTitle, restoreTitle, archiveMessage, restoreMessage,
      categoryUpdated, categoryUpdateFailed
    case newCategory, name, nameHint, categoryAdded, categoryAddFailed
    case privacyTitle, privacyBodyOne, privacyBodyTwo, privacyBodyThree
    case preparingCSV, csvReady, csvDescription, shareCSV, csvFailed
    case clearTitle, finalConfirmation, clearBody, clearFinalBody, typeDelete, clearing,
      continueConfirmation, cleared, clearFailed
    case opening, recoveryRetryableTitle, recoveryIntegrityTitle, recoveryUnsupportedTitle,
      recoveryRetryableDetail, recoveryIntegrityDetail, recoveryUnsupportedDetail, recoveryGuidance
    case currencyRequired, invalidAmount, categoryUnavailable, futureDate, noteTooLong,
      categoryNameInvalid, duplicateCategory, currencyLocked
    case storageRetryable, storageIntegrity, storageUnsupported
    case categoryFood, categoryTransport, categoryHome, categorySalary, categoryFreelance,
      categoryKindDetail, transactionRowAccessibility
  }
  static func text(_ key: Key, _ arguments: CVarArg...) -> String {
    let format = value(for: key)
    return arguments.isEmpty
      ? format : String(format: format, locale: activeLanguage.locale, arguments: arguments)
  }
  static func format(_ key: Key, _ arguments: CVarArg...) -> String {
    String(format: value(for: key), locale: activeLanguage.locale, arguments: arguments)
  }
  private static var activeLanguage: AppLanguage {
    AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? "system")
      ?? .system
  }
  private static func value(for key: Key) -> String {
    let requested = activeLanguage.locale.identifier
    let bundle =
      Bundle.main.path(forResource: requested, ofType: "lproj").flatMap(Bundle.init(path:))
      ?? Bundle.main
    return bundle.localizedString(forKey: key.rawValue, value: key.rawValue, table: "Localizable")
  }
  static func validation(_ error: LedgerValidationError) -> String {
    switch error {
    case .currencyRequired: text(.currencyRequired)
    case .invalidAmount: text(.invalidAmount)
    case .categoryUnavailable: text(.categoryUnavailable)
    case .futureDate: text(.futureDate)
    case .noteTooLong: text(.noteTooLong)
    case .categoryNameInvalid: text(.categoryNameInvalid)
    case .duplicateCategory: text(.duplicateCategory)
    case .currencyLocked: text(.currencyLocked)
    }
  }
  static func categoryName(_ category: LedgerCategory) -> String {
    guard category.isBuiltIn else { return category.name }
    return categoryName(category.name)
  }
  /// Transaction snapshots retain category text, so known built-ins can still
  /// render in the selected language after a category is archived.
  static func categoryName(_ name: String) -> String {
    switch name {
    case "Food": text(.categoryFood)
    case "Transport": text(.categoryTransport)
    case "Home": text(.categoryHome)
    case "Salary": text(.categorySalary)
    case "Freelance": text(.categoryFreelance)
    default: name
    }
  }
}
