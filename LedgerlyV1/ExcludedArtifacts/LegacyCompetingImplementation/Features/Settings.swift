import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var model: LedgerViewModel
    var body: some View {
        NavigationStack { List {
            Section("LEDGER") { NavigationLink("Categories") { CategoriesView(model: model) }; NavigationLink("Currency") { CurrencyView(model: model) } }
            Section("DATA & PRIVACY") { NavigationLink("Export CSV") { ExportView(model: model) }; NavigationLink("Data & privacy") { PrivacyView(model: model) } }
            Section("ABOUT") { LabeledContent("Ledgerly", value: "1.0") }
        }.navigationTitle("Settings") }
    }
}
struct CurrencyView: View {
    @ObservedObject var model: LedgerViewModel; @State private var currency = "USD"
    var body: some View { guard let ledger = model.ledger else { return AnyView(EmptyView()) }; return AnyView(Form {
        if ledger.transactions.isEmpty { Picker("Currency", selection: $currency) { Text("US Dollar (USD)").tag("USD"); Text("Euro (EUR)").tag("EUR"); Text("New Taiwan Dollar (TWD)").tag("TWD") }; Button("Save currency") { var next = ledger; next.currencyCode = currency; model.mutate(next) }.buttonStyle(PrimaryButton())
        } else { Text("Currency is locked").editorialTitle(); Text("Your ledger uses \(ledger.currencyCode) because it already has transactions. Changing it would make historical totals unclear.") }
    }.navigationTitle("Currency").onAppear { currency = ledger.currencyCode }) }
}
struct CategoriesView: View {
    @ObservedObject var model: LedgerViewModel; @State private var archived = false; @State private var adding = false; @State private var target: LedgerCategory?
    var body: some View { guard let ledger = model.ledger else { return AnyView(EmptyView()) }; let categories = ledger.categories.filter { $0.isArchived == archived }; return AnyView(List {
        Picker("Status", selection: $archived) { Text("Active").tag(false); Text("Archived").tag(true) }.pickerStyle(.segmented)
        if categories.isEmpty { ContentUnavailableView(archived ? "No archived categories" : "No active categories", systemImage: "square.stack", description: Text(archived ? "Archived categories can be restored here." : "Add a category before recording this type.")) }
        ForEach(categories) { category in HStack { VStack(alignment: .leading) { Text(category.name); Text("\(category.kind.rawValue.capitalized) · \(category.isBuiltIn ? "Built-in" : "Custom")").font(.caption) }; Spacer(); if category.isArchived { Button("Restore") { model.archive(category, archived: false) } } else if !category.isBuiltIn { Button("Archive") { target = category }.foregroundStyle(LedgerlyStyle.danger) } } }
    }.navigationTitle("Categories").toolbar { Button { adding = true } label: { Label("Add category", systemImage: "plus") } }.sheet(isPresented: $adding) { CategoryForm(model: model) }.alert("Archive \(target?.name ?? "category")?", isPresented: Binding(get: { target != nil }, set: { if !$0 { target = nil } })) { Button("Cancel", role: .cancel) {}; Button("Archive category", role: .destructive) { if let target { model.archive(target, archived: true) } } } message: { Text("It won’t be available for new transactions. Existing transactions and totals stay unchanged.") }) }
}
struct CategoryForm: View {
    @Environment(\.dismiss) private var dismiss; @ObservedObject var model: LedgerViewModel; @State private var name = ""; @State private var kind: TransactionKind = .expense; @State private var error: String?
    var body: some View { NavigationStack { Form { Picker("Type", selection: $kind) { Text("Expense").tag(TransactionKind.expense); Text("Income").tag(TransactionKind.income) }.pickerStyle(.segmented); TextField("e.g. Coffee", text: $name); Text("Up to 40 characters. Names are unique within a type.").font(.footnote); if let error { Text(error).foregroundStyle(LedgerlyStyle.danger) } }.navigationTitle("New category").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Add category") { error = model.addCategory(name: name, kind: kind); if error == nil { dismiss() } } } } } }
}
struct ExportView: View {
    @ObservedObject var model: LedgerViewModel; @State private var url: URL?; @State private var sharing = false; @State private var error: String?
    var body: some View { VStack(alignment: .leading, spacing: 18) { Text("Export CSV").editorialTitle(); Text("Create a UTF-8 file containing your transaction fields only. Sharing is your choice."); if let url { Text(url.lastPathComponent).ledgerCard(); Button("Share CSV") { sharing = true }.buttonStyle(PrimaryButton()).sheet(isPresented: $sharing) { ShareSheet(items: [url]) } } else { Button("Prepare CSV", action: prepare).buttonStyle(PrimaryButton()) }; if let error { Text(error).foregroundStyle(LedgerlyStyle.danger) }; Spacer() }.padding().background(LedgerlyStyle.paper).navigationTitle("Export CSV") }
    private func prepare() { guard let ledger = model.ledger else { return }; do { let file = FileManager.default.temporaryDirectory.appendingPathComponent("ledgerly-export.csv"); try CSVExporter.make(ledger: ledger).data(using: .utf8)!.write(to: file, options: .atomic); url = file } catch { self.error = "CSV wasn’t created. Your ledger is unchanged. Try again when storage is available." } }
}
struct ShareSheet: UIViewControllerRepresentable { let items: [Any]; func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }; func updateUIViewController(_ controller: UIActivityViewController, context: Context) {} }
struct PrivacyView: View {
    @ObservedObject var model: LedgerViewModel; @State private var warning = false; @State private var final = false; @State private var phrase = ""
    var body: some View { VStack(alignment: .leading, spacing: 18) { Text("Data & privacy").editorialTitle(); Text("Ledgerly works offline, has no account, and does not collect transaction data off-device."); Text("Exports are intentional: when you share a CSV, the destination you select controls that copy.").ledgerCard(); Button("Clear all data", role: .destructive) { warning = true }; Spacer() }.padding().background(LedgerlyStyle.paper).navigationTitle("Data & privacy").alert("Clear all data?", isPresented: $warning) { Button("Cancel", role: .cancel) {}; Button("Continue to confirmation", role: .destructive) { final = true } } message: { Text("This permanently removes all Ledgerly v1 transactions, categories, and settings from this device’s app storage. Export a CSV first if you want a copy.") }.sheet(isPresented: $final) { VStack(spacing: 18) { Text("Final confirmation").editorialTitle(); Text("Type DELETE to permanently clear this Ledgerly v1 ledger. You’ll return to setup."); TextField("TYPE DELETE", text: $phrase).textFieldStyle(.roundedBorder); Button("Cancel") { final = false }; Button("Clear all data", role: .destructive) { if phrase == "DELETE" { model.clear(); final = false } }.disabled(phrase != "DELETE") }.padding() } }
}
