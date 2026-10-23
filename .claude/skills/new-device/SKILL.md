---
name: new-device
description: Start a new exynos-linux device port from this template, end to end. Asks which device, researches it with parallel subagents (mainline support for the SoC, postmarketOS, Samsung's GPL source, existing ports, unlock risks), offers to snapshot the stock firmware over adb and to decompile the vendor blobs (REA + Ghidra), then fills config.toml and writes docs/HARDWARE.md, README.md, docs/PLAN.md, docs/STATUS.md and docs/AGENT-HANDOFF.md. Use when the user runs /new-device, asks to start or set up a new device port, or when the repo is still the template (project.template = true) or its docs are unfilled placeholders.
---

# New device port

The goal: a port repo whose docs tell the next agent exactly what this
device is, what upstream Linux already has for it, where every fact came
from and what to do first. No device writes happen in this skill: no
flashing, no reboots, no unlocking. Read `.claude/rules/firmware.md` and
`.claude/rules/device-safety.md` first; they apply throughout.

## 0. Orient (no questions yet)

- `scripts/config get project.template`, `git remote -v`: the template
  itself, or a fresh port?
- `git grep -lE '@(DEVICE_NAME|MODEL|SOC_NAME)@'` (the template's
  placeholders) and empty tables in docs/HARDWARE.md: which docs are
  still unwritten.
- `ls firmware/*/` (or the `firmware.*_dir` paths from
  `scripts/config json`): earlier snapshots, stock extracts, RE output.
- `adb devices`. If exactly one device is attached and authorized, read
  `getprop ro.product.model`, `ro.product.device`, `ro.build.PDA`,
  `ro.soc.model`, `ro.hardware` (read-only) and offer it as the answer
  in step 1.

## 1. Ask which device

One AskUserQuestion call, two questions:

1. **Which device?** Options: the attached device if found ("SM-X306B,
   connected"), "I'll type the model number" (a model number like
   SM-T570 beats a marketing name; both are fine).
2. **Is the device with you?** "Yes, it can be plugged in" / "Yes, but
   not now" / "No, research only".

## 2. Research, in parallel

Start these as background subagents in **one message** (Agent tool,
`general-purpose`, `run_in_background: true`), then go on with step 3
while they run. Each brief names the model, the codename and the SoC as
far as known, and asks for a report of at most 60 lines: every fact with
its source URL, unverified facts marked "?", no Samsung binaries
downloaded.

- **Identity and unlock**: model ↔ codename (`ro.product.device`) ↔
  variants (Wi-Fi/LTE/5G, regions), SoC, RAM/storage options, panel,
  launch and current Android/One UI version, firmware versions
  (samfw.com and similar), whether OEM unlocking still exists on the
  current firmware (One UI 8 has removed it on some devices), KnoxGuard
  and carrier locks, Download mode and recovery key combos.
- **Mainline status of the SoC**: torvalds/linux
  `arch/arm64/boot/dts/exynos/`, `drivers/clk/samsung/`,
  `drivers/pinctrl/samsung/`, the SoC's entries in the bindings, which
  boards already use it, patch series in flight on lore.kernel.org
  (search the SoC name), sibling SoCs that share IP blocks, and ports in
  the exynos-linux GitHub org. Output: a block-by-block table (CPU/PMU,
  clocks, pinctrl, UART, timers, I2C/SPI (USI), UFS/MMC, USB DRD/PHY,
  display (DECON/DPU, DSIM), GPU (Mali generation), PMIC, thermal,
  audio (ABOX), camera (FIMC-IS), modem/Wi-Fi/BT) → upstream state.
- **Downstream and community sources**: Samsung's GPL kernel for the
  model (opensource.samsung.com, the version matching the firmware),
  LineageOS/TWRP device trees for the codename and its siblings,
  postmarketOS wiki and pmaports entries for the device or its SoC
  family, earlier mainline attempts on GitHub and XDA.

## 3. Firmware snapshot (ask first)

AskUserQuestion: **Collect the stock firmware facts now?** Options:
"Over USB from the device (adb, read-only)", "From a stock firmware
package I have (zip / AP tar)", "Both", "Skip for now". Say in the
description what it does: reads hardware facts and Samsung's vendor files
into `firmware/` on this PC (gitignored, never published), the serial and
MAC addresses removed.

**Over USB.** Guide the owner one physical step at a time and check each
yourself with `scripts/firmware-snapshot doctor`:

1. Settings > About tablet/phone > Software information > tap
   **Build number** seven times (PIN if asked).
2. Settings > Developer options > **USB debugging** on.
3. Plug the cable into this PC; on the device, tap **Allow** (tick
   "Always allow from this computer").

When doctor reports the device: if it also says su exists, ask whether to
use root (live device tree, kernel log, clocks, GPIOs, regulators,
partition images); never set up root yourself. Then
`scripts/firmware-snapshot run --yes [--root]` (the `--yes` stands for the
owner's yes in chat).

**From a package.** `scripts/firmware-extract --yes PATH` in the
background (minutes; about 10 GB free needed). If the owner has none,
tell them where packages come from (samfw.com, Frija, Bifrost,
samloader, or `./setup.sh --download-stock` once `android.fus_model` is
set) and let them download it: a multi-GB download is theirs to start.
The snapshot's PDA names the exact version to get.

Both produce a `SUMMARY.md` in their directory: identity, partitions,
block sizes, device tree compatibles, I2C/SPI devices, sensors, firmware
files, HALs, kernel modules.

## 4. Decompilation (ask first)

Only when it answers a question the GPL kernel source cannot: DSP and MCU
firmware (audio ABOX, sensor hub, camera ISP, GNSS), proprietary HAL
command sequences, calibration file formats. AskUserQuestion, multiSelect:
**Decompile the vendor blobs of which subsystems?** e.g. "Audio and
sensor hub", "Camera", "Wi-Fi, Bluetooth, GNSS", "Fingerprint and the
rest"; Other for a list. The description says: Samsung's code is
decompiled on this PC for interoperability, the output stays in
`firmware/re/` (gitignored), only our own notes are published.

1. `scripts/firmware-decompile doctor`. Missing tools: tell the owner what
   to install (REA: `npm install -g rea-agents`; Ghidra 12+ from
   github.com/NationalSecurityAgency/ghidra/releases; a JDK 21) and ask
   before installing anything yourself; then `doctor --write-env`.
2. `scripts/firmware-decompile targets KEYWORD...` to see candidates,
   `targets KEYWORD... --add` for the chosen ones. Raw firmware lines stay
   commented until the CPU and load address are known (the stock DT's
   reserved memory, the loading driver in the GPL kernel).
3. `scripts/firmware-decompile run --yes` in the background (Bash
   `run_in_background`); it is niced and sizes its jobs to the PC.
4. The `firmware-re` skill covers asking it questions afterwards.

## 5. Write the port

Wait for the research agents. If the snapshot or extract exists, start
one more subagent to draft the hardware map: it reads `SUMMARY.md`, the
`.dts` files and the `system/*.txt` facts (read-only) and returns, per
peripheral, the compatible, bus and address, IRQ/GPIO, supplies, firmware
file, stock driver and the mainline driver candidate, each with its file
as source. It copies no Samsung code.

Then, yourself:

1. **Identity.** Show the owner the values for `scripts/init-device`
   (vendor, codename, SoC id and name, device name, models, repo
   `exynos-linux/<vendor>-<codename>`) in one AskUserQuestion
   ("Use these", "Change something"). In the template run it; in a port
   whose identity is already set, skip it.
2. **config.toml** from the snapshot and research: `android.*`
   (`product_device`, `firmware_pattern` as a regex that matches the PDA,
   `fus_model`; `tested_firmware` stays empty until a boot chain is tested
   on it), `installer.*` (`main_disk`, `sector_size` from `block.txt`,
   partition names from `by-name.txt`, `boot_partition_bytes`; extend
   `protected` with every identity, key or bootloader partition this
   device has, never shorten it). Leave a value at its default when unsure
   and say so in the handoff. `scripts/config check` must pass.
3. **docs/HARDWARE.md**: every table filled, a source per row (snapshot
   file, DT node, GPL kernel path, URL), "?" where unverified. Mark the
   partitions the installer must never touch.
4. **README.md**: the port's section (what the device is, status
   `bring-up`, links to INSTALL/STATUS/PLAN). Keep the template's
   structure.
5. **docs/PLAN.md**: the template's phases, made concrete for this
   device: for each block, the upstream state from the research, the
   reference (GPL kernel file, sibling SoC driver, docs/re note), the
   size of the work (S/M/L), what it depends on. Order by dependency:
   unlock and backup, bring-up kernel (closest upstream SoC), USB console,
   storage, display, input, then the rest. Risks first (unlock
   availability, KnoxGuard, missing upstream clocks or pinctrl).
6. **docs/STATUS.md**: one row per block of HARDWARE.md, everything "—":
   nothing works until tested on the device.
7. **docs/AGENT-HANDOFF.md**: the state today (dated), where the snapshot
   and research are (paths only), the sources found, the next three steps
   from the plan, and what waits for the owner (unlock, a cable).
8. `docs/re/<subsystem>.md` only where decompilation already taught
   something: facts in our own words, with sources (docs/re/README.md).

Check: `scripts/config check`, `python3 -I tests/config/test_config.py`,
`bash tests/firmware/run.sh`, and `git status --porcelain` lists nothing
under `firmware/`.

## 6. Hand back

Tell the owner in a few lines: the device and SoC, what upstream already
has and what is missing, the biggest risk, the plan's first three steps,
and what they need to do physically. Commit locally only if asked; never
create the GitHub repo, push or change repo settings without their yes
(docs/PORTING.md lists those steps for them).
