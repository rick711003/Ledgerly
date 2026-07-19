import SwiftUI

func currentMonth() -> DateComponents {
  Calendar.current.dateComponents([.year, .month], from: Date())
}

func currencyFractionDigits(_ currency: String) -> Int {
  currency == "TWD" ? 0 : 2
}

func minorAmount(_ text: String, currency: String, locale: Locale = .current) -> Int64? {
  let formatter = NumberFormatter()
  formatter.locale = locale
  formatter.numberStyle = .decimal
  formatter.generatesDecimalNumbers = true

  guard
    let value = formatter.number(
      from: text.trimmingCharacters(in: .whitespacesAndNewlines)
    )?.decimalValue, value > 0
  else {
    return nil
  }

  let scale = Decimal(currencyFractionDigits(currency) == 0 ? 1 : 100)
  var minor = value * scale
  var rounded = Decimal()
  NSDecimalRound(&rounded, &minor, 0, .plain)

  return rounded == minor ? NSDecimalNumber(decimal: rounded).int64Value : nil
}

func amountText(_ minor: Int64, currency: String, locale: Locale = .current) -> String {
  let formatter = NumberFormatter()
  formatter.locale = locale
  formatter.numberStyle = .decimal
  formatter.maximumFractionDigits = currencyFractionDigits(currency)
  formatter.minimumFractionDigits = 0

  let scale = Decimal(currencyFractionDigits(currency) == 0 ? 1 : 100)
  return formatter.string(from: NSDecimalNumber(decimal: Decimal(minor) / scale)) ?? "0"
}

func money(
  _ minor: Int64,
  currency: String,
  signed: TransactionKind? = nil,
  locale: Locale = .current
) -> String {
  let formatter = NumberFormatter()
  formatter.locale = locale
  formatter.numberStyle = .currency
  formatter.currencyCode = currency
  formatter.minimumFractionDigits = currencyFractionDigits(currency)
  formatter.maximumFractionDigits = currencyFractionDigits(currency)

  let scale = Int64(pow(10.0, Double(currencyFractionDigits(currency))))
  let value = NSDecimalNumber(decimal: Decimal(minor) / Decimal(scale))
  let text = formatter.string(from: value) ?? "0"
  return signed == .expense ? "−" + text : text
}

func minorUnits(_ text: String, currency: String, locale: Locale = .current) -> Int64? {
  minorAmount(text, currency: currency, locale: locale)
}

struct MainShellView: View {
  @State private var addPresented = false

  var body: some View {
    TabView {
      HomeView(showAdd: $addPresented)
        .tabItem { Label(L10n.text(.home), systemImage: "house.fill") }

      HistoryView()
        .tabItem { Label(L10n.text(.history), systemImage: "list.bullet.rectangle") }

      InsightsView()
        .tabItem { Label(L10n.text(.insights), systemImage: "chart.bar.fill") }

      SettingsView()
        .tabItem { Label(L10n.text(.settings), systemImage: "slider.horizontal.3") }
    }
    .tint(LedgerTheme.terracotta)
    .toolbarBackground(LedgerTheme.paper, for: .tabBar)
    .toolbarBackground(.visible, for: .tabBar)
    .sheet(isPresented: $addPresented) {
      TransactionEditorView(existing: nil)
    }
  }
}

struct MonthNavigator: View {
  @EnvironmentObject private var model: LedgerViewModel
  @Environment(\.locale) private var locale

  var body: some View {
    HStack(spacing: 14) {
      monthButton(systemName: "chevron.left", label: .previousMonth) {
        model.moveMonth(by: -1)
      }

      Spacer()

      VStack(spacing: 2) {
        Text(label)
          .font(.subheadline.weight(.bold))
          .foregroundStyle(LedgerTheme.navy)
        Capsule()
          .fill(LedgerTheme.terracotta)
          .frame(width: 24, height: 2)
      }
      .accessibilityAddTraits(.isHeader)

      Spacer()

      monthButton(systemName: "chevron.right", label: .nextMonth) {
        model.moveMonth(by: 1)
      }
      .disabled(isCurrentMonth)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(LedgerTheme.paper.opacity(0.92))
    .clipShape(Capsule())
    .overlay { Capsule().stroke(LedgerTheme.hairline) }
    .accessibilityElement(children: .contain)
  }

  private var label: String {
    (Calendar.current.date(from: model.selectedMonth) ?? Date())
      .formatted(.dateTime.locale(locale).year().month(.wide))
  }

  private var isCurrentMonth: Bool {
    model.selectedMonth.year == currentMonth().year
      && model.selectedMonth.month == currentMonth().month
  }

  private func monthButton(
    systemName: String,
    label: L10n.Key,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .font(.caption.weight(.bold))
        .frame(width: 30, height: 30)
        .background(LedgerTheme.ivory)
        .clipShape(Circle())
    }
    .accessibilityLabel(L10n.text(label))
  }
}

struct HomeView: View {
  @EnvironmentObject private var model: LedgerViewModel
  @Environment(\.locale) private var locale
  @Binding var showAdd: Bool

  var body: some View {
    NavigationStack {
      ZStack {
        LedgerBackground()

        ScrollView {
          VStack(alignment: .leading, spacing: 22) {
            MonthNavigator()
            balanceHero
            metrics
            recentSection
          }
          .padding(.horizontal, 18)
          .padding(.bottom, 28)
        }
      }
      .navigationTitle(L10n.text(.appName))
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showAdd = true
          } label: {
            Image(systemName: "plus")
              .font(.headline)
              .foregroundStyle(.white)
              .frame(width: 36, height: 36)
              .background(LedgerTheme.terracotta)
              .clipShape(Circle())
          }
          .accessibilityLabel(L10n.text(.addTransaction))
        }
      }
    }
  }

  private var summary: MonthlySummary {
    model.ledger.summary(in: model.selectedMonth)
  }

  private var currency: String {
    model.ledger.currency ?? "USD"
  }

  private var balanceHero: some View {
    VStack(alignment: .leading, spacing: 22) {
      HStack {
        Label(L10n.text(.netLabel), systemImage: "wallet.bifold.fill")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.white.opacity(0.72))
        Spacer()
        Image(systemName: "leaf.fill")
          .foregroundStyle(LedgerTheme.terracotta)
      }

      Text(money(summary.net, currency: currency, locale: locale))
        .font(.system(size: 40, weight: .bold, design: .serif))
        .foregroundStyle(.white)
        .minimumScaleFactor(0.6)

      Text(
        L10n.format(
          .monthSummaryTitle,
          (Calendar.current.date(from: model.selectedMonth) ?? Date())
            .formatted(.dateTime.locale(locale).month(.wide))
        )
      )
      .font(.subheadline)
      .foregroundStyle(.white.opacity(0.72))
    }
    .padding(22)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      LinearGradient(
        colors: [LedgerTheme.navy, LedgerTheme.navy.opacity(0.86)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    .overlay(alignment: .bottomTrailing) {
      Circle()
        .fill(LedgerTheme.terracotta.opacity(0.18))
        .frame(width: 130, height: 130)
        .offset(x: 35, y: 55)
    }
    .shadow(color: LedgerTheme.navy.opacity(0.22), radius: 20, y: 10)
  }

  private var metrics: some View {
    HStack(spacing: 12) {
      metric(.incomeLabel, summary.income, LedgerTheme.sage, "arrow.down.left")
      metric(.expensesLabel, summary.expense, LedgerTheme.terracotta, "arrow.up.right")
    }
  }

  private var recentSection: some View {
    let recent = Array(model.ledger.transactions(in: model.selectedMonth).prefix(5))

    return VStack(alignment: .leading, spacing: 16) {
      LedgerSectionTitle(title: L10n.text(.recentActivity))

      if recent.isEmpty {
        VStack(spacing: 14) {
          LedgerIcon(systemName: "book.closed", color: LedgerTheme.olive)
          Text(L10n.text(.nothingRecorded))
            .font(.headline)
          Text(L10n.text(.nothingRecordedDescription))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
          Button(L10n.text(.addTransaction)) {
            showAdd = true
          }
          .buttonStyle(PrimaryButton())
        }
        .frame(maxWidth: .infinity)
        .ledgerCard()
      } else {
        VStack(spacing: 0) {
          ForEach(Array(recent.enumerated()), id: \.element.id) { index, transaction in
            TransactionRow(transaction: transaction)
            if index < recent.count - 1 {
              Divider().padding(.leading, 52)
            }
          }
        }
        .ledgerCard(padding: 14)
      }
    }
  }

  private func metric(
    _ label: L10n.Key,
    _ amount: Int64,
    _ color: Color,
    _ symbol: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      LedgerIcon(systemName: symbol, color: color)
      Text(L10n.text(label))
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(money(amount, currency: currency, locale: locale))
        .font(.headline)
        .foregroundStyle(LedgerTheme.ink)
        .minimumScaleFactor(0.65)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .ledgerCard(padding: 16)
  }
}

struct TransactionRow: View {
  let transaction: LedgerTransaction
  @Environment(\.locale) private var locale

  var body: some View {
    HStack(spacing: 14) {
      LedgerIcon(
        systemName: transaction.kind == .expense ? "arrow.up.right" : "arrow.down.left",
        color: transaction.kind == .expense ? LedgerTheme.terracotta : LedgerTheme.sage
      )

      VStack(alignment: .leading, spacing: 4) {
        Text(displayCategory)
          .font(.body.weight(.semibold))
          .foregroundStyle(LedgerTheme.ink)
        Text(transaction.note.isEmpty ? L10n.text(.noNote) : transaction.note)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer(minLength: 8)

      Text(
        money(
          transaction.amountMinor,
          currency: transaction.currency,
          signed: transaction.kind,
          locale: locale
        )
      )
      .font(.subheadline.weight(.bold))
      .foregroundStyle(transaction.kind == .expense ? LedgerTheme.terracotta : LedgerTheme.sage)
    }
    .padding(.vertical, 10)
    .accessibilityLabel(
      L10n.format(
        .transactionRowAccessibility,
        L10n.text(transaction.kind == .expense ? .expense : .income),
        displayCategory,
        money(
          transaction.amountMinor,
          currency: transaction.currency,
          signed: transaction.kind,
          locale: locale
        )
      )
    )
  }

  private var displayCategory: String {
    L10n.categoryName(transaction.categoryName)
  }
}
