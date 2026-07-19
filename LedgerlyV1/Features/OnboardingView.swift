import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: LedgerViewModel
    @State private var step = 0; @State private var currency = "USD"; @State private var error: String?
    var body: some View { VStack(alignment: .leading, spacing: 24) {
        Spacer()
        Text(L10n.text(step == 0 ? .onboardingTitleOne : step == 1 ? .onboardingTitleTwo : .onboardingTitleThree)).editorialTitle()
        Text(L10n.text(step == 0 ? .onboardingBodyOne : step == 1 ? .onboardingBodyTwo : .onboardingBodyThree))
        if step == 2 { Picker(L10n.text(.currency), selection: $currency) { Text(L10n.text(.usd)).tag("USD"); Text(L10n.text(.eur)).tag("EUR"); Text(L10n.text(.twd)).tag("TWD") }.pickerStyle(.navigationLink) }
        Spacer()
        if step == 2, model.isSaving { ProgressView(L10n.text(.savingSetup)) }
        if let error { Text(error).foregroundStyle(.red); Button(L10n.text(.retrySetup), action: create).disabled(model.isSaving) }
        Button(L10n.text(step == 2 ? .createLedger : .continueAction)) { if step == 2 { create() } else { step += 1 } }
            .buttonStyle(PrimaryButton()).disabled(model.isSaving).accessibilityIdentifier("setup.continue")
    }.padding(28).accessibilityElement(children: .contain) }
    private func create() { if !model.finishSetup(currency: currency) { error = L10n.text(.transactionSaveFailed) } }
}
