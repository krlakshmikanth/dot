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

Do not restore the old lavender/teal palette, Home A/B prototype control, green/amber status colours, status pills, or repeated `dot by latte` lockup. The selected Day map update at the top of the handoff supersedes the earlier Dot and Direct action Home variants.

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

- Day map is the only Home hierarchy.
- A plan is persisted separately and never counts as a taken dose until explicitly confirmed.
- Home shows the rolling 24-hour record; History contains editable dose records grouped by day.
- Only danger uses colour: red border plus warning symbol. Ordinary/waiting rows stay neutral.
- Never rely on colour alone.
- Light/dark is switchable from the header icon; full appearance options remain in Settings.
- Format every displayed time with the iPhone's current system preference. Do not add an in-app 12/24-hour setting or duplicate the current time in the app header.
- Keep the app icon as a single centred black dot on an opaque white background.
- Preserve the dithered launch animation and provide a reduced-motion version.

Before declaring the app complete, test the full flow: launch → plan a dose → confirm it as taken → Day map → edit the record → History in light and dark mode, and verify times follow the simulator or device setting.

## Production implementation

- Open `Dot.xcodeproj`; production Swift source is under `DotApp/`, unit tests are under `DotAppTests/`, and the core journey test is under `DotAppUITests/`.
- Read `DEVELOPMENT.md` for the verified build command, scope boundary, safety invariants, and release checks.
- Keep `prototype/` as a design reference. Do not move prototype-only state or fake medication data into production.
- `DoseLimitEvaluator` is the single owner of rolling-window and minimum-gap calculations. Views may present its result but must not reimplement it.
- The selected profile ID persists in app preferences. Medicines and dose logs must always be filtered through that active profile; never combine family members' data.
- Treat profile age and Medical ID as sensitive local data. Do not log, sync, export, or display the full Medical ID outside the profile editor without an explicit reviewed feature.
- A passing simulator build is not a public-release claim. Device, accessibility, privacy, clinical-safety, signing, and TestFlight checks remain required.
