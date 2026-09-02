# AGENTS.md — Dot (iOS)

This file is the handoff brief for whichever coding agent (or engineer) builds this app next. This repo was just initialized from design assets and product context gathered elsewhere — **there is no code in this repo yet.** Read this file and `designs/design-handoff.md` before writing anything.

## What this project is

**Dot** — previously called "Dot Matrix" and "Latte Dot" (all three names refer to the same product; the copy in the current design export still says "Dot Matrix," the current product name is "Dot"). A simple iOS app centered on medication dosage safety: log a dose, and the app tells you when it's safe to take the next one and whether you've hit today's limit.

Product framing, verbatim from the design's own copy: *"Use the numbers from the pharmacist label or the packet — Dot only checks the limits you set here."* This is a **personal safety utility, not a clinical/EHR system** — it does not carry its own drug database or dosing authority. It stores whatever limits the user enters and checks against those. Keep this framing intact in any copy, onboarding, or validation logic added later — don't quietly turn it into something that implies clinical guidance.

### Where it fits in the wider product

- Built by **Latte Labs** / **Latte Health Ltd**, a UK company whose core product is an AI medical scribe / teleconsulting platform for the UK healthcare market (NHS-facing, MHRA/DTAC/DSPT compliance, partner-led GTM, competing with Heidi Health / Tortus).
- Dot is a separate, lightweight, **consumer/family-facing companion app**, not a rebuild of the scribe product and not the practitioner-oversight side of the business — those are different surfaces. Don't pull in scribe-platform architecture or assumptions.
- The "Me / Son" profile switcher in the Status screen confirms family/dependent tracking (e.g. a parent tracking a child's or elderly relative's medication alongside their own) is core, not an edge case.

## Design source

- `designs/screens/*.png` — 4 exported screens (Home/category picker, medication picker, Add Medication sheet, Status+Settings).
- `designs/design-handoff.md` — full screen-by-screen spec: layout, sampled color tokens, states, interactions, and **explicit open questions/edge cases the screens don't answer**. Read it fully before implementing any screen; it calls out several things that need a decision (empty states, the log-commit trigger on the medication-picker sheet, dark mode, background-theming consistency) rather than guessing them.
- No Figma file or design-tool connector was available when this handoff was written — colors in the spec were sampled from the PNG pixels directly, so they're close approximations, not certified tokens. Re-derive/confirm exact values if a Figma source turns up later.

## Suggested technical approach (recommendation, not a locked decision)

No tech stack was specified for this app anywhere in the source material, so treat the following as a sensible default to start from, not a constraint to defend:

- **SwiftUI, native iOS**, targeting a recent iOS version (17+) — the brief is explicitly "a simple iOS app," the screens are pure native-iOS patterns (sheets, segmented controls, steppers, tab bar), and there's no indication of a cross-platform or backend requirement.
- **Local-first storage** (SwiftData or Core Data) — nothing in the design implies a server, login, or sync; dose logging and limit-checking can run entirely on-device. Multi-profile ("Me / Son") is local family-member records, not multi-user accounts, unless the next agent learns otherwise.
- **No backend/auth for MVP.** If cloud sync across a user's own devices or sharing with a practitioner becomes a requirement later, that's a deliberate scope expansion — flag it rather than building toward it speculatively.

## Data model, inferred from the screens

```
Profile
  id, name, avatarInitial, avatarColor

Medication (belongs to a Profile)
  id, name, doseAmount, doseUnit (mg | ml | tab)
  maxPerDay (Int)          // "Max per 24h" stepper
  minimumGapHours (Double) // "Minimum gap" stepper

DoseLog (belongs to a Medication)
  id, timestamp
```

Derived (not stored) status per medication, per `designs/design-handoff.md`'s worked example:
```
timeSinceLast = now - mostRecentDoseLog.timestamp
dosesToday    = count(DoseLog where timestamp is today)

if timeSinceLast < minimumGapHours:
    status = "Wait {minimumGapHours - timeSinceLast, rounded up to nearest hour}"
elif dosesToday >= maxPerDay:
    status = "Limit reached"
else:
    status = "Safe now"
```
Confirm the rounding rule and the precedence (gap-check before limit-check) with the user before shipping — it's backed out from one example, not specified directly.

## Non-goals (explicit, don't build toward these without a new decision)

- Not a clinical dosing database or drug-interaction checker.
- Not the practitioner/EHR side of Latte Health.
- Not cloud-synced or multi-device for MVP.
- Food and Exercise logging exist as picker options in the design but have **no designed screens** — don't invent flows for them; either stub them as "coming soon" or ask before designing.

## Open questions to resolve before/while building

These are called out in detail in `designs/design-handoff.md`; summarized here:
1. What happens on first launch / with zero medications saved (empty states throughout)?
2. What actually commits a log entry on the medication-picker sheet (screen 2) — the "Ready to log" pill implies a two-step flow whose second step isn't in the export?
3. Is Settings really inline on the Status tab permanently, or is that a scrolled/merged screenshot artifact given the tab bar has a separate Settings icon?
4. Dark mode and a colour-blind-friendly palette are settings in the UI but have no corresponding designed screens.
5. Editing/deleting an existing medication isn't designed (only "Add").

## How this repo was set up

This repo was initialized from a design-only project folder (4 PNG exports, no prior code) plus product context pulled from prior conversations about Latte Health / Dot. It was set up for migration to a different coding agent — there is no existing app target, Xcode project, or CI in here yet. Start by scaffolding a new iOS app project, then build against `designs/design-handoff.md` screen by screen.
