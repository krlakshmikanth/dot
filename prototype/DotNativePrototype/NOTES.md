# dot native prototype

PROTOTYPE — throw this away after the product decisions are absorbed into the iOS app.

Question: can a monochrome, Apple-native version of dot make the dose-logging action explicit while preserving the single-dot identity?

Three Home variants are included in debug builds:

- A — Focus dot
- B — Direct action
- C — Today first

This source uses real SwiftUI system typography and SF Symbols (`Image(systemName:)`). It requires the full Xcode toolchain. The current machine is pointed at Command Line Tools only, whose SwiftUI SDK is missing the `SwiftUIMacros` plugin, so use the sibling `DotWebPrototype` for the verified runnable flow here.

Decision placeholder: choose a Home variant, then carry only the winning structure into the production SwiftUI target.
