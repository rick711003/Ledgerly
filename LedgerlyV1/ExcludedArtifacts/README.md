# Excluded artifacts

`LegacyCompetingImplementation/` is a reversible relocation of the former nested
`LedgerlyV1/LedgerlyV1/` source tree. It contains duplicate app entry points and
domain/persistence implementations. It is intentionally excluded from every Xcode
target and from `Package.swift`; do not treat it as product code.
