# Design Handoff: Dot (formerly "Dot Matrix" / "Latte Dot")

Source: 4 exported screens in `designs/screens/` (home, medication picker, add-medication sheet, status/settings). No Figma file is connected — colors below were sampled directly from the PNG pixels, so treat them as close approximations of the real tokens, not certified values.

## Overview

Dot is a minimal iOS app for tracking medication doses safely — built around a single tappable dot on the home screen rather than a list-first or form-first UI. It's a personal/family safety utility (dose-limit and dose-gap checking), not a clinical record. It's part of the Latte Health product family ("Dot by Latte Labs"); Latte Health's core product is an AI medical scribe / teleconsulting platform for the UK healthcare market, and Dot is a separate, lightweight, patient-facing companion, not a rebuild of the scribe product.

Core interaction loop:
1. Tap the dot → "What are you logging?" (Medication / Food / Exercise)
2. Pick a category → pick a specific item
3. Log it → see a live safety status per medication (Safe now / Wait Xh / Limit reached) on the Status tab

Only the Medication path is designed in these screens; Food and Exercise are present in the picker but undesigned — flag as an open question in AGENTS.md rather than guessing their flows.

## Screens

### 1. Home — Category Picker (`1-home-pick-category.png`)

**What it does**: Default/idle screen. A single dot sits vertically centered-ish on a soft lavender gradient background; tapping it raises a bottom sheet asking what the user is logging.

**Layout**
- Top bar: leading circular avatar chip ("M" initial, filled purple, label "Me" next to it) — this is the active profile switcher, reachable from Home. Trailing: circular settings (gear) icon button.
- Center: a small solid white/off-white dot (~14–16pt diameter) with a soft glow/shadow, roughly at 45% of screen height. This is the primary tap target that launches the logging flow.
- Bottom sheet (appears on tap, shown already open in this export): rounded-top card, off-white, containing:
  - Label "What are you logging?" (small, muted, uppercase-weight but sentence case)
  - Three pill buttons in a row: **Medication** (primary/selected — solid teal, white bold text), **Food**, **Exercise** (both unselected — light gray pill, dark text)
- Bottom tab bar: Home (active, filled dot icon, teal), Status (outline checkbox icon), Settings (gear icon) — all with labels.

**Design tokens observed**
| Token | Sampled value | Usage |
|---|---|---|
| `bg-gradient-top` | `#DBD2F2` | Home background, top |
| `bg-gradient-bottom` | `#EAE9F4` | Home background, bottom |
| `color-primary` (teal) | `#4F9CA3`–`#569FA6` | Selected pill, active tab icon |
| `surface-neutral` | `#E3E2E1` | Unselected pill background |
| `avatar-purple` | `#8C79B5`–`#907EB7` | Profile avatar fill |
| `dot-idle` | near-white `#FCFCFB` with soft outer glow | Home dot |
| `sheet-bg` | `#DBD8E8` (tinted, matches page bg family) | Bottom sheet surface |

**States / interactions**
- Dot: idle (shown) → pressed (no pressed state captured — spec as a scale-down + haptic tap, standard iOS pattern) → sheet presents.
- Pill row: single-select, tapping a pill should immediately either (a) advance to the next step for that category, or (b) become the "armed" category, based on what screen 2 shows (screen 2 already reflects Medication selected and has moved to a "Choose one" step), so treat pill tap as immediate navigation, not a staged select-then-confirm.
- Sheet dismiss: not shown — spec swipe-down-to-dismiss and tap-outside-to-dismiss as standard iOS sheet behavior, returning to idle Home.

**Edge cases to define with the next agent** (not resolved by the screens): what happens on first launch with zero medications saved — does tapping Medication go straight to "Add medication" instead of an empty picker?

---

### 2. Medication Picker — "Choose one" (`2-home-pick-medicine.png`)

**What it does**: After choosing "Medication," the same bottom-sheet pattern updates in place to show the saved medications as selectable chips, with a breadcrumb ("Medication › Choose one") replacing the earlier "What are you logging?" label.

**Layout**
- Background shifts to a cooler mint/aqua gradient (`#F9F8F5` near top fading toward a pale aqua) — background tint appears to shift per top-level category (lavender for the picker step, mint-ish once Medication is engaged); confirm this is intentional theming, not a screenshot artifact, before building it as a rule.
- Top status pill (dark, floating, pill-shaped, centered near the top): checkmark icon + **"Ready to log · 14:32"** — a persistent confirmation chip showing the current time and that a log is staged, in `#37393C` bg with white text.
- Same idle dot, same position, still visible under the sheet.
- Sheet: breadcrumb row ("Medication" muted gray + "›" + "Choose one" bold black), then a horizontally-scrollable chip row of saved medications, e.g. **Paracetamol 500mg ✓** (selected, teal fill `#569FA6`, checkmark), **Metformin 500...** (next chip, partially visible, unselected/gray) — confirms the row scrolls horizontally rather than wrapping.
- Same bottom tab bar (Home still active — user hasn't left the Home tab, this is all sheet-driven).

**States / interactions**
- Chip select: tapping a medication chip marks it selected (checkmark + teal fill) and should update the "Ready to log" pill's timestamp/state.
- The top pill implies logging is a two-step commit: select medication → some confirm action (not shown in these 4 screens — likely a tap on the dot again, or a confirm button that scrolls into view). **Flag this as an unresolved interaction** — the actual "commit the log entry" trigger isn't captured in the export and needs to be confirmed with the user or reasonably assumed (e.g., tapping the dot a second time commits the currently-selected item).

**Edge cases**
- Empty state (no medications saved yet): should route to "Add medication" (screen 3) instead of showing an empty chip row — same open question as screen 1.
- Long medication names / doses: chip text is already getting truncated ("Metformin 500...") at the edge of the visible sheet — confirm truncation vs. wrap behavior, and whether the row auto-scrolls to reveal full chip.

---

### 3. Add Medication (`3-add-medication.png`)

**What it does**: A modal sheet (full drag-handle at top, "Cancel" / title / no trailing action) for defining a medication and its safety limits — this is the form that produces the chips seen in screen 2 and the cards in screen 4.

**Layout, top to bottom**
- Grab handle, then header row: "Cancel" (teal text, leading) — "Add medication" (bold, centered) — no trailing button.
- Subhead copy (muted gray, two lines): *"Use the numbers from the pharmacist label or the packet — Dot Matrix only checks the limits you set here."* — important product-positioning line: the app explicitly disclaims clinical authority; it only enforces whatever limits the user enters. Carry this copy (updating "Dot Matrix" → "Dot" if the rename is finalized) into the built app verbatim; it's doing real liability/expectation-setting work.
- "QUICK START" section label (small caps, muted), then 3 preset cards in a row: **Paracetamol / 500 mg tablet** (selected — pale teal fill `#C8EAEC`, teal border), **Ibuprofen / 200 mg tablet** (unselected, white/outline), **+ Custom** (dashed border, outline-only, "+" icon) — tapping a preset presumably pre-fills the fields below; Custom presumably clears them for manual entry.
- Form list (grouped, inset, white rows on `#F6F5F3`/`#E7E7E3` list background), each row is a label-left / control-right pattern:
  - **Name** — text value "Paracetamol" (read-only display in this export; confirm if it's an editable text field)
  - **Dose amount** — numeric value "500" + a 3-way segmented control **mg / ml / tab** (mg selected)
  - **Max per 24h** — stepper: minus button / value "4" / plus button
  - **Minimum gap** — stepper: minus button / value "4 hrs" / plus button
- Primary CTA, pinned near bottom (not sticky-bottom in this export — sits directly under the form with a lot of empty space below, so likely this sheet is taller than content and the button floats mid-sheet, or the button is meant to dock to the keyboard/safe-area bottom): **"Save medication"** — solid teal `#4F9CA3` fill, white bold text, full-width rounded pill/rounded-rect.

**Design tokens observed**
| Token | Sampled value | Usage |
|---|---|---|
| `surface-sheet` | `#FCFCFB` | Modal background |
| `chip-selected-bg` | `#C8EAEC` | Selected quick-start preset |
| `list-row-bg` | `#F6F5F3` | Grouped form rows |
| `stepper-bg` | `#E7E7E3` | Stepper track |
| `cta-primary` | `#4F9CA3` | Save medication button |

**States / interactions**
- Quick-start card: single-select, 3 states (selected / unselected / Custom-outline). Selecting a preset should populate Name/Dose amount/unit; selecting Custom should clear Name and put focus in it.
- Segmented control (mg/ml/tab): standard 3-way exclusive select.
- Steppers: standard −/value/+ ; needs min/max bounds defined (e.g. Max per 24h shouldn't go below 1 or above some sane ceiling; Minimum gap likely in whole-hour increments here but confirm whether half-hour steps are needed for real-world dosing schedules).
- Save button: no disabled/error state captured — spec one (e.g. disabled/greyed until Name + Dose amount are non-empty).

**Edge cases**
- Validation isn't shown anywhere: what happens if Max per 24h × Dose amount would exceed a known safe daily maximum (this is exactly the kind of thing worth double-checking with the user before building, since it's a health-adjacent safety feature)? The current copy explicitly says the app "only checks the limits you set here" — i.e., no built-in clinical dosing database — so this is likely intentional, but confirm before adding any hidden validation logic.
- Edit vs. add: this screen is captured only in "add" mode; an edit-existing-medication path (and a delete path) will be needed but isn't designed.

---

### 4. Status (`4-status.png`)

**What it does**: The Status tab — the dashboard view. Combines (a) a multi-profile switcher, (b) today's per-medication safety status, and (c) app settings, all on one scrollable screen in this export. Confirm with the user whether Settings is meant to live inline here permanently, or whether this export is showing Status-tab-scrolled-down-into-Settings-tab content merged by mistake (the bottom tab bar has separate Status and Settings icons, which would be redundant if Settings is already inline on Status).

**Layout, top to bottom**
- Large "Status" page title (bold, left-aligned, big).
- Profile row: circular avatars — **Me** (selected, filled purple `#8C79B5`, initial "M", label bold black), **Son** (unselected, filled gray `#717376`, initial "S", label muted gray), **+ Add** (dashed outline circle, "+" icon, "Add" label) — confirms multi-profile / family support is core to the product, matching the "Me / Son" pattern the user has already described for this product line (patient self-tracking with room for dependents).
- "TODAY" section label (small caps, muted).
- Medication cards list, one row per medication, each showing: name + dose (bold, e.g. "Metformin 500mg"), a status subline ("Last taken 6h ago" / "4 of 4 doses today"), and a right-aligned status pill:
  - **Safe now** — pale mint pill `#C8EAEC`, teal text
  - **Wait 1h** — peach pill `#FFE1C9`, orange/brown text
  - **Limit reached** — deeper terracotta pill (~`#CF885D` family — resample against a clean fill area before locking this token, the sampled point may have caught pill text/border), darker text
- **"+ Add medication"** — dashed-outline full-width row, same pattern as the Custom quick-start card, opens screen 3.
- "SETTINGS" section label, then:
  - **Appearance** row — 3-way segmented control **Light / Dark / System** (System selected)
  - **Colour-blind friendly** row — toggle switch (off in this export)
- Bottom tab bar: Home, **Status (active)**, Settings.

**Business rule inferred from the sample data** (important — this is the actual dosing-safety algorithm, back it out and confirm with the user rather than re-deriving it differently):
- Metformin 500mg, last taken 6h ago → **Safe now**
- Paracetamol 500mg, last taken 3h ago, configured minimum gap 4h (per screen 3's default) → **Wait 1h** (4h gap − 3h elapsed = 1h remaining)
- Ibuprofen 200mg, 4 of 4 doses today (max per 24h = 4) → **Limit reached**

So status = `min-gap-not-yet-elapsed ? "Wait {remaining}" : (doses-today >= max-per-24h ? "Limit reached" : "Safe now")` — with min-gap apparently taking precedence for display when both could theoretically apply. Confirm precedence and rounding rules (is "Wait 1h" floor, ceiling, or rounded?) before implementing.

**Design tokens observed**
| Token | Sampled value | Usage |
|---|---|---|
| `status-safe-bg` | `#C8EAEC` | "Safe now" pill |
| `status-wait-bg` | `#FFE1C9` | "Wait Xh" pill |
| `status-limit-bg` | `#CF885D` (verify) | "Limit reached" pill |
| `page-bg` | `#FCFCFB` | Status tab background (flat, not gradient — unlike Home) |
| `avatar-active` | `#8C79B5` | Selected profile avatar |
| `avatar-inactive` | `#717376` | Unselected profile avatar |

**Edge cases**
- No medications saved: empty state under "TODAY" isn't designed.
- More than 2 profiles / long profile row: does the avatar row scroll horizontally like the medication-chip row in screen 2, or wrap?
- Long medication names / many doses today ("4 of 4 doses today" vs. a med with 12 max doses): confirm the subline format doesn't need truncation handling.

---

## Cross-screen notes for whoever builds this

- **Background theming is inconsistent across exports** (lavender gradient on Home/picker steps, near-white flat on the Add sheet and Status tab) — decide whether this is a deliberate "in-flow vs. at-rest" visual language or just unfinished polish before treating it as a rule to implement.
- **No dark-mode screens were exported**, even though the Appearance setting offers Dark — the next build needs a dark palette defined from scratch (don't just invert these tokens without checking contrast, especially for the status pills).
- **No typography scale, spacing scale, or icon set was exported as tokens** — the numbers in this doc are estimates from screenshot inspection (System-rounded-looking sans, likely SF Pro / SF Rounded given the pill-heavy, dot-motif visual language) — confirm the actual type family before building.
- **Copy voice**: short, plain-English, safety-literate but non-clinical ("Use the numbers from the pharmacist label," "Dot Matrix only checks the limits you set here") — keep this tone if new copy is added.
