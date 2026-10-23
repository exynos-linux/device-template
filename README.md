<!-- template:start (scripts/init-device removes this block) -->
# exynos-linux device template

The starting point for every [exynos-linux](https://github.com/exynos-linux)
device port: postmarketOS Duranium on a Samsung Exynos device, with the
upstream Linux kernel, signed A/B updates per UI, and images rebuilt
automatically whenever postmarketOS publishes.

**Use this template**, then `scripts/init-device` (see
[docs/PORTING.md](docs/PORTING.md)). Everything device-specific is in
[`config.toml`](config.toml) ([docs/CONFIG.md](docs/CONFIG.md)); the
layout is in [docs/STRUCTURE.md](docs/STRUCTURE.md).

What you get, working from the first push:

- **CI** (`.github/workflows/`): checks on every push; a postmarketOS
  watcher every 6 hours that rebuilds when upstream publishes or what you
  maintain changes; image builds for every UI x channel (release, dev);
  signed publishing to GitHub releases; release records on GitHub Pages.
- **Updates**: images that trust only your key and update from your
  releases (systemd-sysupdate, boot counting, fallback).
- **Installer** (`./setup.sh`): non-destructive live stage first, Android
  backup, install, undo, updates; hard limits on what it may ever write.
- **Packaging**: kernel and device aport skeletons, the USB debug layer for
  dev images, the duranium-build hooks.
- **Agent rules** (`CLAUDE.md`, `.claude/`), and the docs skeletons.

The README below is what a port's README looks like.

---
<!-- template:end -->
# postmarketOS Duranium on the @DEVICE_NAME@ (@MODEL@)

Part of [exynos-linux](https://exynos-linux.github.io): upstream Linux on
Samsung Exynos devices, with [postmarketOS](https://postmarketos.org)
Duranium on top. Not an official postmarketOS or Samsung project.

| | |
|---|---|
| Device | @DEVICE_NAME@ (@MODEL@), @SOC_NAME@ |
| Status | bring-up ([docs/STATUS.md](docs/STATUS.md)) |
| Images | Phosh, GNOME: [releases](https://github.com/@REPO@/releases) |
| Community | [Discord](https://discord.gg/exynos-linux) |

## Install

On a Linux PC, with the device on USB:

```
git clone https://github.com/@REPO@
cd @DEVICE_ID@ && ./setup.sh
```

It first only puts our Linux into BOOT (Android stays as it is; `./setup.sh
undo` brings it back), then offers a full Android backup and the install.
Requirements, every step and the way back: [docs/INSTALL.md](docs/INSTALL.md).

## Updates

Installed devices update from the
[releases](https://github.com/@REPO@/releases) (`updatectl update`, or the
software centre): A/B, signed, with automatic fallback to the previous
version. The images are rebuilt automatically on every postmarketOS
publish. Release channels carry only builds verified on the device; the
`-dev` channels carry every build and a root-over-USB debug layer, for
development devices only. [docs/RELEASES.md](docs/RELEASES.md)

Vendor firmware is not included: the installer takes it from your own
stock firmware, on your PC.

## Development

- What works: [docs/STATUS.md](docs/STATUS.md), hardware:
  [docs/HARDWARE.md](docs/HARDWARE.md), tests:
  [docs/TESTPLAN.md](docs/TESTPLAN.md)
- Layout: [docs/STRUCTURE.md](docs/STRUCTURE.md), configuration:
  [config.toml](config.toml) / [docs/CONFIG.md](docs/CONFIG.md)
- A local image, exactly as CI builds it:
  `scripts/build-image --ui phosh --channel dev`
- Agents: [CLAUDE.md](CLAUDE.md)

## License

Our code: GPL-2.0 (see [LICENSE](LICENSE)) unless a file says otherwise.
postmarketOS, its packages and the upstream projects keep their own
licenses. Samsung's firmware is Samsung's and is never distributed here.
