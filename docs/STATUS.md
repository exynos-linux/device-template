# @DEVICE_NAME@: hardware status, strictly

"Works" means **tested on the device** at that level. Two levels:

- **Bring-up**: the bring-up Linux (nolibc init, drivers loaded by hand,
  console tools).
- **Duranium**: postmarketOS Duranium as users run it, driven by the normal
  userspace (udev, NetworkManager, PipeWire, the compositor).

Only a **Duranium ✔** counts as done. Everything else is work.

Legend: ✔ verified · ◐ partly / with caveats (stated) · ✘ broken ·
— not built yet · ? not tested at that level.

| Block (stock spec) | Driver / state | Bring-up | Duranium | What is left |
|---|---|---|---|---|
| **CPU** @SOC_NAME@ | | — | — | |
| **CPU frequency** | | — | — | |
| **CPU idle** | | — | — | |
| **GPU** | | — | — | |
| **RAM** | | — | — | |
| **Storage** (UFS / eMMC) | | — | — | |
| **microSD** | | — | — | |
| **Display** | | — | — | |
| **Backlight** | | — | — | |
| **Touch** | | — | — | |
| **Pen** | | — | — | |
| **Keys** | | — | — | |
| **Vibrator** | | — | — | |
| **Wi-Fi** | | — | — | |
| **Bluetooth** | | — | — | |
| **NFC** | | — | — | |
| **Audio** (speaker, jack, mics) | | — | — | |
| **USB-C** (charging, gadget, host) | | — | — | |
| **Battery** / fuel gauge | | — | — | |
| **Thermal** | | — | — | |
| **PMIC** / regulators | | — | — | |
| **Cameras** | | — | — | |
| **Sensors** (accel, gyro, light, ...) | | — | — | |
| **GPS** | | — | — | |
| **Modem** | | — | — | |
| **Fingerprint** | usually TrustZone-owned | — | — | |

## postmarketOS (Duranium) integration

| Piece | State |
|---|---|
| Boot chain (S-Boot → loader → U-Boot → systemd-boot → UKI) | — |
| Immutable /usr (EROFS + dm-verity), A/B slots, LUKS root | — |
| USB debug layer in dev images | — |
| Updates from the channels (systemd-sysupdate, boot counting) | — |
| Suspend | — |
| Hang recovery (watchdog, fallback) | — |
