# shellcheck shell=bash
# Hard limits on what the installer may ever write. Checked right before
# every heimdall flash, console write/discard and mkfs, independent of the
# flow that asks for it. The lists come from config.toml ([installer]
# protected, flash_allow, main_disk, userdata/metadata_partition); with a
# list missing every write is refused.
#
# The protected partitions hold the device's identity, keys and boot chain
# (EFS: IMEI/MAC/serial-bound data; PARAM/UP_PARAM: bootloader settings;
# PERSISTENT: factory reset protection; BOOTLOADER*/VBMETA*: the signed boot
# chain, an unsigned vbmeta leaves S-Boot stuck in Odin mode without USB;
# CPEFS; RPMB and the other storage LUNs). Losing any of them can brick
# the tablet or lose its calibration for good.

DENY_PARTS=${CFG_INSTALLER_PROTECTED:-}

# heimdall (Download mode): only these, by PIT name
HEIMDALL_ALLOW=${CFG_INSTALLER_FLASH_ALLOW:-}

# Linux console: only partitions of this whole-disk device (sda, mmcblk0)
MAIN_DISK=${CFG_INSTALLER_MAIN_DISK:-}
case $MAIN_DISK in
	*[0-9]) MAIN_PART_PREFIX=${MAIN_DISK}p ;;   # mmcblk0 -> mmcblk0p1
	*) MAIN_PART_PREFIX=$MAIN_DISK ;;            # sda -> sda1
esac

# Linux console (block devices, by GPT name): partition -> allowed operations
console_allowed_ops() {
	local n
	n=$(_lc "$1")
	if [ -n "${CFG_INSTALLER_USERDATA_PARTITION:-}" ] && [ "$n" = "$(_lc "$CFG_INSTALLER_USERDATA_PARTITION")" ]; then
		echo "put discard mkfs"
	elif [ -n "${CFG_INSTALLER_METADATA_PARTITION:-}" ] && [ "$n" = "$(_lc "$CFG_INSTALLER_METADATA_PARTITION")" ]; then
		echo "put discard"
	fi
}

_lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

is_denied_part() {
	local n p
	[ -n "$DENY_PARTS" ] || die "no protected partitions configured (installer.protected): refusing every write"
	n=$(_lc "$1")
	for p in $DENY_PARTS; do [ "$n" = "$p" ] && return 0; done
	return 1
}

# guard_heimdall NAME FILE
guard_heimdall() {
	local n=$1 a
	is_denied_part "$n" && die "refusing to flash the protected partition $n"
	[ -n "$HEIMDALL_ALLOW" ] || die "refusing to flash $n: no installer.flash_allow configured"
	for a in $HEIMDALL_ALLOW; do
		if [ "$n" = "$a" ]; then
			[ -s "$2" ] || dry || die "refusing to flash $n: $2 is missing or empty"
			return 0
		fi
	done
	die "refusing to flash $n: the installer only ever writes $HEIMDALL_ALLOW"
}

# guard_console_write OP DEVICE-PATH GPT-NAME
# GPT-NAME must come from the tablet itself (sysfs uevent PARTNAME), read
# just before the write.
guard_console_write() {
	local op=$1 dev=$2 name a
	name=$(_lc "${3:-}")
	case $dev in
		/dev/tty0|/run/*|/tmp/*)
			[ "$op" = put ] && return 0
			die "refusing $op on $dev" ;;
		/dev/"$MAIN_PART_PREFIX"[0-9]|/dev/"$MAIN_PART_PREFIX"[0-9][0-9])
			[ -n "$MAIN_DISK" ] || die "refusing $op on $dev: no installer.main_disk configured" ;;
		*) die "refusing $op on $dev: only partitions of the main storage (${MAIN_DISK:-none}) are ever touched" ;;
	esac
	[ -n "$name" ] || die "refusing $op on $dev: its partition name is unknown"
	is_denied_part "$name" && die "refusing $op on $dev: $name is a protected partition"
	for a in $(console_allowed_ops "$name"); do
		[ "$a" = "$op" ] && return 0
	done
	die "refusing $op on $dev ($name): not allowed"
}
