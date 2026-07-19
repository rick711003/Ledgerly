import Foundation
import SwiftUI

@MainActor final class LedgerModel: ObservableObject {
    enum Route { case loading, onboarding, ledger, recovery(LedgerError) }
    @Published var route: Route = .loading; @Published var month = MonthKey(); @Published var alert: String?
    let repository: LedgerRepository
    init(repository: LedgerRepository) { self.repository = repository; refresh() }
    func refresh() { do { _ = try repository.open(); route = .ledger } catch let error as LedgerError { route = error == .needsOnboarding ? .onboarding : .recovery(error) } catch { route = .recovery(.integrityFailure) } }
    func money(_ minor: Int64) -> String { let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = (try? repository.open().settings.currencyCode) ?? "USD"; return f.string(from: NSNumber(value: Double(minor) / 100)) ?? "$0.00" }
}
