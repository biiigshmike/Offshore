# Accessibility Audit

## Semantics
- [ ] Interactive elements expose appropriate roles.
- [ ] Decorative content is hidden from assistive technologies.
- [ ] Grouped content is combined when it reads better as a single element.

## Labels & Hints
- [ ] Buttons and icons have clear, specific labels.
- [ ] Hints are present where the action is not obvious.
- [ ] Values are exposed for rows and summary elements.

## Focus & Navigation
- [ ] Focus order follows visual order.
- [ ] Focus does not land on redundant elements.
- [ ] Modal and sheet focus is contained and dismissible.

## Dynamic Type & Layout
- [ ] Text scales appropriately at larger sizes.
- [ ] Text uses Dynamic Type styles (avoid fixed-size fonts).
- [ ] Content remains readable without truncation at large sizes.
- [ ] Controls remain reachable without overlap.

## Color & Contrast
- [ ] Text meets contrast requirements.
- [ ] Information is not conveyed by color alone.

## Testing
- [ ] VoiceOver pass completed.
- [ ] Switch Control pass completed.
- [ ] Reduced Motion and Increased Contrast verified.

## Phase A Patterns (Home, Budgets, Budget Details)
- Icon-only buttons use `iconButtonA11y(label:hint:)` with specific labels and concise hints.
- Decorative icons/shapes use `hideDecorative()` to avoid duplicate announcements.
- Interactive rows use `accessibilityRow(label:value:hint:)` to combine content into a single element.
- Static multi-line blocks use `combineChildrenForA11y()` or explicit label/value to avoid fragmented focus.
- Charts/gauges provide `accessibilityLabel` and `accessibilityValue` summaries (latest values or top categories).
- Animations respect Reduce Motion by passing `nil` when `accessibilityReduceMotion` is enabled.
