# Button Intent Audit (Views/ + Views/Components/)

Scope: `OffshoreBudgeting/Views/` and `OffshoreBudgeting/Views/Components/`

What counts as “button-like” in this audit:
- SwiftUI interactive primitives: `Button`, `NavigationLink`, `Menu`, `Link`
- Button-adjacent interaction surfaces: `.contextMenu { … }`, alert/action-sheet buttons, `.unifiedSwipeActions(…)` actions
- Reusable wrappers that *render* or *style* buttons/menus: `DesignSystemV2.Buttons.*`, `GlassCTAButton`, `TranslucentButtonStyle`, `ub_menuButtonStyle()`
- Segmented controls (button-like toggles): `Picker` with `.segmented` style

## Primary CTA

- `DesignSystemV2.Buttons.PrimaryCTA` — “primary action” semantic wrapper (glass prominent on OS 26+).
  - Used: `OffshoreBudgeting/Views/SettingsView.swift:764`, `OffshoreBudgeting/Views/SettingsView.swift:901`
  - Defined: `OffshoreBudgeting/DesignSystem/v2/Components/ButtonsV2.swift:161`

- `GlassCTAButton` — reusable CTA button; glass on OS 26+ with legacy translucent fallback.
  - Used: `OffshoreBudgeting/Views/AddPlannedExpenseView.swift:140`, `OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:192`
  - Defined: `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:7`

- `Button` styled as prominent primary CTA (non-DSv2 semantic wrapper).
  - Examples:
    - `.buttonStyle(.glassProminent)`: `OffshoreBudgeting/Views/AddBudgetView.swift:317`, `OffshoreBudgeting/Views/HomeView.swift:3609`, `OffshoreBudgeting/Views/HelpView.swift:477`
    - `.buttonStyle(.borderedProminent)`: `OffshoreBudgeting/Views/AppLockView.swift:51`, `OffshoreBudgeting/Views/HomeView.swift:3988`, `OffshoreBudgeting/Views/IncomeView.swift:644`

- `OnboardingButtonsRow2` (primary action within the onboarding button row).
  - Defined/used: `OffshoreBudgeting/Views/OnboardingView.swift:135`

## Secondary CTA

- `DesignSystemV2.Buttons.SecondaryCTA` — “secondary action” semantic wrapper (uses glass prominent on OS 26+ like PrimaryCTA, differentiated by call site intent).
  - Used: `OffshoreBudgeting/Views/SettingsView.swift:929`
  - Defined: `OffshoreBudgeting/DesignSystem/v2/Components/ButtonsV2.swift:243`

- `Button` with cancel semantics (role or placement).
  - Examples:
    - `role: .cancel`: `OffshoreBudgeting/Views/AddIncomeFormView.swift:89`, `OffshoreBudgeting/Views/AddPlannedExpenseView.swift:484`, `OffshoreBudgeting/Views/WorkspaceProfilesView.swift:149`
    - Toolbar cancel/done buttons (no explicit role): `OffshoreBudgeting/Views/ExpenseImportView.swift:295`, `OffshoreBudgeting/Views/ManageBudgetCardsSheet.swift:44`

- `OnboardingButtonsRow2` (secondary/back action within the onboarding button row).
  - Defined/used: `OffshoreBudgeting/Views/OnboardingView.swift:135`

## Toolbar CTA

- `DesignSystemV2.Buttons.ToolbarIcon` — toolbar icon wrapper (plain-styled icon button).
  - Used: `OffshoreBudgeting/Views/PresetsView.swift:123`, `OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:70`
  - Defined: `OffshoreBudgeting/DesignSystem/v2/Components/ButtonsV2.swift:407`

- `DesignSystemV2.Buttons.LegacyToolbarIcon` — legacy toolbar icon wrapper (plain-styled icon button).
  - Used: `OffshoreBudgeting/Views/CardsView.swift:181`, `OffshoreBudgeting/Views/BudgetsView.swift:109`, `OffshoreBudgeting/Views/IncomeView.swift:112`, `OffshoreBudgeting/Views/CardDetailView.swift:568`
  - Defined: `OffshoreBudgeting/DesignSystem/v2/Components/ButtonsV2.swift:75`

- `DesignSystemV2.Buttons.GlassProminentIconMenu` — toolbar/menu icon control that presents a `Menu`.
  - Used: `OffshoreBudgeting/Views/WorkspaceProfilesView.swift:21`
  - Defined: `OffshoreBudgeting/DesignSystem/v2/Components/ButtonsV2.swift:475`

- `WorkspaceMenuButton` — toolbar profile/workspace menu wrapper built on `DesignSystemV2.Buttons.GlassProminentIconMenu`.
  - Defined/used: `OffshoreBudgeting/Views/WorkspaceProfilesView.swift:6`

- `IconOnlyButton` — Card detail toolbar icon button wrapper.
  - Defined/used: `OffshoreBudgeting/Views/CardDetailView.swift:1005`

- Inline `Menu` in toolbars (not wrapped in DSv2 component).
  - Examples:
    - Add Expense menu: `OffshoreBudgeting/Views/CardDetailView.swift:534`

- `DesignSystemV2.Toolbar.plusButton` / `DesignSystemV2.Toolbar.prominentButton` — Settings-scoped toolbar factories.
  - Defined: `OffshoreBudgeting/Views/Components/SettingsToolbarButtons.swift:8`
  - Call sites in scanned scope: none found.

## Destructive CTA

- `DesignSystemV2.Buttons.DestructiveCTA` — semantic destructive CTA wrapper (uses `Button(role: .destructive)`).
  - Used: `OffshoreBudgeting/Views/SettingsView.swift:716`, `OffshoreBudgeting/Views/SettingsView.swift:1075`
  - Defined: `OffshoreBudgeting/DesignSystem/v2/Components/ButtonsV2.swift:325`

- `Button(role: .destructive)` — direct SwiftUI destructive actions (alerts, menus, confirmations).
  - Examples:
    - Alerts/confirmation flows: `OffshoreBudgeting/Views/CardDetailView.swift:150`, `OffshoreBudgeting/Views/WorkspaceProfilesView.swift:148`
    - Context menu delete: `OffshoreBudgeting/Views/CardsView.swift:108`
    - Menus with destructive items: `OffshoreBudgeting/Views/ExpenseImportView.swift:254`, `OffshoreBudgeting/Views/BudgetDetailsView.swift:397`

- `.unifiedSwipeActions(…)` — swipe action buttons (typically includes edit + delete; delete is destructive).
  - Examples: `OffshoreBudgeting/Views/HomeView.swift:5084`, `OffshoreBudgeting/Views/IncomeView.swift:628`, `OffshoreBudgeting/Views/PresetsView.swift:56`, `OffshoreBudgeting/Views/WorkspaceProfilesView.swift:180`

## Other / Unclear

- `NavigationLink` — navigational row/button.
  - Examples: `OffshoreBudgeting/Views/HomeView.swift:1046`, `OffshoreBudgeting/Views/SettingsView.swift:169`, `OffshoreBudgeting/Views/HelpView.swift:64`

- `Link` — external navigation (e.g., App Store / developer links).
  - Used: `OffshoreBudgeting/Views/SettingsView.swift:582`, `OffshoreBudgeting/Views/SettingsView.swift:591`

- `Menu` — selection/actions popup (non-toolbar use).
  - Examples: `OffshoreBudgeting/Views/ExpenseImportView.swift:247`, `OffshoreBudgeting/Views/BudgetDetailsView.swift:382`, `OffshoreBudgeting/Views/HomeView.swift:1932`

- `ub_menuButtonStyle()` — menu/button styling compatibility helper (capsule border shape on iOS16+).
  - Used: `OffshoreBudgeting/Views/ExpenseImportView.swift:274`
  - Defined: `OffshoreBudgeting/Core/UIFoundation/MenuButtonStyleCompatibility.swift:7`

- Segmented controls (tappable segments; “button-like” toggles).
  - `BudgetExpenseSegmentedControl` (`Picker` + `.segmented`): used `OffshoreBudgeting/Views/BudgetDetailsView.swift:145`, defined `OffshoreBudgeting/Views/Components/BudgetFilterControls.swift:3`
  - `BudgetSortBar` (`Picker` + `.segmented`): used `OffshoreBudgeting/Views/BudgetDetailsView.swift:155`, defined `OffshoreBudgeting/Views/Components/BudgetFilterControls.swift:17`
  - `PillSegmentedControl` (`Picker` + `.segmented`): used `OffshoreBudgeting/Views/AddIncomeFormView.swift:129`, `OffshoreBudgeting/Views/HomeView.swift:1508`, defined `OffshoreBudgeting/Views/Components/PillSegmentedControl.swift:7`

- Chip/pill selection surfaces (tappable when wrapped in `Button` at call site).
  - `DesignSystemV2.CategoryChipsRow` (contains chip buttons + “Add Category” pill): used `OffshoreBudgeting/Views/AddPlannedExpenseView.swift:186`, `OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:220`
  - `CategoryChipPill` (visual pill view typically used as a `Button` label): used `OffshoreBudgeting/Views/HomeView.swift:4418`, defined `OffshoreBudgeting/Views/Components/CategoryChipPill.swift:5`

- Row containers that become tappable depending on context.
  - `DesignSystemV2.SettingsRow` (wraps in `Button` only if `action` is provided; otherwise used as a label inside `NavigationLink`/`Link`):
    - Used: `OffshoreBudgeting/Views/SettingsView.swift:177`
    - Defined: `OffshoreBudgeting/Views/Components/SettingsRow.swift:9`

- Styles/adapters (button behavior depends on the call site).
  - `TranslucentButtonStyle` (`ButtonStyle`) — used as the legacy fallback styling for `GlassCTAButton`.
    - Defined: `OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:7`
    - Direct call sites in scanned scope: none found (only used by `GlassCTAButton` internally).

- Deprecated wrapper that may still produce a primary action, depending on call site.
  - `UBEmptyState` (delegates to `DesignSystemV2.EmptyState`, which can show a primary CTA).
    - Defined: `OffshoreBudgeting/Views/UBEmptyState.swift:23`
    - Call sites in scanned scope: none found.
