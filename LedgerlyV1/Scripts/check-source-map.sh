#!/bin/sh
# Validates the intentionally small, explicit target membership of LedgerlyV1.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
project="$root/LedgerlyV1.xcodeproj/project.pbxproj"

fail() { printf '%s\n' "source-map check: $*" >&2; exit 1; }

# Xcode project files are OpenStep plists, which CommandLineTools plutil does not parse.
grep -Fq 'rootObject = PROJ;' "$project" || fail "project.pbxproj is incomplete"
for path in \
  App/LedgerlyV1App.swift App/Localization.swift Domain/Ledger.swift Persistence/LedgerStore.swift \
  DesignSystem/Theme.swift Features/InsightsView.swift Features/MainShellView.swift \
  Features/OnboardingView.swift Features/RootView.swift Features/SettingsViews.swift \
  Features/TransactionViews.swift LedgerlyV1Tests/LedgerlyV1Tests.swift \
  LedgerlyV1UITests/LedgerlyV1UITests.swift Resources/Assets.xcassets \
  Resources/LaunchScreen.storyboard Resources/Info.plist Resources/en.lproj/Localizable.strings \
  Resources/zh-Hant.lproj/Localizable.strings
do
  test -e "$root/$path" || fail "missing $path"
done

for source in LedgerlyV1App.swift Localization.swift Ledger.swift LedgerStore.swift Theme.swift InsightsView.swift MainShellView.swift OnboardingView.swift RootView.swift SettingsViews.swift TransactionViews.swift LedgerlyV1Tests.swift LedgerlyV1UITests.swift
do
  count=$(grep -Ec "path = $source;" "$project" || true)
  test "$count" -eq 1 || fail "$source must have one basename-only file reference (found $count)"
done

for group in App Domain Persistence DesignSystem Features Resources LedgerlyV1Tests LedgerlyV1UITests
do
  grep -Eq "path = $group; sourceTree = \"<group>\";" "$project" || fail "missing $group PBXGroup"
done

sources=$(grep -Ec '^ A0[0-9][0-9] /\* .* in Sources \*/ = \{isa = PBXBuildFile;' "$project" || true)
test "$sources" -eq 11 || fail "expected exactly eleven app source build files"
grep -Fq 'files = (R001, R002, R003);' "$project" || fail "resource phase is incomplete"
grep -Fq 'knownRegions = (en, zh-Hant, Base);' "$project" || fail "Traditional Chinese region missing"
grep -Fq 'ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;' "$project" || fail "AppIcon build setting missing"
grep -Fq 'IPHONEOS_DEPLOYMENT_TARGET = 17.0;' "$project" || fail "iOS 17 deployment target missing"
if grep -Eq 'ExcludedArtifacts|LegacyCompetingImplementation|\.\./(Sources|Tests)' "$project" "$root/Package.swift"; then
  fail "excluded artifacts or root prototype leak into product mappings"
fi

printf '%s\n' 'source-map check: passed (11 app sources, 2 test sources, 3 resources)'
