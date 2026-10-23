# Agent handoff: @DEVICE_NAME@ (read this first)

A coding agent keeps this file current: what is true now, what is next.
Newest state on top; trim history that no longer matters. Facts that live
elsewhere (config.toml, docs/STATUS.md, git log) are linked, not copied.

## State YYYY-MM-DD HH:MM (who)

- Device: what is installed (slot A/B versions, boot chain), how it is
  connected, anything a person must do
- Kernel: branch, candidate, what is tested
- Packages / images: newest local and published versions
- Open: the next three things, each with where it stands
- Waiting for the owner (physical actions): ...

## Who / what

- Device: @DEVICE_NAME@ (@MODEL@), @SOC_NAME@
- Repo: https://github.com/@REPO@ (config in `config.toml`)
- Mission: postmarketOS Duranium with every piece of hardware working and
  verified on the device; signed images per UI, rebuilt automatically on
  postmarketOS publishes; the port maintains kernel, drivers and device
  packages only.

## Standing rules

See `CLAUDE.md` and `.claude/rules/`. Device rules from the owner go here,
in their words, with the date.
