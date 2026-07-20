import SwiftUI
import UIKit

struct SettingsView: View {
  @EnvironmentObject private var model: LedgerViewModel
  @AppStorage("appLanguage") private var language = AppLanguage.system.rawValue
  @State private var destination: SettingsDestination?

  var body: some View {
    NavigationStack {
      GeometryReader { viewport in
        let contentWidth = min(max(viewport.size.width - 36, 1), 720)

        ScrollView {
          HStack(alignment: .top, spacing: 0) {
            Spacer(minLength: 18)

            VStack(alignment: .leading, spacing: 24) {
              LedgerScreenHeader(
                title: L10n.text(.settings),
                detail: L10n.text(.aboutDetail),
                systemName: "slider.horizontal.3"
              )
              .frame(width: contentWidth, alignment: .leading)

              SettingsGroup(title: L10n.text(.settings), width: contentWidth) {
                SettingsRow(
                  title: L10n.text(.categories),
                  detail: L10n.text(.archivedDescription),
                  systemName: "tag.fill",
                  color: LedgerTheme.terracotta
                ) { destination = .categories }
                .accessibilityIdentifier("settings.categories")

                SettingsDivider()

                SettingsRow(
                  title: L10n.text(.currency),
                  detail: model.ledger.transactions.isEmpty
                    ? L10n.text(.changeCurrencyHint) : L10n.text(.currencyLockedHint),
                  systemName: "dollarsign.circle.fill",
                  color: LedgerTheme.sage
                ) { destination = .currency }
                .accessibilityIdentifier("settings.currency")

                SettingsDivider()

                SettingsRow(
                  title: L10n.text(.language),
                  detail: selectedLanguageTitle,
                  systemName: "globe.asia.australia.fill",
                  color: LedgerTheme.olive
                ) { destination = .language }
                .accessibilityIdentifier("settings.language")
              }

              SettingsGroup(title: L10n.text(.dataPrivacy), width: contentWidth) {
                SettingsRow(
                  title: L10n.text(.exportCSV),
                  detail: L10n.text(.csvDescription),
                  systemName: "square.and.arrow.up.fill",
                  color: LedgerTheme.sage
                ) { destination = .export }
                .accessibilityIdentifier("settings.export")

                SettingsDivider()

                SettingsRow(
                  title: L10n.text(.dataPrivacy),
                  detail: L10n.text(.privacySummary),
                  systemName: "lock.shield.fill",
                  color: LedgerTheme.navy
                ) { destination = .privacy }
                .accessibilityIdentifier("settings.privacy")

                SettingsDivider()

                SettingsRow(
                  title: L10n.text(.clearAllData),
                  detail: L10n.text(.clearSummary),
                  systemName: "trash.fill",
                  color: LedgerTheme.terracotta,
                  isDestructive: true
                ) { destination = .clear }
                .accessibilityIdentifier("settings.clear")
              }

              HStack(alignment: .top, spacing: 12) {
                LedgerIcon(systemName: "leaf.fill", color: LedgerTheme.sage)
                VStack(alignment: .leading, spacing: 5) {
                  Text(L10n.text(.aboutVersion)).font(LedgerTypography.label)
                  Text(L10n.text(.aboutDetail))
                    .font(LedgerTypography.footnote)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                }
              }
              .frame(width: max(contentWidth - 36, 1), alignment: .leading)
              .ledgerCard()
            }
            .frame(width: contentWidth, alignment: .leading)
            .padding(.top, 12)
            .padding(.bottom, 32)

            Spacer(minLength: 18)
          }
          .frame(width: viewport.size.width)
        }
      }
      .background { LedgerBackground(showsArtwork: true) }
      .toolbar(.hidden, for: .navigationBar)
      .sheet(item: $destination) { destination in
        switch destination {
        case .categories: CategoriesView()
        case .currency: CurrencyEditorView()
        case .language: LanguageSelectionView(language: $language)
        case .export: ExportView()
        case .privacy: PrivacyView()
        case .clear: ClearDataView()
        }
      }
    }
    .accessibilityIdentifier("settings.screen")
  }

  private var selectedLanguageTitle: String {
    AppLanguage(rawValue: language)?.title ?? L10n.text(.systemDefault)
  }
}

private enum SettingsDestination: String, Identifiable {
  case categories, currency, language, export, privacy, clear
  var id: String { rawValue }
}

private struct SettingsGroup<Content: View>: View {
  let title: String
  let width: CGFloat
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title.uppercased())
        .font(LedgerTypography.captionStrong)
        .tracking(1.2)
        .foregroundStyle(LedgerTheme.navy.opacity(0.62))
      VStack(spacing: 0) { content }
        .environment(\.settingsRowWidth, max(width - 28, 1))
        .frame(width: max(width - 28, 1), alignment: .leading)
        .ledgerCard(padding: 14)
    }
    .frame(width: width, alignment: .leading)
  }
}

private struct SettingsDivider: View {
  var body: some View { Divider().padding(.leading, 50) }
}

private struct SettingsRow: View {
  @Environment(\.settingsRowWidth) private var rowWidth
  let title: String
  var detail: String?
  let systemName: String
  let color: Color
  var isDestructive = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 14) {
        LedgerIcon(systemName: systemName, color: color)
        VStack(alignment: .leading, spacing: 3) {
          Text(title)
            .font(LedgerTypography.bodyStrong)
            .foregroundStyle(isDestructive ? Color.red : LedgerTheme.ink)
          if let detail {
            Text(detail)
              .font(LedgerTypography.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Spacer(minLength: 12)
        Image(systemName: "chevron.right")
          .font(LedgerTypography.captionStrong)
          .foregroundStyle(
            isDestructive ? Color.red.opacity(0.65) : LedgerTheme.navy.opacity(0.35)
          )
      }
      .frame(width: rowWidth, alignment: .leading)
      .contentShape(Rectangle())
      .padding(.vertical, 7)
    }
    .buttonStyle(.plain)
    .frame(width: rowWidth, alignment: .leading)
  }
}

private struct SettingsRowWidthKey: EnvironmentKey {
  static let defaultValue: CGFloat = 320
}

extension EnvironmentValues {
  fileprivate var settingsRowWidth: CGFloat {
    get { self[SettingsRowWidthKey.self] }
    set { self[SettingsRowWidthKey.self] = newValue }
  }
}

struct LedgerSheetHeader: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.ledgerSheetContentWidth) private var contentWidth
  let title: String
  let detail: String
  let systemName: String
  var color = LedgerTheme.sage

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      LedgerCloseButton { dismiss() }

      LedgerIcon(systemName: systemName, color: color)
      VStack(alignment: .leading, spacing: 4) {
        Text(title).font(LedgerTypography.screenTitle).foregroundStyle(LedgerTheme.navy)
        Text(detail)
          .font(LedgerTypography.footnote)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(
        width: max(contentWidth - 108, 1),
        alignment: .leading
      )
    }
    .frame(width: contentWidth, alignment: .leading)
  }
}

private struct LanguageSelectionView: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var language: String

  var body: some View {
    LedgerSheetScrollView {
      VStack(alignment: .leading, spacing: 22) {
        LedgerSheetHeader(
          title: L10n.text(.language), detail: L10n.text(.languageDetail),
          systemName: "globe.asia.australia.fill", color: LedgerTheme.olive)

        VStack(spacing: 10) {
          ForEach(AppLanguage.allCases) { option in
            Button {
              language = option.rawValue
              UIAccessibility.post(notification: .announcement, argument: option.title)
            } label: {
              HStack(spacing: 14) {
                LedgerIcon(systemName: languageIcon(option), color: LedgerTheme.olive)
                Text(option.title).font(LedgerTypography.bodyStrong).foregroundStyle(LedgerTheme.ink)
                Spacer()
                Image(systemName: language == option.rawValue ? "checkmark.circle.fill" : "circle")
                  .font(LedgerTypography.sectionTitle)
                  .foregroundStyle(language == option.rawValue ? LedgerTheme.sage : LedgerTheme.hairline)
              }
              .padding(16)
              .background(language == option.rawValue ? LedgerTheme.sage.opacity(0.10) : LedgerTheme.paper)
              .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
              .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                  .stroke(language == option.rawValue ? LedgerTheme.sage.opacity(0.45) : LedgerTheme.hairline)
              }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("language.\(option.rawValue)")
          }
        }

        Button(L10n.text(.done)) { dismiss() }.buttonStyle(PrimaryButton())
      }
    }
    .background { LedgerBackground(showsArtwork: true) }
    .overlay(alignment: .topLeading) { SurfaceMarker(identifier: "language.screen") }
  }

  private func languageIcon(_ option: AppLanguage) -> String {
    switch option {
    case .system: "iphone"
    case .english: "character.book.closed.fill"
    case .traditionalChinese: "textformat"
    }
  }
}

struct CurrencyEditorView: View {
  @EnvironmentObject private var model: LedgerViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var currency = "USD"
  @State private var error: String?

  private let options = [("USD", "$", L10n.Key.usd), ("EUR", "€", .eur), ("TWD", "NT$", .twd)]

  var body: some View {
    LedgerSheetScrollView {
      VStack(alignment: .leading, spacing: 22) {
        LedgerSheetHeader(
          title: L10n.text(.currency),
          detail: L10n.text(model.ledger.transactions.isEmpty ? .changeCurrencyHint : .currencyLockedHint),
          systemName: "dollarsign.circle.fill")

        if !model.ledger.transactions.isEmpty {
          NoticeCard(text: L10n.text(.currencyLocked), systemName: "lock.fill", color: LedgerTheme.terracotta)
        }

        VStack(spacing: 10) {
          ForEach(options, id: \.0) { option in
            Button {
              currency = option.0
            } label: {
              HStack(spacing: 14) {
                Text(option.1)
                  .font(LedgerTypography.monetarySymbol)
                  .lineLimit(1)
                  .minimumScaleFactor(0.8)
                  .frame(width: 44, height: 44)
                  .background(LedgerTheme.sage.opacity(0.12)).clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                  Text(L10n.text(option.2)).font(LedgerTypography.bodyStrong)
                  Text(option.0).font(LedgerTypography.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: currency == option.0 ? "checkmark.circle.fill" : "circle")
                  .font(LedgerTypography.sectionTitle)
                  .foregroundStyle(currency == option.0 ? LedgerTheme.sage : LedgerTheme.hairline)
              }
              .padding(16).background(LedgerTheme.paper)
              .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
              .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                  .stroke(currency == option.0 ? LedgerTheme.sage.opacity(0.5) : LedgerTheme.hairline)
              }
            }
            .buttonStyle(.plain)
            .disabled(!model.ledger.transactions.isEmpty)
            .accessibilityIdentifier("currency.\(option.0.lowercased())")
          }
        }

        if let error { NoticeCard(text: error, systemName: "exclamationmark.triangle.fill", color: .red) }

        Button(L10n.text(model.isSaving ? .saving : .save), action: save)
          .buttonStyle(PrimaryButton())
          .disabled(model.isSaving || !model.ledger.transactions.isEmpty)
          .accessibilityIdentifier("currency.save")
      }
    }
    .background { LedgerBackground(showsArtwork: true) }
    .onAppear { currency = model.ledger.currency ?? "USD" }
    .overlay(alignment: .topLeading) { SurfaceMarker(identifier: "currency.screen") }
  }

  private func save() {
    if model.changeCurrency(currency) {
      dismiss()
    } else {
      error = model.notice.map { L10n.text($0) }
    }
  }
}
