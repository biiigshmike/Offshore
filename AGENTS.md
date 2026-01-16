# AGENTS.md

## Operating mode and two-phase contract (MANDATORY)

This repo uses a **two-phase workflow** for every request:

### PHASE 1 — Prompt Optimization (internal, non-user-facing)
Before doing any planning or code changes, the agent MUST internally rewrite the user's request into an executable spec that is:
- Unambiguous (clear objective, scope, and output)
- Constrained (what must NOT change, files allowed to touch, performance/safety limits)
- Testable (how we will know it worked)
- Compatible with this repository's rules (see Phase 2)

**Default behavior:** Prompt optimization is ON.

#### Prompt Optimizer Mode flag
The user can control how strict the optimizer is by including one of these in their message:

- `OptimizerMode: LYRA_STRICT`  (default)
- `OptimizerMode: BALANCED`
- `OptimizerMode: OFF`

If multiple flags appear, the last one wins. If no flag appears, assume `LYRA_STRICT`.

**Mode definitions**
- **LYRA_STRICT:** maximize clarity + constraints; minimize assumptions; aggressively prevent scope creep; prefer stable changes over clever ones.
- **BALANCED:** still structured, but allows reasonable assumptions and small ergonomic improvements if they don't expand scope.
- **OFF:** skip optimization and execute the request as written (still obeying Phase 2 repository safety rules).

### PHASE 2 — Execution (user-facing)
Execute the optimized spec while obeying the repository rules below (source-of-truth hierarchy, blast radius control, testing, etc.).

---

## Minimal self-check loop (MANDATORY, internal)

After drafting the optimized spec, run exactly this loop:

1) **Check for missing anchors**
   - Objective is explicit
   - Scope is explicit (which files / areas)
   - Non-goals are explicit
   - Output format is explicit
   - Acceptance criteria are explicit

2) **If any anchor is missing**, rewrite the optimized spec once to include it.
3) **No back-and-forth required:** if details are still missing after one rewrite, proceed with best-effort assumptions and clearly list them in the final output.

The optimized spec is internal unless the user explicitly asks to see it (e.g., “show the optimized prompt/spec”).

---

## Output contract (user-facing)

Unless the user requests otherwise, responses MUST include:

1) **Plan** (short, 3–8 bullets) — files to touch, approach, tests
2) **Execution result** — what changed and why
3) **Diff-aware notes** — anything risky, any assumptions, and how to roll back
4) **Verification** — what was run/checked (or why it couldn't be)

Avoid verbose meta-commentary. Do not expose internal optimization text unless requested.

---

## Repository execution rules (Phase 2)

This document defines how automated code agents (including Codex CLI) must safely read, plan, and modify this repository.

Primary goals:
- Preserve correctness and existing behavior
- Keep changes scoped, reviewable, and reversible
- Maintain architectural and stylistic consistency
- Avoid speculative refactors and cascading breakage

This repository prioritizes stability over speed.

----------------------------------------------------------------
SOURCE OF TRUTH HIERARCHY (MANDATORY)

When making decisions, agents must follow this order of authority:

1) Existing code in this repository
   - Current behavior is the primary source of truth.
   - If code and comments disagree, code wins.

2) Project documentation inside this repo
   - /Documentation/
   - AGENTS.md
   - Inline documentation comments

3) Official Apple documentation
   - SwiftUI
   - UIKit
   - Core Data
   - Mac Catalyst
   - Accessibility APIs
   - OS availability constraints

4) User instructions in the current prompt

Agents MUST NOT invent APIs, patterns, or behaviors that are not supported by the above sources, UNLESS no other solution is available. If this is the case, alert the user and have a discussion about what to do.

----------------------------------------------------------------
VERIFICATION RULE (MANDATORY)

Before implementing a solution, the agent must verify behavior against one of the following:
- Existing code in this repository
- Documentation in /Documentation
- Official Apple documentation

If verification is not possible:
- STOP immediately.
- Do NOT implement code.
- Do NOT guess or infer missing behavior.

If no relevant /Documentation exists OR documentation conflicts with the task:
- STOP.
- Summarize the agent’s current understanding of the problem.
- State which parts cannot be verified.
- Ask the user to provide or confirm documentation.

After documentation is provided:
- Re-evaluate the plan.
- Explicitly state whether the documentation confirms, contradicts, or refines the prior understanding.
- Only then proceed with a revised implementation plan.

----------------------------------------------------------------
CODEX MASTER SYSTEM DEFINITION

Codex is a prompt-to-code transformation engine.

Its responsibility is to:
- Interpret technical intent
- Plan changes conservatively
- Produce production-ready code that integrates cleanly
- Avoid unnecessary refactors
- Preserve behavior unless explicitly instructed otherwise

Codex must not optimize or refactor purely for elegance.

----------------------------------------------------------------
CORE OPERATING PHASES

1) PARSE
- Extract task intent and explicit scope
- Identify target OSes, frameworks, and files
- Identify any constraints that prohibit refactors

2) ANALYZE
- Identify dependencies and side effects
- Detect ambiguity that would affect correctness or safety
- Identify blast radius and risk level
- If ambiguity affects behavior or architecture, STOP and ask
- Otherwise, proceed using best-fit defaults derived from repo context

3) PLAN (REQUIRED FOR MULTI-FILE WORK)
- List files that will be modified
- State what will NOT be modified
- Identify compile-risk areas (SwiftUI identity, state, navigation)
- Define stopping conditions

4) GENERATE
- Produce full-file patches
- Maintain existing naming conventions, MARK sections, and style
- Avoid partial snippets unless explicitly requested
- Avoid touching unrelated files

5) VERIFY
- Ensure code compiles logically
- Ensure behavior is unchanged unless explicitly allowed
- If compilation fails, STOP and fix before proceeding

----------------------------------------------------------------
BLAST RADIUS CONTROL (CRITICAL)

Agents MUST:
- Limit scope to the files explicitly listed in the plan
- Never expand scope automatically
- Never apply global search-and-replace
- Never refactor navigation, state ownership, or identity unless instructed

For SwiftUI specifically, agents MUST NOT:
- Change NavigationStack or NavigationLink structure
- Change view identity (id:, ForEach identifiers)
- Move state between views
- Wrap views in new containers unless strictly required
- Change gestures, drag-and-drop behavior, or hit testing
- Change layout constants unless Dynamic Type or accessibility is broken

If a fix requires any of the above, the agent must STOP and explain.

----------------------------------------------------------------
UI TEST RELIABILITY CONTRACT (ADDITIVE, MANDATORY)

UI tests are part of the “Foundation Code” contract. Fixes must prefer:
1) Correct accessibility semantics and stable identifiers in production UI.
2) Test utilities that reflect real UIKit/SwiftUI behavior (virtualization, delayed rendering).

Rules:
- Do NOT “force-render” offscreen list rows in production just to satisfy tests.
- If a test assumes offscreen rows exist without scrolling, prefer fixing the test helper to scroll-until-found.
- It is acceptable to add *test-only* behavior behind explicit UI testing flags ONLY if:
  - It does not change data, persistence, or user flows.
  - It does not change hit testing/gestures/navigation structure.
  - It is limited to layout density/animation timing and clearly labeled.
  - Agents may add UI-test-only Core Data store switching and deterministic seeding via launch arguments, provided production behavior is unchanged when flags are absent.
Accessibility identifier rules:
- Identifiers that tests rely on MUST be attached to a stable, top-level element representing the semantic row/container.
- Avoid attaching identifiers to text nodes that may be merged/combined away.
- Avoid duplicate identifiers in the subtree.

Scrolling rules:
- Never implement “find element then scroll to it” if the element may not exist before scroll (common in SwiftUI List/Lazy stacks).
- Prefer: “scroll container until an element with identifier exists (or timeout)”.

----------------------------------------------------------------
OUTPUT FORMAT

When generating code, use this structure:

### Files Modified
- FileName.swift
- FileName.swift

### Changes Made
- Concise description of what changed and why

### Assumptions
- Any assumptions made due to missing context

### Known Limitations
- Anything intentionally not addressed

----------------------------------------------------------------
MEMORY AND CONTINUITY

Codex does not retain memory across runs.

Therefore:
- Do not assume prior instructions persist
- Re-read AGENTS.md and repo context every run
- Re-verify existing helpers and patterns before adding new ones

----------------------------------------------------------------
XCODEBUILD CONFIGURATION

If asked to run xcodebuild:
- Use Offshore.xcodeproj
- Path: /OffshoreBudgeting
- Scheme: OffshoreBudgeting
- Destination: iPhone 16, osVersion: iOS 18.5

----------------------------------------------------------------
CODING GUIDELINES

- Prefer clarity over abstraction
- Avoid creating helpers used only once
- Check for existing helpers before adding new ones
- Match existing patterns exactly when extending functionality
- Keep methods small and purpose-driven
- Preserve existing comments and MARK sections, and add/update // MARK sections as new code is implemented

----------------------------------------------------------------
OS AND PLATFORM SUPPORT

- Latest OS target: iOS/iPadOS/macOS 26.x
- Minimum supported: iOS/iPadOS/macOS 16.x

Rules:
- Liquid Glass UI only for OS 26
- Legacy OSes must receive stable, simple, consistent UI
- Use availability checks, not device checks, unless specifically directed or outlined in the plan to do so

----------------------------------------------------------------
UI AND DESIGN SYSTEM RULES

- Use existing layout environment values where present
- Maintain consistent spacing, padding, and typography
- Avoid hard-coded sizes unless required
- Avoid visual-only meaning without semantic backing
- Accessibility is a requirement, not an enhancement

----------------------------------------------------------------
CORE DATA AND MODEL SAFETY

- Do NOT modify the Core Data schema unless explicitly instructed
- Respect existing entity and relationship names
- Centralize fetch logic in service files when that pattern exists
- Avoid introducing fetch logic directly into views unless already established

----------------------------------------------------------------
LOGGING AND ERROR HANDLING

- Use existing alert and logging helpers
- Do NOT introduce print statements, unless debugging is required to find the cause of an error
- Do NOT change error-handling behavior unless instructed

----------------------------------------------------------------
COMMIT STYLE FOR TOOL-GENERATED CHANGES

- Conventional subject:
  feat(view): short description
  fix(service): short description

- Body must include:
  - Files touched
  - Reason for change
  - Any notable constraints or risks

----------------------------------------------------------------
STOP CONDITIONS (MANDATORY)

Agents MUST STOP if:
- The project does not compile
- Behavior would change unintentionally
- Scope expansion is required
- A refactor would be necessary
- Documentation is insufficient to proceed safely
- A test still fails after 3 attempts to fix or rerun it

In these cases, explain clearly and wait for instruction.






## Repository overview

```
./
Offshore.xcodeproj/
OffshoreBudgeting/
  AGENTS.md
  AppIcon.icon/
  Assets.xcassets/
  ContentView.swift
  Info.plist
  OffshoreBudgeting.entitlements
  OffshoreBudgetingApp.swift
  OffshoreBudgetingModel.xcdatamodeld/
  Models/
  Resources/
  Screenshots/
  Services/
  Support/
  Systems/
  Testing/
  View Models/
  Views/
```

## Important files by role

### Views (SwiftUI / UI)
- OffshoreBudgeting/ContentView.swift — ContentView
- OffshoreBudgeting/Systems/RootTabView.swift — RootTabView
- OffshoreBudgeting/Views/HomeView.swift — HomeView2
- OffshoreBudgeting/Views/CardsView.swift — CardsView2
- OffshoreBudgeting/Views/IncomeView.swift — IncomeView2
- OffshoreBudgeting/Views/PresetsView.swift — PresetsView2
- OffshoreBudgeting/Views/SettingsView.swift — SettingsView2
- OffshoreBudgeting/Views/CardDetailView.swift — CardDetailView
- OffshoreBudgeting/Views/AddPlannedExpenseView.swift — AddPlannedExpenseView (CategoryChipsRow, AddCategoryPill)
- OffshoreBudgeting/Views/AddUnplannedExpenseView.swift — AddUnplannedExpenseView (CategoryChipsRow, AddCategoryPill)
- OffshoreBudgeting/Views/AddCardFormView.swift — AddCardFormView (ThemeSwatch)
- OffshoreBudgeting/Views/AddBudgetView.swift — AddBudgetView
- OffshoreBudgeting/Views/IncomeEditorView.swift — IncomeEditorView
- OffshoreBudgeting/Views/RecurrencePickerView.swift — RecurrencePickerView
- OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift — ExpenseCategoryManagerView, ExpenseCategoryEditorSheet, ColorCircle
- OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift — CustomRecurrenceEditorView
- OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift — PresetBudgetAssignmentSheet
- OffshoreBudgeting/Views/RenameCardSheet.swift — RenameCardSheet
- OffshoreBudgeting/Views/UBEmptyState.swift — UBEmptyState
- OffshoreBudgeting/Views/Components/CalendarNavigationButtonStyle.swift — CalendarNavigationButtonStyle
- OffshoreBudgeting/Views/Components/GlassCTAButton.swift — GlassCTAButton
- OffshoreBudgeting/Views/Components/PillSegmentedControl.swift — PillSegmentedControl
- OffshoreBudgeting/Views/Components/CategoryChipPill.swift — CategoryChipPill
- OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift — TranslucentButtonStyle
- OffshoreBudgeting/Views/Components/Buttons.swift — Buttons
- OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift — UBPresentationDetent + applyDetentsIfAvailable

### Services / Data access
- OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift
- OffshoreBudgeting/Core/Persistence/CoreDataService.swift
- OffshoreBudgeting/Services/CardService.swift
- OffshoreBudgeting/Services/BudgetService.swift
- OffshoreBudgeting/Services/ExpenseCategoryService.swift
- OffshoreBudgeting/Services/RecurrenceEngine.swift
- OffshoreBudgeting/Core/Cloud/CloudAccountStatusProvider.swift
- OffshoreBudgeting/Services/PlannedExpenseService.swift
- OffshoreBudgeting/Services/IncomeService.swift
- OffshoreBudgeting/Services/UnplannedExpenseService.swift
- OffshoreBudgeting/Core/Persistence/CoreDataRepository.swift

### Models / Entities
- OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift — AddIncomeFormViewModel
- OffshoreBudgeting/View Models/CardsViewModel.swift — CardsViewModel
- OffshoreBudgeting/View Models/HomeViewModel.swift — HomeViewModel
- OffshoreBudgeting/View Models/CardDetailViewModel.swift — CardDetailViewModel
- OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift — AddPlannedExpenseViewModel
- OffshoreBudgeting/View Models/SettingsViewModel.swift — SettingsViewModel
- OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift — AddUnplannedExpenseViewModel
- OffshoreBudgeting/View Models/BudgetDetailsViewModelStore.swift — BudgetDetailsViewModelStore
- OffshoreBudgeting/View Models/AddBudgetViewModel.swift — AddBudgetViewModel
- OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift — BudgetDetailsViewModel
- OffshoreBudgeting/View Models/IncomeScreenViewModel.swift — IncomeScreenViewModel
- OffshoreBudgeting/Models/CardItem.swift — CardItem
- OffshoreBudgeting/Models/BudgetPeriod.swift — BudgetPeriod

### Systems / Environment / Helpers
- OffshoreBudgeting/Systems/MetallicTextStyles.swift — types: UBTypography, UBDecor
- OffshoreBudgeting/Core/Config/AppSettings.swift — types: AppSettingsKeys
- OffshoreBudgeting/Systems/ScrollViewInsetAdjustment.swift — types: UBScrollViewInsetAdjustmentDisabler
- OffshoreBudgeting/Systems/PlatformCapabilities.swift — types: PlatformCapabilities, PlatformCapabilitiesKey
- OffshoreBudgeting/Systems/Compatibility.swift — types: UBListStyleLiquidAwareModifier, UBListStyleSeparators, UBPreOS26ListRowBackgroundModifier, UBRootNavigationChromeModifier, UBNavigationBackgroundModifier, UBHorizontalBounceDisabler
- OffshoreBudgeting/Systems/IncomeCalendarPalette.swift — types: UBMonthLabel, UBDayView, UBWeekdayLabel, UBWeekdaysView
- OffshoreBudgeting/Systems/DesignSystem+Motion.swift — types: Motion
- OffshoreBudgeting/Systems/DesignSystem.swift — types: DesignSystem, Spacing, Radius
- OffshoreBudgeting/Systems/SafeAreaInsetsCompatibility.swift — types: UBSafeAreaInsetsEnvironmentKey, UBSafeAreaInsetsPreferenceKey, UBSafeAreaInsetsReader
- OffshoreBudgeting/Systems/MotionSupport.swift — types: MotionMonitor
- OffshoreBudgeting/Systems/CardTheme.swift — types: CardTheme, BackgroundPattern, DiagonalStripesOverlay, CrossHatchOverlay, GridOverlay
- OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift — types: ResponsiveLayoutContext, Idiom, ResponsiveLayoutContextKey, ResponsiveLayoutReader, LegacySafeAreaCapture
- OffshoreBudgeting/Core/Theme/AppTheme.swift — types: NotificationCenterAdapter, CloudSyncPreferences, AppTheme, TabBarPalette, GlassConfiguration
- OffshoreBudgeting/Systems/OnboardingEnvironment.swift — types: OnboardingPresentationKey
- OffshoreBudgeting/Systems/CardAppearanceStore.swift — types: CardAppearanceStore
- OffshoreBudgeting/Systems/SystemTheme.swift — types: SystemThemeAdapter, Flavor
- OffshoreBudgeting/Systems/RootTabView.swift — types: RootTabView, Tab, MacToolbarBackgroundModifier, MacRootTabBar, MacTabLabel
  (Removed: DesignSystem+Typography.swift, DesignSystem+Decor.swift, HomeHeaderLayoutEnvironment.swift)

## Conventions and constraints

- Preserve naming, structure, and // MARK organization already in the code.
- Prefer small, isolated changes. Avoid refactors unless explicitly requested.
- Keep platform behavior consistent across iOS, iPadOS, and macOS Catalyst when editing UI.
- Avoid adding dependencies without prior approval.

## How to read the code using // MARK and comments

Use the following // MARK anchors to understand intent and safe insertion points. Only add new // MARK sections if needed for clarity.

**OffshoreBudgeting/OffshoreBudgetingApp.swift**
- // MARK: Dependencies
- // MARK: Onboarding State
- // MARK: Init

**OffshoreBudgeting/View Models/AddIncomeFormViewModel.swift**
- // MARK: - AddIncomeFormViewModel
- // MARK: Inputs / Identity
- // MARK: Editing State
- // MARK: Core Fields
- // MARK: Recurrence
- // MARK: Currency
- // MARK: Validation
- // MARK: Init
- // MARK: Load
- // MARK: Save
- // MARK: Parsing & Formatting
- // MARK: Errors
- // MARK: - Safe KVC helpers for schema drift

**OffshoreBudgeting/View Models/CardsViewModel.swift**
- // MARK: - CardsLoadState
- // MARK: - CardsViewAlert
- // MARK: - CardsViewModel
- // MARK: Published State
- // MARK: Dependencies
- // MARK: Combine
- // MARK: Init
- // MARK: startIfNeeded()
- // MARK: refresh()
- // MARK: configureAndStartObserver()
- // MARK: addCard(name:theme:)
- // MARK: promptRename(for:)
- // MARK: rename(card:to:)
- // MARK: requestDelete(card:)
- // MARK: confirmDelete(card:)
- // MARK: edit(card:name:theme:)
- // MARK: reapplyThemes()

**OffshoreBudgeting/View Models/HomeViewModel.swift**
- // MARK: - BudgetLoadState
- // MARK: - HomeViewAlert
- // MARK: - BudgetSummary (View Model DTO)
- // MARK: Identity
- // MARK: Budget Basics
- // MARK: Variable Spend (Unplanned) by Category
- // MARK: Planned Expenses (line items attached to budget)
- // MARK: Income (date-based; no relationship)
- // MARK: Savings
- // MARK: Convenience
- // MARK: - Month (Helper)
- // MARK: start(of:)
- // MARK: end(of:)
- // MARK: range(for:)
- // MARK: - HomeViewModel
- // MARK: Published State
- // MARK: Dependencies
- // MARK: init()
- // MARK: startIfNeeded()
- // MARK: refresh()

**OffshoreBudgeting/View Models/CardDetailViewModel.swift**
- // MARK: - CardCategoryTotal
- // MARK: - CardExpense
- // MARK: - CardDetailLoadState
- // MARK: - CardDetailViewModel
- // MARK: Inputs
- // MARK: Services
- // MARK: Outputs
- // MARK: Init
- // MARK: load()

**OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift**
- // MARK: - AddPlannedExpenseViewModel
- // MARK: Dependencies
- // MARK: Identity
- // MARK: Loaded Data
- // MARK: Form State
- // MARK: Init
- // MARK: load()
- // MARK: Validation
- // MARK: save()
- // MARK: Private fetch

**OffshoreBudgeting/View Models/SettingsViewModel.swift**
- // MARK: - SettingsViewModel
- // MARK: - Init
- // MARK: - Cross-Platform Colors
- // MARK: - SettingsIcon
- // MARK: - SettingsCard
- // MARK: - SettingsRow

**OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift**
- // MARK: - AddUnplannedExpenseViewModel
- // MARK: Dependencies
- // MARK: Identity
- // MARK: Loaded Data
- // MARK: Allowed filter (e.g., only cards tracked by a given budget)
- // MARK: Preselection
- // MARK: Live Updates
- // MARK: Form State
- // MARK: Init
- // MARK: load()
- // MARK: Validation
- // MARK: Parsed Amount
- // MARK: save()
- // MARK: Private fetch

**OffshoreBudgeting/View Models/AddBudgetViewModel.swift**
- // MARK: - AddBudgetViewModel
- // MARK: Inputs (bound to UI)
- // MARK: Loaded Data (Core Data)
- // MARK: Selections
- // MARK: Dependencies
- // MARK: Editing
- // MARK: Init
- // MARK: Validation
- // MARK: load()
- // MARK: save()
- // MARK: - Private (ADD)
- // MARK: - Private (EDIT)
- // MARK: Private fetch helpers

**OffshoreBudgeting/View Models/BudgetDetailsViewModel.swift**
- // MARK: - BudgetDetailsViewModel
- // MARK: Inputs
- // MARK: Core Data
- // MARK: Filter/Search/Sort
- // MARK: Date Window
- // MARK: Sort
- // MARK: Loaded data (raw)
- // MARK: Summary
- // MARK: Derived filtered/sorted
- // MARK: Init
- // MARK: Public API
- // MARK: - Fetch helpers

**OffshoreBudgeting/View Models/IncomeScreenViewModel.swift**
- // MARK: - IncomeScreenViewModel
- // MARK: Public, @Published
- // MARK: Private
- // MARK: Init
- // MARK: Titles
- // MARK: Loading
- // MARK: CRUD
- // MARK: Formatting
- // MARK: Events Summary
- // MARK: - Event Cache Management
- // MARK: - Currency NumberFormatter

**OffshoreBudgeting/Core/Sync/CoreDataEntityChangeMonitor.swift**
- // MARK: - CoreDataEntityChangeMonitor
- // MARK: Private
- // MARK: Init

**OffshoreBudgeting/Resources/CoreDataListObserver.swift**
- // MARK: - CoreDataListObserver
- // MARK: Stored
- // MARK: Init
- // MARK: start()
- // MARK: stop()
- // MARK: NSFetchedResultsControllerDelegate

**OffshoreBudgeting/Resources/BudgetIncomeCalculator.swift**
- // MARK: - BudgetIncomeCalculator
- // MARK: Fetch
- // MARK: Sum
- // MARK: Totals Bucket
- // MARK: Helpers

<!-- Removed: OffshoreBudgeting/Resources/Color+Hex.swift -->

**OffshoreBudgeting/Resources/PlannedExpenseService+Templates.swift**
- // MARK: - PlannedExpenseService + Templates
- // MARK: Fetch Global Templates
- // MARK: Fetch Children
- // MARK: Ensure Child (Assign)
- // MARK: Remove Child (Unassign)
- // MARK: Child Lookup
- // MARK: Fetch Budgets (helper)
- // MARK: Delete Template + Children
- // MARK: Update Template + Propagate
- // MARK: Update Child + Optionally Parent/Future Siblings

**OffshoreBudgeting/Resources/RecurrenceRule.swift**
- // MARK: - Weekday
- // MARK: - RecurrenceRule
- // MARK: Builder Output
- // MARK: RRULE Generation
- // MARK: Parse (best-effort)
- // MARK: Utilities

**OffshoreBudgeting/Resources/SaveError.swift**
- // MARK: - SaveError
- // MARK: Cases
- // MARK: Identifiable
- // MARK: Presentation
- // MARK: Bridging
- // MARK: Pretty Printer for Core Data

**OffshoreBudgeting/Resources/CardItem+CoreDataBridge.swift**
- // MARK: - CardItem + Core Data Bridge
- // MARK: init(from:appearanceStore:)

**OffshoreBudgeting/Resources/NotificationName+Extensions.swift**
- // MARK: - App Notification Names
- // MARK: - dataStoreDidChange
<!-- Removed: // MARK: - dataStoreDidChangeRemotely -->


**OffshoreBudgeting/Resources/HolographicMetallicText.swift**
- // MARK: - HolographicMetallicText
- // MARK: Inputs
- // MARK: Motion
- // MARK: Body
- // MARK: Base title (dark + readable across platforms)
- // MARK: Overlays (masked to text)
- // MARK: - Motion → Parameters
- // MARK: Metallic Overlay Opacity
- // MARK: Shine Overlay Opacity
- // MARK: Shine Intensity
- // MARK: Metallic Angle
- // MARK: Shine Angle

<!-- Removed: OffshoreBudgeting/Resources/AddIncomeFormView+Lifecycle.swift -->

**OffshoreBudgeting/Resources/UnifiedSwipeActions.swift**
- // MARK: - UnifiedSwipeConfig
- // MARK: Platform Defaults
- // MARK: - UnifiedSwipeCustomAction
- // MARK: - UnifiedSwipeActionsModifier
- // MARK: Buttons
- // MARK: - Label
- // MARK: - Helpers
- // MARK: - View Extension
- // MARK: - Helpers
- // MARK: - Color Helpers

**OffshoreBudgeting/Models/CardItem.swift**
- // MARK: - CardItem (UI Model)
- // MARK: Identity
- // MARK: Display
- // MARK: Identifiable

**OffshoreBudgeting/Systems/MetallicTextStyles.swift**
- UBTypography: cardTitleStatic, cardTitleShadowColor
- UBDecor: metallicSilverLinear, holographicGradient, holographicShine, metallicShine

**OffshoreBudgeting/Core/Config/AppSettings.swift**
- // MARK: - AppSettingsKeys

**OffshoreBudgeting/Systems/PlatformCapabilities.swift**
- // MARK: - Environment support

**OffshoreBudgeting/Systems/Compatibility.swift**
- // MARK: - SwiftUI View Extensions (Cross-Platform)
- // MARK: ub_rootNavigationChrome()
- // MARK: ub_cardTitleShadow()
- // MARK: ub_surfaceBackground()
- // MARK: ub_navigationBackground()
- // MARK: ub_disableHorizontalBounce()
- // MARK: ub_listStyleLiquidAware()
- // MARK: ub_preOS26ListRowBackground(_:)
- // MARK: - Internal Modifiers (List Styling)
- // MARK: - List Separators Helper
- // MARK: - Private Modifiers
  (Removed wrappers: ub_noAutoCapsAndCorrection, ub_decimalKeyboard, ub_tabNavigationTitle, ub_toolbarTitleInline, ub_toolbarTitleLarge, ub_sheetPadding, ub_onChange, ub_compactDatePickerStyle, ub_formStyleGrouped, ub_pickerBackground, ub_hideScrollIndicators, ub_chromeBackground, ub_glassBackground)
  (Removed UBChromeBackgroundModifier, UBOnChange* modifiers, and UBGlassBackgroundView)

**OffshoreBudgeting/Systems/HomeHeaderLayoutEnvironment.swift**
- // MARK: - Environment Key

**OffshoreBudgeting/Systems/IncomeCalendarPalette.swift**
- // MARK: - Month title (e.g., "August 2025")
- // MARK: - Day cell with income summaries
- // MARK: - Weekday label (M T W T F S S)
- // MARK: - Weekdays row

**OffshoreBudgeting/Systems/DesignSystem+Motion.swift**
- // MARK: Card Background Tuning

**OffshoreBudgeting/Systems/DesignSystem.swift**
- // MARK: Platform Color Imports
- // MARK: - DesignSystem (Tokens)
- // MARK: Spacing (pts)
- // MARK: Corner Radii
- // MARK: Colors
- // MARK: System‑Aware Container Background
- // MARK: Chip and Pill Fills
  (Removed legacy Shadows and cardBackground helper)

// DS.Decor was removed; use MetallicTextStyles.swift

**OffshoreBudgeting/Systems/MotionSupport.swift**
- // MARK: - MotionMonitor
- // MARK: Singleton
- // MARK: Raw Motion (unscaled)
- // MARK: Smoothed / Scaled for display (use these for backgrounds)
- // MARK: Config
- // MARK: Provider
- // MARK: Init
- // MARK: start()
- // MARK: stop()
- // MARK: updateTuning(smoothing:scale:)

**OffshoreBudgeting/Systems/CardTheme.swift**
- // MARK: - Platform Color Bridge
- // MARK: - Helper: labelCGColor(_:)
- // MARK: - CardTheme
- // MARK: Display Name
- // MARK: Base Colors
- // MARK: Stripe Overlay Color (legacy compat)
- // MARK: Glow Color
- // MARK: Gradient (tilt-aware)
- // MARK: - BackgroundPattern
- // MARK: CardTheme → BackgroundPattern mapping
- // MARK: - CardTheme.Pattern Overlay
- // MARK: - Pattern Implementations (SwiftUI-only; iOS/macOS)
- // MARK: DiagonalStripesOverlay
- // MARK: CrossHatchOverlay
- // MARK: GridOverlay
- // MARK: DotsOverlay
- // MARK: NoiseOverlay

**OffshoreBudgeting/Core/Theme/AppTheme.swift**
- // MARK: - Cloud Sync Infrastructure
- // MARK: - AppTheme
- // MARK: - AppTheme.GlassConfiguration
- // MARK: - Color Utilities
- // MARK: - ThemeManager

**OffshoreBudgeting/Systems/CardAppearanceStore.swift**
- // MARK: - CardAppearanceStore
- // MARK: Singleton
- // MARK: Storage Backbone
- // MARK: Init
- // MARK: load()
- // MARK: save()
- // MARK: theme(for:)
- // MARK: setTheme(_:for:)
- // MARK: removeTheme(for:)

**OffshoreBudgeting/Views/PresetsView.swift**
- // MARK: - PresetsView
- // MARK: Dependencies
- // MARK: State
- // MARK: Body
- // MARK: Empty State — standardized with UBEmptyState (same as Home/Cards)
- // MARK: Non-empty List
- // MARK: Data lifecycle
- // MARK: Add Preset Sheet
- // MARK: Assign Budgets Sheet
- // MARK: Edit Template Sheet
- // MARK: - Actions
- // MARK: - AddGlobalPlannedExpenseSheet
- // MARK: Callbacks
- // MARK: Env
- // MARK: Body
- // MARK: - Array Safe Indexing
- // MARK: - ViewModel + Helpers
- // MARK: - PresetListItem
- // MARK: Identity
- // MARK: Display

**OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift**
- // MARK: - CustomRecurrence
- // MARK: - CustomRecurrenceEditorView
- // MARK: Inputs
- // MARK: State
- // MARK: Init
- // MARK: Body
- // MARK: Subviews
- // MARK: - AddIncomeFormViewModel (Custom Hook)

**OffshoreBudgeting/Views/SettingsView.swift**
- // MARK: - SettingsView
- // MARK: Dependencies
- // MARK: - Helpers
- // MARK: General Hero Card
- // MARK: Appearance Card
- // MARK: Sync Card (disabled)
- // MARK: Calendar Card
- // MARK: Presets Card
- // MARK: Expenses Card (with sub-page)
- // MARK: Help Card
- // MARK: Onboarding Card
- // MARK: Reset Card
- // MARK: - Platform-Safe Modifiers
- // MARK: applyInlineNavTitleOnIOS()

**OffshoreBudgeting/Views/RenameCardSheet.swift**
- // MARK: - RenameCardSheet
- // MARK: State
- // MARK: body
- // MARK: Name field
- // MARK: Helpers

**OffshoreBudgeting/Views/PresetRowView.swift**
- // MARK: - PresetRowView
- // MARK: Inputs
- // MARK: Body
- // MARK: Left Column (Title + Planned/Actual)
- // MARK: Right Column (Assigned Budgets + Next Date)
- // MARK: - LabeledAmountBlock

**OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift**
- // MARK: - ExpenseCategoryManagerView
- // MARK: Dependencies
- // MARK: Sorting (extracted to avoid heavy type inference)
- // MARK: Fetch Request
- // MARK: UI State
- // MARK: - Body
- // MARK: - Row Builders
- // MARK: - Empty State
- // MARK: - CRUD
- // MARK: - Availability Helpers
- // MARK: - ExpenseCategoryEditorSheet
- // MARK: Environment
- // MARK: State
- // MARK: Callback
- // MARK: Init
- // MARK: Body
- // MARK: Helper: Color -> Hex
- // MARK: - ColorCircle
- // MARK: Utility

**OffshoreBudgeting/Views/UBEmptyState.swift**
- // MARK: - UBEmptyState
- // MARK: Content
- // MARK: Actions
- // MARK: Layout
- // MARK: init(...)
- // MARK: Body
- // MARK: Icon
- // MARK: Title
- // MARK: Message
- // MARK: Primary CTA (optional)
- // MARK: Primary Button Helpers

**OffshoreBudgeting/Views/HomeView.swift**
- // MARK: - HomeView
- // MARK: State & ViewModel
- // MARK: Add Budget Sheet
- // MARK: Header Layout
- // MARK: Body
- // MARK: ADD SHEET — present new budget UI for the selected period
- // MARK: Empty-state: Create budget (+)
- // MARK: New: Standalone glass buttons for empty state header
- // MARK: Sheets & Alerts
- // MARK: Content Container
- // MARK: Empty Period Shell (replaces generic empty state)
- // MARK: Helpers
- // MARK: Empty-period CTA helpers
- // MARK: - Home Header Primary Summary
- // MARK: - Fallback header when no budget exists
- // MARK: - Zero summary grid for empty periods
- // MARK: - Section header + total row
- // MARK: - Empty shell helpers (glass capsule + segmented sizing)
- // MARK: - Home Header Summary
- // MARK: - Header Control Width Matching

**OffshoreBudgeting/Views/AddBudgetView.swift**
- // MARK: - AddBudgetView
- // MARK: Environment
- // MARK: Inputs
- // MARK: VM
- // MARK: Local UI State
- // MARK: Init (ADD)
- // MARK: Init (EDIT)
- // MARK: Body
- // MARK: Standardized Sheet Chrome
- // MARK: Form Content (standardized)
- // MARK: Actions

**OffshoreBudgeting/Views/CardTileView.swift**
- // MARK: - CardTileView
- // MARK: Inputs
- // MARK: Layout
- // MARK: Body
- // MARK: Card Background (STATIC gradient + pattern)
- // MARK: Title (Metallic shimmer stays)
- // MARK: - Computed Views
- // MARK: Background Gradient (STATIC)
- // MARK: Selection Ring (always visible, not clipped)
- // MARK: Selection Glow (soft, outside)
- // MARK: Thin Edge
- // MARK: Title builder

**OffshoreBudgeting/Views/NoCardTile.swift**
- // MARK: Inputs
- // MARK: Layout
- // MARK: - Overlays

**OffshoreBudgeting/Views/AddPlannedExpenseView.swift**
- // MARK: - AddPlannedExpenseView
- // MARK: Inputs
- // MARK: State
- // MARK: Layout
- // MARK: Init
- // MARK: Body
- // MARK: Card Selection
- // MARK: Budget Assignment
- // MARK: Category Selection
- // MARK: Individual Fields
- // MARK: Use in future budgets?
- // MARK: Lifecycle
- // MARK: Actions
- // MARK: - CategoryChipsRow
- // MARK: - AddCategoryPill
- // MARK: - CategoryChip

**OffshoreBudgeting/Views/IncomeEditorView.swift**
- // MARK: - IncomeEditorMode
- // MARK: - IncomeEditorAction
- // MARK: - Editor Form Model
- // MARK: RecurrenceOption
- // MARK: - IncomeEditorView
- // MARK: Inputs
- // MARK: State
- // MARK: Init
- // MARK: Body
- // MARK: Details
- // MARK: Recurrence
- // MARK: Labels
- // MARK: Validation
- // MARK: Amount Field
- // MARK: Save Handler
- // MARK: Initial Form

**OffshoreBudgeting/Views/RecurrencePickerView.swift**
- // MARK: - RecurrencePickerView
- // MARK: Bindings
- // MARK: Local State (UI)
- // MARK: Preset Options
- // MARK: Init
- // MARK: Body
- // MARK: Behavior
- // MARK: Subviews

**OffshoreBudgeting/Views/AddCardFormView.swift**
- // MARK: - AddCardFormView
- // MARK: Mode
- // MARK: Configuration
- // MARK: Inputs
- // MARK: Init
- // MARK: Local State
- // MARK: Computed
- // MARK: - Body
- // MARK: Standardized Sheet Chrome (matches Add Budget)
- // MARK: Form Content (standardized)
- // MARK: Cross-platform placeholder handling
- // MARK: - Actions
- // MARK: saveTapped()
- // MARK: - ThemeSwatch

**OffshoreBudgeting/Views/CardPickerRow.swift**
- // MARK: - CardPickerRow
- // MARK: Inputs
- // MARK: Layout
- // MARK: Body
- // MARK: Bridge Core Data → UI model
- // MARK: On Tap → Select for Expense

**OffshoreBudgeting/Views/CardPickerItemTile.swift**
- // MARK: - CardPickerItemTile
- // MARK: Inputs
- // MARK: Layout Constants
- // MARK: Body

**OffshoreBudgeting/Views/HelpView.swift**
- // MARK:` comments across the codebase so users can
- // MARK: Getting Started
- // MARK: Core Screens
- // MARK: Tips & Tricks
- // MARK: Getting Started
- // MARK: Core Screens
- // MARK: Tips & Tricks
- // MARK: Getting Started
- // MARK: Core Screens
- // MARK: Tips & Tricks
- // MARK: - Pages

**OffshoreBudgeting/Views/IncomeView.swift**
- // MARK: - IncomeView
- // MARK: State
- // MARK: Environment
- // MARK: View Model
- // MARK: Calendar
- // MARK: Body
- // MARK: Present Add Income Form
- // MARK: Present Edit Income Form (triggered by non-nil `editingIncome`)
- // MARK: - Calendar Section
- // MARK: Double-click calendar to add income (macOS)
- // MARK: - Weekly Summary Bar
- // MARK: - Selected Day Section (WITH swipe to delete & edit)
- // MARK: Section Title — Selected Day
- // MARK: - Calendar Navigation Helpers
- // MARK: - Edit Flow Helpers
- // MARK: - Formatting Helpers
- // MARK: - Delete Handler
- // MARK: - IncomeRow
- // MARK: Properties
- // MARK: Body

**OffshoreBudgeting/Views/AddUnplannedExpenseView.swift**
- // MARK: - AddUnplannedExpenseView
- // MARK: Inputs
- // MARK: State
- // MARK: - Layout
- // MARK: Init
- // MARK: Body
- // MARK: Card Picker (horizontal)
- // MARK: Category Chips Row
- // MARK: Individual Fields
- // MARK: - trySave()
- // MARK: - CategoryChipsRow
- // MARK: Binding
- // MARK: Environment
- // MARK: Live Fetch
- // MARK: Local State
- // MARK: Static Add Button (doesn't scroll)
- // MARK: Scrolling Chips
- // MARK: - AddCategoryPill
- // MARK: - CategoryChip

**OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift**
- UBPresentationDetent (compat wrapper)
- View.applyDetentsIfAvailable(detents:selection:) — applies presentationDetents on iOS 16+ with a safe no-op fallback

**OffshoreBudgeting/Views/BudgetDetailsView.swift**
- // MARK: - BudgetDetailsView
- // MARK: Inputs
- // MARK: View Model
- // MARK: Theme
- // MARK: UI State
- // MARK: Layout
- // MARK: Init
- // MARK: Body
- // MARK: Lists
- // MARK: Add Sheets
- // MARK: Helpers
- // MARK: - Scrolling List Header Content
- // MARK: - Combined Budget Header Grid (aligns all numeric totals)
- // MARK: - SummarySection
- // MARK: - CategoryTotalsRow
- // MARK: - FilterBar (unchanged API)
- // MARK: - Shared Glass Capsule Container
- // MARK: - PlannedListFR (List-backed; swipe enabled)
- // MARK: Environment for deletes
- // MARK: Compact empty state (single Add button)

**OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift**
- // MARK: - PresetBudgetAssignmentSheet
- // MARK: Environment
- // MARK: Inputs
- // MARK: State
- // MARK: Body
- // MARK: Toolbar Buttons
- // MARK: - Navigation container (iOS 16+/macOS 13+ NavigationStack; older NavigationView)
- // MARK: - Load
- // MARK: - Membership Utilities
- // MARK: - Save
- // MARK: - Formatting


**OffshoreBudgeting/Views/CardsView.swift**
- // MARK: - CardsView
- // MARK: State & Dependencies
- // MARK: Selection State
- // MARK: Grid Layout
- // MARK: Layout Constants
- // MARK: Body
- // MARK: Start observing when view appears
- // MARK: App Toolbar
- // MARK: Add Sheet
- // MARK: Edit Sheet
- // MARK: Alerts
- // MARK: - Content View (Type-Safe)
- // MARK: Loading View
- // MARK: Empty View
- // MARK: Grid View
- // MARK: On Tap → Select Card
- // MARK: Keep selection valid when dataset changes (delete/rename)
- // MARK: - Tiny shimmer for placeholder

**OffshoreBudgeting/Views/OnboardingView.swift**
- // MARK: - OnboardingView
- // MARK: AppStorage
- // MARK: Step
- // MARK: - Body
- // MARK: - WelcomeStep
- // MARK: - ThemeStep
- // MARK: ThemePreviewTile
- // MARK: - CardsStep
- // MARK: - Navigation container compatibility
- // MARK: - PresetsStep
- // MARK: - CloudSyncStep
- // MARK: - CategoriesStep
- // MARK: - Navigation container compatibility
- // MARK: - LoadingStep
- // MARK: - Shared Components

**OffshoreBudgeting/Views/CardDetailView.swift**
- // MARK: - CardDetailView
- // MARK: Inputs
- // MARK: State
- // MARK: Init
- // MARK: Body
- // MARK: content
- // MARK: navigationContainer
- // MARK: totalsSection
- // MARK: categoryBreakdown
- // MARK: expensesList
- // MARK: - ExpenseRow
- // MARK: - Shared Toolbar Icon

**OffshoreBudgeting/Views/AddIncomeFormView.swift**
- // MARK: - AddIncomeFormView
- // MARK: Environment
- // MARK: Inputs
- // MARK: State
- // MARK: Init
- // MARK: Body
- // MARK: Standardized Sheet Chrome
- // MARK: Form Content
- // MARK: Eager load (edit) / Prefill date (add)
- // MARK: Sections
- // MARK: Type
- // MARK: Source
- // MARK: Amount
- // MARK: First Date
- // MARK: Recurrence
- // MARK: Save
- // MARK: Utilities

**OffshoreBudgeting/Views/Components/CalendarNavigationButtonStyle.swift**
- // MARK: - Layers
- // MARK: - Colors

**OffshoreBudgeting/Views/Components/RootHeaderActions.swift**
- // MARK: - Shared Metrics
- // MARK: - Icon Content
- // MARK: - Action Button Style
- // MARK: - Optional Accessibility Identifier
- // MARK: - Header Glass Controls (iOS + macOS)
- // MARK: - Convenience Icon Button

**OffshoreBudgeting/Views/Components/PeriodNavigationControl.swift**
- // MARK: - Properties
- // MARK: - Init
- // MARK: - Body
- // MARK: - Typography Helpers
- // MARK: - Button Styling Helpers

**OffshoreBudgeting/Views/Components/RootTabHeader.swift**
- // MARK: Properties
- // MARK: Init
- // MARK: Body

**OffshoreBudgeting/Views/Components/RootTabPageScaffold.swift**
- // MARK: Scroll Behaviour
- // MARK: Width Constraints
- // MARK: Inputs
- // MARK: Environment
- // MARK: State
- // MARK: Init
- // MARK: Body
- // MARK: Stack Content
- // MARK: Height Tracking
- // MARK: - RootTabPageProxy
- // MARK: - Preference Infrastructure
- // MARK: - Padding Helpers

**OffshoreBudgeting/Core/Persistence/CoreDataService.swift**
- // MARK: - CoreDataService
- // MARK: Singleton
- // MARK: Configuration
- // MARK: Load State
- // MARK: Change Observers
- // MARK: Persistent Container
- // MARK: Store Options
- // MARK: Contexts
- // MARK: Lifecycle
- // MARK: Post-Load Configuration
- // MARK: Change Observation
- // MARK: Save
- // MARK: Background Task
- // MARK: Await Stores Loaded (Tiny helper)
- // MARK: - Reset
- // MARK: - Cloud Sync Preferences
- // MARK: - Private Helpers

**OffshoreBudgeting/Services/CardService.swift**
- // MARK: - CardService
- // MARK: Properties
- // MARK: Init
- // MARK: fetchAllCards(sortedByName:)
- // MARK: fetchCards(forBudgetID:)
- // MARK: findCard(byID:)
- // MARK: countCards(named:)
- // MARK: createCard(name:ensureUniqueName:attachToBudgetIDs:)
- // MARK: renameCard(_:to:)
- // MARK: updateCard(_:name:)
- // MARK: deleteCard(_:)
- // MARK: deleteAllCards()
- // MARK: attachCard(_:toBudgetsWithIDs:)
- // MARK: detachCard(_:fromBudgetsWithIDs:)
- // MARK: replaceCard(_:budgetsWithIDs:)

**OffshoreBudgeting/Services/BudgetService.swift**
- // MARK: - BudgetService
- // MARK: Properties
- // MARK: fetchAllBudgets(sortByStartDateDescending:)
- // MARK: findBudget(byID:)
- // MARK: fetchActiveBudget(on:)
- // MARK: createBudget(...)
- // MARK: updateBudget(_:name:dates:isRecurring:recurrenceType:recurrenceEndDate:parentID:)
- // MARK: deleteBudget(_:)
- // MARK: projectedDates(for:in:)

**OffshoreBudgeting/Services/ExpenseCategoryService.swift**
- // MARK: - ExpenseCategoryService
- // MARK: Properties
- // MARK: fetchAllCategories(sortedByName:)
- // MARK: findCategory(byID:)
- // MARK: findCategory(named:)
- // MARK: addCategory(name:color:ensureUniqueName:)
- // MARK: updateCategory(_:name:color:)
- // MARK: deleteCategory(_:)
- // MARK: deleteAllCategories()

**OffshoreBudgeting/Services/RecurrenceEngine.swift**
- // MARK: - Keyword Handling
- // MARK: - RRULE Handling
- // MARK: - Core Stride Helpers
- // MARK: - Utilities
- // MARK: - Persistence Helpers (Income)

**OffshoreBudgeting/Core/Cloud/CloudAccountStatusProvider.swift**
- // MARK: Shared Instance
- // MARK: Availability State
- // MARK: Init
- // MARK: Public API
- // MARK: Private Helpers
- // MARK: - CloudAvailabilityProviding

**OffshoreBudgeting/Services/PlannedExpenseService.swift**
- // MARK: - PlannedExpenseServiceError
- // MARK: - PlannedExpenseService
- // MARK: Singleton (for convenience across SwiftUI)
- // MARK: Properties
- // MARK: Init
- // MARK: - FETCH
- // MARK: fetchAll(sortedByDateAscending:)
- // MARK: find(byID:)
- // MARK: fetchForBudget(_:sortedByDateAscending:)
- // MARK: fetchForBudget(_:in:sortedByDateAscending:)
- // MARK: fetchForCard(_:sortedByDateAscending:)
- // MARK: fetchForCard(_:in:sortedByDateAscending:)
- // MARK: - CREATE
- // MARK: create(inBudgetID:titleOrDescription:plannedAmount:actualAmount:transactionDate:isGlobal:globalTemplateID:)
- // MARK: createGlobalTemplate(titleOrDescription:plannedAmount:defaultTransactionDate:)
- // MARK: instantiateTemplate(_:intoBudgetID:on:)
- // MARK: duplicate(_:intoBudgetID:on:)
- // MARK: - UPDATE
- // MARK: update(_:titleOrDescription:plannedAmount:actualAmount:transactionDate:isGlobal:globalTemplateID:)
- // MARK: move(_:toBudgetID:)

**OffshoreBudgeting/Services/IncomeService.swift**
- // MARK: - RecurrenceScope
- // MARK: - IncomeService
- // MARK: Types
- // MARK: Properties
- // MARK: Init
- // MARK: - CRUD
- // MARK: fetchAllIncomes(sortedByDateAscending:)
- // MARK: fetchIncomes(in:)
- // MARK: fetchIncomes(on:)
- // MARK: findIncome(byID:)
- // MARK: createIncome(...)
- // MARK: updateIncome(_:scope:...)
- // MARK: deleteIncome(_:scope:)
- // MARK: deleteAllIncomes()
- // MARK: - Calendar Helpers
- // MARK: events(in:includeProjectedRecurrences:)
- // MARK: eventsByDay(in:)
- // MARK: eventsByDay(inMonthContaining:)
- // MARK: totalAmount(in:includePlanned:)
- // MARK: - Private: Recurrence & Date Utilities

**OffshoreBudgeting/Services/UnplannedExpenseService.swift**
- // MARK: - UnplannedExpenseService
- // MARK: Types
- // MARK: Properties
- // MARK: Init
- // MARK: - FETCH
- // MARK: fetchAll(sortedByDateAscending:)
- // MARK: find(byID:)
- // MARK: fetchForCard(_:in:sortedByDateAscending:)
- // MARK: fetchForCategory(_:in:sortedByDateAscending:)
- // MARK: fetchForBudget(_:in:sortedByDateAscending:)
- // MARK: - CREATE
- // MARK: create(description:amount:date:cardID:categoryID:recurrence:recurrenceEnd:secondBiMonthlyDay:secondBiMonthlyDate:parentID:)
- // MARK: - UPDATE
- // MARK: update(_:description:amount:date:cardID:categoryID:recurrence:recurrenceEnd:secondBiMonthlyDay:secondBiMonthlyDate:parentID:)
- // MARK: - DELETE
- // MARK: delete(_:cascadeChildren:)
- // MARK: deleteAllForCard(_:)
- // MARK: - TOTALS
- // MARK: totalForCard(_:in:)
- // MARK: totalForBudget(_:in:)

**OffshoreBudgeting/Core/Persistence/CoreDataRepository.swift**
- // MARK: - CoreDataStackProviding
- // MARK: - CoreDataService + CoreDataStackProviding
- // MARK: - CoreDataRepository
- // MARK: Properties
- // MARK: Init
- // MARK: fetchAll(...)
- // MARK: fetchFirst(...)
- // MARK: count(...)
- // MARK: create(configure:)
- // MARK: delete(_:)
- // MARK: deleteAll(predicate:)
- // MARK: saveIfNeeded()
- // MARK: performBackgroundTask(_:)

## Repository Tree

** Can be found in /Offshore/repository.txt**
Use this if you cannot find a file. This was the most up-to-date tree overview as of 1/16/2026. Moving forward, if any updates are made to the repository, e.g. files moved/deleted/renamed, user advises you to also make those same changes to repository.txt for App to Tree consistency. 
