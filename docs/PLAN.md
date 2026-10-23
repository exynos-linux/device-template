# @DEVICE_NAME@ (@MODEL@): port plan

The way from stock Android to postmarketOS Duranium with every block
working. The `new-device` skill writes the first version from the
research and the firmware snapshot; keep it current as blocks land
(docs/STATUS.md says what is verified, this file says what comes next).

## Risks first

| Risk | What we know (source) | What it means for the plan |
|---|---|---|
| Bootloader unlock on the current firmware | | |
| KnoxGuard / carrier lock | | |
| Upstream clocks / pinctrl for @SOC_NAME@ | | |

## Phases

| # | Phase | Done when | Depends on |
|---|---|---|---|
| 0 | Unlock, backups, firmware snapshot | OEM unlock done, EFS backup on the PC, `firmware/` snapshot + stock extract | the owner |
| 1 | Bring-up kernel | a mainline kernel boots from BOOT and stays up (panic → Download mode) | 0 |
| 2 | USB console | root shell over USB NCM, `put`/`get` | 1 |
| 3 | Storage | UFS/eMMC partitions readable, the nested GPT | 2 |
| 4 | Display + input | framebuffer/DRM on the panel, touch, keys | 2 |
| 5 | Boot chain + installer | U-Boot + systemd-boot from BOOT, `./setup.sh` tests pass | 3 |
| 6 | First Duranium image | GNOME/Phosh on the panel, A/B update works | 4, 5 |
| 7 | The rest, block by block | docs/STATUS.md all ✔ | 6 |

## Blocks

One row per block of docs/HARDWARE.md. Size: S (DT only), M (driver
changes), L (new driver or reverse engineering).

| Block | Upstream state (source) | Reference (GPL kernel file, sibling SoC, docs/re note) | Size | Depends on |
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
