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
    @State private var cardPickerStore: CardPickerStore?
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
        // Defer Core Data store loading and CardPickerStore creation to onAppear
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
        let base = content()
            .environmentObject(themeManager)
            .ifLet(cardPickerStore) { view, store in
                view.environmentObject(store)
            }
            .environment(\.platformCapabilities, platformCapabilities)
            .environment(\.uiTestingFlags, testFlags)
            .environment(\.startTabIdentifier, startTab)
            .accentColor(themeManager.selectedTheme.resolvedTint)
            .tint(themeManager.selectedTheme.resolvedTint)
            .modifier(ThemedToggleTint(color: themeManager.selectedTheme.toggleTint))
            .onAppear {
                themeManager.refreshSystemAppearance(systemColorScheme)
                SystemThemeAdapter.applyGlobalChrome(
                    theme: themeManager.selectedTheme,
                    colorScheme: systemColorScheme,
                    platformCapabilities: platformCapabilities
                )

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
                    if cardPickerStore == nil {
                        let store = CardPickerStore()
                        cardPickerStore = store
                        store.start()
                    }
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
            .onChange(of: homeContentReady) { isReady in
                guard isReady else { return }
                guard !didTriggerInitialAppLock else { return }
                guard appLockViewModel.isLockEnabled else { return }
                didTriggerInitialAppLock = true
                appLockViewModel.lock()
                appLockViewModel.attemptUnlockWithBiometrics()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    CloudSyncAccelerator.shared.nudgeOnForeground()
                    LocalNotificationScheduler.shared.recordAppOpen()
                    Task { await LocalNotificationScheduler.shared.refreshAll() }

                    // Foreground return: prompt once if still locked.
                    if appLockViewModel.isLockEnabled && didTriggerInitialAppLock && appLockViewModel.isLocked {
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
        coreDataReady && cardPickerStore != nil
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
        if env["UITEST_RESET_STATE"] == "1" {
            resetPersistentStateForUITests()
        }
        if env["UITEST_DISABLE_ANIMATIONS"] == "1" {
            UIView.setAnimationsEnabled(false)
        }
        if let seed = env["UITEST_SEED"], !seed.isEmpty {
            Task { @MainActor in
                await CoreDataService.shared.waitUntilStoresLoaded(timeout: 5.0)
                await seedForUITests(scenario: seed)
            }
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
        #if DEBUG
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        if isUITesting { return UITestingFlags(isUITesting: true, showTestControls: true) }
        #endif
        return UITestingFlags(isUITesting: false, showTestControls: false)
    }

    @MainActor
    func seedForUITests(scenario: String) async {
        let ctx = CoreDataService.shared.viewContext
        switch scenario.lowercased() {
        case "empty":
            return
        case "demo":
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
        default:
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
