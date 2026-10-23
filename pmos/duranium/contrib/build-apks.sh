#!/bin/sh
# Build the port's packages that are not in the postmarketOS binary
# repository (pmos/aports/BUILD, copied here as BUILD by ci/prepare) from the
# pmaports tree, without pmbootstrap.
#
# They are built in an x86_64 postmarketOS container (pkgbuilder.
# Containerfile) with CARCH=aarch64, the kernel and any C helpers with the
# aarch64 cross compiler, like pmbootstrap's "cross-native" mode: no
# qemu-user emulation. Output: a flat directory of .apk files for mkosi's
# --package-directory.
#
# The vendor firmware package (firmware/APKBUILD here, optional) is only
# built when the extracted vendor firmware is present (FIRMWARE_DIR). It is
# proprietary: the .apk stays in the local package directory, outside every
# git tree, and is never published.
#
# Usage: build-apks.sh [aport ...]   (default: everything in BUILD)
# Environment (defaults below): PMAPORTS, PKGS, DISTFILES, CCACHE, LOCK,
# FIRMWARE_DIR, BUILDER, JOBS.
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=/dev/null
. "$HERE/config.env"
WORK=$(cd "$HERE/../../.." && pwd)
PMAPORTS=${PMAPORTS:-$HERE/../../pmaports}
PKGS=${PKGS:-$WORK/packages}
DISTFILES=${DISTFILES:-$WORK/distfiles}
CCACHE=${CCACHE:-$WORK/ccache}
LOCK=${LOCK:-$WORK/build.lock}
FIRMWARE_DIR=${FIRMWARE_DIR:-$WORK/../../firmware/extracted/lib/firmware}
BUILDER=${BUILDER:-$CFG_DEVICE_ID-pkgbuilder}
JOBS=${JOBS:-$(nproc)}

if [ $# -eq 0 ]; then
	# shellcheck disable=SC2046 # one aport per line
	set -- $(grep -v '^#' "$HERE/BUILD")
	[ -d "$FIRMWARE_DIR" ] && [ -f "$HERE/firmware/APKBUILD" ] && set -- "$@" firmware
fi

# rebuild the builder whenever its Containerfile changes
want=$(sha256sum "$HERE/pkgbuilder.Containerfile" | cut -c1-12)
have=$(podman image inspect -f '{{index .Labels "port.containerfile"}}' "$BUILDER" 2>/dev/null || true)
[ "$want" = "$have" ] ||
	podman build -t "$BUILDER" --label port.containerfile="$want" \
		-f "$HERE/pkgbuilder.Containerfile" "$HERE"

mkdir -p "$PKGS" "$DISTFILES" "$CCACHE"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/repo" "$work/out"

cat > "$work/build.sh" <<'IN'
#!/bin/sh
set -eu
abuild-keygen -a -i -n -q >/dev/null 2>&1
export CARCH=aarch64 SRCDEST=/distfiles JOBS
export MAKEFLAGS="-j$JOBS"
for p in "$@"; do
	case "$p" in
	firmware) src=/contrib/firmware; export FIRMWARE_DIR=/firmware ;;
	*) src="/pmaports/$p" ;;
	esac
	name=$(basename "$p")
	echo "=== $name"
	rm -rf /b && mkdir -p /b && cp -r "$src" "/b/$name"
	# a kernel aport may build from a local snapshot of the live-tested
	# branch (linux-<codename>-<commit>.tar.gz in the distfiles cache)
	# instead of downloading the upstream base + patch
	if grep -q "linux-$CODENAME-[0-9a-f]*\.tar\.gz" "/b/$name/APKBUILD"; then
		cp /distfiles/linux-"$CODENAME"-*.tar.gz "/b/$name/"
	fi
	cd "/b/$name"
	case "$name" in
	firmware) ;;
	*) abuild -F verify ;;
	esac
	# cross-native: compile with the aarch64 cross compiler on the host CPU;
	# the kernel through ccache (persistent /ccache, path independent, as
	# every snapshot unpacks to a new directory)
	cc=aarch64-alpine-linux-musl-gcc
	case "$name" in
	linux-*) cc="ccache $cc" ;;
	esac
	CROSS_COMPILE=aarch64-alpine-linux-musl- CC="$cc" \
		abuild -F -d -P /repo -D postmarketOS
done
find /repo -name '*.apk' -exec cp {} /out/ \;
IN
chmod +x "$work/build.sh"

fwmount=""
[ -d "$FIRMWARE_DIR" ] && fwmount="-v $FIRMWARE_DIR:/firmware:ro,Z"
# shellcheck disable=SC2086
flock "$LOCK" nice -n 19 podman run --rm --entrypoint /bin/sh \
	-e JOBS="$JOBS" -e CODENAME="$CFG_DEVICE_CODENAME" \
	-v "$CCACHE:/ccache:Z" -e CCACHE_DIR=/ccache -e CCACHE_NOHASHDIR=1 \
	-e CCACHE_BASEDIR=/b -e CCACHE_MAXSIZE=15G -e CCACHE_SLOPPINESS=time_macros,include_file_mtime,include_file_ctime \
	-v "$PMAPORTS:/pmaports:ro,Z" -v "$HERE:/contrib:ro,Z" $fwmount \
	-v "$DISTFILES:/distfiles:Z" -v "$work/repo:/repo:Z" -v "$work:/s:Z" \
	-v "$work/out:/out:Z" \
	"$BUILDER" /s/build.sh "$@"

# Replace only the packages that were rebuilt (and their old versions)
for apk in "$work"/out/*.apk; do
	[ -e "$apk" ] || continue
	n=$(basename "$apk" | sed 's/-[0-9][^-]*-r[0-9]*\.apk$//')
	rm -f "$PKGS/$n"-[0-9]*.apk
	cp "$apk" "$PKGS/"
done
ls -l "$PKGS"
