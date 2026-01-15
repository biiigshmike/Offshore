# Platform Surface (Phase: index)

This report lists platform-facing SwiftUI hooks (environment keys, ub_* modifiers/extensions, and preference keys).

## EnvironmentKeys
- receipt: `rg -n "\bEnvironmentKey\b" OffshoreBudgeting -g"*.swift"`
- `OffshoreBudgeting/App/Onboarding/OnboardingEnvironment.swift:7:struct OnboardingPresentationKey: EnvironmentKey {`
- `OffshoreBudgeting/App/Testing/UITestingEnvironment.swift:20:private struct UITestingFlagsKey: EnvironmentKey {`
- `OffshoreBudgeting/App/Testing/UITestingEnvironment.swift:40:private struct StartTabIdentifierKey: EnvironmentKey {`
- `OffshoreBudgeting/App/Testing/UITestingEnvironment.swift:54:private struct StartRouteIdentifierKey: EnvironmentKey {`
- `OffshoreBudgeting/App/Environment/DataRevisionEnvironment.swift:3:private struct DataRevisionKey: EnvironmentKey {`
- `OffshoreBudgeting/Core/Platform/PlatformCapabilities.swift:114:private struct PlatformCapabilitiesKey: EnvironmentKey {`
- `OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift:14:private struct UBSafeAreaInsetsEnvironmentKey: EnvironmentKey {`
- `OffshoreBudgeting/Core/Platform/Layout/ResponsiveLayoutContext.swift:73:private struct ResponsiveLayoutContextKey: EnvironmentKey {`

## View Modifiers (ub_*)
- receipt: `rg -n "\bfunc ub_" OffshoreBudgeting -g"*.swift"`
- `OffshoreBudgeting/Views/ExpenseImportView.swift:548:    func ub_menuButtonStyle() -> some View {`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:62:    func ub_rootNavigationChrome() -> some View {`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:70:    func ub_cardTitleShadow() -> some View {`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:87:    func ub_surfaceBackground(`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:108:    func ub_navigationBackground(`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:127:    func ub_disableHorizontalBounce() -> some View {`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:141:    func ub_listStyleLiquidAware() -> some View {`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:150:    func ub_preOS26ListRowBackground(_ color: Color) -> some View {`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:157:    func ub_windowTitle(_ title: String) -> some View {`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:262:    func ub_applyListRowSeparators() -> some View {`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:274:    func ub_applyCompactSectionSpacingIfAvailable() -> some View {`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:288:    func ub_applyZeroRowSpacingIfAvailable() -> some View {`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:461:    func ub_ignoreSafeArea(edges: Edge.Set) -> some View {`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:477:func ub_dismissKeyboard() {`
- `OffshoreBudgeting/DesignSystem/v2/Components/Effects/UnifiedSwipeActions.swift:272:    func ub_swipeActionTint(_ color: Color) -> some View {`
- `OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift:69:    func ub_captureSafeAreaInsets() -> some View {`

## PreferenceKeys
- receipt: `rg -n "\bPreferenceKey\b" OffshoreBudgeting -g"*.swift"`
- `OffshoreBudgeting/Views/HomeView.swift:3339:    private struct ScenarioPlannerWidthPreferenceKey: PreferenceKey {`
- `OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift:32:private struct UBSafeAreaInsetsPreferenceKey: PreferenceKey {`

