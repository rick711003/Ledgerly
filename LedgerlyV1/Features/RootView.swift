import SwiftUI

struct RootView: View {
  @EnvironmentObject private var model: LedgerViewModel
  var body: some View {
    Group {
      switch model.state {
      case .loading:
        ProgressView(L10n.text(.opening))
      case .onboarding:
        OnboardingView()
      case .ready:
        MainShellView()
      case .recovery(let recovery):
        RecoveryView(recovery: recovery)
      }
    }
    .tint(LedgerTheme.terracotta)
    .background(LedgerTheme.ivory.ignoresSafeArea())
    .alert(
      L10n.text(.appName),
      isPresented: Binding(
        get: { model.notice != nil },
        set: { if !$0 { model.notice = nil } }
      )
    ) {
      Button(L10n.text(.ok)) {}
    } message: {
      Text(model.notice.map { L10n.text($0) } ?? "")
    }
  }
}

struct RecoveryView: View {
  @EnvironmentObject private var model: LedgerViewModel
  let recovery: LedgerViewModel.Recovery

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "lock.shield")
        .font(.largeTitle)

      Text(L10n.text(title))
        .editorialTitle()

      Text(L10n.text(detail))
        .multilineTextAlignment(.center)

      if recovery == .retryable {
        Button(L10n.text(.retryOpening)) {
          model.open()
        }
        .buttonStyle(PrimaryButton())
        .accessibilityIdentifier("recovery.retry")
      } else {
        Text(L10n.text(.recoveryGuidance))
          .font(.footnote)
      }
    }
    .padding()
    .accessibilityElement(children: .contain)
  }

  private var title: L10n.Key {
    recovery == .integrity
      ? .recoveryIntegrityTitle
      : recovery == .unsupportedFormat ? .recoveryUnsupportedTitle : .recoveryRetryableTitle
  }

  private var detail: L10n.Key {
    recovery == .integrity
      ? .recoveryIntegrityDetail
      : recovery == .unsupportedFormat ? .recoveryUnsupportedDetail : .recoveryRetryableDetail
  }
}
