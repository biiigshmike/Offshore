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
    @State private var isSyncing = false
    @State private var dataRevision: Int = 0
    @State private var dataChangeObserver: NSObjectProtocol?
    private let platformCapabilities = PlatformCapabilities.current
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.scenePhase) private var scenePhase

    // MARK: Onboarding State
    /// Persisted flag indicating whether the intro flow has been completed.
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false

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
                        // Base content (only when Core Data + stores are ready)
                        if coreDataReady, cardPickerStore != nil {
                            if didCompleteOnboarding {
                                RootTabView()
                                    .environment(\.dataRevision, dataRevision)
                                    .transition(.opacity)
                            } else {
                                CloudSyncGateView()
                                    .transition(.opacity)
                            }
                        }
                        // Glass setup overlay while preparing/syncing
                        if !dataReady || !coreDataReady || cardPickerStore == nil {
                            WorkspaceSetupView(isSyncing: isSyncing)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: dataReady)
                    .animation(.easeInOut(duration: 0.25), value: coreDataReady)
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
            // Apply the selected theme's accent color to all controls.
            // `tint` covers most modern SwiftUI controls, while `accentColor`
            // is still required for some AppKit-backed macOS components
            // (e.g., checkboxes, date pickers) to respect the theme.
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
                    // Re-apply cloud preference if needed and initialize workspace
                    if UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue) {
                        await CoreDataService.shared.applyCloudSyncPreferenceChange(enableSync: true)
                        if CloudDataProbe().hasAnyData() { UbiquitousFlags.setHasCloudDataTrue() }
                    }
                    await WorkspaceService.shared.initializeOnLaunch()

                    // Ensure KVS-based sync services reflect current settings
                    CardAppearanceStore.shared.applySettingsChanged()
                    BudgetPreferenceSync.shared.applySettingsChanged()
                    // Create the CardPickerStore now that Core Data is ready
                    if cardPickerStore == nil {
                        let store = CardPickerStore()
                        cardPickerStore = store
                        store.start()
                    }
                    coreDataReady = true
                    startDataReadinessFlow()
                    startObservingDataChanges()
                    // Nudge CloudKit while foreground to accelerate initial sync visibility.
                    CloudSyncAccelerator.shared.nudgeOnForeground()
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    CloudSyncAccelerator.shared.nudgeOnForeground()
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
            // Apply test-only UI overrides (color scheme, content size, locale)
            .modifier(TestUIOverridesModifier(overrides: overrides))
            // Inject the managedObjectContext only after stores are ready to avoid main-thread I/O warning.
            .if(coreDataReady) { view in
                view.environment(\.managedObjectContext, CoreDataService.shared.viewContext)
            }
        return base
    }

    private var syncPlaceholderText: String {
        let cloudOn = UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue)
        return cloudOn ? (isSyncing ? "Syncing from iCloud…" : "Loading…") : "Loading…"
    }

    @MainActor
    private func startDataReadinessFlow() {
        let cloudOn = UserDefaults.standard.bool(forKey: AppSettingsKeys.enableCloudSync.rawValue)
        if !cloudOn {
            dataReady = true
            return
        }
        dataReady = false
        isSyncing = true
        Task { @MainActor in
            // If remote likely empty, don’t wait long.
            let remoteHas = await CloudDataRemoteProbe().hasAnyRemoteData(timeout: 4.0)
            if !remoteHas {
                // No remote data expected; proceed immediately.
                dataReady = true
                isSyncing = false
                return
            }
            // Wait for either import to complete or any data to appear locally.
            async let importDone: Bool = CloudSyncMonitor.shared.awaitInitialImport(timeout: 10.0)
            async let localData: Bool = CloudDataProbe().scanForExistingData(timeout: 8.0, pollInterval: 0.25)
            let a = await importDone
            let b = await localData
            let ok = a || b
            dataReady = ok
            isSyncing = false
            if ok { dataRevision &+= 1 }
            // After initial import is satisfied, issue one more gentle nudge so
            // any straggling pushes land while the main UI is up.
            if ok { CloudSyncAccelerator.shared.nudgeOnForeground() }
        }
    }

    @MainActor
    private func startObservingDataChanges() {
        if dataChangeObserver != nil { return }
        dataChangeObserver = NotificationCenter.default.addObserver(
            forName: .dataStoreDidChange,
            object: nil,
            queue: .main
        ) { _ in
            // Only force a one-time refresh while the setup overlay is still visible.
            if !dataReady {
                dataRevision &+= 1
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
            // Mark onboarding complete so tabs show immediately
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
        // Stores may still be loading asynchronously. Wait, then wipe.
        Task { @MainActor in
            await CoreDataService.shared.waitUntilStoresLoaded(timeout: 3.0)
            do { try CoreDataService.shared.wipeAllData() } catch { /* non-fatal in UI tests */ }
        }
    }

    private func resetUserDefaultsForUITests() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        let defaults = UserDefaults.standard
        defaults.removePersistentDomain(forName: bundleIdentifier)
        // Respect skip-onboarding flag when resetting defaults for UI tests
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

        // Color scheme: "light" or "dark"
        let scheme: ColorScheme? = {
            switch env["UITEST_COLOR_SCHEME"]?.lowercased() {
            case "dark": return .dark
            case "light": return .light
            default: return nil
            }
        }()

        // Dynamic Type size category (e.g., "XXL", "accessibilityXL")
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

        // Locale override, e.g., "de_DE", "en_US"
        let locale: Locale? = {
            if let ident = env["UITEST_LOCALE"], !ident.isEmpty { return Locale(identifier: ident) }
            return nil
        }()

        // Time zone override, e.g., "UTC" or "America/Los_Angeles"
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
