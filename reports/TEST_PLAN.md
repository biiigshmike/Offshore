Test Plan (Phase A)

A1) Principles
- Characterization tests: capture current behavior to protect refactors.
- Unit vs integration vs UI tests:
  - Unit: service-layer behavior with in-memory Core Data.
  - Integration: CoreDataService + WorkspaceService + services together (still in-memory).
  - UI (XCUITest): only 2–4 golden flows later; no UI layout assumptions.
- No-tests baseline: Start with service+CoreData tests because business logic and persistence are highest risk and easy to regress during refactors.

A2) Risk-Based Priorities (Top-Down)
1) Highest risk
- Delete flows and service-layer bypass (planned expenses and categories).
- Workspace scoping (activeWorkspaceID predicate and assignment).
2) Next
- Core Data observer behavior (CoreDataListObserver, CoreDataService merges) and save semantics.
3) Next
- CloudKit gating/config (shallow tests only; no network reliance).
4) Next
- UI smoke tests (XCUITest) for 2–4 golden flows (Phase 2.5).

A3) Minimal Starter Suite (10–20 tests total)
(Initial set to implement now is marked [Now])
1) [Now] PlannedExpenseService.fetchAll sorts by transactionDate ascending by default.
2) [Now] PlannedExpenseService.find(byID:) returns inserted expense.
3) [Now] PlannedExpenseService.find(byID:) returns nil for unknown ID.
4) [Now] PlannedExpenseService.fetchForBudget returns only expenses for matching budget.
5) [Now] PlannedExpenseService.fetchAll(in:) includes boundaries (inclusive).
6) [Now] PlannedExpenseService.delete removes an expense from the store.
7) [Now] PlannedExpenseService.createGlobalTemplate + instantiateTemplate copies values and links globalTemplateID.
8) [Now] Workspace predicate applied when activeWorkspaceID is set (PlannedExpenseService).
9) [Now] ExpenseCategoryService.create persists and fetches.
10) [Now] ExpenseCategoryService.fetchAll sorted by name ascending.
11) [Now] ExpenseCategoryService workspace predicate filters categories.
12) [Now] ExpenseCategoryService.updateCategory persists.
13) [Now] ExpenseCategoryService.deleteCategory removes category (no cascade expectations yet).
14) [Now] ExpenseCategoryService.addCategory applies workspaceID when active workspace is set.
15) [Now] PlannedExpenseService.create applies workspaceID when active workspace is set.
16) [Now] Delete category with linked planned/unplanned expenses (service delete path) characterizes cascade outcome.
17) [Now] Delete category with linked planned/unplanned expenses (view cascade path) characterizes outcome.
18) [Now] dataStoreDidChange notification posts on category deletion (characterization).
19) [Now] CoreDataRepository.deleteAll merges changes back into viewContext.
20) [Now] CoreDataService.wipeAllData merges deletes and leaves context safe to access.
21) [Now] CloudKit gating: enableCloudSync=false stays local; enableCloudSync=true + unavailable stays local.
22) PlannedExpenseService.fetchForCard excludes globals (isGlobal == false).
23) PlannedExpenseService.fetchTemplatesForCard includes only globals.
24) HomeView delete behavior characterization (service bypass noted; test via service-layer only, no UI).
25) BudgetService.create + PlannedExpenseService.create: cross-entity linkage is valid.

Phase 2.5: UI Tests (follow-up)
- [Now] Categories: add and delete a category (seed: categories_empty).
- [Now] Categories: delete used category shows cascade alert (seed: categories_with_one).
- Add budget → add planned expense → delete planned expense.
- Add card → delete card (verify confirmation and deletion).

A4) Test Data Strategy
- Use in-memory Core Data store with the app’s actual model.
- Control WorkspaceService via UserDefaults (activeWorkspaceID) and clear after each test.
- Avoid global UserDefaults state leakage; reset keys per test.

A5) Build/Run Instructions
- xcodebuild -project Offshore.xcodeproj -scheme OffshoreBudgeting -destination 'platform=iOS Simulator,name=iPhone 15' test
- If the unit test scheme differs, use the project’s shared test plan (OffshoreBudgeting.xctestplan).
- Unit-only: xcodebuild -project Offshore.xcodeproj -scheme OffshoreBudgeting -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' test -only-testing:OffshoreBudgetingTests
- UI-only: xcodebuild -project Offshore.xcodeproj -scheme OffshoreBudgeting -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' test -only-testing:OffshoreBudgetingUITests
