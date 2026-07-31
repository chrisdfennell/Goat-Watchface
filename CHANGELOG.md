# Changelog

All notable changes to Goat Face are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-07-31

### Added
- Data fields are **labelled** - a dimmed caption above each value (STEPS, HR,
  CAL, BATT, BODY, ALERTS, ACTIVE, and KM/MILES following your unit setting).
- The date now reads **weekday, month and day**, falling back to weekday and
  day on panels too narrow to fit it.
- `tools/check_palette.py`, which asserts the breed colours survive the
  64-colour MIP palette and that the PIL mirror still matches the Monkey C
  source.

### Fixed
- **The face was badly wrong on 64-colour MIP watches** (fenix 5/6,
  vivoactive 3/4, fr245/745/945, marq and friends). Those panels declare a
  fixed palette where every channel snaps to 0x00/0x55/0xAA/0xFF, and the
  colours had been picked without it in mind:
  - chocolate coats quantised to **olive**, and so did the halter's leather -
    so on a Nubian the strap disappeared into the face
  - the daylight sky quantised to **indigo**, the meadow and dusk backdrops to
    **grey**, and slate to **teal**
  - eight of sixteen breeds lost most of their shading, Black Bengal collapsing
    from eight distinct colours to three

  Colours are now chosen so they land on sensible, distinct palette entries -
  nudged the minimum distance needed, and biased to keep the hue's channel
  ordering so a brown picks an orange-brown rather than the numerically nearer
  grey. On a 16-bit AMOLED panel the change is imperceptible.
- The date is drawn with a one-pixel halo, so it stays legible where it crosses
  from a blaze onto the coat.
- The release workflow referenced a container image tag (`9.2.0`) that does not
  exist; pinned to `9.1.0`, the newest published.

## [1.1.0] - 2026-07-31

### Added
- **Six more goats**, for sixteen in all: **Nigerian Dwarf** (chocolate and
  white, the breed's famous blue eyes, wattles, and the short kid face it keeps
  for life), **Oberhasli**, **Valais Blacknose**, **Markhor**, **Golden
  Guernsey** and **Kiko**.
- **Wattles** - the little tassels that hang under a goat's chin - on the
  breeds that carry them, swinging with the beard.
- **Kid proportions**: breeds get a muzzle-length and eye-size dial, so the
  dwarf breeds read as small goats rather than shrunken big ones.
- **Gestures.** The animation is now two layers: an idle layer always running
  (breathing, beard, head rock, cud chewed to a three-beat rhythm) and one
  gesture per five-second bucket that has a *shape* across several seconds -
  an ear flicks hard and settles back, the goat glances aside and the head
  follows a beat later, a head shake, and a full **yawn** with the jaw wide,
  eyes screwed shut and the tongue just showing.
- **An open mouth**, so the yawn and the tongue come out of something.
- **Distance** and **Active minutes** data fields.

### Changed
- The tongue now goes out *and back in* over three seconds rather than
  appearing for one.
- Long pendulous ears are drawn in two bent segments, so they hang in a curve
  and the tip turns outward instead of sticking out like a plank.
- A shadow under the chin gives the muzzle some depth.
- Data fields move in and up on panels under 280px to stay clear of the round
  edge.

### Fixed
- **The goat never blinked.** The animation hash was linear enough that taking
  it modulo a small number walked a short repeating cycle which never hit zero,
  so the blink, the tongue and the ear flicks could not fire at all for the
  first ten minutes of every hour. Replaced with a multiply-shift-xor hash.
- The Valais Blacknose's date was written in white on its white fringe.

## [1.0.0] - 2026-07-30

Initial release. 🐐

### Added
- **A goat's face, drawn procedurally** — skull, jaw, tapering muzzle, ears,
  horns and beard are all Graphics primitives measured in fractions of the
  shorter screen edge, so one source set fills every round panel from 218x218
  to 454x454 with no bitmap art and no per-resolution resource folders.
- **Ten breeds**, each with its own coat, markings, ear style, horn style and
  beard: Nubian, Alpine, Boer, Angora, Pygmy, LaMancha, Toggenburg, Saanen,
  Wild Ibex and Black Bengal. Pick one, or let the face surprise you with a new
  goat every hour or every day.
- **It fidgets every second the screen is awake.** The pose is a pure function
  of the clock, so the goat is caught mid-blink, mid-chew or mid-glance
  whenever you look:
  - blinks, with the odd half-blink
  - ears flick independently, the way they do at a fly
  - the jaw chews cud in bouts rather than constantly
  - the slot pupils glance left and right
  - nostrils flare with the breathing, and the beard sways
  - the tongue comes out every twenty-odd seconds — sometimes a full pink loll,
    sometimes just a flick
  - the head **rocks about the neck** rather than sliding, so it wiggles in
    place
- **The time is stamped on the halter's leather noseband** — a stitched strap
  across the face, set in the largest numeric font that fits the panel. Turn the
  strap off for bare digits with a drop shadow.
- The **date is written across the forehead**, in an ink chosen per breed so it
  reads against that coat (dark on the Boer's white blaze, cream on the
  Nubian's chocolate).
- **Two configurable data fields** flanking the beard: steps, heart rate,
  calories, battery, Body Battery or notifications.
- **Backdrops**: Auto (dawn / daylight / dusk / night by the clock), Meadow,
  Slate or Black.
- **Liveliness** setting — Still, Normal or Frisky — scales the whole animation,
  including off.
- **Burn-in-safe Always-On mode** on AMOLED: a dim outline goat with its slot
  pupils and the time, nudged a few pixels every minute.
- Detail level drops automatically on panels under 300px (no stitching, horn
  ridges or fleece curls) to keep the once-a-second redraw cheap on older MIP
  watches.
- Broad round-watch support: 94 products across eight panel resolutions.
- `tools/goatart.py` mirrors the Monkey C artist in PIL, so `tools/preview.py`
  renders the whole herd without opening the simulator, and the launcher icons
  and store art are drawn from the same geometry as the face itself.
