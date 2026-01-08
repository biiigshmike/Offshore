Consistency Audit (Phase 1)

Focus: delete flows and whether they consistently use the service layer and observers.

Findings (evidence-based):
- Planned expense deletes are inconsistent: HomeView deletes directly via CoreData context, while BudgetDetailsView and CardDetailView use PlannedExpenseService.
- Expense category delete bypasses ExpenseCategoryService and manually cascades deletes via Core Data fetches.
- Preset template delete uses PlannedExpenseService; income delete uses IncomeService; card delete uses CardService.

Consistency Matrix
Feature/Behavior | View(s) | Entry point | Service layer used? | Observers used? | Notes/Risks
Card delete | OffshoreBudgeting/Views/CardsView.swift (alert) + OffshoreBudgeting/View Models/CardsViewModel.swift | Alert confirm -> vm.confirmDelete(card:) | Yes (CardService.deleteCard) | Yes (CoreDataListObserver in CardsViewModel) | Consistent; also nudges CloudSyncAccelerator after delete.
Budget delete | OffshoreBudgeting/Views/BudgetDetailsView.swift | Delete button -> deleteBudget() | Yes (BudgetService.deleteBudget) | No explicit observer; view dismisses | Consistent with service layer.
Planned expense delete (budget detail) | OffshoreBudgeting/Views/BudgetDetailsView.swift:169-182 | UnifiedSwipeActions -> onDelete closure | Yes (PlannedExpenseService.delete) | Manual refresh (vm.refreshRows) | Uses service layer; no observer.
Planned expense delete (card detail) | OffshoreBudgeting/Views/CardDetailView.swift:430-460 + OffshoreBudgeting/View Models/CardDetailViewModel.swift:265-292 | UnifiedSwipeActions / List onDelete -> viewModel.delete(expense:) | Yes (PlannedExpenseService.delete) | ViewModel state update | Consistent with service layer.
Planned expense delete (home) | OffshoreBudgeting/Views/HomeView.swift:4105-4111 and 5381-5387 | UnifiedSwipeActions -> deletePlannedExpense | No (direct CoreData context delete) | Implicit Core Data updates | Inconsistent with service layer; potential behavior drift.
Unplanned expense delete (budget detail) | OffshoreBudgeting/Views/BudgetDetailsView.swift:189-201 | UnifiedSwipeActions -> onDelete closure | Yes (UnplannedExpenseService.delete) | Manual refresh (vm.refreshRows) | Uses service layer.
Income delete | OffshoreBudgeting/Views/IncomeView.swift:698-717 + OffshoreBudgeting/View Models/IncomeScreenViewModel.swift:127-137 | Swipe action / delete button -> vm.delete(income:) | Yes (IncomeService.deleteIncome) | ViewModel reload | Consistent; uses view model reload.
Preset template delete | OffshoreBudgeting/Views/PresetsView.swift:56-75 and 128-131 | UnifiedSwipeActions / List onDelete -> delete(template:) | Yes (PlannedExpenseService.deleteTemplateAndChildren) | Manual reload (vm.loadTemplates) | Consistent with service layer.
Expense category delete | OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:245-258 | Button/alert -> deleteCategory | No (direct CoreData fetch + delete) | @FetchRequest updates list | Inconsistent with ExpenseCategoryService; risk of bypassing shared logic.

Notes:
- UnifiedSwipeActions is used in multiple views (e.g., CardDetailView, HomeView, PresetsView) but the delete handler paths vary (service vs direct context).
- Where deletes bypass services, behavior may diverge from service-level invariants (e.g., cascade expectations, logging, or CloudKit nudges).
