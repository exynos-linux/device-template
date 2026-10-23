# pmos/: what this port maintains for postmarketOS Duranium

The image CI (`.github/workflows/images.yml`, `ci/`) builds the published
images from this directory plus upstream postmarketOS (`ci/prepare`).

- `aports/`: our aports, added to upstream pmaports (never replacing one);
  `aports/BUILD` lists the ones the images need
  - `device/testing/device-<device.id>/`: the device package (UI-neutral)
  - `device/testing/linux-postmarketos-<soc>/`: the kernel (`scripts/kernel-export`)
  - `main/duranium-usb-debug/`: the USB debug layer of the dev images
- `duranium/patches/`: generic hooks on top of upstream duranium-build
  (`BASE`: the commit they were made on; upstream them when you can)
- `duranium/contrib/`: the port's image build layer (its README)
- `sysupdate-public-key.asc`: the key every channel's SHA256SUMS is signed
  with (`scripts/new-signing-key`); installed devices trust only this one
- `VERIFIED` (`scripts/pmos-verify`): the aports + duranium trees that passed
  on the device; only those reach the release channels

See [../docs/RELEASES.md](../docs/RELEASES.md).
