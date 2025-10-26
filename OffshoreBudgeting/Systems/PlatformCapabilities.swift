import SwiftUI

// MARK: - Overview
/// Platform- and version-derived feature toggles used to keep SwiftUI
/// codepaths clean. Centralizes OS 26 “Liquid Glass” vs. classic behaviors
/// and related affordances so view modifiers can remain declarative.

// MARK: - Capabilities Model
/// Runtime-evaluated feature toggles that describe which platform niceties are
/// available on the current device. Inject a single instance at the app entry
/// point so that every scene and modifier can consult the same source of
/// truth when opting into newer system behaviours.
struct PlatformCapabilities: Equatable {
    /// Whether the current OS supports the refreshed translucent chrome
    /// treatments Apple shipped alongside the OS 26 cycle (iOS/iPadOS,
    /// macCatalyst).
    let supportsOS26Translucency: Bool

    /// Whether the adaptive numeric keyboard layout from OS 26 is available on
    /// this device. Only meaningful on iOS builds.
    let supportsAdaptiveKeypad: Bool
}

extension PlatformCapabilities {
    /// Snapshot the current process' capabilities using the most specific
    /// availability information we have at launch.
    /// - Note: Honors debug overrides to force legacy chrome for QA.
    static var current: PlatformCapabilities {
        // Liquid Glass is available starting with the OS 26 system releases.
        // Align the feature gate to each platform's modern availability so the
        // macCatalyst runtime on macOS 26 correctly opts into glass alongside
        // iOS/iPadOS peers.
        var supportsModernTranslucency = resolveOS26TranslucencySupport()

        // Developer / QA override to simulate legacy behaviour on devices
        // that support Liquid Glass. Debug‑only so Release builds always
        // prioritize OS26 styling on modern devices.
        let forceLegacyByEnv = ProcessInfo.processInfo.environment["UB_FORCE_LEGACY_CHROME"] == "1" // CI/dev knob
        let forceLegacyByDefaults = UserDefaults.standard.bool(forKey: "UBForceLegacyChrome")
        if forceLegacyByEnv || forceLegacyByDefaults {
            supportsModernTranslucency = false
        }

        #if targetEnvironment(macCatalyst)
        let supportsAdaptiveKeypad = false // Catalyst does not present iOS keypad layouts.
        #else
        let supportsAdaptiveKeypad = supportsModernTranslucency // Mirrors OS 26 adoption on iOS/iPadOS.
        #endif

        return PlatformCapabilities(
            supportsOS26Translucency: supportsModernTranslucency,
            supportsAdaptiveKeypad: supportsAdaptiveKeypad
        )
    }

    // MARK: Resolution Logic
    /// Determines whether the current process should consider OS 26 translucency
    /// features available, based on compile-time platform and runtime availability.
    private static func resolveOS26TranslucencySupport() -> Bool {
#if targetEnvironment(macCatalyst)
        if #available(macCatalyst 26.0, *) { return true }
        return fallbackMacCatalyst26Support()
#elseif os(macOS)
        if #available(macOS 26.0, *) { return true }
        return false
#elseif os(iOS)
        if #available(iOS 26.0, *) { return true }
        return false
#else
        return false
#endif
    }

#if targetEnvironment(macCatalyst)
    // MARK: Catalyst Fallbacks
    /// Some early macCatalyst 26 runtimes may not satisfy the availability
    /// checks that Xcode bakes into the binary. As a safety net, inspect the
    /// host's `ProcessInfo` so modern macOS 15+ builds still opt into glass.
    private static func fallbackMacCatalyst26Support(
        processInfo: ProcessInfo = .processInfo
    ) -> Bool {
        if processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: 15, minorVersion: 0, patchVersion: 0)
        ) {
            return true
        }

        if let runtimeVersion = processInfo.environment["SIMULATOR_RUNTIME_VERSION"],
           runtimeVersionIndicatesOS26(runtimeVersion) {
            return true
        }

        return false
    }

    /// Returns `true` when the Simulator runtime string maps to the iOS 26
    /// family (e.g. "26.0", "26.1").
    private static func runtimeVersionIndicatesOS26(_ version: String) -> Bool {
        guard let majorComponent = version.split(separator: ".").first,
              let major = Int(majorComponent) else {
            return false
        }
        return major >= 26
    }
#endif

    /// Baseline set of capabilities used as a default value in the environment.
    static let fallback = PlatformCapabilities(supportsOS26Translucency: false, supportsAdaptiveKeypad: false)
}

// MARK: - Environment support

/// Environment key for injecting `PlatformCapabilities` into SwiftUI view trees.
private struct PlatformCapabilitiesKey: EnvironmentKey {
    static let defaultValue: PlatformCapabilities = .fallback
}

extension EnvironmentValues {
    /// Active platform capabilities for this view hierarchy.
    var platformCapabilities: PlatformCapabilities {
        get { self[PlatformCapabilitiesKey.self] }
        set { self[PlatformCapabilitiesKey.self] = newValue }
    }
}

extension PlatformCapabilities {
    /// Debug-only telemetry helper to trace the chrome policy decision at call sites.
    /// - Parameters:
    ///   - component: Human-friendly component name (e.g., "List", "NavBar").
    ///   - path: Hierarchy or identifier to locate the call site.
    func qaLogLiquidGlassDecision(component: String, path: String) {
        AppLog.ui.debug(
            "LiquidGlassQA component=\(component, privacy: .public) path=\(path, privacy: .public) supportsOS26Translucency=\(supportsOS26Translucency, privacy: .public)"
        )
    }
}
