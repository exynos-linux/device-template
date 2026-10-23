# Test plan

Every change that reaches a release channel passed these on the device,
on exactly the exported trees (`scripts/pmos-verify`). Record each run in
`logs/test-runs/<date>-<what>/results.tsv` (not committed) and the outcome
in `docs/STATUS.md`.

## Before any boot test

- [ ] The test can come back without a human: to the USB console, to the
      previous version (boot counting) or to Download mode
- [ ] A way to tell it failed (console, journal, a marker) is in place
- [ ] Nothing in it writes a protected partition (`installer.protected`)

## Boot and updates

| # | Test | Pass when |
|---|---|---|
| B1 | Fresh install with `./setup.sh` on a device running stock Android | Duranium boots, first-boot repart creates the root, the UI starts |
| B2 | `./setup.sh undo` from the live stage | Android boots exactly as before |
| B3 | A/B update from the dev channel (`updatectl update`) | new version boots, is blessed, the old one stays as fallback |
| B4 | A broken update (a version that does not boot) | boot counting falls back to the previous version by itself |
| B5 | Interrupted download | the slot is vacuumed and the next update succeeds |
| B6 | Release image | no debug layer (`ci/check-image` and on the device) |

## Hardware (per row of docs/STATUS.md)

| # | Block | Pass when |
|---|---|---|
| H1 | Display, backlight | the UI on the GPU, the slider changes brightness |
| H2 | Touch, pen | drags without lost frames, pen hover and pressure |
| H3 | Wi-Fi, Bluetooth | connect, transfer, pair |
| H4 | Audio | speaker, jack, mic capture |
| H5 | Charging, battery | charges, capacity and temperature plausible |
| H6 | Suspend | sleeps, wakes by power key and RTC, the USB console returns |
| H7 | Cameras | front and rear in the camera app |

## Physical actions

Some tests need a person: pressing keys, unplugging, looking at the
screen. Ask for exactly one action at a time, say what to look for, and
never leave the device in a state only a person can recover from without
saying so first.
