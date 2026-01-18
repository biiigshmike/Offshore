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
    @StateObject private var appSettings: AppSettingsState
    @StateObject private var onboarding: OnboardingState
    @StateObject private var homeWidgetState = HomeWidgetState()
    @StateObject private var uiTestingState: UITestingState
    @State private var coreDataReady = false
    @State private var didRunUITestBootstrap = false
    @State private var didStartAppServices = false
    @State private var dataReady = false
    @State private var dataRevision: Int = 0
    @State private var dataChangeObserver: NSObjectProtocol?
    @State private var homeContentReady = false
    @State private var homeDataObserver: NSObjectProtocol?
    @State private var didTriggerInitialAppLock = false
    private let platformCapabilities = PlatformCapabilities.current
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.scenePhase) private var scenePhase

    // MARK: App Lock (Biometrics)
    @StateObject private var appLockState: AppLockState
    @StateObject private var appLockViewModel: AppLockViewModel

    // MARK: Init
    init() {
        Self.configureForUITestingIfNeeded()
        _appSettings = StateObject(wrappedValue: AppSettingsState(store: UserDefaultsAppSettingsStore()))
        _onboarding = StateObject(wrappedValue: OnboardingState())
        _uiTestingState = StateObject(wrappedValue: UITestingState())

        let appLockState = AppLockState()
        _appLockState = StateObject(wrappedValue: appLockState)
        _appLockViewModel = StateObject(wrappedValue: AppLockViewModel(appLockState: appLockState))

        // Defer Core Data store loading and CardPickerStore start to onAppear
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
                        if onboarding.didCompleteOnboarding {
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
        let shouldInjectManagedObjectContext = coreDataReady || testFlags.isUITesting
        if shouldInjectManagedObjectContext {
            UBPerfDI.resolve("Resolve.CoreDataService.shared.viewContext", every: 25)
        }

        if UBPerf.isEnabled {
            UBPerfDI.inject("Env.ThemeManager", instance: themeManager)
            UBPerfDI.inject("Env.CardPickerStore", instance: cardPickerStore)
            UBPerfDI.inject("Env.AppSettingsState", instance: appSettings)
            UBPerfDI.inject("Env.OnboardingState", instance: onboarding)
            UBPerfDI.inject("Env.HomeWidgetState", instance: homeWidgetState)
            UBPerfDI.inject("Env.UITestingState", instance: uiTestingState)
            UBPerfDI.inject("Env.AppLockState", instance: appLockState)
            UBPerfDI.inject("Env.AppLockViewModel", instance: appLockViewModel)
        }

        let base = content()
            .environmentObject(themeManager)
            .environmentObject(cardPickerStore)
            .environmentObject(appSettings)
            .environmentObject(onboarding)
            .environmentObject(homeWidgetState)
            .environmentObject(uiTestingState)
            .environmentObject(appLockState)
            .environment(\.platformCapabilities, platformCapabilities)
            .environment(\.uiTestingFlags, testFlags)
            .environment(\.startTabIdentifier, startTab)
            .environment(\.startRouteIdentifier, startRoute)
            .environmentObject(appLockViewModel)
            .accentColor(themeManager.selectedTheme.resolvedTint)
            .tint(themeManager.selectedTheme.resolvedTint)
            .modifier(ThemedToggleTint(color: themeManager.selectedTheme.toggleTint))
            .onAppear {
                if testFlags.isUITesting, !testFlags.allowAppLock {
                    appLockViewModel.disableAppLockForUITests()
                }
#if DEBUG
                if testFlags.isUITesting {
                    configureAppLockForUITestingIfNeeded()
                }
#endif
                themeManager.refreshSystemAppearance(systemColorScheme)
                SystemThemeAdapter.applyGlobalChrome(
                    theme: themeManager.selectedTheme,
                    colorScheme: systemColorScheme,
                    platformCapabilities: platformCapabilities
                )

                appLockViewModel.refreshAvailability()
                if appLockViewModel.shouldRequireAuthentication, !didTriggerInitialAppLock {
                    didTriggerInitialAppLock = true
                    appLockViewModel.lock()
                    appLockViewModel.attemptUnlockWithBiometrics()
                }
                startAppServicesIfNeeded(testFlags: testFlags)
            }
            .onChange(of: onboarding.didCompleteOnboarding) { _ in
                startAppServicesIfNeeded(testFlags: testFlags)
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
                    if appLockViewModel.shouldRequireAuthentication {
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
            .if(shouldInjectManagedObjectContext) { view in
                view.environment(\.managedObjectContext, CoreDataService.shared.viewContext)
            }
        return base
    }

    @MainActor
    private func startAppServicesIfNeeded(testFlags: UITestingFlags) {
        if didStartAppServices { return }
#if DEBUG
        if testFlags.isUITesting, !onboarding.didCompleteOnboarding {
            return
        }
#endif
        didStartAppServices = true

        // Register for remote notifications so CloudKit can push changes.
        UIApplication.shared.registerForRemoteNotifications()

        Task { @MainActor in
            // Ensure stores are loaded in the background
            CoreDataService.shared.ensureLoaded()
            await CoreDataService.shared.waitUntilStoresLoaded()
#if DEBUG
            if testFlags.isUITesting, !didRunUITestBootstrap {
                didRunUITestBootstrap = true
                await seedAndResetIfNeededForUITesting(env: ProcessInfo.processInfo.environment)
            }
#endif
            // Initialize workspace and reflect cloud flags
            if appSettings.enableCloudSync {
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

    @MainActor
    private func startDataReadinessFlow() {
        let cloudOn = appSettings.enableCloudSync
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
            if ok {
                dataRevision &+= 1
                UBPerf.mark("DataRevision.increment", "reason=dataReadiness ok new=\(dataRevision)")
            }
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
                UBPerf.mark("DataRevision.increment", "reason=dataStoreDidChange dataReady=\(dataReady) homeContentReady=\(homeContentReady) new=\(dataRevision)")
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
    private static func configureForUITestingIfNeeded() {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo
        guard processInfo.arguments.contains("-ui-testing") else { return }
        let env = processInfo.environment
        let cloudAvailabilityOverride = env["UITEST_CLOUD_SYNC_AVAILABLE"]?.lowercased()
        if let rawWorkspaceID = env["UITEST_ACTIVE_WORKSPACE_ID"], !rawWorkspaceID.isEmpty {
            UserDefaults.standard.set(rawWorkspaceID, forKey: AppSettingsKeys.activeWorkspaceID.rawValue)
            UserDefaults.standard.synchronize()
        }
        if env["UITEST_SKIP_ONBOARDING"] == "1" {
            UserDefaults.standard.set(true, forKey: "didCompleteOnboarding")
            UserDefaults.standard.synchronize()
        }
        let shouldResetState = env["UITEST_RESET_STATE"] == "1"
        if shouldResetState {
            resetUserDefaultsForUITests()
            KeychainAppLockStore().deleteUnlockToken()
        }
        if env["UITEST_DISABLE_ANIMATIONS"] == "1" {
            UIView.setAnimationsEnabled(false)
        }

        if cloudAvailabilityOverride == "existing_data" || cloudAvailabilityOverride == "no_icloud" {
            UserDefaults.standard.set(true, forKey: AppSettingsKeys.enableCloudSync.rawValue)
            UserDefaults.standard.synchronize()
        } else if cloudAvailabilityOverride == "local" {
            UserDefaults.standard.set(false, forKey: AppSettingsKeys.enableCloudSync.rawValue)
            UserDefaults.standard.synchronize()
        }
        if env["UITEST_ENABLE_CLOUD_SYNC"] == "1" {
            UserDefaults.standard.set(true, forKey: AppSettingsKeys.enableCloudSync.rawValue)
            UserDefaults.standard.synchronize()
        } else if env["UITEST_ENABLE_CLOUD_SYNC"] == "0" {
            UserDefaults.standard.set(false, forKey: AppSettingsKeys.enableCloudSync.rawValue)
            UserDefaults.standard.synchronize()
        }
        #endif
    }

    @MainActor
    private func seedAndResetIfNeededForUITesting(env: [String: String]) async {
        let shouldResetState = env["UITEST_RESET_STATE"] == "1"
        if shouldResetState {
            do { try CoreDataService.shared.wipeAllData() } catch { /* non-fatal in UI tests */ }
        }

        guard let seed = env["UITEST_SEED"], !seed.isEmpty else { return }
        await seedForUITests(scenario: seed)
    }

    private static func resetUserDefaultsForUITests() {
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
        let processInfo = ProcessInfo.processInfo
        let isUITesting = processInfo.arguments.contains("-ui-testing")
        guard isUITesting else {
            return UITestingFlags(
                isUITesting: false,
                showTestControls: false,
                allowAppLock: false,
                deviceAuthAvailableOverride: nil,
                biometricAuthResult: nil,
                cloudAccountAvailableOverride: nil,
                cloudDataExistsOverride: nil
            )
        }

        let env = processInfo.environment
        let allowAppLock = env["UITEST_ALLOW_APP_LOCK"] == "1"
        let deviceAuthAvailableOverride = parseUITestBool(env["UITEST_DEVICE_AUTH_AVAILABLE"])
        let deviceAuthRaw = env["UITEST_DEVICE_AUTH_RESULT"] ?? env["UITEST_BIOMETRIC_RESULT"]
        let biometricAuthResult = deviceAuthRaw
            .flatMap { UITestBiometricAuthResult(rawValue: $0.lowercased()) }

        let injectedICloudState = env["UITEST_ICLOUD_STATE"]?.lowercased()
        let cloudAvailabilityOverride = env["UITEST_CLOUD_SYNC_AVAILABLE"]?.lowercased()
        let cloudAccountAvailableOverride: Bool?
        let cloudDataExistsOverride: Bool?
        switch injectedICloudState {
        case "found":
            cloudAccountAvailableOverride = true
            cloudDataExistsOverride = true
        case "none":
            // Deterministic "iCloud available, but no data present".
            cloudAccountAvailableOverride = true
            cloudDataExistsOverride = false
        default:
            switch cloudAvailabilityOverride {
            case "existing_data":
                cloudAccountAvailableOverride = true
                cloudDataExistsOverride = true
            case "no_icloud":
                cloudAccountAvailableOverride = false
                cloudDataExistsOverride = false
            case "local":
                cloudAccountAvailableOverride = false
                cloudDataExistsOverride = false
            default:
                cloudAccountAvailableOverride = parseUITestBool(env["UITEST_CLOUD_ACCOUNT_AVAILABLE"])
                cloudDataExistsOverride = parseUITestBool(env["UITEST_CLOUD_DATA_EXISTS"])
            }
        }

        return UITestingFlags(
            isUITesting: true,
            showTestControls: true,
            allowAppLock: allowAppLock,
            deviceAuthAvailableOverride: deviceAuthAvailableOverride,
            biometricAuthResult: biometricAuthResult,
            cloudAccountAvailableOverride: cloudAccountAvailableOverride,
            cloudDataExistsOverride: cloudDataExistsOverride
        )
    }

    private func configureAppLockForUITestingIfNeeded() {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo
        guard processInfo.arguments.contains("-ui-testing") else { return }
        let env = processInfo.environment
        let allowAppLock = env["UITEST_ALLOW_APP_LOCK"] == "1"
        guard allowAppLock else { return }
        let deviceAuthRaw = env["UITEST_DEVICE_AUTH_RESULT"] ?? env["UITEST_BIOMETRIC_RESULT"]
        let biometricResult = deviceAuthRaw
            .flatMap { UITestBiometricAuthResult(rawValue: $0.lowercased()) }
        let deviceAuthAvailableOverride = parseUITestBool(env["UITEST_DEVICE_AUTH_AVAILABLE"])
        let flags = UITestingFlags(
            isUITesting: true,
            showTestControls: true,
            allowAppLock: true,
            deviceAuthAvailableOverride: deviceAuthAvailableOverride,
            biometricAuthResult: biometricResult,
            cloudAccountAvailableOverride: nil,
            cloudDataExistsOverride: nil
        )
        appLockViewModel.configureForUITesting(flags: flags)
        #endif
    }
    private func parseUITestBool(_ raw: String?) -> Bool? {
        guard let raw else { return nil }
        switch raw.lowercased() {
        case "1", "true", "yes": return true
        case "0", "false", "no": return false
        default: return nil
        }
    }

    @MainActor
    func seedForUITests(scenario: String) async {
        let ctx = CoreDataService.shared.viewContext
        UserDefaults.standard.set(false, forKey: "uitest_seed_done")
        let markSeedDone = {
            UserDefaults.standard.set(true, forKey: "uitest_seed_done")
            UserDefaults.standard.synchronize()
        }
        let env = ProcessInfo.processInfo.environment
        let groceriesID = UUID(uuidString: "9B44A0A2-9E1E-4B1C-B8C9-2C7FD31F1E3A")!
        let testCatID = UUID(uuidString: "4E7B2C3F-6B1D-4F5F-AF6A-1D58D6F2A1D2")!
        let homeCategoryID = UUID(uuidString: "F6E9D6D1-7A68-4D65-AE7B-2B0F3E6E5A21")!
        let homeMonthlyBudgetID = UUID(uuidString: "7D2E8F1C-9A10-4E7B-8C6D-8A0C2A5E7B11")!
        let homeQuarterlyBudgetID = UUID(uuidString: "A3B1C2D3-4E5F-6789-ABCD-1234567890AB")!
        let homeYearlyBudgetID = UUID(uuidString: "B4C5D6E7-F809-1A2B-3C4D-5E6F708192A3")!
        let homeMonthlyCardID = UUID(uuidString: "1A2B3C4D-5E6F-4701-8A9B-0C1D2E3F4050")!
        let homeQuarterlyCardID = UUID(uuidString: "2B3C4D5E-6F70-4812-9ABC-1D2E3F405162")!
        let homeYearlyCardID = UUID(uuidString: "3C4D5E6F-7081-4923-ABCD-2E3F40516273")!
        let homeMonthlyPlannedID = UUID(uuidString: "4D5E6F70-8192-4A34-BCDE-3F4051627384")!
        let homeQuarterlyPlannedID = UUID(uuidString: "5E6F7081-9203-4B45-CDEF-405162738495")!
        let homeYearlyPlannedID = UUID(uuidString: "6F708192-0314-4C56-DEF0-516273849506")!
        let homeMonthlyUnplannedID = UUID(uuidString: "70819203-1425-4D67-EF01-627384950617")!
        let homeQuarterlyUnplannedID = UUID(uuidString: "81920314-2536-4E78-F012-738495061728")!
        let homeYearlyUnplannedID = UUID(uuidString: "92031425-3647-4F89-0123-849506172839")!
        let homeGlobalPresetID = UUID(uuidString: "A2031425-3647-4F89-0123-84950617283A")!
        let homeMonthlyPresetChildID = UUID(uuidString: "B3142536-4758-509A-1234-95061728394B")!
        let homeQuarterlyPresetChildID = UUID(uuidString: "C4253647-5869-60AB-2345-06172839405C")!
        let homeYearlyPresetChildID = UUID(uuidString: "D5364758-697A-70BC-3456-17283940516D")!
        switch scenario.lowercased() {
        case "cloud_workspace_mismatch":
            // Intentionally create a dataset under a specific workspaceID WITHOUT
            // updating the active workspace. This simulates a device where cloud
            // data is present but the app initially points at the wrong workspace.
            let fallbackWorkspaceID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
            let seededWorkspaceID = env["UITEST_SEED_WORKSPACE_ID"]
                .flatMap(UUID.init(uuidString:))
                ?? fallbackWorkspaceID

            // Ensure the backing Workspace row exists.
            // NOTE: Avoid calling WorkspaceService's internal seeding helpers here
            // so we don't unintentionally change the active workspace during this seed.
            let workspace = Workspace(context: ctx)
            workspace.id = seededWorkspaceID
            workspace.name = "Personal"
            if workspace.entity.attributesByName.keys.contains("isCloud") {
                workspace.isCloud = true
            }
            if workspace.entity.attributesByName.keys.contains("color"),
               (workspace.value(forKey: "color") as? String) == nil {
                workspace.setValue(WorkspaceService.defaultNewWorkspaceColorHex, forKey: "color")
            }

            // A simple, recognizable record set.
            let period = WorkspaceService.shared.currentBudgetPeriod(in: ctx)
            let range = period.range(containing: Date())

            let budget = Budget(context: ctx)
            budget.setValue(UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!, forKey: "id")
            budget.name = "Core Budget"
            budget.startDate = range.start
            budget.endDate = range.end
            budget.isRecurring = false
            budget.setValue(seededWorkspaceID, forKey: "workspaceID")

            let card = Card(context: ctx)
            card.setValue(UUID(uuidString: "BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF")!, forKey: "id")
            card.name = "Core Card"
            card.setValue(seededWorkspaceID, forKey: "workspaceID")
            card.mutableSetValue(forKey: "budget").add(budget)

            let category = ExpenseCategory(context: ctx)
            category.setValue(UUID(uuidString: "CCCCCCCC-DDDD-EEEE-FFFF-000000000000")!, forKey: "id")
            category.name = "Groceries"
            category.color = "#4E9CFF"
            category.setValue(seededWorkspaceID, forKey: "workspaceID")

            let income = Income(context: ctx)
            income.setValue(UUID(uuidString: "DDDDDDDD-EEEE-FFFF-0000-111111111111")!, forKey: "id")
            income.source = "Seeded Actual Income"
            income.amount = 101.33
            income.date = range.start
            income.isPlanned = false
            income.setValue(seededWorkspaceID, forKey: "workspaceID")

            try? ctx.save()
            markSeedDone()
            return
        case "core_universe":
            let workspaceID = WorkspaceService.shared.ensureActiveWorkspaceID()
            appSettings.activeWorkspaceID = workspaceID.uuidString
            appSettings.confirmBeforeDelete = true
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
        case "homeview_multi_budget":
            let workspaceID = WorkspaceService.shared.ensureActiveWorkspaceID()
            appSettings.activeWorkspaceID = workspaceID.uuidString
            appSettings.confirmBeforeDelete = true
            _ = WorkspaceService.shared.fetchOrCreateWorkspace(in: ctx)

            let calendar = Calendar.current
            let now = Date()
            let monthlyRange = BudgetPeriod.monthly.range(containing: now)
            let quarterlyRange = BudgetPeriod.quarterly.range(containing: now)
            let yearlyRange = BudgetPeriod.yearly.range(containing: now)

            var quarterMonthStarts: [Date] = []
            var quarterCursor = BudgetPeriod.monthly.start(of: quarterlyRange.start)
            while quarterCursor <= quarterlyRange.end {
                quarterMonthStarts.append(quarterCursor)
                guard let next = calendar.date(byAdding: .month, value: 1, to: quarterCursor) else { break }
                quarterCursor = next
            }
            let currentMonthStart = BudgetPeriod.monthly.start(of: now)
            let otherQuarterMonthStart = quarterMonthStarts.first(where: { !calendar.isDate($0, inSameDayAs: currentMonthStart) }) ?? currentMonthStart

            var yearMonthStarts: [Date] = []
            var yearCursor = BudgetPeriod.monthly.start(of: yearlyRange.start)
            while yearCursor <= yearlyRange.end {
                yearMonthStarts.append(yearCursor)
                guard let next = calendar.date(byAdding: .month, value: 1, to: yearCursor) else { break }
                yearCursor = next
            }
            let outsideQuarterMonthStart = yearMonthStarts.first(where: { $0 < quarterlyRange.start || $0 > quarterlyRange.end }) ?? currentMonthStart

            let category = ExpenseCategory(context: ctx)
            category.setValue(homeCategoryID, forKey: "id")
            category.name = "Seed Category"
            category.color = "#4E9CFF"
            category.setValue(workspaceID, forKey: "workspaceID")

            let monthlyBudget = Budget(context: ctx)
            monthlyBudget.setValue(homeMonthlyBudgetID, forKey: "id")
            monthlyBudget.name = "Monthly Budget"
            monthlyBudget.startDate = monthlyRange.start
            monthlyBudget.endDate = monthlyRange.end
            monthlyBudget.isRecurring = false
            WorkspaceService.applyWorkspaceIDIfPossible(on: monthlyBudget)

            let quarterlyBudget = Budget(context: ctx)
            quarterlyBudget.setValue(homeQuarterlyBudgetID, forKey: "id")
            quarterlyBudget.name = "Quarterly Budget"
            quarterlyBudget.startDate = quarterlyRange.start
            quarterlyBudget.endDate = quarterlyRange.end
            quarterlyBudget.isRecurring = false
            WorkspaceService.applyWorkspaceIDIfPossible(on: quarterlyBudget)

            let yearlyBudget = Budget(context: ctx)
            yearlyBudget.setValue(homeYearlyBudgetID, forKey: "id")
            yearlyBudget.name = "Yearly Budget"
            yearlyBudget.startDate = yearlyRange.start
            yearlyBudget.endDate = yearlyRange.end
            yearlyBudget.isRecurring = false
            WorkspaceService.applyWorkspaceIDIfPossible(on: yearlyBudget)

            let monthlyCard = Card(context: ctx)
            monthlyCard.setValue(homeMonthlyCardID, forKey: "id")
            monthlyCard.name = "Monthly Card"
            WorkspaceService.applyWorkspaceIDIfPossible(on: monthlyCard)
            monthlyCard.mutableSetValue(forKey: "budget").add(monthlyBudget)

            let quarterlyCard = Card(context: ctx)
            quarterlyCard.setValue(homeQuarterlyCardID, forKey: "id")
            quarterlyCard.name = "Quarterly Card"
            WorkspaceService.applyWorkspaceIDIfPossible(on: quarterlyCard)
            quarterlyCard.mutableSetValue(forKey: "budget").add(quarterlyBudget)

            let yearlyCard = Card(context: ctx)
            yearlyCard.setValue(homeYearlyCardID, forKey: "id")
            yearlyCard.name = "Yearly Card"
            WorkspaceService.applyWorkspaceIDIfPossible(on: yearlyCard)
            yearlyCard.mutableSetValue(forKey: "budget").add(yearlyBudget)

            let globalPreset = PlannedExpense(context: ctx)
            globalPreset.setValue(homeGlobalPresetID, forKey: "id")
            globalPreset.setValue("Seed Global Preset", forKey: "descriptionText")
            globalPreset.plannedAmount = 50
            globalPreset.actualAmount = 0
            globalPreset.transactionDate = monthlyRange.start
            globalPreset.isGlobal = true
            globalPreset.setValue(nil, forKey: "budget")
            globalPreset.setValue(workspaceID, forKey: "workspaceID")

            let monthlyPresetChild = PlannedExpense(context: ctx)
            monthlyPresetChild.setValue(homeMonthlyPresetChildID, forKey: "id")
            monthlyPresetChild.setValue("Seed Preset Child - Monthly", forKey: "descriptionText")
            monthlyPresetChild.plannedAmount = 50
            monthlyPresetChild.actualAmount = 15
            monthlyPresetChild.transactionDate = calendar.date(byAdding: .day, value: 3, to: monthlyRange.start)
            monthlyPresetChild.isGlobal = false
            monthlyPresetChild.globalTemplateID = homeGlobalPresetID
            monthlyPresetChild.setValue(monthlyBudget, forKey: "budget")
            monthlyPresetChild.card = monthlyCard
            monthlyPresetChild.expenseCategory = category
            monthlyPresetChild.setValue(workspaceID, forKey: "workspaceID")

            let quarterlyPresetChild = PlannedExpense(context: ctx)
            quarterlyPresetChild.setValue(homeQuarterlyPresetChildID, forKey: "id")
            quarterlyPresetChild.setValue("Seed Preset Child - Quarterly", forKey: "descriptionText")
            quarterlyPresetChild.plannedAmount = 75
            quarterlyPresetChild.actualAmount = 30
            quarterlyPresetChild.transactionDate = calendar.date(byAdding: .day, value: 4, to: otherQuarterMonthStart)
            quarterlyPresetChild.isGlobal = false
            quarterlyPresetChild.globalTemplateID = homeGlobalPresetID
            quarterlyPresetChild.setValue(quarterlyBudget, forKey: "budget")
            quarterlyPresetChild.card = quarterlyCard
            quarterlyPresetChild.expenseCategory = category
            quarterlyPresetChild.setValue(workspaceID, forKey: "workspaceID")

            let yearlyPresetChild = PlannedExpense(context: ctx)
            yearlyPresetChild.setValue(homeYearlyPresetChildID, forKey: "id")
            yearlyPresetChild.setValue("Seed Preset Child - Yearly", forKey: "descriptionText")
            yearlyPresetChild.plannedAmount = 120
            yearlyPresetChild.actualAmount = 40
            yearlyPresetChild.transactionDate = calendar.date(byAdding: .day, value: 5, to: outsideQuarterMonthStart)
            yearlyPresetChild.isGlobal = false
            yearlyPresetChild.globalTemplateID = homeGlobalPresetID
            yearlyPresetChild.setValue(yearlyBudget, forKey: "budget")
            yearlyPresetChild.card = yearlyCard
            yearlyPresetChild.expenseCategory = category
            yearlyPresetChild.setValue(workspaceID, forKey: "workspaceID")

            let monthlyPlanned = PlannedExpense(context: ctx)
            monthlyPlanned.setValue(homeMonthlyPlannedID, forKey: "id")
            monthlyPlanned.setValue("Seed Planned - Monthly", forKey: "descriptionText")
            monthlyPlanned.plannedAmount = 120
            monthlyPlanned.actualAmount = 80
            monthlyPlanned.transactionDate = calendar.date(byAdding: .day, value: 2, to: monthlyRange.start)
            monthlyPlanned.isGlobal = false
            monthlyPlanned.setValue(monthlyBudget, forKey: "budget")
            monthlyPlanned.card = monthlyCard
            monthlyPlanned.expenseCategory = category
            monthlyPlanned.setValue(workspaceID, forKey: "workspaceID")

            let quarterlyPlanned = PlannedExpense(context: ctx)
            quarterlyPlanned.setValue(homeQuarterlyPlannedID, forKey: "id")
            quarterlyPlanned.setValue("Seed Planned - Quarterly", forKey: "descriptionText")
            quarterlyPlanned.plannedAmount = 300
            quarterlyPlanned.actualAmount = 240
            quarterlyPlanned.transactionDate = calendar.date(byAdding: .day, value: 2, to: otherQuarterMonthStart)
            quarterlyPlanned.isGlobal = false
            quarterlyPlanned.setValue(quarterlyBudget, forKey: "budget")
            quarterlyPlanned.card = quarterlyCard
            quarterlyPlanned.expenseCategory = category
            quarterlyPlanned.setValue(workspaceID, forKey: "workspaceID")

            let yearlyPlanned = PlannedExpense(context: ctx)
            yearlyPlanned.setValue(homeYearlyPlannedID, forKey: "id")
            yearlyPlanned.setValue("Seed Planned - Yearly", forKey: "descriptionText")
            yearlyPlanned.plannedAmount = 900
            yearlyPlanned.actualAmount = 700
            yearlyPlanned.transactionDate = calendar.date(byAdding: .day, value: 2, to: outsideQuarterMonthStart)
            yearlyPlanned.isGlobal = false
            yearlyPlanned.setValue(yearlyBudget, forKey: "budget")
            yearlyPlanned.card = yearlyCard
            yearlyPlanned.expenseCategory = category
            yearlyPlanned.setValue(workspaceID, forKey: "workspaceID")

            let monthlyUnplanned = UnplannedExpense(context: ctx)
            monthlyUnplanned.setValue(homeMonthlyUnplannedID, forKey: "id")
            monthlyUnplanned.descriptionText = "Seed Unplanned - Monthly"
            monthlyUnplanned.amount = 30
            monthlyUnplanned.transactionDate = calendar.date(byAdding: .day, value: 1, to: monthlyRange.start)
            monthlyUnplanned.card = monthlyCard
            monthlyUnplanned.expenseCategory = category
            monthlyUnplanned.setValue(workspaceID, forKey: "workspaceID")

            let quarterlyUnplanned = UnplannedExpense(context: ctx)
            quarterlyUnplanned.setValue(homeQuarterlyUnplannedID, forKey: "id")
            quarterlyUnplanned.descriptionText = "Seed Unplanned - Quarterly"
            quarterlyUnplanned.amount = 60
            quarterlyUnplanned.transactionDate = calendar.date(byAdding: .day, value: 1, to: otherQuarterMonthStart)
            quarterlyUnplanned.card = quarterlyCard
            quarterlyUnplanned.expenseCategory = category
            quarterlyUnplanned.setValue(workspaceID, forKey: "workspaceID")

            let yearlyUnplanned = UnplannedExpense(context: ctx)
            yearlyUnplanned.setValue(homeYearlyUnplannedID, forKey: "id")
            yearlyUnplanned.descriptionText = "Seed Unplanned - Yearly"
            yearlyUnplanned.amount = 150
            yearlyUnplanned.transactionDate = calendar.date(byAdding: .day, value: 1, to: outsideQuarterMonthStart)
            yearlyUnplanned.card = yearlyCard
            yearlyUnplanned.expenseCategory = category
            yearlyUnplanned.setValue(workspaceID, forKey: "workspaceID")

            let monthlyPlannedIncome = Income(context: ctx)
            monthlyPlannedIncome.setValue(UUID(), forKey: "id")
            monthlyPlannedIncome.source = "Seed Planned Income - Monthly"
            monthlyPlannedIncome.amount = 1000
            monthlyPlannedIncome.date = calendar.date(byAdding: .day, value: 10, to: currentMonthStart)
            monthlyPlannedIncome.isPlanned = true
            monthlyPlannedIncome.setValue(workspaceID, forKey: "workspaceID")

            let monthlyActualIncome = Income(context: ctx)
            monthlyActualIncome.setValue(UUID(), forKey: "id")
            monthlyActualIncome.source = "Seed Actual Income - Monthly"
            monthlyActualIncome.amount = 700
            monthlyActualIncome.date = calendar.date(byAdding: .day, value: 12, to: currentMonthStart)
            monthlyActualIncome.isPlanned = false
            monthlyActualIncome.setValue(workspaceID, forKey: "workspaceID")

            let quarterlyPlannedIncome = Income(context: ctx)
            quarterlyPlannedIncome.setValue(UUID(), forKey: "id")
            quarterlyPlannedIncome.source = "Seed Planned Income - Quarterly"
            quarterlyPlannedIncome.amount = 2000
            quarterlyPlannedIncome.date = calendar.date(byAdding: .day, value: 10, to: otherQuarterMonthStart)
            quarterlyPlannedIncome.isPlanned = true
            quarterlyPlannedIncome.setValue(workspaceID, forKey: "workspaceID")

            let quarterlyActualIncome = Income(context: ctx)
            quarterlyActualIncome.setValue(UUID(), forKey: "id")
            quarterlyActualIncome.source = "Seed Actual Income - Quarterly"
            quarterlyActualIncome.amount = 1200
            quarterlyActualIncome.date = calendar.date(byAdding: .day, value: 12, to: otherQuarterMonthStart)
            quarterlyActualIncome.isPlanned = false
            quarterlyActualIncome.setValue(workspaceID, forKey: "workspaceID")

            let yearlyPlannedIncome = Income(context: ctx)
            yearlyPlannedIncome.setValue(UUID(), forKey: "id")
            yearlyPlannedIncome.source = "Seed Planned Income - Yearly"
            yearlyPlannedIncome.amount = 3000
            yearlyPlannedIncome.date = calendar.date(byAdding: .day, value: 10, to: outsideQuarterMonthStart)
            yearlyPlannedIncome.isPlanned = true
            yearlyPlannedIncome.setValue(workspaceID, forKey: "workspaceID")

            let yearlyActualIncome = Income(context: ctx)
            yearlyActualIncome.setValue(UUID(), forKey: "id")
            yearlyActualIncome.source = "Seed Actual Income - Yearly"
            yearlyActualIncome.amount = 1500
            yearlyActualIncome.date = calendar.date(byAdding: .day, value: 12, to: outsideQuarterMonthStart)
            yearlyActualIncome.isPlanned = false
            yearlyActualIncome.setValue(workspaceID, forKey: "workspaceID")

            try? ctx.save()
            markSeedDone()
            return
        case "homeview_no_budget":
            let workspaceID = WorkspaceService.shared.ensureActiveWorkspaceID()
            appSettings.activeWorkspaceID = workspaceID.uuidString
            appSettings.confirmBeforeDelete = true
            _ = WorkspaceService.shared.fetchOrCreateWorkspace(in: ctx)

            let calendar = Calendar.current
            var components = DateComponents()
            components.year = 2000
            components.month = 1
            components.day = 1
            let start = calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
            let end = calendar.date(byAdding: .day, value: 30, to: start) ?? start

            let category = ExpenseCategory(context: ctx)
            category.setValue(homeCategoryID, forKey: "id")
            category.name = "Seed Category"
            category.color = "#4E9CFF"
            category.setValue(workspaceID, forKey: "workspaceID")

            let budget = Budget(context: ctx)
            budget.setValue(homeMonthlyBudgetID, forKey: "id")
            budget.name = "Legacy Budget"
            budget.startDate = start
            budget.endDate = end
            budget.isRecurring = false
            WorkspaceService.applyWorkspaceIDIfPossible(on: budget)

            let card = Card(context: ctx)
            card.setValue(homeMonthlyCardID, forKey: "id")
            card.name = "Legacy Card"
            WorkspaceService.applyWorkspaceIDIfPossible(on: card)
            card.mutableSetValue(forKey: "budget").add(budget)

            let globalPreset = PlannedExpense(context: ctx)
            globalPreset.setValue(homeGlobalPresetID, forKey: "id")
            globalPreset.setValue("Seed Global Preset", forKey: "descriptionText")
            globalPreset.plannedAmount = 50
            globalPreset.actualAmount = 0
            globalPreset.transactionDate = start
            globalPreset.isGlobal = true
            globalPreset.setValue(nil, forKey: "budget")
            globalPreset.setValue(workspaceID, forKey: "workspaceID")

            let presetChild = PlannedExpense(context: ctx)
            presetChild.setValue(homeMonthlyPresetChildID, forKey: "id")
            presetChild.setValue("Seed Preset Child - Legacy", forKey: "descriptionText")
            presetChild.plannedAmount = 50
            presetChild.actualAmount = 15
            presetChild.transactionDate = calendar.date(byAdding: .day, value: 3, to: start)
            presetChild.isGlobal = false
            presetChild.globalTemplateID = homeGlobalPresetID
            presetChild.setValue(budget, forKey: "budget")
            presetChild.card = card
            presetChild.expenseCategory = category
            presetChild.setValue(workspaceID, forKey: "workspaceID")

            let planned = PlannedExpense(context: ctx)
            planned.setValue(homeMonthlyPlannedID, forKey: "id")
            planned.setValue("Seed Planned - Legacy", forKey: "descriptionText")
            planned.plannedAmount = 120
            planned.actualAmount = 80
            planned.transactionDate = calendar.date(byAdding: .day, value: 2, to: start)
            planned.isGlobal = false
            planned.setValue(budget, forKey: "budget")
            planned.card = card
            planned.expenseCategory = category
            planned.setValue(workspaceID, forKey: "workspaceID")

            let unplanned = UnplannedExpense(context: ctx)
            unplanned.setValue(homeMonthlyUnplannedID, forKey: "id")
            unplanned.descriptionText = "Seed Unplanned - Legacy"
            unplanned.amount = 30
            unplanned.transactionDate = calendar.date(byAdding: .day, value: 1, to: start)
            unplanned.card = card
            unplanned.expenseCategory = category
            unplanned.setValue(workspaceID, forKey: "workspaceID")

            let plannedIncome = Income(context: ctx)
            plannedIncome.setValue(UUID(), forKey: "id")
            plannedIncome.source = "Seed Planned Income - Legacy"
            plannedIncome.amount = 1000
            plannedIncome.date = calendar.date(byAdding: .day, value: 10, to: start)
            plannedIncome.isPlanned = true
            plannedIncome.setValue(workspaceID, forKey: "workspaceID")

            let actualIncome = Income(context: ctx)
            actualIncome.setValue(UUID(), forKey: "id")
            actualIncome.source = "Seed Actual Income - Legacy"
            actualIncome.amount = 700
            actualIncome.date = calendar.date(byAdding: .day, value: 12, to: start)
            actualIncome.isPlanned = false
            actualIncome.setValue(workspaceID, forKey: "workspaceID")

            try? ctx.save()
            markSeedDone()
            return
        case "categories_empty":
            let workspaceID = WorkspaceService.shared.ensureActiveWorkspaceID()
            appSettings.activeWorkspaceID = workspaceID.uuidString
            appSettings.confirmBeforeDelete = true
            markSeedDone()
            return
        case "categories_with_one":
            let workspaceID = WorkspaceService.shared.ensureActiveWorkspaceID()
            appSettings.activeWorkspaceID = workspaceID.uuidString
            appSettings.confirmBeforeDelete = true

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
            appSettings.activeWorkspaceID = workspaceID.uuidString
            appSettings.confirmBeforeDelete = true

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
