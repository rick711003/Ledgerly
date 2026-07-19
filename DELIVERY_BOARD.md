# Ledgerly v1 Delivery Board

## QA — 20260718T071533Z-69598423

**Status: NOT PASSED — no ship.** Rick remains the sole manual release approver; this result does not authorize release.

### Evidence-based result

| Check | Result | Evidence |
|---|---|---|
| Fresh-project boundary | Pass | `LedgerlyV1/LedgerlyV1.xcodeproj/project.pbxproj` maps the ten direct `App/`, `Domain/`, `Persistence/`, `DesignSystem/`, and `Features/` v1 files plus `LedgerlyV1Tests/LedgerlyV1Tests.swift`; it maps neither `Ledgerly.xcodeproj`, `Sources/`, nor `LedgerlyV1/LedgerlyV1/`. The shared `LedgerlyV1` scheme names the app and XCTest targets. |
| Offline/local boundary | Static pass | QA scan of mapped sources found no network, analytics, cloud, advertising, or external-open APIs. `FileLedgerStore` uses the new `Application Support/LedgerlyV1/ledger-v1.json` namespace, atomic writes, and `FileProtectionType.complete`. |
| Persistence/recovery | Fail | See P0 and P1 defects below. Corrupt/newer store load tests preserve bytes, but the UI does not offer retry or differentiated recovery. |
| Functional/design traceability | Fail | Required month navigation, loading/retry/recovery, saving/retry, and destructive failure states from `coverage.md` are missing. |
| Automated coverage | Compiles; execution blocked | Added regression coverage for category normalization, newest-first ordering, and 500-character notes. Existing coverage includes store round-trip, corrupted/newer bytes preservation, CSV escaping, monthly arithmetic, archived-category validation, and future-date rejection. Fresh `xcodebuild build-for-testing` with Xcode 26.6 succeeded for the isolated app and XCTest bundle in `.qa-run-20260718T071533Z-69598423`; test execution cannot start because CoreSimulatorService is unavailable and no simulator runtime/device can be discovered. |
| Accessibility | Not passed | Standard controls and a few labels/hints exist, but no simulator/device proof for VoiceOver announcements, Dynamic Type, contrast, 44 pt hit targets, or Reduce Motion. Error and post-save announcements are not implemented. |

### Defects

- **P0 — failed persistence leaves the displayed ledger mutated.** Transaction save/edit, transaction delete, category add, and category archive/restore change `model.ledger` before `persist()` succeeds. Reproduce with a `LedgerStoring.save` failure: attempt one of these operations; the UI state is already changed despite the stated “unchanged” failure message and disk state remaining unchanged. Stage a copy, save it, then publish it only on success.
- **P1 — retryable open failures cannot be retried.** `LedgerViewModel.open()` always moves failures to a static `RecoveryView`; it has no Retry control and does not distinguish retryable, corrupt, and unsupported-format cases.
- **P1 — month is not explicit or selectable.** Home, History, and Insights are hard-coded to `currentMonth()` and offer no month navigation; this violates AC-03/AC-04 and the approved coverage.
- **P1 — pre-first-transaction currency cannot be changed in Settings.** The Currency row only presents a notice although onboarding states it may be changed before the first transaction.
- **P1 — saves have no progress/duplicate-submit guard.** Transaction save can be tapped repeatedly and has no saving/retry UI.
- **P1 — export and clear-data failures are not recoverable in their flows.** Both dismiss on failure or after attempted clear; required retry/progress/failure states are absent.

### Release blockers

- `PRODUCT_HANDOFF.ios.md` was not found in the workspace, so its claimed iOS build/test evidence cannot be traced.
- Fresh simulator build succeeded; XCTest execution and accessibility evidence require a host where CoreSimulatorService and an iOS runtime/device are available.
- Required support/privacy destinations, backup decision, signing, icon, and Rick’s manual approval remain unresolved.

### Handoff

iOS Engineering: fix atomic state publication first, then complete the missing retry/recovery/month/currency/saving/export/clear flows and provide fresh simulator results. QA: rerun unit and UI/accessibility regression evidence on a full-Xcode host after those changes. Do not release.
