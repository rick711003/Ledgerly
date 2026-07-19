import SwiftUI

@main struct LedgerlyV1App: App { var body: some Scene { WindowGroup { LedgerlyRootView(repository: LedgerRepository(store: JSONLedgerStore())) } } }

@MainActor final class AppModel: ObservableObject {
    @Published var ledger: Ledger?
    @Published var recovery: LedgerError?
    @Published var isLoading = true
    let repository: LedgerRepository
    init(repository: LedgerRepository) { self.repository = repository }
    func open() async { isLoading = true; defer { isLoading = false }; do { ledger = try await repository.open() } catch let error as LedgerError { recovery = error } catch { recovery = .retryableStorage } }
    func setup(currency: String) async throws { ledger = try await repository.setup(currencyCode: currency) }
    func refresh() async { await open() }
    func currency(_ code: String) async throws { try await repository.updateCurrency(code); ledger = try await repository.open() }
    func clear() async throws { try await repository.clear(); ledger = nil }
}

struct LedgerlyRootView: View {
    @StateObject private var model: AppModel
    init(repository: LedgerRepository) { _model = StateObject(wrappedValue: AppModel(repository: repository)) }
    var body: some View {
        Group {
            if model.isLoading { ProgressView("Opening Ledgerly").accessibilityLabel("Loading ledger") }
            else if let error = model.recovery { RecoveryView(error: error, retry: { Task { await model.open() } }) }
            else if model.ledger == nil { OnboardingView(model: model) }
            else { MainTabs(model: model) }
        }.task { await model.open() }.tint(LedgerTheme.navy).background(LedgerTheme.paper).preferredColorScheme(nil)
    }
}

struct RecoveryView: View { let error: LedgerError; let retry: () -> Void; var body: some View { VStack(spacing: 20) { Text(error == .newerStore ? "A newer Ledgerly version is needed" : "Your ledger needs help").editorialTitle(); Text(error.localizedDescription).multilineTextAlignment(.center); Notice(text: "Writes are disabled to protect your records.", error: true); if error == .retryableStorage { Button("Retry", action: retry).buttonStyle(PrimaryButton()) }; Button("View recovery guidance") {}.frame(minHeight: 44) }.padding().accessibilityElement(children: .contain) } }
