# Ledgerly Settings Design Contract v1

Status: approved for implementation

## Experience direction

Settings is a calm control room, not a collection of system forms. Every surface uses the ivory journal background, paper cards, navy hierarchy, sage confirmation, terracotta warnings, semantic typography tokens, generous spacing, and explicit consequences. Native controls remain where they improve accessibility, but they are composed inside Ledgerly surfaces.

## Surface inventory

| ID | Surface and states | Design requirement | Acceptance evidence |
| --- | --- | --- | --- |
| settings.home | default, saving | Grouped journal cards with current values and clear destinations | iPhone/iPad, EN/ZH-Hant |
| settings.language | system, English, Traditional Chinese | Dedicated selection sheet; current selection, explanation, checkmark, immediate update | runtime selection UI and relaunch test |
| settings.currency | editable, locked, saving, error | Currency cards with symbol/name/code, selected state, historical-data consequence | unit/UI tests and screenshots |
| settings.categories | active, archived, empty, saving, error | Branded filter, category cards, kind/origin metadata, archive/restore action | active/archived runtime evidence |
| settings.category.new | expense/income, invalid, duplicate, saving | Branded editor with guidance and inline validation | validation tests |
| settings.category.confirm | archive, restore | Ledgerly confirmation sheet with named category, consequence, safe cancel | runtime and mutation test |
| settings.privacy | default | Privacy promise hero plus local storage, sharing, and collection disclosure cards | EN/ZH-Hant evidence |
| settings.export | preparing, ready, error | Branded progress/result/error states and explicit sharing consequence | export tests |
| settings.clear | warning, typed confirmation, saving, error | Two-step destructive flow, export reminder, exact DELETE phrase, prominent safe exit | clear/cancel/retry tests |

## Ownership and gates

- PM owns behavior and consequences: currency locks after the first transaction; archiving preserves history; clearing is irreversible; language changes presentation only.
- Design owns this inventory, hierarchy, semantic typography, component styling, warning severity, and every overlay/state.
- iOS owns readable components, persistence correctness, platform accessibility, responsive iPhone/iPad layout, identifiers, and runtime evidence.
- Design must review runtime output for every row before QA.
- QA verifies behavior, localization, Dynamic Type, VoiceOver semantics, device classes, failure states, and that no row silently falls back to an undesigned generic form or alert.
