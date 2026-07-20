# Ledgerly real runtime verification — 2026-07-20

Status: passed after manifest correction

## Corrective finding

The portable Swift package initially failed before tests because localized resources
were present but `Package.swift` did not declare `defaultLocalization`. The package
also treated unrelated app, test, resource, script, and archived files as unhandled
target inputs. The manifest now declares English as the default localization and
explicitly excludes files outside the Domain/Persistence harness.

## Machine evidence

- `LedgerlyV1/Scripts/check-source-map.sh`: passed; 13 app sources, 2 test sources,
  and 5 resources are mapped.
- `LedgerlyV1/Scripts/check-format.sh`: passed.
- `swift test --package-path LedgerlyV1 --disable-sandbox`: passed; 1 portable
  Domain/Persistence test, 0 failures.
- Xcode `LedgerlyV1` scheme on the booted iPhone 17 Pro Simulator: passed; 25 unit
  tests and 10 UI tests, 0 failures.
- The UI suite launched `com.ledgerly.v1` repeatedly and exercised onboarding,
  Home, History, Insights, Add Transaction, Settings, Language, Currency,
  Categories, Export, Privacy, Clear Data, accessibility sizing, and Traditional
  Chinese presentation.

Xcode result bundle:

`/tmp/ledgerly-edge-derived/Logs/Test/Test-LedgerlyV1-2026.07.20_21-47-10-+0800.xcresult`

## Gate interpretation

This evidence proves build, unit-test, UI-test, and Simulator-launch health for the
tested revision. It does not authorize App Store submission or production release;
those remain manual gates.
