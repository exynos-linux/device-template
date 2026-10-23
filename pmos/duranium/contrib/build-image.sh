#!/bin/sh
# Build one Duranium image of this port: UI (images.uis) x CHANNEL (release
# or dev), from the pmaports tree that ci/prepare put next to us, without
# pmbootstrap.
#
#  1. Build the port's packages (build-apks.sh) into $PKGS. Skip with
#     SKIP_APKS=1 (reuse what is in $PKGS, as CI does).
#  2. Run mkosi (in its container, scripts/mkosi-container) with $PKGS as an
#     extra package source.
#
# Output: mkosi.output/<device.id>_<UI>_<release>/ (disk image .raw, UKI
# .efi, split partitions; --profile=compressed for the published files).
#
# CHANNEL=dev (default): development image with images.dev_packages (the
# USB debug layer, in the base image and the initrd), updating from the
# "-dev" channel. CHANNEL=release: the public image without them. Both
# update from update.base (mkosi.finalize here).
#
# Environment: UI, CHANNEL, PKGS, PMAPORTS, MKOSI, SKIP_APKS, FRESH, LOCK.
# Extra arguments go to mkosi (e.g. --profile=compressed).
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=/dev/null
. "$HERE/config.env"
DUR=$(cd "$HERE/../.." && pwd)
WORK=$(cd "$DUR/.." && pwd)
PMAPORTS=$(cd "${PMAPORTS:-$DUR/pmaports}" && pwd -P)
PKGS=${PKGS:-$WORK/packages}
LOCK=${LOCK:-$WORK/build.lock}
UI=${UI:-$CFG_IMAGES_DEFAULT_UI}
RELEASE=$CFG_IMAGES_RELEASE
CHANNEL=${CHANNEL:-dev}
case " $CFG_IMAGES_UIS " in
*" $UI "*) ;;
*) echo "UI must be one of: $CFG_IMAGES_UIS (images.uis)" >&2; exit 1 ;;
esac
# comma separated: mkosi splits --environment= values at whitespace
extra=$(echo "$CFG_IMAGES_EXTRA_PACKAGES" | tr ' ' ,)
dev=$(echo "$CFG_IMAGES_DEV_PACKAGES" | tr ' ' ,)
case "$CHANNEL" in
dev) PORT_CHANNEL=dev; EXTRA=$extra${extra:+${dev:+,}}$dev ;;
release) PORT_CHANNEL=; EXTRA=$extra ;;
*) echo "CHANNEL must be dev or release" >&2; exit 1 ;;
esac

MKOSI=${MKOSI:-$DUR/scripts/mkosi-container}
export MKOSI
# The container must see the package directory and the symlinked pmaports
# at the same paths as the host. SELinux hosts: the bind mounts are not
# relabeled, so the build container runs unconfined. Pinned resolvers: a
# flaky local DNS forwarder killed long builds.
MKOSI_CONTAINER_ARGS="${MKOSI_CONTAINER_ARGS:-} --security-opt label=disable --dns=1.1.1.1 --dns=9.9.9.9 -v $PKGS:$PKGS:ro -v $PMAPORTS:$PMAPORTS:ro"
export MKOSI_CONTAINER_ARGS

if [ -z "${SKIP_APKS:-}" ]; then
	echo "== 1. port packages -> $PKGS"
	PKGS=$PKGS PMAPORTS=$PMAPORTS LOCK=$LOCK sh "$HERE/build-apks.sh"
fi
ls "$PKGS/$CFG_KERNEL_PACKAGE"-*.apk "$PKGS/$CFG_DEVICE_PACKAGE"-*.apk >/dev/null

echo "== 2. mkosi image"
if [ -e "$DUR/pmaports" ] && [ ! -L "$DUR/pmaports" ]; then
	echo "$DUR/pmaports is a directory, not ci/prepare's symlink; move it away first" >&2
	exit 1
fi
ln -sfn "$PMAPORTS" "$DUR/pmaports"
cd "$DUR"
[ -s mkosi.version ] || "$MKOSI" bump
IMAGE_ID="${CFG_DEVICE_ID}_${UI}_${RELEASE}"
# Once a build cached the repository metadata, do not refresh it: every
# sub-image ran "apk update" and any flaky lookup killed the build. FRESH=1
# refreshes on purpose (CI always does).
CACHE_ONLY=
if [ -z "${FRESH:-}" ] && ls mkosi.cache/*.metadata.cache >/dev/null 2>&1; then
	CACHE_ONLY=--cache-only=metadata
fi
log=$(mktemp)
trap 'rm -f "$log"' EXIT
for attempt in 1 2 3; do
	{
		rc=0
		# shellcheck disable=SC2086
		flock "$LOCK" nice -n 19 "$MKOSI" build \
			--force \
			--architecture=arm64 \
			--image-id="$IMAGE_ID" \
			--environment=PMOS_DEVICE="$CFG_DEVICE_ID" \
			--environment=PMOS_VARIANT="$UI" \
			--environment=PORT_CHANNEL="$PORT_CHANNEL" \
			--environment=DURANIUM_EXTRA_PACKAGES="$EXTRA" \
			--release="$RELEASE" \
			--package-directory="$PKGS" \
			$CACHE_ONLY \
			"$@" 2>&1 || rc=$?
		echo "MKOSI-EXIT $rc"
	} | tee "$log"
	rc=$(sed -n 's/^MKOSI-EXIT //p' "$log")
	[ "$rc" = 0 ] && break
	if [ "$attempt" -lt 3 ] &&
	   grep -qE "transient|Temporary failure|Could not resolve|timed out|Network unreachable" "$log"; then
		echo "== transient network failure (exit $rc), retrying ($attempt/3)" >&2
		sleep 20
		continue
	fi
	exit "$rc"
done

echo "Image in: $DUR/mkosi.output/$IMAGE_ID/"
ls -l "$DUR/mkosi.output/$IMAGE_ID/"
