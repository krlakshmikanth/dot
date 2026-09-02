# Building dot

## Current scope

The first production slice is a local-only iOS 17+ SwiftUI app. It stores profiles, medicines, user-entered limits, and dose logs with SwiftData. It does not require an account or network connection.

Profiles are on-device records, not online accounts. Each profile has a short nickname, age, and optional user-entered Medical ID. The selected profile persists across launches, and its medicines and history stay isolated by profile ID.

Not included yet: notifications, medication databases, interaction checking, cloud sync, widgets, family-profile editing, exports, or App Store distribution. Each needs its own product, privacy, and safety review.

## Open in Xcode

1. Open `Dot.xcodeproj` in the repository root.
2. Select the `dot` scheme.
3. Select an iPhone simulator.
4. Press Run.

This Mac currently has Xcode at `/Applications/Xcode-beta.app`, while the command line still points to Command Line Tools. Either select the Xcode app in **Xcode → Settings → Locations → Command Line Tools**, or run:

```sh
sudo xcode-select --switch /Applications/Xcode-beta.app/Contents/Developer
```

Until that is changed, command-line builds can use:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild \
  -project Dot.xcodeproj \
  -scheme dot \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

## Engineering rules

- Treat `designs/design-handoff.md` as the approved product and visual specification.
- Keep all medication data on-device unless a future feature is explicitly designed and reviewed.
- Never add inferred dose limits, clinical recommendations, drug interactions, or “safe to take” claims.
- Validate stored and entered limits. Invalid configuration must not produce a reassuring status.
- Rolling 24 hours means the inclusive interval from exactly 24 hours before `now` through `now`; future timestamps are excluded.
- Reuse `DoseLimitEvaluator` for every status surface. Do not duplicate safety calculations in views.
- Add unit tests for boundary, rounding, migration, or precedence changes before changing safety behavior.
- Use semantic system colours and SF Symbols. Red is reserved for configured-maximum danger and must always be paired with a symbol and VoiceOver wording.
- Check Dynamic Type, VoiceOver, Reduce Motion, light/dark appearance, and system-selected 12/24-hour formatting for user-facing changes.
- Do not add third-party dependencies without a concrete need and a privacy/maintenance review.
- Do not commit signing identities, provisioning profiles, credentials, or real medication data.
- Treat age and Medical ID as sensitive. Do not place them in logs, analytics, crash metadata, notifications, or screenshots.

## Before release

The simulator build and unit tests are only engineering proof. A release also needs on-device testing, notification behavior if introduced, privacy copy, clinical-safety review of claims and failure states, App Store metadata, signing, and beta feedback through TestFlight.
