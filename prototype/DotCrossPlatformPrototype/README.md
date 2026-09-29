# dot: proactive iOS and Android prototype

Throwaway, browser-based interaction prototype. It does not modify the production SwiftUI app. All medicine details are fictional demo data, no information is persisted, and no clinical calculation is validated here.

## Run

From the repository root:

```sh
python3 -m http.server 4175 --bind 127.0.0.1 --directory prototype/DotCrossPlatformPrototype
```

Open <http://127.0.0.1:4175/>.

## Question

Can dot make the intended behaviour simple enough to become a habit: check the person and recent record, plan a dose before taking it, then confirm what actually happened?

The prototype keeps planning and confirmed history separate. A plan does not count as a taken dose. Confirming “I took it” adds the dose to the rolling 24-hour record. Closing or cancelling a plan never creates false history.

This expanded pass also demonstrates:

- Adding, editing, archiving and restoring medicines while preserving historical dose snapshots.
- Recording an earlier dose with its actual amount, unit and time.
- Correcting an existing dose, including resolving an uncertain record.
- Removing a mistaken or duplicate entry with Undo.
- Switching or adding local profiles with isolated records.
- Optional in-memory reminder design and a UK urgent-help route.
- A first-time setup scenario using `?scenario=new`.

The selected Home is Day map. It keeps the confirmed rolling 24-hour count, uncertain records, pending plan and newest dose events in one scan-friendly view. The external platform control compares the iOS and Android treatments; it is a design-workbench control, not product UI.

Medicine, liquid medicine, uncertainty, warning, calendar and urgent-help symbols use selected SVGs from [Health Icons](https://healthicons.org/). The artwork is CC0. Local copies and provenance are in `assets/healthicons/`.

## Safety boundary

dot displays only the limits entered by the user and doses recorded on this device. It does not suggest a dose, establish that another dose is safe, check ingredients or interactions, or contact a clinician. Real medication wording and escalation links require clinical and regional review before release.
