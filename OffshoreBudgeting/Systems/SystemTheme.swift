import SwiftUI
import UIKit

// MARK: - Overview
/// Adapter that selects between Liquid Glass (OS 26 cycle) and Classic styling
/// (earlier OS versions) and applies minimal, platform-appropriate global
/// chrome for legacy systems. Keeps UI code paths simple and declarative.

/// Central adapter that decides whether the system should use Liquid Glass (OS 26
/// cycle) or Classic styling (earlier OS versions), and applies minimal global
/// chrome where appropriate for legacy systems.
enum SystemThemeAdapter {
    // MARK: Flavor
    /// High-level system look the app should adopt based on capabilities.
    enum Flavor { case liquid, classic }

    /// Resolves the current flavor using `.current` platform capabilities.
    static var currentFlavor: Flavor { flavor() }

    /// Computes the system flavor from a capability snapshot.
    /// - Parameter capabilities: Platform flags for the running process.
    /// - Returns: `.liquid` on OS 26 (translucency available), otherwise `.classic`.
    static func flavor(for capabilities: PlatformCapabilities = .current) -> Flavor {
        capabilities.supportsOS26Translucency ? .liquid : .classic
    }

    /// Apply minimal, system-friendly global chrome. On OS 26 we avoid
    /// overriding system appearances per Apple guidance. On earlier OS versions,
    /// we set plain, opaque backgrounds to respect the classic, flat style.
    /// The supplied `platformCapabilities` snapshot ensures every scene makes
    /// the same chrome decision without re-evaluating availability checks.
    /// Applies minimal, system-friendly global chrome only for classic systems.
    /// On OS 26, defers to system defaults (no overrides).
    /// - Parameters:
    ///   - theme: Active app theme used to derive legacy chrome colors.
    ///   - colorScheme: Resolved color scheme, if known, to pick readable text colors.
    ///   - platformCapabilities: Platform feature snapshot to keep decisions consistent.
    static func applyGlobalChrome(
        theme: AppTheme,
        colorScheme: ColorScheme?,
        platformCapabilities: PlatformCapabilities = .current
    ) {
        // Always prefer large titles so OS26 shows the big title on initial load.
        UINavigationBar.appearance().prefersLargeTitles = true

        guard !platformCapabilities.supportsOS26Translucency else { return }

        // UINavigationBar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = theme.legacyUIKitChromeBackgroundColor(colorScheme: colorScheme)
        // Ensure readable titles/buttons for classic (opaque) chrome.
        let resolvedTitleColor = resolvedForegroundColor(for: theme, colorScheme: colorScheme)
        navAppearance.titleTextAttributes = [.foregroundColor: resolvedTitleColor]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: resolvedTitleColor]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().isTranslucent = false

        // UIToolbar (avoid custom backgrounds on OS 26; safe on classic)
        let toolAppearance = UIToolbarAppearance()
        toolAppearance.configureWithOpaqueBackground()
        let resolvedBackground = theme.legacyUIKitChromeBackgroundColor(colorScheme: colorScheme)
        toolAppearance.backgroundColor = resolvedBackground
        UIToolbar.appearance().standardAppearance = toolAppearance
        UIToolbar.appearance().compactAppearance = toolAppearance
        UIToolbar.appearance().scrollEdgeAppearance = toolAppearance

        // UITabBar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = resolvedBackground
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().isTranslucent = false
    }

    /// Picks a readable title/controls color for classic opaque chrome.
    /// Prefers white in dark mode and black in light mode.
    private static func resolvedForegroundColor(
        for theme: AppTheme,
        colorScheme: ColorScheme?
    ) -> UIColor {
        // On classic chrome, prefer white text for dark mode backgrounds.
        // For light mode, prefer black text. This keeps titles readable
        // against the legacy chrome backgrounds computed above.
        if let scheme = colorScheme {
            return (scheme == .dark) ? UIColor.white : UIColor.black
        }
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        return isDark ? UIColor.white : UIColor.black
    }
}
