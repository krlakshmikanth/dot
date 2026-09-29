# dot

<p align="center">
  <img src="DotApp/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="96" height="96" alt="dot app icon">
</p>

**A simple, proactive, local-first medication dose planner and logger for iPhone.**

dot helps individuals and families record medicine doses and stay aware of the limits they entered. It keeps profiles, medicines, limits, and dose history on the device using SwiftData.

> [!IMPORTANT]
> dot is not a dosing authority, drug database, interaction checker, clinical record, or medical device. It does not tell you whether taking a medicine is safe. Statuses are calculated only from limits entered by the user; always follow the medicine label and advice from a qualified clinician or pharmacist.

## Features

- See confirmed doses, uncertainty and a pending plan together on the Day map.
- Plan a dose before taking it, then explicitly confirm what happened.
- Keep planned doses out of dose history until they are confirmed as taken.
- Keep medicines and history separated across local profiles.
- Count doses in a rolling 24-hour window.
- Show the remaining time in a user-entered minimum gap.
- Highlight when a user-entered maximum has been reached.
- Correct a dose amount or time, resolve an uncertain record, or remove a mistaken entry.
- Add, edit, archive and restore medicines without rewriting historical dose snapshots.
- Record a dose that was already taken at its actual time.
- Follow the system time format, Dynamic Type, VoiceOver, and Reduce Motion settings.
- Choose light, dark, or system appearance.

## Privacy

The current app has no account, backend, analytics, advertising SDK, or cloud sync. App data remains in the local SwiftData store. Profile age and the optional Medical ID are sensitive local data and must not be added to logs, analytics, notifications, screenshots, or exports.

## Requirements

- macOS with a current version of Xcode capable of targeting iOS 17 or later
- iOS 17 or later

The project has no third-party package dependencies. Selected medicine, calendar, uncertainty and warning artwork comes from [Health Icons](https://healthicons.org/) under CC0.

## Getting started

```sh
git clone <repository-url>
cd dot
open Dot.xcodeproj
```

Select the `dot` scheme and an iPhone simulator, then run the app. Simulator builds do not require an Apple Developer team. For a physical device, select your own team in Xcode; the repository intentionally does not commit a team identifier or provisioning profile.

## Testing

Run the `dot` scheme's tests in Xcode, or choose an installed simulator and run:

```sh
xcodebuild \
  -project Dot.xcodeproj \
  -scheme dot \
  -destination 'platform=iOS Simulator,name=<simulator name>' \
  test
```

The test suite covers rolling-window boundaries, configured maximums, minimum-gap calculations, invalid configurations, form validation, and the plan, confirm, history, dose-editing, and medicine-editing journey.

## Project layout

- `DotApp/` — production SwiftUI and SwiftData app
- `DotAppTests/` — unit tests
- `DotAppUITests/` — core journey UI tests
- `designs/` — approved design handoff and historical screen explorations
- `prototype/` — native and web interaction references
- `DEVELOPMENT.md` — engineering boundaries and release checks

## Contributing

Issues and pull requests are welcome. Please preserve the local-first privacy model and the core safety boundary: dot may evaluate limits explicitly entered by the user, but it must not infer doses, provide clinical recommendations, or imply that taking a medicine is safe.

Before submitting a change, run the tests and check the main flow in light and dark mode with accessibility settings enabled.

## License

dot is available under the [MIT License](LICENSE).
