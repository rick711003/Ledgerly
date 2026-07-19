import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var categories = false
    @State private var privacy = false
    @State private var exportURL: URL?
    @State private var clearWarning = false
    @State private var finalConfirmation = false
    @State private var confirmation = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Ledger") {
                    Button("Categories") { categories = true }
                    Text("Currency: \(model.ledger!.currencyCode)")
                    if !model.ledger!.entries.isEmpty { Text("Currency is locked because this ledger has transactions.").font(.footnote) }
                }
                Section("Data & privacy") {
                    Button("Export CSV") { prepareCSV() }
                    Button("Data & privacy") { privacy = true }
                    Button("Clear all data", role: .destructive) { clearWarning = true }
                }
                Section("About") { Text("Ledgerly 1.0"); Text("Support destination pending release approval"); Text("Privacy policy destination pending release approval") }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $categories) { CategoriesView(model: model) }
            .sheet(isPresented: $privacy) { PrivacyView() }
            .sheet(isPresented: Binding(get: { exportURL != nil }, set: { if !$0 { exportURL = nil } })) { if let exportURL { ShareSheet(url: exportURL) } }
            .alert("Clear all data?", isPresented: $clearWarning) {
                Button("Cancel", role: .cancel) {}
                Button("Continue to confirmation", role: .destructive) { finalConfirmation = true }
            } message: { Text("This permanently removes all Ledgerly v1 transactions, categories, and settings from this device’s app storage. Export a CSV first if you want a copy. This does not touch the discarded prototype data.") }
            .alert("Final confirmation", isPresented: $finalConfirmation) {
                TextField("Type DELETE", text: $confirmation)
                Button("Cancel", role: .cancel) { confirmation = "" }
                Button("Clear all data", role: .destructive) { if confirmation == "DELETE" { Task { try? await model.clear() } } }
            } message: { Text("Type DELETE to permanently clear this Ledgerly v1 ledger. You’ll return to setup.") }
        }.background(LedgerTheme.paper)
    }
    private func prepareCSV() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ledgerly-export.csv")
        do { try CSVExporter.data(from: model.ledger!).write(to: url, options: .atomic); exportURL = url } catch { }
    }
}

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View { NavigationStack { VStack(alignment: .leading, spacing: 18) { Text("Data & privacy").editorialTitle(); Text("Ledgerly works offline, has no account, and does not collect transaction data off-device."); Notice(text: "Exports are intentional. When you share a CSV, the destination you select controls that copy."); Text("Backup policy will be stated here exactly as approved for release.").font(.footnote); Spacer() }.padding().toolbar { Button("Done") { dismiss() } } } }
}

struct CategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: AppModel
    @State private var archived = false
    @State private var adding = false
    @State private var selected: Category?
    var body: some View {
        NavigationStack { List {
            Picker("Status", selection: $archived) { Text("Active").tag(false); Text("Archived").tag(true) }.pickerStyle(.segmented)
            let list = model.ledger!.categories.filter { $0.isArchived == archived }
            if list.isEmpty { ContentUnavailableView(archived ? "No archived categories" : "No active categories", systemImage: "square.grid.2x2", description: Text("Add a category before recording a transaction of this type.")) }
            else { ForEach(list) { category in Button { selected = category } label: { HStack { Text(category.name); Spacer(); Text("\(category.type.rawValue)\(category.isBuiltIn ? " · Built-in" : "")").font(.caption).foregroundStyle(.secondary) } } } }
        }.navigationTitle("Categories").toolbar { Button("Add") { adding = true } }.sheet(isPresented: $adding) { CategoryEditor(model: model) }.alert(item: $selected) { category in
            Alert(title: Text(archived ? "Restore \(category.name)?" : "Archive \(category.name)?"), message: Text(archived ? "It will be available for new entries." : "Existing transactions and totals stay unchanged."), primaryButton: .destructive(Text(archived ? "Restore" : "Archive")) { Task { try? await model.repository.setArchived(id: category.id, archived: !archived); await model.refresh() } }, secondaryButton: .cancel())
        } }.background(LedgerTheme.paper)
    }
}

struct CategoryEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: AppModel
    @State private var name = ""
    @State private var type: EntryType = .expense
    @State private var error: String?
    var body: some View { NavigationStack { Form { Picker("Type", selection: $type) { Text("Expense").tag(EntryType.expense); Text("Income").tag(EntryType.income) }.pickerStyle(.segmented); TextField("Name", text: $name).accessibilityHint("Up to 40 characters. Names must be unique within a type."); if let error { Notice(text: error, error: true) } }.navigationTitle("New category").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Add category") { Task { do { try await model.repository.addCategory(name: name, type: type); await model.refresh(); dismiss() } catch { self.error = error.localizedDescription } } } } } } }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [url], applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
