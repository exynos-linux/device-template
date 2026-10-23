# bootchain: the BOOT partition payload (optional, per device)

Samsung's S-Boot loads an Android boot image from BOOT. The ports put a
small chain there instead:

    S-Boot -> loader (uniLoader) -> U-Boot -> systemd-boot -> Duranium UKI
                                  \-> bring-up Linux (fallback, live env)

- `build.sh`: the device part of `ci/bootchain/build` (see its header)
- `<project>/`: patch series for each upstream project (uniLoader,
  U-Boot), each with a `BASE` file: `URL COMMIT` on one line
- the payload is published as the `bootchain.tag` release, signed like the
  images; the installer packs it with the owner's stock DTB and header
  values into their BOOT image (`scripts/installer/lib/bootimg.sh`)

Set `bootchain.enabled = true` in config.toml once `build.sh` works. No
Samsung file ever goes into the payload.
