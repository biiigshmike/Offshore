Refactor Plan (Phase 2 proposal only; no code changes in Phase 1)

Safety gate
- Baseline build succeeded (see reports/build-baseline.txt).
- Use the same command for each patch: xcodebuild -project Offshore.xcodeproj -scheme OffshoreBudgeting -destination "platform=iOS Simulator,name=iPhone 16,OS=18.5" build

Ordered plan (safest -> riskiest)

1) Centralize section header typography
Goal:
- Create a single, reusable section header style to remove repeated header typography code.
Files touched (example scope):
- Add a new small helper in OffshoreBudgeting/Views/Components (e.g., SectionHeaderStyle.swift).
- Update usage in:
  - OffshoreBudgeting/Views/AddBudgetView.swift
  - OffshoreBudgeting/Views/AddCardFormView.swift
  - OffshoreBudgeting/Views/AddIncomeFormView.swift
  - OffshoreBudgeting/Views/AddPlannedExpenseView.swift
  - OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift
Why behavior should not change:
- The modifier will apply the exact same font, color, and textCase already used.
Verification:
- Build command above.
- Manual smoke: open each form and confirm header casing, weight, and color match current UI.
Rollback:
- Revert the modifier usage in the touched views.
Risk rating: Low.
Mitigations:
- Keep the modifier minimal and avoid changing layout.

2) Centralize form TextField styling
Goal:
- Unify repeated TextField prompt + autocorrect + alignment + layout modifiers.
Files touched (example scope):
- New helper in OffshoreBudgeting/Views/Components (e.g., FormTextFieldStyle.swift).
- Update in:
  - OffshoreBudgeting/Views/AddBudgetView.swift
  - OffshoreBudgeting/Views/AddCardFormView.swift
  - OffshoreBudgeting/Views/AddPlannedExpenseView.swift
  - OffshoreBudgeting/Views/AddUnplannedExpenseView.swift
  - OffshoreBudgeting/Views/RenameCardSheet.swift
  - OffshoreBudgeting/Views/AddIncomeFormView.swift
Why behavior should not change:
- The helper will apply the same set of modifiers with identical ordering.
Verification:
- Build command above.
- Manual smoke: check placeholder rendering and alignment on iOS + macOS Catalyst.
Rollback:
- Replace helper usage with the original inline modifiers.
Risk rating: Medium.
Mitigations:
- Keep modifier order identical; verify line limits and alignment per form.

3) Share CategoryChipsRow components
Goal:
- Remove duplicate CategoryChipsRow/AddCategoryPill/CategoryChip across planned/unplanned forms.
Files touched (example scope):
- Add a shared component file in OffshoreBudgeting/Views/Components/ (or reuse existing CategoryChipPill if compatible).
- Update:
  - OffshoreBudgeting/Views/AddPlannedExpenseView.swift
  - OffshoreBudgeting/Views/AddUnplannedExpenseView.swift
Why behavior should not change:
- Extracted component will be a copy of existing logic with identical parameters.
Verification:
- Build command above.
- Manual smoke: verify chip scrolling, selection, add-new-category behavior on both screens.
Rollback:
- Inline the previous local structs back into each view file.
Risk rating: Medium.
Mitigations:
- Keep layout constants and tap targets identical.

4) Standardize primary CTA button styling (glass vs fallback)
Goal:
- Consolidate repeated glassProminent/plain fallback button styling into a shared helper.
Files touched (example scope):
- Extend OffshoreBudgeting/Views/Components/Buttons.swift or add a dedicated style helper.
- Update:
  - OffshoreBudgeting/Views/HomeView.swift
  - OffshoreBudgeting/Views/SettingsView.swift
  - OffshoreBudgeting/Views/HelpView.swift
Why behavior should not change:
- The helper mirrors the existing OS-conditional styling paths.
Verification:
- Build command above.
- Manual smoke: compare primary button appearance on OS 26+ and legacy paths.
Rollback:
- Restore inlined button style logic in each view.
Risk rating: Medium.
Mitigations:
- Only centralize when the existing implementation matches exactly.

5) Formatter cache for Date/Number formatters
Goal:
- Reduce repeated formatter instantiation; centralize common formats (e.g., medium date, currency).
Files touched (example scope):
- New shared formatter cache in OffshoreBudgeting/Systems/ (or extend existing cache patterns).
- Update:
  - OffshoreBudgeting/Views/HomeView.swift
  - OffshoreBudgeting/Views/IncomeView.swift
  - OffshoreBudgeting/Views/BudgetDetailsView.swift
  - OffshoreBudgeting/Views/CardDetailView.swift
  - OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift
  - OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift
Why behavior should not change:
- Centralized formatter must be configured identically to current inline formatters.
Verification:
- Build command above.
- Manual smoke: compare date/currency strings across screens.
Rollback:
- Revert to inline formatter creation in each file.
Risk rating: Medium.
Mitigations:
- Preserve locale/timezone settings; avoid shared mutable formatters where thread-safety is a concern.

6) Consolidate CloudKit probe constants/helpers
Goal:
- Avoid drift in record type lists and probe logic across CloudKit helpers.
Files touched (example scope):
- Add a shared constants/helper in OffshoreBudgeting/Services/ (record types list + minimal query helper).
- Update:
  - OffshoreBudgeting/Services/CloudAccountStatusProvider.swift
  - OffshoreBudgeting/Services/CloudSyncAccelerator.swift
  - OffshoreBudgeting/Services/CloudDataRemoteProbe.swift
Why behavior should not change:
- The helper mirrors current record types and query settings.
Verification:
- Build command above.
- Manual smoke: toggle Cloud Sync in Settings and verify gating screens behave the same.
Rollback:
- Restore inline record type lists and queries in each file.
Risk rating: Medium.
Mitigations:
- Keep semantics identical (same record type, same resultsLimit, same error handling).

7) Service-layer alignment for delete flows (highest risk)
Goal:
- Ensure deletions go through service-layer APIs consistently and retain any invariants.
Files touched (example scope):
- OffshoreBudgeting/Views/HomeView.swift (planned expense delete)
- OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift (category delete)
- Possibly OffshoreBudgeting/Services/ExpenseCategoryService.swift (add an explicit delete-with-expenses helper)
Why behavior should not change:
- Any new service helper must perform the same cascade deletion as current view code.
Verification:
- Build command above.
- Manual smoke: delete planned expenses and categories; verify related expenses are removed and UI refreshes.
Rollback:
- Restore direct Core Data delete logic in views.
Risk rating: High.
Mitigations:
- Add explicit service API that matches current cascade behavior; do not reuse the existing deleteCategory without adding cascade logic.

Manual smoke checklist (per patch)
- Open Home, Cards, Income, Presets, Settings.
- Add and delete a planned expense and unplanned expense (when available).
- Add and delete a category (confirm category-related expenses are removed).
- Confirm button styles look identical on OS 26+ and legacy style paths.
- Confirm date/currency formatting matches previous UI.
