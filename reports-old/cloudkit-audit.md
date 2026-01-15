CloudKit Audit (Phase 1)

Scope files:
- OffshoreBudgeting/Services/CloudAccountStatusProvider.swift
- OffshoreBudgeting/Services/CloudDataProbe.swift
- OffshoreBudgeting/Services/CloudDataRemoteProbe.swift
- OffshoreBudgeting/Services/CloudDiagnostics.swift
- OffshoreBudgeting/Services/CloudKitConfig.swift
- OffshoreBudgeting/Services/CloudSyncAccelerator.swift
- OffshoreBudgeting/Services/CloudSyncMonitor.swift

1) CloudAccountStatusProvider.swift
Responsibility (per code):
- Determines CloudKit account availability for the configured container, caches status, and runs a minimal container probe (CKQuery for CD_Budget).
Public surface area:
- availability (Published), isCloudAccountAvailable, requestAccountStatusCheck(force:), resolveAvailability(forceRefresh:), invalidateCache(), availabilityPublisher.
Usage:
- OffshoreBudgeting/Core/Persistence/CoreDataService.swift:313
- OffshoreBudgeting/Systems/AppTheme.swift:817, 936
- OffshoreBudgeting/Services/CloudDiagnostics.swift:53
- OffshoreBudgeting/Views/CloudSyncGateView.swift:84
Overlap:
- Uses CKContainer.accountStatus + minimal CKQuery similar to CloudSyncAccelerator (nudge) and CloudDataRemoteProbe (remote data detection).
Consolidation recommendation:
- Potential shared helper for “minimal CKQuery probe” (record type + container) to avoid duplicated probe logic.
- Risk: Medium. Any probe change affects gating decisions; must preserve error handling and availability semantics.

2) CloudKitConfig.swift
Responsibility (per code):
- Single source of truth for CloudKit container identifier.
Public surface area:
- CloudKitConfig.containerIdentifier.
Usage:
- OffshoreBudgeting/Core/Persistence/CoreDataService.swift:31
- OffshoreBudgeting/Services/CloudAccountStatusProvider.swift:24
- OffshoreBudgeting/Services/CloudSyncAccelerator.swift:35
- OffshoreBudgeting/Services/CloudDataRemoteProbe.swift:15
Overlap:
- None beyond being the shared configuration constant.
Consolidation recommendation:
- None; file already centralizes configuration.
Risk: Low.

3) CloudSyncMonitor.swift
Responsibility (per code):
- Observes NSPersistentCloudKitContainer event notifications to track import activity and initial import completion; offers awaitInitialImport(timeout:).
Public surface area:
- initialImportCompleted, isImporting, awaitInitialImport(timeout:pollInterval:).
Usage:
- OffshoreBudgeting/OffshoreBudgetingApp.swift:204
- OffshoreBudgeting/Views/CloudSyncGateView.swift:157
- OffshoreBudgeting/View Models/HomeViewModel.swift:347
- OffshoreBudgeting/View Models/PresetsViewModel.swift:140
- OffshoreBudgeting/View Models/CardsViewModel.swift:201
- OffshoreBudgeting/Systems/DataChangeDebounce.swift:11, 23
Overlap:
- Shares event notification observation with CloudDiagnostics (different outputs: errors vs import state).
Consolidation recommendation:
- Possible shared event observer to reduce duplicate NotificationCenter hooks, but responsibilities are distinct.
- Risk: Low/Med; split outputs could be merged but would tighten coupling.

4) CloudSyncAccelerator.swift
Responsibility (per code):
- Best-effort “nudge” on foreground: accountStatus check + tiny CKQuery to warm CloudKit connection.
Public surface area:
- nudgeOnForeground().
Usage:
- OffshoreBudgeting/OffshoreBudgetingApp.swift:139, 149, 211
- OffshoreBudgeting/Views/CardsView.swift:118
- OffshoreBudgeting/Views/IncomeView.swift:670
- OffshoreBudgeting/Views/PresetsView.swift:88
- OffshoreBudgeting/View Models/CardsViewModel.swift:297
Overlap:
- CKQuery for CD_Budget overlaps with CloudAccountStatusProvider probe and CloudDataRemoteProbe record type list.
Consolidation recommendation:
- Consider a shared “CloudKitProbe” utility for one-record query to avoid drift (record type, zone selection).
- Risk: Medium. Changes could affect perceived sync responsiveness.

5) CloudDataProbe.swift
Responsibility (per code):
- Local Core Data probe: checks if any records exist for key entities; includes async polling.
Public surface area:
- hasAnyData(), scanForExistingData(timeout:pollInterval:).
Usage:
- OffshoreBudgeting/OffshoreBudgetingApp.swift:129, 205
- OffshoreBudgeting/Views/CloudSyncGateView.swift:139
Overlap:
- Shares entity list semantics with CloudDataRemoteProbe (local vs remote).
Consolidation recommendation:
- Consider a shared entity list (local names vs CD_ prefixed) to keep probes consistent.
- Risk: Low. Must preserve polling timing and entity set.

6) CloudDataRemoteProbe.swift
Responsibility (per code):
- Remote CloudKit probe: checks if any CD_* records exist in private database.
Public surface area:
- hasAnyRemoteData(timeout:).
Usage:
- OffshoreBudgeting/OffshoreBudgetingApp.swift:199
- OffshoreBudgeting/Views/CloudSyncGateView.swift:114
Overlap:
- Record types list overlaps with CloudAccountStatusProvider and CloudSyncAccelerator (CD_Budget used as probe).
Consolidation recommendation:
- Potential shared record type constants to avoid drift across probes.
- Risk: Low/Med. Ensure timeouts and query semantics remain unchanged.

7) CloudDiagnostics.swift
Responsibility (per code):
- Settings-facing diagnostics: store mode string, container reachability, last CloudKit error.
Public surface area:
- storeMode, containerReachable, lastCloudKitErrorDescription, refresh().
Usage:
- OffshoreBudgeting/Views/SettingsView.swift:31
Overlap:
- Observes same CloudKit event notification as CloudSyncMonitor, but for different output.
Consolidation recommendation:
- Avoid consolidating unless a shared event observer yields measurable value; responsibilities are distinct.
- Risk: Low.

Is the “7 files” split justified?
- Largely yes. Each file has a focused, separate responsibility (availability, diagnostics, import monitoring, foreground nudge, local data probe, remote data probe, config).
- The main duplication is around the minimal “probe” CKQuery and shared record type lists.
- Consolidation is warranted only for shared constants/helpers (record type list, minimal query utility), not for merging responsibilities.
