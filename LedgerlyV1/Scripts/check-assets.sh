#!/bin/sh
# Verifies that code-loaded image names resolve through Assets.xcassets.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
catalog="$root/Resources/Assets.xcassets"
project="$root/LedgerlyV1.xcodeproj/project.pbxproj"

fail() { printf '%s\n' "asset check: $*" >&2; exit 1; }

names=$(grep -Rho 'Image("[^"]*"' "$root/App" "$root/DesignSystem" "$root/Features" 2>/dev/null \
  | sed 's/^Image("//;s/"$//' \
  | sort -u)

for name in $names
do
  test -d "$catalog/$name.imageset" || fail "SwiftUI Image(\"$name\") has no matching $name.imageset"
  manifest="$catalog/$name.imageset/Contents.json"
  test -f "$manifest" || fail "$name.imageset has no Contents.json"
  filename=$(sed -n 's/.*"filename"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -1)
  test -n "$filename" || fail "$name.imageset declares no image file"
  test -f "$catalog/$name.imageset/$filename" || fail "$name.imageset references missing $filename"
done

if grep -Eq '\.png in Resources|lastKnownFileType = image\.png' "$project"; then
  fail "raw PNG files are mapped as bundle resources; code-loaded images must use asset catalogs"
fi

count=$(printf '%s\n' "$names" | sed '/^$/d' | wc -l | tr -d ' ')
printf '%s\n' "asset check: passed ($count named image asset(s))"
