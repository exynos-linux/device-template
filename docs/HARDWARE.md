# @DEVICE_NAME@ (@MODEL@): hardware map

From the stock firmware and Samsung's GPL kernel source. Sources for every
row (file, DT node, register dump): no guesses without a "?".

## Identity

| | |
|---|---|
| Models | @MODEL@ |
| SoC | @SOC_NAME@ |
| Stock firmware tested | |
| Bootloader revision | |
| Samsung GPL source | opensource.samsung.com: model, version |

## Memory map (from the stock DT / /proc/iomem)

| Block | Base | Size | Stock driver | Mainline driver |
|---|---|---|---|---|

## Buses and peripherals

| Peripheral | Bus / address | IRQ / GPIO | Supplies | Firmware file | Notes |
|---|---|---|---|---|---|

## Partitions (PIT / GPT)

| Name | LUN / device | Size | Contents | Installer |
|---|---|---|---|---|

Mark every partition the installer must never touch: they belong in
`installer.protected` in config.toml.

## Boot

- S-Boot: boot image header version, page size, DTB / DTBO handling,
  AVB / vbmeta behaviour with the bootloader unlocked
- Download mode / recovery key combos
- PMU registers for the reboot reason (Download mode from Linux)
