# Dead Code Cleanup — Phase 14 (Read-only)

Scope: `OffshoreBudgeting/**/*.swift`, excluding `OffshoreBudgeting/DesignSystem/v2/**` and `OffshoreBudgeting/DesignSystem/Legacy/**` for type candidate enumeration.

## A) Unused top-level type candidates

Method: extract file-scope type declarations (no leading indentation) and count external references via `rg` (excluding the defining file).

### `OffshoreBudgeting/App/Environment/DataRevisionEnvironment.swift`
- `struct DataRevisionKey` (decl at L3): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bDataRevisionKey\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Environment/DataRevisionEnvironment.swift'` → `0`

### `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift`
- `enum TipsScreen` (decl at L4): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bTipsScreen\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift'` → `0`
- `enum TipsKind` (decl at L28): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bTipsKind\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift'` → `0`
- `struct TipsItem` (decl at L33): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bTipsItem\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift'` → `0`
- `struct TipsContent` (decl at L40): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bTipsContent\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift'` → `0`
- `enum TipsCatalog` (decl at L47): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bTipsCatalog\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift'` → `0`
- `struct TipsAndHintsStore` (decl at L205): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bTipsAndHintsStore\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift'` → `0`
- `struct TipsAndHintsOverlayModifier` (decl at L341): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bTipsAndHintsOverlayModifier\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift'` → `0`
- `struct TipsAndHintsSheet` (decl at L411): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bTipsAndHintsSheet\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift'` → `0`
- `struct TipsItemRow` (decl at L475): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bTipsItemRow\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift'` → `0`

### `OffshoreBudgeting/App/Navigation/RootTabView.swift`
- `struct RootTabView` (decl at L24): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bRootTabView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Navigation/RootTabView.swift'` → `0`

### `OffshoreBudgeting/App/OffshoreBudgetingApp.swift`
- `struct OffshoreBudgetingApp` (decl at L13): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bOffshoreBudgetingApp\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/OffshoreBudgetingApp.swift'` → `0`
- `struct TestUIOverridesModifier` (decl at L354): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bTestUIOverridesModifier\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/OffshoreBudgetingApp.swift'` → `0`
- `struct ThemedToggleTint` (decl at L1039): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bThemedToggleTint\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/OffshoreBudgetingApp.swift'` → `0`

### `OffshoreBudgeting/App/Onboarding/OnboardingEnvironment.swift`
- `struct OnboardingPresentationKey` (decl at L7): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bOnboardingPresentationKey\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Onboarding/OnboardingEnvironment.swift'` → `0`

### `OffshoreBudgeting/App/Testing/UITestingEnvironment.swift`
- `struct UITestingFlags` (decl at L4): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUITestingFlags\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Testing/UITestingEnvironment.swift'` → `0`
- `enum UITestBiometricAuthResult` (decl at L14): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUITestBiometricAuthResult\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Testing/UITestingEnvironment.swift'` → `0`
- `struct UITestingFlagsKey` (decl at L20): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUITestingFlagsKey\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Testing/UITestingEnvironment.swift'` → `0`
- `struct StartTabIdentifierKey` (decl at L40): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bStartTabIdentifierKey\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Testing/UITestingEnvironment.swift'` → `0`
- `struct StartRouteIdentifierKey` (decl at L54): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bStartRouteIdentifierKey\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/App/Testing/UITestingEnvironment.swift'` → `0`

### `OffshoreBudgeting/AppUpdateLogs/2.0.1.swift`
- `enum AppUpdateLog_2_0_1` (decl at L3): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppUpdateLog_2_0_1\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/AppUpdateLogs/2.0.1.swift'` → `0`

### `OffshoreBudgeting/AppUpdateLogs/2.0.swift`
- `enum AppUpdateLog_2_0` (decl at L3): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppUpdateLog_2_0\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/AppUpdateLogs/2.0.swift'` → `0`

### `OffshoreBudgeting/AppUpdateLogs/2.1.swift`
- `enum AppUpdateLog_2_1` (decl at L10): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppUpdateLog_2_1\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/AppUpdateLogs/2.1.swift'` → `0`

### `OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift`
- `enum AppUpdateLogs` (decl at L4): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppUpdateLogs\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift'` → `0`

### `OffshoreBudgeting/Core/Cloud/CloudAccountStatusProvider.swift`
- `protocol CloudAvailabilityProviding` (decl at L121): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudAvailabilityProviding\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Cloud/CloudAccountStatusProvider.swift'` → `0`

### `OffshoreBudgeting/Core/Cloud/CloudClient.swift`
- `struct CloudClient` (decl at L11): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudClient\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Cloud/CloudClient.swift'` → `0`

### `OffshoreBudgeting/Core/Cloud/CloudDataRemoteProbe.swift`
- `struct CloudDataRemoteProbe` (decl at L11): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudDataRemoteProbe\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Cloud/CloudDataRemoteProbe.swift'` → `0`

### `OffshoreBudgeting/Core/Cloud/CloudKitConfig.swift`
- `enum CloudKitConfig` (decl at L11): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudKitConfig\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Cloud/CloudKitConfig.swift'` → `0`

### `OffshoreBudgeting/Core/Cloud/CloudProbe.swift`
- `protocol CloudProbe` (decl at L12): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudProbe\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Cloud/CloudProbe.swift'` → `0`
- `enum CloudProbeDefaults` (decl at L18): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudProbeDefaults\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Cloud/CloudProbe.swift'` → `0`
- `struct LocalCloudDataProbeRunner` (decl at L31): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bLocalCloudDataProbeRunner\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Cloud/CloudProbe.swift'` → `0`
- `struct RemoteCloudDataProbeRunner` (decl at L71): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bRemoteCloudDataProbeRunner\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Cloud/CloudProbe.swift'` → `0`

### `OffshoreBudgeting/Core/Cloud/ForceReuploadHelper.swift`
- `enum ForceReuploadHelper` (decl at L38): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bForceReuploadHelper\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Cloud/ForceReuploadHelper.swift'` → `0`

### `OffshoreBudgeting/Core/Cloud/State/CloudStateFacade.swift`
- `enum CloudStateFacade` (decl at L8): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudStateFacade\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Cloud/State/CloudStateFacade.swift'` → `0`

### `OffshoreBudgeting/Core/Cloud/State/UbiquitousFlags.swift`
- `enum UbiquitousFlags` (decl at L3): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUbiquitousFlags\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Cloud/State/UbiquitousFlags.swift'` → `0`

### `OffshoreBudgeting/Core/Config/AppSettings.swift`
- `enum AppSettingsKeys` (decl at L7): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppSettingsKeys\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Config/AppSettings.swift'` → `0`

### `OffshoreBudgeting/Core/Domain/Calculations/BudgetIncomeCalculator.swift`
- `struct BudgetIncomeCalculator` (decl at L14): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBudgetIncomeCalculator\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Domain/Calculations/BudgetIncomeCalculator.swift'` → `0`

### `OffshoreBudgeting/Core/Domain/Models/RecurrenceRule.swift`
- `enum Weekday` (decl at L12): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bWeekday\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Domain/Models/RecurrenceRule.swift'` → `0`
- `enum RecurrenceRule` (decl at L57): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bRecurrenceRule\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Domain/Models/RecurrenceRule.swift'` → `0`

### `OffshoreBudgeting/Core/Persistence/CoreDataRepository.swift`
- `protocol CoreDataStackProviding` (decl at L14): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCoreDataStackProviding\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Persistence/CoreDataRepository.swift'` → `0`

### `OffshoreBudgeting/Core/Platform/Layout/ResponsiveLayoutContext.swift`
- `struct ResponsiveLayoutContext` (decl at L15): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bResponsiveLayoutContext\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Platform/Layout/ResponsiveLayoutContext.swift'` → `0`
- `struct ResponsiveLayoutContextKey` (decl at L73): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bResponsiveLayoutContextKey\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Platform/Layout/ResponsiveLayoutContext.swift'` → `0`
- `struct ResponsiveLayoutReader` (decl at L107): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bResponsiveLayoutReader\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Platform/Layout/ResponsiveLayoutContext.swift'` → `0`
- `struct LegacySafeAreaCapture` (decl at L156): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bLegacySafeAreaCapture\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Platform/Layout/ResponsiveLayoutContext.swift'` → `0`

### `OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift`
- `struct UBSafeAreaInsetsEnvironmentKey` (decl at L14): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBSafeAreaInsetsEnvironmentKey\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift'` → `0`
- `struct UBSafeAreaInsetsPreferenceKey` (decl at L32): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBSafeAreaInsetsPreferenceKey\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift'` → `0`
- `struct UBSafeAreaInsetsReader` (decl at L44): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBSafeAreaInsetsReader\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift'` → `0`

### `OffshoreBudgeting/Core/Platform/PlatformCapabilities.swift`
- `struct PlatformCapabilities` (decl at L13): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPlatformCapabilities\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Platform/PlatformCapabilities.swift'` → `0`
- `struct PlatformCapabilitiesKey` (decl at L114): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPlatformCapabilitiesKey\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Platform/PlatformCapabilities.swift'` → `0`

### `OffshoreBudgeting/Core/Platform/Theme/SystemTheme.swift`
- `enum SystemThemeAdapter` (decl at L12): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSystemThemeAdapter\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Platform/Theme/SystemTheme.swift'` → `0`

### `OffshoreBudgeting/Core/Security/AppLockKeychainStore.swift`
- `protocol AppLockKeychainStoring` (decl at L6): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppLockKeychainStoring\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Security/AppLockKeychainStore.swift'` → `0`

### `OffshoreBudgeting/Core/Security/BiometricAuthenticating.swift`
- `enum BiometricAuthResult` (decl at L5): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBiometricAuthResult\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Security/BiometricAuthenticating.swift'` → `0`
- `protocol BiometricAuthenticating` (decl at L12): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBiometricAuthenticating\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Security/BiometricAuthenticating.swift'` → `0`

### `OffshoreBudgeting/Core/Security/BiometricAuthenticationManager.swift`
- `enum BiometricError` (decl at L15): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBiometricError\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Security/BiometricAuthenticationManager.swift'` → `0`

### `OffshoreBudgeting/Core/Shared/Errors/SaveError.swift`
- `enum SaveError` (decl at L14): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSaveError\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Shared/Errors/SaveError.swift'` → `0`

### `OffshoreBudgeting/Core/Sync/DataChangeDebounce.swift`
- `enum DataChangeDebounce` (decl at L12): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bDataChangeDebounce\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Sync/DataChangeDebounce.swift'` → `0`

### `OffshoreBudgeting/Core/Theme/AppTheme.swift`
- `protocol UbiquitousKeyValueStoring` (decl at L14): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUbiquitousKeyValueStoring\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Theme/AppTheme.swift'` → `0`
- `protocol NotificationCentering` (decl at L24): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bNotificationCentering\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Theme/AppTheme.swift'` → `0`
- `enum CloudSyncPreferences` (decl at L65): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudSyncPreferences\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Theme/AppTheme.swift'` → `0`
- `enum AppTheme` (decl at L77): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppTheme\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Theme/AppTheme.swift'` → `0`
- `enum AppThemeColorUtilities` (decl at L647): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppThemeColorUtilities\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Theme/AppTheme.swift'` → `0`

### `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift`
- `struct UBGlassBackgroundPolicy` (decl at L28): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBGlassBackgroundPolicy\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0`
- `struct UBHorizontalBounceDisabler` (decl at L172): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBHorizontalBounceDisabler\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0`
- `struct UBListStyleLiquidAwareModifier` (decl at L224): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBListStyleLiquidAwareModifier\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0`
- `enum UBListStyleSeparators` (decl at L302): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBListStyleSeparators\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0`
- `struct UBPreOS26ListRowBackgroundModifier` (decl at L310): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBPreOS26ListRowBackgroundModifier\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0`
- `struct UBRootNavigationChromeModifier` (decl at L325): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBRootNavigationChromeModifier\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0`
- `struct UBSurfaceBackgroundModifier` (decl at L345): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBSurfaceBackgroundModifier\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0`
- `struct UBNavigationGlassModifier` (decl at L366): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBNavigationGlassModifier\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0`
- `struct UBNavigationBackgroundModifier` (decl at L407): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBNavigationBackgroundModifier\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0`
- `enum UBWindowTitleUpdater` (decl at L437): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBWindowTitleUpdater\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0`
- `protocol UBMotionsProviding` (decl at L485): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBMotionsProviding\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0`
- `enum UBPlatform` (decl at L538): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBPlatform\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/Compatibility.swift'` → `0`

### `OffshoreBudgeting/Core/UIFoundation/IncomeCalendarPalette.swift`
- `struct UBMonthLabel` (decl at L13): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBMonthLabel\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/IncomeCalendarPalette.swift'` → `0`
- `struct UBDayView` (decl at L41): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBDayView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/UIFoundation/IncomeCalendarPalette.swift'` → `0`

### `OffshoreBudgeting/Core/Widgets/WidgetRefreshCoordinator.swift`
- `enum WidgetRefreshCoordinator` (decl at L8): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bWidgetRefreshCoordinator\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Widgets/WidgetRefreshCoordinator.swift'` → `0`

### `OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift`
- `enum WidgetSharedStore` (decl at L7): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bWidgetSharedStore\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Core/Widgets/WidgetSharedStore.swift'` → `0`

### `OffshoreBudgeting/Models/BudgetPeriod.swift`
- `enum BudgetPeriod` (decl at L4): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBudgetPeriod\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Models/BudgetPeriod.swift'` → `0`

### `OffshoreBudgeting/Models/CardItem.swift`
- `enum CardEffect` (decl at L13): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardEffect\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Models/CardItem.swift'` → `0`
- `struct CardItem` (decl at L44): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardItem\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Models/CardItem.swift'` → `0`

### `OffshoreBudgeting/Resources/AccessibilityIdentifiers.swift`
- `enum AccessibilityRowIdentifier` (decl at L5): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAccessibilityRowIdentifier\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Resources/AccessibilityIdentifiers.swift'` → `0`

### `OffshoreBudgeting/Services/CloudOnboardingDecisionEngine.swift`
- `protocol CloudAvailabilityChecking` (decl at L4): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudAvailabilityChecking\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Services/CloudOnboardingDecisionEngine.swift'` → `0`
- `enum CloudOnboardingDecision` (decl at L11): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudOnboardingDecision\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Services/CloudOnboardingDecisionEngine.swift'` → `0`
- `enum CloudDataChoice` (decl at L16): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudDataChoice\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Services/CloudOnboardingDecisionEngine.swift'` → `0`
- `enum CloudOnboardingResolution` (decl at L21): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudOnboardingResolution\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Services/CloudOnboardingDecisionEngine.swift'` → `0`
- `struct CloudOnboardingDecisionEngine` (decl at L27): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudOnboardingDecisionEngine\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Services/CloudOnboardingDecisionEngine.swift'` → `0`

### `OffshoreBudgeting/Services/IncomeService.swift`
- `enum RecurrenceScope` (decl at L16): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bRecurrenceScope\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Services/IncomeService.swift'` → `0`

### `OffshoreBudgeting/Services/PlannedExpenseService.swift`
- `enum PlannedExpenseServiceError` (decl at L34): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPlannedExpenseServiceError\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Services/PlannedExpenseService.swift'` → `0`

### `OffshoreBudgeting/Services/PlannedExpenseUpdateScope.swift`
- `enum PlannedExpenseUpdateScope` (decl at L13): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPlannedExpenseUpdateScope\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Services/PlannedExpenseUpdateScope.swift'` → `0`

### `OffshoreBudgeting/Services/RecurrenceEngine.swift`
- `struct RecurrenceEngine` (decl at L7): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bRecurrenceEngine\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Services/RecurrenceEngine.swift'` → `0`

### `OffshoreBudgeting/Support/Logging.swift`
- `enum AppLog` (decl at L6): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppLog\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Support/Logging.swift'` → `0`

### `OffshoreBudgeting/ViewModels/BudgetMetrics.swift`
- `enum BudgetMetrics` (decl at L4): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBudgetMetrics\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/BudgetMetrics.swift'` → `0`

### `OffshoreBudgeting/ViewModels/CardDetailViewModel.swift`
- `struct CardCategoryTotal` (decl at L16): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardCategoryTotal\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/CardDetailViewModel.swift'` → `0`
- `struct CardExpense` (decl at L30): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardExpense\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/CardDetailViewModel.swift'` → `0`
- `enum CardDetailLoadState` (decl at L48): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardDetailLoadState\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/CardDetailViewModel.swift'` → `0`
- `enum CardDetailViewModelError` (decl at L57): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardDetailViewModelError\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/CardDetailViewModel.swift'` → `0`

### `OffshoreBudgeting/ViewModels/CardsViewModel.swift`
- `enum CardsLoadState` (decl at L24): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardsLoadState\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/CardsViewModel.swift'` → `0`
- `struct CardsViewAlert` (decl at L36): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardsViewAlert\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/CardsViewModel.swift'` → `0`

### `OffshoreBudgeting/ViewModels/HomeViewModel.swift`
- `enum BudgetLoadState` (decl at L21): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBudgetLoadState\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/HomeViewModel.swift'` → `0`
- `struct HomeViewAlert` (decl at L34): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bHomeViewAlert\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/HomeViewModel.swift'` → `0`
- `struct BudgetSummary` (decl at L45): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBudgetSummary\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/HomeViewModel.swift'` → `0`
- `enum Month` (decl at L132): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bMonth\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/HomeViewModel.swift'` → `0`

### `OffshoreBudgeting/ViewModels/PresetsViewModel.swift`
- `struct PresetListItem` (decl at L13): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPresetListItem\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/PresetsViewModel.swift'` → `0`

### `OffshoreBudgeting/ViewModels/SettingsViewModel.swift`
- `struct SettingsIcon` (decl at L74): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSettingsIcon\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/SettingsViewModel.swift'` → `0`
- `struct SettingsCard` (decl at L116): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSettingsCard\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/SettingsViewModel.swift'` → `0`
- `struct SettingsRow` (decl at L217): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSettingsRow\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/ViewModels/SettingsViewModel.swift'` → `0`

### `OffshoreBudgeting/Views/AddBudgetView.swift`
- `struct AddBudgetView` (decl at L21): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAddBudgetView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/AddBudgetView.swift'` → `0`

### `OffshoreBudgeting/Views/AddCardFormView.swift`
- `struct AddCardFormView` (decl at L26): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAddCardFormView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/AddCardFormView.swift'` → `0`
- `struct EffectSwatch` (decl at L238): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bEffectSwatch\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/AddCardFormView.swift'` → `0`
- `struct ThemeSwatch` (decl at L291): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bThemeSwatch\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/AddCardFormView.swift'` → `0`

### `OffshoreBudgeting/Views/AddIncomeFormView.swift`
- `struct AddIncomeFormView` (decl at L7): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAddIncomeFormView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/AddIncomeFormView.swift'` → `0`

### `OffshoreBudgeting/Views/AddPlannedExpenseView.swift`
- `struct AddPlannedExpenseView` (decl at L13): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAddPlannedExpenseView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/AddPlannedExpenseView.swift'` → `0`

### `OffshoreBudgeting/Views/AddUnplannedExpenseView.swift`
- `struct AddUnplannedExpenseView` (decl at L18): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAddUnplannedExpenseView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/AddUnplannedExpenseView.swift'` → `0`

### `OffshoreBudgeting/Views/AppLockView.swift`
- `struct AppLockView` (decl at L17): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppLockView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/AppLockView.swift'` → `0`

### `OffshoreBudgeting/Views/BudgetDetailsView.swift`
- `struct BudgetDetailsView` (decl at L5): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBudgetDetailsView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/BudgetDetailsView.swift'` → `0`

### `OffshoreBudgeting/Views/BudgetsView.swift`
- `struct BudgetsView` (decl at L6): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBudgetsView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/BudgetsView.swift'` → `0`
- `struct BudgetRow` (decl at L519): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBudgetRow\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/BudgetsView.swift'` → `0`
- `struct AlertItem` (decl at L557): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAlertItem\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/BudgetsView.swift'` → `0`

### `OffshoreBudgeting/Views/CardDetailView.swift`
- `struct CardDetailView` (decl at L20): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardDetailView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CardDetailView.swift'` → `0`
- `struct ExpenseRow` (decl at L956): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bExpenseRow\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CardDetailView.swift'` → `0`
- `struct IconOnlyButton` (decl at L1006): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bIconOnlyButton\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CardDetailView.swift'` → `0`
- `struct DeletionError` (decl at L1032): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bDeletionError\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CardDetailView.swift'` → `0`

### `OffshoreBudgeting/Views/CardPickerItemTile.swift`
- `struct CardPickerItemTile` (decl at L15): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardPickerItemTile\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CardPickerItemTile.swift'` → `0`

### `OffshoreBudgeting/Views/CardPickerRow.swift`
- `struct CardPickerRow` (decl at L25): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardPickerRow\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CardPickerRow.swift'` → `0`

### `OffshoreBudgeting/Views/CardTileView.swift`
- `struct CardTileView` (decl at L20): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardTileView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CardTileView.swift'` → `0`
- `struct CardMaterialBackground` (decl at L270): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardMaterialBackground\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CardTileView.swift'` → `0`
- `struct MetalBrushedLinesOverlay` (decl at L981): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bMetalBrushedLinesOverlay\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CardTileView.swift'` → `0`
- `struct MetalAnisotropicBandingOverlay` (decl at L1005): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bMetalAnisotropicBandingOverlay\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CardTileView.swift'` → `0`

### `OffshoreBudgeting/Views/CardsView.swift`
- `struct CardsView` (decl at L9): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardsView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CardsView.swift'` → `0`

### `OffshoreBudgeting/Views/CategoryChipStyle.swift`
- `struct CategoryChipStyle` (decl at L6): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCategoryChipStyle\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CategoryChipStyle.swift'` → `0`

### `OffshoreBudgeting/Views/CloudSyncGateView.swift`
- `struct CloudSyncGateView` (decl at L6): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCloudSyncGateView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CloudSyncGateView.swift'` → `0`
- `struct UITestCloudAvailabilityChecker` (decl at L216): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUITestCloudAvailabilityChecker\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CloudSyncGateView.swift'` → `0`

### `OffshoreBudgeting/Views/Components/BudgetCategoryChipView.swift`
- `struct BudgetCategoryChipView` (decl at L6): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBudgetCategoryChipView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/Components/BudgetCategoryChipView.swift'` → `0`

### `OffshoreBudgeting/Views/Components/BudgetFilterControls.swift`
- `struct BudgetExpenseSegmentedControl` (decl at L3): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBudgetExpenseSegmentedControl\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/Components/BudgetFilterControls.swift'` → `0`
- `struct BudgetSortBar` (decl at L17): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bBudgetSortBar\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/Components/BudgetFilterControls.swift'` → `0`

### `OffshoreBudgeting/Views/Components/CalendarNavigationButtonStyle.swift`
- `struct CalendarNavigationButtonStyle` (decl at L6): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCalendarNavigationButtonStyle\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/Components/CalendarNavigationButtonStyle.swift'` → `0`

### `OffshoreBudgeting/Views/Components/CategoryAvailabilityRow.swift`
- `struct CategoryAvailabilityRow` (decl at L3): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCategoryAvailabilityRow\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/Components/CategoryAvailabilityRow.swift'` → `0`

### `OffshoreBudgeting/Views/Components/CategoryChipPill.swift`
- `struct CategoryChipPill` (decl at L5): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCategoryChipPill\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/Components/CategoryChipPill.swift'` → `0`

### `OffshoreBudgeting/Views/Components/ExpenseCategoryChipsRow.swift`
- `struct ExpenseCategoryChipsRow` (decl at L5): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bExpenseCategoryChipsRow\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/Components/ExpenseCategoryChipsRow.swift'` → `0`

### `OffshoreBudgeting/Views/Components/GlassCTAButton.swift`
- `struct GlassCTAButton` (decl at L7): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bGlassCTAButton\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/Components/GlassCTAButton.swift'` → `0`

### `OffshoreBudgeting/Views/Components/PillSegmentedControl.swift`
- `struct PillSegmentedControl` (decl at L7): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPillSegmentedControl\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/Components/PillSegmentedControl.swift'` → `0`

### `OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift`
- `enum UBPresentationDetent` (decl at L12): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBPresentationDetent\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift'` → `0`

### `OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift`
- `struct TranslucentButtonStyle` (decl at L7): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bTranslucentButtonStyle\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift'` → `0`

### `OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift`
- `struct CustomRecurrence` (decl at L16): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCustomRecurrence\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift'` → `0`
- `struct CustomRecurrenceEditorView` (decl at L75): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCustomRecurrenceEditorView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/CustomRecurrenceEditorView.swift'` → `0`

### `OffshoreBudgeting/Views/EditCategoryCapsView.swift`
- `struct EditCategoryCapsView` (decl at L6): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bEditCategoryCapsView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/EditCategoryCapsView.swift'` → `0`

### `OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift`
- `struct ExpenseCategoryManagerView` (decl at L13): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bExpenseCategoryManagerView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift'` → `0`
- `struct CategoryRowView` (decl at L292): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCategoryRowView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift'` → `0`
- `struct ExpenseCategoryEditorSheet` (decl at L328): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bExpenseCategoryEditorSheet\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift'` → `0`
- `struct ColorCircle` (decl at L452): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bColorCircle\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift'` → `0`
- `struct DetentsForCategoryEditorCompat` (decl at L467): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bDetentsForCategoryEditorCompat\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift'` → `0`

### `OffshoreBudgeting/Views/ExpenseImportView.swift`
- `struct ExpenseImportView` (decl at L12): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bExpenseImportView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/ExpenseImportView.swift'` → `0`
- `struct CategoryPickerSheet` (decl at L508): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCategoryPickerSheet\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/ExpenseImportView.swift'` → `0`
- `struct ImportError` (decl at L573): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bImportError\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/ExpenseImportView.swift'` → `0`

### `OffshoreBudgeting/Views/HelpView.swift`
- `struct HelpView` (decl at L7): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bHelpView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HelpView.swift'` → `0`
- `struct HelpView_Previews` (decl at L509): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bHelpView_Previews\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HelpView.swift'` → `0`
- `enum HelpIconStyle` (decl at L516): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bHelpIconStyle\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HelpView.swift'` → `0`
- `struct HelpRowLabel` (decl at L571): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bHelpRowLabel\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HelpView.swift'` → `0`
- `struct HelpIconTile` (decl at L593): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bHelpIconTile\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HelpView.swift'` → `0`
- `enum HelpDeviceFrame` (decl at L617): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bHelpDeviceFrame\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HelpView.swift'` → `0`
- `struct DeviceScreenshotPlaceholders` (decl at L647): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bDeviceScreenshotPlaceholders\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HelpView.swift'` → `0`
- `struct HelpScreenshotPlaceholder` (decl at L689): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bHelpScreenshotPlaceholder\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HelpView.swift'` → `0`

### `OffshoreBudgeting/Views/HomeView.swift`
- `struct SpendBucket` (decl at L14): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSpendBucket\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `enum SpendBarOrientation` (decl at L24): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSpendBarOrientation\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct SpendChartSection` (decl at L30): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSpendChartSection\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct CategorySpendKey` (decl at L37): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCategorySpendKey\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct CapStatus` (decl at L42): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCapStatus\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct CategoryAvailability` (decl at L53): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCategoryAvailability\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `enum CategoryAvailabilitySegment` (decl at L76): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCategoryAvailabilitySegment\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct WidgetSpan` (decl at L93): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bWidgetSpan\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct WidgetSpanKey` (decl at L98): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bWidgetSpanKey\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct WidgetGridLayout` (decl at L103): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bWidgetGridLayout\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct HomeView` (decl at L215): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bHomeView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct MetricDetailView` (decl at L2315): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bMetricDetailView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct NextPlannedDetailRow` (decl at L5064): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bNextPlannedDetailRow\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct PresetExpenseRowView` (decl at L5162): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPresetExpenseRowView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct NextPlannedExpenseWidgetRow` (decl at L5187): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bNextPlannedExpenseWidgetRow\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct NextPlannedPresetsView` (decl at L5285): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bNextPlannedPresetsView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct CategorySlice` (decl at L5405): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCategorySlice\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct DaySpendTotal` (decl at L5412): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bDaySpendTotal\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct CategoryDonutView` (decl at L5960): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCategoryDonutView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct DonutSliceOutline` (decl at L6079): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bDonutSliceOutline\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct CategoryTopRow` (decl at L6098): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCategoryTopRow\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct PlannedRowsList` (decl at L6184): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPlannedRowsList\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct SegmentedGlassStyleModifier` (decl at L6354): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSegmentedGlassStyleModifier\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`
- `struct VariableRowsList` (decl at L6399): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bVariableRowsList\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/HomeView.swift'` → `0`

### `OffshoreBudgeting/Views/IncomeEditorView.swift`
- `enum IncomeEditorMode` (decl at L16): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bIncomeEditorMode\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/IncomeEditorView.swift'` → `0`
- `enum IncomeEditorAction` (decl at L23): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bIncomeEditorAction\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/IncomeEditorView.swift'` → `0`
- `struct IncomeEditorForm` (decl at L34): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bIncomeEditorForm\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/IncomeEditorView.swift'` → `0`
- `enum RecurrenceOption` (decl at L58): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bRecurrenceOption\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/IncomeEditorView.swift'` → `0`
- `struct IncomeEditorView` (decl at L78): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bIncomeEditorView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/IncomeEditorView.swift'` → `0`

### `OffshoreBudgeting/Views/IncomeView.swift`
- `struct IncomeView` (decl at L11): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bIncomeView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/IncomeView.swift'` → `0`

### `OffshoreBudgeting/Views/ManageBudgetCardsSheet.swift`
- `struct ManageBudgetCardsSheet` (decl at L5): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bManageBudgetCardsSheet\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/ManageBudgetCardsSheet.swift'` → `0`

### `OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift`
- `struct ManageBudgetPresetsSheet` (decl at L5): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bManageBudgetPresetsSheet\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift'` → `0`

### `OffshoreBudgeting/Views/OnboardingView.swift`
- `struct OnboardingView` (decl at L5): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bOnboardingView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/OnboardingView.swift'` → `0`
- `struct WelcomeStep2` (decl at L56): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bWelcomeStep2\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/OnboardingView.swift'` → `0`
- `struct CategoriesStep2` (decl at L77): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCategoriesStep2\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/OnboardingView.swift'` → `0`
- `struct CardsStep2` (decl at L92): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bCardsStep2\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/OnboardingView.swift'` → `0`
- `struct PresetsStep2` (decl at L107): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPresetsStep2\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/OnboardingView.swift'` → `0`
- `struct LoadingStep2` (decl at L122): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bLoadingStep2\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/OnboardingView.swift'` → `0`
- `struct OnboardingButtonsRow2` (decl at L135): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bOnboardingButtonsRow2\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/OnboardingView.swift'` → `0`

### `OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift`
- `struct PresetBudgetAssignmentSheet` (decl at L15): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPresetBudgetAssignmentSheet\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift'` → `0`
- `struct ObjectIDBox` (decl at L215): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bObjectIDBox\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/PresetBudgetAssignmentSheet.swift'` → `0`

### `OffshoreBudgeting/Views/PresetRowView.swift`
- `struct PresetRowView` (decl at L21): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPresetRowView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/PresetRowView.swift'` → `0`
- `struct LabeledAmountBlock` (decl at L130): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bLabeledAmountBlock\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/PresetRowView.swift'` → `0`
- `struct AssignedBudgetsBadge` (decl at L155): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAssignedBudgetsBadge\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/PresetRowView.swift'` → `0`

### `OffshoreBudgeting/Views/PresetsView.swift`
- `struct PresetsView` (decl at L6): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPresetsView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/PresetsView.swift'` → `0`
- `struct AddGlobalPresetSheet` (decl at L144): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAddGlobalPresetSheet\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/PresetsView.swift'` → `0`

### `OffshoreBudgeting/Views/RecurrencePickerView.swift`
- `struct RecurrencePickerView` (decl at L14): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bRecurrencePickerView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/RecurrencePickerView.swift'` → `0`

### `OffshoreBudgeting/Views/RenameCardSheet.swift`
- `struct RenameCardSheet` (decl at L16): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bRenameCardSheet\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/RenameCardSheet.swift'` → `0`

### `OffshoreBudgeting/Views/SettingsView.swift`
- `struct SettingsView` (decl at L14): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSettingsView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `struct SettingsRowLabel` (decl at L422): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSettingsRowLabel\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `enum SettingsIconStyle` (decl at L456): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSettingsIconStyle\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `struct SettingsIconTile` (decl at L506): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bSettingsIconTile\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `struct AppInfoRow` (decl at L530): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppInfoRow\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `struct AppInfoView` (decl at L559): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppInfoView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `struct ReleaseLogsView` (decl at L644): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bReleaseLogsView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `struct ReleaseLogItemRow` (decl at L669): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bReleaseLogItemRow\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `struct GeneralSettingsView` (decl at L698): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bGeneralSettingsView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `struct PrivacySettingsView` (decl at L784): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bPrivacySettingsView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `struct NotificationsSettingsView` (decl at L838): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bNotificationsSettingsView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `struct ICloudSettingsView` (decl at L1046): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bICloudSettingsView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `enum AppIconShape` (decl at L1110): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppIconShape\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `struct AppIconImageView` (decl at L1115): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppIconImageView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `enum AppIconProvider` (decl at L1145): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppIconProvider\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`
- `enum AppIconGraphic` (decl at L1151): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bAppIconGraphic\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/SettingsView.swift'` → `0`

### `OffshoreBudgeting/Views/UBEmptyState.swift`
- `struct UBEmptyState` (decl at L23): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bUBEmptyState\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/UBEmptyState.swift'` → `0`

### `OffshoreBudgeting/Views/WorkspaceProfilesView.swift`
- `struct WorkspaceMenuButton` (decl at L6): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bWorkspaceMenuButton\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/WorkspaceProfilesView.swift'` → `0`
- `struct WorkspaceColorDot` (decl at L84): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bWorkspaceColorDot\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/WorkspaceProfilesView.swift'` → `0`
- `struct WorkspaceManagerView` (decl at L101): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bWorkspaceManagerView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/WorkspaceProfilesView.swift'` → `0`
- `struct WorkspaceEditorView` (decl at L196): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bWorkspaceEditorView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/WorkspaceProfilesView.swift'` → `0`

### `OffshoreBudgeting/Views/WorkspaceSetupView.swift`
- `struct WorkspaceSetupView` (decl at L6): external hits = **0** → **CANDIDATE**
  - receipt: `rg -g'*.swift' --count-matches -n \"\bWorkspaceSetupView\b\" OffshoreBudgeting --glob '!OffshoreBudgeting/Views/WorkspaceSetupView.swift'` → `0`

**Total candidates (0 external hits): 232**

## B) Extension-only / modifier files (special handling)

These files primarily define extensions/modifiers/environment keys. Low type-name hit counts are not a reliable dead-code signal here; mark as **needs manual review**.

- `OffshoreBudgeting/App/ContentView.swift` (extensions: 0, top-level types: 0, marker hits: 1) → needs manual review
  - imports: import SwiftUI
- `OffshoreBudgeting/Core/Persistence/Bridges/CardItem+CoreDataBridge.swift` (extensions: 1, top-level types: 0, marker hits: 0) → needs manual review
  - imports: import Foundation, import CoreData, import SwiftUI
- `OffshoreBudgeting/Core/Persistence/CoreDataService.swift` (extensions: 2, top-level types: 0, marker hits: 0) → needs manual review
  - imports: import Foundation, import CoreData
- `OffshoreBudgeting/Core/Shared/Extensions/NotificationName+Extensions.swift` (extensions: 1, top-level types: 0, marker hits: 1) → needs manual review
  - imports: import Foundation
- `OffshoreBudgeting/Core/Sync/CoreDataEntityChangeMonitor.swift` (extensions: 0, top-level types: 0, marker hits: 1) → needs manual review
  - imports: import Foundation, import CoreData, import Combine
- `OffshoreBudgeting/Services/PlannedExpenseService+Templates.swift` (extensions: 1, top-level types: 0, marker hits: 0) → needs manual review
  - imports: import Foundation, import CoreData
- `OffshoreBudgeting/Services/WorkspaceService.swift` (extensions: 2, top-level types: 0, marker hits: 0) → needs manual review
  - imports: import Foundation, import CoreData
- `OffshoreBudgeting/Shared/UI/Extensions/View+If.swift` (extensions: 1, top-level types: 0, marker hits: 2) → needs manual review
  - imports: import SwiftUI

## C) “Resources” residue / Shared UI / Compatibility helpers

Remaining “junk drawer” style directories under `OffshoreBudgeting/`:
- `OffshoreBudgeting/Resources/`
- `OffshoreBudgeting/Support/`
- `OffshoreBudgeting/Systems/`

Contained Swift files (recommended destination heuristic):
- `OffshoreBudgeting/Resources/AccessibilityIdentifiers.swift` → Needs manual review
- `OffshoreBudgeting/Support/ColorHelpers.swift` → Needs manual review
- `OffshoreBudgeting/Support/Logging.swift` → Needs manual review

Notes: recommendations are filename/keyword-based; confirm by responsibility/imports before moving.

## D) Quick redundancy clusters

Heuristic clusters by filename substring (suspected overlap; manual review required).

### `Compat` (3 files)
- `OffshoreBudgeting/Core/Platform/Layout/SafeAreaInsetsCompatibility.swift`
- `OffshoreBudgeting/Core/UIFoundation/Compatibility.swift`
- `OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift`
- Suspected overlap: multiple `Compat`-named helpers often duplicate token mapping / platform branching; compare responsibilities and callsites before merging.

### `Manager` (3 files)
- `OffshoreBudgeting/App/Guidance/GuidedWalkthroughManager.swift`
- `OffshoreBudgeting/Core/Security/BiometricAuthenticationManager.swift`
- `OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift`
- Suspected overlap: multiple `Manager`-named helpers often duplicate token mapping / platform branching; compare responsibilities and callsites before merging.

### `Probe` (3 files)
- `OffshoreBudgeting/Core/Cloud/CloudDataProbe.swift`
- `OffshoreBudgeting/Core/Cloud/CloudDataRemoteProbe.swift`
- `OffshoreBudgeting/Core/Cloud/CloudProbe.swift`
- Suspected overlap: multiple `Probe`-named helpers often duplicate token mapping / platform branching; compare responsibilities and callsites before merging.

### `Style` (3 files)
- `OffshoreBudgeting/Views/CategoryChipStyle.swift`
- `OffshoreBudgeting/Views/Components/CalendarNavigationButtonStyle.swift`
- `OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift`
- Suspected overlap: multiple `Style`-named helpers often duplicate token mapping / platform branching; compare responsibilities and callsites before merging.

### `Helper` (2 files)
- `OffshoreBudgeting/Core/Cloud/ForceReuploadHelper.swift`
- `OffshoreBudgeting/Support/ColorHelpers.swift`
- Suspected overlap: multiple `Helper`-named helpers often duplicate token mapping / platform branching; compare responsibilities and callsites before merging.

### `Monitor` (2 files)
- `OffshoreBudgeting/Core/Cloud/CloudSyncMonitor.swift`
- `OffshoreBudgeting/Core/Sync/CoreDataEntityChangeMonitor.swift`
- Suspected overlap: multiple `Monitor`-named helpers often duplicate token mapping / platform branching; compare responsibilities and callsites before merging.

### `Theme` (2 files)
- `OffshoreBudgeting/Core/Platform/Theme/SystemTheme.swift`
- `OffshoreBudgeting/Core/Theme/AppTheme.swift`
- Suspected overlap: multiple `Theme`-named helpers often duplicate token mapping / platform branching; compare responsibilities and callsites before merging.

---
### Inventory receipts
- Swift files scanned (excluding DS v2/Legacy): `130`
- File selection command: `rg --files OffshoreBudgeting -g'*.swift' | rg -v '^OffshoreBudgeting/DesignSystem/(v2|Legacy)/'`
