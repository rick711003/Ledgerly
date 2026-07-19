# Ledgerly Settings QA Report

Date: 2026-07-19

Result: pass

## Automated coverage

- 25 domain and persistence tests passed.
- 10 UI tests passed on iPhone 17 Pro.
- Settings root plus all six Settings destinations passed on iPad Pro 13-inch.
- A clean simulator automatically completes onboarding before Settings validation.
- The suite covers English and Traditional Chinese, an accessibility Dynamic Type launch,
  viewport bounds, category creation, Clear Data two-step confirmation, Home, History,
  Insights, and Add Transaction.

## Commands

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project LedgerlyV1/LedgerlyV1.xcodeproj \
  -scheme LedgerlyV1 \
  -destination 'platform=iOS Simulator,id=2728A38A-2438-4EF8-B4FA-D0677CF6BFEB' \
  CODE_SIGNING_ALLOWED=NO test
```

The iPad acceptance run uses the same project and scheme with simulator
`A5A832A7-6D3A-4108-8D93-CFCD6B0954FC` and the two Settings visual suites.

Final successful results:

- iPhone: `.derived-data-design/Logs/Test/Test-LedgerlyV1-2026.07.19_21-44-55-+0800.xcresult`
- iPad: `.derived-data-ipad/Logs/Test/Test-LedgerlyV1-2026.07.19_21-39-32-+0800.xcresult`

## Manual visual review

Named XCTest screenshot attachments were inspected after the final successful runs.
No clipping, blank destinations, placeholder release copy, or unstyled Settings surface remained.
