import SwiftUI

// MARK: - PlatformExtensions (Entrypoint Index)
//
// Goal: keep a stable, searchable index of “platform surface area” extensions,
// modifiers, and environment keys. This file intentionally contains no logic.
//
// Environment keys (source of truth: definitions):
// - `OnboardingPresentationKey` → `OffshoreBudgeting/App/Onboarding/OnboardingEnvironment.swift`
// - `DataRevisionKey` → `OffshoreBudgeting/App/Environment/DataRevisionEnvironment.swift`
// - `UITestingFlagsKey`, `StartTabIdentifierKey`, `StartRouteIdentifierKey` → `OffshoreBudgeting/App/Testing/UITestingEnvironment.swift`
// - `ResponsiveLayoutContextKey` → `OffshoreBudgeting/Core/Platform/Layout/ResponsiveLayoutContext.swift`
// - `UBSafeAreaInsetsEnvironmentKey` → `OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift`
// - `PlatformCapabilitiesKey` → `OffshoreBudgeting/Core/Platform/PlatformCapabilities.swift`
//
// View modifiers / extensions (ub_*):
// - `ub_rootNavigationChrome`, `ub_cardTitleShadow`, `ub_surfaceBackground`, `ub_navigationBackground`,
//   `ub_disableHorizontalBounce`, `ub_listStyleLiquidAware`, `ub_preOS26ListRowBackground`,
//   `ub_windowTitle`, `ub_applyListRowSeparators`, `ub_applyCompactSectionSpacingIfAvailable`,
//   `ub_applyZeroRowSpacingIfAvailable`, `ub_ignoreSafeArea` → `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift`
// - `ub_captureSafeAreaInsets` → `OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift`
// - `ub_menuButtonStyle` → `OffshoreBudgeting/Views/ExpenseImportView.swift`
// - `ub_swipeActionTint` → `OffshoreBudgeting/DesignSystem/v2/Components/Effects/UnifiedSwipeActions.swift`
//
// Preference keys:
// - `UBSafeAreaInsetsPreferenceKey` → `OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift`
// - `ScenarioPlannerWidthPreferenceKey` → `OffshoreBudgeting/Views/HomeView.swift`

