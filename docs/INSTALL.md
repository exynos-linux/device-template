# Installing postmarketOS Duranium on the `<Device name>` (`<model>`)

<!-- Port maintainers: replace every <placeholder> and every "see
config.toml" with this device's values, then delete this comment. The last
section lists what to fill in. -->

`./setup.sh` installs postmarketOS Duranium (the UIs in `config.toml`,
`[images] uis`) on a Samsung `<Device name>` **`<model>`** from a Linux PC,
over the USB cable. It guides you through every step, waits for you where
you have to press buttons on the tablet, and can always put Android back.

It is a development port: read [STATUS.md](STATUS.md) for what works.

## In short

```sh
git clone https://github.com/<owner>/<repo>
cd <repo>
./setup.sh --stock-ap ~/Downloads/AP_<firmware version>_....tar.md5
```

Re-running `./setup.sh` always continues where it stopped.

## How it works: two stages

| Stage | What changes on the tablet | Android afterwards | Back to Android |
|---|---|---|---|
| Bootloader unlock (Samsung's own step, only if locked) | **Samsung erases the tablet** (factory reset) | empty, as new | - |
| **1. Try** (`./setup.sh`) | only the boot partition (`<BOOT>`): it gets our Linux (the "live environment") | untouched: system, apps, files | `./setup.sh undo`: exactly as before |
| **2. Install** (`./setup.sh install`, from the live environment) | Android's data partition is erased, Duranium is written into it | system still there, data gone | `./setup.sh restore-android-backup` (your backup) or `restore-android` (empty Android) |

Nothing of Android is erased until you choose **Install** and confirm it
twice: by typing `ERASE` on the PC and by pressing **Power** on the tablet.
Before that you can make a byte-exact backup of all of Android to your PC.

Duranium lives in a disk nested inside Android's `userdata` partition and
starts through our boot chain in the boot partition (uniLoader, U-Boot,
systemd-boot). Android's system partitions, the recovery and Samsung's
bootloader are not changed. The installer never writes the partitions that
hold the tablet's identity and boot security (EFS, PARAM, PERSISTENT,
VBMETA, the bootloader, ...; the full list is `[installer] protected` in
`config.toml`): it refuses that in code, before every write.

## What you need

- A Samsung `<Device name>` **`<model>`**. `<Not the ... models (sister
  models this port does not support).>` Tested with firmware
  **`<tested firmware>`** (bootloader revision `<rev>`), hardware revision
  `<hw rev>` (see `[android]` in `config.toml`).
- A Linux PC (Fedora, Debian, Ubuntu, Arch, Alpine, ...) with these tools;
  `./setup.sh doctor` checks them and prints the install command:

  | Fedora | Debian / Ubuntu | Arch |
  |---|---|---|
  | `sudo dnf install android-tools heimdall curl gnupg2 zstd lz4 python3 openssl mtools e2fsprogs usbutils iproute` | `sudo apt install adb heimdall-flash curl gnupg zstd lz4 python3 openssl mtools e2fsprogs usbutils iproute2` | `sudo pacman -S android-tools heimdall curl gnupg zstd lz4 python openssl mtools e2fsprogs usbutils iproute2` |

- A USB **data** cable (charge-only cables do not work) and a USB port on
  the PC itself (hubs often drop the connection in Download mode).
- Your tablet's **stock firmware** for `<model>` in the version the tablet
  runs (Settings > About tablet > Software information > Build number),
  from SamFW, Frija, Bifrost or samloader. You need the `AP_....tar.md5`
  file (inside the downloaded zip). Samsung's files cannot be shipped with
  this project; the installer needs them for:
  - your **stock boot image**, kept on your PC: `undo` puts it back, and our
    boot image is built around its device tree,
  - the **vendor firmware** for `<Wi-Fi, Bluetooth, audio, ...>` (when
    Android does not let the installer copy it directly).
  `<If [android] fus_model is set:>` Or let the installer download it from
  Samsung: `./setup.sh --download-stock` (needs `tools/auth_param.dat` from
  [Bifrost](https://github.com/zacharee/Bifrost),
  `common/src/commonMain/composeResources/files/auth_param.dat`; your
  tablet's serial number goes to Samsung's server only, as with Samsung's
  own tools).
- Free space on the PC: about 10 GB for downloads, plus room for backups
  (the full Android backup is about as big as the data Android uses).
- About an hour, most of it waiting.

## Stage 1: try it

1. On the tablet: **Settings > About tablet > Software information**, tap
   **Build number** 7 times. Then **Settings > Developer options**: switch
   on **USB debugging** (and **OEM unlocking**, if it is there).
2. Plug the tablet into the PC and run `./setup.sh --stock-ap AP_....tar.md5`.
3. The tablet asks **"Allow USB debugging?"**: tick "Always allow" and tap
   Allow.
4. The installer reads the model, firmware and lock state and tells you
   what to do. If the bootloader is **locked**, it walks you through
   Samsung's unlock (see below).
5. It saves your stock boot image and the vendor firmware on the PC, gets
   our boot chain (signed, checked) and builds your boot image.
6. It restarts the tablet into **Download mode** and flashes the boot
   partition. Then:
   - the orange/yellow warning "The bootloader is unlocked and software
     integrity cannot be guaranteed": normal, it continues by itself;
   - white text on black, "`<banner of the bring-up Linux>`": the **live
     environment**. The PC talks to it over the USB cable.
7. A menu: back up Android, install Duranium, go back to Android, or stop.

### The bootloader unlock (only if it is locked)

Samsung's unlock **erases everything on the tablet**. The installer first
offers to copy your photos, downloads, documents, music and videos to the
PC (or to the tablet's microSD card, which the unlock does not erase) and
lists your apps. App data, accounts and passwords cannot be backed up
without root. Then:

1. Type `UNLOCK` on the PC.
2. `<The device's unlock buttons, as device_unlock_steps in
   scripts/installer/device.sh prints them, e.g.:>` Power the tablet off.
3. Hold **Volume Up + Volume Down** and plug in the USB cable.
4. At the warning screen, **long-press Volume Up** ("Device unlock mode"),
   then press **Volume Up** to confirm.
5. The tablet erases itself and restarts. Go through Android's setup quickly
   but **connect to Wi-Fi**: Samsung's KnoxGuard check needs the internet.
6. Again: Build number x7, Developer options > USB debugging, allow the PC.
   The installer notices and continues.

If **OEM unlocking** is missing in Developer options: connect to Wi-Fi, set
date and time to automatic, check for software updates, restart and look
again. If it never appears, the tablet is probably carrier- or
company-managed and cannot be unlocked.

## Stage 2: from the live environment

### Full Android backup (recommended before installing)

`./setup.sh backup-android` (or menu item 1) reads Android's `userdata`
and `metadata` partitions byte for byte into
`~/<codename>-backups/android-raw-<date>/` (zstd-compressed), plus a
read-only copy of `efs`/`sec_efs` (`[installer] backup_readonly`: your
tablet's identity data, for your safety only: never shared, never written
back by the installer). Unused space compresses away; the encrypted data
does not, so expect roughly the size Android said it uses. Reading the
`<size>` partition over USB takes `<minutes>` minutes (the installer prints
its estimate).

The backup only works on **this** tablet (Android's encryption keys are in
its secure hardware). `./setup.sh restore-android-backup [DIR]` puts it
back and starts Android exactly as it was, with apps and data.

### Install Duranium

`./setup.sh install` (or menu item 2):

1. Choose the image: one per UI (`[images] uis`; `default_ui`,
   `<UI title>`, is recommended and the default), **release** or **dev**.
   Dev images run a root shell, ssh and adb on the USB cable **without a
   password**: only for development tablets. Images marked "not yet
   confirmed on a device" have not passed the on-device test yet.
2. The image is downloaded (resumable), its signature checked against the
   project key (`pmos/sysupdate-public-key.asc`, fingerprint
   `<fingerprint, [update] fingerprint in config.toml>`) and unpacked. Your
   vendor firmware is added to the image's boot partition.
3. Confirm: type `ERASE` on the PC, then press **Power** on the tablet
   (Volume Up cancels; nothing is changed).
4. Android's data partition is erased, the image is written and read back
   for checking, the boot partition gets the Duranium boot chain.
5. First start, 5-10 minutes: U-Boot, systemd-boot, the postmarketOS logo.
   The first start creates the encrypted root partition. Then choose your
   **disk passphrase** (asked at every start) and your user.

`<Wi-Fi, Bluetooth and audio>` need the vendor firmware: the installer puts
it on the image's boot partition (`/boot/<device id>-firmware.tar.zst`) and
Duranium moves it into `/var/lib/firmware` at the first start, before the
drivers load (updates never touch it). If Wi-Fi is missing after setup, copy
`~/.local/state/<codename>-setup/firmware/firmware.tar` to the tablet (USB
stick) and run in a terminal:

```sh
sudo tar -xf firmware.tar -C /var/lib/firmware --no-same-owner
sudo reboot
```

On dev images the installer checks this over USB and installs it itself
(`./setup.sh firmware` does it again).

## Going back to Android

| Situation | Command | Result |
|---|---|---|
| Stage 1 (Duranium not installed) | `./setup.sh undo` | stock boot image back; Android starts exactly as before |
| You have a full backup | `./setup.sh restore-android-backup` | Android exactly as it was when you backed it up |
| No backup | `./setup.sh restore-android` | Duranium erased; Android's data partition is formatted (as Samsung formats it) and Android starts its first-time setup |
| Temporarily, Duranium installed | `./setup.sh undo`, later `./setup.sh redo` | **careful**, see below |

`restore-android` needs to know how Samsung formats `userdata` on this
device (`[android] userdata_f2fs_options` / `userdata_f2fs_features`);
`<if those are empty: this port does not offer it yet; use your backup or
the full stock firmware>`.

**Never use "Factory data reset" from Samsung's recovery menu**, and do not
accept Android's offer to reset. On these tablets it sets **KnoxGuard** back
to "Prenormal": Download mode then refuses every non-Samsung image ("Only
official released binaries are allowed to be flashed") until the tablet has
checked in with Samsung over the internet. `restore-android` avoids it: it
formats Android's data from our Linux instead.

`undo` after installing Duranium flashes the stock boot image, but Android's
data partition then holds Duranium, so Android stops with "Can't load
Android system" and offers a factory reset: refuse it, put Duranium back
with `./setup.sh redo`, or use `restore-android`. The installer asks you to
type `UNDO` in that case.

**Full stock firmware**: if Android's system was erased (on tablets
prepared by hand; the installer never erases it), flash your complete stock
firmware: Odin on Windows (BL, AP, CP, HOME_CSC), or heimdall with every
image from the AP file. Never flash a modified `vbmeta`: the bootloader
then stops in Download mode without USB.

## Updates

Installed tablets update themselves from this project's releases (A/B: the
running version stays as the fallback; a version that fails to start twice
is dropped automatically):

```sh
sudo updatectl update   # on the tablet, then restart
./setup.sh update       # from the PC, dev images (USB console)
```

Your files, settings and the vendor firmware are on the encrypted root and
are never touched by updates. A tablet updates within its UI; switching UI
is an update too, see [RELEASES.md](RELEASES.md).

### Testing your own build

For developers: `./setup.sh update --next-test-version` prints the version
to build a test image with (`<newest published + 1>~test<N>`, e.g.
`26102215~test1`). Build it with that version (`mkosi --image-version`,
never rename a build), then `./setup.sh update --test [mkosi.output dir]`
installs it as a one-off A/B update through `scripts/duranium-update`. `~`
sorts below the plain version, so the next official update replaces the
test build; the tablet's update channel is not changed (the installer
checks it before and after).

## Commands

| Command | |
|---|---|
| `./setup.sh` | the guided install; continues where it stopped |
| `./setup.sh live` | stage 1 only |
| `./setup.sh backup-android` / `restore-android-backup [DIR]` | full Android backup / restore |
| `./setup.sh install` | stage 2: install Duranium |
| `./setup.sh undo` / `redo [linux\|chain]` | stock boot image back / ours back |
| `./setup.sh restore-android` (= `uninstall`) | erase Duranium, Android starts fresh |
| `./setup.sh wipe` | fresh install over an existing Duranium (type `WIPE`) |
| `./setup.sh update [--test ...]` | updates |
| `./setup.sh firmware [--export FILE]` | (re)install the vendor firmware |
| `./setup.sh backup-files` | copy Android's files over adb |
| `./setup.sh prepare` | only rebuild your boot images (e.g. after a new boot-chain release) |
| `./setup.sh status` / `doctor` | what is connected, versions, slots / + PC checks |

Options: `--stock-ap FILE`, `--stock-zip FILE`, `--stock-boot FILE`,
`--download-stock`, `--firmware-dir DIR`, `--channel ID`, `--version V`,
`--image FILE` (a local image, no signature check), `--payload DIR|TAR`,
`--serial SERIAL`, `--dry-run` (show every action, change nothing),
`--verbose`, `--yes` / `--yes-wipe` (non-interactive). `./setup.sh --help`.

## Buttons

`<The device's buttons; they must match HINT_FORCE_RESTART, HINT_DOWNLOAD
and device_download_steps in scripts/installer/device.sh.>`

| What | How |
|---|---|
| Force restart | hold **Power + Volume Down** for 7-10 s |
| Download mode | force restart, then at once hold **Volume Up + Volume Down** and plug in USB; press Volume Up at the warning |
| Leave the live environment | **Volume Up** restarts it into Download mode |

## Troubleshooting

- **adb shows no device**: USB debugging off, charge-only cable, or no USB
  rules: `./setup.sh doctor` offers to install
  `scripts/installer/udev/60-exynos-linux-samsung.rules`.
- **"unauthorized"**: accept the prompt on the tablet; no prompt? replug,
  or Developer options > Revoke USB debugging authorisations.
- **The live environment does not answer**: the PC must bring up the
  tablet's USB network (`ip link` shows a new interface with the cdc_ncm
  driver); `./setup.sh status` explains what it sees and offers
  `sudo ip link set <if> up`.
- **"An error has occurred while updating the device software"** in
  Download mode: KnoxGuard blocks custom images, or the USB connection
  dropped. Look at the small text at the top of the Download mode screen:
  `KG STATE: Prenormal` means: restart into Android, stay online on Wi-Fi
  for 10 minutes, restart once, try again. Otherwise use another USB
  port/cable. Download mode always works, and `./setup.sh undo` puts your
  stock boot image back.
- **Duranium does not start**: after a failed start the boot chain falls
  back to our Linux (white text). `./setup.sh status` tells you what runs.
- **Logs**: every run writes `~/.local/state/<codename>-setup/log/`.

## Files on your PC

The directory names come from `[installer] name` (default
`<codename>-setup`) and `[device] codename`.

| Where | What |
|---|---|
| `~/.local/state/<codename>-setup/` (`SETUP_STATE_DIR`) | progress (`state.env`), logs, your stock boot/recovery images, vendor firmware, your boot images and the local key for their footer |
| `~/.cache/<codename>-setup/` (`SETUP_CACHE_DIR`) | downloads (safe to delete) |
| `~/<codename>-backups/` (`SETUP_BACKUP_DIR`) | your backups |

The serial number is never stored (only a hash, to recognise the tablet).
Samsung's firmware and your backups stay on your PC: do not share them.

## For developers

- Everything lives in `scripts/installer/` (`setup.sh` only starts it);
  every device value comes from `config.toml` (read once, through
  `scripts/config shell`), the device logic from
  `scripts/installer/device.sh`. Tests: `tests/installer/run.sh` (a fake
  tablet with the fictional device of `tests/installer/config.toml`; no
  device, no network).
- The boot chain payload (uniLoader + U-Boot + our bring-up Linux, all GPL,
  no Samsung files) is built by `ci/bootchain/build` and published by
  `.github/workflows/bootchain.yml` to the release `<device id>_bootchain`
  (`[bootchain] tag`) with a signed SHA256SUMS. The installer packs it with
  the owner's stock DTB and header.
- `--image FILE.raw[.zst]` and `--payload DIR` take local builds.

## For port maintainers: what to fill in

In `config.toml` (every key is described in `docs/CONFIG.md`):

- `[device]`: `name`, `models`, `codename`, `vendor`, `form_factor`.
- `[android]`: `product_device`, `firmware_pattern`, `tested_firmware` and
  `tested_bootloader_rev` (empty: every user is asked whether to continue),
  `fus_model` (or `""`), `userdata_f2fs_options` / `userdata_f2fs_features`
  from your stock `userdata.img` (or `""`: no `restore-android`).
- `[installer]`: `flash_allow`, `boot_partition`, `recovery_partition` and
  `boot_partition_bytes` from the PIT (`heimdall print-pit`); `main_disk`
  and `sector_size` (UFS: `sda`, 4096; eMMC: `mmcblk0`, 512); the GPT names;
  `protected` (extend it with every identity/key/boot-chain partition of
  your PIT, never shorten it); `required_firmware` and `firmware_exclude`;
  `backup_readonly`.
- `[update] fingerprint` (scripts/new-signing-key) and `[bootchain]`.

In `scripts/installer/device.sh` (each hook is documented in its header):

- `device_check_model`: sister models (LTE, ...) with a clear message.
- `device_check_hardware`: known hardware revisions.
- `HINT_FORCE_RESTART`, `HINT_DOWNLOAD`, `device_download_steps`,
  `device_unlock_steps`: the device's buttons.
- `device_firmware_vendor_dirs`, `device_extra_firmware`,
  `device_firmware_stage`: where the vendor firmware comes from and the
  names the mainline drivers request.
- `device_reset_boot_record`: the payload's boot record before the first
  Duranium boot, if it has one.

In this file: every `<placeholder>`, the tested firmware, the buttons, the
banner of the live environment, what the vendor firmware is for, and any
device-specific section (e.g. extra storage from Android's partitions).
Then run `tests/installer/run.sh` and `./setup.sh --dry-run` against the
device.
