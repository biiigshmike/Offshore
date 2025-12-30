Accessibility Audit - Offshore

Audit Plan
1) Inventory all screens and flows (root tabs, sheets, modals, detail views).
2) Implement shared AccessibilityFoundation helpers and reusable patterns.
3) Apply the checklist to every screen, updating controls, labels, ordering, and reduced motion.
4) Validate with Accessibility Inspector and simulator dynamic type.

Testing Workflow
- Accessibility Inspector:
  - Audit each screen using "Audit" and "Live" modes.
  - Verify VoiceOver order, labels, hints, and actions.
  - Toggle Reduce Motion, Differentiate Without Color, and Increased Contrast.
- xcodebuild (adjust destination as needed):
  - `xcodebuild -project Offshore.xcodeproj -scheme OffshoreBudgeting -destination 'platform=iOS Simulator,name=iPhone 15' test`

Screen Inventory
- Root tabs: Home, Budgets, Income, Cards, Settings
- Flows: CloudSyncGateView, OnboardingView, AppLockView, HelpView
- Details: CardDetailView, BudgetDetailsView
- Management: PresetsView, ExpenseCategoryManagerView, EditCategoryCapsView, WorkspaceManagerView, WorkspaceEditorView
- Forms: AddBudgetView, AddPlannedExpenseView, AddUnplannedExpenseView, AddIncomeFormView, IncomeEditorView, AddCardFormView
- Sheets: RenameCardSheet, ManageBudgetCardsSheet, ManageBudgetPresetsSheet, PresetBudgetAssignmentSheet
- Pickers: RecurrencePickerView, CustomRecurrenceEditorView

Checklist Template (apply to every screen)
- [ ] All interactive controls reachable with VoiceOver.
- [ ] Icon-only controls have accessibilityLabel and hint as needed.
- [ ] Decorative images hidden.
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable.
- [ ] Focus order is logical.
- [ ] Dynamic Type: works at Accessibility sizes, no clipped essential content.
- [ ] Tap targets remain usable.
- [ ] Color is not the only differentiator.
- [ ] Contrast is acceptable in light/dark and increased contrast settings.
- [ ] Reduce Motion: avoids problematic motion triggers.
- [ ] Voice Control: labels are unique, speakable, and match UI intent.
- [ ] Keyboard operability (especially on iPad + Catalyst).
- [ ] Charts have an accessible summary and a non-color-only explanation.

Shared Foundation (applies across all screens)
Issues found
- Icon-only controls lacked uniform labeling and hints.
- Swipe actions lacked VoiceOver actions.
- Charts lacked a11y summaries and textual fallback lists.
- Drag reordering lacked VoiceOver move actions.

Fixes applied
- Added AccessibilityFoundation helpers and rules.
- Added `iconButtonA11y`, `hideDecorative`, `combine(children:)`, `chartA11ySummary`, `a11yMoveUpDownActions`.
- Added accessibility actions to UnifiedSwipeActions.
- Added reduce motion handling for MotionMonitor.

Home (HomeView + MetricDetailView)
Issues found
- Icon-only buttons and decorative glyphs in widgets and controls.
- Widget drag reorder lacked VoiceOver move actions.
- Charts lacked accessible summaries and text fallbacks.
- Color-only indicators in category rows and caps.

Fixes applied
- Added icon labels and hints for widget controls and period/date controls.
- Added move up/down accessibility actions for widget reorder and announcements.
- Added chart summaries and per-chart value lists in detail views.
- Added non-color indicators and hid decorative shapes.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs manual validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (implemented).
- [ ] Decorative images hidden (implemented).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (implemented).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (needs manual validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (implemented with text indicators).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (implemented for motion monitor; needs validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (needs manual validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (implemented).

Budgets (BudgetsView)
Issues found
- Icon-only toolbar buttons and search controls lacked explicit labels.
- Decorative chevrons announced by VoiceOver.

Fixes applied
- Added labeled toolbar icons and clear search button labels.
- Hid decorative chevrons and added expand/collapse value/hint.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (implemented).
- [ ] Decorative images hidden (implemented).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (implemented).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (needs manual validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (needs manual validation).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (needs manual validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (needs manual validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (n/a).

Income (IncomeView)
Issues found
- Icon-only calendar navigation and toolbar controls.

Fixes applied
- Added explicit labels to calendar navigation and toolbar actions.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (implemented).
- [ ] Decorative images hidden (n/a).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (needs validation).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (needs manual validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (needs manual validation).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (needs manual validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (needs manual validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (n/a).

Cards (CardsView)
Issues found
- Icon-only toolbar button.

Fixes applied
- Added labeled toolbar icon for add card.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (implemented).
- [ ] Decorative images hidden (n/a).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (implemented).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (needs manual validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (needs manual validation).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (needs manual validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (needs manual validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (n/a).

Settings (SettingsView)
Issues found
- Decorative icons/chevrons announced.
- Permission button and iCloud refresh icon-only cues.

Fixes applied
- Hid decorative icons/chevrons, added accessibility-appropriate labels.
- Ensured button labels are text-first and dynamic type friendly.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (implemented).
- [ ] Decorative images hidden (implemented).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (implemented).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (implemented in key rows; needs validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (needs manual validation).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (needs manual validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (needs manual validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (n/a).

Card Detail (CardDetailView)
Issues found
- Icon-only controls (search, menu, date presets).
- Decorative icons announced.
- Category chips fixed height and color-only selection.

Fixes applied
- Added icon labels/hints and hid decorative glyphs.
- Added differentiate-without-color checkmark for selected chips.
- Relaxed fixed heights to improve Dynamic Type.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (implemented).
- [ ] Decorative images hidden (implemented).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (implemented).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (implemented in chips; needs validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (implemented in chips).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (needs manual validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (implemented where buttons used; needs validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (n/a).

Budget Details (BudgetDetailsView)
Issues found
- Icon-only menu buttons lacked explicit labels/hints.

Fixes applied
- Added labels/hints for add/actions menus.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (implemented).
- [ ] Decorative images hidden (needs validation).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (needs validation).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (needs manual validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (needs manual validation).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (needs manual validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (needs manual validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (n/a).

Presets (PresetsView + PresetRowView)
Issues found
- Icon-only toolbar add button.

Fixes applied
- Added labeled toolbar icon.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (implemented).
- [ ] Decorative images hidden (needs validation).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (implemented).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (needs manual validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (needs manual validation).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (needs manual validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (needs manual validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (n/a).

Expense Categories (ExpenseCategoryManagerView + Editor)
Issues found
- Icon-only add button and non-button row tap targets.
- Decorative chevrons announced.

Fixes applied
- Added icon labels and converted row taps to buttons.
- Hid decorative chevrons and swatch circles.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (implemented).
- [ ] Decorative images hidden (implemented).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (implemented).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (needs manual validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (implemented via text).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (needs manual validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (implemented via buttons; needs validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (n/a).

Workspace Profiles (WorkspaceMenuButton + Manager/Editor)
Issues found
- Icon-only menu and decorative checkmark.

Fixes applied
- Added icon labels and hid decorative checkmark; added active value.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (implemented).
- [ ] Decorative images hidden (implemented).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (implemented).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (needs manual validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (needs manual validation).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (needs manual validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (implemented via buttons; needs validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (n/a).

Add/Edit Forms (AddPlannedExpenseView, AddUnplannedExpenseView, AddCardFormView, AddIncomeFormView, IncomeEditorView, AddBudgetView)
Issues found
- Category chips used color-only selection and fixed heights.
- Theme swatches used tap gestures instead of buttons.

Fixes applied
- Added differentiate-without-color checkmarks and removed fixed max heights.
- Converted swatches to buttons.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (implemented where applicable).
- [ ] Decorative images hidden (implemented where applicable).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (implemented).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (implemented in chips; needs validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (implemented).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (needs manual validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (implemented via buttons; needs validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (n/a).

Help (HelpView)
Issues found
- Decorative icons/chevrons announced.

Fixes applied
- Hid decorative icons/chevrons and placeholder device glyph.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (n/a).
- [ ] Decorative images hidden (implemented).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (implemented).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (needs manual validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (n/a).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (needs manual validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (needs manual validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (n/a).

App Lock (AppLockView)
Issues found
- No explicit control to retry unlock.

Fixes applied
- Added "Unlock" button with VoiceOver hint.

Checklist
- [ ] All interactive controls reachable with VoiceOver (implemented, needs validation).
- [ ] Icon-only controls have accessibilityLabel and hint as needed (n/a).
- [ ] Decorative images hidden (implemented).
- [ ] Rows/cards have a sensible combined announcement OR child elements are individually navigable (n/a).
- [ ] Focus order is logical (needs manual validation).
- [ ] Dynamic Type: works at Accessibility sizes (needs manual validation).
- [ ] Tap targets remain usable (needs manual validation).
- [ ] Color is not the only differentiator (n/a).
- [ ] Contrast is acceptable in light/dark and increased contrast settings (needs manual validation).
- [ ] Reduce Motion: avoids problematic motion triggers (needs manual validation).
- [ ] Voice Control: labels are unique, speakable, and match UI intent (implemented).
- [ ] Keyboard operability (especially on iPad + Catalyst) (needs manual validation).
- [ ] Charts have an accessible summary and a non-color-only explanation (n/a).
