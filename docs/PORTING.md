# Porting a new device

From "a Samsung Exynos device with an unlockable bootloader" to "signed
postmarketOS Duranium images that update themselves". Steps 1-4 take an
afternoon; the kernel work after that is the real port.

## 0. Before anything: can it be unlocked?

- Settings > About > Software information: tap Build number 7 times, then
  Developer options > **OEM unlocking** must exist and be switchable. If it
  is missing, stop: newer Samsung firmware (One UI 8) has been reported to
  remove it. **Do not install system updates** on a device you want to port
  until it is unlocked.
- Not enrolled in Knox device management (company devices): enrolment can
  block the unlock. Unlocking trips the Knox warranty fuse for good.
- Note the firmware version (`ro.build.PDA`, e.g. `X306BXXU1AXB5`) and the
  bootloader revision (5th character from the end).
- Find the SoC (`ro.soc.model`, `ro.hardware`) and check what upstream Linux
  already has for it: `arch/arm64/boot/dts/exynos/`, `drivers/clk/samsung/`,
  `drivers/pinctrl/samsung/`, and the mailing list (lore.kernel.org).

## 1. Make the repo

1. On GitHub, exynos-linux/device-template: **Use this template**, name the
   repo `<vendor>-<codename>` (postmarketOS device naming, e.g.
   `samsung-gtactive5`). Public.
2. Clone it, then:

   ```
   scripts/init-device --vendor samsung --codename gtactive5 \
     --soc exynos1380 --soc-name "Exynos 1380" \
     --name "Galaxy Tab Active5" --model SM-X306B --model SM-X300 \
     --maintainer "Your Name <you@example.org>"
   ```

   It fills `config.toml`, sets `project.template = false`, renames the
   aports and replaces the placeholders (`@VENDOR@`, `@CODENAME@`,
   `@DEVICE_ID@`, `@SOC@`, `@SOC_NAME@`, `@DEVICE_NAME@`, `@VENDOR_NAME@`,
   `@MODEL@`, `@REPO@`, `@MAINTAINER@`, `@FORM_FACTOR@`).
3. `scripts/new-signing-key`, then add the private key as the
   `SYSUPDATE_SIGNING_KEY` secret (the script prints the command). Keep an
   offline copy.
4. Settings > Pages > Source: **GitHub Actions**.
5. Commit and push. `check` must pass. `images` runs but builds nothing
   until the kernel and device packages exist (`ci/state`).
6. Add the device to the org site: one `[[devices]]` block in
   exynos-linux.github.io's `site.config.toml`.

## 2. Hardware map

Fill `docs/HARDWARE.md` from the stock firmware: the stock kernel's DT
(`dtc -I dtb` on the boot image's DTB/DTBO), `/proc/iomem`, `lsmod`,
`/vendor/firmware`, the partition table (`ls -l /dev/block/by-name`), the
PIT (`heimdall print-pit`). Samsung's GPL kernel source for the model
(opensource.samsung.com) is the driver reference. Never commit Samsung
binaries.

## 3. Bring-up Linux

The first goal is a mainline kernel that boots from BOOT and gives you a USB
console, without touching Android:

- `src/linux`: a clone of torvalds/linux; branch per topic, an integration
  branch the device runs.
- DT: `arch/arm64/boot/dts/exynos/<soc>.dtsi` + `<soc>-<codename>.dts`,
  starting from the nearest upstream SoC and the stock DT.
- `initramfs/`: the bring-up init (`initramfs/README.md` has the contract;
  the first port's `init.c` is the reference).
- Flash with heimdall to BOOT only; Volume keys into Download mode are the
  way back. Every boot test must come back to the USB console or to
  Download mode without a human (`.claude/rules/device-safety.md`).

## 4. Kernel aport

When a kernel boots and is worth packaging:

```
scripts/kernel-export --config build/<kernel-out>/.config <branch> <upstream-base>
```

writes `<codename>.patch`, the config, `_commit`, `_base`, `pkgver`, a pkgrel
bump and the checksums. The config needs what Duranium needs on top of the
bring-up: systemd (cgroups, namespaces, `CONFIG_FHANDLE`, ...), the EFI
stub (systemd-boot starts the UKI), dm-verity, EROFS, `BLK_DEV_LOOP`,
`BLK_DEV_WRITE_MOUNTED`, `CONFIG_PARTITION_ADVANCED` + EFI partitions, USB
gadget NCM (debug layer), and the postmarketOS kconfigcheck categories in
the APKBUILD's options. The first port's kernel fragments are a checklist.

## 5. Device package

`pmos/aports/device/testing/device-<id>/`: deviceinfo, kernel command line,
firmware import, the nested-GPT udev rule, the watchdog. Add what the
hardware needs (udev rules, modprobe.d, UCM audio profiles, gschema
overrides) and keep it UI-neutral: anything for one UI goes into a
subpackage with `install_if`. `scripts/aport-checksum` after every change,
and bump `pkgrel`.

## 6. Boot chain and installer

- `bootchain/build.sh`: loader + U-Boot + the bring-up Linux, from public
  sources (`bootchain/README.md`); then `bootchain.enabled = true`.
- `config.toml` `[installer]`: partitions, protected list, firmware files
  the drivers need. `scripts/installer/device.sh`: the hooks for what config
  cannot say. `bash tests/installer/run.sh` must pass.
- `docs/INSTALL.md`: fill in the device specifics.

## 7. First images

```
scripts/build-image --ui phosh --channel dev
```

builds locally exactly as CI does. Install it with `./setup.sh` on the
device, test (`docs/TESTPLAN.md`), fix, repeat. Push: CI publishes the dev
channels. After an on-device pass of the exact export:
`scripts/pmos-verify "what passed"`, commit, push: the release channels
publish. Set `device.status = "testing"`, later `"stable"`.

## Keeping up

- postmarketOS moves: CI rebuilds on every publish. If
  `pmos/duranium/patches` stop applying, CI falls back to
  `pmos/duranium/BASE` and warns; rebase them then.
- Improvements to the plumbing (ci/, scripts/, workflows, installer) belong
  in device-template too: send them there so every port gets them.
