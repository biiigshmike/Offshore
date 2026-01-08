Refactor Audit (Phase 1 baseline)

Objectives
- Centralize repeated UI styling and shared logic without changing behavior.
- Make delete flows consistent with the service layer where safe.
- Reduce drift in CloudKit probes and formatting utilities.

Non-goals
- No UI redesigns or layout changes.
- No architectural rewrites or view model migrations.
- No Core Data schema changes.

Source of Truth Targets
- Styles: section headers, form TextFields, primary CTA button styling.
- CRUD flows: planned/unplanned expense delete, category delete, card delete.
- Observers: keep CoreDataListObserver usage intact.
- CloudKit config/probes: shared constants for record types and container identifier.

Key Findings (Phase 1)
- Section header typography is repeated across multiple forms (see reports/duplication.md).
- Form TextField styling is duplicated in several views (see reports/duplication.md).
- Category chip components are duplicated between AddPlannedExpenseView and AddUnplannedExpenseView.
- Planned expense deletes are inconsistent: HomeView bypasses PlannedExpenseService.
- Category delete bypasses ExpenseCategoryService and performs manual cascades.
- Date/Number formatter creation is scattered across views and view models.

Decisions Log (Phase 1)
- No code changes yet; Phase 2 will use one-view-at-a-time patches with xcodebuild after each patch.
- Service-layer alignment for deletes is highest-risk and should be scheduled last.

Pattern Library (placeholders; no code yet)
- SectionHeaderStyle: Text("Title").ubSectionHeader() // applies footnote + secondary + uppercase
- FormTextFieldStyle: TextField(...).ubFormTextFieldStyle() // autocorrect off, leading alignment, etc.
- CategoryChipsRow: shared component used by planned/unplanned expense forms
- PrimaryCTAButon: Buttons.primary(...) or a dedicated glass/legacy helper
- FormatterCache: shared named formatters (medium date, currency)

View-by-view checklist (Phase 2 execution order candidate)
- [ ] RenameCardSheet (small, low risk)
- [ ] AddCardFormView (header + TextField style)
- [ ] AddBudgetView (header + TextField style)
- [ ] AddIncomeFormView (header + TextField style)
- [ ] AddPlannedExpenseView (category chips + TextField style)
- [ ] AddUnplannedExpenseView (category chips + TextField style)
- [ ] HomeView (delete flow alignment)
- [ ] ExpenseCategoryManagerView (delete flow alignment)
- [ ] SettingsView / HelpView (CTA style consolidation)

Verification checklist per patch
- xcodebuild -project Offshore.xcodeproj -scheme OffshoreBudgeting -destination "platform=iOS Simulator,name=iPhone 16,OS=18.5" build
- Manual smoke:
  - Confirm section headers and TextFields render identically.
  - Verify delete flows still prompt correctly and remove data.
  - Verify Cloud Sync gating screens still behave as before.
  - Check iOS and macOS Catalyst layouts for spacing regressions.

High-value first views (Phase 2)
- RenameCardSheet
- AddCardFormView
- AddBudgetView
- AddIncomeFormView
- AddPlannedExpenseView
