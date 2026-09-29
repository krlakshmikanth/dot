# Prototype decision

Question: Which cross-platform Home hierarchy makes a proactive “plan before taking” habit easiest to understand without creating false medication history?

Status: decided. Day map was selected because people can understand the day and recent dose record at a glance.

Selected direction: Day map is now the only Home hierarchy in the prototype. It presents the rolling 24-hour confirmed count, pending plan, uncertain records and newest dose events together. The plan and confirmation stages remain separate so a planned dose cannot become false history. iOS and Android share the information architecture while using different controls and sheet shapes.

Health-related symbols now use selected local SVGs from Health Icons. Navigation and generic interface actions continue to use simple platform-neutral symbols so the health iconography remains meaningful instead of decorative.

The current prototype now treats dose records as snapshots. Editing a medicine changes future defaults only; it does not rewrite the amount, unit, name or strength displayed for earlier confirmed doses. Every history entry can be corrected or removed as a mistake, and a removed entry can be restored with Undo.

Before production work, decide:

- Whether the confirmation step feels reassuring or burdensome in real use.
- How long an unconfirmed plan should remain visible and when it should expire.
- Whether carers need shared-device or multi-caregiver coordination. This local prototype does not solve that problem.
- Which medicine regimens are out of scope for the simple fixed-dose, maximum and minimum-gap model.
