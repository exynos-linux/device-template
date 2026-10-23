# shellcheck shell=bash
# Device hooks: the parts of the installer that are logic, not values.
#
# Values (model names, partition names, the firmware version pattern, URLs,
# ...) live in config.toml and reach the installer as CFG_* variables
# (scripts/config shell). What cannot be a value lives here: each port
# edits this file, and only this file, for its device. Every hook below has
# a safe default that works for a typical Samsung Exynos tablet without
# extra device knowledge; keep the defaults if they fit.
#
# Rules for every hook: never write to the tablet (the installer's guards
# in lib/guard.sh only cover the writes the installer itself makes), never
# weaken a check, and print with info/ok/warn/die (lib/ui.sh).
#
# Variables (read when a box or a wait needs them):
#   HINT_FORCE_RESTART  one line: how to force a restart with the buttons
#   HINT_DOWNLOAD       one line: how to reach Download mode with the buttons
#
# Hooks, in the order the installer calls them:
#
#   device_check_model MODEL DEVICE        android_inspect (stage 1, status)
#       ro.product.model / ro.product.device of the connected Android. Must
#       die for anything that is not this port's device. Default: MODEL is
#       one of device.models and DEVICE is android.product_device. A port
#       with sister models (LTE variants, ...) names them here so the user
#       gets a clear message.
#   device_check_hardware HWREV            android_inspect, after the model
#       ro.revision. Warn about untested hardware revisions or explain known
#       differences. Default: nothing.
#   device_unlock_steps                    unlock_guide (locked bootloader)
#       Prints the lines of the "Unlock the bootloader" box, one per line:
#       the buttons for Samsung's Device unlock mode.
#   device_download_steps                  to_download (no adb, no console)
#       Prints the lines of the "Put the tablet into Download mode" box.
#   device_firmware_vendor_dirs            firmware from adb / the vendor image
#       Prints the /vendor/etc subdirectories with firmware-like data that
#       are copied next to /vendor/firmware (space separated). Default:
#       "wifi nfc".
#   device_extra_firmware STOCK_KERNEL OUT fw_stage, when the stock boot image is known
#       STOCK_KERNEL is the kernel of your stock boot.img (a file); copy
#       blobs the stock kernel carried built in (CONFIG_EXTRA_FIRMWARE:
#       touch screen, pen, ...) into OUT (keeping their paths). Return
#       non-zero if there are none. Default: none.
#   device_firmware_stage SRC DEST         fw_stage
#       SRC holds what was collected: SRC/vendor/firmware/...,
#       SRC/vendor/etc/<dirs>/..., SRC/kernel-builtin/... (if any). Fill
#       DEST (empty, a lib/firmware tree) with the files under the names the
#       mainline drivers request. installer.required_firmware is checked in
#       DEST afterwards and installer.firmware_exclude is left out when it is
#       packed. Default: Android's names, unchanged (vendor/firmware/* and
#       kernel-builtin/* at the top of DEST).
#   device_reset_boot_record               install_duranium, before the boot chain
#       Over the live console, right before BOOT gets the Duranium boot
#       chain: put the payload's boot record (boot counting of uniLoader,
#       ...) into its "fresh install" state. Must not fail the install.
#       Default: nothing.
#
# Other parts that may need a port's attention but are not hooks: the boot
# image layout (lib/bootimg.sh builds an Android boot image header v2 with
# the DTB in BOOT) and the Samsung firmware tools under tools/.

HINT_FORCE_RESTART="Force restart: hold Power + Volume Down for 7-10 s."
HINT_DOWNLOAD="Download mode: force restart, then at once hold Volume Up + Volume Down and plug in the USB cable; press Volume Up at the warning."

device_check_model() {
	local model=$1 dev=$2 m
	for m in $CFG_DEVICE_MODELS; do
		[ "$model" = "$m" ] && [ "$dev" = "$CFG_ANDROID_PRODUCT_DEVICE" ] && return 0
	done
	# e.g. for a Wi-Fi-only port with LTE sister models:
	#   case $model in SM-T575*|SM-T577*) die "this is a $model (LTE): only the Wi-Fi model SM-T570 is supported" ;; esac
	die "this is not a $CFG_DEVICE_NAME ($CFG_DEVICE_MODELS): model '$model', device '$dev'"
}

device_check_hardware() {
	# e.g.
	#   case $1 in
	#       4) ;;
	#       5) info "hardware revision 5: another speaker amplifier; audio may differ" ;;
	#       *) warn "untested hardware revision '${1:-?}' (tested: 4)" ;;
	#   esac
	:
}

device_unlock_steps() {
	cat <<-'EOF'
		1. Power the tablet off (hold Power, tap Power off).
		2. Hold Volume Up + Volume Down and plug in the USB cable.
		3. A warning screen appears: LONG-press Volume Up for
		   "Device unlock mode".
		4. Press Volume Up to confirm "Unlock bootloader?".
		5. The tablet erases itself and restarts (a few minutes).
	EOF
}

device_download_steps() {
	cat <<-'EOF'
		1. Force restart: hold Power + Volume Down for 7-10 s.
		2. As soon as the screen goes black, hold Volume Up +
		   Volume Down and plug in the USB cable (if it is plugged
		   in, hold them while it restarts).
		3. At the warning screen press Volume Up.
	EOF
}

device_firmware_vendor_dirs() { echo "wifi nfc"; }

device_extra_firmware() {
	# e.g. the touch screen firmware the stock kernel had built in:
	#   python3 -I "$SETUP_REPO/tools/builtin_fw_extract.py" "$1" "$2" \
	#       tsp_himax/hx83102e_gtactive3.bin >> "$LOG_FILE" 2>&1
	return 1
}

device_firmware_stage() {
	local src=$1 dest=$2
	# e.g. a port's own index that renames Android's blobs for mainline:
	#   python3 -I "$SETUP_REPO/tools/fw_index.py" "$src" >> "$LOG_FILE" &&
	#       cp -a "$src/linux-firmware/lib/firmware/." "$dest/"
	cp -a "$src/vendor/firmware/." "$dest/" || return 1
	[ -d "$src/kernel-builtin" ] && cp -a "$src/kernel-builtin/." "$dest/"
	return 0
}

device_reset_boot_record() {
	# e.g. uniLoader's boot record in a reserved DRAM word (the address is
	# the device's):  con_cmd "poke 0x8ff1ff04c 3" >/dev/null 2>&1 || true
	:
}
