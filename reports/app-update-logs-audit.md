# App Update Logs Audit (Read-only)

Goal: document how “What's New” / release logs are structured, where UI is presented, and how “show once” gating + version/build sourcing works.

## 1) Files involved (paths)

### Search receipt
- `rg -n "AppUpdateLog|AppUpdateLogs|UpdateLog|Changelog|What's New|Release Notes" OffshoreBudgeting -g"*.swift"`
- hits: `24`

### Matching files
- `OffshoreBudgeting/AppUpdateLogs/2.1.swift`
- `OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift`
- `OffshoreBudgeting/AppUpdateLogs/2.0.swift`
- `OffshoreBudgeting/AppUpdateLogs/2.0.1.swift`
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift`
- `OffshoreBudgeting/Views/SettingsView.swift`

## 2) Data model / types representing an update log entry

Primary types:
- `OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:4` `enum AppUpdateLogs`
- `OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:5` `struct AppUpdateLogEntry: Identifiable` → `{ versionToken: String, content: TipsContent }`
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:40` `struct TipsContent` → `{ title: String, items: [TipsItem], actionTitle: String }`
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:33` `struct TipsItem` → `{ symbolName: String, title: String, detail: String }`
- Release-specific content providers:
  - `OffshoreBudgeting/AppUpdateLogs/2.0.swift:3` `enum AppUpdateLog_2_0`
  - `OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:3` `enum AppUpdateLog_2_0_1`
  - `OffshoreBudgeting/AppUpdateLogs/2.1.swift:10` `enum AppUpdateLog_2_1`

How logs are selected:
- `OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:23` `AppUpdateLogs.content(for:versionToken:)` switches on a **version token** string (e.g. `"2.1.4"`).
- `OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:38` `AppUpdateLogs.releaseLogs` is the “Release Logs” list source (newest-first).

## 3) UI entrypoint (where the update sheet/banner is presented)

### Presentation mechanism
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:367` `TipsAndHintsOverlayModifier` presents a SwiftUI `.sheet(isPresented:onDismiss:)` with `TipsAndHintsSheet`.
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:404` provides `View.tipsAndHintsOverlay(for:kind:versionToken:)` as the callsite API.

### Where “What's New” is triggered
- `OffshoreBudgeting/Views/HomeView.swift:510` attaches `.tipsAndHintsOverlay(for: .home, kind: .whatsNew, versionToken: whatsNewVersionToken)` (this is the release/update UI hook).

### Search receipt (broad UI search)
- `rg -n "alert\(|sheet\(|fullScreenCover\(|Whats New|What's new|Release|Changelog|Update" OffshoreBudgeting -g"*.swift"`
- hits: `173` (broad; includes many unrelated alerts/sheets)

### Search receipt (specific overlay usage)
- `rg -n "tipsAndHintsOverlay\(" OffshoreBudgeting -g"*.swift"`
- hits: `10`

Overlay callsites:
- `OffshoreBudgeting/Views/CardDetailView.swift:203:        .tipsAndHintsOverlay(for: .cardDetail)`
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:198:    /// `.tipsAndHintsOverlay(for:kind:versionToken:)` with `.whatsNew`.`
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:405:    func tipsAndHintsOverlay(for screen: TipsScreen, kind: TipsKind = .walkthrough, versionToken: String? = nil) -> some View {`
- `OffshoreBudgeting/Views/CardsView.swift:57:            .tipsAndHintsOverlay(for: .cards)`
- `OffshoreBudgeting/Views/PresetsView.swift:28:            .tipsAndHintsOverlay(for: .presets)`
- `OffshoreBudgeting/Views/BudgetsView.swift:59:            .tipsAndHintsOverlay(for: .budgets)`
- `OffshoreBudgeting/Views/IncomeView.swift:61:        .tipsAndHintsOverlay(for: .income)`
- `OffshoreBudgeting/Views/HomeView.swift:509:        .tipsAndHintsOverlay(for: .home)`
- `OffshoreBudgeting/Views/HomeView.swift:510:        .tipsAndHintsOverlay(for: .home, kind: .whatsNew, versionToken: whatsNewVersionToken)`
- `OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:131:        .tipsAndHintsOverlay(for: .categories)`

## 4) Gating logic (“show once” / reset / migration)

### Store + persistence
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:205` `TipsAndHintsStore` persists seen-state in **both** `UserDefaults` and `NSUbiquitousKeyValueStore` (with migration).
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:222` `shouldShowTips(...)` is the main gate.

### Key format
- Current keys:
  - `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:247` walkthrough: `tips.seen.walkthrough.<screen>.r<resetToken>`
  - `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:250` whatsNew: `tips.seen.whatsNew.<screen>.v<versionToken>`
- Legacy whatsNew key (migration / back-compat):
  - `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:257` `tips.seen.whatsNew.<screen>.v<versionToken>.r<resetToken>`

### “Show once” decision
- For `.whatsNew`, if the current key is already true → do not show (`GuidedWalkthroughManager.swift:226`).
- If legacy key is true, it “burns” the new key and also does not show (`GuidedWalkthroughManager.swift:227-230`).
- Otherwise, show if `!bool(forKey: key)` (`GuidedWalkthroughManager.swift:232`).

### Reset behavior
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:239` `resetAllTips()` sets a new UUID reset token in `AppSettingsKeys.tipsHintsResetToken`.
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:349` `TipsAndHintsOverlayModifier` observes that reset token via `@AppStorage` and reevaluates display. 

### Migration to ubiquitous store
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:295` `migrateDefaultsToUbiquitousIfNeeded()` copies the reset token and any existing “seen” flags from `UserDefaults` into `NSUbiquitousKeyValueStore` once, guarded by `migrationKey`.
- It migrates whatsNew keys for all known release version tokens (`GuidedWalkthroughManager.swift:323-337`).

### Receipt search (broad persistence signals)
- `rg -n "UserDefaults|@AppStorage|lastSeen|lastShown|hasShown|didShow|build|version" OffshoreBudgeting -g"*.swift"`
- hits: `281` (broad; includes many unrelated app settings)

## 5) Version/build source (current app version token)

Where version/build are read from `Bundle.main.infoDictionary`:
- Release content title strings:
  - `OffshoreBudgeting/AppUpdateLogs/2.0.swift:7-11` uses `CFBundleShortVersionString` + `CFBundleVersion`
  - `OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:7-11` uses `CFBundleShortVersionString` + `CFBundleVersion`
  - `OffshoreBudgeting/AppUpdateLogs/2.1.swift:14-18` uses `CFBundleShortVersionString` + `CFBundleVersion`
- Gating token computation:
  - `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:331-337` `currentWhatsNewVersionToken()` returns `"<version>.<build>"`
  - `OffshoreBudgeting/Views/HomeView.swift:442-448` `whatsNewVersionToken` returns `"<version>.<build>"` for `.tipsAndHintsOverlay(...kind: .whatsNew...)`
- Display in Settings:
  - `OffshoreBudgeting/Views/SettingsView.swift:624-629` `appVersionLine` → `Version X • Build Y`

### Receipt search
- `rg -n "CFBundleShortVersionString|CFBundleVersion|Bundle\\.main|infoDictionary|appVersion|buildNumber" OffshoreBudgeting -g"*.swift"`
- hits: `25`

## 6) Manual “Release Logs” UI (non-gated)

- `OffshoreBudgeting/Views/SettingsView.swift:605-667` `ReleaseLogsView` renders `AppUpdateLogs.releaseLogs` into a list, parsing the `versionToken` for a “What's New • Version (Build)” header.

---
## Raw rg outputs (receipts)

### 1) AppUpdateLogs / changelog terms
```
rg -n "AppUpdateLog|AppUpdateLogs|UpdateLog|Changelog|What's New|Release Notes" OffshoreBudgeting -g"*.swift"
```
```
OffshoreBudgeting/AppUpdateLogs/2.1.swift:10:enum AppUpdateLog_2_1 {
OffshoreBudgeting/AppUpdateLogs/2.1.swift:18:                title: "What's New • \(version) (Build \(build))",
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:4:enum AppUpdateLogs {
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:5:    struct AppUpdateLogEntry: Identifiable {
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:22:    // What's New title and Release Logs list stay aligned.
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:27:            return AppUpdateLog_2_1.content(for: screen)
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:29:            return AppUpdateLog_2_0_1.content(for: screen)
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:31:            return AppUpdateLog_2_0.content(for: screen)
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:38:    static var releaseLogs: [AppUpdateLogEntry] {
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:40:            ("2.1.4", AppUpdateLog_2_1.content(for: .home)),
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:41:            ("2.0.1.1", AppUpdateLog_2_0_1.content(for: .home)),
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:42:            ("2.0.1", AppUpdateLog_2_0.content(for: .home))
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:47:            return AppUpdateLogEntry(versionToken: versionToken, content: content)
OffshoreBudgeting/AppUpdateLogs/2.0.swift:3:enum AppUpdateLog_2_0 {
OffshoreBudgeting/AppUpdateLogs/2.0.swift:11:                title: "What's New • \(version) (Build \(build))",
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:3:enum AppUpdateLog_2_0_1 {
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:11:                title: "What's New • \(version) (Build \(build))",
OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:196:    // MARK: - What's New Hooks
OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:197:    /// Provide per-release content via AppUpdateLogs and surface it by calling
OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:200:        AppUpdateLogs.content(for: screen, versionToken: versionToken)
OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:324:        var tokens = Set(AppUpdateLogs.releaseLogs.map(\.versionToken))
OffshoreBudgeting/Views/SettingsView.swift:647:            ForEach(AppUpdateLogs.releaseLogs) { log in
OffshoreBudgeting/Views/SettingsView.swift:662:        guard parts.count >= 2 else { return "What's New • \(versionToken)" }
OffshoreBudgeting/Views/SettingsView.swift:665:        return "What's New • \(version) (Build \(build))"
```

### 2) UI presentation broad scan
```
rg -n "alert\(|sheet\(|fullScreenCover\(|Whats New|What's new|Release|Changelog|Update" OffshoreBudgeting -g"*.swift"
```
```
OffshoreBudgeting/AppUpdateLogs/2.1.swift:10:enum AppUpdateLog_2_1 {
OffshoreBudgeting/AppUpdateLogs/2.1.swift:23:                        detail: "Import .csv transactions directly into a card from its detail view. Select what you want and attach them instantly. Updated Card creation form with new Effects feature! Find the perfect effect to pair with your Card's theme."
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:3:// MARK: - App Update Logs
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:4:enum AppUpdateLogs {
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:5:    struct AppUpdateLogEntry: Identifiable {
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:12:    // MARK: - Version Token Format (Release Log Titles)
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:22:    // What's New title and Release Logs list stay aligned.
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:27:            return AppUpdateLog_2_1.content(for: screen)
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:29:            return AppUpdateLog_2_0_1.content(for: screen)
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:31:            return AppUpdateLog_2_0.content(for: screen)
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:37:    // MARK: - Release Logs Source (Newest First)
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:38:    static var releaseLogs: [AppUpdateLogEntry] {
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:40:            ("2.1.4", AppUpdateLog_2_1.content(for: .home)),
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:41:            ("2.0.1.1", AppUpdateLog_2_0_1.content(for: .home)),
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:42:            ("2.0.1", AppUpdateLog_2_0.content(for: .home))
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:47:            return AppUpdateLogEntry(versionToken: versionToken, content: content)
OffshoreBudgeting/AppUpdateLogs/2.0.swift:3:enum AppUpdateLog_2_0 {
OffshoreBudgeting/AppUpdateLogs/2.0.swift:15:                        title: "Offshore Released to the Public",
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:3:enum AppUpdateLog_2_0_1 {
OffshoreBudgeting/Views/ExpenseImportView.swift:69:        .sheet(isPresented: $isPresentingAddCategory) {
OffshoreBudgeting/Views/ExpenseImportView.swift:80:        .sheet(isPresented: $isPresentingAssignCategory) {
OffshoreBudgeting/Views/ExpenseImportView.swift:89:        .alert("Missing Categories", isPresented: $isShowingMissingCategoryAlert) {
OffshoreBudgeting/Views/ExpenseImportView.swift:95:        .alert(item: $importError) { error in
OffshoreBudgeting/Views/PresetsView.swift:92:        .sheet(isPresented: $isPresentingAdd) {
OffshoreBudgeting/Views/PresetsView.swift:96:        .sheet(item: $sheetTemplateToAssign) { template in
OffshoreBudgeting/Views/PresetsView.swift:100:        .sheet(item: $editingTemplate) { template in
OffshoreBudgeting/Views/PresetsView.swift:109:        .alert(item: $templateToDelete) { template in
OffshoreBudgeting/Views/SettingsView.swift:115:            .alert("Erase All Data?", isPresented: $showResetAlert) {
OffshoreBudgeting/Views/SettingsView.swift:121:            .alert("Merge Local Data into iCloud?", isPresented: $showMergeConfirm) {
OffshoreBudgeting/Views/SettingsView.swift:127:            .alert("Merge Complete", isPresented: $showMergeDone) {
OffshoreBudgeting/Views/SettingsView.swift:132:            .alert("Force iCloud Sync Refresh?", isPresented: $showForceReuploadConfirm) {
OffshoreBudgeting/Views/SettingsView.swift:138:            .alert("Sync Refresh Finished", isPresented: $showForceReuploadResult) {
OffshoreBudgeting/Views/SettingsView.swift:357:                forceReuploadMessage = "Updated \(result.totalUpdated) records. \(summary.isEmpty ? "" : "Details: \(summary)")"
OffshoreBudgeting/Views/SettingsView.swift:607:                    ReleaseLogsView()
OffshoreBudgeting/Views/SettingsView.swift:610:                        title: "Release Logs",
OffshoreBudgeting/Views/SettingsView.swift:644:private struct ReleaseLogsView: View {
OffshoreBudgeting/Views/SettingsView.swift:647:            ForEach(AppUpdateLogs.releaseLogs) { log in
OffshoreBudgeting/Views/SettingsView.swift:650:                        ReleaseLogItemRow(item: item)
OffshoreBudgeting/Views/SettingsView.swift:656:        .navigationTitle("Release Logs")
OffshoreBudgeting/Views/SettingsView.swift:657:        .ub_windowTitle("Release Logs")
OffshoreBudgeting/Views/SettingsView.swift:669:private struct ReleaseLogItemRow: View {
OffshoreBudgeting/Views/SettingsView.swift:892:        .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
OffshoreBudgeting/Views/AddBudgetView.swift:249:        .alert("Couldn’t Save Budget",
OffshoreBudgeting/Views/CloudSyncGateView.swift:44:        .alert("Sync with iCloud?", isPresented: $showFirstPrompt) {
OffshoreBudgeting/Views/CloudSyncGateView.swift:51:        .alert("iCloud data found", isPresented: $showExistingDataPrompt) {
OffshoreBudgeting/Views/AddIncomeFormView.swift:57:        .alert(item: $error) { err in
OffshoreBudgeting/Views/AddIncomeFormView.swift:73:        .sheet(isPresented: $viewModel.isPresentingCustomRecurrenceEditor) {
OffshoreBudgeting/Views/AddIncomeFormView.swift:82:            "Update Recurring Income",
OffshoreBudgeting/Views/BudgetDetailsView.swift:74:        .sheet(isPresented: $isPresentingAddPlanned) { addPlannedSheet }
OffshoreBudgeting/Views/BudgetDetailsView.swift:75:        .sheet(isPresented: $isPresentingAddVariable) { addVariableSheet }
OffshoreBudgeting/Views/BudgetDetailsView.swift:76:        .sheet(isPresented: $isPresentingManageCards) { manageCardsSheet }
OffshoreBudgeting/Views/BudgetDetailsView.swift:77:        .sheet(isPresented: $isPresentingManagePresets) { managePresetsSheet }
OffshoreBudgeting/Views/BudgetDetailsView.swift:78:        .sheet(item: $editingBudgetBox) { box in
OffshoreBudgeting/Views/BudgetDetailsView.swift:85:        .sheet(item: $editingPlannedBox) { box in
OffshoreBudgeting/Views/BudgetDetailsView.swift:93:        .sheet(item: $editingUnplannedBox) { box in
OffshoreBudgeting/Views/BudgetDetailsView.swift:97:        .sheet(item: $capGaugeData) { data in
OffshoreBudgeting/Views/BudgetDetailsView.swift:104:        .alert("Delete Budget?", isPresented: $isConfirmingDelete) {
OffshoreBudgeting/Views/BudgetDetailsView.swift:110:        .alert("Error", isPresented: Binding(get: { deleteErrorMessage != nil }, set: { if !$0 { deleteErrorMessage = nil } })) {
OffshoreBudgeting/Services/UnplannedExpenseService.swift:240:    /// Update fields on an unplanned expense (only what you pass will change).
OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:83:        .sheet(isPresented: $isPresentingAddSheet, onDismiss: {
OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:103:        .sheet(item: $categoryToEdit) { category in
OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:114:        .alert(item: $categoryToDelete) { cat in
OffshoreBudgeting/Views/CardDetailView.swift:92:        .sheet(isPresented: $isPresentingEditCard) {
OffshoreBudgeting/Views/CardDetailView.swift:101:        .sheet(isPresented: $isPresentingAddExpense) {
OffshoreBudgeting/Views/CardDetailView.swift:112:        .sheet(isPresented: $isPresentingAddPlanned) {
OffshoreBudgeting/Views/CardDetailView.swift:125:        .sheet(item: $editingExpense) { expense in
OffshoreBudgeting/Views/CardDetailView.swift:150:        .alert("Delete Expense?", isPresented: $isConfirmingDelete) {
OffshoreBudgeting/Views/CardDetailView.swift:160:        .alert(item: $deletionError) { error in
OffshoreBudgeting/Views/CardDetailView.swift:188:        .fullScreenCover(item: $importSelection, onDismiss: { importSelection = nil }) { selection in
OffshoreBudgeting/Views/CardDetailView.swift:193:        .sheet(item: $importSelection, onDismiss: { importSelection = nil }) { selection in
OffshoreBudgeting/Views/HomeView.swift:477:        .alert(item: $vm.alert, content: aler
```

### 3) Gating/persistence broad scan
```
rg -n "UserDefaults|@AppStorage|lastSeen|lastShown|hasShown|didShow|build|version" OffshoreBudgeting -g"*.swift"
```
```
OffshoreBudgeting/AppUpdateLogs/2.1.swift:15:            let version = info?["CFBundleShortVersionString"] as? String ?? "0"
OffshoreBudgeting/AppUpdateLogs/2.1.swift:16:            let build = info?["CFBundleVersion"] as? String ?? "0"
OffshoreBudgeting/AppUpdateLogs/2.1.swift:18:                title: "What's New • \(version) (Build \(build))",
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:6:        let versionToken: String
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:9:        var id: String { versionToken }
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:14:    // - The final component is treated as the build number.
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:15:    // - All preceding components are joined back into the display version string.
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:23:    static func content(for screen: TipsScreen, versionToken: String?) -> TipsContent? {
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:24:        guard let versionToken else { return nil }
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:25:        switch versionToken {
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:45:        return candidates.compactMap { versionToken, content in
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:47:            return AppUpdateLogEntry(versionToken: versionToken, content: content)
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:8:            let version = info?["CFBundleShortVersionString"] as? String ?? "0"
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:9:            let build = info?["CFBundleVersion"] as? String ?? "0"
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:11:                title: "What's New • \(version) (Build \(build))",
OffshoreBudgeting/AppUpdateLogs/2.0.swift:8:            let version = info?["CFBundleShortVersionString"] as? String ?? "0"
OffshoreBudgeting/AppUpdateLogs/2.0.swift:9:            let build = info?["CFBundleVersion"] as? String ?? "0"
OffshoreBudgeting/AppUpdateLogs/2.0.swift:11:                title: "What's New • \(version) (Build \(build))",
OffshoreBudgeting/AppUpdateLogs/2.0.swift:14:                        symbolName: "dollarsign.bank.building",
OffshoreBudgeting/Views/CardDetailView.swift:37:    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue)
OffshoreBudgeting/Views/OnboardingView.swift:8:    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false
OffshoreBudgeting/Views/OnboardingView.swift:9:    @AppStorage(AppSettingsKeys.enableCloudSync.rawValue) private var enableCloudSync: Bool = false
OffshoreBudgeting/Services/WorkspaceService.swift:20:    private var defaults: UserDefaults { .standard }
OffshoreBudgeting/Services/WorkspaceService.swift:161:    /// One-time seed: if Workspace.budgetPeriod is nil, copy from UserDefaults and persist.
OffshoreBudgeting/Services/WorkspaceService.swift:167:            let localRaw = UserDefaults.standard.string(forKey: AppSettingsKeys.budgetPeriod.rawValue) ?? BudgetPeriod.monthly.rawValue
OffshoreBudgeting/Services/WorkspaceService.swift:184:        guard let raw = UserDefaults.standard.string(forKey: AppSettingsKeys.activeWorkspaceID.rawValue) else {
OffshoreBudgeting/Views/WorkspaceProfilesView.swift:12:    @AppStorage(AppSettingsKeys.activeWorkspaceID.rawValue) private var activeWorkspaceIDRaw: String = ""
OffshoreBudgeting/Views/WorkspaceProfilesView.swift:108:    @AppStorage(AppSettingsKeys.activeWorkspaceID.rawValue) private var activeWorkspaceIDRaw: String = ""
OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift:21:    @AppStorage(AppSettingsKeys.confirmBeforeDelete.rawValue)
OffshoreBudgeting/App/Navigation/RootTabView.swift:54:    @AppStorage("uitest_seed_done") private var uiTestSeedDone: Bool = false
OffshoreBudgeting/App/Navigation/RootTabView.swift:78:    // MARK: Body builders
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:141:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:152:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:157:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:165:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:170:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:181:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:186:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:194:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:199:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:210:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:215:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:223:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:228:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:239:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:244:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:252:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:257:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:268:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:273:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:281:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:286:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:297:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:305:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:316:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:321:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:329:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:334:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:344:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return [] }
OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift:351:        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
OffshoreBudgeting/Core/Widgets/WidgetSha
```

### 4) Version/build sourcing scan
```
rg -n "CFBundleShortVersionString|CFBundleVersion|Bundle\\.main|infoDictionary|appVersion|buildNumber" OffshoreBudgeting -g"*.swift"
```
```
OffshoreBudgeting/AppUpdateLogs/2.1.swift:14:            let info = Bundle.main.infoDictionary
OffshoreBudgeting/AppUpdateLogs/2.1.swift:15:            let version = info?["CFBundleShortVersionString"] as? String ?? "0"
OffshoreBudgeting/AppUpdateLogs/2.1.swift:16:            let build = info?["CFBundleVersion"] as? String ?? "0"
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:7:            let info = Bundle.main.infoDictionary
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:8:            let version = info?["CFBundleShortVersionString"] as? String ?? "0"
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:9:            let build = info?["CFBundleVersion"] as? String ?? "0"
OffshoreBudgeting/AppUpdateLogs/2.0.swift:7:            let info = Bundle.main.infoDictionary
OffshoreBudgeting/AppUpdateLogs/2.0.swift:8:            let version = info?["CFBundleShortVersionString"] as? String ?? "0"
OffshoreBudgeting/AppUpdateLogs/2.0.swift:9:            let build = info?["CFBundleVersion"] as? String ?? "0"
OffshoreBudgeting/Views/SettingsView.swift:392:        let info = Bundle.main.infoDictionary
OffshoreBudgeting/Views/SettingsView.swift:576:                    Text(appVersionLine)
OffshoreBudgeting/Views/SettingsView.swift:624:    private var appVersionLine: String {
OffshoreBudgeting/Views/SettingsView.swift:625:        let info = Bundle.main.infoDictionary
OffshoreBudgeting/Views/SettingsView.swift:626:        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
OffshoreBudgeting/Views/SettingsView.swift:627:        let build = info?["CFBundleVersion"] as? String ?? "-"
OffshoreBudgeting/Support/Logging.swift:7:    static let subsystem = Bundle.main.bundleIdentifier ?? "OffshoreBudgeting"
OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:332:        let info = Bundle.main.infoDictionary
OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:333:        let version = info?["CFBundleShortVersionString"] as? String
OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift:334:        let build = info?["CFBundleVersion"] as? String
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:319:        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:340:        (Bundle.main.bundleIdentifier ?? "com.offshorebudgeting") + ".help"
OffshoreBudgeting/Views/HomeView.swift:443:        let info = Bundle.main.infoDictionary
OffshoreBudgeting/Views/HomeView.swift:444:        let version = info?["CFBundleShortVersionString"] as? String
OffshoreBudgeting/Views/HomeView.swift:445:        let build = info?["CFBundleVersion"] as? String
OffshoreBudgeting/Core/Security/AppLockKeychainStore.swift:18:        let bundleID = Bundle.main.bundleIdentifier ?? "com.offshorebudgeting"
```

