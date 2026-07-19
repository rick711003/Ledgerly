import SwiftUI

struct TransactionEditorView: View {
  @EnvironmentObject private var model: LedgerViewModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.locale) private var locale

  let existing: LedgerTransaction?

  @State private var kind: TransactionKind = .expense
  @State private var amount = ""
  @State private var categoryID: UUID?
  @State private var date = Date()
  @State private var note = ""
  @State private var error: String?
  @FocusState private var errorFocused: Bool

  var body: some View {
    NavigationStack {
      ZStack {
        LedgerBackground()

        ScrollView {
          VStack(spacing: 18) {
            amountCard
            detailsCard

            if let error {
              Label(error, systemImage: "exclamationmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .ledgerCard(padding: 14)
                .accessibilityAddTraits(.isStaticText)
                .focused($errorFocused)
            }

            Button(action: save) {
              HStack {
                Text(L10n.text(model.isSaving ? .saving : saveTitle))
                Spacer()
                Image(systemName: "checkmark.circle.fill")
              }
              .padding(.horizontal, 18)
            }
            .buttonStyle(PrimaryButton())
            .disabled(model.isSaving)
            .accessibilityIdentifier("transaction.save")
          }
          .padding(.horizontal, 18)
          .padding(.bottom, 30)
        }
      }
      .accessibilityIdentifier("transaction.editor.screen")
      .navigationTitle(L10n.text(existing == nil ? .addTransaction : .editTransaction))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .font(.caption.weight(.bold))
              .foregroundStyle(LedgerTheme.navy)
              .frame(width: 32, height: 32)
              .background(LedgerTheme.paper)
              .clipShape(Circle())
              .overlay { Circle().stroke(LedgerTheme.hairline) }
          }
          .disabled(model.isSaving)
          .accessibilityLabel(L10n.text(.cancel))
        }
      }
    }
    .onAppear(perform: loadExisting)
    .onChange(of: kind) { _, _ in categoryID = nil }
  }

  private var amountCard: some View {
    VStack(spacing: 24) {
      HStack(spacing: 10) {
        kindButton(.expense, icon: "arrow.up.right")
        kindButton(.income, icon: "arrow.down.left")
      }

      VStack(spacing: 10) {
        HStack(spacing: 8) {
          LedgerIcon(
            systemName: kind == .expense ? "minus" : "plus",
            color: kindColor
          )
          Text(L10n.text(.amount))
            .font(.caption.weight(.bold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
          Spacer()
          Text(model.ledger.currency ?? "USD")
            .font(.caption.weight(.bold))
            .foregroundStyle(kindColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(kindColor.opacity(0.1))
            .clipShape(Capsule())
        }

        TextField("0", text: $amount)
          .keyboardType(.decimalPad)
          .font(LedgerTypography.displayAmount)
          .foregroundStyle(LedgerTheme.navy)
          .multilineTextAlignment(.leading)
          .minimumScaleFactor(0.6)
          .accessibilityLabel(L10n.text(.amount))
          .accessibilityHint(L10n.text(.amountHint))

        Rectangle()
          .fill(kindColor.opacity(0.55))
          .frame(height: 2)
      }
    }
    .ledgerCard(padding: 20)
  }

  private var kindColor: Color {
    kind == .expense ? LedgerTheme.terracotta : LedgerTheme.sage
  }

  private func kindButton(_ value: TransactionKind, icon: String) -> some View {
    let selected = kind == value
    let color = value == .expense ? LedgerTheme.terracotta : LedgerTheme.sage

    return Button {
      withAnimation(.easeOut(duration: 0.2)) {
        kind = value
      }
    } label: {
      Label(L10n.text(value == .expense ? .expense : .income), systemImage: icon)
        .font(.subheadline.weight(.semibold))
        .frame(maxWidth: .infinity, minHeight: 44)
        .foregroundStyle(selected ? Color.white : color)
        .background(selected ? color : color.opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(color.opacity(selected ? 0 : 0.15))
        }
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }

  private var detailsCard: some View {
    VStack(spacing: 0) {
      editorRow(icon: "tag.fill", color: LedgerTheme.terracotta) {
        Picker(L10n.text(.category), selection: $categoryID) {
          Text(L10n.text(.chooseCategory)).tag(UUID?.none)
          ForEach(activeCategories) { category in
            Text(L10n.categoryName(category)).tag(Optional(category.id))
          }
        }
      }

      Divider().padding(.leading, 50)

      editorRow(icon: "calendar", color: LedgerTheme.sage) {
        DatePicker(
          L10n.text(.date),
          selection: $date,
          in: ...Date(),
          displayedComponents: .date
        )
      }

      Divider().padding(.leading, 50)

      HStack(alignment: .top, spacing: 14) {
        LedgerIcon(systemName: "text.alignleft", color: LedgerTheme.olive)
        TextField(L10n.text(.noteOptional), text: $note, axis: .vertical)
          .lineLimit(3...6)
          .padding(.top, 8)
      }
      .padding(.vertical, 10)
    }
    .ledgerCard(padding: 14)
  }

  private var saveTitle: L10n.Key {
    existing == nil ? .save : .saveChanges
  }

  private var activeCategories: [LedgerCategory] {
    model.ledger.categories.filter { $0.kind == kind && $0.status == .active }
  }

  private func editorRow<Content: View>(
    icon: String,
    color: Color,
    @ViewBuilder content: () -> Content
  ) -> some View {
    HStack(spacing: 14) {
      LedgerIcon(systemName: icon, color: color)
      content()
      Spacer(minLength: 0)
    }
    .padding(.vertical, 8)
  }

  private func loadExisting() {
    guard let existing else { return }
    kind = existing.kind
    amount = amountText(existing.amountMinor, currency: existing.currency, locale: locale)
    categoryID = existing.categoryID
    note = existing.note
    date = Calendar.current.date(from: existing.occurredOn) ?? Date()
  }

  private func save() {
    guard let minor = minorAmount(amount, currency: model.ledger.currency ?? "USD", locale: locale)
    else {
      fail(L10n.validation(.invalidAmount))
      return
    }

    let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
    let category = activeCategories.first { $0.id == categoryID }

    do {
      try LedgerValidator.validate(
        kind: kind,
        amountMinor: minor,
        category: category,
        date: components,
        note: note
      )

      let now = Date()
      let record = LedgerTransaction(
        id: existing?.id ?? UUID(),
        kind: kind,
        amountMinor: minor,
        currency: model.ledger.currency ?? "USD",
        categoryID: category!.id,
        categoryName: category!.name,
        occurredOn: components,
        note: note,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now
      )

      let saved = model.mutate(success: .transactionSaved, failure: .transactionSaveFailed) {
        staged in
        if let index = staged.transactions.firstIndex(where: { $0.id == record.id }) {
          staged.transactions[index] = record
        } else {
          staged.transactions.append(record)
        }
      }

      saved ? dismiss() : fail(L10n.text(.transactionSaveFailed))
    } catch let validationError as LedgerValidationError {
      fail(L10n.validation(validationError))
    } catch {
      fail(L10n.text(.transactionSaveFailed))
    }
  }

  private func fail(_ message: String) {
    error = message
    errorFocused = true
    UIAccessibility.post(notification: .announcement, argument: message)
  }
}

struct HistoryView: View {
  @EnvironmentObject private var model: LedgerViewModel
  @State private var selected: LedgerTransaction?

  var body: some View {
    NavigationStack {
      ZStack {
        LedgerBackground()

        ScrollView {
          VStack(alignment: .leading, spacing: 22) {
            MonthNavigator()
            LedgerSectionTitle(
              title: L10n.text(.history),
              detail: L10n.text(.transactionsDescription)
            )

            if records.isEmpty {
              emptyState
            } else {
              transactionList
            }
          }
          .padding(.horizontal, 18)
          .padding(.bottom, 28)
        }
      }
      .accessibilityIdentifier("history.screen")
      .navigationTitle(L10n.text(.history))
      .sheet(item: $selected) { TransactionDetailView(transaction: $0) }
    }
  }

  private var records: [LedgerTransaction] {
    model.ledger.transactions(in: model.selectedMonth)
  }

  private var emptyState: some View {
    VStack(spacing: 14) {
      LedgerIcon(systemName: "clock.arrow.circlepath", color: LedgerTheme.olive)
      Text(L10n.text(.noTransactions))
        .font(.headline)
      Text(L10n.text(.transactionsDescription))
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .ledgerCard()
  }

  private var transactionList: some View {
    VStack(spacing: 0) {
      ForEach(Array(records.enumerated()), id: \.element.id) { index, transaction in
        Button {
          selected = transaction
        } label: {
          TransactionRow(transaction: transaction)
        }
        .buttonStyle(.plain)

        if index < records.count - 1 {
          Divider().padding(.leading, 52)
        }
      }
    }
    .ledgerCard(padding: 14)
  }
}

struct TransactionDetailView: View {
  @EnvironmentObject private var model: LedgerViewModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.locale) private var locale

  let transaction: LedgerTransaction

  @State private var editing = false
  @State private var deleting = false
  @State private var deleteError: String?

  var body: some View {
    NavigationStack {
      ZStack {
        LedgerBackground()

        ScrollView {
          VStack(spacing: 20) {
            detailHero
            noteCard

            if let deleteError {
              Label(deleteError, systemImage: "exclamationmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .ledgerCard(padding: 14)

              Button(L10n.text(.retryDelete), role: .destructive, action: delete)
                .accessibilityIdentifier("transaction.delete.retry")
            }

            Button(L10n.text(.editTransactionAction)) { editing = true }
              .buttonStyle(PrimaryButton())

            Button(L10n.text(model.isSaving ? .deleting : .deleteTransaction), role: .destructive) {
              deleting = true
            }
            .disabled(model.isSaving)
          }
          .padding(.horizontal, 18)
          .padding(.bottom, 30)
        }
      }
      .navigationTitle(L10n.text(.transaction))
      .navigationBarTitleDisplayMode(.inline)
      .alert(L10n.text(.deleteTransactionTitle), isPresented: $deleting) {
        Button(L10n.text(.cancel), role: .cancel) {}
        Button(L10n.text(.deletePermanently), role: .destructive, action: delete)
      } message: {
        Text(L10n.format(.deleteTransactionMessage, L10n.categoryName(transaction.categoryName)))
      }
      .sheet(isPresented: $editing) { TransactionEditorView(existing: transaction) }
    }
  }

  private var detailHero: some View {
    VStack(spacing: 16) {
      LedgerIcon(
        systemName: transaction.kind == .expense ? "arrow.up.right" : "arrow.down.left",
        color: transaction.kind == .expense ? LedgerTheme.terracotta : LedgerTheme.sage
      )

      Text(L10n.text(transaction.kind == .expense ? .expense : .income).uppercased())
        .font(.caption.weight(.bold))
        .tracking(1.2)
        .foregroundStyle(.white.opacity(0.7))

      Text(L10n.categoryName(transaction.categoryName))
        .font(.system(.title, design: .serif, weight: .bold))
        .foregroundStyle(.white)

      Text(
        money(
          transaction.amountMinor,
          currency: transaction.currency,
          signed: transaction.kind,
          locale: locale
        )
      )
      .font(LedgerTypography.heroAmount)
      .foregroundStyle(.white)
      .minimumScaleFactor(0.5)
    }
    .padding(24)
    .frame(maxWidth: .infinity)
    .background(
      LinearGradient(
        colors: [LedgerTheme.navy, LedgerTheme.navy.opacity(0.84)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    .shadow(color: LedgerTheme.navy.opacity(0.2), radius: 18, y: 9)
  }

  private var noteCard: some View {
    HStack(alignment: .top, spacing: 14) {
      LedgerIcon(systemName: "text.alignleft", color: LedgerTheme.olive)
      Text(transaction.note.isEmpty ? L10n.text(.noNote) : transaction.note)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(transaction.note.isEmpty ? .secondary : LedgerTheme.ink)
    }
    .ledgerCard()
  }

  private func delete() {
    let deleted = model.mutate(success: .transactionDeleted, failure: .transactionDeleteFailed) {
      $0.transactions.removeAll { $0.id == transaction.id }
    }

    if deleted {
      dismiss()
    } else {
      deleteError = L10n.text(.transactionDeleteFailed)
    }
  }
}
