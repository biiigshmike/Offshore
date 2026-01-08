Duplication Audit (Phase 1)

A) UI styling duplication (SwiftUI-first)

1) Section header typography (uppercase footnote + secondary)
Examples:
- OffshoreBudgeting/Views/AddBudgetView.swift:134-138
- OffshoreBudgeting/Views/AddCardFormView.swift:104-109
- OffshoreBudgeting/Views/AddIncomeFormView.swift:134-138
- OffshoreBudgeting/Views/AddPlannedExpenseView.swift:204-208

Pattern:
- Repeated: Text(...).font(.footnote).foregroundStyle(.secondary).textCase(.uppercase)

Suggested centralization:
- Create a small ViewModifier or helper (e.g., SectionHeaderStyle) that applies the exact typography.
- Use only where the pattern already exists (no behavior change).

Risk:
- Low/Med. Any modifier must preserve font, color, and text casing exactly. Verify visually after centralization.

2) Form TextField styling (prompt + autocorrect off + leading alignment)
Examples:
- OffshoreBudgeting/Views/AddBudgetView.swift:108-127
- OffshoreBudgeting/Views/AddCardFormView.swift:118-131
- OffshoreBudgeting/Views/AddPlannedExpenseView.swift:183-199
- OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:227-236
- OffshoreBudgeting/Views/RenameCardSheet.swift:29-36

Pattern:
- Repeated: TextField("", text:..., prompt: ...)
  .autocorrectionDisabled(true)
  .textInputAutocapitalization(.never)
  .multilineTextAlignment(.leading)
  .frame(maxWidth: .infinity, alignment: .leading)

Suggested centralization:
- Introduce a focused ViewModifier (e.g., FormTextFieldStyle) or helper builder used by these forms.
- Keep the same prompts and accessibility labels per callsite.

Risk:
- Medium. TextField sizing and layout are sensitive across iOS/macOS; verify no spacing or line-limit changes.

3) Category chip row components duplicated
Examples:
- OffshoreBudgeting/Views/AddPlannedExpenseView.swift:612-829
- OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:322-572

Pattern:
- Duplicate definitions of CategoryChipsRow, AddCategoryPill, and CategoryChip.

Suggested centralization:
- Extract shared components into Views/Components (or reuse CategoryChipPill if aligned).
- Keep view identity, spacing, and scroll behavior unchanged.

Risk:
- Medium. Chip layouts often have subtle spacing/hit-testing differences; compare in both screens.

4) Primary action button (glass vs plain fallback) repeated
Examples:
- OffshoreBudgeting/Views/HomeView.swift:3644-3663
- OffshoreBudgeting/Views/SettingsView.swift:687-709
- OffshoreBudgeting/Views/HelpView.swift:471-488

Pattern:
- Repeated: Button + .buttonStyle(.glassProminent) on OS 26+, .plain + background fallback on legacy.

Suggested centralization:
- Prefer existing Buttons.primary (OffshoreBudgeting/Views/Components/Buttons.swift) if it matches visuals, or add a focused helper for this specific pattern.

Risk:
- Medium. The glass vs legacy fallback shapes/tints are visually sensitive; verify tint, corner radius, and row insets.

B) Logic duplication

1) Amount formatting in planned vs unplanned view models
Examples:
- OffshoreBudgeting/View Models/AddPlannedExpenseViewModel.swift:609-615
- OffshoreBudgeting/View Models/AddUnplannedExpenseViewModel.swift:277-283

Pattern:
- Identical NumberFormatter setup for decimal amount strings.

Suggested centralization:
- A shared formatter helper (static on a small type, or a formatter cache in Systems) used by both view models.

Risk:
- Low. Must preserve locale, fraction digits, and behavior for empty/invalid values.

2) Repeated Date/NumberFormatter creation across views
Examples:
- OffshoreBudgeting/Views/HomeView.swift:3456-3555 (NumberFormatter/DateFormatter creation)
- OffshoreBudgeting/Views/IncomeView.swift:366-373, 733-733 (DateFormatter inline)
- OffshoreBudgeting/Views/BudgetDetailsView.swift:420-429, 576-576 (NumberFormatter/DateFormatter)
- OffshoreBudgeting/Views/CardDetailView.swift:946-951 (DateFormatter)

Pattern:
- Ad hoc formatter instantiation in multiple views and view models.

Suggested centralization:
- A lightweight formatter cache in Systems (similar to PresetsViewModel.DateFormatterCache) with explicit, named formatters.

Risk:
- Medium. Formatters are locale/timezone sensitive; consistent configuration is required and should not alter output.

3) Planned expense delete in HomeView bypasses service layer
Examples:
- OffshoreBudgeting/Views/HomeView.swift:4105-4111
- OffshoreBudgeting/Views/HomeView.swift:5381-5387

Pattern:
- Direct Core Data delete + save, while other views use PlannedExpenseService.

Suggested centralization:
- Route deletes through PlannedExpenseService in Phase 2 to align with service-layer behavior.

Risk:
- High. Service layer may enforce additional invariants; any change must be verified against current behavior.
