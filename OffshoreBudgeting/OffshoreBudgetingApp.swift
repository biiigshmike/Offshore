//
//  OffshoreBudgetingApp.swift
//  OffshoreBudgeting
//
//  Created by Michael Brown on 8/11/25.
//

import SwiftUI
import UIKit
import Combine

@main
struct OffshoreBudgetingApp: App {
    // UIApplicationDelegate bridge for remote notifications
    @UIApplicationDelegateAdaptor(OffshoreAppDelegate.self) private var appDelegate

    // MARK: Dependencies
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var cardPickerStore = CardPickerStore()
    @State private var coreDataReady = false
    @State private var dataReady = false
    @State private var dataRevision: Int = 0
    @State private var dataChangeObserver: NSObjectProtocol?
    @State private var homeContentReady = false
    @State private var homeDataObserver: NSObjectProtocol?
    @State private var didTriggerInitialAppLock = false
    private let platformCapabilities = PlatformCapabilities.current
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.scenePhase) private var scenePhase

    // MARK: Onboarding State
    /// Persisted flag indicating whether the intro flow has been completed.
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false

    // MARK: App Lock (Biometrics)
    @StateObject private var appLockViewModel = AppLockViewModel()

    // MARK: Init
    init() {
        // Defer Core Data store loading and CardPickerStore start to onAppear
        configureForUITestingIfNeeded()
        logPlatformCapabilities()
        let labelAppearance = UILabel.appearance()
        labelAppearance.adjustsFontSizeToFitWidth = true
        labelAppearance.minimumScaleFactor = 0.75
        labelAppearance.lineBreakMode = .byClipping
    }

    var body: some Scene {
        WindowGroup {
            configuredScene {
                ResponsiveLayoutReader { _ in
                    ZStack {
                        if didCompleteOnboarding {
                            RootTabView(isWorkspaceReady: workspaceReady)
                                .environment(\.dataRevision, dataRevision)
                                .transition(.opacity)
                        } else {
                            CloudSyncGateView()
                                .transition(.opacity)
                        }

                        // MARK: App Lock Overlay (optional privacy mask)
                        if appLockViewModel.isLockEnabled && (appLockViewModel.isLocked || appLockViewModel.isAuthenticating) {
                            AppLockView(viewModel: appLockViewModel)
                                .transition(.opacity)
                        }
                    }
                }
            }
        }
#if targetEnvironment(macCatalyst)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Offshore Budgeting Help") {
                    requestHelpScene()
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
#endif

#if targetEnvironment(macCatalyst)
        WindowGroup(id: catalystHelpSceneIdentifier) {
            configuredScene {
                HelpView()
            }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: helpActivityType))
#endif
    }

    // MARK: Scene Wiring
    private func configuredScene<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let overrides = testUIOverridesIfAny()
        let testFlags = uiTestingFlagsIfAny()
        let startTab = ProcessInfo.processInfo.environment["UITEST_START_TAB"]
#if DEBUG
        let startRoute = ProcessInfo.processInfo.environment["UITEST_START_ROUTE"]
#else
        let startRoute: String? = nil
#endif
        let base = content()
            .environmentObject(themeManager)
            .environmentObject(cardPickerStore)
            .environment(\.platformCapabilities, platformCapabilities)
            .environment(\.uiTestingFlags, testFlags)
            .environment(\.startTabIdentifier, startTab)
            .environment(\.startRouteIdentifier, startRoute)
            .accentColor(themeManager.selectedTheme.resolvedTint)
            .tint(themeManager.selectedTheme.resolvedTint)
            .modifier(ThemedToggleTint(color: themeManager.selectedTheme.toggleTint))
            .onAppear {
                if testFlags.isUITesting {
                    appLockViewModel.isLockEnabled = false
                }
                themeManager.refreshSystemAppearance(systemColorScheme)
                SystemThemeAdapter.applyGlobalChrome(
                    theme: themeManager.selectedTheme,
                    colorScheme: systemColorScheme,
                    platformCapabilities: platformCapabilities
                )

                if appLockViewModel.isLockEnabled && !didTriggerInitialAppLock {
                    didTriggerInitialAppLock = true
                    appLockViewModel.lock()
                    appLockViewModel.attemptUnlockWithBiometrics()
                }

                // Register for remote notifications so CloudKit can push changes.
                UIApplication.shared.registerForRemoteNotifications()
                Task { @MainActor in
                    // Ensure stores are loaded in the background
                    CoreDataService.shared.ensureLoaded()
                    await CoreDataService.shared.waitUntilStoresLoaded()
                    // Initialize workspace and reflect cloud flags
                    if UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue) {
                        if CloudDataProbe().hasAnyData() { UbiquitousFlags.setHasCloudDataTrue() }
                    }
                    await WorkspaceService.shared.initializeOnLaunch()

                    // No BudgetPreferenceSync – budget period mirrors via Core Data (Workspace)
                    cardPickerStore.start()
                    coreDataReady = true
                    startDataReadinessFlow()
                    startObservingDataChanges()
                    startObservingHomeReadiness()
                    CloudSyncAccelerator.shared.nudgeOnForeground()
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["INIT_CLOUDKIT_SCHEMA"] == "1" {
                        await CoreDataService.shared.initializeCloudKitSchemaIfNeeded()
                    }
                    #endif
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    CloudSyncAccelerator.shared.nudgeOnForeground()
                    LocalNotificationScheduler.shared.recordAppOpen()
                    Task { await LocalNotificationScheduler.shared.refreshAll() }

                    // Foreground return: prompt once if still locked.
                    if appLockViewModel.isLockEnabled
                        && didTriggerInitialAppLock
                        && appLockViewModel.isLocked
                        && !appLockViewModel.isAuthenticating
                    {
                        appLockViewModel.attemptUnlockWithBiometrics()
                    }
                } else if newPhase == .background {
                    // Centralize background locking here to avoid races
                    if appLockViewModel.isLockEnabled {
                        appLockViewModel.lock()
                    }
                }
            }
            .onChange(of: systemColorScheme) { newScheme in
                themeManager.refreshSystemAppearance(newScheme)
                SystemThemeAdapter.applyGlobalChrome(
                    theme: themeManager.selectedTheme,
                    colorScheme: newScheme,
                    platformCapabilities: platformCapabilities
                )
            }
            .onChange(of: themeManager.selectedTheme) { _ in
                SystemThemeAdapter.applyGlobalChrome(
                    theme: themeManager.selectedTheme,
                    colorScheme: systemColorScheme,
                    platformCapabilities: platformCapabilities
                )
            }
            .modifier(TestUIOverridesModifier(overrides: overrides))
            .if(coreDataReady) { view in
                view.environment(\.managedObjectContext, CoreDataService.shared.viewContext)
            }
        return base
    }

    @MainActor
    private func startDataReadinessFlow() {
        let cloudOn = UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue)
        if !cloudOn {
            dataReady = true
            return
        }
        dataReady = false
        Task { @MainActor in
            let remoteHas = await CloudDataRemoteProbe().hasAnyRemoteData(timeout: 4.0)
            if !remoteHas {
                dataReady = true
                return
            }
            async let importDone: Bool = CloudSyncMonitor.shared.awaitInitialImport(timeout: 10.0)
            async let localData: Bool = CloudDataProbe().scanForExistingData(timeout: 8.0, pollInterval: 0.25)
            let a = await importDone
            let b = await localData
            let ok = a || b
            dataReady = ok
            if ok { dataRevision &+= 1 }
            if ok { CloudSyncAccelerator.shared.nudgeOnForeground() }
        }
    }

    private var workspaceReady: Bool {
        coreDataReady && cardPickerStore.isReady
    }

    @MainActor
    private func startObservingDataChanges() {
        if dataChangeObserver != nil { return }
        dataChangeObserver = NotificationCenter.default.addObserver(
            forName: .dataStoreDidChange,
            object: nil,
            queue: .main
        ) { _ in
            if !dataReady && !homeContentReady {
                dataRevision &+= 1
            }
        }
    }

    @MainActor
    private func startObservingHomeReadiness() {
        guard homeDataObserver == nil else { return }
        homeDataObserver = NotificationCenter.default.addObserver(
            forName: .homeViewInitialDataLoaded,
            object: nil,
            queue: .main
        ) { _ in
            self.homeContentReady = true
            if let observer = self.homeDataObserver {
                NotificationCenter.default.removeObserver(observer)
                self.homeDataObserver = nil
            }
        }
    }


    // MARK: UI Testing Helpers
    private func configureForUITestingIfNeeded() {
#if DEBUG
        let processInfo = ProcessInfo.processInfo
        guard processInfo.arguments.contains("-ui-testing") else { return }
        let env = processInfo.environment
        if env["UITEST_SKIP_ONBOARDING"] == "1" {
            UserDefaults.standard.set(true, forKey: "didCompleteOnboarding")
            UserDefaults.standard.synchronize()
        }
        let shouldResetState = env["UITEST_RESET_STATE"] == "1"
        if shouldResetState {
            resetUserDefaultsForUITests()
        }
        if env["UITEST_DISABLE_ANIMATIONS"] == "1" {
            UIView.setAnimationsEnabled(false)
        }
        if let seed = env["UITEST_SEED"], !seed.isEmpty {
            Task { @MainActor in
                await CoreDataService.shared.waitUntilStoresLoaded(timeout: 5.0)
                if shouldResetState {
                    do { try CoreDataService.shared.wipeAllData() } catch { /* non-fatal in UI tests */ }
                }
                await seedForUITests(scenario: seed)
            }
        } else if shouldResetState {
            resetPersistentStateForUITests()
        }
#endif
    }

    private func resetPersistentStateForUITests() {
        resetUserDefaultsForUITests()
        Task { @MainActor in
            await CoreDataService.shared.waitUntilStoresLoaded(timeout: 3.0)
            do { try CoreDataService.shared.wipeAllData() } catch { /* non-fatal in UI tests */ }
        }
    }

    private func resetUserDefaultsForUITests() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        let defaults = UserDefaults.standard
        defaults.removePersistentDomain(forName: bundleIdentifier)
        #if DEBUG
        let skip = ProcessInfo.processInfo.environment["UITEST_SKIP_ONBOARDING"] == "1"
        defaults.set(skip, forKey: "didCompleteOnboarding")
        #else
        defaults.set(false, forKey: "didCompleteOnboarding")
        #endif
        defaults.synchronize()
    }

    private func logPlatformCapabilities() {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        let runtimeVersion = ProcessInfo.processInfo.environment["SIMULATOR_RUNTIME_VERSION"] ?? "n/a"
        AppLog.ui.info("PlatformCapabilities.current supportsOS26Translucency=\(platformCapabilities.supportsOS26Translucency, privacy: .public) supportsAdaptiveKeypad=\(platformCapabilities.supportsAdaptiveKeypad, privacy: .public) osVersion=\(versionString, privacy: .public) runtimeVersion=\(runtimeVersion, privacy: .public)")
    }

#if targetEnvironment(macCatalyst)
    private var helpActivityType: String {
        (Bundle.main.bundleIdentifier ?? "com.offshorebudgeting") + ".help"
    }

    private var catalystHelpSceneIdentifier: String { "help" }

    private func requestHelpScene() {
        let activity = NSUserActivity(activityType: helpActivityType)
        activity.title = "Offshore Budgeting Help"
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
    }
#endif
}

// MARK: - Test UI Overrides
private struct TestUIOverridesModifier: ViewModifier {
    struct Overrides {
        var colorScheme: ColorScheme?
        var sizeCategory: ContentSizeCategory?
        var locale: Locale?
    }

    let overrides: Overrides

    func body(content: Content) -> some View {
        var view = AnyView(content)
        if let scheme = overrides.colorScheme {
            view = AnyView(view.preferredColorScheme(scheme))
        }
        if let sz = overrides.sizeCategory {
            view = AnyView(view.environment(\.sizeCategory, sz))
        }
        if let loc = overrides.locale {
            view = AnyView(view.environment(\.locale, loc))
        }
        return view
    }
}

private extension OffshoreBudgetingApp {
    func testUIOverridesIfAny() -> TestUIOverridesModifier.Overrides {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo
        guard processInfo.arguments.contains("-ui-testing") else { return .init(colorScheme: nil, sizeCategory: nil, locale: nil) }
        let env = processInfo.environment

        let scheme: ColorScheme? = {
            switch env["UITEST_COLOR_SCHEME"]?.lowercased() {
            case "dark": return .dark
            case "light": return .light
            default: return nil
            }
        }()

        let sizeCategory: ContentSizeCategory? = {
            guard let raw = env["UITEST_SIZE_CATEGORY"]?.lowercased() else { return nil }
            let map: [String: ContentSizeCategory] = [
                "xs": .extraSmall,
                "s": .small,
                "m": .medium,
                "l": .large,
                "xl": .extraLarge,
                "xxl": .extraExtraLarge,
                "xxxl": .extraExtraExtraLarge,
                "axl": .accessibilityLarge,
                "axxl": .accessibilityExtraLarge,
                "axxxl": .accessibilityExtraExtraLarge,
                "axxxxl": .accessibilityExtraExtraExtraLarge
            ]
            return map[raw]
        }()

        let locale: Locale? = {
            if let ident = env["UITEST_LOCALE"], !ident.isEmpty { return Locale(identifier: ident) }
            return nil
        }()

        if let tzIdent = env["UITEST_TIMEZONE"], let tz = TimeZone(identifier: tzIdent) {
            NSTimeZone.default = tz
        }

        return .init(colorScheme: scheme, sizeCategory: sizeCategory, locale: locale)
        #else
        return .init(colorScheme: nil, sizeCategory: nil, locale: nil)
        #endif
    }

    func uiTestingFlagsIfAny() -> UITestingFlags {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        if isUITesting { return UITestingFlags(isUITesting: true, showTestControls: true) }
        return UITestingFlags(isUITesting: false, showTestControls: false)
    }

    @MainActor
    func seedForUITests(scenario: String) async {
        let ctx = CoreDataService.shared.viewContext
        UserDefaults.standard.set(false, forKey: "uitest_seed_done")
        let markSeedDone = {
            UserDefaults.standard.set(true, forKey: "uitest_seed_done")
            UserDefaults.standard.synchronize()
        }
        let groceriesID = UUID(uuidString: "9B44A0A2-9E1E-4B1C-B8C9-2C7FD31F1E3A")!
        let testCatID = UUID(uuidString: "4E7B2C3F-6B1D-4F5F-AF6A-1D58D6F2A1D2")!
        switch scenario.lowercased() {
        case "core_universe":
            let workspaceID = WorkspaceService.shared.ensureActiveWorkspaceID()
            UserDefaults.standard.set(workspaceID.uuidString, forKey: AppSettingsKeys.activeWorkspaceID.rawValue)
            UserDefaults.standard.set(true, forKey: AppSettingsKeys.confirmBeforeDelete.rawValue)
            _ = WorkspaceService.shared.fetchOrCreateWorkspace(in: ctx)

            let budgetID = UUID(uuidString: "DCE9E4FD-4EC7-4EA1-9A67-1E5C3A3A8AA1")!
            let cardID = UUID(uuidString: "B51F1C5D-3FD7-4C5F-BBBE-8B5A6F5D8F70")!
            let categoryID = UUID(uuidString: "C8AFB4B9-5F10-4EB4-9C12-06D6E86B7C2B")!
            let plannedExpenseID = UUID(uuidString: "8E6DCA5A-9D1C-4C91-85B9-A990C4B2E199")!
            let unplannedExpenseID = UUID(uuidString: "B8A91A83-3E7E-4B27-BAC1-3F66D6463D2D")!
            let presetTemplateID = UUID(uuidString: "6E71C8A6-2A7F-4F87-8D4A-4B3E7A3C1CC1")!
            let plannedIncomeID = UUID(uuidString: "2D2072C4-2F80-4F32-9E7B-8A9D0D2F6B15")!
            let actualIncomeID = UUID(uuidString: "E2A6D5D3-9F38-4F8B-8C35-3A2A9E45D821")!

            let period = WorkspaceService.shared.currentBudgetPeriod(in: ctx)
            let range = period.range(containing: Date())

            let budget = Budget(context: ctx)
            budget.setValue(budgetID, forKey: "id")
            budget.name = "Core Budget"
            budget.startDate = range.start
            budget.endDate = range.end
            budget.isRecurring = false
            WorkspaceService.applyWorkspaceIDIfPossible(on: budget)

            let card = Card(context: ctx)
            card.setValue(cardID, forKey: "id")
            card.name = "Core Card"
            WorkspaceService.applyWorkspaceIDIfPossible(on: card)
            card.mutableSetValue(forKey: "budget").add(budget)

            let category = ExpenseCategory(context: ctx)
            category.setValue(categoryID, forKey: "id")
            category.name = "Groceries"
            category.color = "#4E9CFF"
            category.setValue(workspaceID, forKey: "workspaceID")

            let planned = PlannedExpense(context: ctx)
            planned.setValue(plannedExpenseID, forKey: "id")
            planned.setValue("Seeded Planned", forKey: "descriptionText")
            planned.plannedAmount = 25
            planned.actualAmount = 12
            planned.transactionDate = Calendar.current.date(byAdding: .day, value: 2, to: range.start) ?? Date()
            planned.isGlobal = false
            planned.setValue(budget, forKey: "budget")
            planned.card = card
            planned.expenseCategory = category
            planned.setValue(workspaceID, forKey: "workspaceID")

            let template = PlannedExpense(context: ctx)
            template.setValue(presetTemplateID, forKey: "id")
            template.setValue("Seeded Preset", forKey: "descriptionText")
            template.plannedAmount = 40
            template.actualAmount = 0
            template.transactionDate = range.start
            template.isGlobal = true
            template.setValue(nil, forKey: "budget")
            template.setValue(workspaceID, forKey: "workspaceID")

            let unplanned = UnplannedExpense(context: ctx)
            unplanned.setValue(unplannedExpenseID, forKey: "id")
            unplanned.descriptionText = "Seeded Unplanned"
            unplanned.amount = 9
            unplanned.transactionDate = Calendar.current.date(byAdding: .day, value: 1, to: range.start) ?? Date()
            unplanned.card = card
            unplanned.expenseCategory = category
            unplanned.setValue(workspaceID, forKey: "workspaceID")

            let plannedIncome = Income(context: ctx)
            plannedIncome.setValue(plannedIncomeID, forKey: "id")
            plannedIncome.source = "Seeded Planned Income"
            plannedIncome.amount = 1500
            plannedIncome.date = Date()
            plannedIncome.isPlanned = true
            plannedIncome.setValue(workspaceID, forKey: "workspaceID")

            let actualIncome = Income(context: ctx)
            actualIncome.setValue(actualIncomeID, forKey: "id")
            actualIncome.source = "Seeded Actual Income"
            actualIncome.amount = 900
            actualIncome.date = Date()
            actualIncome.isPlanned = false
            actualIncome.setValue(workspaceID, forKey: "workspaceID")

            try? ctx.save()
            markSeedDone()
            return
        case "categories_empty":
            let workspaceID = WorkspaceService.shared.ensureActiveWorkspaceID()
            UserDefaults.standard.set(workspaceID.uuidString, forKey: AppSettingsKeys.activeWorkspaceID.rawValue)
            UserDefaults.standard.set(true, forKey: AppSettingsKeys.confirmBeforeDelete.rawValue)
            markSeedDone()
            return
        case "categories_with_one":
            let workspaceID = WorkspaceService.shared.ensureActiveWorkspaceID()
            UserDefaults.standard.set(workspaceID.uuidString, forKey: AppSettingsKeys.activeWorkspaceID.rawValue)
            UserDefaults.standard.set(true, forKey: AppSettingsKeys.confirmBeforeDelete.rawValue)

            let category = ExpenseCategory(context: ctx)
            category.setValue(groceriesID, forKey: "id")
            category.name = "Groceries"
            category.color = "#4E9CFF"
            category.setValue(workspaceID, forKey: "workspaceID")

            let planned = PlannedExpense(context: ctx)
            planned.setValue(UUID(), forKey: "id")
            planned.descriptionText = "Seeded Planned"
            planned.plannedAmount = 10
            planned.actualAmount = 8
            planned.transactionDate = Date()
            planned.isGlobal = false
            planned.expenseCategory = category
            planned.setValue(workspaceID, forKey: "workspaceID")

            let unplanned = UnplannedExpense(context: ctx)
            unplanned.setValue(UUID(), forKey: "id")
            unplanned.descriptionText = "Seeded Unplanned"
            unplanned.amount = 5
            unplanned.transactionDate = Date()
            unplanned.expenseCategory = category
            unplanned.setValue(workspaceID, forKey: "workspaceID")

            try? ctx.save()
            markSeedDone()
            return
        case "categories_with_testcat":
            let workspaceID = WorkspaceService.shared.ensureActiveWorkspaceID()
            UserDefaults.standard.set(workspaceID.uuidString, forKey: AppSettingsKeys.activeWorkspaceID.rawValue)
            UserDefaults.standard.set(true, forKey: AppSettingsKeys.confirmBeforeDelete.rawValue)

            let category = ExpenseCategory(context: ctx)
            category.setValue(testCatID, forKey: "id")
            category.name = "Test Cat"
            category.color = "#4E9CFF"
            category.setValue(workspaceID, forKey: "workspaceID")

            try? ctx.save()
            markSeedDone()
            return
        case "empty":
            markSeedDone()
            return
        case "demo":
            markSeedDone()
            return
        case "income1":
            let inc = Income(context: ctx)
            inc.setValue(UUID(), forKey: "id")
            inc.source = "Seeded"
            inc.amount = 42.0
            inc.isPlanned = true
            inc.date = Date()
            WorkspaceService.shared.applyWorkspaceID(on: inc)
            try? ctx.save()
            markSeedDone()
        default:
            markSeedDone()
            return
        }
    }
}

private struct ThemedToggleTint: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        if #available(iOS 15.0, macCatalyst 15.0, *) {
            content.toggleStyle(SwitchToggleStyle(tint: color))
        } else {
            content
        }
    }
}
