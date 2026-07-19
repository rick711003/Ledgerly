import SwiftUI

func currentMonth() -> DateComponents { Calendar.current.dateComponents([.year, .month], from: Date()) }
func currencyFractionDigits(_ currency: String) -> Int { currency == "TWD" ? 0 : 2 }
func minorAmount(_ text: String, currency: String, locale: Locale = .current) -> Int64? {
    let formatter = NumberFormatter(); formatter.locale = locale; formatter.numberStyle = .decimal; formatter.generatesDecimalNumbers = true
    guard let value = formatter.number(from: text.trimmingCharacters(in: .whitespacesAndNewlines))?.decimalValue, value > 0 else { return nil }
    let scale = Decimal(currencyFractionDigits(currency) == 0 ? 1 : 100); var minor = value * scale; var rounded = Decimal()
    NSDecimalRound(&rounded, &minor, 0, .plain)
    return rounded == minor ? NSDecimalNumber(decimal: rounded).int64Value : nil
}
func amountText(_ minor: Int64, currency: String, locale: Locale = .current) -> String { let formatter = NumberFormatter(); formatter.locale = locale; formatter.numberStyle = .decimal; formatter.maximumFractionDigits = currencyFractionDigits(currency); formatter.minimumFractionDigits = 0; return formatter.string(from: NSDecimalNumber(decimal: Decimal(minor) / Decimal(currencyFractionDigits(currency) == 0 ? 1 : 100))) ?? "0" }
func money(_ minor: Int64, currency: String, signed: TransactionKind? = nil, locale: Locale = .current) -> String { let formatter = NumberFormatter(); formatter.locale = locale; formatter.numberStyle = .currency; formatter.currencyCode = currency; formatter.minimumFractionDigits = currencyFractionDigits(currency); formatter.maximumFractionDigits = currencyFractionDigits(currency); let scale = Int64(pow(10.0, Double(currencyFractionDigits(currency)))); let text = formatter.string(from: (Decimal(minor) / Decimal(scale)) as NSDecimalNumber) ?? "0"; return signed == .expense ? "−" + text : text }
func minorUnits(_ text: String, currency: String, locale: Locale = .current) -> Int64? { minorAmount(text, currency: currency, locale: locale) }

struct MainShellView: View {
    @State private var addPresented = false
    var body: some View { TabView { HomeView(showAdd: $addPresented).tabItem { Label(L10n.text(.home), systemImage: "house") }; HistoryView().tabItem { Label(L10n.text(.history), systemImage: "list.bullet") }; InsightsView().tabItem { Label(L10n.text(.insights), systemImage: "chart.bar") }; SettingsView().tabItem { Label(L10n.text(.settings), systemImage: "gearshape") } }.tint(LedgerTheme.terracotta).sheet(isPresented: $addPresented) { TransactionEditorView(existing: nil) } }
}

struct MonthNavigator: View {
    @EnvironmentObject private var model: LedgerViewModel
    @Environment(\.locale) private var locale
    var body: some View { ViewThatFits(in: .horizontal) { horizontal; vertical }.buttonStyle(.bordered).accessibilityElement(children: .contain) }
    private var label: String { (Calendar.current.date(from: model.selectedMonth) ?? Date()).formatted(.dateTime.locale(locale).year().month(.wide)) }
    private var horizontal: some View { HStack { Button(L10n.text(.previousMonth)) { model.moveMonth(by: -1) }.accessibilityLabel(L10n.text(.previousMonth)); Spacer(); Text(label).font(.headline).accessibilityAddTraits(.isHeader); Spacer(); nextButton } }
    private var vertical: some View { VStack(alignment: .leading, spacing: 8) { Text(label).font(.headline).accessibilityAddTraits(.isHeader); HStack { Button(L10n.text(.previousMonth)) { model.moveMonth(by: -1) }.accessibilityLabel(L10n.text(.previousMonth)); Spacer(); nextButton } } }
    private var nextButton: some View { Button(L10n.text(.nextMonth)) { model.moveMonth(by: 1) }.disabled(model.selectedMonth.year == currentMonth().year && model.selectedMonth.month == currentMonth().month).accessibilityLabel(L10n.text(.nextMonth)) }
}

struct HomeView: View {
    @EnvironmentObject private var model: LedgerViewModel; @Environment(\.locale) private var locale; @Binding var showAdd: Bool
    var body: some View { let summary = model.ledger.summary(in: model.selectedMonth); NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 18) { MonthNavigator(); Text(L10n.format(.monthSummaryTitle, (Calendar.current.date(from: model.selectedMonth) ?? Date()).formatted(.dateTime.locale(locale).month(.wide)))).editorialTitle(); Text(money(summary.net, currency: model.ledger.currency ?? "USD", locale: locale)).font(.system(size: 42, weight: .bold, design: .rounded)).minimumScaleFactor(0.6); ViewThatFits(in: .horizontal) { HStack { metric(.incomeLabel, summary.income, LedgerTheme.sage); metric(.expensesLabel, summary.expense, LedgerTheme.terracotta) }; VStack { metric(.incomeLabel, summary.income, LedgerTheme.sage); metric(.expensesLabel, summary.expense, LedgerTheme.terracotta) } }; Text(L10n.text(.recentActivity)).font(.title2.bold()); let recent = Array(model.ledger.transactions(in: model.selectedMonth).prefix(5)); if recent.isEmpty { ContentUnavailableView(L10n.text(.nothingRecorded), systemImage: "tray", description: Text(L10n.text(.nothingRecordedDescription))) } else { ForEach(recent) { TransactionRow(transaction: $0) } }; Button(L10n.text(.addTransaction)) { showAdd = true }.buttonStyle(PrimaryButton()) }.padding() }.navigationTitle(L10n.text(.appName)) } }
    private func metric(_ label: L10n.Key, _ amount: Int64, _ color: Color) -> some View { VStack(alignment: .leading) { Text(L10n.text(label)).font(.caption); Text(money(amount, currency: model.ledger.currency ?? "USD", locale: locale)).font(.headline).minimumScaleFactor(0.7) }.frame(maxWidth: .infinity, alignment: .leading).padding().background(color.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 14)) }
}

struct TransactionRow: View { let transaction: LedgerTransaction; @Environment(\.locale) private var locale
    var body: some View { HStack { VStack(alignment: .leading) { Text(displayCategory).font(.headline); Text(transaction.note.isEmpty ? L10n.text(.noNote) : transaction.note).font(.caption).foregroundStyle(.secondary) }; Spacer(); Text(money(transaction.amountMinor, currency: transaction.currency, signed: transaction.kind, locale: locale)).foregroundStyle(transaction.kind == .expense ? LedgerTheme.terracotta : LedgerTheme.sage) }.padding(.vertical, 8).accessibilityLabel(L10n.format(.transactionRowAccessibility, L10n.text(transaction.kind == .expense ? .expense : .income), displayCategory, money(transaction.amountMinor, currency: transaction.currency, signed: transaction.kind, locale: locale))) }
    private var displayCategory: String { L10n.categoryName(transaction.categoryName) }
}
