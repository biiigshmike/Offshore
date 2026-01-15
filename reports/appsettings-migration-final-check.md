# AppSettings Migration — Final Check

## Check 1 — `@AppStorage` usage scope

Command:

`rg -n "@AppStorage" OffshoreBudgeting -g"*.swift"`

Result: **NOT limited to `OffshoreBudgeting/Core/Config/`** (hits exist elsewhere)

Matches:
- `OffshoreBudgeting/Views/CloudSyncGateView.swift:14` — `@AppStorage("didCompleteOnboarding")`
- `OffshoreBudgeting/Views/CloudSyncGateView.swift:15` — `@AppStorage("didChooseCloudDataOnboarding")`
- `OffshoreBudgeting/App/Navigation/RootTabView.swift:54` — `@AppStorage("uitest_seed_done")`
- `OffshoreBudgeting/Views/HomeView.swift:235` — `@AppStorage("homePinnedWidgetIDs")`
- `OffshoreBudgeting/Views/HomeView.swift:236` — `@AppStorage("homeWidgetOrderIDs")`
- `OffshoreBudgeting/Views/HomeView.swift:237` — `@AppStorage("homeAvailabilitySegment")`
- `OffshoreBudgeting/Views/HomeView.swift:238` — `@AppStorage("homeScenarioAllocations")`
- `OffshoreBudgeting/Views/HomeView.swift:2344` — `@AppStorage("homeScenarioAllocations")`
- `OffshoreBudgeting/Views/HomeView.swift:2346` — `@AppStorage("homeAvailabilitySegment")`
- `OffshoreBudgeting/App/OffshoreBudgetingApp.swift:34` — `@AppStorage("didCompleteOnboarding")`
- `OffshoreBudgeting/Views/HelpView.swift:9` — `@AppStorage("didCompleteOnboarding")`
- `OffshoreBudgeting/Views/OnboardingView.swift:9` — `@AppStorage("didCompleteOnboarding")`
- `OffshoreBudgeting/ViewModels/AppLockViewModel.swift:42` — `@AppStorage("appLockEnabled")`

## Check 2 — `AppSettingsKeys.*.rawValue` usage in `Views/` and `ViewModels/`

Command:

`rg -n "AppSettingsKeys\\.[A-Za-z0-9_]+\\.rawValue" OffshoreBudgeting/Views OffshoreBudgeting/ViewModels -g"*.swift"`

Result: **0 matches**

