# pmos/duranium/contrib: the port's image build layer

`ci/prepare` copies this directory into upstream duranium-build as
`contrib/<device.id>/`, next to:

- `config.env`: the resolved `config.toml` (`scripts/config shell`)
- `channels`: the update channels (`scripts/config channels`)
- `BUILD`: the aports to build (`pmos/aports/BUILD`)
- `sysupdate-public-key.asc`: the public half of the signing key

| File | What it does |
|---|---|
| `build-apks.sh` | builds the aports in `BUILD` (cross-native, in a postmarketOS container) into a flat `.apk` directory |
| `build-image.sh` | one image: `UI` x `CHANNEL` (release, dev), mkosi with that package directory |
| `mkosi.finalize` | device hook of duranium-build's `mkosi.finalize`: update server, keyring, channel file |
| `pkgbuilder.Containerfile` | the package builder image |
| `firmware/APKBUILD` | optional: a local-only vendor firmware package (never published) |

Nothing here knows the device: every value comes from `config.env`. Change
behaviour in `config.toml` first; edit these scripts only for something
config cannot express, and say why in the commit.
