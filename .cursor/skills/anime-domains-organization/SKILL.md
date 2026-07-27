---
name: anime-domains-organization
description: >-
  Where files go in AnimeDomains (src/ layers, Rojo mounts, Services vs Constants
  vs Networker vs Workers). Use when creating modules, deciding paths, adding a
  domain, or asking where something should live.
---

# AnimeDomains organization

Source of truth on disk: **`src/`**. Runtime: **`ReplicatedStorage.Shareds.*`** (and SSS for server boots/services).

## Layers

| Disk | Runtime | Role |
|---|---|---|
| `src/Boot/` | SSS / client boots | Start services — no domain logic |
| `src/Services/<Domain>/` | `Shareds.Services.<Domain>` | Gameplay domains (Cards, Energy, Gameplay…) |
| `src/Constants/` | `Shareds.Constants` | Shared catalogs / PlayerData template |
| `src/Networker/` | `Shareds.Networker` | Debi channels (`.debi` + generated Client/Server) |
| `src/Workers/` | `Shareds.Workers` | Shared wrappers (DataServiceV2 facade, EntityHelper…) |
| `src/Utils/` | `Shareds.Utils` | Pure helpers (Math, Assets, Animation…) |
| `src/Modules/` | `Shareds.Modules` | Cross-cutting infra (UIModule…) — **not** domain |
| `src/Classes/` | `Shareds.Classes` | Mega/jecs World, Tree MetaData, unit datas |
| `src/Handlers/` | SSS Handlers | Thin Cmdr commands, glue |
| `Packages/` | `ReplicatedStorage.Packages` | Wally deps |

## Placement rules

- New feature domain → `src/Services/<Name>/` (+ types/utils client/server as needed)
- Persist player fields → `Constants/Datas/PlayerData.luau` + DataService Paths
- Match remotes → edit `src/Networker/<Channel>/*.debi`, regenerate — don’t hand-edit generated
- Shared math/assets → `Utils/`; don’t duplicate in Services
- Deny codes / domain tuning → under that Service, **not** PrimaryDatas

## Rojo notes

- `default.project.json` maps folders/files explicitly for many Services
- Adding a new Service file often needs a `$path` entry (or regenerate tree tool if used)
- Assets live in Studio `ReplicatedStorage.Assets` (not always Rojo)

## Related

- `AGENT.md` layout sections
- Skill `debi-networker` for remotes
- Skill `dataservicev2` for saves
