# Package builder for the port's aports (pmos/aports), without pmbootstrap.
#
# x86_64 postmarketOS edge with the cross compiler that pmbootstrap uses for
# its "cross-native" kernel builds (gcc-aarch64 from the postmarketOS
# repository), the usual kernel aport makedepends and
# devicepkg-dev. Add what your aports need to the first RUN. Everything is built natively on the host CPU with
# CARCH=aarch64, so no qemu-user emulation is involved.
FROM gitlab.postmarketos.org:5050/postmarketos/docker-postmarketos:edge

RUN apk add --no-cache \
	alpine-sdk \
	gcc-aarch64 \
	binutils-aarch64 \
	devicepkg-dev \
	bash bc bison elfutils-dev findutils flex gmp-dev linux-headers \
	mpc1-dev mpfr-dev openssl-dev pahole perl python3 zstd \
	postmarketos-installkernel \
	dtc \
	ccache

# aarch64 musl + kernel headers in the cross compiler's sysroot, for the
# device package's small C helper (like pmbootstrap's cross-native2 sysroot).
# --no-scripts: nothing from the target architecture is executed.
RUN apk add --root /usr/aarch64-alpine-linux-musl --arch aarch64 --initdb \
	--no-scripts --no-cache --allow-untrusted \
	--repositories-file /etc/apk/repositories \
	musl-dev linux-headers
