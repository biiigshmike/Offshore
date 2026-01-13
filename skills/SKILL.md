---
name: dsv2-repeat-only-screen-migration
description: Migrate a SwiftUI screen and its reachable destinations to DesignSystemV2 using repeat-only mechanical tokenization phases (Spacing→Icons→Typography→Colors) plus AccessibilityID centralization, with no layout or accessibility movement and Dynamic Type preserved.
---

# DSv2 Repeat-Only Screen Migration (All Screens)

This skill performs a strict, mechanical DSv2 migration for **one entry screen** at a time, plus its **reachable destinations/sheets**.

It is intentionally conservative: repeated-literal tokenization only, no layout changes, and no accessibility identifier movement.

---

## Inputs (must be stated in the task)

Every run must specify:

- **ENTRY FILE(S):** the primary screen file(s) being migrated
- **SCOPE ALLOWLIST:** additional files permitted *only if directly reachable* from the entry screen (destinations/sheets/components)

If inputs are missing, assume:
- only the entry file is allowed
- and do not expand scope

---

## Global invariants (apply to all phases)

Hard rules:

- Repeat-only replacements (2+ exact matches only) for tokens and modifier-chain extraction
- Mechanical substitutions only
- No layout or view-structure changes
- No modifier reordering
- Do not move, rename, or reattach accessibility identifiers; keep at call sites
- Preserve Dynamic Type (no fixed font sizes; avoid `.system(size:)` unless already scaled and DSv2-equivalent)
- No unrelated formatting churn
- Stop after each phase with a brief summary

If any change violates an invariant, do not make it.

---

## Scope contract (strict)

Allowed edits are limited to:
- ENTRY FILE(S)
- Plus any files in the SCOPE ALLOWLIST that contain views directly reachable from the entry screen

Do not touch any other files.

Exception:
- You may edit `DesignSystemV2/Accessibility/AccessibilityID.swift` to add minimal identifiers needed for this run.

---

# Phase pipeline

Run phases in order. Do not skip forward unless explicitly instructed.

---

## Phase 1A — Spacing

Goal:
Replace repeated numeric spacing literals with DSv2 spacing tokens.

Repeat-only rule:
- Replace numeric spacing values that appear 2+ times exactly (same literal)
- Replace exact repeated modifier sequences only if they repeat 2+ times
- Leave single-use values unchanged

Scan for:
- `.padding(...)`
- Stack spacing: `VStack/HStack/LazyVGrid(spacing:)`
- `.frame(width/height/min/max:)`
- `.offset(x:/y:)`
- Corner radius only if acting like repeated container spacing and aligned to DSv2 strategy

Replacement rules:
- Prefer existing DSv2 spacing APIs used by the project (match naming exactly)
- If no 1:1 token exists, leave unchanged
- Do not invent tokens

Allowed helper:
- One tiny file-local constant only if needed to replace repeated literals

Output:
- Patch/diff only
- Stop with 2–4 bullet summary

---

## Phase 1B — Icons

Goal:
Replace repeated SF Symbol identifiers with DSv2 icon tokens.

Repeat-only rule:
- Only replace icon identifiers used 2+ times exactly
- Leave single-use icons unchanged

Scan for:
- `Image(systemName:)`
- `Label(..., systemImage:)`
- equivalent patterns

Replacement rules:
- Prefer existing DSv2 icon token API
- Keep call-site structure intact
- Do not invent token names

Allowed helper:
- One file-private icon constant grouping only if DSv2 tokens are unavailable

Output:
- Patch/diff only
- Stop with 2–4 bullet summary

---

## Phase 1C — Typography

Goal:
Replace repeated inline font declarations with DSv2 typography tokens.

Repeat-only rule:
- Only replace inline fonts that repeat 2+ times exactly
- Leave single-use fonts unchanged
- Do not refactor existing font constants unless replacing repeated literals

Dynamic Type rule (hard):
- Do not introduce fixed font sizes
- Prefer DSv2 tokens that map to text styles / scalable typography

Replacement rules:
- Prefer existing DSv2 typography API
- Mapping must be 1:1; if unclear, do not change

Output:
- Patch/diff only
- Stop with 2–4 bullet summary

---

## Phase 1D — Colors

Goal:
Replace repeated color usage with DSv2 color tokens.

Repeat-only rule:
- Replace colors that repeat 2+ times exactly
- Leave single-use colors unchanged

Do not touch:
- Theme-derived colors or appearance-store outputs unless there is an established DSv2-safe mapping pattern already in use

Replacement rules:
- Prefer existing DSv2 color token API
- Preserve semantic meaning (primary vs secondary)
- Do not invent tokens

Output:
- Patch/diff only
- Stop with 2–4 bullet summary

---

## Phase 1E — Accessibility IDs

Goal:
Centralize existing accessibility identifiers into `AccessibilityID.<Feature>` while keeping identifiers at the same call sites.

Rules:
- Replace `.accessibilityIdentifier("...")` string literals with constants/functions in AccessibilityID
- Underlying string values must remain identical
- Do not introduce new identifiers unless they already exist as literals in-scope
- For dynamic IDs, add helper functions mirroring existing patterns (safe fallback for missing UUID)

Allowed file:
- `DesignSystemV2/Accessibility/AccessibilityID.swift` (minimal additions only)

Output:
- Patch/diff only
- Stop with 2–4 bullet summary

---

# Optional later phases (only when explicitly requested)

## Phase 2F — Buttons / ToolbarButtons

- Extract only exact repeated button modifier chains/styles
- Prefer DSv2 ButtonStyle/ToolbarButton helpers if they exist
- No tap-target or role changes
- No identifier movement
- Stop after patch + brief summary

## Phase 2G — RowStyles / Reusable elements

- Only extract exact repeated row modifier sequences
- Create minimal DSv2 helper only if repetition exists
- No layout changes; stop after patch + summary

---

## End-of-phase checklist (always)

- Scope respected (no extra files changed)
- No layout/hierarchy changes
- Modifier order preserved
- Accessibility identifiers unchanged and still attached to same views
- No fixed font sizes introduced; Dynamic Type preserved