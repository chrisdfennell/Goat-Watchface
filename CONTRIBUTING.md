# Contributing to Goat Face

Thanks for your interest in improving Goat Face! This is a Garmin Connect IQ watch face that looks like a note teenagers pass to each other in class — lined notebook paper with everything handwritten in different pens — written in [Monkey C](https://developer.garmin.com/connect-iq/monkey-c/). Contributions of all kinds are welcome — bug reports, layout/styling improvements, new indicators, device support, art/font assets, and documentation.

By participating in this project you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## Ways to contribute

- **Report a bug** — open a [bug report](../../issues/new?template=bug_report.yml). Please include your device, firmware version, and the SDK version you used.
- **Request a feature** — open a [feature request](../../issues/new?template=feature_request.yml).
- **Submit a change** — fork, branch, and open a pull request (see below).

## Development setup

### Prerequisites

- [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) **9.1.0+** (install the device profiles you need via the **SDK / Device Manager**).
- **Java 17+** (Java 21 is what `build.ps1` defaults to).
- **PowerShell** (the build script is PowerShell-based).
- **Python 3 + Pillow** — only needed if you regenerate the bitmap fonts (`pip install pillow`, then `python tools/gen_fonts.py`).
- A Connect IQ **developer key** (`developer_key.der`) in the repo root. Generate one with:
  ```powershell
  openssl genrsa -out developer_key.pem 4096
  openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
  ```
  This file is git-ignored and must **never** be committed.

### Build

```powershell
# Compile for a specific device (defaults to fenix847mm / 454x454)
.\build.ps1 -Device fenix847mm

# Compile and launch in the simulator
.\build.ps1 -Device fenix843mm -Run

# Package a store-ready .iq bundle (all products in the manifest)
.\build.ps1 -Export
```

On first run, `build.ps1` writes a `build_config.json` (git-ignored) with your local `JavaHome` and `SdkDir` paths — edit it to match your machine.

## Project layout

- `source/NotebookApp.mc` / `NotebookView.mc` — the app + watch face (all rendering is procedural in `onUpdate`; the paper, doodles, and weather icons are drawn with pen-stroke primitives).
- `resources/` — strings, settings, the base (454) handwriting bitmap fonts (`fonts/`), and the launcher icon.
- `resources-round-416x416/` … `resources-round-218x218/` — per-resolution bitmap font sets, wired up via device `resourcePath` entries in `monkey.jungle`.
- `fonts-src/` — source TTF handwriting fonts; `tools/gen_fonts.py` bakes them into the bitmap fonts for every panel size.

## Testing your changes

Please verify your change on at least an AMOLED and a MIP panel before submitting:

- `fenix847mm` (454×454 AMOLED)
- `fr255` (260×260 MIP, 64 colours)

Things to check in the simulator:

- Layout holds — text baselines sit on the notebook rules, and nothing clips at the round edge (the paper chords narrow near the top and bottom).
- Weather (Simulation → Weather), heart rate, and Body Battery render from live data and **hide cleanly** when unavailable.
- All four settings work (time pen colour, paper style, weather toggle, heart-rate toggle).
- **Always-On / low-power mode** (Settings → toggle sleep) — the dim, burn-in-safe time page still renders and shifts each minute.
- `savescreenshot.ps1` captures a clean, correctly-framed shot.

## Coding guidelines

- Match the existing style in `source/NotebookView.mc`: 4-space indentation, explicit type annotations on method signatures, and `private var` for fields.
- Keep drawing **procedural** — lay out against the 454×454 base grid via the `s()` scaler and the `RULE_SPACING` rules, never hard-coded pixel coordinates, so layouts hold across the supported device range.
- Guard optional APIs with `has` checks (e.g. `SensorHistory has :getBodyBatteryHistory`) and wrap risky calls in `try/catch` so missing data never crashes the face.
- Ink and paper colours are the `C_*` constants at the top of the view; text baselines are placed with `writeOn()` using the per-font ascent ratios (`ASC_*`).
- New user settings go in `resources/settings/` (properties + settings) with a matching label in `resources/strings/strings.xml`, read in `loadSettings()`.
- If you change a font size or glyph set, re-run `python tools/gen_fonts.py` and commit the regenerated `.fnt` / `.png` for **every** resolution folder.

## Pull request process

1. Fork the repo and create a topic branch off `main` (e.g. `feature/tic-tac-toe-doodle` or `fix/weather-icon-clip`).
2. Make your change and confirm it **builds clean** (`.\build.ps1` with no warnings) and runs in the simulator.
3. Fill out the pull request template, including the devices you tested and before/after screenshots for any visual change.
4. Keep PRs focused — one logical change per PR is easier to review.

### Commit messages

Short, imperative summaries are preferred, optionally using [Conventional Commits](https://www.conventionalcommits.org/) prefixes:

```
feat: add a tic-tac-toe doodle that fills in through the day
fix: keep the condition word from touching the time on the 390 panel
docs: document the handwriting font pipeline
```

## Questions

Open a discussion or file an issue. Thanks for contributing!
