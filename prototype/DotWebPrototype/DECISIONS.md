# Prototype decisions

Question: can dot become a monochrome, Apple-native medication logger without losing the single-dot identity?

Current default: **A — Focus dot**. It preserves the brand idea while giving the visible dot an 88px interactive target and an explicit “Log a dose” label.

Validated in the prototype:

- 12-hour and 24-hour time formats update the visible clock and log-confirmation time.
- A single sun/moon icon in the header switches light and dark appearance; the full appearance choice remains in Settings.
- The `dot by latte` lockup appears only in the launch animation, leaving the working screens product-first.
- Status is neutral by default. Only danger is colour-coded, using a red border plus the warning symbol; green/amber labels and per-row status pills are intentionally omitted.
- Dot is the default Home action. Direct action remains available as a Settings preference rather than an on-screen A/B prototype control.
- The ambiguous “Ready to log” state has been replaced by an explicit “Log dose now” action and confirmation.
- “Max per 24h” is expressed as a rolling 24-hour window.
- “Safe now” has been replaced with “Within your limits,” alongside the user-entered-limits disclaimer.
- Add-medication and status updates work in memory; no persistence is included.

Open decision: decide whether Direct action should remain as a user preference after testing the default Dot interaction.
