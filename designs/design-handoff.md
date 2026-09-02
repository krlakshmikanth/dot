# Approved design handoff — dot

Status: **approved for app implementation**

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

- Leading: active profile chip, such as `M · Me`, opening profile status.
- Centre: current time, respecting the selected 12-hour or 24-hour format.
- Trailing: one circular appearance icon. Show a moon in light mode and a sun in dark mode. Tapping switches immediately between light and dark without navigating away.

Bottom navigation:

- Home
- Status
- Settings

Do not display the brand lockup in the shell.

## Home

### Default: Dot action

- A centred 88pt black dot is the primary action.
- A small contrasting centre point preserves the dot-matrix identity.
- Label: `Log a dose`.
- Supporting copy: `Dot checks only the limits you entered.`
- Tapping the dot opens the medication selection sheet.

### Optional: Direct action

Users can select this under **Settings → Home action**. Do not show an A/B or prototype switcher on Home.

- Heading: `Log a dose`.
- Supporting row may show the most recent medication and elapsed time.
- Primary control is a circular black button containing only the SF Symbol `plus`.
- Its accessibility label is `Log a dose`.

Dot action is the default on first launch.

## Log-dose sheet

1. Present `Choose a medicine`.
2. Show saved medications with name and dose.
3. Selecting one enables `Log dose now`.
4. Confirmation view says `Dose logged` and displays the recorded time.
5. Offer `View status`.

The confirmation must say that status is based only on the limits the user entered.

## Status

Status starts with a profile row and a Today/Past segmented control.

### Today

- Heading: `Doses in the rolling 24 hours`.
- Include dose activity from the preceding 24 hours.
- Each medication row contains a neutral icon, medication name and dose, and a concise activity detail.
- Do not show right-aligned status pills or text labels such as `Within your limits`, `Wait 1 hr`, or `Limit reached`.
- Ordinary and waiting rows use the neutral system border.
- Danger rows alone use a red border and red warning triangle.
- Include danger in the VoiceOver description so the meaning does not depend on red.
- Do not show an In limit / Medium / Danger legend.

### Past

- Contains logs older than the current rolling 24-hour window.
- Group entries by day.
- Show time, medication name, and dose.
- Past is history, not a second status dashboard.

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

### Home action

- Dot — default
- Direct action

### Time format

- 12-hour
- 24-hour

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
- [ ] Dot action is the first-launch Home default.
- [ ] Direct action can be selected only from Settings.
- [ ] Header icon switches light/dark without routing.
- [ ] 12-hour and 24-hour formats update every displayed timestamp.
- [ ] A dose can be selected, logged, and confirmed.
- [ ] Today uses a true rolling 24-hour window.
- [ ] Past contains older logs grouped by day.
- [ ] Only danger rows use red; no green/amber coding or status legend appears.
- [ ] Danger also has a warning symbol and VoiceOver description.
- [ ] Add-medication validation and rolling-window logic have tests.
- [ ] Light, dark, Dynamic Type, VoiceOver, and Reduce Motion have been checked on device or simulator.

## Running the design reference

From the repository root:

```sh
python3 -m http.server 4173 --directory prototype/DotWebPrototype
```

Then open `http://localhost:4173/`.
