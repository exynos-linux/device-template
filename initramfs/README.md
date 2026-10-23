# initramfs: the bring-up Linux's init (optional, per device)

The bring-up Linux is the first thing a port boots: a mainline kernel with
a tiny init built with the kernel's nolibc (no userspace at all). It is the
installer's live environment too, so the protocol below is a contract.

What every port's `init.c` must do:

1. Arm "reboot into Download mode" for any reset (Samsung PMU INFORM3 =
   0x12345671 on the SoCs so far), so a crash lands where the PC can flash
   the next build. Never leave the device with no way back.
2. Bring up a USB NCM gadget, device fe80::57:aff:fe00:1, host
   fe80::57:aff:fe00:2 (MACs 02:57:0a:00:00:01/02).
3. Serve the line console on TCP `console.port` (23): a `> ` prompt, one
   command per line; at least `dmesg`, `peek ADDR`, `dump ADDR N`, `poke
   ADDR VAL`, `put PATH SIZE` (binary upload), `run CMD`, `reboot
   [download|recovery]`. `scripts/installer/py/console.py` is the client.
4. If no USB host configures the gadget within a timeout, reboot into
   Download mode.

The SoC-specific parts (register bases, clock gates to force on, the USB
PHY / DWC3 / storage modules to load) are the port's. The first port's
`initramfs/init.c` (exynos-linux/samsung-gtactive3wifi, Exynos 9810) is
the reference implementation to copy from.
