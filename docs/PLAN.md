# @DEVICE_NAME@ (@MODEL@): port plan

The way from stock Android to postmarketOS Duranium with every block
working. The `setup` skill (`/setup`) writes the first version from the
research and the firmware snapshot; keep it current as blocks land
(docs/STATUS.md says what is verified, this file says what comes next).

## Risks first

| Risk | What we know (source) | What it means for the plan |
|---|---|---|
| Bootloader unlock on the current firmware | | |
| KnoxGuard / carrier lock | | |
| Upstream clocks / pinctrl for @SOC_NAME@ | | |

## Starting points

Existing trees this port reads or builds on, maintained or archived. They
are where registers, clocks, pin setups and power sequences come from;
the drivers we write are clean mainline code. Their history and GPL
attribution stay intact (`src/` clones keep every commit, ported files
keep their headers, commits credit the authors).

| Tree (URL) | Kind | Match | Commit / SHA-256 | License | How we use it | What it gives us |
|---|---|---|---|---|---|---|
| | downstream kernel | | | | `src/` clone / raw files / org fork / facts only | |
| | mainline attempt | | | | | |

## Phases

| # | Phase | Done when | Depends on |
|---|---|---|---|
| 0 | Unlock, backups, firmware snapshot | OEM unlock done, EFS backup on the PC, `firmware/` snapshot + stock extract | the owner |
| 1 | Downstream first boot (stepping stone) | a postmarketOS downstream-kernel image boots from BOOT, shell over USB, the hardware dump in `firmware/downstream/`; never released, retired after phase 3 | 0 |
| 2 | Bring-up kernel | a mainline kernel boots from BOOT and stays up (panic → Download mode) | 0 (1 for the dump) |
| 3 | USB console | root shell over USB NCM, `put`/`get` | 2 |
| 4 | Storage | UFS/eMMC partitions readable, the nested GPT | 3 |
| 5 | Display + input | framebuffer/DRM on the panel, touch, keys | 3 |
| 6 | Boot chain + installer | U-Boot + systemd-boot from BOOT, `./setup.sh` tests pass | 4 |
| 7 | First Duranium image | GNOME/Phosh on the panel, A/B update works | 5, 6 |
| 8 | The rest, block by block | docs/STATUS.md all ✔ | 7 |

## Blocks

One row per block of docs/HARDWARE.md. Size: S (DT only), M (driver
changes), L (new driver or reverse engineering).

| Block | Upstream state (source) | Reference (starting tree file, GPL kernel file, sibling SoC, docs/re note) | Size | Depends on |
|---|---|---|---|---|
| CPU, PMU, timers | | | | |
| Clocks (CMU) | | | | |
| Pinctrl, GPIO | | | | |
| UART / USI | | | | |
| Storage (UFS / eMMC) | | | | |
| USB (DRD, PHY) | | | | |
| PMIC, regulators | | | | |
| Display (DECON/DPU, DSIM, panel) | | | | |
| Touch, keys | | | | |
| GPU | | | | |
| Wi-Fi, Bluetooth | | | | |
| Audio | | | | |
| Battery, charger | | | | |
| Sensors | | | | |
| Cameras | | | | |
| GNSS, NFC, modem | | | | |

## Next three steps

1.
2.
3.
