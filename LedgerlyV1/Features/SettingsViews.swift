import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var model: LedgerViewModel
    @AppStorage("appLanguage") private var language = AppLanguage.system.rawValue
    @State private var categories = false
    @State private var privacy = false
    @State private var exporting = false
    @State private var clearing = false
    @State private var currency = false

    var body: some View {
        NavigationStack {
            ZStack {
                LedgerBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        settingsGroup(title: L10n.text(.settings)) {
                            SettingsRow(
                                title: L10n.text(.categories),
                                detail: L10n.text(.archivedDescription),
                                systemName: "tag.fill",
                                color: LedgerTheme.terracotta
                            ) {
                                categories = true
                            }

                            Divider().padding(.leading, 50)

                            SettingsRow(
                                title: L10n.text(.currency),
                                detail: model.ledger.transactions.isEmpty
                                    ? L10n.text(.changeCurrencyHint)
                                    : L10n.text(.currencyLockedHint),
                                systemName: "dollarsign.circle.fill",
                                color: LedgerTheme.sage
                            ) {
                                currency = true
                            }
                            .accessibilityHint(
                                L10n.text(
                                    model.ledger.transactions.isEmpty
                                        ? .changeCurrencyHint
                                        : .currencyLockedHint
                                )
                            )

                            Divider().padding(.leading, 50)

                            HStack(spacing: 14) {
                                LedgerIcon(systemName: "globe", color: LedgerTheme.olive)
                                Text(L10n.text(.language))
                                    .font(.body.weight(.medium))
                                Spacer()
                                Picker(L10n.text(.language), selection: $language) {
                                    ForEach(AppLanguage.allCases) { option in
                                        Text(option.title).tag(option.rawValue)
                                    }
                                }
                                .labelsHidden()
                                .accessibilityIdentifier("settings.language")
                            }
                        }

                        settingsGroup(title: L10n.text(.dataPrivacy)) {
                            SettingsRow(
                                title: L10n.text(.exportCSV),
                                systemName: "square.and.arrow.up.fill",
                                color: LedgerTheme.sage
                            ) {
                                exporting = true
                            }

                            Divider().padding(.leading, 50)

                            SettingsRow(
                                title: L10n.text(.dataPrivacy),
                                systemName: "lock.shield.fill",
                                color: LedgerTheme.navy
                            ) {
                                privacy = true
                            }

                            Divider().padding(.leading, 50)

                            SettingsRow(
                                title: L10n.text(.clearAllData),
                                systemName: "trash.fill",
                                color: LedgerTheme.terracotta,
                                isDestructive: true
                            ) {
                                clearing = true
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Label(L10n.text(.aboutVersion), systemImage: "leaf.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(LedgerTheme.sage)
                            Text(L10n.text(.aboutDetail))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .ledgerCard()
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(L10n.text(.settings))
            .sheet(isPresented: $categories) { CategoriesView() }
            .sheet(isPresented: $privacy) { PrivacyView() }
            .sheet(isPresented: $exporting) { ExportView() }
            .sheet(isPresented: $clearing) { ClearDataView() }
            .sheet(isPresented: $currency) { CurrencyEditorView() }
        }
    }

    private func settingsGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(LedgerTheme.navy.opacity(0.62))

            VStack(spacing: 0, content: content)
                .ledgerCard(padding: 14)
        }
    }
}

private struct SettingsRow: View {
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
                        .font(.body.weight(.medium))
                        .foregroundStyle(isDestructive ? Color.red : LedgerTheme.ink)

                    if let detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }
}

struct CurrencyEditorView: View {
    @EnvironmentObject private var model: LedgerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currency = "USD"
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker(L10n.text(.currency), selection: $currency) {
                    Text(L10n.text(.usd)).tag("USD")
                    Text(L10n.text(.eur)).tag("EUR")
                    Text(L10n.text(.twd)).tag("TWD")
                }

                if !model.ledger.transactions.isEmpty {
                    Text(L10n.text(.currencyLocked))
                        .foregroundStyle(.secondary)
                }

                if let error {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(L10n.text(.currency))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text(.cancel)) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text(model.isSaving ? .saving : .save)) {
                        if model.changeCurrency(currency) {
                            dismiss()
                        } else {
                            error = model.notice.map { L10n.text($0) }
                        }
                    }
                    .disabled(model.isSaving || !model.ledger.transactions.isEmpty)
                }
            }
        }
        .onAppear {
            currency = model.ledger.currency ?? "USD"
        }
    }
}

struct CategoriesView: View {
    @EnvironmentObject private var model: LedgerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var archived = false
    @State private var adding = false
    @State private var candidate: LedgerCategory?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                Picker(L10n.text(.status), selection: $archived) {
                    Text(L10n.text(.active)).tag(false)
                    Text(L10n.text(.archived)).tag(true)
                }
                .pickerStyle(.segmented)

                let list = model.ledger.categories.filter { ($0.status == .archived) == archived }

                if list.isEmpty {
                    ContentUnavailableView(
                        L10n.text(archived ? .noArchivedCategories : .noActiveCategories),
                        systemImage: "tag",
                        description: Text(L10n.text(.archivedDescription))
                    )
                } else {
                    ForEach(list) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(L10n.categoryName(item))
                                Text(
                                    L10n.format(
                                        .categoryKindDetail,
                                        L10n.text(item.kind == .expense ? .expense : .income),
                                        L10n.text(item.isBuiltIn ? .builtIn : .custom)
                                    )
                                )
                                .font(.caption)
                            }

                            Spacer()

                            if !item.isBuiltIn {
                                Button(L10n.text(archived ? .restore : .archive)) {
                                    candidate = item
                                }
                                .disabled(model.isSaving)
                            }
                        }
                    }
                }

                if let error {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(L10n.text(.categories))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text(.add), systemImage: "plus") {
                        adding = true
                    }
                    .disabled(model.isSaving)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text(.done)) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $adding) {
                CategoryEditorView()
            }
            .alert(
                L10n.text(candidate?.status == .archived ? .restoreTitle : .archiveTitle),
                isPresented: Binding(
                    get: { candidate != nil },
                    set: { if !$0 { candidate = nil } }
                )
            ) {
                Button(L10n.text(.cancel), role: .cancel) {}
                Button(
                    L10n.text(candidate?.status == .archived ? .restore : .archive),
                    role: candidate?.status == .archived ? nil : .destructive,
                    action: changeStatus
                )
            } message: {
                Text(L10n.text(candidate?.status == .archived ? .restoreMessage : .archiveMessage))
            }
        }
    }

    private func changeStatus() {
        guard let candidate else { return }

        let saved = model.mutate(success: .categoryUpdated, failure: .categoryUpdateFailed) { staged in
            guard let index = staged.categories.firstIndex(where: { $0.id == candidate.id }) else { return }
            staged.categories[index].status = candidate.status == .active ? .archived : .active
        }

        if saved {
            self.candidate = nil
        } else {
            error = L10n.text(.categoryUpdateFailed)
        }
    }
}

struct CategoryEditorView: View {
    @EnvironmentObject private var model: LedgerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var kind: TransactionKind = .expense
    @State private var name = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker(L10n.text(.type), selection: $kind) {
                    Text(L10n.text(.expense)).tag(TransactionKind.expense)
                    Text(L10n.text(.income)).tag(TransactionKind.income)
                }
                .pickerStyle(.segmented)

                TextField(L10n.text(.name), text: $name)
                    .accessibilityHint(L10n.text(.nameHint))

                if let error {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(L10n.text(.newCategory))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text(.cancel)) {
                        dismiss()
                    }
                    .disabled(model.isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text(model.isSaving ? .saving : .add), action: add)
                        .disabled(model.isSaving)
                        .accessibilityIdentifier("category.add")
                }
            }
        }
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...40).contains(trimmed.count) else {
            error = L10n.validation(.categoryNameInvalid)
            return
        }

        let key = LedgerValidator.normalizedCategoryName(trimmed)
        guard !model.ledger.categories.contains(where: { $0.kind == kind && LedgerValidator.normalizedCategoryName($0.name) == key }) else {
            error = L10n.validation(.duplicateCategory)
            return
        }

        if model.mutate(success: .categoryAdded, failure: .categoryAddFailed, { staged in
            staged.categories.append(.init(id: UUID(), kind: kind, name: trimmed, isBuiltIn: false, status: .active))
        }) {
            dismiss()
        } else {
            error = L10n.text(.categoryAddFailed)
        }
    }
}

struct PrivacyView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text(L10n.text(.privacyTitle))
                    .editorialTitle()
                Text(L10n.text(.privacyBodyOne))
                Text(L10n.text(.privacyBodyTwo))
                Text(L10n.text(.privacyBodyThree))
                    .font(.footnote)
                Spacer()
            }
            .padding()
            .navigationTitle(L10n.text(.dataPrivacy))
        }
    }
}

struct ExportView: View {
    @EnvironmentObject private var model: LedgerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var url: URL?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(L10n.text(url == nil ? .preparingCSV : .csvReady))
                    .editorialTitle()
                Text(L10n.text(.csvDescription))

                if let url {
                    ShareLink(item: url) {
                        Text(L10n.text(.shareCSV))
                    }
                    .buttonStyle(PrimaryButton())
                } else if let error {
                    Text(error)
                        .foregroundStyle(.red)
                    Button(L10n.text(.retry), action: create)
                        .buttonStyle(PrimaryButton())
                        .accessibilityIdentifier("export.retry")
                } else {
                    ProgressView()
                        .onAppear(perform: create)
                }

                Button(L10n.text(.done)) {
                    dismiss()
                }
            }
            .padding()
        }
    }

    private func create() {
        do {
            let file = FileManager.default.temporaryDirectory.appendingPathComponent("ledgerly-export-\(ISO8601DateFormatter().string(from: Date()).prefix(10)).csv")
            guard let data = CSVExporter.makeCSV(model.ledger).data(using: .utf8) else {
                throw LedgerStoreError.retryable
            }
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
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text(L10n.text(final ? .finalConfirmation : .clearTitle))
                    .editorialTitle()
                Text(L10n.text(final ? .clearFinalBody : .clearBody))

                if final {
                    TextField(L10n.text(.typeDelete), text: $confirmation)
                        .textInputAutocapitalization(.characters)

                    Button(L10n.text(model.isSaving ? .clearing : .clearAllData), role: .destructive) {
                        if model.clearLedger() {
                            dismiss()
                        } else {
                            error = model.notice.map { L10n.text($0) }
                        }
                    }
                    .disabled(confirmation != "DELETE" || model.isSaving)

                    if let error {
                        Text(error)
                            .foregroundStyle(.red)

                        Button(L10n.text(.retryClear), role: .destructive) {
                            if model.clearLedger() {
                                dismiss()
                            } else {
                                self.error = model.notice.map { L10n.text($0) }
                            }
                        }
                        .accessibilityIdentifier("clear.retry")
                    }
                } else {
                    Button(L10n.text(.continueConfirmation)) {
                        final = true
                    }
                    .buttonStyle(PrimaryButton())
                }

                Button(L10n.text(.cancel)) {
                    dismiss()
                }

                Spacer()
            }
            .padding()
        }
    }
}
