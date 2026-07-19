import SwiftUI

struct PrivacyView: View {
  var body: some View {
    LedgerSheetScrollView(maxWidth: 660) {
      VStack(alignment: .leading, spacing: 20) {
        LedgerSheetHeader(
          title: L10n.text(.privacyTitle), detail: L10n.text(.privacyBodyOne),
          systemName: "lock.shield.fill", color: LedgerTheme.navy)
        PrivacyPromise(icon: "iphone.gen3", title: L10n.text(.privacyBodyOne), color: LedgerTheme.sage)
        PrivacyPromise(icon: "square.and.arrow.up", title: L10n.text(.privacyBodyTwo), color: LedgerTheme.olive)
        PrivacyPromise(icon: "checkmark.shield.fill", title: L10n.text(.privacyBodyThree), color: LedgerTheme.navy)
      }
    }
    .background { LedgerBackground(showsArtwork: true) }
    .overlay(alignment: .topLeading) { SurfaceMarker(identifier: "privacy.screen") }
  }
}

private struct PrivacyPromise: View {
  let icon: String
  let title: String
  let color: Color
  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      LedgerIcon(systemName: icon, color: color)
      Text(title).font(LedgerTypography.body).foregroundStyle(LedgerTheme.ink).lineSpacing(4)
    }.frame(maxWidth: .infinity, alignment: .leading).ledgerCard()
  }
}

struct ExportView: View {
  @EnvironmentObject private var model: LedgerViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var url: URL?
  @State private var error: String?

  var body: some View {
    LedgerSheetScrollView(maxWidth: 560, inset: 28) {
      VStack(spacing: 22) {
        LedgerIcon(systemName: url == nil ? "doc.badge.gearshape" : "checkmark.circle.fill", color: LedgerTheme.sage)
        Text(L10n.text(url == nil ? .preparingCSV : .csvReady)).font(LedgerTypography.screenTitle)
        Text(L10n.text(.csvDescription)).font(LedgerTypography.body).foregroundStyle(.secondary)
          .multilineTextAlignment(
            .center)
        if let url {
          ShareLink(item: url) { Label(L10n.text(.shareCSV), systemImage: "square.and.arrow.up") }
            .buttonStyle(PrimaryButton())
        } else if let error {
          NoticeCard(text: error, systemName: "exclamationmark.triangle.fill", color: .red)
          Button(L10n.text(.retry), action: create).buttonStyle(PrimaryButton()).accessibilityIdentifier(
            "export.retry")
        } else {
          ProgressView().tint(LedgerTheme.sage).controlSize(.large).onAppear(perform: create)
        }
        Button(L10n.text(.done)) { dismiss() }.font(LedgerTypography.action)
      }
    }
    .background { LedgerBackground(showsArtwork: true) }
    .overlay(alignment: .topLeading) { SurfaceMarker(identifier: "export.screen") }
  }

  private func create() {
    do {
      let file = FileManager.default.temporaryDirectory.appendingPathComponent(
        "ledgerly-export-\(ISO8601DateFormatter().string(from: Date()).prefix(10)).csv")
      guard let data = CSVExporter.makeCSV(model.ledger).data(using: .utf8) else { throw LedgerStoreError.retryable }
      try data.write(to: file, options: .atomic)
      url = file
    } catch {
      self.error = L10n.text(.csvFailed)
      UIAccessibility.post(notification: .announcement, argument: self.error)
    }
  }
}

struct ClearDataView: View {
  @EnvironmentObject private var model: LedgerViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var confirmation = ""
  @State private var final = false
  @State private var error: String?

  var body: some View {
    LedgerSheetScrollView {
      VStack(alignment: .leading, spacing: 20) {
        LedgerSheetHeader(
          title: L10n.text(final ? .finalConfirmation : .clearTitle),
          detail: L10n.text(final ? .clearFinalBody : .clearBody),
          systemName: final ? "exclamationmark.octagon.fill" : "trash.fill",
          color: .red)
        NoticeCard(
          text: L10n.text(.clearBody), systemName: "externaldrive.fill.badge.exclamationmark",
          color: LedgerTheme.terracotta)

        if final {
          VStack(alignment: .leading, spacing: 9) {
            Text(L10n.text(.typeDelete).uppercased()).font(LedgerTypography.captionStrong).foregroundStyle(.red)
            TextField(L10n.text(.typeDelete), text: $confirmation)
              .textInputAutocapitalization(.characters).autocorrectionDisabled()
              .font(LedgerTypography.bodyStrong).padding(16).background(LedgerTheme.paper)
              .clipShape(RoundedRectangle(cornerRadius: 16))
              .overlay {
                RoundedRectangle(cornerRadius: 16).stroke(confirmation == "DELETE" ? Color.red : LedgerTheme.hairline)
              }
              .accessibilityIdentifier("clear.confirmation")
          }
          if let error { NoticeCard(text: error, systemName: "exclamationmark.triangle.fill", color: .red) }
          Button(L10n.text(model.isSaving ? .clearing : .clearAllData), action: clear)
            .buttonStyle(DestructiveLedgerButton()).disabled(confirmation != "DELETE" || model.isSaving)
            .accessibilityIdentifier("clear.execute")
        } else {
          Button(L10n.text(.continueConfirmation)) { withAnimation { final = true } }
            .buttonStyle(DestructiveLedgerButton()).accessibilityIdentifier("clear.continue")
        }

        Button(L10n.text(.cancel)) { dismiss() }
          .font(LedgerTypography.action).frame(maxWidth: .infinity).padding(.vertical, 10)
      }
    }
    .background { LedgerBackground(showsArtwork: true) }
    .overlay(alignment: .topLeading) { SurfaceMarker(identifier: "clear.screen") }
  }

  private func clear() {
    if model.clearLedger() {
      dismiss()
    } else {
      error = model.notice.map { L10n.text($0) }
    }
  }
}

struct NoticeCard: View {
  let text: String
  let systemName: String
  let color: Color
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: systemName).font(LedgerTypography.icon).foregroundStyle(color)
      Text(text).font(LedgerTypography.footnote).foregroundStyle(LedgerTheme.ink).lineSpacing(3)
    }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
      .background(color.opacity(0.09)).clipShape(RoundedRectangle(cornerRadius: 16))
  }
}

struct SurfaceMarker: View {
  let identifier: String

  var body: some View {
    Color.clear
      .frame(width: 1, height: 1)
      .accessibilityElement()
      .accessibilityIdentifier(identifier)
  }
}

struct EmptyLedgerCard: View {
  let title: String
  let detail: String
  let systemName: String
  var body: some View {
    VStack(spacing: 12) {
      LedgerIcon(systemName: systemName, color: LedgerTheme.olive)
      Text(title).font(LedgerTypography.sectionTitle)
      Text(detail).font(LedgerTypography.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
    }.frame(maxWidth: .infinity).ledgerCard(padding: 24)
  }
}

struct DestructiveLedgerButton: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.font(LedgerTypography.action).frame(maxWidth: .infinity, minHeight: 52)
      .background(Color.red.opacity(configuration.isPressed ? 0.78 : 0.92)).foregroundStyle(.white)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .scaleEffect(configuration.isPressed ? 0.985 : 1)
  }
}

struct LedgerSheetScrollView<Content: View>: View {
  let maxWidth: CGFloat
  let inset: CGFloat
  @ViewBuilder let content: Content

  init(
    maxWidth: CGFloat = 620,
    inset: CGFloat = 22,
    @ViewBuilder content: () -> Content
  ) {
    self.maxWidth = maxWidth
    self.inset = inset
    self.content = content()
  }

  var body: some View {
    GeometryReader { viewport in
      let contentWidth = min(max(viewport.size.width - (inset * 2), 1), maxWidth)

      ScrollView {
        HStack(alignment: .top, spacing: 0) {
          Spacer(minLength: inset)
          content
            .environment(\.ledgerSheetContentWidth, contentWidth)
            .frame(width: contentWidth, alignment: .leading)
          Spacer(minLength: inset)
        }
        .frame(width: viewport.size.width)
        .padding(.vertical, inset)
      }
    }
  }
}

private struct LedgerSheetContentWidthKey: EnvironmentKey {
  static let defaultValue: CGFloat = 320
}

extension EnvironmentValues {
  var ledgerSheetContentWidth: CGFloat {
    get { self[LedgerSheetContentWidthKey.self] }
    set { self[LedgerSheetContentWidthKey.self] = newValue }
  }
}
