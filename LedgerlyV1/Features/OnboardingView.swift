import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject private var model: LedgerViewModel
  @State private var step = 0
  @State private var currency = "USD"
  @State private var error: String?

  private let symbols = ["book.closed.fill", "lock.shield.fill", "dollarsign.circle.fill"]

  var body: some View {
    ZStack {
      LedgerBackground(showsArtwork: true)

      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          brandHeader
          Spacer(minLength: 160)
          contentCard
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 30)
      }
    }
    .accessibilityElement(children: .contain)
  }

  private var brandHeader: some View {
    HStack(spacing: 10) {
      Image(systemName: "leaf.fill")
        .foregroundStyle(LedgerTheme.sage)
        .frame(width: 34, height: 34)
        .background(LedgerTheme.paper.opacity(0.86))
        .clipShape(Circle())

      Text(L10n.text(.appName))
        .font(.system(.headline, design: .serif, weight: .bold))
        .foregroundStyle(LedgerTheme.navy)

      Spacer()

      HStack(spacing: 6) {
        ForEach(0..<3, id: \.self) { index in
          Capsule()
            .fill(index <= step ? LedgerTheme.terracotta : LedgerTheme.navy.opacity(0.14))
            .frame(width: index == step ? 24 : 8, height: 8)
        }
      }
      .animation(.easeInOut, value: step)
    }
  }

  private var contentCard: some View {
    VStack(alignment: .leading, spacing: 18) {
      LedgerIcon(
        systemName: symbols[step], color: step == 1 ? LedgerTheme.sage : LedgerTheme.terracotta)

      Text(L10n.text(titleKey))
        .editorialTitle()

      Text(L10n.text(bodyKey))
        .font(.body)
        .foregroundStyle(LedgerTheme.ink.opacity(0.78))
        .lineSpacing(4)

      if step == 2 {
        currencyPicker
      }

      if model.isSaving {
        ProgressView(L10n.text(.savingSetup))
          .tint(LedgerTheme.terracotta)
      }

      if let error {
        Label(error, systemImage: "exclamationmark.circle.fill")
          .font(.footnote)
          .foregroundStyle(.red)

        Button(L10n.text(.retrySetup), action: create)
          .disabled(model.isSaving)
      }

      Button {
        step == 2 ? create() : advance()
      } label: {
        HStack {
          Text(L10n.text(step == 2 ? .createLedger : .continueAction))
          Spacer()
          Image(systemName: step == 2 ? "checkmark" : "arrow.right")
        }
        .padding(.horizontal, 18)
      }
      .buttonStyle(PrimaryButton())
      .disabled(model.isSaving)
      .accessibilityIdentifier("setup.continue")
    }
    .ledgerCard(padding: 22)
  }

  private var currencyPicker: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(L10n.text(.currency))
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)

      Picker(L10n.text(.currency), selection: $currency) {
        Text(L10n.text(.usd)).tag("USD")
        Text(L10n.text(.eur)).tag("EUR")
        Text(L10n.text(.twd)).tag("TWD")
      }
      .pickerStyle(.segmented)
    }
    .padding(14)
    .background(LedgerTheme.ivory.opacity(0.72))
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }

  private var titleKey: L10n.Key {
    step == 0 ? .onboardingTitleOne : step == 1 ? .onboardingTitleTwo : .onboardingTitleThree
  }

  private var bodyKey: L10n.Key {
    step == 0 ? .onboardingBodyOne : step == 1 ? .onboardingBodyTwo : .onboardingBodyThree
  }

  private func advance() {
    withAnimation(.easeInOut(duration: 0.3)) {
      step += 1
    }
  }

  private func create() {
    if !model.finishSetup(currency: currency) {
      error = L10n.text(.transactionSaveFailed)
    }
  }
}
