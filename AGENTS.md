# AGENTS.md — Dot app build

Read `designs/design-handoff.md` before building the app. The approved interaction design is also runnable in `prototype/DotWebPrototype/`.

## Product

**Dot** is a minimal, local-first iOS medication-dose logger for individuals and families. It checks only the limits entered by the user; it is not a dosing authority, drug database, interaction checker, clinical record, or EHR.

The product name is always **dot** in the interface. The `dot by latte` lockup appears only during launch.

## Current source of truth

Use these in order:

1. `designs/design-handoff.md` — approved visual and behaviour specification.
2. `prototype/DotWebPrototype/` — working interaction reference.
3. `designs/screens/*.png` — historical exploration only. These exports are superseded where they conflict with the approved handoff.

Do not restore the old lavender/teal palette, Home A/B prototype control, green/amber status colours, status pills, or repeated `dot by latte` lockup.

## Recommended app approach

- SwiftUI, targeting iOS 17 or later.
- Apple system typography and SF Symbols.
- SwiftData for profiles, medications, and dose logs.
- Local-first MVP with no backend or account requirement.
- VoiceOver labels, Dynamic Type, Reduce Motion, and minimum 44pt controls.

## Core model

```text
Profile
  id, name, avatarInitial

Medication
  id, profileID, name, doseAmount, doseUnit
  maximumDosesPerRolling24Hours, minimumGapHours

DoseLog
  id, medicationID, timestamp
```

Compute status from dose logs in the preceding rolling 24 hours, not by calendar day. Danger is shown only when a configured limit is reached. The product must continue to say that it checks only user-entered limits.

## Build constraints

- Dot is the default Home action.
- Direct action is an optional Home preference in Settings.
- Today contains the rolling 24-hour view; Past contains older logs.
- Only danger uses colour: red border plus warning symbol. Ordinary/waiting rows stay neutral.
- Never rely on colour alone.
- Light/dark is switchable from the header icon; full appearance options remain in Settings.
- Support both 12-hour and 24-hour time.
- Preserve the dithered launch animation and provide a reduced-motion version.

Before declaring the app complete, test the full flow: launch → log a dose → confirmation → Today status → Past history, in light and dark mode and both time formats.
