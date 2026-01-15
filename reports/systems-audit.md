# Systems Audit

Generated: 2026-01-14T18:56:13

## Summary

| File | Primary responsibility | Imports | Types | Classification | Callsites |
|---|---|---|---|---|---|
| OffshoreBudgeting/Systems/CardPickerStore.swift | Centralizes card fetching for picker UIs so that sheets can render | Foundation, CoreData | class CardPickerStore | Unclear (needs human review) | [13 matches](#CardPickerStore) |
| OffshoreBudgeting/Systems/CardTheme.swift | A small catalog of card themes. Pure SwiftUI Colors (cross-platform). | SwiftUI, UIKit | enum CardTheme, enum BackgroundPattern, struct DiagonalStripesOverlay, struct CrossHatchOverlay, struct GridOverlay, struct DotsOverlay, struct NoiseOverlay | Core platform capability | [27 matches](#CardTheme) |
| OffshoreBudgeting/Systems/Compatibility.swift | Cross-platform helpers to keep SwiftUI views tidy by hiding | SwiftUI, UIKit, CoreMotion | struct UBGlassBackgroundPolicy, struct UBHorizontalBounceDisabler, class UBHorizontalBounceDisablingView, struct UBListStyleLiquidAwareModifier, enum UBListStyleSeparators, struct UBPreOS26ListRowBackgroundModifier, struct UBRootNavigationChromeModifier, struct UBSurfaceBackgroundModifier, struct UBNavigationGlassModifier, struct UBNavigationBackgroundModifier, enum UBWindowTitleUpdater, protocol UBMotionsProviding, class UBCoreMotionProvider, class UBNoopMotionProvider, enum UBPlatform | Core platform capability | [6 matches](#Compatibility) |
| OffshoreBudgeting/Systems/DesignSystem+Motion.swift | Central place for motion tuning values. | SwiftUI | enum Motion | Core platform capability | [14 matches](#DesignSystem-Motion) |
| OffshoreBudgeting/Systems/DesignSystem.swift | (no header comment; inferred from name) | SwiftUI, UIKit | enum DesignSystem, enum Spacing, enum Radius, enum Colors | Core platform capability | [552 matches](#DesignSystem) |
| OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift | (no header comment; inferred from name) | SwiftUI | enum TipsScreen, enum TipsKind, struct TipsItem, struct TipsContent, enum TipsCatalog, struct TipsAndHintsStore, struct TipsAndHintsOverlayModifier, class TipsPresentationCoordinator, struct TipsAndHintsSheet, struct TipsItemRow | App wiring | [31 matches](#GuidedWalkthroughManager) |
| OffshoreBudgeting/Systems/IncomeCalendarPalette.swift | Shared calendar components for MijickCalendarView. | SwiftUI, MijickCalendarView | struct UBMonthLabel, struct UBDayView | Core platform capability | [2 matches](#IncomeCalendarPalette) |
| OffshoreBudgeting/Systems/MetallicTextStyles.swift | (no header comment; inferred from name) | SwiftUI | enum UBTypography, enum UBDecor | Core platform capability | [6 matches](#MetallicTextStyles) |
| OffshoreBudgeting/Systems/MotionSupport.swift | Centralized device-motion publisher with smoothing and amplitude scaling. | SwiftUI, Combine, UIKit | class MotionMonitor | Core platform capability | [5 matches](#MotionSupport) |
| OffshoreBudgeting/Systems/OnboardingEnvironment.swift | (no header comment; inferred from name) | SwiftUI | struct OnboardingPresentationKey | App wiring | [3 matches](#OnboardingEnvironment) |
| OffshoreBudgeting/Systems/PlatformCapabilities.swift | (no header comment; inferred from name) | SwiftUI | struct PlatformCapabilities, struct PlatformCapabilitiesKey | Core platform capability | [34 matches](#PlatformCapabilities) |
| OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift | (no header comment; inferred from name) | SwiftUI, UIKit | struct ResponsiveLayoutContext, enum Idiom, struct ResponsiveLayoutContextKey, struct ResponsiveLayoutReader, struct LegacySafeAreaCapture | Core platform capability | [10 matches](#ResponsiveLayoutContext) |
| OffshoreBudgeting/Systems/SafeAreaInsetsCompatibility.swift | (no header comment; inferred from name) | SwiftUI | struct UBSafeAreaInsetsEnvironmentKey, struct UBSafeAreaInsetsPreferenceKey, struct UBSafeAreaInsetsReader | Core platform capability | [3 matches](#SafeAreaInsetsCompatibility) |
| OffshoreBudgeting/Systems/SystemTheme.swift | (no header comment; inferred from name) | SwiftUI, UIKit | enum SystemThemeAdapter, enum Flavor | Core platform capability | [3 matches](#SystemTheme) |
| OffshoreBudgeting/Systems/UITestingEnvironment.swift | (no header comment; inferred from name) | SwiftUI | struct UITestingFlags, enum UITestBiometricAuthResult, struct UITestingFlagsKey, struct StartTabIdentifierKey, struct StartRouteIdentifierKey | App wiring | [32 matches](#UITestingEnvironment) |

## Details

## OffshoreBudgeting/Systems/CardPickerStore.swift

- Primary responsibility: Centralizes card fetching for picker UIs so that sheets can render
- Imports: `Foundation, CoreData`
- Classification: **Unclear (needs human review)**

### Callsites
#### `CardPickerStore` (type)

```
rg -n "\bCardPickerStore\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/ViewModels/AddUnplannedExpenseViewModel.swift:21:    private var cardPickerStore: CardPickerStore?
OffshoreBudgeting/ViewModels/AddUnplannedExpenseViewModel.swift:56:         cardPickerStore: CardPickerStore? = nil,
OffshoreBudgeting/ViewModels/AddUnplannedExpenseViewModel.swift:70:    func attachCardPickerStoreIfNeeded(_ store: CardPickerStore) {
OffshoreBudgeting/ViewModels/AddUnplannedExpenseViewModel.swift:240:    private func bindToCardPickerStore(_ store: CardPickerStore, preserveSelection: Bool) {
OffshoreBudgeting/ViewModels/AddPlannedExpenseViewModel.swift:22:    private var cardPickerStore: CardPickerStore?
OffshoreBudgeting/ViewModels/AddPlannedExpenseViewModel.swift:65:         cardPickerStore: CardPickerStore? = nil,
OffshoreBudgeting/ViewModels/AddPlannedExpenseViewModel.swift:81:    func attachCardPickerStoreIfNeeded(_ store: CardPickerStore) {
OffshoreBudgeting/ViewModels/AddPlannedExpenseViewModel.swift:568:    private func bindToCardPickerStore(_ store: CardPickerStore, preserveSelection: Bool) {
OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:31:    @EnvironmentObject private var cardPickerStore: CardPickerStore
OffshoreBudgeting/Views/AddPlannedExpenseView.swift:37:    @EnvironmentObject private var cardPickerStore: CardPickerStore
OffshoreBudgeting/Views/CardTileView.swift:53:    @EnvironmentObject private var cardPickerStore: CardPickerStore
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:19:    @StateObject private var cardPickerStore = CardPickerStore()
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:40:        // Defer Core Data store loading and CardPickerStore start to onAppear
```
## OffshoreBudgeting/Systems/CardTheme.swift

- Primary responsibility: A small catalog of card themes. Pure SwiftUI Colors (cross-platform).
- Imports: `SwiftUI, UIKit`
- Classification: **Core platform capability**

### Callsites
#### `CardTheme` (type)

```
rg -n "\bCardTheme\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Models/CardItem.swift:53:    var theme: CardTheme
OffshoreBudgeting/Services/CardService.swift:164:    func updateCard(_ card: Card, name: String? = nil, theme: CardTheme? = nil, effect: CardEffect? = nil) throws {
OffshoreBudgeting/Core/Persistence/Bridges/CardItem+CoreDataBridge.swift:34:        let theme: CardTheme = {
OffshoreBudgeting/Core/Persistence/Bridges/CardItem+CoreDataBridge.swift:37:               let t = CardTheme(rawValue: raw) {
OffshoreBudgeting/Views/CardDetailView.swift:419:    private func handleCardEdit(name: String, theme: CardTheme, effect: CardEffect) {
OffshoreBudgeting/Views/AddCardFormView.swift:42:    var onSave: (_ name: String, _ theme: CardTheme, _ effect: CardEffect) -> Void
OffshoreBudgeting/Views/AddCardFormView.swift:53:        onSave: @escaping (_ name: String, _ theme: CardTheme, _ effect: CardEffect) -> Void
OffshoreBudgeting/Views/AddCardFormView.swift:66:    @State private var selectedTheme: CardTheme = .rose
OffshoreBudgeting/Views/AddCardFormView.swift:167:                    ForEach(CardTheme.allCases) { theme in
OffshoreBudgeting/Views/AddCardFormView.swift:240:    let theme: CardTheme
OffshoreBudgeting/Views/AddCardFormView.swift:292:    let theme: CardTheme
OffshoreBudgeting/Views/HomeView.swift:3030:            let theme: CardTheme = {
OffshoreBudgeting/Views/HomeView.swift:3033:                   let t = CardTheme(rawValue: raw) { return t }
OffshoreBudgeting/Views/HomeView.swift:5122:                let theme: CardTheme = {
OffshoreBudgeting/Views/HomeView.swift:5125:                       let t = CardTheme(rawValue: raw) { return t }
OffshoreBudgeting/Views/HomeView.swift:5394:    private func cardTheme(from card: Card?) -> CardTheme? {
OffshoreBudgeting/Views/HomeView.swift:5400:        return CardTheme(rawValue: raw)
OffshoreBudgeting/Views/HomeView.swift:6251:                                    let theme: CardTheme = {
OffshoreBudgeting/Views/HomeView.swift:6254:                                           let t = CardTheme(rawValue: raw) { return t }
OffshoreBudgeting/Views/HomeView.swift:6473:                                    let theme: CardTheme = {
OffshoreBudgeting/Views/HomeView.swift:6476:                                           let t = CardTheme(rawValue: raw) { return t }
OffshoreBudgeting/ViewModels/CardsViewModel.swift:164:                let theme: CardTheme = {
OffshoreBudgeting/ViewModels/CardsViewModel.swift:167:                       let t = CardTheme(rawValue: raw) { return t }
OffshoreBudgeting/ViewModels/CardsViewModel.swift:235:    func addCard(name: String, theme: CardTheme, effect: CardEffect) async {
OffshoreBudgeting/ViewModels/CardsViewModel.swift:310:    func edit(card: CardItem, name: String, theme: CardTheme, effect: CardEffect) async {
OffshoreBudgeting/ViewModels/CardsViewModel.swift:347:               let t = CardTheme(rawValue: raw) {
OffshoreBudgeting/Views/CardTileView.swift:271:    let theme: CardTheme
```

#### `BackgroundPattern` (type)

```
rg -n "\bBackgroundPattern\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `DiagonalStripesOverlay` (type)

```
rg -n "\bDiagonalStripesOverlay\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `CrossHatchOverlay` (type)

```
rg -n "\bCrossHatchOverlay\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `GridOverlay` (type)

```
rg -n "\bGridOverlay\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `DotsOverlay` (type)

```
rg -n "\bDotsOverlay\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `NoiseOverlay` (type)

```
rg -n "\bNoiseOverlay\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```
## OffshoreBudgeting/Systems/Compatibility.swift

- Primary responsibility: Cross-platform helpers to keep SwiftUI views tidy by hiding
- Imports: `SwiftUI, UIKit, CoreMotion`
- Classification: **Core platform capability**

### Callsites
#### `UBGlassBackgroundPolicy` (type)

```
rg -n "\bUBGlassBackgroundPolicy\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBHorizontalBounceDisabler` (type)

```
rg -n "\bUBHorizontalBounceDisabler\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBHorizontalBounceDisablingView` (type)

```
rg -n "\bUBHorizontalBounceDisablingView\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBListStyleLiquidAwareModifier` (type)

```
rg -n "\bUBListStyleLiquidAwareModifier\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBListStyleSeparators` (type)

```
rg -n "\bUBListStyleSeparators\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBPreOS26ListRowBackgroundModifier` (type)

```
rg -n "\bUBPreOS26ListRowBackgroundModifier\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBRootNavigationChromeModifier` (type)

```
rg -n "\bUBRootNavigationChromeModifier\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBSurfaceBackgroundModifier` (type)

```
rg -n "\bUBSurfaceBackgroundModifier\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBNavigationGlassModifier` (type)

```
rg -n "\bUBNavigationGlassModifier\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBNavigationBackgroundModifier` (type)

```
rg -n "\bUBNavigationBackgroundModifier\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBWindowTitleUpdater` (type)

```
rg -n "\bUBWindowTitleUpdater\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBMotionsProviding` (type)

```
rg -n "\bUBMotionsProviding\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Systems/MotionSupport.swift:11://  NOTE: Uses UBMotionsProviding from Compatibility.swift to stay cross-platform.
OffshoreBudgeting/Systems/MotionSupport.swift:49:    private let provider: UBMotionsProviding
OffshoreBudgeting/Systems/MotionSupport.swift:54:    init(provider: UBMotionsProviding = UBPlatform.makeMotionProvider()) {
```

#### `UBCoreMotionProvider` (type)

```
rg -n "\bUBCoreMotionProvider\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBNoopMotionProvider` (type)

```
rg -n "\bUBNoopMotionProvider\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBPlatform` (type)

```
rg -n "\bUBPlatform\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Systems/MotionSupport.swift:54:    init(provider: UBMotionsProviding = UBPlatform.makeMotionProvider()) {
```

#### `ub_rootNavigationChrome` (func)

```
rg -n "\bub_rootNavigationChrome\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/App/Navigation/RootTabView.swift:23:///   and `ub_rootNavigationChrome()` to centralize OS 26 vs. classic styling.
OffshoreBudgeting/App/Navigation/RootTabView.swift:341:            .ub_rootNavigationChrome()
```

#### `ub_ignoreSafeArea` (func)

```
rg -n "\bub_ignoreSafeArea\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```
## OffshoreBudgeting/Systems/DesignSystem+Motion.swift

- Primary responsibility: Central place for motion tuning values.
- Imports: `SwiftUI`
- Classification: **Core platform capability**

### Callsites
#### `Motion` (type)

```
rg -n "\bMotion\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Systems/MotionSupport.swift:9://    Smoothing uses DS.Motion.smoothingAlpha; roll/pitch scaling uses DS.Motion.cardBackgroundAmplitudeScale.
OffshoreBudgeting/Systems/MotionSupport.swift:27:    // MARK: Raw Motion (unscaled)
OffshoreBudgeting/Systems/MotionSupport.swift:44:    private var smoothingAlpha: Double = DS.Motion.smoothingAlpha
OffshoreBudgeting/Systems/MotionSupport.swift:46:    private var amplitudeScale: Double = DS.Motion.cardBackgroundAmplitudeScale
OffshoreBudgeting/Systems/MotionSupport.swift:93:    ///   - raw: Incoming reading from Core Motion.
OffshoreBudgeting/Systems/MotionSupport.swift:115:    ///   - smoothing: 0...1 (default from DS.Motion.smoothingAlpha)
OffshoreBudgeting/Systems/MotionSupport.swift:116:    ///   - scale: 0...1 (default from DS.Motion.cardBackgroundAmplitudeScale). Applied to roll/pitch smoothing only.
OffshoreBudgeting/Views/CardTileView.swift:835:// MARK: - Motion → Parameters
OffshoreBudgeting/Systems/Compatibility.swift:481:// MARK: - Motion Provider Abstraction
OffshoreBudgeting/Systems/Compatibility.swift:486:    /// Starts delivering Core Motion updates. Gravity components are normalized (√(x²+y²+z²)=1).
OffshoreBudgeting/Systems/Compatibility.swift:499:    private let manager = CMMotionManager() // Core Motion manager owned for the provider lifetime.
OffshoreBudgeting/Systems/Compatibility.swift:529:/// No‑op motion provider for platforms without Core Motion.
OffshoreBudgeting/DesignSystem/v2/Components/Effects/HolographicMetallicText.swift:35:    // MARK: Motion
OffshoreBudgeting/DesignSystem/v2/Components/Effects/HolographicMetallicText.swift:75:// MARK: - Motion → Parameters
```
## OffshoreBudgeting/Systems/DesignSystem.swift

- Primary responsibility: (no header comment; inferred from name)
- Imports: `SwiftUI, UIKit`
- Classification: **Core platform capability**

### Callsites
#### `DesignSystem` (type)

```
rg -n "\bDesignSystem\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Systems/DesignSystem+Motion.swift:2://  DesignSystem+Motion.swift
OffshoreBudgeting/App/Navigation/RootTabView.swift:439:                    .padding(.horizontal, DesignSystem.Spacing.s)
OffshoreBudgeting/App/Navigation/RootTabView.swift:458:                .padding(.horizontal, DesignSystem.Spacing.s)
OffshoreBudgeting/DesignSystem/v2/Tokens/Radius.swift:6:/// Keep values 1:1 with legacy `DesignSystem.Radius` when migrating call sites.
```

#### `Spacing` (type)

```
rg -n "\bSpacing\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Views/CardDetailView.swift:215:            VStack(spacing: Spacing.m) {
OffshoreBudgeting/Views/CardDetailView.swift:237:                let topPadding: CGFloat = uiTestingFlags.isUITesting ? Spacing.s : initialHeaderTopPadding
OffshoreBudgeting/Views/CardDetailView.swift:238:                let bottomPadding: CGFloat = uiTestingFlags.isUITesting ? Spacing.xs : Spacing.m
OffshoreBudgeting/Views/CardDetailView.swift:268:                            VStack(alignment: .leading, spacing: Spacing.m) {
OffshoreBudgeting/Views/CardDetailView.swift:269:                                VStack(alignment: .leading, spacing: Spacing.s) {
OffshoreBudgeting/Views/CardDetailView.swift:273:                                HStack(spacing: Spacing.m) {
OffshoreBudgeting/Views/CardDetailView.swift:282:                            HStack(spacing: Spacing.sPlus) {
OffshoreBudgeting/Views/CardDetailView.swift:283:                                HStack(spacing: Spacing.s) {
OffshoreBudgeting/Views/CardDetailView.swift:288:                                HStack(spacing: Spacing.s) {
OffshoreBudgeting/Views/CardDetailView.swift:302:                    let row = VStack(alignment: .leading, spacing: Spacing.s) {
OffshoreBudgeting/Views/CardDetailView.swift:309:                    .padding(.vertical, Spacing.s)
OffshoreBudgeting/Views/CardDetailView.swift:325:                        HStack(spacing: Spacing.sPlus) {
OffshoreBudgeting/Views/CardDetailView.swift:332:                                    .padding(.vertical, Spacing.s)
OffshoreBudgeting/Views/CardDetailView.swift:377:                            .padding(.vertical, Spacing.l)
OffshoreBudgeting/Views/CardDetailView.swift:566:        GlassEffectContainer(spacing: Spacing.s) {
OffshoreBudgeting/Views/CardDetailView.swift:567:            HStack(spacing: Spacing.xs) {
OffshoreBudgeting/Views/CardDetailView.swift:649:        HStack(spacing: Spacing.xs) {
OffshoreBudgeting/Views/CardDetailView.swift:662:            .padding(.horizontal, Spacing.s)
OffshoreBudgeting/Views/CardDetailView.swift:663:            .padding(.vertical, Spacing.xs)
OffshoreBudgeting/Views/CardDetailView.swift:676:            .padding(.horizontal, Spacing.s)
OffshoreBudgeting/Views/CardDetailView.swift:677:            .padding(.vertical, Spacing.xs)
OffshoreBudgeting/Views/CardDetailView.swift:689:        HStack(spacing: Spacing.xs) {
OffshoreBudgeting/Views/CardDetailView.swift:973:                HStack(spacing: Spacing.xs) {
OffshoreBudgeting/Views/CardDetailView.swift:1050:        let label = HStack(spacing: Spacing.s) {
OffshoreBudgeting/Views/CardDetailView.swift:1055:        .padding(.horizontal, Spacing.m)
OffshoreBudgeting/Views/PresetsView.swift:35:                VStack(spacing: Spacing.l) {
OffshoreBudgeting/Views/PresetsView.swift:38:                            .padding(.horizontal, Spacing.l)
OffshoreBudgeting/Views/PresetsView.swift:48:                            .listRowInsets(EdgeInsets(top: Spacing.m, leading: Spacing.l, bottom: Spacing.m, trailing: Spacing.l))
OffshoreBudgeting/Views/PresetsView.swift:55:                                .listRowInsets(EdgeInsets(top: Spacing.m, leading: Spacing.l, bottom: Spacing.m, trailing: Spacing.l))
OffshoreBudgeting/Views/PresetRowView.swift:31:        VStack(alignment: .leading, spacing: Spacing.m) {
OffshoreBudgeting/Views/PresetRowView.swift:35:        .padding(.vertical, Spacing.xxs)
OffshoreBudgeting/Views/PresetRowView.swift:47:                VStack(alignment: .leading, spacing: Spacing.s) {
OffshoreBudgeting/Views/PresetRowView.swift:56:                HStack(alignment: .center, spacing: Spacing.m) {
OffshoreBudgeting/Views/PresetRowView.swift:64:                    Spacer(minLength: Spacing.m)
OffshoreBudgeting/Views/PresetRowView.swift:89:                VStack(alignment: .leading, spacing: Spacing.sPlus) {
OffshoreBudgeting/Views/PresetRowView.swift:97:                HStack(alignment: .top, spacing: Spacing.m) {
OffshoreBudgeting/Views/PresetRowView.swift:103:                    Spacer(minLength: Spacing.m)
OffshoreBudgeting/Views/PresetRowView.swift:112:        VStack(alignment: alignment, spacing: Spacing.xxs) {
OffshoreBudgeting/Views/PresetRowView.swift:167:        HStack(spacing: Spacing.sPlus) {
OffshoreBudgeting/Views/PresetRowView.swift:185:        .padding(.horizontal, Spacing.m)
… (truncated; 250 more lines)
```

#### `Radius` (type)

```
rg -n "\bRadius\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/DesignSystem/v2/Tokens/Radius.swift:3:// MARK: - Radius
OffshoreBudgeting/DesignSystem/v2/Tokens/Radius.swift:6:/// Keep values 1:1 with legacy `DesignSystem.Radius` when migrating call sites.
OffshoreBudgeting/DesignSystem/v2/Tokens/Radius.swift:7:enum Radius {
OffshoreBudgeting/Views/IncomeView.swift:580:                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
OffshoreBudgeting/App/Navigation/RootTabView.swift:437:                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
OffshoreBudgeting/Views/CardPickerItemTile.swift:40:            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
OffshoreBudgeting/Views/CardPickerItemTile.swift:41:            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
OffshoreBudgeting/Views/AddCardFormView.swift:250:                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
OffshoreBudgeting/Views/AddCardFormView.swift:252:                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
OffshoreBudgeting/Views/AddCardFormView.swift:255:                    .patternOverlay(cornerRadius: Radius.card)
OffshoreBudgeting/Views/AddCardFormView.swift:260:                    cornerRadius: Radius.card,
OffshoreBudgeting/Views/AddCardFormView.swift:263:                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
OffshoreBudgeting/Views/AddCardFormView.swift:274:            RoundedRectangle(cornerRadius: Radius.card)
OffshoreBudgeting/Views/AddCardFormView.swift:303:                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
OffshoreBudgeting/Views/AddCardFormView.swift:305:                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
OffshoreBudgeting/Views/AddCardFormView.swift:307:                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
OffshoreBudgeting/Views/AddCardFormView.swift:320:            RoundedRectangle(cornerRadius: Radius.card)
OffshoreBudgeting/Views/CardTileView.swift:60:    private let cornerRadius: CGFloat = Radius.card
```

#### `Colors` (type)

```
rg -n "\bColors\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Views/AddIncomeFormView.swift:112:                    .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddIncomeFormView.swift:137:                .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddIncomeFormView.swift:170:                .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddIncomeFormView.swift:199:                .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddIncomeFormView.swift:214:                .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddIncomeFormView.swift:226:                .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddIncomeFormView.swift:254:            .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/DesignSystem/v2/Tokens/Colors.swift:6:// MARK: - Colors
OffshoreBudgeting/DesignSystem/v2/Tokens/Colors.swift:11:enum Colors {
OffshoreBudgeting/Views/CardDetailView.swift:220:                Text(message).font(.subheadline).foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/CardDetailView.swift:331:                                    .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/CardDetailView.swift:375:                            .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/CardDetailView.swift:666:                    .fill(Colors.secondaryOpacity012)
OffshoreBudgeting/Views/CardDetailView.swift:670:                    .stroke(Colors.secondaryOpacity018, lineWidth: 0.5)
OffshoreBudgeting/Views/CardDetailView.swift:680:                    .fill(Colors.secondaryOpacity012)
OffshoreBudgeting/Views/CardDetailView.swift:684:                    .stroke(Colors.secondaryOpacity018, lineWidth: 0.5)
OffshoreBudgeting/Views/CardDetailView.swift:698:                    .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/CardDetailView.swift:734:                        .foregroundStyle(Colors.stylePrimary)
OffshoreBudgeting/Views/CardDetailView.swift:748:                        .fill(Colors.primaryOpacity008)
OffshoreBudgeting/Views/CardDetailView.swift:751:                        .foregroundStyle(Colors.stylePrimary)
OffshoreBudgeting/Views/CardDetailView.swift:778:                        .foregroundStyle(Colors.stylePrimary)
OffshoreBudgeting/Views/CardDetailView.swift:798:                        .fill(Colors.primaryOpacity008)
OffshoreBudgeting/Views/CardDetailView.swift:801:                        .foregroundStyle(Colors.stylePrimary)
OffshoreBudgeting/Views/CardDetailView.swift:984:                        .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/CardDetailView.swift:988:                            .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/CardDetailView.swift:991:                            .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/CardDetailView.swift:1091:                    fill: isSelected ? glassTintColor : Colors.chipFill,
OffshoreBudgeting/Views/CardDetailView.swift:1092:                    stroke: isSelected ? Colors.chipSelectedStroke : Colors.chipFill,
OffshoreBudgeting/DesignSystem/v2/Components/CategoryChips.swift:122:                let neutralFill = Colors.chipFill
OffshoreBudgeting/Views/AddBudgetView.swift:137:                    .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddBudgetView.swift:165:                    .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddBudgetView.swift:173:                        .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddBudgetView.swift:195:                    .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddBudgetView.swift:203:                        .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddBudgetView.swift:225:                    .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:172:                            .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:199:                    .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:209:                    .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:244:                    .foregroundStyle(Colors.styleSecondary)
OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:269:                    .foregroundStyle(Colors.styleSecondary)
… (truncated; 181 more lines)
```

#### `DS` (typealias)

```
rg -n "\bDS\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:18:        var horizontalPadding: CGFloat = DS.Spacing.l
OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:19:        var verticalPadding: CGFloat = DS.Spacing.m
OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:42:            horizontalPadding: DS.Spacing.l,
OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:64:            horizontalPadding: DS.Spacing.m,
OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:75:            horizontalPadding: DS.Spacing.m,
OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift:166:        VStack(spacing: DS.Spacing.m) {
OffshoreBudgeting/Views/ManageBudgetPresetsSheet.swift:176:                .padding(.horizontal, DS.Spacing.xl)
OffshoreBudgeting/Views/Components/GlassCTAButton.swift:84:            .padding(.horizontal, DS.Spacing.xl)
OffshoreBudgeting/Views/Components/GlassCTAButton.swift:85:            .padding(.vertical, DS.Spacing.m)
OffshoreBudgeting/Systems/DesignSystem+Motion.swift:10:extension DS {
OffshoreBudgeting/Systems/MotionSupport.swift:9://    Smoothing uses DS.Motion.smoothingAlpha; roll/pitch scaling uses DS.Motion.cardBackgroundAmplitudeScale.
OffshoreBudgeting/Systems/MotionSupport.swift:44:    private var smoothingAlpha: Double = DS.Motion.smoothingAlpha
OffshoreBudgeting/Systems/MotionSupport.swift:46:    private var amplitudeScale: Double = DS.Motion.cardBackgroundAmplitudeScale
OffshoreBudgeting/Systems/MotionSupport.swift:115:    ///   - smoothing: 0...1 (default from DS.Motion.smoothingAlpha)
OffshoreBudgeting/Systems/MotionSupport.swift:116:    ///   - scale: 0...1 (default from DS.Motion.cardBackgroundAmplitudeScale). Applied to roll/pitch smoothing only.
OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:88:                            .foregroundColor(DS.Colors.plannedIncome)
OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:95:                            .foregroundColor(DS.Colors.actualIncome)
OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:102:                            .foregroundColor(DS.Colors.plannedIncome)
OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:109:                            .foregroundColor(DS.Colors.actualIncome)
```
## OffshoreBudgeting/Systems/GuidedWalkthroughManager.swift

- Primary responsibility: (no header comment; inferred from name)
- Imports: `SwiftUI`
- Classification: **App wiring**

### Callsites
#### `TipsScreen` (type)

```
rg -n "\bTipsScreen\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/AppUpdateLogs/2.1.swift:11:    static func content(for screen: TipsScreen) -> TipsContent? {
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:23:    static func content(for screen: TipsScreen, versionToken: String?) -> TipsContent? {
OffshoreBudgeting/AppUpdateLogs/2.0.swift:4:    static func content(for screen: TipsScreen) -> TipsContent? {
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:4:    static func content(for screen: TipsScreen) -> TipsContent? {
```

#### `TipsKind` (type)

```
rg -n "\bTipsKind\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `TipsItem` (type)

```
rg -n "\bTipsItem\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/AppUpdateLogs/2.1.swift:20:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.1.swift:25:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.1.swift:30:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.1.swift:35:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.1.swift:40:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.1.swift:45:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.0.swift:13:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:13:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:18:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:23:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:28:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:33:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:38:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:43:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:48:                    TipsItem(
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:53:                    TipsItem(
OffshoreBudgeting/Views/SettingsView.swift:670:    let item: TipsItem
```

#### `TipsContent` (type)

```
rg -n "\bTipsContent\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/AppUpdateLogs/2.1.swift:11:    static func content(for screen: TipsScreen) -> TipsContent? {
OffshoreBudgeting/AppUpdateLogs/2.1.swift:17:            return TipsContent(
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:7:        let content: TipsContent
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:23:    static func content(for screen: TipsScreen, versionToken: String?) -> TipsContent? {
OffshoreBudgeting/AppUpdateLogs/AppUpdateLogs.swift:39:        let candidates: [(String, TipsContent?)] = [
OffshoreBudgeting/AppUpdateLogs/2.0.swift:4:    static func content(for screen: TipsScreen) -> TipsContent? {
OffshoreBudgeting/AppUpdateLogs/2.0.swift:10:            return TipsContent(
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:4:    static func content(for screen: TipsScreen) -> TipsContent? {
OffshoreBudgeting/AppUpdateLogs/2.0.1.swift:10:            return TipsContent(
```

#### `TipsCatalog` (type)

```
rg -n "\bTipsCatalog\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `TipsAndHintsStore` (type)

```
rg -n "\bTipsAndHintsStore\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Views/SettingsView.swift:773:            action: { TipsAndHintsStore.shared.resetAllTips() },
```

#### `TipsAndHintsOverlayModifier` (type)

```
rg -n "\bTipsAndHintsOverlayModifier\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `TipsPresentationCoordinator` (type)

```
rg -n "\bTipsPresentationCoordinator\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `TipsAndHintsSheet` (type)

```
rg -n "\bTipsAndHintsSheet\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `TipsItemRow` (type)

```
rg -n "\bTipsItemRow\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```
## OffshoreBudgeting/Systems/IncomeCalendarPalette.swift

- Primary responsibility: Shared calendar components for MijickCalendarView.
- Imports: `SwiftUI, MijickCalendarView`
- Classification: **Core platform capability**

### Callsites
#### `UBMonthLabel` (type)

```
rg -n "\bUBMonthLabel\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Views/IncomeView.swift:281:                .monthLabel(UBMonthLabel.init)
```

#### `UBDayView` (type)

```
rg -n "\bUBDayView\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Views/IncomeView.swift:270:                    UBDayView(
```
## OffshoreBudgeting/Systems/MetallicTextStyles.swift

- Primary responsibility: (no header comment; inferred from name)
- Imports: `SwiftUI`
- Classification: **Core platform capability**

### Callsites
#### `UBTypography` (type)

```
rg -n "\bUBTypography\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Views/AddCardFormView.swift:270:                .foregroundStyle(UBTypography.cardTitleStatic)
OffshoreBudgeting/Views/CardTileView.swift:233:        let titleColor: Color = isHighContrast ? .primary : UBTypography.cardTitleStatic
OffshoreBudgeting/Systems/Compatibility.swift:72:            color: UBTypography.cardTitleShadowColor,
OffshoreBudgeting/DesignSystem/v2/Components/Effects/HolographicMetallicText.swift:47:                .foregroundStyle(UBTypography.cardTitleStatic) // uses your Compatibility.swift
```

#### `UBDecor` (type)

```
rg -n "\bUBDecor\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/DesignSystem/v2/Components/Effects/HolographicMetallicText.swift:57:                    .fill(UBDecor.metallicSilverLinear(angle: metallicAngle))
OffshoreBudgeting/DesignSystem/v2/Components/Effects/HolographicMetallicText.swift:66:                    .fill(UBDecor.metallicShine(angle: shineAngle, intensity: shineIntensity))
```
## OffshoreBudgeting/Systems/MotionSupport.swift

- Primary responsibility: Centralized device-motion publisher with smoothing and amplitude scaling.
- Imports: `SwiftUI, Combine, UIKit`
- Classification: **Core platform capability**

### Callsites
#### `MotionMonitor` (type)

```
rg -n "\bMotionMonitor\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Views/CardTileView.swift:275:    @ObservedObject private var motion: MotionMonitor = MotionMonitor.shared
OffshoreBudgeting/DesignSystem/v2/Components/Effects/HolographicMetallicText.swift:5://  Metallic text effect that reacts to device tilt using MotionMonitor.
OffshoreBudgeting/DesignSystem/v2/Components/Effects/HolographicMetallicText.swift:36:    /// Use the shared MotionMonitor on the main actor (no default arg needed).
OffshoreBudgeting/DesignSystem/v2/Components/Effects/HolographicMetallicText.swift:37:    @ObservedObject private var motion: MotionMonitor = MotionMonitor.shared
OffshoreBudgeting/DesignSystem/v2/Components/Effects/HolographicMetallicText.swift:84:    /// Smoothed, normalized device gravity vector supplied by MotionMonitor.
```
## OffshoreBudgeting/Systems/OnboardingEnvironment.swift

- Primary responsibility: (no header comment; inferred from name)
- Imports: `SwiftUI`
- Classification: **App wiring**

### Callsites
#### `OnboardingPresentationKey` (type)

```
rg -n "\bOnboardingPresentationKey\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `isOnboardingPresentation` (env)

```
rg -n "\bisOnboardingPresentation\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
rg -n "\\\.isOnboardingPresentation\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/DesignSystem/v2/Components/EmptyState.swift:11:        @Environment(\.isOnboardingPresentation) private var isOnboardingPresentation
OffshoreBudgeting/DesignSystem/v2/Components/EmptyState.swift:105:            let fallbackTint = isOnboardingPresentation ? onboardingTint : primaryButtonTint
OffshoreBudgeting/DesignSystem/v2/Components/EmptyState.swift:106:            let glassTint = isOnboardingPresentation ? onboardingTint : primaryButtonGlassTint
```
## OffshoreBudgeting/Systems/PlatformCapabilities.swift

- Primary responsibility: (no header comment; inferred from name)
- Imports: `SwiftUI`
- Classification: **Core platform capability**

### Callsites
#### `PlatformCapabilities` (type)

```
rg -n "\bPlatformCapabilities\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:27:    private let platformCapabilities = PlatformCapabilities.current
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:335:        AppLog.ui.info("PlatformCapabilities.current supportsOS26Translucency=\(platformCapabilities.supportsOS26Translucency, privacy: .public) supportsAdaptiveKeypad=\(platformCapabilities.supportsAdaptiveKeypad, privacy: .public) osVersion=\(versionString, privacy: .public) runtimeVersion=\(runtimeVersion, privacy: .public)")
OffshoreBudgeting/Systems/Compatibility.swift:38:        capabilities: PlatformCapabilities
OffshoreBudgeting/Systems/Compatibility.swift:49:    static func shouldUseSystemChrome(capabilities: PlatformCapabilities) -> Bool {
OffshoreBudgeting/Systems/SystemTheme.swift:23:    static func flavor(for capabilities: PlatformCapabilities = .current) -> Flavor {
OffshoreBudgeting/Systems/SystemTheme.swift:41:        platformCapabilities: PlatformCapabilities = .current
OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:4:/// the onboarding flow. It automatically consults `PlatformCapabilities` so
OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:82:        static func macRootTab(for capabilities: PlatformCapabilities) -> Metrics { .macNavigationControl }
```

#### `PlatformCapabilitiesKey` (type)

```
rg -n "\bPlatformCapabilitiesKey\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `platformCapabilities` (env)

```
rg -n "\bplatformCapabilities\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
rg -n "\\\.platformCapabilities\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:27:    private let platformCapabilities = PlatformCapabilities.current
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:107:            .environment(\.platformCapabilities, platformCapabilities)
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:123:                    platformCapabilities: platformCapabilities
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:185:                    platformCapabilities: platformCapabilities
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:192:                    platformCapabilities: platformCapabilities
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:335:        AppLog.ui.info("PlatformCapabilities.current supportsOS26Translucency=\(platformCapabilities.supportsOS26Translucency, privacy: .public) supportsAdaptiveKeypad=\(platformCapabilities.supportsAdaptiveKeypad, privacy: .public) osVersion=\(versionString, privacy: .public) runtimeVersion=\(runtimeVersion, privacy: .public)")
OffshoreBudgeting/Views/OnboardingView.swift:7:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Views/WorkspaceSetupView.swift:10:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Views/HomeView.swift:228:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/DesignSystem/v2/Components/EmptyState.swift:13:        @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/ViewModels/SettingsViewModel.swift:123:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift:85:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:18:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Views/SettingsView.swift:1052:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Views/CloudSyncGateView.swift:9:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Systems/SystemTheme.swift:30:    /// The supplied `platformCapabilities` snapshot ensures every scene makes
OffshoreBudgeting/Systems/SystemTheme.swift:37:    ///   - platformCapabilities: Platform feature snapshot to keep decisions consistent.
OffshoreBudgeting/Systems/SystemTheme.swift:41:        platformCapabilities: PlatformCapabilities = .current
OffshoreBudgeting/Systems/SystemTheme.swift:46:        guard !platformCapabilities.supportsOS26Translucency else { return }
OffshoreBudgeting/Views/Components/GlassCTAButton.swift:8:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Systems/Compatibility.swift:225:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Systems/Compatibility.swift:312:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Systems/Compatibility.swift:326:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Systems/Compatibility.swift:346:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Systems/Compatibility.swift:367:    @Environment(\.platformCapabilities) private var capabilities
OffshoreBudgeting/Systems/Compatibility.swift:408:    @Environment(\.platformCapabilities) private var capabilities
```
## OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift

- Primary responsibility: (no header comment; inferred from name)
- Imports: `SwiftUI, UIKit`
- Classification: **Core platform capability**

### Callsites
#### `ResponsiveLayoutContext` (type)

```
rg -n "\bResponsiveLayoutContext\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Views/CardDetailView.swift:817:    private func resolvedCardMaxWidth(in context: ResponsiveLayoutContext) -> CGFloat? {
OffshoreBudgeting/Views/CardDetailView.swift:834:    private func resolvedDateRowMaxWidth(in context: ResponsiveLayoutContext) -> CGFloat? {
OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:31:    private func resolvedBaseFontSize(in context: ResponsiveLayoutContext) -> CGFloat {
```

#### `Idiom` (type)

```
rg -n "\bIdiom\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `ResponsiveLayoutContextKey` (type)

```
rg -n "\bResponsiveLayoutContextKey\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `ResponsiveLayoutReader` (type)

```
rg -n "\bResponsiveLayoutReader\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:53:                ResponsiveLayoutReader { _ in
```

#### `LegacySafeAreaCapture` (type)

```
rg -n "\bLegacySafeAreaCapture\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `responsiveLayoutContext` (env)

```
rg -n "\bresponsiveLayoutContext\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
rg -n "\\\.responsiveLayoutContext\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Systems/IncomeCalendarPalette.swift:18:    @Environment(\.responsiveLayoutContext) private var layoutContext
OffshoreBudgeting/App/Navigation/RootTabView.swift:29:    @Environment(\.responsiveLayoutContext) private var layoutContext
OffshoreBudgeting/Views/CardDetailView.swift:30:    @Environment(\.responsiveLayoutContext) private var layoutContext
OffshoreBudgeting/Views/CardsView.swift:19:    @Environment(\.responsiveLayoutContext) private var layoutContext
OffshoreBudgeting/Views/HelpView.swift:650:    @Environment(\.responsiveLayoutContext) private var layoutContext
OffshoreBudgeting/Views/IncomeView.swift:26:    @Environment(\.responsiveLayoutContext) private var layoutContext
```
## OffshoreBudgeting/Systems/SafeAreaInsetsCompatibility.swift

- Primary responsibility: (no header comment; inferred from name)
- Imports: `SwiftUI`
- Classification: **Core platform capability**

### Callsites
#### `UBSafeAreaInsetsEnvironmentKey` (type)

```
rg -n "\bUBSafeAreaInsetsEnvironmentKey\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBSafeAreaInsetsPreferenceKey` (type)

```
rg -n "\bUBSafeAreaInsetsPreferenceKey\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `UBSafeAreaInsetsReader` (type)

```
rg -n "\bUBSafeAreaInsetsReader\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `ub_safeAreaInsets` (env)

```
rg -n "\bub_safeAreaInsets\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
rg -n "\\\.ub_safeAreaInsets\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:19:    @Environment(\.ub_safeAreaInsets) private var legacySafeAreaInsets
OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:111:    @Environment(\.ub_safeAreaInsets) private var legacySafeAreaInsets
```

#### `ub_captureSafeAreaInsets` (func)

```
rg -n "\bub_captureSafeAreaInsets\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Systems/ResponsiveLayoutContext.swift:163:            content.ub_captureSafeAreaInsets()
```
## OffshoreBudgeting/Systems/SystemTheme.swift

- Primary responsibility: (no header comment; inferred from name)
- Imports: `SwiftUI, UIKit`
- Classification: **Core platform capability**

### Callsites
#### `SystemThemeAdapter` (type)

```
rg -n "\bSystemThemeAdapter\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:120:                SystemThemeAdapter.applyGlobalChrome(
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:182:                SystemThemeAdapter.applyGlobalChrome(
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:189:                SystemThemeAdapter.applyGlobalChrome(
```

#### `Flavor` (type)

```
rg -n "\bFlavor\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```
## OffshoreBudgeting/Systems/UITestingEnvironment.swift

- Primary responsibility: (no header comment; inferred from name)
- Imports: `SwiftUI`
- Classification: **App wiring**

### Callsites
#### `UITestingFlags` (type)

```
rg -n "\bUITestingFlags\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/ViewModels/AppLockViewModel.swift:245:    func configureForUITesting(flags: UITestingFlags) {
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:426:    func uiTestingFlagsIfAny() -> UITestingFlags {
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:430:            return UITestingFlags(
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:466:        return UITestingFlags(
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:488:        let flags = UITestingFlags(
```

#### `UITestBiometricAuthResult` (type)

```
rg -n "\bUITestBiometricAuthResult\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/ViewModels/AppLockViewModel.swift:297:            .flatMap { UITestBiometricAuthResult(rawValue: $0.lowercased()) }
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:446:            .flatMap { UITestBiometricAuthResult(rawValue: $0.lowercased()) }
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:486:            .flatMap { UITestBiometricAuthResult(rawValue: $0.lowercased()) }
```

#### `UITestingFlagsKey` (type)

```
rg -n "\bUITestingFlagsKey\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `StartTabIdentifierKey` (type)

```
rg -n "\bStartTabIdentifierKey\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `StartRouteIdentifierKey` (type)

```
rg -n "\bStartRouteIdentifierKey\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
(no matches outside defining file)
```

#### `uiTestingFlags` (env)

```
rg -n "\buiTestingFlags\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
rg -n "\\\.uiTestingFlags\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/Views/CardDetailView.swift:36:    @Environment(\.uiTestingFlags) private var uiTestingFlags
OffshoreBudgeting/Views/CardDetailView.swift:237:                let topPadding: CGFloat = uiTestingFlags.isUITesting ? Spacing.s : initialHeaderTopPadding
OffshoreBudgeting/Views/CardDetailView.swift:238:                let bottomPadding: CGFloat = uiTestingFlags.isUITesting ? Spacing.xs : Spacing.m
OffshoreBudgeting/Views/CardDetailView.swift:246:                if uiTestingFlags.isUITesting {
OffshoreBudgeting/Views/CardDetailView.swift:253:            if !uiTestingFlags.isUITesting {
OffshoreBudgeting/Views/CardDetailView.swift:351:            if !uiTestingFlags.isUITesting {
OffshoreBudgeting/Views/IncomeView.swift:15:    @Environment(\.uiTestingFlags) private var uiTest
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:108:            .environment(\.uiTestingFlags, testFlags)
OffshoreBudgeting/App/Navigation/RootTabView.swift:53:    @Environment(\.uiTestingFlags) private var uiTestingFlags
OffshoreBudgeting/App/Navigation/RootTabView.swift:68:                if uiTestingFlags.isUITesting, uiTestSeedDone {
OffshoreBudgeting/App/Navigation/RootTabView.swift:395:            if uiTestingFlags.isUITesting, uiTestStartRoute == "categories", shouldUseCompactTabs {
OffshoreBudgeting/App/Navigation/RootTabView.swift:535:        guard uiTestingFlags.isUITesting, !appliedStartRoute, let route = startRouteIdentifier else { return }
OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:21:    @Environment(\.uiTestingFlags) private var uiTestingFlags
OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:209:        .accessibilityElement(children: uiTestingFlags.isUITesting ? .contain : .ignore)
OffshoreBudgeting/Views/CloudSyncGateView.swift:8:    @Environment(\.uiTestingFlags) private var uiTesting
OffshoreBudgeting/Views/SettingsView.swift:790:    @Environment(\.uiTestingFlags) private var uiTestingFlags
OffshoreBudgeting/Views/SettingsView.swift:813:            if uiTestingFlags.isUITesting {
OffshoreBudgeting/Views/SettingsView.swift:815:                    Text("UI Test App Lock: allow=\(uiTestingFlags.allowAppLock ? "1" : "0"), available=\(appLockViewModel.isDeviceAuthAvailable ? "1" : "0")")
```

#### `startTabIdentifier` (env)

```
rg -n "\bstartTabIdentifier\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
rg -n "\\\.startTabIdentifier\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/App/Navigation/RootTabView.swift:51:    @Environment(\.startTabIdentifier) private var startTabIdentifier
OffshoreBudgeting/App/Navigation/RootTabView.swift:512:        guard !appliedStartTab, let key = startTabIdentifier else { return }
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:109:            .environment(\.startTabIdentifier, startTab)
```

#### `startRouteIdentifier` (env)

```
rg -n "\bstartRouteIdentifier\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
rg -n "\\\.startRouteIdentifier\b" OffshoreBudgeting OffshoreWidgets OffshoreBudgetingTests OffshoreBudgetingUITests
OffshoreBudgeting/App/Navigation/RootTabView.swift:52:    @Environment(\.startRouteIdentifier) private var startRouteIdentifier
OffshoreBudgeting/App/Navigation/RootTabView.swift:535:        guard uiTestingFlags.isUITesting, !appliedStartRoute, let route = startRouteIdentifier else { return }
OffshoreBudgeting/App/OffshoreBudgetingApp.swift:110:            .environment(\.startRouteIdentifier, startRoute)
```
