# Ledgerly v1 Localization Requirements

## Launch languages

- English (`en`) and Traditional Chinese (`zh-Hant`) are first-class launch
  languages.
- The default follows the device/app language. Settings also offers an explicit
  language choice: System Default, English, and 繁體中文.
- No production-facing interface string may be hard-coded in a view. Use typed
  localization keys and provide both language values.

## Product language rules

- Keep Ledgerly as the product name in both languages.
- Currency and dates use the selected ledger currency and active locale; do not
  translate amounts or change stored money values.
- VoiceOver labels, validation, recovery, destructive confirmations, export
  text, and accessibility hints require both translations.
- The launch screen must remain mostly visual. It may show `Ledgerly` but must
  not depend on language-specific marketing copy.

## Acceptance gate

Before QA, verify the approved P0 flows in English and Traditional Chinese:
onboarding, Home, transactions, categories, insights, settings, export,
recovery, and delete-all confirmation. Test Dynamic Type and text expansion so
Chinese/English labels do not clip or overlap.
