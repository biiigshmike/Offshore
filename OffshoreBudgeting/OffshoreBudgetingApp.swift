//
//  OffshoreBudgetingApp.swift
//  OffshoreBudgeting
//
//  Created by Michael Brown on 8/11/25.
//

import SwiftUI
import UIKit

@main
struct OffshoreBudgetingApp: App {
    // MARK: Dependencies
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var cardPickerStore: CardPickerStore
    private let platformCapabilities = PlatformCapabilities.current
    @Environment(\.colorScheme) private var systemColorScheme

    // MARK: Onboarding State
    /// Persisted flag indicating whether the intro flow has been completed.
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false

    // MARK: Init
    init() {
        let cardPickerStore = CardPickerStore()
        _cardPickerStore = StateObject(wrappedValue: cardPickerStore)
        CoreDataService.shared.ensureLoaded()
        configureForUITestingIfNeeded()
        // Removed test seeding hook (UITestDataSeeder) to avoid requiring
        // UI test-only code in the main app target.
        cardPickerStore.start()
        logPlatformCapabilities()
        // No macOS-specific setup required at the moment.
        // Reduce the chance of text truncation across the app by allowing
        // UILabel-backed Text views to shrink when space is constrained.
        let labelAppearance = UILabel.appearance()
        labelAppearance.adjustsFontSizeToFitWidth = true
        labelAppearance.minimumScaleFactor = 0.75
        labelAppearance.lineBreakMode = .byClipping
    }

    var body: some Scene {
        WindowGroup {
            configuredScene {
                ResponsiveLayoutReader { _ in
                    Group {
                        if didCompleteOnboarding {
                            RootTabView()
                        } else {
                            OnboardingView()
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
    @ViewBuilder
    private func configuredScene<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let overrides = testUIOverridesIfAny()
        let testFlags = uiTestingFlagsIfAny()
        let startTab = ProcessInfo.processInfo.environment["UITEST_START_TAB"]
        content()
            .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
            .environmentObject(themeManager)
            .environmentObject(cardPickerStore)
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
                seedForUITests(scenario: seed)
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
    func seedForUITests(scenario: String) {
        let ctx = CoreDataService.shared.viewContext
        switch scenario.lowercased() {
        case "empty":
            return
        case "income1":
            let inc = Income(context: ctx)
            inc.setValue(UUID(), forKey: "id")
            inc.source = "Seeded"
            inc.amount = 42.0
            inc.isPlanned = true
            inc.date = Date()
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
