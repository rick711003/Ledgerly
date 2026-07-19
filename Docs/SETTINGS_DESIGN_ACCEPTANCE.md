# Ledgerly Settings Design Acceptance

Date: 2026-07-19

Decision: accepted for QA

Runtime acceptance owner: Design (independent of Engineering)

## Reviewed runtime surfaces

- Settings root on iPhone 17 Pro and iPad Pro 13-inch
- Home, History, Insights, and Add Transaction on iPhone 17 Pro
- Language in English and Traditional Chinese
- Currency in editable and locked presentation
- Categories, including active list and new-category editor
- Data & privacy in English and Traditional Chinese
- CSV export ready state
- Clear all data warning and typed final-confirmation state

## Acceptance result

- All content stays inside the visible viewport with no horizontal clipping.
- iPhone content uses compact full-width cards; iPad content keeps a bounded reading width and native sheet presentation.
- Every surface uses the Ledgerly paper, navy, sage, olive, and terracotta visual language.
- The shared visual system now uses a quiet paper gradient, restrained elevation,
  18-point card geometry, semantic typography, consistent screen headers, and one
  intentional primary action per context.
- Home no longer combines a competing system navigation title with an overlapping
  floating action; History and Insights now share the same editorial header and month control.
- Headings, supporting text, cards, selection states, safe exits, destructive actions, and disabled states have consistent hierarchy.
- English and Traditional Chinese copy is release-ready; internal placeholder and `v1` wording was removed.
- No Settings destination falls back to an undesigned native alert or generic form.

## Reproducible evidence

The UI suite keeps named screenshots for `settings-root`, all six primary destinations,
`category-editor`, `clear-final-confirmation`, and the Traditional Chinese Language,
Privacy, and Clear Data surfaces. Primary-product evidence also includes `home-redesign`,
`history-redesign`, `insights-redesign`, and `add-transaction-redesign`. The same tests run on iPhone and iPad without relying
on pre-seeded simulator data.

Final evidence:

- iPhone final completion audit: `/Users/rick/Library/Developer/Xcode/DerivedData/LedgerlyV1-ccfhueccikktqmcbqcuunmnvxrky/Logs/Test/Test-LedgerlyV1-2026.07.19_22-02-54-+0800.xcresult`
- iPad: `.derived-data-ipad/Logs/Test/Test-LedgerlyV1-2026.07.19_21-39-32-+0800.xcresult`
