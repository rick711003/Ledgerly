import SwiftUI

struct CategoriesView: View {
  @EnvironmentObject private var model: LedgerViewModel
  @State private var archived = false
  @State private var adding = false
  @State private var candidate: LedgerCategory?
  @State private var error: String?

  private var categories: [LedgerCategory] {
    model.ledger.categories.filter { ($0.status == .archived) == archived }
  }

  var body: some View {
    LedgerSheetScrollView(maxWidth: 680) {
      VStack(alignment: .leading, spacing: 20) {
        LedgerSheetHeader(
          title: L10n.text(.categories), detail: L10n.text(.archivedDescription),
          systemName: "tag.fill", color: LedgerTheme.terracotta)

        LedgerSegmentedSelection(
          leading: L10n.text(.active), trailing: L10n.text(.archived), selection: $archived)

        if categories.isEmpty {
          EmptyLedgerCard(
            title: L10n.text(archived ? .noArchivedCategories : .noActiveCategories),
            detail: L10n.text(.archivedDescription), systemName: "tag")
        } else {
          LazyVStack(spacing: 10) {
            ForEach(categories) { category in
              CategoryCard(category: category, archived: archived) { candidate = category }
            }
          }
        }

        if let error { NoticeCard(text: error, systemName: "exclamationmark.triangle.fill", color: .red) }

        Button {
          adding = true
        } label: {
          Label(L10n.text(.add), systemImage: "plus")
        }
        .buttonStyle(PrimaryButton()).disabled(model.isSaving)
        .accessibilityIdentifier("category.new")
      }
    }
    .background { LedgerBackground(showsArtwork: true) }
    .sheet(isPresented: $adding) { CategoryEditorView() }
    .sheet(item: $candidate) { category in
      CategoryStatusConfirmation(category: category, onConfirm: { changeStatus(category) })
        .presentationDetents([.height(390)])
    }
    .overlay(alignment: .topLeading) { SurfaceMarker(identifier: "categories.screen") }
  }

  private func changeStatus(_ category: LedgerCategory) {
    let saved = model.mutate(success: .categoryUpdated, failure: .categoryUpdateFailed) { staged in
      guard let index = staged.categories.firstIndex(where: { $0.id == category.id }) else { return }
      staged.categories[index].status = category.status == .active ? .archived : .active
    }
    if saved { candidate = nil } else { error = L10n.text(.categoryUpdateFailed) }
  }
}

private struct LedgerSegmentedSelection: View {
  let leading: String
  let trailing: String
  @Binding var selection: Bool

  var body: some View {
    HStack(spacing: 6) {
      segment(leading, selected: !selection) { selection = false }
      segment(trailing, selected: selection) { selection = true }
    }
    .padding(5).background(LedgerTheme.navy.opacity(0.07))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

  private func segment(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title).font(LedgerTypography.label).frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(selected ? LedgerTheme.paper : .clear)
        .foregroundStyle(selected ? LedgerTheme.navy : .secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }.buttonStyle(.plain)
  }
}

private struct CategoryCard: View {
  let category: LedgerCategory
  let archived: Bool
  let action: () -> Void

  var body: some View {
    HStack(spacing: 14) {
      LedgerIcon(
        systemName: category.kind == .expense ? "arrow.up.right" : "arrow.down.left",
        color: category.kind == .expense ? LedgerTheme.terracotta : LedgerTheme.sage)
      VStack(alignment: .leading, spacing: 3) {
        Text(L10n.categoryName(category)).font(LedgerTypography.bodyStrong)
        Text(
          L10n.format(
            .categoryKindDetail,
            L10n.text(category.kind == .expense ? .expense : .income),
            L10n.text(category.isBuiltIn ? .builtIn : .custom))
        )
        .font(LedgerTypography.caption).foregroundStyle(.secondary)
      }
      Spacer()
      if !category.isBuiltIn {
        Button(L10n.text(archived ? .restore : .archive), action: action)
          .font(LedgerTypography.label)
          .foregroundStyle(archived ? LedgerTheme.sage : LedgerTheme.terracotta)
      } else {
        Image(systemName: "lock.fill").foregroundStyle(.tertiary)
          .accessibilityLabel(L10n.text(.builtIn))
      }
    }
    .padding(16).background(LedgerTheme.paper)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay { RoundedRectangle(cornerRadius: 18).stroke(LedgerTheme.hairline) }
  }
}

private struct CategoryStatusConfirmation: View {
  @Environment(\.dismiss) private var dismiss
  let category: LedgerCategory
  let onConfirm: () -> Void

  var body: some View {
    ZStack {
      LedgerBackground()
      VStack(spacing: 18) {
        LedgerIcon(
          systemName: category.status == .archived ? "arrow.uturn.backward" : "archivebox.fill",
          color: category.status == .archived ? LedgerTheme.sage : LedgerTheme.terracotta)
        Text(L10n.text(category.status == .archived ? .restoreTitle : .archiveTitle))
          .font(LedgerTypography.screenTitle).multilineTextAlignment(.center)
        Text(L10n.categoryName(category)).font(LedgerTypography.bodyStrong)
        Text(L10n.text(category.status == .archived ? .restoreMessage : .archiveMessage))
          .font(LedgerTypography.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
        Button(L10n.text(category.status == .archived ? .restore : .archive), action: onConfirm)
          .buttonStyle(PrimaryButton())
        Button(L10n.text(.cancel)) { dismiss() }.font(LedgerTypography.action)
      }.padding(24)
    }
    .accessibilityIdentifier("category.confirmation")
  }
}

struct CategoryEditorView: View {
  @EnvironmentObject private var model: LedgerViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var kind: TransactionKind = .expense
  @State private var name = ""
  @State private var error: String?

  var body: some View {
    LedgerSheetScrollView {
      VStack(alignment: .leading, spacing: 20) {
        LedgerSheetHeader(
          title: L10n.text(.newCategory), detail: L10n.text(.nameHint),
          systemName: "tag.circle.fill", color: LedgerTheme.terracotta)
        LedgerSegmentedKindSelection(selection: $kind)
        VStack(alignment: .leading, spacing: 8) {
          Text(L10n.text(.name).uppercased()).font(LedgerTypography.captionStrong)
          TextField(L10n.text(.name), text: $name)
            .font(LedgerTypography.body).padding(16).background(LedgerTheme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).stroke(LedgerTheme.hairline) }
            .accessibilityHint(L10n.text(.nameHint))
          Text(L10n.text(.nameHint)).font(LedgerTypography.footnote).foregroundStyle(.secondary)
        }
        if let error { NoticeCard(text: error, systemName: "exclamationmark.triangle.fill", color: .red) }
        Button(L10n.text(model.isSaving ? .saving : .add), action: add)
          .buttonStyle(PrimaryButton()).disabled(model.isSaving)
          .accessibilityIdentifier("category.add")
      }
    }
    .background { LedgerBackground(showsArtwork: true) }
    .overlay(alignment: .topLeading) {
      SurfaceMarker(identifier: "category.editor.screen")
    }
  }

  private func add() {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard (1...40).contains(trimmed.count) else {
      error = L10n.validation(.categoryNameInvalid)
      return
    }
    let key = LedgerValidator.normalizedCategoryName(trimmed)
    guard
      !model.ledger.categories.contains(where: {
        $0.kind == kind && LedgerValidator.normalizedCategoryName($0.name) == key
      })
    else {
      error = L10n.validation(.duplicateCategory)
      return
    }
    if model.mutate(
      success: .categoryAdded, failure: .categoryAddFailed,
      { staged in
        staged.categories.append(.init(id: UUID(), kind: kind, name: trimmed, isBuiltIn: false, status: .active))
      })
    {
      dismiss()
    } else {
      error = L10n.text(.categoryAddFailed)
    }
  }
}

private struct LedgerSegmentedKindSelection: View {
  @Binding var selection: TransactionKind
  var body: some View {
    HStack(spacing: 8) {
      kindButton(.expense, title: L10n.text(.expense), icon: "arrow.up.right", color: LedgerTheme.terracotta)
      kindButton(.income, title: L10n.text(.income), icon: "arrow.down.left", color: LedgerTheme.sage)
    }
  }
  private func kindButton(_ kind: TransactionKind, title: String, icon: String, color: Color) -> some View {
    Button {
      selection = kind
    } label: {
      Label(title, systemImage: icon).font(LedgerTypography.label).frame(maxWidth: .infinity).padding(14)
        .background(selection == kind ? color.opacity(0.13) : LedgerTheme.paper)
        .foregroundStyle(selection == kind ? color : LedgerTheme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
          RoundedRectangle(cornerRadius: 16).stroke(selection == kind ? color.opacity(0.45) : LedgerTheme.hairline)
        }
    }.buttonStyle(.plain)
  }
}
