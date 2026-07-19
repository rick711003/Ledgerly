import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: LedgerModel
    var body: some View { Group { switch model.route { case .loading: ProgressView("Opening Ledgerly").accessibilityLabel("Loading ledger"); case .onboarding: OnboardingView(); case .ledger: LedgerTabView(); case .recovery(let error): RecoveryView(error: error) } }.tint(.ledgerNavy).background(Color.ledgerPaper.ignoresSafeArea()) }
}

struct RecoveryView: View { let error: LedgerError
    var body: some View { VStack(spacing: 18) { Spacer(); Text(error == .unsupportedFormat ? "A newer Ledgerly version is needed" : "Your ledger needs help").editorialTitle().multilineTextAlignment(.center); Text(error.errorDescription ?? "").multilineTextAlignment(.center); Text("Writes are disabled to protect your records.").font(.callout).padding().background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12)); Button("Contact support") {}.buttonStyle(PrimaryLedgerButton()); Spacer() }.padding().accessibilityElement(children: .contain) }
}

struct OnboardingView: View { @EnvironmentObject private var model: LedgerModel; @State private var page = 0; @State private var currency = "USD"; @State private var error: String?
    var body: some View { VStack(alignment: .leading, spacing: 22) { Spacer(); if page == 0 { Text("LEDGERLY").font(.caption.weight(.bold)); Text("A quieter way to know your month.").editorialTitle(); Text("Record what matters. See a clear monthly picture."); Button("Get started") { page = 1 }.buttonStyle(PrimaryLedgerButton()) } else if page == 1 { Text("Private by default").editorialTitle(); Text("Ledgerly works offline and has no account. Your entries are stored in the app’s private storage."); Text("Export is your choice: a shared file is controlled by the destination you choose.").font(.callout).padding().background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12)); Button("Continue") { page = 2 }.buttonStyle(PrimaryLedgerButton()) } else { Text("Choose your currency").editorialTitle(); Text("Suggested for your region. You can change this until you add your first transaction."); Picker("Currency", selection: $currency) { Text("US Dollar (USD)").tag("USD"); Text("Euro (EUR)").tag("EUR"); Text("New Taiwan Dollar (TWD)").tag("TWD"); Text("British Pound (GBP)").tag("GBP") }.pickerStyle(.navigationLink); if let error { Text(error).foregroundStyle(.red).accessibilityLiveRegion(.assertive) }; Button("Use \(currency)") { do { try model.repository.completeOnboarding(currencyCode: currency); model.refresh() } catch { self.error = error.localizedDescription } }.buttonStyle(PrimaryLedgerButton()) }; Spacer() }.padding() }
}
