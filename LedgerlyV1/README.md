# Ledgerly v1

Standalone iPhone SwiftUI implementation of the approved Ledgerly v1 design. It does not link to, read from, migrate, or share storage with the discarded root prototype.

The Xcode navigator mirrors the on-disk product layout: `App`, `Domain`,
`Persistence`, `DesignSystem`, `Features`, and `Resources`. Unit and UI tests
live in their own top-level directories. Each file reference uses its basename;
the containing PBXGroup provides its project-relative directory.

## Open and run

Open **`LedgerlyV1/LedgerlyV1.xcodeproj`** in Xcode 15.4 or later (not the discarded root `Ledgerly.xcodeproj`), select the shared **LedgerlyV1** scheme, choose an iPhone simulator or device, then Run. The project targets iOS 17.0.

Run tests with Product → Test, or:

```sh
xcodebuild -project LedgerlyV1/LedgerlyV1.xcodeproj -scheme LedgerlyV1 -destination 'platform=iOS Simulator,name=iPhone 15' test
```

Before a build, validate the project mapping from the repository root:

```sh
LedgerlyV1/Scripts/check-source-map.sh
LedgerlyV1/Scripts/check-format.sh
cd LedgerlyV1 && swift test
```

`swift test` is a portable harness for the Domain/Persistence boundary only; the
app and its Xcode test bundles are validated by the shared Xcode scheme. Use a
host with full Xcode selected (`xcode-select -p` must not point to Command Line
Tools) for the `xcodebuild` command above.

## Resources and excluded artifacts

`Resources/` contains the explicit app Info.plist, launch storyboard, branded
background artwork, and an `Assets.xcassets` catalog with the Ledgerly AppIcon.

`ExcludedArtifacts/LegacyCompetingImplementation/` retains the previous nested
implementation for recovery only. It is deliberately excluded from Xcode targets
and `Package.swift`. The root discarded prototype remains untouched.

## Storage and privacy

The app stores only `LedgerlyV1.PrivateLedger/ledger-v1.json` in its own Application Support directory with atomic writes and complete file protection. It has no network, account, analytics, or prototype-data access. CSV is generated only after the user selects Export CSV and is passed to the system share sheet. Backup policy and release URLs remain product-owner decisions and are not claimed as implemented.
