# UI Consolidation Audit — Phase 20 (Read-only)

Scope:
- `OffshoreBudgeting/Views/Components/*.swift`
- `OffshoreBudgeting/Shared/UI/**/*.swift`
- DSv2 reference: `OffshoreBudgeting/DesignSystem/v2/Components/**/*.swift`

## 1) Inventory

### Views/Components
- `OffshoreBudgeting/Views/Components/BudgetCategoryChipView.swift`
- `OffshoreBudgeting/Views/Components/BudgetFilterControls.swift`
- `OffshoreBudgeting/Views/Components/CalendarNavigationButtonStyle.swift`
- `OffshoreBudgeting/Views/Components/CategoryAvailabilityRow.swift`
- `OffshoreBudgeting/Views/Components/CategoryChipPill.swift`
- `OffshoreBudgeting/Views/Components/ExpenseCategoryChipsRow.swift`
- `OffshoreBudgeting/Views/Components/GlassCTAButton.swift`
- `OffshoreBudgeting/Views/Components/PillSegmentedControl.swift`
- `OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift`
- `OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift`

### Shared/UI
- `OffshoreBudgeting/Shared/UI/Extensions/View+If.swift`

### DesignSystem/v2/Components
- `OffshoreBudgeting/DesignSystem/v2/Components/ButtonsV2.swift`
- `OffshoreBudgeting/DesignSystem/v2/Components/CategoryChips.swift`
- `OffshoreBudgeting/DesignSystem/v2/Components/ChipStyles.swift`
- `OffshoreBudgeting/DesignSystem/v2/Components/Effects/HolographicMetallicText.swift`
- `OffshoreBudgeting/DesignSystem/v2/Components/Effects/UnifiedSwipeActions.swift`
- `OffshoreBudgeting/DesignSystem/v2/Components/EmptyState.swift`
- `OffshoreBudgeting/DesignSystem/v2/Components/HomeListRowStyle.swift`
- `OffshoreBudgeting/DesignSystem/v2/Components/SettingsListRowStyle.swift`
- `OffshoreBudgeting/DesignSystem/v2/Components/SettingsRow.swift`
- `OffshoreBudgeting/DesignSystem/v2/Components/SettingsToolbarButtons.swift`

## 2) Per-file analysis (Views/Components + Shared/UI)

Method:
- Extract top-level types and file-scope functions; also extension methods declared in the file.
- For each symbol, count callsites using `rg --count-matches` excluding the defining file.
- Dead-code candidate = all non-private symbols have 0 external hits (heuristic; requires human confirmation).
- “Migrate to DSv2” = DSv2 contains a likely equivalent by filename or symbol presence (heuristic).

### `OffshoreBudgeting/Views/Components/BudgetCategoryChipView.swift`
- exported symbols (heuristic):
  - `internal struct BudgetCategoryChipView` at L6
- callsites receipts:
  - `BudgetCategoryChipView`: `rg -n --count-matches "\\bBudgetCategoryChipView\\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/Components/BudgetCategoryChipView.swift'` → `0`
- classification: **dead-code candidate** (0 external hits for all non-private symbols)
- DSv2: no obvious equivalent detected (heuristic)

### `OffshoreBudgeting/Views/Components/BudgetFilterControls.swift`
- exported symbols (heuristic):
  - `internal struct BudgetExpenseSegmentedControl` at L3
  - `internal struct BudgetSortBar` at L17
- callsites receipts:
  - `BudgetExpenseSegmentedControl`: `rg -n --count-matches "\\bBudgetExpenseSegmentedControl\\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/Components/BudgetFilterControls.swift'` → `1`
  - `BudgetSortBar`: `rg -n --count-matches "\\bBudgetSortBar\\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/Components/BudgetFilterControls.swift'` → `1`
- classification: in use (>=1 external hit for at least one non-private symbol)
- DSv2: no obvious equivalent detected (heuristic)

### `OffshoreBudgeting/Views/Components/CalendarNavigationButtonStyle.swift`
- exported symbols (heuristic):
  - `internal struct CalendarNavigationButtonStyle` at L6
- callsites receipts:
  - `CalendarNavigationButtonStyle`: `rg -n --count-matches "\\bCalendarNavigationButtonStyle\\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/Components/CalendarNavigationButtonStyle.swift'` → `0`
- classification: **dead-code candidate** (0 external hits for all non-private symbols)
- DSv2: no obvious equivalent detected (heuristic)

### `OffshoreBudgeting/Views/Components/CategoryAvailabilityRow.swift`
- exported symbols (heuristic):
  - `internal struct CategoryAvailabilityRow` at L3
- callsites receipts:
  - `CategoryAvailabilityRow`: `rg -n --count-matches "\\bCategoryAvailabilityRow\\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/Components/CategoryAvailabilityRow.swift'` → `3`
- classification: in use (>=1 external hit for at least one non-private symbol)
- DSv2: no obvious equivalent detected (heuristic)

### `OffshoreBudgeting/Views/Components/CategoryChipPill.swift`
- exported symbols (heuristic):
  - `internal struct CategoryChipPill` at L5
- callsites receipts:
  - `CategoryChipPill`: `rg -n --count-matches "\\bCategoryChipPill\\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/Components/CategoryChipPill.swift'` → `2`
- classification: in use (>=1 external hit for at least one non-private symbol)
- DSv2: no obvious equivalent detected (heuristic)

### `OffshoreBudgeting/Views/Components/ExpenseCategoryChipsRow.swift`
- exported symbols (heuristic):
  - `internal struct ExpenseCategoryChipsRow` at L5
- callsites receipts:
  - `ExpenseCategoryChipsRow`: `rg -n --count-matches "\\bExpenseCategoryChipsRow\\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/Components/ExpenseCategoryChipsRow.swift'` → `2`
- classification: in use (>=1 external hit for at least one non-private symbol)
- DSv2: **migrate to DSv2** (heuristic match)
  - filename-similar: categorychips.swift

### `OffshoreBudgeting/Views/Components/GlassCTAButton.swift`
- exported symbols (heuristic):
  - `internal struct GlassCTAButton` at L7
- callsites receipts:
  - `GlassCTAButton`: `rg -n --count-matches "\\bGlassCTAButton\\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/Components/GlassCTAButton.swift'` → `2`
- classification: in use (>=1 external hit for at least one non-private symbol)
- DSv2: no obvious equivalent detected (heuristic)

### `OffshoreBudgeting/Views/Components/PillSegmentedControl.swift`
- exported symbols (heuristic):
  - `internal struct PillSegmentedControl` at L7
- callsites receipts:
  - `PillSegmentedControl`: `rg -n --count-matches "\\bPillSegmentedControl\\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/Components/PillSegmentedControl.swift'` → `5`
- classification: in use (>=1 external hit for at least one non-private symbol)
- DSv2: no obvious equivalent detected (heuristic)

### `OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift`
- exported symbols (heuristic):
  - `internal enum UBPresentationDetent` at L12
  - `internal ext-func applyDetentsIfAvailable` at L33 (extension View)
- callsites receipts:
  - `UBPresentationDetent`: `rg -n --count-matches "\\bUBPresentationDetent\\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift'` → `0`
  - `applyDetentsIfAvailable`: `rg -n --count-matches "(\\.applyDetentsIfAvailable\\b|\\bapplyDetentsIfAvailable\\s*\\()" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift'` → `11`
- classification: in use (>=1 external hit for at least one non-private symbol)
- DSv2: no obvious equivalent detected (heuristic)

### `OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift`
- exported symbols (heuristic):
  - `internal struct TranslucentButtonStyle` at L7
- callsites receipts:
  - `TranslucentButtonStyle`: `rg -n --count-matches "\\bTranslucentButtonStyle\\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift'` → `6`
- classification: in use (>=1 external hit for at least one non-private symbol)
- DSv2: no obvious equivalent detected (heuristic)

### `OffshoreBudgeting/Shared/UI/Extensions/View+If.swift`
- exported symbols: (none detected by heuristic)
- dead-code candidate: needs manual review (extensions/modifiers may be implicit)

