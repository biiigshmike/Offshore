# AppSettings Migration Map

This report inventories current preference persistence callsites to support a future migration away from direct `@AppStorage`/`UserDefaults` usage.

## Summary

- @AppStorage callsites: 41
- Direct UserDefaults.standard usage: 37
- AppSettingsKeys.rawValue usage: 85

## Legend

- `access`: `read`, `write`, `read/write`, `unknown`, or `comment`
- `key`: extracted from `AppSettingsKeys.*.rawValue` or a string literal when present

## @AppStorage callsites

| Location | Key | Access | API |
|---|---|---|---|
| `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:345` | `AppSettingsKeys.tipsHintsResetToken.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/App/Navigation/RootTabView.swift:54` | `uitest_seed_done` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:34` | `didCompleteOnboarding` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/ViewModels/AppLockViewModel.swift:42` | `appLockEnabled` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:12` | `` | `comment` | `@AppStorage` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:18` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:22` | `AppSettingsKeys.calendarHorizontal.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:26` | `AppSettingsKeys.presetsDefaultUseInFutureBudgets.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:35` | `AppSettingsKeys.enableCloudSync.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:44` | `AppSettingsKeys.syncHomeWidgetsAcrossDevices.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/AddPlannedExpenseView.swift:42` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:34` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/CardDetailView.swift:37` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/CloudSyncGateView.swift:13` | `didCompleteOnboarding` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/CloudSyncGateView.swift:14` | `AppSettingsKeys.enableCloudSync.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/CloudSyncGateView.swift:15` | `didChooseCloudDataOnboarding` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:41` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:42` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/HelpView.swift:9` | `didCompleteOnboarding` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/HomeView.swift:234` | `homePinnedWidgetIDs` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/HomeView.swift:235` | `homeWidgetOrderIDs` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/HomeView.swift:236` | `homeAvailabilitySegment` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/HomeView.swift:237` | `homeScenarioAllocations` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/HomeView.swift:238` | `AppSettingsKeys.enableCloudSync.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/HomeView.swift:239` | `AppSettingsKeys.syncHomeWidgetsAcrossDevices.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/HomeView.swift:2345` | `homeScenarioAllocations` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/HomeView.swift:2347` | `homeAvailabilitySegment` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/HomeView.swift:5068` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/IncomeView.swift:28` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/OnboardingView.swift:8` | `didCompleteOnboarding` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/OnboardingView.swift:9` | `AppSettingsKeys.enableCloudSync.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:21` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/PresetsView.swift:22` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/SettingsView.swift:833` | `AppSettingsKeys.enableDailyReminder.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/SettingsView.swift:834` | `AppSettingsKeys.enablePlannedIncomeReminder.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/SettingsView.swift:835` | `AppSettingsKeys.enablePresetExpenseDueReminder.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/SettingsView.swift:836` | `AppSettingsKeys.silencePresetWithActualAmount.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/SettingsView.swift:837` | `AppSettingsKeys.excludeNonGlobalPresetExpenses.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/SettingsView.swift:838` | `AppSettingsKeys.notificationReminderTimeMinutes.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/WorkspaceProfilesView.swift:12` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `read/write` | `@AppStorage` |
| `OffshoreBudgeting/Views/WorkspaceProfilesView.swift:108` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `read/write` | `@AppStorage` |

## Direct UserDefaults.standard usage

| Location | Key | Access | API |
|---|---|---|---|
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:142` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:206` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:272` | `didCompleteOnboarding` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:296` | `AppSettingsKeys.enableCloudSync.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:299` | `AppSettingsKeys.enableCloudSync.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:303` | `AppSettingsKeys.enableCloudSync.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:306` | `AppSettingsKeys.enableCloudSync.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:514` | `uitest_seed_done` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:516` | `uitest_seed_done` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:541` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:542` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:629` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:630` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:871` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:872` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:968` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:969` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:974` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:975` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:1006` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:1007` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/Core/Cloud/CloudSyncAccelerator.swift:37` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/Core/Cloud/State/CloudStateFacade.swift:12` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/Core/Persistence/CoreDataService.swift:66` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/Core/Platform/PlatformCapabilities.swift:39` | `UBForceLegacyChrome` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/Core/Sync/DataChangeDebounce.swift:16` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/Core/Sync/DataChangeDebounce.swift:25` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/Core/Sync/MergeService.swift:30` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/Services/CloudOnboardingDecisionEngine.swift:51` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/Services/WorkspaceService.swift:167` | `AppSettingsKeys.budgetPeriod.rawValue` | `read` | `UserDefaults.standard.string` |
| `OffshoreBudgeting/Services/WorkspaceService.swift:184` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `read` | `UserDefaults.standard.string` |
| `OffshoreBudgeting/Support/Logging.swift:20` | `` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/Support/Logging.swift:21` | `` | `write` | `UserDefaults.standard.set` |
| `OffshoreBudgeting/ViewModels/CardsViewModel.swift:201` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/ViewModels/HomeViewModel.swift:347` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/ViewModels/PresetsViewModel.swift:140` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |
| `OffshoreBudgeting/Views/BudgetsView.swift:419` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `UserDefaults.standard.bool` |

## AppSettingsKeys.rawValue usage

| Location | Key | Access | API |
|---|---|---|---|
| `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:210` | `AppSettingsKeys.tipsHintsResetToken.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:345` | `AppSettingsKeys.tipsHintsResetToken.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:142` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:206` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:296` | `AppSettingsKeys.enableCloudSync.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:299` | `AppSettingsKeys.enableCloudSync.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:303` | `AppSettingsKeys.enableCloudSync.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:306` | `AppSettingsKeys.enableCloudSync.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:541` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:542` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:629` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:630` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:871` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:872` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:968` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:969` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:974` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:975` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:1006` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:1007` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Cloud/CloudSyncAccelerator.swift:37` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Cloud/State/CloudStateFacade.swift:12` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Persistence/CoreDataService.swift:66` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Persistence/CoreDataService.swift:453` | `AppSettingsKeys.enableCloudSync.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Scheduling/LocalNotificationScheduler.swift:44` | `AppSettingsKeys.lastAppOpenDate.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Scheduling/LocalNotificationScheduler.swift:48` | `AppSettingsKeys.lastExpenseAddedDate.rawValue` | `write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Scheduling/LocalNotificationScheduler.swift:59` | `AppSettingsKeys.enableDailyReminder.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Scheduling/LocalNotificationScheduler.swift:64` | `AppSettingsKeys.lastAppOpenDate.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Scheduling/LocalNotificationScheduler.swift:65` | `AppSettingsKeys.lastExpenseAddedDate.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Scheduling/LocalNotificationScheduler.swift:78` | `AppSettingsKeys.enablePlannedIncomeReminder.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Scheduling/LocalNotificationScheduler.swift:98` | `AppSettingsKeys.enablePresetExpenseDueReminder.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Scheduling/LocalNotificationScheduler.swift:107` | `AppSettingsKeys.excludeNonGlobalPresetExpenses.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Scheduling/LocalNotificationScheduler.swift:108` | `AppSettingsKeys.silencePresetWithActualAmount.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Scheduling/LocalNotificationScheduler.swift:180` | `AppSettingsKeys.notificationReminderTimeMinutes.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Sync/DataChangeDebounce.swift:16` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Sync/DataChangeDebounce.swift:25` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Core/Sync/MergeService.swift:30` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Services/CloudOnboardingDecisionEngine.swift:51` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Services/WorkspaceService.swift:15` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Services/WorkspaceService.swift:167` | `AppSettingsKeys.budgetPeriod.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Services/WorkspaceService.swift:184` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/CardsViewModel.swift:201` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/CardsViewModel.swift:278` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/HomeViewModel.swift:347` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/HomeViewModel.swift:1241` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/PresetsViewModel.swift:140` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:18` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:22` | `AppSettingsKeys.calendarHorizontal.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:26` | `AppSettingsKeys.presetsDefaultUseInFutureBudgets.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:35` | `AppSettingsKeys.enableCloudSync.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:44` | `AppSettingsKeys.syncHomeWidgetsAcrossDevices.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:50` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:51` | `AppSettingsKeys.calendarHorizontal.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:52` | `AppSettingsKeys.presetsDefaultUseInFutureBudgets.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:53` | `AppSettingsKeys.budgetPeriod.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:54` | `AppSettingsKeys.enableCloudSync.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:55` | `AppSettingsKeys.syncHomeWidgetsAcrossDevices.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:56` | `AppSettingsKeys.enableDailyReminder.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:57` | `AppSettingsKeys.enablePlannedIncomeReminder.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:58` | `AppSettingsKeys.enablePresetExpenseDueReminder.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:59` | `AppSettingsKeys.silencePresetWithActualAmount.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:60` | `AppSettingsKeys.excludeNonGlobalPresetExpenses.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:61` | `AppSettingsKeys.notificationReminderTimeMinutes.rawValue` | `unknown` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/AddPlannedExpenseView.swift:42` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:34` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/BudgetsView.swift:419` | `AppSettingsKeys.enableCloudSync.rawValue` | `read` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/CardDetailView.swift:37` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/CloudSyncGateView.swift:14` | `AppSettingsKeys.enableCloudSync.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:41` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:42` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/HomeView.swift:238` | `AppSettingsKeys.enableCloudSync.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/HomeView.swift:239` | `AppSettingsKeys.syncHomeWidgetsAcrossDevices.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/HomeView.swift:5068` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/IncomeView.swift:28` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/OnboardingView.swift:9` | `AppSettingsKeys.enableCloudSync.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:21` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/PresetsView.swift:22` | `AppSettingsKeys.confirmBeforeDelete.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/SettingsView.swift:833` | `AppSettingsKeys.enableDailyReminder.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/SettingsView.swift:834` | `AppSettingsKeys.enablePlannedIncomeReminder.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/SettingsView.swift:835` | `AppSettingsKeys.enablePresetExpenseDueReminder.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/SettingsView.swift:836` | `AppSettingsKeys.silencePresetWithActualAmount.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/SettingsView.swift:837` | `AppSettingsKeys.excludeNonGlobalPresetExpenses.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/SettingsView.swift:838` | `AppSettingsKeys.notificationReminderTimeMinutes.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/WorkspaceProfilesView.swift:12` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |
| `OffshoreBudgeting/Views/WorkspaceProfilesView.swift:108` | `AppSettingsKeys.activeWorkspaceID.rawValue` | `read/write` | `AppSettingsKeys.*.rawValue` |

## Unknown Access Notes

These `AppSettingsKeys.*.rawValue` references are not directly adjacent to a recognizable `UserDefaults` read/write API call on the same line.

- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:210` — `private let resetTokenKey = AppSettingsKeys.tipsHintsResetToken.rawValue`
- `OffshoreBudgeting/Services/WorkspaceService.swift:15` — `private let defaultsActiveKey = AppSettingsKeys.activeWorkspaceID.rawValue`
- `OffshoreBudgeting/ViewModels/CardsViewModel.swift:278` — `forKey: AppSettingsKeys.confirmBeforeDelete.rawValue`
- `OffshoreBudgeting/ViewModels/HomeViewModel.swift:1241` — `forKey: AppSettingsKeys.confirmBeforeDelete.rawValue`
- `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:50` — `AppSettingsKeys.confirmBeforeDelete.rawValue: true,`
- `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:51` — `AppSettingsKeys.calendarHorizontal.rawValue: true,`
- `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:52` — `AppSettingsKeys.presetsDefaultUseInFutureBudgets.rawValue: true,`
- `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:53` — `AppSettingsKeys.budgetPeriod.rawValue: BudgetPeriod.monthly.rawValue,`
- `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:54` — `AppSettingsKeys.enableCloudSync.rawValue: false,`
- `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:55` — `AppSettingsKeys.syncHomeWidgetsAcrossDevices.rawValue: false,`
- `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:56` — `AppSettingsKeys.enableDailyReminder.rawValue: false,`
- `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:57` — `AppSettingsKeys.enablePlannedIncomeReminder.rawValue: false,`
- `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:58` — `AppSettingsKeys.enablePresetExpenseDueReminder.rawValue: false,`
- `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:59` — `AppSettingsKeys.silencePresetWithActualAmount.rawValue: false,`
- `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:60` — `AppSettingsKeys.excludeNonGlobalPresetExpenses.rawValue: false,`
- `OffshoreBudgeting/ViewModels/SettingsViewModel.swift:61` — `AppSettingsKeys.notificationReminderTimeMinutes.rawValue: 20 * 60`
