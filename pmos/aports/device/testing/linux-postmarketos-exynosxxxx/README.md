# Kernel aport

- `APKBUILD`: torvalds/linux at `_base` + `@CODENAME@.patch`
- `@CODENAME@.patch`: the port's kernel branch, linearised (generated)
- `config-postmarketos-@SOC@.aarch64`: the full kernel config (generated)

Nothing here is edited by hand except `APKBUILD`'s comments and options:
the patch, the config, `pkgver`, `_commit`, `_base` and the checksums come
from the kernel branch (docs/PORTING.md, "Kernel"). A config fragment that
Duranium needs is in `docs/PORTING.md` too.
