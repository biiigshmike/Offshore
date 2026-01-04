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

## Views

### Template
- View:
- Issue:
- Evidence:
- Fix:
- Verification:
- Status:

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
