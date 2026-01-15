# Components → DesignSystemV2 equivalence audit (read-only)

Scope (legacy files audited):
- `OffshoreBudgeting/Views/Components/CategoryChipPill.swift`
- `OffshoreBudgeting/Views/Components/GlassCTAButton.swift`
- `OffshoreBudgeting/Views/Components/SheetDetentsCompat.swift`
- `OffshoreBudgeting/Views/Components/TranslucentButtonStyle.swift`

Scope (DSv2 searched):
- `OffshoreBudgeting/DesignSystem/v2` (Swift files only)

DSv2 search command (as requested):
```sh
rg -n "CategoryChip|ChipPill|GlassCTA|CTAButton|Detents|sheetDetents|Translucent|ButtonStyle" OffshoreBudgeting/DesignSystem/v2 -g"*.swift"
```

Result highlights:
- Matches were found only for `CategoryChip*` in `OffshoreBudgeting/DesignSystem/v2/Components/CategoryChips.swift`.
- No DSv2 matches were found for `GlassCTA*`, `*Detents*`, `Translucent*`, or `ButtonStyle` by this search term set.

---

## 1) `CategoryChipPill.swift`

### Summary
- Primary responsibility: renders a pill-shaped container around an arbitrary label view, with an OS 26 “glassEffect” treatment when `glassTint` is provided; otherwise a legacy fill/stroke fallback.
- Required inputs:
  - `label: () -> Label` (content)
  - Visual config: `glassTint`, `glassTextColor`, `fallbackTextColor`, `fallbackFill`, `fallbackStrokeColor`, `fallbackStrokeLineWidth`
  - State-like inputs present but not currently used: `isSelected`, `isInteractive`
- Output: `some View` (a capsule-like “chip” with fixed height).

### Public API surface
- Exported type: `struct CategoryChipPill<Label: View>: View`
- Initializer:
  - `init(isSelected:glassTint:glassTextColor:fallbackTextColor:fallbackFill:fallbackStrokeColor:fallbackStrokeLineWidth:isInteractive:label:)`

### Styling tokens used
- Typography:
  - `.font(.footnote.weight(.semibold))`
- Spacing / sizing:
  - `.padding(.horizontal, 12)`
  - `.frame(height: 33)`
- Radius / shape:
  - `.clipShape(Capsule())`
  - `RoundedRectangle(cornerRadius: 16, style: .continuous)` for background + overlay + content shape
- Colors:
  - Default fallback fill `Color(UIColor.systemGray5)`
  - OS 26 stroke `Color.primary.opacity(0.12)` (line width `0.8`)
  - Default text colors are `.primary`

### Callsites
Commands used:
```sh
rg -n "CategoryChipPill" OffshoreBudgeting -g"*.swift"
```

Counts and top locations:
- `CategoryChipPill`: `4` matches total, `2` callsites excluding definition
  - `OffshoreBudgeting/Views/HomeView.swift:4418`
  - `OffshoreBudgeting/Views/HomeView.swift:4431`

### DSv2 equivalents
- Closest DSv2 component: `DesignSystemV2.CategoryChip` (`OffshoreBudgeting/DesignSystem/v2/Components/CategoryChips.swift`)
  - Mapping: **partial**
  - Why: `CategoryChipPill` is a generic “pill surface around arbitrary label” component, while `DesignSystemV2.CategoryChip` is a semantic “category chip” with a fixed layout (dot + title + optional trailing text) and built-in selection + accessibility semantics.
- Related DSv2 entrypoints:
  - `DesignSystemV2.CategoryChipsRow` (`OffshoreBudgeting/DesignSystem/v2/Components/CategoryChips.swift`) — semantic row + scrolling behavior + Dynamic Type handling.
  - `DesignSystemV2.ChipLegacySurface` (`OffshoreBudgeting/DesignSystem/v2/Components/ChipStyles.swift`) — legacy rounded-rect surface modifier used by DSv2 chips.

---

## 2) `GlassCTAButton.swift`

### Summary
- Primary responsibility: a call-to-action `Button` wrapper that prefers OS 26 glass styling when `PlatformCapabilities.supportsOS26Translucency` is true, otherwise uses a legacy `TranslucentButtonStyle` fallback.
- Required inputs:
  - `action: () -> Void`
  - `label: () -> Label`
  - Layout inputs: `maxWidth`, `fillHorizontally`
  - Fallback inputs: `fallbackAppearance: TranslucentButtonStyle.Appearance`, `fallbackMetrics: TranslucentButtonStyle.Metrics`
  - Environment dependencies: `PlatformCapabilities`, `ThemeManager`, `ColorScheme`
- Output: `some View` (a `Button` with conditional styling).

### Public API surface
- Exported type: `struct GlassCTAButton<Label: View>: View`
- Initializer:
  - `init(maxWidth:height:fillHorizontally:fallbackAppearance:fallbackMetrics:action:label:)`

### Styling tokens used
- Typography:
  - `.font(.system(size: 17, weight: .semibold, design: .rounded))`
- Spacing:
  - `.padding(.horizontal, DS.Spacing.xl)`
  - `.padding(.vertical, DS.Spacing.m)`
- Colors:
  - OS 26 tint uses `themeManager.selectedTheme.glassPalette.accent`
  - Fallback tint uses `themeManager.selectedTheme.resolvedTint`
  - Label foreground: `colorScheme == .light ? .black : .primary`
- Platform styling:
  - OS 26 path: `.buttonStyle(.glass)` + `.tint(glassTint)`
  - Legacy path: `.buttonStyle(TranslucentButtonStyle(...))`

Notes (observed in file as-written):
- `height` is accepted by the initializer but is not applied anywhere in `body`.

### Callsites
Commands used:
```sh
rg -n "GlassCTAButton" OffshoreBudgeting -g"*.swift"
rg -n "TranslucentButtonStyle" OffshoreBudgeting -g"*.swift"
```

Counts and top locations:
- `GlassCTAButton`: `6` matches total, `2` callsites excluding definition
  - `OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:192`
  - `OffshoreBudgeting/Views/AddPlannedExpenseView.swift:140`
- `TranslucentButtonStyle`: `7` matches total, `6` callsites excluding `TranslucentButtonStyle.swift` (all within `GlassCTAButton.swift`)
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:17`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:18`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:24`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:25`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:52`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:101`

### DSv2 equivalents
- Closest DSv2 component(s): `DesignSystemV2.Buttons.PrimaryCTA` / `SecondaryCTA` / `DestructiveCTA` (`OffshoreBudgeting/DesignSystem/v2/Components/ButtonsV2.swift`)
  - Mapping: **partial**
  - Why:
    - DSv2 CTA components provide an OS 26 glass path (`.buttonStyle(.glassProminent)` + `.tint(tint)`) and a legacy fallback path via an injectable `legacyStyle` closure.
    - `GlassCTAButton` uses `.buttonStyle(.glass)` (not `.glassProminent`) and hard-wires its legacy fallback to `TranslucentButtonStyle` with ThemeManager-derived tinting; DSv2 does not include an equivalent “TranslucentButtonStyle” in `v2/`.

---

## 3) `SheetDetentsCompat.swift`

### Summary
- Primary responsibility: compatibility wrapper for sheet detents; applies `.presentationDetents` and `.presentationDragIndicator(.visible)` only when iOS/macCatalyst 16+ APIs are available.
- Required inputs:
  - `detents: [UBPresentationDetent]`
  - `selection: Binding<UBPresentationDetent>?` (optional)
- Output: `some View` (wrapped in `AnyView` for availability branching).

### Public API surface
- Exported type: `enum UBPresentationDetent: Equatable, Hashable`
  - Cases: `.medium`, `.large`, `.fraction(Double)`
  - iOS 16+ bridge: `var systemDetent: PresentationDetent`
- Exported extension:
  - `View.applyDetentsIfAvailable(detents:selection:) -> some View`

### Styling tokens used
- None (behavioral / availability compatibility only).

### Callsites
Commands used:
```sh
rg -n "applyDetentsIfAvailable" OffshoreBudgeting -g"*.swift"
rg -n "UBPresentationDetent" OffshoreBudgeting -g"*.swift"
```

Counts and top locations:
- `applyDetentsIfAvailable`: `12` matches total, `11` callsites excluding definition
  - `OffshoreBudgeting/Views/AddIncomeFormView.swift:49`
  - `OffshoreBudgeting/Views/IncomeEditorView.swift:174`
  - `OffshoreBudgeting/Views/BudgetDetailsView.swift:796`
  - `OffshoreBudgeting/Views/AddCardFormView.swift:196`
  - `OffshoreBudgeting/Views/AddUnplannedExpenseView.swift:129`
  - `OffshoreBudgeting/Views/RenameCardSheet.swift:59`
  - `OffshoreBudgeting/Views/ExpenseCategoryManagerView.swift:472`
  - `OffshoreBudgeting/Views/ExpenseImportView.swift:52`
  - `OffshoreBudgeting/Views/ExpenseImportView.swift:541`
  - `OffshoreBudgeting/Views/AddPlannedExpenseView.swift:402`
- `UBPresentationDetent`: `5` matches total, `0` callsites excluding definition

Notes (observed in file as-written):
- When `selection` is provided, the `PresentationDetent -> UBPresentationDetent` reverse mapping only recognizes `.medium` and `.large`; all other values (including `.fraction`) map to `.medium`.

### DSv2 equivalents
- No DSv2 equivalent found in `OffshoreBudgeting/DesignSystem/v2` by the required search terms, and no `v2` sheet/detents abstraction was observed during this audit.
  - Mapping: **none**
  - Comment: this helper is compatibility behavior rather than visual styling, so it may not belong in DSv2 unless DSv2 is also the home for cross-platform/availability view modifiers.

---

## 4) `TranslucentButtonStyle.swift`

### Summary
- Primary responsibility: a `ButtonStyle` implementing a tinted translucent “glass-like” treatment that consults `PlatformCapabilities` (OS 26 translucency) and falls back to a legacy flat fill on older OSes.
- Required inputs:
  - `tint: Color`
  - `metrics: TranslucentButtonStyle.Metrics` (layout + sizing + typography config)
  - `appearance: TranslucentButtonStyle.Appearance` (tinted vs neutral behavior)
  - Environment dependencies: `PlatformCapabilities`, `ThemeManager`, `ColorScheme`
- Output: `some View` via `ButtonStyle.makeBody(configuration:)`.

### Public API surface
- Exported type: `struct TranslucentButtonStyle: ButtonStyle`
- Exported nested types:
  - `struct Metrics`
    - `enum Layout { case expandHorizontally, hugging }`
    - Properties: `layout`, `width`, `height`, `cornerRadius`, `horizontalPadding`, `verticalPadding`, `pressedScale`, `font`, `overridesLabelForeground`
    - Presets: `.standard`, `.rootActionIcon`, `.rootActionLabel`, `.calendarNavigationIcon`, `.calendarNavigationLabel`, `.macNavigationControl`, `macRootTab(for:)`
  - `enum Appearance { case tinted, neutral }`
- Exported initializer:
  - `init(tint:metrics:appearance:)`

### Styling tokens used
- Spacing:
  - Defaults use `DS.Spacing.l` / `DS.Spacing.m` for padding
- Radius:
  - Default `cornerRadius: 26` (and several fixed radii in presets)
  - OS 26 path uses `radius = metrics.cornerRadius`; legacy path uses `radius = 0`
- Typography:
  - Presets use `.system(size:…, weight:…, design: .rounded)` in some cases
  - Optional per-metrics `font` override
- Colors / materials:
  - OS 26 path uses `.ultraThinMaterial` plus tinted overlays
  - Legacy path uses theme-derived `secondaryBackground` with opacity adjustments
  - Multiple hard-coded opacities, line widths, blur radii, and highlight/glow blend modes
- Motion:
  - `.animation(.spring(response: 0.32, dampingFraction: 0.72), value: configuration.isPressed)`
  - `pressedScale` defaults (`0.98`) and varies by preset

### Callsites
Commands used:
```sh
rg -n "TranslucentButtonStyle" OffshoreBudgeting -g"*.swift"
rg -n "TranslucentButtonStyle\\(" OffshoreBudgeting -g"*.swift"
rg -n "TranslucentButtonStyle\\.Metrics" OffshoreBudgeting -g"*.swift"
rg -n "TranslucentButtonStyle\\.Appearance" OffshoreBudgeting -g"*.swift"
```

Counts and top locations:
- `TranslucentButtonStyle`: `7` matches total, `6` callsites excluding definition
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:17`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:18`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:24`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:25`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:52`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:101`
- `TranslucentButtonStyle(`: `1` match total
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:52`
- `TranslucentButtonStyle.Metrics`: `3` matches total (all within `GlassCTAButton.swift`)
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:18`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:25`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:101`
- `TranslucentButtonStyle.Appearance`: `2` matches total (all within `GlassCTAButton.swift`)
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:17`
  - `OffshoreBudgeting/Views/Components/GlassCTAButton.swift:24`

### DSv2 equivalents
- No DSv2 equivalent found in `OffshoreBudgeting/DesignSystem/v2` by the required search terms, and `OffshoreBudgeting/DesignSystem/v2/Components/ButtonsV2.swift` does not define a DSv2 `ButtonStyle` analogous to `TranslucentButtonStyle`.
  - Mapping: **none**
  - Closest conceptual DSv2 area: `DesignSystemV2.Buttons.*CTA` components (`OffshoreBudgeting/DesignSystem/v2/Components/ButtonsV2.swift`), but these are component wrappers over glass/legacy styles rather than a reusable style with metrics/presets.
