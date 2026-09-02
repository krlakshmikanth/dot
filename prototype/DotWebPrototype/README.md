# dot approved interaction reference

This runnable prototype is the approved interaction and visual reference for building the native app. Keep it in sync with `designs/design-handoff.md` until the native implementation has passed the handoff checklist.

Run from the repository root:

```sh
python3 -m http.server 4173 --directory prototype/DotWebPrototype
```

Open `http://localhost:4173/`.

The Dot interaction is the default Home action. You can choose Direct action from Settings without placing prototype controls on Home.

Status separates doses in the rolling 24-hour Today view from older dose history in Past. The header’s single appearance icon switches instantly between light and dark.
