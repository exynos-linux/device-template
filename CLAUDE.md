# Agent guide: @DEVICE_NAME@ port (exynos-linux)

<!-- template:start (scripts/init-device removes this block) -->
This is exynos-linux/device-template itself: the `@TOKENS@` are
placeholders that `scripts/init-device` fills in for a port. Changes here
must stay device-neutral (every value from config.toml); test them with a
scratch port (`scripts/init-device` in a copy).
<!-- template:end -->

postmarketOS Duranium (immutable: systemd, UKI + systemd-boot, A/B
systemd-sysupdate) on the @DEVICE_NAME@ (@MODEL@, @SOC_NAME@), with the
upstream Linux kernel and our drivers. We maintain the kernel, the drivers
and the device packages; the UIs and the rest of the OS come unchanged from
postmarketOS, rebuilt automatically when postmarketOS publishes.

Read first: `docs/AGENT-HANDOFF.md` (current state), `docs/STATUS.md`
(what works, strictly), `docs/PLAN.md` (what comes next),
`docs/STRUCTURE.md` (where everything is), `config.toml` (the port's
public configuration). A new port starts with `/setup` (the `setup`
skill); `/status` reports where the port stands and `/continue` picks up
the next priority from it into the build loop.

## Commands

- `scripts/config check` / `get KEY` / `json` / `channels`: the config
- `scripts/build-image --ui <ui> --channel dev`: a local image, as CI builds it
- `scripts/kernel-export <branch> <base>`: kernel branch -> kernel aport
- `scripts/aport-checksum <aport-dir>`: after editing an aport (and bump pkgrel)
- `python3 -I tests/config/test_config.py`, `bash tests/installer/run.sh`: offline tests
- `./setup.sh doctor` / `status`: the installer's view of this PC and the device
- `scripts/firmware-snapshot`, `scripts/firmware-extract`, `scripts/firmware-decompile`:
  stock firmware facts and reverse engineering, owner's yes first (docs/FIRMWARE.md,
  the `firmware-re` skill); `bash tests/firmware/run.sh`: their offline tests

## Rules

@.claude/rules/device-safety.md
@.claude/rules/config.md
@.claude/rules/builds.md
@.claude/rules/releases.md
@.claude/rules/code.md
@.claude/rules/firmware.md
@.claude/rules/docs.md
