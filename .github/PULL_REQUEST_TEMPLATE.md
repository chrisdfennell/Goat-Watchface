<!-- Thanks for contributing to Goat Face! -->

## Description

<!-- What does this PR change and why? Link any related issue, e.g. "Closes #12". -->

## Type of change

- [ ] Bug fix
- [ ] New feature (new indicator, doodle, paper style, etc.)
- [ ] Layout / readability improvement
- [ ] New device support
- [ ] Art / font assets
- [ ] Documentation
- [ ] Other:

## Devices tested

<!-- Please cover at least one AMOLED and one MIP panel. -->

- [ ] `fenix847mm` (454×454 AMOLED)
- [ ] `fr255` (260×260 MIP)

## Checklist

- [ ] `.\build.ps1 -Device <device>` compiles with no warnings
- [ ] Verified in the simulator in both active and Always-On / low-power modes
- [ ] Weather, heart rate, and Body Battery render from live data and hide
      cleanly when a value is unavailable
- [ ] Text baselines still sit on the notebook rules, with no clipping at the
      round edge
- [ ] Re-ran `python tools/gen_fonts.py` if any font size/glyph changed
- [ ] Updated `CHANGELOG.md` if this is a user-facing change

## Screenshots

<!-- Before/after simulator screenshots for any visual change (see savescreenshot.ps1). -->
