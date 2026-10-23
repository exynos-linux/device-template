# Codebase structure

Every exynos-linux device port has this layout. It comes from
[exynos-linux/device-template](https://github.com/exynos-linux/device-template);
keep it, so the plumbing can be merged back and forth between ports.

```
config.toml               the port's public configuration (docs/CONFIG.md)
setup.sh                  installer entry point for users (docs/INSTALL.md)
README.md  LICENSE  CLAUDE.md
.claude/
  rules/                  rules for coding agents, loaded with CLAUDE.md
  skills/build-loop/      the build, flash and test loop, as a skill
  skills/setup/           /setup: a new port: research, starting trees, firmware, the first docs
  skills/firmware-re/     stock firmware facts and reverse engineering
.github/workflows/
  check.yml               config, shell, Python and installer tests (every push / PR)
  images.yml              postmarketOS watcher + image builds + publishing
  pages.yml               release records and device.json on GitHub Pages
  bootchain.yml           boot-chain payload (bootchain.enabled)
ci/
  state                   build or not? (upstream version + fingerprint), next version
  prepare                 upstream duranium-build + pmaports + what we maintain
  check-image             an image's keyring, channel and debug layer, before publishing
  publish                 one image to its channel (signed SHA256SUMS, pruning)
  pages                   releases.json, channels/, device.json, index.html
  bootchain/build|publish the boot-chain payload
scripts/
  config                  the only reader of config.toml (get, shell, json, channels, check)
  init-device             template -> port (once)
  new-signing-key         the update signing key pair (once)
  build-image             a local image build, the same steps as CI
  kernel-export           the kernel branch -> the kernel aport
  aport-checksum          sha512sums= without abuild
  pmos-verify             record a device-verified export (release channels)
  firmware-snapshot       the stock Android's hardware facts + vendor files, over adb
  firmware-extract        a stock firmware package -> images, DTs, vendor trees
  firmware-decompile      REA + Ghidra on chosen vendor binaries (docs/FIRMWARE.md)
  firmware-tool           their helpers (redaction, DTB carving, summaries, targets)
  installer/              the installer (setup, lib/, py/, udev/, device.sh hooks)
pmos/
  aports/BUILD            what the images need from us
  aports/device/testing/device-<id>/          device package
  aports/device/testing/linux-postmarketos-<soc>/   kernel
  aports/main/duranium-usb-debug/             USB debug layer (dev images)
  duranium/patches/ BASE  generic duranium-build hooks
  duranium/contrib/       the port's image build layer (-> contrib/<id>/)
  sysupdate-public-key.asc  VERIFIED
bootchain/                BOOT payload: build.sh, the vendored u-boot/ and uniLoader/
initramfs/                bring-up Linux init (nolibc), optional
docs/                     this, CONFIG, PORTING, RELEASES, INSTALL, STATUS,
                          HARDWARE, PLAN, FIRMWARE, TESTPLAN, AGENT-HANDOFF
  re/                     reverse engineering notes, our own words (re/README.md)
tests/
  config/                 scripts/config tests
  installer/              offline installer tests (mock tablet, mock server)
  firmware/               firmware tools tests (mock adb, synthetic images)
```

Not committed (`.gitignore`): `src/` (kernel, U-Boot, loader clones; the
kernel branch is exported with `scripts/kernel-export`), `build/` (work
trees, packages, images, ccache, `build/work/build.lock`), `firmware/`
(vendor firmware, stock images, device snapshots, decompiled code:
Samsung's or private, never published; config.toml `[firmware]`).

## Where things are decided

| Question | Answer lives in |
|---|---|
| What device, which UIs, which channels, where updates come from | `config.toml` |
| What the kernel is | `pmos/aports/device/testing/linux-postmarketos-<soc>/` (exported from `src/linux`) |
| What is on the device besides postmarketOS | the device package (`pmos/aports/device/testing/device-<id>/`) |
| How an image is built | `pmos/duranium/contrib/`, `ci/prepare` |
| Whether CI builds, and which version | `ci/state` |
| What may be published | `ci/check-image`, `pmos/VERIFIED`, the signing key |
| What the installer may write | `config.toml` `[installer]` + `scripts/installer/lib/guard.sh` |
| Device-specific installer logic | `scripts/installer/device.sh` |

## The flow

```
 postmarketOS publishes          a push to config.toml / pmos/ / ci/
            \                     /
             ci/state (every 6 h): fingerprint changed?
                         | yes
             ci/prepare: duranium-build + patches + contrib, pmaports + aports
                         |
             build-apks.sh (kernel via ccache, device, debug layer)
                         |
   image job per (ui, channel): build-image.sh -> ci/check-image -> ci/publish
                         |
   GitHub release per channel (signed SHA256SUMS)  ->  devices: systemd-sysupdate
                         |
   pages.yml: releases.json, device.json  ->  exynos-linux.github.io, setup.sh
```

Release channels only get builds of a `pmos/VERIFIED` export: an on-device
pass of exactly those trees. Dev channels get every build, as pre-releases.
