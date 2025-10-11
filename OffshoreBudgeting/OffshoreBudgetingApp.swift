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
        content()
            .environment(\.managedObjectContext, CoreDataService.shared.viewContext)
            .environmentObject(themeManager)
            .environmentObject(cardPickerStore)
            .environment(\.platformCapabilities, platformCapabilities)
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
