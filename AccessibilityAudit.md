# Accessibility Audit

This file tracks accessibility findings and fixes view-by-view.
Keep entries scoped, verified against repo code and /Documentation, and link to
evidence (Accessibility Inspector HTML report, screenshots, or Apple docs).

## Sources
- /Documentation/AccessibilityGuidelines.md
- /Documentation/Accessibility | Apple Developer Documentation.pdf
- /Documentation/Applying custom fonts to text | Documentation.pdf
- AuditReport_2026-01-01_12-30-07.html
- Reports/AuditReport_2026-01-02_11-02-25.html
- Reports/AuditReport_2026-01-02_13-56-17.html
- Reports/AuditReport_2026-01-03_12-58-34.html
- Reports/AuditReport_2026-01-03_13-12-13.html
- Reports/AuditReport_2026-01-03_15-49-13.html
- Reports/AuditReport_2026-01-03_16-28-16.html
- Reports/AuditReport_2026-01-04_17-49-22.html

## Audit Log

### Session 1
- Date:
- Scope:
- Notes:
  - Parsed Accessibility Inspector HTML report for HomeView (iOS 26, iPhone) and extracted per-issue metadata.
  - Exported issue thumbnails and a labeled index sheet for visual mapping.
  - Observed repeated issue types: contrast on colored widget titles, Dynamic Type unsupported on most text, and a small hit target on the date-range apply arrow.

### Session 2
- Date:
- Scope: HomeView Dynamic Type warnings
- Notes:
  - Reviewed `/Documentation/Applying custom fonts to text | Documentation.pdf` and `/Documentation/Accessibility | Apple Developer Documentation.pdf`.
  - Identified fixed layout constraints in `HomeView` (grid row height, fixed-size frames near text, widget card height) as likely contributors to Dynamic Type warnings.
  - Decided to use `@ScaledMetric` for row height/spacing and replace fixed-size fonts in HomeView-related subviews with Dynamic Type styles.

### Session 3
- Date:
- Scope: HomeView Dynamic Type warnings (AuditReport_2026-01-03_12-58-34.html)
- Notes:
  - Extracted issue thumbnails and index sheet at `Reports/a11y_thumbs_2026-01-03_12-58-34/index_sheet.jpg`.
  - Dynamic Type warnings map to date range labels, widget titles, percentage labels, and currency values.
  - Planned to reflow the widget grid into a stacked list and relax line limits at accessibility sizes.

### Session 4
- Date:
- Scope: Expense import menus (button shapes)
- Notes:
  - On iOS with Button Shapes enabled, Menu controls can render an oversized oblong outline around custom capsule/rounded-rect labels.
  - Fix: apply `.buttonStyle(.plain)` and `.buttonBorderShape(.capsule)` to Menu labels so the accessibility outline matches the visual capsule/rounded-rect.
  - Code: `OffshoreBudgeting/Views/ExpenseImportView.swift`
  - Verify: Enable Button Shapes in Accessibility settings and confirm menu outlines match the label shape.

### Session 4
- Date: 2026-01-03
- Scope: HomeView layout refactor, hit targets, and contrast strategy
- Notes:
  - Replaced masonry widget grid with a List + Section layout to allow vertical growth.
  - Removed inner chevrons inside widgets (keep List/NavigationLink chevron only).
  - Date row converted to a stacked layout in accessibility sizes; pickers + action buttons now in separate rows.
  - Apply + calendar buttons kept at 44x44 with increased spacing; symbol sizing tied to Dynamic Type text styles.
  - Card widgets: removed span-based minHeight and vertical filler to reduce excess whitespace.
  - Category Availability: stacked header/status in accessibility sizes and switched to a single vertical list (no paging) for readability.
  - Category Spotlight: donut height uses scaled metrics; caption allowed to wrap.
  - Day of Week Spend: chart height uses scaled metrics; "Highest" label allowed to wrap; label widths increased for longer date spans.
  - Next Planned Expense: stacked layout in accessibility sizes and removed line limits to avoid truncation.
  - Preference confirmed: keep original UI colors; only adjust colors in Increased Contrast mode, do not change the default palette.
  - Color hex changes were disliked and rolled back; high-contrast alternatives only.

### Session 5
- Date: 2026-01-03
- Scope: AuditReport_2026-01-03_16-28-16.html mapping and residual warnings
- Notes:
  - Extracted issue thumbnails and index sheet at `Reports/index_sheet_2026-01-03_16-28-16.jpg`.
  - Contrast warnings mapped to header “Widgets”, Edit button, and system UI (status bar / tab bar).
  - Dynamic Type warnings mapped to: Widgets header, Edit button, Category Availability title and status labels (Over/Near/Max), date range subtitle, and “Next” label.
  - Some warnings correspond to system UI (status bar time and tab bar icons) and are not app-controlled.
  - HomeView text uses Dynamic Type styles throughout; remaining “Dynamic Type unsupported” warnings likely reflect Accessibility Inspector false positives for styled SwiftUI containers.

### Session 6
- Date: 2026-01-03
- Scope: BudgetsView (AuditReport_2026-01-03_17-09-32.html)
- Notes:
  - Mapped 3 Dynamic Type warnings to: section header “Active Budgets”, budget row title (“January 2026”), and budget row date range (“Jan 1 – 31, 2026”).
  - All mapped texts use Dynamic Type styles (`.headline` / `.subheadline`) and scale correctly in the simulator.
  - Replaced fixed icon sizes (chevron + clear search icon) with Dynamic Type caption styles to reduce false positives.
  - Result: Accessibility Inspector still reports “Dynamic Type unsupported” despite correct scaling. Treated as Inspector noise for grouped list styling; UI accepted as-is.
  - VoiceOver pass:
    - Section headers announce title + expanded/collapsed state with a hint.
    - Search toolbar icons labeled (“Search Budgets” / “Close Search”).
    - Search field labeled explicitly.
    - Budget rows announce a combined label (title + date range).

### Session 7
- Date: 2026-01-03
- Scope: HomeView layout cleanup + VoiceOver labels
- Notes:
  - Date row controls: added a horizontal-first layout so compact mode keeps start/end pickers side-by-side when possible, with a two-row fallback before the fully stacked layout.
  - Apply and calendar buttons: visual circle size clamped to 44pt minimum and labels/hints added for VoiceOver.
  - Category Availability widget: removed paging in non-accessibility sizes so the container grows with content; rows now list vertically like the accessibility version.
  - Widgets header controls: Edit/Done button now includes explicit VoiceOver label/hint.
  - Widget pin controls: added VoiceOver labels/hints for pin/unpin actions, including widget title in the announcement.
  - Category Availability rows now render a progress bar even when no cap is set (uses remaining income as the denominator) to keep visual alignment consistent.
  - Category Availability paging restored (5 rows per page) with HIG-sized chevron buttons; glass buttons on iOS 26 and plain SF symbols on legacy OSes.

### Session 8
- Date: 2026-01-03
- Scope: Category Availability layout stabilization
- Notes:
  - Fixed widget height across pages by locking the non-accessibility list height to 5 rows + spacing + padding.
  - Accessibility sizes use flexible height (no placeholders) to avoid compression at large Dynamic Type sizes.
  - Added per-row breathing room that scales with accessibility size (normal +10, accessibility +20).

### Session 9
- Date: 2026-01-03
- Scope: SettingsView accessibility sweep
- Notes:
  - Removed fixed symbol font sizes from settings icons and toolbar menu button; icons now scale with Dynamic Type and use `@ScaledMetric` for tile sizes.
  - Increased icon/text spacing in settings rows and allowed titles to wrap without truncation.
  - Added explicit accessibility labels for settings rows and the App Info row; decorative icons hidden from VoiceOver.
  - Removed fixed max-height constraints on settings action buttons to avoid clipping at larger text sizes.

### Session 10
- Date: 2026-01-03
- Scope: CardsView + CardTileView accessibility sweep (pre-CardDetail)
- Notes:
  - Card tile backgrounds now adapt to light/dark and Increased Contrast via a subtle theme overlay.
  - Card title respects Reduce Motion by disabling holographic motion and falling back to static text when needed.
  - Card title allows wrapping at accessibility sizes and scales with Dynamic Type; padding uses `@ScaledMetric`.
  - Cards grid sizes (tile width/height/spacing) now scale with Dynamic Type to reduce clipping.
  - Theme swatches in Add Card preview use the same adaptive overlay for visual consistency.

### Session 11
- Date: 2026-01-04
- Scope: AddPlannedExpenseView + AddUnplannedExpenseView (AuditReport_2026-01-04_17-49-22.html)
- Notes:
  - Card picker rows now scale with Dynamic Type using `@ScaledMetric` and flexible min-heights to avoid clipping at largest text sizes.
  - Category chips use scaled dot sizes and flexible chip heights; vertical padding increases at accessibility sizes to prevent text clipping.
  - Added explicit VoiceOver labels/hints for category chips (select action).
  - Fixed-height text in the empty card state replaced with a minimum height to allow wrapping at large text sizes.

### Session 12
- Date: 2026-01-04
- Scope: IncomeView calendar + navigation controls
- Notes:
  - Calendar nav buttons now use Dynamic Type styles with scaled hit targets and spacing.
  - Calendar height scales with Dynamic Type via `@ScaledMetric` so month/day labels have room to grow.
  - Month label and day cell typography now scale with Dynamic Type while preserving layout-based sizing.

## Extraction Algorithm (HomeView Report)
1) Read the HTML report and locate the embedded `rootObject` JSON payload.
2) Parse `_axKeyAllScreens[0]._axKeyAllIssues` to collect each issue.
3) For each issue:
   - Capture type (`_axKeyShortDesc`), description/suggestion, and element rect (x, y, w, h).
   - Decode `_axKeyImageThumbnail._axKeyImageData` and save as `issue_XX.jpg`.
4) Create a labeled index sheet:
   - Render each thumbnail with its issue number, type, and rect.
   - Export to `/Reports/a11y_thumbs_2026-01-02/index_sheet.jpg`.
5) Use the index sheet to visually map repeated issue patterns to specific UI elements before proposing code changes.

## Mapping Step (HomeView)
1) Open `index_sheet.jpg` and identify repeating labels (e.g., widget titles, date range, edit button).
2) Find the corresponding SwiftUI text/button definitions in `OffshoreBudgeting/Views/HomeView.swift`.
3) Map each issue pattern to a single source of truth:
   - Widget title color -> `HomeWidgetKind.titleColor` and `widgetCard` title styling.
   - Dynamic Type warnings -> widget title/subtitle/value fonts, date range label, and edit button.
   - Hit target warning -> apply arrow button in date range controls.
4) Propose a pattern-based fix plan that addresses all repeated elements in one pass.
5) Draft proposed code changes (no edits) with exact file locations before implementation.

## Audit Checklist
- Verify Button Shapes outlines match visible button/menu shapes (especially `Menu` labels and capsule buttons).
- Verify Dynamic Type scaling with large sizes (no clipped text; list rows expand).
- Verify contrast for secondary labels against glass/overlay backgrounds.

## Patterns and Heuristics
- Dynamic Type warnings: eliminate fixed font sizes; use Dynamic Type styles and `@ScaledMetric` for spacing, chart sizes, and row heights.
- Accessibility sizes: prefer stacked layouts, remove line limits, and allow containers to grow instead of forcing fixed heights.
- Non-accessibility sizes: stabilize layout by fixing list/widget heights and using placeholder rows to avoid page-to-page shifts.
- Hit targets: icon-only actions need a visible 44x44 container; keep symbol size tied to Dynamic Type (e.g., `.title3/.title2`).
- Contrast: preserve the default palette; only change colors in Increased Contrast mode.
- List chevrons: use the system NavigationLink chevron; remove custom inner chevrons to avoid duplication.
- Pagination: use fixed page sizes with HIG-sized left/right buttons; ensure symbols remain visible in light/dark via `.primary` and a subtle background on legacy.
- VoiceOver: add explicit labels and hints for icon-only controls (edit, pin/unpin, apply, calendar, search, etc.).

## Views

### Template
- View:
- Issue:
- Evidence:
- Fix:
- Verification:
- Status:

### ExpenseImportView
- Issue: Menu buttons show oversized oblong outlines with Button Shapes enabled, making labels look detached.
- Fix: Apply `.buttonStyle(.plain)` + `.buttonBorderShape(.capsule)` via a shared helper for Menu labels.
- Verification: Toggle Button Shapes and confirm the outline matches the capsule/rounded-rect menu label.

### HomeView
- Issue:
  - Dynamic Type unsupported warnings on widget headers/labels despite using Dynamic Type styles.
  - Clipping/truncation in widget captions and availability list.
  - Hit target sizing for date-range apply/calendar buttons.
  - Contrast warnings on widget titles in Increased Contrast mode; original colors must remain.
- Evidence:
  - AuditReport_2026-01-03_16-28-16.html
  - Reports/index_sheet_2026-01-03_16-28-16.jpg
  - Simulator screenshots in Reports/ (iPhone 17 Pro Max series)
- Fix:
  - List + Section layout for widgets; remove inner chevrons; allow multi-line titles/subtitles.
  - Date row stacked in accessibility sizes; buttons at least 44x44 with increased spacing.
  - Category Availability uses stacked header and full list in accessibility sizes.
  - Category Spotlight and Day of Week Spend allow captions to wrap; scaled chart/donut heights.
  - Keep original colors; use high-contrast alternatives only when Increase Contrast is enabled.
- Verification:
  - Visual review with Largest Text enabled and Accessibility Inspector reports.
- Status:
  - Improved layout and readability; residual Dynamic Type warnings persist, likely due to Inspector false positives and system UI elements.
