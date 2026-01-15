# Platform Surface — Callsites

Goal: enumerate callsites for platform-facing surface area (EnvironmentValues keys, ub_* modifiers/extensions, and PreferenceKeys).

## EnvironmentKeys (EnvironmentValues access)
- `isOnboardingPresentation` defined at `OffshoreBudgeting/App/Onboarding/OnboardingEnvironment.swift:11`
  - receipt: `rg -n "\bisOnboardingPresentation\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/App/Onboarding/OnboardingEnvironment.swift'` → `0` hits
- `dataRevision` defined at `OffshoreBudgeting/App/Environment/DataRevisionEnvironment.swift:7`
  - receipt: `rg -n "\bdataRevision\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/App/Environment/DataRevisionEnvironment.swift'` → `0` hits
- `uiTestingFlags` defined at `OffshoreBudgeting/App/Testing/UITestingEnvironment.swift:32`
  - receipt: `rg -n "\buiTestingFlags\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/App/Testing/UITestingEnvironment.swift'` → `0` hits
- `startTabIdentifier` defined at `OffshoreBudgeting/App/Testing/UITestingEnvironment.swift:44`
  - receipt: `rg -n "\bstartTabIdentifier\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/App/Testing/UITestingEnvironment.swift'` → `0` hits
- `startRouteIdentifier` defined at `OffshoreBudgeting/App/Testing/UITestingEnvironment.swift:58`
  - receipt: `rg -n "\bstartRouteIdentifier\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/App/Testing/UITestingEnvironment.swift'` → `0` hits
- `responsiveLayoutContext` defined at `OffshoreBudgeting/Core/Platform/Layout/ResponsiveLayoutContext.swift:77`
  - receipt: `rg -n "\bresponsiveLayoutContext\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/Platform/Layout/ResponsiveLayoutContext.swift'` → `0` hits
- `ub_safeAreaInsets` defined at `OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift:18`
  - receipt: `rg -n "\bub_safeAreaInsets\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift'` → `0` hits
- `platformCapabilities` defined at `OffshoreBudgeting/Core/Platform/PlatformCapabilities.swift:118`
  - receipt: `rg -n "\bplatformCapabilities\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/Platform/PlatformCapabilities.swift'` → `0` hits

## View entrypoints (non-ub helpers)
- `onboardingPresentation` defined at `OffshoreBudgeting/App/Onboarding/OnboardingEnvironment.swift:20`
  - receipt: `rg -n "\bonboardingPresentation\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/App/Onboarding/OnboardingEnvironment.swift'` → `0` hits
- `responsiveLayoutContext` defined at `OffshoreBudgeting/Core/Platform/Layout/ResponsiveLayoutContext.swift:85`
  - receipt: `rg -n "\bresponsiveLayoutContext\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/Platform/Layout/ResponsiveLayoutContext.swift'` → `0` hits
- `ub_captureSafeAreaInsets` defined at `OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift:65`
  - receipt: `rg -n "\bub_captureSafeAreaInsets\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift'` → `0` hits

## View modifiers / extensions (ub_*)
- `ub_applyCompactSectionSpacingIfAvailable` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:274`
  - receipt: `rg -n "\.ub_applyCompactSectionSpacingIfAvailable\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits
- `ub_applyListRowSeparators` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:262`
  - receipt: `rg -n "\.ub_applyListRowSeparators\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits
- `ub_applyZeroRowSpacingIfAvailable` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:288`
  - receipt: `rg -n "\.ub_applyZeroRowSpacingIfAvailable\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits
- `ub_captureSafeAreaInsets` defined at `OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift:69`
  - receipt: `rg -n "\.ub_captureSafeAreaInsets\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift'` → `0` hits
- `ub_cardTitleShadow` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:70`
  - receipt: `rg -n "\.ub_cardTitleShadow\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits
- `ub_disableHorizontalBounce` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:127`
  - receipt: `rg -n "\.ub_disableHorizontalBounce\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits
- `ub_dismissKeyboard` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:477`
  - receipt: `rg -n "\.ub_dismissKeyboard\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits
- `ub_ignoreSafeArea` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:461`
  - receipt: `rg -n "\.ub_ignoreSafeArea\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits
- `ub_listStyleLiquidAware` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:141`
  - receipt: `rg -n "\.ub_listStyleLiquidAware\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits
- `ub_menuButtonStyle` defined at `OffshoreBudgeting/Core/UIFoundation/MenuButtonStyleCompatibility.swift:6`
  - receipt: `rg -n "\.ub_menuButtonStyle\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/MenuButtonStyleCompatibility.swift'` → `0` hits
- `ub_navigationBackground` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:108`
  - receipt: `rg -n "\.ub_navigationBackground\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits
- `ub_preOS26ListRowBackground` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:150`
  - receipt: `rg -n "\.ub_preOS26ListRowBackground\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits
- `ub_rootNavigationChrome` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:62`
  - receipt: `rg -n "\.ub_rootNavigationChrome\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits
- `ub_surfaceBackground` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:87`
  - receipt: `rg -n "\.ub_surfaceBackground\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits
- `ub_swipeActionTint` defined at `OffshoreBudgeting/DesignSystem/v2/Components/Effects/UnifiedSwipeActions.swift:272`
  - receipt: `rg -n "\.ub_swipeActionTint\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/DesignSystem/v2/Components/Effects/UnifiedSwipeActions.swift'` → `0` hits
- `ub_windowTitle` defined at `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift:157`
  - receipt: `rg -n "\.ub_windowTitle\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0` hits

## PreferenceKeys
- `ScenarioPlannerWidthPreferenceKey` defined at `OffshoreBudgeting/Views/HomeView.swift:3339`
  - receipt: `rg -n "\bScenarioPlannerWidthPreferenceKey\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0` hits
- `UBSafeAreaInsetsPreferenceKey` defined at `OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift:32`
  - receipt: `rg -n "\bUBSafeAreaInsetsPreferenceKey\b" OffshoreBudgeting -g"*.swift" --glob '!OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift'` → `0` hits
