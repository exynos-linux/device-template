# Releases, update channels and signing

## Channels

One GitHub release per channel, for every UI in `images.uis`:

| Channel tag | What |
|---|---|
| `<device.id>_<ui>_<release>` | release image: device-verified builds only |
| `<device.id>_<ui>_<release>-dev` | development image: every build, with the USB debug layer (root over USB without a password), marked pre-release |

`scripts/config channels` lists them. The tag is systemd-sysupdate's source
directory `%M_%W_%w` (IMAGE_ID, VARIANT_ID, VERSION_ID) plus `-dev`, so an
installed device fetches `<update.base><tag>/SHA256SUMS` and the files it
names. A device updates within its own UI and flavour; another UI is a
deliberate switch.

Each release holds the newest version and the one before it
(`channels.keep`): the UKI (`.efi`), the `/usr` image and its verity hash
tree, the extensions, and the full disk image `<prefix>_<version>.raw.zst`
for fresh installs.

## Versions

- Published: `YYMMDDNN` (UTC date + revision), always growing, above every
  version any channel ever had (`ci/state`).
- Local test builds: `<newest published + 1>~test<N>`, or anything with a
  `~`: it sorts below the plain version, so the next published update
  replaces a test build on its own. Never publish a `~` version
  (`ci/publish` refuses).
- `MIN_VERSION` (repository variable, or the workflow input) lifts the next
  published version above local builds that devices run.

## When CI builds

`images.yml` runs every 6 hours, on pushes to `config.toml`, `pmos/` or
`ci/`, and by hand. `ci/state` computes a fingerprint: postmarketOS's newest
published Duranium version (`upstream.version_url`) + a hash of everything
we maintain. A channel whose release notes carry another fingerprint gets a
build. So a new postmarketOS publish rebuilds every channel within hours,
with no action from anyone.

The release channels only build when `pmos/VERIFIED` names the exact
aports and duranium trees (`scripts/pmos-verify`, after an on-device pass).
Otherwise only the dev channels publish.

## Signing

- `scripts/new-signing-key` makes the key pair once: the public half is
  `pmos/sysupdate-public-key.asc` (committed; every image trusts exactly
  this key), the fingerprint goes into `update.fingerprint`, the private
  half into the repository secret `SYSUPDATE_SIGNING_KEY`.
- `ci/publish` signs each new `SHA256SUMS` (detached `SHA256SUMS.gpg`),
  refuses to replace a manifest that our key did not sign, uploads files
  before the manifest that names them and deletes old files only after the
  manifest stopped naming them.
- `ci/check-image` refuses an image whose keyring is not exactly our key,
  whose transfers point anywhere but its own channel, or (release) that
  contains any part of the debug layer.
- Losing the private key means no update can reach installed devices
  again; a new key means reinstalling them. Keep an offline copy.

## The records (GitHub Pages)

`pages.yml` publishes, at `update.pages`:

- `releases.json`: every channel with a valid signed manifest, its versions
  and files (name, size, sha256, url, kind); schema in `ci/pages`
- `channels/<tag>.json`: one channel each
- `device.json`: the resolved `config.toml` (what the org site shows)
- `sysupdate-public-key.asc`, `index.html`

The installer reads `releases.json` and still checks the signature itself.

## Vendor firmware

Never in a release, never in git. The installer takes it from the owner's
own stock firmware and leaves `<device.id>-firmware.tar.zst` on the ESP;
the device package imports it into `/var/lib/firmware` on the root
partition, which A/B updates never touch.
