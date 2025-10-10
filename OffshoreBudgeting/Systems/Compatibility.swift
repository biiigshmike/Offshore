//
//  Compatibility.swift
//  SoFar
//
//  Cross-platform helpers to keep SwiftUI views tidy by hiding
//  platform/version differences behind neutral modifiers and types.
//

import SwiftUI
import UIKit

// MARK: - Overview
/// Compatibility helpers and presentation policies used across SwiftUI views.
///
/// Scope:
/// - Unifies version/platform divergences behind small, localized modifiers.
/// - Concentrates decisions about Liquid Glass vs. classic/opaque backgrounds.
/// - Provides UIKit bridges when SwiftUI lacks direct affordances.
/// - Avoids changing any runtime logic; all branches and availability remain intact.

// MARK: - Glass Background Policy

/// Centralized policy for deciding when the app should render Liquid Glass
/// backgrounds versus classic opaque fills. We rely on the combination of the
/// current theme and the resolved platform capabilities so tests can simulate
/// OS 26 (glass available) and OS 15.4 (opaque) configurations without
/// sprinkling conditional logic across individual modifiers.
struct UBGlassBackgroundPolicy {
    /// Determines whether surface-level backgrounds (root pages, navigation)
    /// should adopt the custom glass treatment. Themes like `.system` opt out
    /// even on modern OS builds to mirror Apple's stock styling.
    /// - Parameters:
    ///   - theme: Active app theme which may opt-in/opt-out of glass.
    ///   - capabilities: Resolved platform capability flags (e.g., OS 26 glass).
    /// - Returns: `true` to enable custom liquid/glass surface backgrounds.
    static func shouldUseGlassSurfaces(
        theme: AppTheme,
        capabilities: PlatformCapabilities
    ) -> Bool {
        capabilities.supportsOS26Translucency && theme.usesGlassMaterials
    }

    /// Determines whether container chrome (tab bars, navigation bars) should
    /// defer to the system's built-in glass materials. On legacy OS versions we
    /// return `false` so modifiers can fall back to opaque backgrounds that
    /// match the classic design.
    /// - Parameter capabilities: Resolved platform capability flags.
    /// - Returns: `true` when native OS chrome should be used (OS 26).
    static func shouldUseSystemChrome(capabilities: PlatformCapabilities) -> Bool {
        capabilities.supportsOS26Translucency
    }
}

// MARK: - SwiftUI View Extensions (Cross-Platform)

extension View {

    // MARK: ub_onChange(of:initial:)
    /// Bridges the macOS 14 / iOS 17 `onChange` overloads with earlier operating systems.
    /// - Parameters:
    ///   - value: The equatable value to observe.
    ///   - initial: Whether the action should fire immediately on appear.
    ///   - action: A closure executed whenever `value` changes.
    /// - Returns: A view that performs the provided action when `value` changes.
    func ub_onChange<Value: Equatable>(
        of value: Value,
        initial: Bool = false,
        _ action: @escaping () -> Void
    ) -> some View {
        modifier(
            UBOnChangeWithoutValueModifier(
                value: value,
                initial: initial,
                action: action
            )
        )
    }

    /// Bridges the macOS 14 / iOS 17 `onChange` overloads with earlier operating systems.
    /// Provides the new value back to the caller whenever it changes.
    /// - Parameters:
    ///   - value: The equatable value to observe.
    ///   - initial: Whether the action should fire immediately on appear.
    ///   - action: A closure receiving the new value whenever `value` changes.
    /// - Returns: A view that performs the provided action when `value` changes.
    func ub_onChange<Value: Equatable>(
        of value: Value,
        initial: Bool = false,
        _ action: @escaping (Value) -> Void
    ) -> some View {
        modifier(
            UBOnChangeWithValueModifier(
                value: value,
                initial: initial,
                action: action
            )
        )
    }

    // Removed: ub_noAutoCapsAndCorrection()
    // Removed: ub_toolbarTitleInline(), ub_toolbarTitleLarge()
    // Removed: ub_tabNavigationTitle(_:)

    // MARK: ub_rootNavigationChrome()
    /// Hides the navigation bar background for root-level navigation stacks on modern OS releases.
    /// Earlier platforms ignore the call so they retain their default opaque chrome.
    @ViewBuilder
    func ub_rootNavigationChrome() -> some View {
        modifier(UBRootNavigationChromeModifier())
    }

    // MARK: ub_cardTitleShadow()
    /// Tight, offset shadow for card titles (small 3D lift). Softer gray tone, not harsh black.
    /// Use on text layers: `.ub_cardTitleShadow()`
    /// - Returns: A view with a subtle title shadow applied.
    func ub_cardTitleShadow() -> some View {
        return self.shadow(
            color: UBTypography.cardTitleShadowColor,
            radius: 0.8,
            x: 0,
            y: 1.2
        )
    }
    
    // MARK: ub_compactDatePickerStyle()
    /// Applies `.compact` date picker style where available (iPhone/iPad), no-op elsewhere.
    /// - Returns: The same view on unsupported platforms; otherwise compact-styled picker.
    func ub_compactDatePickerStyle() -> some View {
        #if targetEnvironment(macCatalyst)
        return self
        #else
        return self
        #endif
    }
    
    // Removed: ub_decimalKeyboard()

    /// Applies the platform-aware OS 26 translucent background when supported,
    /// falling back to the provided base color elsewhere.
    /// - Parameters:
    ///   - baseColor: The theme/tint-aware fallback color.
    ///   - configuration: Fine-tuning for highlight/specular/shadow characteristics.
    ///   - edges: Optional edges that should extend through the safe area.
    /// - Returns: A view with either glass or flat background applied.
    func ub_glassBackground(
        _ baseColor: Color,
        configuration: AppTheme.GlassConfiguration = .standard,
        ignoringSafeArea edges: Edge.Set = []
    ) -> some View {
        modifier(
            UBGlassBackgroundModifier(
                baseColor: baseColor,
                configuration: configuration,
                ignoresSafeAreaEdges: edges
            )
        )
    }

    /// Applies either the custom glass background or a plain system background
    /// depending on the active theme.
    /// - Parameters:
    ///   - theme: The active app theme controlling glass usage.
    ///   - configuration: Fine-tuning for the glass parameters.
    ///   - edges: Edges to extend through the safe area if needed.
    /// - Returns: A view with a theme-appropriate surface background.
    func ub_surfaceBackground(
        _ theme: AppTheme,
        configuration: AppTheme.GlassConfiguration,
        ignoringSafeArea edges: Edge.Set = []
    ) -> some View {
        modifier(
            UBSurfaceBackgroundModifier(
                theme: theme,
                configuration: configuration,
                ignoresSafeAreaEdges: edges
            )
        )
    }

    /// Applies navigation styling appropriate for the current theme. System
    /// theme favors the platform's plain backgrounds while custom themes keep
    /// the glass treatment.
    /// - Parameters:
    ///   - theme: The active app theme controlling glass usage.
    ///   - configuration: Glass configuration used on eligible systems.
    /// - Returns: A view that adopts theme-aware navigation backgrounds.
    func ub_navigationBackground(
        theme: AppTheme,
        configuration: AppTheme.GlassConfiguration
    ) -> some View {
        modifier(
            UBNavigationBackgroundModifier(
                theme: theme,
                configuration: configuration
            )
        )
    }

    // (Removed) ub_navigationGlassBackground – unused wrapper.
    // (Removed) ub_chromeGlassBackground – unused wrapper.

    /// Applies theme-aware chrome styling for tab bars and other container chrome.
    /// - Parameters:
    ///   - theme: The active app theme controlling glass usage.
    ///   - configuration: Glass configuration used on eligible systems.
    /// - Returns: A view with theme-aware chrome background.
    func ub_chromeBackground(
        theme: AppTheme,
        configuration: AppTheme.GlassConfiguration
    ) -> some View {
        modifier(
            UBChromeBackgroundModifier(
                theme: theme,
                configuration: configuration
            )
        )
    }

    // MARK: ub_formStyleGrouped()
    /// Applies a grouped form style on platforms that support it.  On iOS 16+
    /// and macOS 13+, `.formStyle(.grouped)` gives a subtle, neutral
    /// background with inset sections.  On older systems or platforms that
    /// don’t support it, this is a no-op so the view still compiles.  Use
    /// this helper instead of sprinkling `#if` checks throughout your views.
    /// - Returns: A view with grouped form style when available; otherwise unchanged.
    func ub_formStyleGrouped() -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            return self.formStyle(.grouped)
        } else {
            return self
        }
    }

    // Removed: ub_sheetPadding()

    // MARK: ub_pickerBackground()
    /// Applies the app’s container background behind a scrollable picker (e.g.
    /// card or budget pickers).  Without a background, horizontal `ScrollView`s
    /// in a form may render on pure white on macOS and grouped gray on iOS.
    /// Applying this ensures consistency across platforms.  You can call
    /// `.ub_pickerBackground()` on a `ScrollView` or any container view to
    /// unify its background.
    /// - Returns: A view with a unified container background applied.
    func ub_pickerBackground() -> some View {
        self.background(DS.Colors.containerBackground)
    }

    // MARK: ub_hideScrollIndicators()
    /// Hides scroll indicators consistently across platforms.  On iOS and
    /// macOS this sets `.scrollIndicators(.hidden)` when available; on older
    /// versions it falls back to the legacy API.  Use this to avoid
    /// repetitive availability checks.
    /// - Returns: A view with scroll indicators hidden where supported.
    func ub_hideScrollIndicators() -> some View {
        if #available(iOS 16.0, macCatalyst 16.0, *) {
            return self.scrollIndicators(.hidden)
        } else {
            return self
        }
    }

    // MARK: ub_disableHorizontalBounce()
    /// Disables horizontal bouncing on the enclosing `UIScrollView`. SwiftUI does not
    /// expose this knob directly, so we bridge via a lightweight `UIViewRepresentable`
    /// that walks up the view hierarchy and toggles the UIKit flags.
    /// - Returns: A view that disables horizontal bouncing on the underlying scroll view.
    func ub_disableHorizontalBounce() -> some View {
        overlay(alignment: .topLeading) {
            UBHorizontalBounceDisabler()
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
    }

    // MARK: ub_listStyleLiquidAware()
    /// Applies OS-aware list styling:
    /// - On OS 26: use `.automatic` so the system’s Liquid Glass list treatment shows through.
    /// - On earlier OSes: prefer `.insetGrouped` and hide the scroll background (iOS 16+/macOS 13+)
    ///   so our app’s surface background remains consistent.
    /// - Returns: A view whose list style adapts to OS capabilities.
    func ub_listStyleLiquidAware() -> some View {
        modifier(UBListStyleLiquidAwareModifier())
    }

    // MARK: ub_preOS26ListRowBackground(_:)
    /// Applies a list row background only on pre‑OS26 systems. On OS26 this is a no-op so
    /// the system’s default row background (Liquid Glass) can be used.
    /// - Parameter color: The background color for list rows on pre‑OS26.
    /// - Returns: A view that conditionally sets the list row background.
    func ub_preOS26ListRowBackground(_ color: Color) -> some View {
        modifier(UBPreOS26ListRowBackgroundModifier(color: color))
    }
}

// MARK: - UIKit Bridges
/// Host view that disables horizontal bounce on the nearest enclosing `UIScrollView`.
private struct UBHorizontalBounceDisabler: UIViewRepresentable {
    /// Creates the host view that will scan the ancestor chain for a scroll view.
    func makeUIView(context: Context) -> UBHorizontalBounceDisablingView {
        UBHorizontalBounceDisablingView()
    }

    /// Ensures the host view re-applies bounce settings when SwiftUI updates.
    func updateUIView(_ uiView: UBHorizontalBounceDisablingView, context: Context) {
        uiView.updateScrollViewIfNeeded()
    }
}

/// A lightweight view that, once mounted, walks up its superview chain to locate
/// an enclosing `UIScrollView` and disable horizontal bouncing and clipping flags.
private final class UBHorizontalBounceDisablingView: UIView {
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateScrollViewIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateScrollViewIfNeeded()
    }

    /// Finds the nearest `UIScrollView` and disables horizontal bounce when any
    /// of the relevant flags suggest bouncing/clipping may differ from desired state.
    func updateScrollViewIfNeeded() {
        guard let scrollView = findEnclosingScrollView() else { return }
        if scrollView.bounces || scrollView.alwaysBounceHorizontal || scrollView.clipsToBounds == false {
            scrollView.bounces = false
            scrollView.alwaysBounceHorizontal = false
            scrollView.clipsToBounds = true
        }
    }

    /// Walks the superview chain to locate the first `UIScrollView` instance.
    private func findEnclosingScrollView() -> UIScrollView? {
        var candidate = superview
        while let view = candidate {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            candidate = view.superview
        }
        return nil
    }
}

// MARK: - Internal Modifiers (List Styling)
/// Chooses list styles and section spacing consistent with OS 26 surface behavior
/// while providing sensible grouped styles on earlier OS versions.
private struct UBListStyleLiquidAwareModifier: ViewModifier {
    @Environment(\.platformCapabilities) private var capabilities

    func body(content: Content) -> some View {
        if UBGlassBackgroundPolicy.shouldUseSystemChrome(capabilities: capabilities) {
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                content
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .ub_applyListRowSeparators()
                    .ub_applyZeroRowSpacingIfAvailable()
                    .ub_applyCompactSectionSpacingIfAvailable()
            } else {
                content
                    .listStyle(.plain)
                    .ub_applyListRowSeparators()
            }
        } else {
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                content
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .ub_applyListRowSeparators()
                    .ub_applyCompactSectionSpacingIfAvailable()
            } else {
                content
                    .listStyle(.insetGrouped)
                    .ub_applyListRowSeparators()
            }
        }
    }
}

// MARK: - List Separators Helper
private extension View {
    /// Applies visible list row separators tinted with a neutral system color,
    /// guarded by availability to avoid compile‑time/platform issues.
    @ViewBuilder
    func ub_applyListRowSeparators() -> some View {
        if #available(iOS 15.0, macCatalyst 15.0, *) {
            self
                .listRowSeparator(.visible)
                .listRowSeparatorTint(UBListStyleSeparators.separatorColor)
        } else {
            self
        }
    }

    /// Applies compact section spacing when the OS provides the list API.
    @ViewBuilder
    func ub_applyCompactSectionSpacingIfAvailable() -> some View {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            self.listSectionSpacing(.compact)
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// Applies zero row spacing on lists when the OS provides the API.
    @ViewBuilder
    func ub_applyZeroRowSpacingIfAvailable() -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            self.listRowSpacing(0)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

/// Namespaced helpers for list row separator colors.
private enum UBListStyleSeparators {
    /// Standard system separator color, bridged into SwiftUI's `Color`.
    static var separatorColor: Color {
        return Color(uiColor: .separator)
    }
}

/// Conditionally applies a list row background only on pre‑OS26 systems.
private struct UBPreOS26ListRowBackgroundModifier: ViewModifier {
    let color: Color
    @Environment(\.platformCapabilities) private var capabilities

    func body(content: Content) -> some View {
        if UBGlassBackgroundPolicy.shouldUseSystemChrome(capabilities: capabilities) {
            content
        } else {
            content.listRowBackground(color)
        }
    }
}

// MARK: - Root Tab Navigation Title Styling
/// Hides navigation bar background on modern OS releases for root pages.
private struct UBRootNavigationChromeModifier: ViewModifier {
    @Environment(\.platformCapabilities) private var capabilities

    @ViewBuilder
    func body(content: Content) -> some View {
        if UBGlassBackgroundPolicy.shouldUseSystemChrome(capabilities: capabilities) {
            if #available(iOS 16.0, macCatalyst 16.0, *) {
                content.toolbarBackground(.hidden, for: .navigationBar)
            } else {
                content
            }
        } else {
            content
        }
    }
}

// Removed: UBRootTabNavigationTitleModifier (no longer used)

// MARK: - Private Modifiers

/// Polyfill for the iOS 17/macOS 14 `onChange` overload that doesn't expose the new value.
private struct UBOnChangeWithoutValueModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let initial: Bool // When true, triggers once on appear even if no change occurred.
    let action: () -> Void // Action to run when value changes, no argument provided.
    @State private var previousValue: Value? // Last observed value; nil until first task run.

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 17.0, macCatalyst 17.0, *) {
            content.onChange(of: value, initial: initial, action)
        } else {
            content.task(id: value) {
                let shouldTrigger: Bool
                if let previousValue {
                    shouldTrigger = previousValue != value
                } else {
                    shouldTrigger = initial
                }
                previousValue = value
                if shouldTrigger {
                    action()
                }
            }
        }
    }
}

/// Polyfill for the iOS 17/macOS 14 `onChange` overload that exposes old/new values.
private struct UBOnChangeWithValueModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let initial: Bool // When true, triggers once on appear with the current value.
    let action: (Value) -> Void // Action receiving the new/current value.
    @State private var previousValue: Value? // Last observed value; used to detect transitions.

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 17.0, macCatalyst 17.0, *) {
            content.onChange(of: value, initial: initial) { _, newValue in
                action(newValue)
            }
        } else {
            content.task(id: value) {
                let shouldTrigger: Bool
                if let previousValue {
                    shouldTrigger = previousValue != value
                } else {
                    shouldTrigger = initial
                }
                previousValue = value
                if shouldTrigger {
                    action(value)
                }
            }
        }
    }
}

// Removed: UBDecimalKeyboardModifier (no longer used)

/// Wraps a background view that decides between OS 26 liquid glass and classic fill.
private struct UBGlassBackgroundModifier: ViewModifier {
    @Environment(\.platformCapabilities) private var platformCapabilities

    let baseColor: Color // Theme-aware base tint used on classic OS versions.
    let configuration: AppTheme.GlassConfiguration // Fine-tuning for glass overlays.
    let ignoresSafeAreaEdges: Edge.Set // Edges to extend through safe areas.

    func body(content: Content) -> some View {
        content.background(
            UBGlassBackgroundView(
                capabilities: platformCapabilities,
                baseColor: baseColor,
                configuration: configuration,
                ignoresSafeAreaEdges: ignoresSafeAreaEdges
            )
        )
    }
}

/// Applies a theme-appropriate surface background, deferring to system glass on OS 26.
private struct UBSurfaceBackgroundModifier: ViewModifier {
    @Environment(\.platformCapabilities) private var capabilities

    let theme: AppTheme // Active theme controlling glass usage/appearance.
    let configuration: AppTheme.GlassConfiguration // Glass tuning for eligible systems.
    let ignoresSafeAreaEdges: Edge.Set // Edges to extend through safe areas when painting.

    func body(content: Content) -> some View {
        // On OS 26, avoid painting custom backgrounds. Defer to system surfaces.
        if UBGlassBackgroundPolicy.shouldUseGlassSurfaces(theme: theme, capabilities: capabilities) {
            content
        } else {
            content.background(
                theme.background.ub_ignoreSafeArea(edges: ignoresSafeAreaEdges)
            )
        }
    }
}

/// Navigation chrome configured with either native OS 26 materials or a
/// gradient-based glass look on earlier platforms, depending on policy.
private struct UBNavigationGlassModifier: ViewModifier {
    @Environment(\.platformCapabilities) private var capabilities

    let baseColor: Color // Base tint under the glass overlays.
    let configuration: AppTheme.GlassConfiguration // Glass tuning for overlays.

    @ViewBuilder
    func body(content: Content) -> some View {
        if UBGlassBackgroundPolicy.shouldUseSystemChrome(capabilities: capabilities) {
            content
        } else {
            if #available(iOS 16.0, *) {
                content
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(gradientStyle, for: .navigationBar)
            } else {
                content
            }
        }
    }

    @available(iOS 16.0, *)
    /// Gradient style used to emulate glass highlights/specular/shadow on older systems.
    private var gradientStyle: AnyShapeStyle {
        let highlight = Color.white.opacity(min(configuration.glass.highlightOpacity * 0.6, 0.28))
        let mid = baseColor.opacity(min(configuration.liquid.tintOpacity + 0.12, 0.92))
        let shadow = configuration.glass.shadowColor.opacity(min(configuration.glass.shadowOpacity * 0.85, 0.6))

        return AnyShapeStyle(
            LinearGradient(
                colors: [highlight, mid, shadow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// Removed: UBChromeGlassModifier (unused)

/// Chrome background for tab bars that respects OS 26 policy and falls back to
/// a flat legacy background on older OS versions.
private struct UBChromeBackgroundModifier: ViewModifier {
    @Environment(\.platformCapabilities) private var capabilities
    @Environment(\.colorScheme) private var colorScheme

    let theme: AppTheme // Active theme controlling appearance.
    let configuration: AppTheme.GlassConfiguration // Glass tuning for eligible systems.

    func body(content: Content) -> some View {
        // On OS 26, defer to system chrome; on classic, use a flat background.
        if UBGlassBackgroundPolicy.shouldUseSystemChrome(capabilities: capabilities) {
            content
        } else {
            if #available(iOS 16.0, *) {
                content
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarBackground(theme.legacyChromeBackground, for: .tabBar)
            } else {
                content.background(theme.legacyChromeBackground)
            }
        }
    }
}

/// Theme-aware navigation bar backgrounds that either defer to system glass
/// or apply a legacy flat background with appropriate color scheme.
private struct UBNavigationBackgroundModifier: ViewModifier {
    @Environment(\.platformCapabilities) private var capabilities
    @Environment(\.colorScheme) private var colorScheme

    let theme: AppTheme // Active theme controlling glass usage/appearance.
    let configuration: AppTheme.GlassConfiguration // Glass tuning for eligible systems.

    @ViewBuilder
    func body(content: Content) -> some View {
        if UBGlassBackgroundPolicy.shouldUseGlassSurfaces(theme: theme, capabilities: capabilities) {
            content.modifier(
                UBNavigationGlassModifier(
                    baseColor: theme.glassBaseColor,
                    configuration: configuration
                )
            )
        } else {
            if #available(iOS 16.0, *) {
                content
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(theme.legacyChromeBackground, for: .navigationBar)
                    .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            } else {
                content
            }
        }
    }
}

/// Draws the background layer that underpins liquid glass on OS 26 and provides
/// a visually similar fallback on earlier systems.
private struct UBGlassBackgroundView: View {
    let capabilities: PlatformCapabilities // Resolved platform capability flags.
    let baseColor: Color // Base theme tint or surface color.
    let configuration: AppTheme.GlassConfiguration // Glass and liquid tuning parameters.
    let ignoresSafeAreaEdges: Edge.Set // Edges to extend through safe areas.

    var body: some View {
        backgroundLayer
    }

    /// Indicates whether a shadow overlay should be drawn based on configured opacity/blur.
    private var hasShadowOverlay: Bool {
        configuration.glass.shadowOpacity > 0 && configuration.glass.shadowBlur > 0
    }

    @ViewBuilder
    /// Applies safe-area ignoring only when requested, to keep call sites tidy.
    private var backgroundLayer: some View {
        if ignoresSafeAreaEdges.isEmpty {
            baseLayer
        } else {
            baseLayer.ub_ignoreSafeArea(edges: ignoresSafeAreaEdges)
        }
    }

    @ViewBuilder
    /// Chooses between translucent OS materials (when supported) and classic fill.
    private var baseLayer: some View {
        if capabilities.supportsOS26Translucency {
            if #available(iOS 15.0, macCatalyst 15.0, *) {
                decoratedGlass
                    .background(configuration.glass.material.shapeStyle)
            } else {
                decoratedGlass
            }
        } else {
            // Classic OS: use a flat fill that matches the theme's base color.
            Rectangle().fill(baseColor)
        }
    }

    /// Core stack of overlays that build up the liquid glass appearance.
    private var decoratedGlass: some View {
        ZStack {
            Rectangle()
                .fill(baseColor.opacity(configuration.liquid.tintOpacity))

            if configuration.liquid.bloom > 0 {
                bloomOverlay
            }

            if hasShadowOverlay {
                shadowOverlay
            }

            if configuration.glass.highlightOpacity > 0 {
                highlightOverlay
            }

            if configuration.glass.specularOpacity > 0 {
                specularOverlay
            }

            if configuration.glass.rimOpacity > 0 && configuration.glass.rimWidth > 0 {
                rimOverlay
            }

            if configuration.glass.noiseOpacity > 0 {
                noiseOverlay
            }
        }
        .compositingGroup()
        .saturation(configuration.liquid.saturation)
        .brightness(configuration.liquid.brightness)
        .contrast(configuration.liquid.contrast)
    }

    /// Soft bloom emanating from the center; brightens the base tint.
    private var bloomOverlay: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(configuration.liquid.bloom),
                        .clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 600
                )
            )
            .blendMode(.screen)
    }

    /// Broad highlight from the top-left to bottom-right for depth.
    private var highlightOverlay: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        configuration.glass.highlightColor.opacity(configuration.glass.highlightOpacity),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blur(radius: configuration.glass.highlightBlur)
    }

    /// Shadowed gradient opposing the highlight to reinforce curvature.
    private var shadowOverlay: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        configuration.glass.shadowColor.opacity(configuration.glass.shadowOpacity)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blur(radius: configuration.glass.shadowBlur)
    }

    /// Narrow vertical band that simulates a specular reflection.
    private var specularOverlay: some View {
        let clampedWidth = min(max(configuration.glass.specularWidth, 0.001), 0.49)
        let lower = max(0.0, 0.5 - clampedWidth)
        let upper = min(1.0, 0.5 + clampedWidth)

        return Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: configuration.glass.specularColor.opacity(0.0), location: 0.0),
                        .init(color: configuration.glass.specularColor.opacity(configuration.glass.specularOpacity), location: lower),
                        .init(color: configuration.glass.specularColor.opacity(configuration.glass.specularOpacity), location: upper),
                        .init(color: configuration.glass.specularColor.opacity(0.0), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blendMode(.screen)
    }

    /// A rim stroke soft‑blurred for a subtle edge glow.
    private var rimOverlay: some View {
        Rectangle()
            .strokeBorder(
                configuration.glass.rimColor.opacity(configuration.glass.rimOpacity),
                lineWidth: configuration.glass.rimWidth
            )
            .blur(radius: configuration.glass.rimBlur)
            .blendMode(.screen)
    }

    /// Fine‑grain noise to avoid banding in low‑contrast regions.
    private var noiseOverlay: some View {
        Rectangle()
            .fill(Color.white.opacity(configuration.glass.noiseOpacity))
            .blendMode(.softLight)
    }
}


private extension Edge.Set {
    /// Convenience flag for checking if no edges are set.
    var isEmpty: Bool { self == [] }
}

extension View {
    /// Bridges iOS 17's `.ignoresSafeArea(.container, edges:)` to earlier APIs.
    /// - Parameter edges: Edges to ignore when extending backgrounds.
    /// - Returns: A view that ignores only the specified safe area edges.
    @ViewBuilder
    func ub_ignoreSafeArea(edges: Edge.Set) -> some View {
        if #available(iOS 17.0, macCatalyst 17.0, *) {
            self.ignoresSafeArea(.container, edges: edges)
        } else {
            self.edgesIgnoringSafeArea(edges)
        }
    }
}

// Removed: UBColor (unused)

// MARK: - Global Helpers

/// Dismisses the on‑screen keyboard on platforms that support UIKit.
/// Call this in your save actions to neatly resign the first responder before
/// dismissing a sheet.  On macOS and other platforms this is a no‑op.
/// - Note: Safe to call multiple times; no effect when no responder is active.
func ub_dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// MARK: - Motion Provider Abstraction

/// Abstraction over motion data sources so views can depend on a simple protocol
/// and tests can inject a no‑op or stub provider.
protocol UBMotionsProviding: AnyObject {
    /// Starts delivering Core Motion updates. Gravity components are normalized (√(x²+y²+z²)=1).
    /// - Parameter onUpdate: Closure receiving roll, pitch, yaw and gravity X/Y/Z.
    func start(onUpdate: @escaping (_ roll: Double, _ pitch: Double, _ yaw: Double, _ gravityX: Double, _ gravityY: Double, _ gravityZ: Double) -> Void)
    /// Stops updates and releases any retained closures.
    func stop()
}

#if os(iOS) || targetEnvironment(macCatalyst)
import CoreMotion

/// Concrete implementation backed by `CMMotionManager` that streams device motion
/// on the main queue at ~60Hz when available.
final class UBCoreMotionProvider: UBMotionsProviding {
    private let manager = CMMotionManager() // Core Motion manager owned for the provider lifetime.
    private var onUpdate: ((_ r: Double, _ p: Double, _ y: Double, _ gx: Double, _ gy: Double, _ gz: Double) -> Void)? // Retained update sink.

    /// Starts device motion updates if supported by the hardware/OS.
    /// - Parameter onUpdate: Closure invoked with attitude and gravity components.
    func start(onUpdate: @escaping (Double, Double, Double, Double, Double, Double) -> Void) {
        guard manager.isDeviceMotionAvailable else { return }
        self.onUpdate = onUpdate
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] motion, _ in
            guard let self, let m = motion else { return }
            let gravity = m.gravity
            self.onUpdate?(
                m.attitude.roll,
                m.attitude.pitch,
                m.attitude.yaw,
                gravity.x,
                gravity.y,
                gravity.z
            )
        }
    }

    /// Stops device motion updates and clears the update closure.
    func stop() {
        manager.stopDeviceMotionUpdates()
        onUpdate = nil
    }
}
#else
/// No‑op motion provider for platforms without Core Motion.
final class UBNoopMotionProvider: UBMotionsProviding {
    func start(onUpdate: @escaping (Double, Double, Double, Double, Double, Double) -> Void) { /* no-op */ }
    func stop() { /* no-op */ }
}
#endif

// MARK: - Factory
/// Platform factory that returns a motion provider appropriate for the target.
enum UBPlatform {
    static func makeMotionProvider() -> UBMotionsProviding {
        #if os(iOS) || targetEnvironment(macCatalyst)
        return UBCoreMotionProvider()
        #else
        return UBNoopMotionProvider()
        #endif
    }
}
