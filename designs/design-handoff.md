# Approved design handoff — dot

Status: **approved for app implementation**

## Selected Day map update

The later cross-platform prototype selected **Day map** as the only Home hierarchy. This section supersedes the older Dot action, Direct action, and Today/Past shell details below where they conflict.

- Home opens with `Your day, at a glance.` and the confirmed rolling-24-hour count.
- Show a pending plan separately and label it as not recorded as taken.
- Show confirmed and uncertain recent records newest first. Uncertain records are visible but excluded from the confirmed count.
- The primary action is `Plan a dose` or `Finish planned dose` when a plan is pending.
- Planning never creates dose history. Only explicit `I took it` confirmation creates a confirmed record.
- Bottom navigation is Home, History, Settings.
- History lets the user correct amount or time, confirm an uncertain record, remove a mistake, and record an earlier dose.
- Settings lets the user add, edit, archive, and restore medicines. Historical records keep the medicine name, amount, and unit recorded at the time.
- Selected health-related symbols use Health Icons under CC0. Generic navigation and platform controls remain native.

Product: **dot**

Working reference: `prototype/DotWebPrototype/`

The PNG files in `designs/screens/` document an earlier direction. They are retained for history, but this handoff and the working prototype supersede them.

## Design principles

- Quiet, minimal, and Apple-native.
- Black, white, and system neutrals form the interface.
- Red is reserved for danger. Do not use green or amber status coding.
- Use Apple system typography and SF Symbols in the native app.
- Keep the primary task obvious: logging a dose.
- Safety meaning must never depend on colour alone.
- Use plain language and avoid implying clinical dosing advice.

## Brand and launch

- Display the product name as lowercase `dot`.
- The full `dot by latte` lockup appears only on launch, not in page headers.
- Launch animation: scattered monochrome dither particles gather and reveal a bold lowercase `dot`, with a much smaller lowercase `by latte` underneath.
- With Reduce Motion enabled, skip particle travel and use a short static fade.
- App icon/logo direction: lowercase black `dot` lettermark on white. Its animated variant uses the same dither-to-letter reveal as launch.

## Global shell

Header:

- Leading: active profile chip opening the local profile switcher.
- Trailing: one circular appearance icon. Show a moon in light mode and a sun in dark mode. Tapping switches immediately between light and dark without navigating away.

Bottom navigation:

- Home
- History
- Settings

Do not display the brand lockup in the shell.

## Home

- Heading: `Your day, at a glance.`
- Summary: confirmed doses in the rolling 24-hour window and the boundary `Only what this device has recorded`.
- Show a pending plan above the action and label it `NOT RECORDED AS TAKEN`.
- Show uncertain records in the recent timeline but exclude them from the confirmed count.
- Primary action: `Plan a dose`, changing to `Finish planned dose` while a plan is pending.
- Recent records are newest first and open the record editor.

## Plan-dose sheet

1. Present `Choose a medicine`.
2. Show saved active medicines with name and dose.
3. Review the selected person, medicine, entered limits, and confirmed rolling-24-hour record.
4. Block planning when the user-entered maximum has been reached. Display the red warning icon, border, and accessible danger wording.
5. `Plan this dose` creates a pending plan only.
6. `Yes, I took it` converts the pending plan into a confirmed dose record.
7. `I’ll confirm later` preserves the pending plan. `Cancel plan` removes it without adding history.

## History

- Group confirmed and uncertain records by day.
- Open a record to correct its amount or taken time.
- An uncertain record can be explicitly confirmed after review.
- A mistaken or duplicate record can be removed after confirmation.
- `Record an earlier dose` requires the user to confirm it was actually taken.

### Danger token

| Mode | Red |
|---|---|
| Light | `#B42318` |
| Dark | `#FF6961` |

No green or amber status tokens are approved.

## Add medication

The sheet includes:

- Name
- Dose amount
- Unit: mg, ml, or tab
- Maximum doses in a rolling 24-hour window
- Minimum gap in hours
- `Save medication`

Use the pharmacist label or packet as the source. Dot checks the configured values and must not silently add clinical recommendations.

## Settings

### Appearance

- Light
- Dark
- System

The header icon is a quick light/dark switch. The Settings control remains the full preference.

### Accessibility

- Reduce Motion
- Dynamic Type
- VoiceOver labels
- Minimum 44pt interactive targets
- Warning symbol plus accessible danger description; never red alone

## Visual tokens

| Token | Light | Dark |
|---|---|---|
| Background | `#FFFFFF` | `#000000` |
| Foreground | `#000000` | `#FFFFFF` |
| Surface | `#F2F2F7` | `#1C1C1E` |
| Muted text | `#636366` | `#AEAEB2` |
| Neutral border | `#D1D1D6` | `#38383A` |
| Danger | `#B42318` | `#FF6961` |

Native implementation should prefer semantic system colours when they preserve this appearance and contrast.

Typography:

- Apple system font / SF Pro.
- Large page title: approximately 34pt, bold.
- Primary action label: approximately 20pt, semibold.
- Body: 15–17pt.
- Supporting/detail text: 12–13pt.

## Safety logic

For each medication:

1. Collect dose logs in the preceding rolling 24 hours.
2. Compare the count with the user-entered maximum.
3. Compare elapsed time since the latest dose with the user-entered minimum gap.
4. Mark danger when the configured maximum has been reached.
5. Keep non-danger states visually neutral in Status.

Exact precedence and rounding must be covered by unit tests before release. Reject invalid or non-finite configuration values and fail safely when required data is missing.

## App-build acceptance checklist

- [ ] `dot by latte` appears only during launch.
- [ ] Dithered launch and reduced-motion launch both work.
- [ ] Day map is the only Home hierarchy.
- [ ] A pending plan is visibly separate and excluded from dose history.
- [ ] Header icon switches light/dark without routing.
- [ ] 12-hour and 24-hour formats update every displayed timestamp.
- [ ] A dose can be selected, planned, and explicitly confirmed as taken.
- [ ] Home uses a true rolling 24-hour window and excludes uncertain records from its confirmed count.
- [ ] History groups records by day and supports correcting amount or time.
- [ ] Medicines can be edited, archived, and restored without rewriting historical snapshots.
- [ ] Only danger rows use red; no green/amber coding or status legend appears.
- [ ] Danger also has a warning symbol and VoiceOver description.
- [ ] Add-medication validation and rolling-window logic have tests.
- [ ] Light, dark, Dynamic Type, VoiceOver, and Reduce Motion have been checked on device or simulator.

## Running the design reference

From the repository root:

```sh
python3 -m http.server 4175 --directory prototype/DotCrossPlatformPrototype
```

Then open `http://localhost:4175/`.
