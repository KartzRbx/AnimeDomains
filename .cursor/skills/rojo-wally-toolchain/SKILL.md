---
name: rojo-wally-toolchain
description: >-
  Rojo 7, Wally, and Rokit workflow for AnimeDomains (sync, sourcemap, install
  packages). Use when setting up the project, adding Wally deps, regenerating
  sourcemap, or debugging Rojo/Wally sync.
---

# Rojo / Wally / Rokit

## Versions (rokit.toml)

- `rojo` 7.6.1
- `wally` 0.3.2

## Everyday commands

```bash
rokit install
wally install
rojo sourcemap default.project.json -o sourcemap.json
# optional if installed:
# wally-package-types --sourcemap sourcemap.json Packages/
rojo serve   # or npm run / project script if present
```

## Roles

| Tool | Job |
|---|---|
| **Rokit** | Pins CLI tools |
| **Wally** | Luau packages → `Packages/` → `ReplicatedStorage.Packages` |
| **Rojo** | Syncs `src/` ↔ Studio via `default.project.json` |

## Wally

- Declare deps in `wally.toml` `[dependencies]`
- Require: `ReplicatedStorage.Packages.<alias>`
- Hyphen names: `Packages["vfx-util"]`

## Rojo pitfalls

- New ModuleScript under a folder that is **not** `$path`-mapped as a whole may need an explicit project entry
- Don’t edit Studio copies of Rojo-managed scripts — edit `src/`
- Sourcemap must be refreshed after structural changes for Luau LSP

## Related

- Package skills under `.cursor/skills/<package>/`
- `anime-domains-organization`
