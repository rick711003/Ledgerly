// swift-tools-version: 6.0
import PackageDescription

// Portable domain/persistence test harness. The iOS app is built by LedgerlyV1.xcodeproj.
let package = Package(
    name: "LedgerlyV1Domain",
    defaultLocalization: "en",
    products: [.library(name: "LedgerlyDomain", targets: ["LedgerlyDomain"])],
    targets: [
        .target(
            name: "LedgerlyDomain",
            path: ".",
            exclude: [
                "App",
                "DesignSystem",
                "ExcludedArtifacts",
                "Features",
                "LedgerlyV1Tests",
                "LedgerlyV1UITests",
                "LOCALIZATION_REQUIREMENTS.md",
                "PackageTests",
                "README.md",
                "Resources",
                "Scripts"
            ],
            sources: ["Domain/Ledger.swift", "Persistence/LedgerStore.swift"]
        ),
        .testTarget(name: "LedgerlyDomainTests", dependencies: ["LedgerlyDomain"], path: "PackageTests")
    ]
)
