import SwiftUI

struct InsightsView: View {
  @EnvironmentObject private var model: LedgerViewModel
  @Environment(\.locale) private var locale

  var body: some View {
    NavigationStack {
      ZStack {
        LedgerBackground()

        ScrollView {
          VStack(alignment: .leading, spacing: 22) {
            MonthNavigator()
            overviewCard
            categoryBreakdown
          }
          .padding(.horizontal, 18)
          .padding(.bottom, 28)
        }
      }
      .navigationTitle(L10n.text(.monthlyInsights))
      .accessibilityLabel(L10n.text(.insightsAccessibility))
    }
  }

  private var transactions: [LedgerTransaction] {
    model.ledger.transactions(in: model.selectedMonth)
  }

  private var summary: MonthlySummary {
    model.ledger.summary(in: model.selectedMonth)
  }

  private var currency: String {
    model.ledger.currency ?? "USD"
  }

  private var expenseGroups: [(name: String, value: Int64)] {
    Dictionary(
      grouping: transactions.filter { $0.kind == .expense },
      by: \.categoryName
    )
    .map { name, values in
      (name, values.reduce(Int64(0)) { $0 + $1.amountMinor })
    }
    .sorted { $0.value > $1.value }
  }

  private var overviewCard: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        LedgerSectionTitle(title: L10n.text(.monthlyTotals))
        Spacer()
        LedgerIcon(systemName: "chart.pie.fill", color: LedgerTheme.sage)
      }

      HStack(alignment: .bottom, spacing: 5) {
        RoundedRectangle(cornerRadius: 5)
          .fill(LedgerTheme.sage.opacity(0.32))
          .frame(height: barHeight(summary.income))
        RoundedRectangle(cornerRadius: 5)
          .fill(LedgerTheme.terracotta.opacity(0.82))
          .frame(height: barHeight(summary.expense))
        RoundedRectangle(cornerRadius: 5)
          .fill(LedgerTheme.navy.opacity(0.72))
          .frame(height: barHeight(abs(summary.net)))
      }
      .frame(height: 92, alignment: .bottom)
      .accessibilityHidden(true)

      Divider()

      metricRow(.incomeLabel, value: summary.income, color: LedgerTheme.sage)
      metricRow(.expensesLabel, value: summary.expense, color: LedgerTheme.terracotta)
      metricRow(.netLabel, value: summary.net, color: LedgerTheme.navy)
    }
    .ledgerCard()
  }

  private var categoryBreakdown: some View {
    VStack(alignment: .leading, spacing: 16) {
      LedgerSectionTitle(title: L10n.text(.expensesByCategory))

      if expenseGroups.isEmpty {
        VStack(spacing: 12) {
          LedgerIcon(systemName: "chart.bar.xaxis", color: LedgerTheme.olive)
          Text(L10n.text(.noExpenseData))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .ledgerCard()
      } else {
        VStack(spacing: 18) {
          ForEach(Array(expenseGroups.enumerated()), id: \.element.name) { index, group in
            categoryRow(group, index: index)
          }
        }
        .ledgerCard()
      }
    }
  }

  private func metricRow(_ key: L10n.Key, value: Int64, color: Color) -> some View {
    HStack {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
      Text(L10n.text(key))
        .foregroundStyle(.secondary)
      Spacer()
      Text(money(value, currency: currency, locale: locale))
        .font(.body.weight(.semibold))
        .foregroundStyle(LedgerTheme.ink)
    }
  }

  private func categoryRow(
    _ group: (name: String, value: Int64),
    index: Int
  ) -> some View {
    let colors = [LedgerTheme.terracotta, LedgerTheme.sage, LedgerTheme.olive, LedgerTheme.navy]
    let color = colors[index % colors.count]
    let maximum = max(expenseGroups.first?.value ?? 1, 1)

    return VStack(alignment: .leading, spacing: 9) {
      HStack {
        Text(L10n.categoryName(group.name))
          .font(.subheadline.weight(.semibold))
        Spacer()
        Text(money(group.value, currency: currency, locale: locale))
          .font(.subheadline.weight(.bold))
      }

      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule().fill(color.opacity(0.12))
          Capsule()
            .fill(color)
            .frame(width: proxy.size.width * CGFloat(group.value) / CGFloat(maximum))
        }
      }
      .frame(height: 8)
    }
  }

  private func barHeight(_ value: Int64) -> CGFloat {
    let maximum = [summary.income, summary.expense, abs(summary.net), 1].max() ?? 1
    return max(18, 92 * CGFloat(value) / CGFloat(maximum))
  }
}
