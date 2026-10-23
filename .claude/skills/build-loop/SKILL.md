---
name: build-loop
description: Build, flash and test loop for this exynos-linux device port (kernel, drivers, device package, Duranium images). Use before starting any build, for any kernel/driver/package/image change, and when builds are slow.
---

# Build and test loop

Read `docs/AGENT-HANDOFF.md`, `docs/STATUS.md` and `config.toml` first.

## 1. Drivers: in the bring-up Linux, live

- Change the driver in `src/linux` (topic branch, merged into the
  integration branch the device runs).
- Rebuild only that module (`make -C src/linux ARCH=arm64
  CROSS_COMPILE=aarch64-linux-gnu- O=$PWD/build/bringup M=drivers/<dir>
  modules`), upload it over the USB console (`put`), `rmmod`/`insmod`, read
  `dmesg`. Seconds, no reflash.
- A whole bring-up kernel only when a module swap cannot test it; it must
  come back to the console or Download mode on its own.

## 2. Packages and images: cached, like CI

- `scripts/kernel-export <branch> <base>` after the kernel tested well, then
  `scripts/build-image --ui <ui> --channel dev`. The kernel builds through
  the persistent ccache in `build/work/ccache` (never delete it).
- Device package change: bump `pkgrel`, `scripts/aport-checksum <dir>`.
- `FRESH=1` refreshes the cached repository metadata; otherwise builds run
  offline from the cache.

## 3. Deliver: A/B update, never a reinstall

- A set-up device gets the new image as an A/B update (the installer's
  `./setup.sh update --test <dir> <version>` for local builds, or the dev
  channel after CI published). Its root and the owner's data stay.
- Boot counting keeps the previous version as the fallback; check the new
  one booted and was blessed.

## 4. Test and record

- `docs/TESTPLAN.md`; results in `logs/test-runs/<date>-<what>/`, state in
  `docs/STATUS.md` (only a Duranium ✔ is done), `docs/AGENT-HANDOFF.md`
  updated before you stop.
- Passed on the device and worth releasing: `scripts/pmos-verify`, commit,
  push.
