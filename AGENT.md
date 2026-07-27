# Agent Guide — Luau / Roblox Style

Mandatory guide for AI agents and developers working in repositories that follow this programming style. Describes **conventions, priorities, and agent behavior** — not a specific game or product.

For detailed architecture of the current repository, see [Docs/FRAMEWORK.md](Docs/FRAMEWORK.md) when it exists in the project.

---

## Bootstrap — recreate the full environment

This `AGENT.md` is the **source of truth** for the style. With a single command the agent recreates the entire workspace (Rojo, Rokit, Wally, Selene, `sourcemap`, `src/`, `.cursor/`, docs).

### Commands that trigger bootstrap

- `bootstrap framework`
- `setup framework` / `inicie o ambiente` / `configurar framework`
- `criar projeto roblox` / `scaffold framework`

### What the agent must do

1. Read and execute **`.cursor/skills/bootstrap-framework/SKILL.md`**
2. Copy templates from `.cursor/skills/bootstrap-framework/templates/` to the project root
3. Replace `{{PROJECT_NAME}}` and `{{WALLY_PACKAGE}}` in the configs
4. Run: `rokit install` → `wally install` → `rojo sourcemap default.project.json -o sourcemap.json` → `rojo build` (verify) → `rojo plugin install`

### Minimum seed (new / empty repository)

Copy only these two items into the project folder:

```
AGENT.md
.cursor/skills/bootstrap-framework/    # includes templates/
```

Then: **bootstrap framework**. The agent delivers the rest.

### Expected deliverable after bootstrap

| Item | Origin |
|---|---|
| `default.project.json`, `rokit.toml`, `wally.toml`, `selene.toml`, `.gitignore` | templates |
| `src/` skeleton (Boots, PlayerData, DataServiceV2, Networking, …) | templates |
| `Docs/FRAMEWORK.md`, `AGENT.md` | templates |
| `.cursor/skills/` + `.cursor/learnings/` | templates |
| `Packages/` | `wally install` (gitignored) |
| `wally.lock` | `wally install` |
| `sourcemap.json` | `rojo sourcemap` |

**Keep templates up to date:** when evolving the framework in this canonical repository, sync `.cursor/skills/bootstrap-framework/templates/` with the changes.

---

## Overview

Projects with this style are **Roblox (Luau)** games synced via **Rojo**, with explicit layers and strict typing. Priorities when generating code:

1. Layered architecture (Boot → Services → Handlers / Controllers)
2. Strict typing (`--!strict`, semantic `export type`, `const`)
3. Explicit lifecycle (`:Init()` / `:init()` — never side effects in `require`)
4. Performance on hot paths (pooling, cache, minimal networking)
5. Server as the source of truth

**Central rule:** `require` does **not** register listeners, does **not** mutate data, and does **not** touch game instances. All of that happens only after `:Init()` (server/controllers) or `:init()` (`*ServiceClient`).

---

## Author style — hand-written code (mandatory)

The owner programs **by hand**. Their code is the source of truth for *how* things are written in a file — not the agent's preferred organization.

### Agent must

1. **Match the author's existing style** in the file being edited: naming, `const`/`local` choices already present, spacing, section markers, stub shapes, incomplete helpers they are mid-writing.
2. **Only change what was asked.** Do not rewrite, reorganize, "clean up", rename, or restructure surrounding code for taste.
3. **Preserve bindings as written** — if the author used `const`, keep `const`. Never silently swap `const` ↔ `local` (or `const function` ↔ `local function`) unless they asked.
4. **Leave WIP alone** — empty function bodies, `TODO`, partial `ClockTimeEffect`-style stubs, commented blocks: fill or touch them only when requested.
5. When adding **new** code in a file the author owns, **mirror their patterns** in that file even if AGENT.md would prefer a stricter layout elsewhere.

### Agent must not

- "Improve organization" of hand-written modules without an explicit request
- Replace the author's structure with a full rewrite during a small fix
- Impose agent formatting preferences over the author's established voice in that file

> **Priority:** Author hand style in the open file **wins** over the agent's idea of cleaner code. Framework rules in this guide still apply for *new* architecture (Services, Networker, `--!strict`, no side effects in `require`) — but style/organization of *existing* hand code is not the agent's to redesign.

---

## Cursor Skills

### `.cursor/` organization

Standard repository structure. **Never** create skills in `~/.cursor/skills-cursor/` (reserved for Cursor).

```
.cursor/
├── skills/                    # Project skills (versioned in git)
│   ├── packages-index/        # Index of package/tool skills
│   ├── author-hand-programming/ # Owner hand-coding voice
│   ├── respect-author-hand-style/  # Never rewrite owner's hand voice
│   ├── anime-domains-organization/ # src/ placement rules
│   ├── rojo-wally-toolchain/  # Rojo + Wally + Rokit
│   ├── debi-networker/        # Typed Debi remotes
│   ├── janitor/ · signal/ · jecs/ · dataservicev2/ · cmdr/
│   ├── topbarplus/ · simplepath/ · spring/ · display/
│   ├── module3d/ · stickybillboard/ · ezvisualz/
│   ├── formatnumber/ · vfx-util/ · jabby/
│   ├── bootstrap-framework/   # Recreate full environment — templates/
│   ├── roblox-framework/      # Entry — read first on Luau tasks
│   ├── add-domain/
│   ├── luau-style/
│   ├── jecs-ecs/              # Tower/Unit entities (jecs ECS)
│   ├── anime-domains-layout/  # Where to put files in this game
│   ├── arena-maps/            # FlorestMap / Clash-like Maps pattern
│   ├── entity-animations/     # Idle/Walk + AnimationResolveUtils / Signal
│   ├── quicknet-handler/      # Legacy — gameplay uses typed Networker
│   ├── extend-player-data/
│   ├── learning-mode/         # Learning mode — always active
│   └── <new-skill>/          # One folder per skill
│       ├── SKILL.md           # Required
│       ├── reference.md       # Optional — long details
│       └── examples.md        # Optional — examples
└── learnings/                 # Fixed mistakes (learning mode)
    ├── index.md               # Index — read before coding
    └── <slug>.md              # One file per learned lesson
```

#### Rules for creating or editing skills

| Rule | Detail |
|---|---|
| **Location** | Only in `.cursor/skills/<name>/` |
| **Name** | lowercase, hyphens, max 64 chars (`add-domain`, `luau-style`) |
| **SKILL.md** | YAML frontmatter with `name` + `description` (third person, WHEN + WHAT) |
| **Size** | Concise SKILL.md (< 500 lines); details in `reference.md` |
| **Scope** | One skill = one clear workflow or domain |
| **Duplication** | Do not repeat all of `AGENT.md` — summarize and link |
| **New skill** | Prefer extending an existing skill; create a new one only for a distinct workflow |
| **Promotion** | Pattern repeated 3× in `learnings/` → promote to skill or `AGENT.md` |

#### When to create a new skill vs learning

| Situation | Where to register |
|---|---|
| Error fixed once | `.cursor/learnings/<slug>.md` |
| New workflow (e.g. deploy, save migration) | `.cursor/skills/<name>/SKILL.md` |
| One-off rule that repeats | `learnings/` first → promote to skill |
| Global style rule | `AGENT.md` or `Docs/FRAMEWORK.md` |

#### Reading order (code tasks)

1. `.cursor/learnings/index.md` (+ relevant files)
2. `.cursor/skills/roblox-framework`
3. Specific skill (`add-domain`, `quicknet-handler`, …)
4. `.cursor/skills/learning-mode` (when fixing an error)
5. `AGENT.md` → `Docs/FRAMEWORK.md`

---

### Learning mode (always active)

Whenever you **fix an error** (runtime, strict, user review, failed build), the agent must:

1. Identify the **root cause** — not just the symptom
2. Fix the code
3. Document in `.cursor/learnings/<slug>.md` using the `learning-mode` skill template
4. Update `.cursor/learnings/index.md` with a row in the table
5. If the same pattern appears **3 times**, promote the rule to the corresponding skill or `AGENT.md`

**Before coding:** read `index.md` and learnings with tags related to the task.

---

### Project skills (`.cursor/skills/`)

Read `SKILL.md` before applying. These skills are **specific to this framework** and take priority on Luau code tasks.

| Skill | When to use |
|---|---|
| **packages-index** | Which package/tool skill to open |
| **author-hand-programming** | Owner hand style — match voice, no rewrite |
| **respect-author-hand-style** | Same (short) — editing author-owned modules |
| **anime-domains-organization** | Where to put a file under `src/` |
| **rojo-wally-toolchain** | Rojo sync, Wally install, Rokit, sourcemap |
| **debi-networker** | `.debi` remotes, Fire/SetCallback/On |
| **janitor** | Cleanup / connections / `:Remove` quirk |
| **signal** | Custom events (Completed, etc.) |
| **jecs** | ECS World / components / queries |
| **dataservicev2** | Player save Get/Set / Paths |
| **cmdr** | Admin/debug commands |
| **topbarplus** | Client topbar icons |
| **simplepath** | Pathfinding agents |
| **spring** | Scalar spring Step/Set |
| **display** | Debug pretty-print |
| **module3d** | ViewportFrame 3D previews |
| **stickybillboard** | On-screen billboard clamp |
| **ezvisualz** | UI gradient presets |
| **formatnumber** | Number formatting / NumberFormater |
| **vfx-util** | Particle emit helpers |
| **jabby** | jecs debugger (dev) |
| **bootstrap-framework** | `bootstrap framework` — recreate workspace from scratch |
| **roblox-framework** | Any code in `src/` — read first |
| **anime-domains-layout** | Where to put a file / Studio map / match flow |
| **arena-maps** | New map / FlorestMap / Build+Teams / BuildMap |
| **entity-animations** | Entity anims + AnimationResolveUtils + Signal |
| **jecs-ecs** | Tower, Unit, Primitive, MetaData, World jecs |
| **add-domain** | New system/domain (shop, inventory, units, …) |
| **luau-style** | Create or edit `.luau` modules |
| **quicknet-handler** | Legacy / DataService — gameplay uses typed **Networker** |
| **extend-player-data** | New fields in the save / `PlayerData.luau` |
| **learning-mode** | Always active — document fixes, read learnings before coding |

**Order:** `learnings/index.md` → `author-hand-programming` / `respect-author-hand-style` → `packages-index` (if tooling) → `anime-domains-organization` → package skill → `AGENT.md`.

### Built-in Cursor skills (`~/.cursor/skills-cursor/`)

Use when the task asks for or fits them — read `SKILL.md` before invoking.

| Skill | When to use |
|---|---|
| **babysit** | PR with pending comments, failing CI, merge conflicts — make merge-ready |
| **review-bugbot** | User asks for code review / `/review-bugbot` — launch Bugbot subagent |
| **review-security** | User asks for security review of local changes |
| **split-to-prs** | Split a branch or large work into small reviewable PRs |
| **create-rule** | Create or update rules in `.cursor/rules/` or the project's `AGENT.md` |
| **create-skill** | Author a new custom skill (`SKILL.md`) |
| **create-hook** | Automate agent events via `hooks.json` |
| **canvas** | Rich analytical deliverable (tables, timelines, audits, MCP data) |

### Use only if the user asks explicitly

| Skill | When to use |
|---|---|
| **sdk** | Integration with `@cursor/sdk` / `cursor-sdk` outside the IDE |
| **automate** | Create Cursor Automations |
| **loop** | Recurring prompt (`/loop`) |
| **statusline** | Customize CLI status line |
| **update-cursor-settings** | Change editor `settings.json` |
| **migrate-to-skills** | Migrate old rules to skill format |

### Do not use by default for Luau code

Do not invoke tooling/editor skills when the task is implementing features — use the project skills above.

**Reading order for code tasks:** `.cursor/learnings/index.md` → `roblox-framework` → specific skill → `learning-mode` (when fixing) → `AGENT.md` → `Docs/FRAMEWORK.md`.

---

## Character (R6)

Projects with this style assume **R6 rig** — not R15.

| Setting | Value |
|---|---|
| **Rig** | R6 (`StarterPlayer` → `Character Rig Type` = R6 in Studio) |
| **Parts** | `Head`, `Torso`, `Left Arm`, `Right Arm`, `Left Leg`, `Right Leg` |
| **Humanoid** | `RigType = Enum.HumanoidRigType.R6` |

**Rules for code and assets:**

- Animations, meshes, and accessories compatible with **R6** only.
- Do not reference R15-exclusive parts (`UpperTorso`, `LowerTorso`, `LeftUpperArm`, …).
- Weld/attach to `Torso` or R6 limbs; `HumanoidRootPart` exists, but visible limbs follow the R6 skeleton.
- NPCs and pets that mimic the player must use the same R6 format.

---

## Toolchain

| Tool | File | Use |
|---|---|---|
| **Rojo** | `default.project.json` | Sync filesystem ↔ Studio |
| **Rokit** | `rokit.toml` | CLI manager (rojo, wally) |
| **Wally** | `wally.toml` | Luau dependencies → `Packages/` |
| **Selene** | `selene.toml` | Linter (Roblox std) |

```bash
rokit install
wally install
rojo serve
rojo plugin install   # keep Studio plugin on the same version as the CLI
```

---

## Package stack (Wally)

When the repository uses Wally, access via `ReplicatedStorage.Packages`. Local persistence wrapper via `ReplicatedStorage.DataServiceV2` (do not use the raw package in game code).

| Package | Require | Use |
|---|---|---|
| `dataservicev2` | `ReplicatedStorage.DataServiceV2` | Persistence + player data replication |
| `jecs` | `Packages.jecs` | ECS — `src/Classes` (Tower, Unit, Primitives) |
| `signal` | `Packages.signal` | Custom events (AnimationPlayer Played/Paused) |
| `janitor` | `Packages.janitor` | Clean up connections, tweens, and callbacks |
| `simplepath` | `Packages.simplepath` | Unit pathing (`Path:Run` / `Stop`) |
| `cmdr` | server + client boot | Admin console (dev/ops) |
| `ezvisualz` | `Packages.ezvisualz` | Gradients and shine in UI |
| `spring` | `Packages.spring` | Spring animations |
| `display` | `Packages.display` | Display helpers |
| `module3d` | `Packages.module3d` | 3D manipulation |
| `stickybillboard` | `Packages.stickybillboard` | Anchored billboards |
| `formatnumber` | `Packages.formatnumber` or `Utils.FormatNumber` | Number formatting |
| `vfx-util` | `Packages.vfx-util` | VFX utilities |
| `topbarplus` | `Packages.topbarplus` | Client topbar buttons |

```luau
--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Janitor = require(ReplicatedStorage.Packages.janitor)
const Networker = require(ReplicatedStorage.Shareds.Networker)
const jecs = require(ReplicatedStorage.Packages.jecs)
const Signal = require(ReplicatedStorage.Packages.signal)
const DataServiceV2 = require(ReplicatedStorage.DataServiceV2)
```

> **Anime Domains:** gameplay net = typed Networker (`src/Networker/`, leif-style + Luau types + `@native` on hot paths); combat = jecs; anim events = Signal. QuickNet is not a gameplay dependency (may exist only inside DataServiceV2). Check `wally.toml`.

---

## Project structure

### Important rule: filesystem != final Studio tree

The new organization of this repository is **flat under `src/`**. The agent must decide where to save files by looking first at the **filesystem**, and only then consider where `default.project.json` mounts that into the Roblox DataModel.

```
src/
├── Boot/                           # .server/.client entry points
├── Classes/                        # ECS / component tree / metadata
├── Constants/
│   ├── Datas/                      # Gameplay catalogs + PlayerData
│   └── PrimaryDatas/               # Icons, rarities, global items
├── Controllers/                    # Placeholder for LocalScripts/controllers
├── Handlers/                       # Placeholder for thin integration scripts
├── Modules/                        # Shared / cross-cutting infra
├── Networker/                      # Typed Networker (leif-style) — one remote per Service
├── Services/                       # Domain services
├── Utils/                          # Pure helpers
└── Workers/                        # Shared wrappers/infra (e.g. DataServiceV2)
```

### Current Studio mapping (`default.project.json`)

| Filesystem | Studio runtime | Role |
|---|---|---|
| `src/Boot/Server.server.luau` | `ServerScriptService.Boot.Server` | Server boot |
| `src/Boot/Client.client.luau` | `StarterPlayer.StarterPlayerScripts.Boot.Client` | Client boot |
| `src/Services/` | `ReplicatedStorage.Shareds.Services` | Domains and shared services |
| `src/Constants/` | `ReplicatedStorage.Shareds.Constants` | Static data |
| `src/Classes/` | `ReplicatedStorage.Shareds.Classes` | jecs, primitives, metadata |
| `src/Modules/` | `ReplicatedStorage.Shareds.Modules` | Shared infra |
| `src/Networker/` | `ReplicatedStorage.Shareds.Networker` | Typed server/client Networker |
| `src/Workers/` | `ReplicatedStorage.Shareds.Workers` | Wrappers such as `DataServiceV2` |
| `src/Utils/` | `ReplicatedStorage.Shareds.Utils` | Pure helpers |

### How to decide where to edit

| Layer | Repo path | Runtime path | Responsibility |
|---|---|---|---|
| **Boot** | `src/Boot/` | `ServerScriptService.Boot` / `StarterPlayerScripts.Boot` | Single entry point; calls `:Init()` / `:init()` |
| **Services** | `src/Services/` | `ReplicatedStorage.Shareds.Services` | Authority and domain logic |
| **Handlers** | `src/Handlers/` | not mounted yet | Thin scripts that connect platform/network → Service |
| **Controllers** | `src/Controllers/` | not mounted yet | Local infra and client orchestration |
| **Classes** | `src/Classes/` | `ReplicatedStorage.Shareds.Classes` | jecs: components, metadata, entity helpers |
| **Constants** | `src/Constants/` | `ReplicatedStorage.Shareds.Constants` | Catalogs, save template, static data |
| **Modules** | `src/Modules/` | `ReplicatedStorage.Shareds.Modules` | Cross-cutting UI/UX infra |
| **Utils** | `src/Utils/` | `ReplicatedStorage.Shareds.Utils` | Generic pure functions |
| **Workers** | `src/Workers/` | `ReplicatedStorage.Shareds.Workers` | Wrappers and shared infrastructure |

**Agent rule:** when referring to a path for create/edit, prefer `src/...`. When showing `require`, use the real **runtime** path under `ReplicatedStorage.Shareds...`.

---

## Where to put code — Modules vs Services vs PrimaryDatas

Central rule in the new organization: **domain goes in `src/Services/`**; **general game data in `src/Constants/PrimaryDatas/`**; **`src/Modules/` only for shared infra**. At runtime this still appears under `ReplicatedStorage.Shareds.*`.

### `src/Modules/` — shared infra

Only cross-cutting UI/UX/feedback facades used by **multiple** domains:

| Module | Use |
|---|---|
| **`GuiModule`** | Hover, open/close of central interfaces |
| **`NotificationModule`** | Toasts and notification queue |
| **`TransitionModule`** | Fullscreen grid transition (In/Out) |
| **`SoundModule`** | `playInterface`, `playClick`, `playGame`, `playMovement` |
| **`NumberModule`** | Number formatting + animation (`animateNumber`, `playDropEffect`) |
| **`PopupModule`** | Physical and currency popups |
| **`EzVisualzGradientModule`** | Shine/gradient on `GuiObject` |
| **`CameraShakeModule`** | Reusable camera shake |

**Do not** put here: `UnitsModule`, `GachaModule`, `ComboCombatModule`, `PotionHudModule`, deny codes, service settings, etc.

### `src/Services/<Domínio>/` — everything for the domain

Each domain folder (`Units`, `Click`, `Gacha`, `Potion`, `Enemy`, `Rebirth`, `Island`, `Settings`, `Movement`, …) groups:

| Type | Examples |
|---|---|
| **Client singleton** | `UnitsServiceClient`, `ClickServiceClient`, `GachaServiceClient` |
| **Utils** | `UnitFollowerServiceUtils`, `ClickPowerUtils`, `EnemyServiceUtils` |
| **Domain module** | `UnitsModule`, `GachaModule`, `ComboCombatModule`, `PotionHudModule` |
| **Service constants** | `PotionDenyCodes`, `UnitsDenyCodes`, `Click.luau`, `Combo.luau`, `Gacha.luau`, `Rebirth.luau`, `Multipliers.luau` |

```luau
const UnitsModule = require(ReplicatedStorage.Shareds.Services.Units.UnitsModule)
const PotionDenyCodes = require(ReplicatedStorage.Shareds.Services.Potion.PotionDenyCodes)
const ComboSettings = require(ReplicatedStorage.Shareds.Services.Click.Combo)
```

### `src/Constants/PrimaryDatas/` — general game data

Only **cross-cutting** catalogs and assets, with no coupling to a single service:

| File | Use |
|---|---|
| **`Icons`** | Icon asset IDs (coins, islands, potions, HUD, …) |
| **`Raritys`** | Rarity definitions (color, name, order) |
| **`Items`** | Global item catalog (references Icons + Raritys) |
| **`Notifications`** | Notification duration, gradients, and limits |
| **`_RobuxIcon`**, **`_PremiumIcon`**, **`_VerifiedIcon`** | Reusable badge icons |

Content/template folders (`Enemys/EggHead`, `Units/Overrides`) also live here.

**Do not** put: deny codes, combo/click tuning, gacha/rebirth config, `Multipliers`, `Potions` (settings), `_EnemyTypes`, etc.

### `src/Constants/Datas/` — gameplay catalogs

Lists and definitions that make up the game: `Units`, `Gachas`, `Enemys`, `Islands`, `Ranks`, `PlayerData`. May `require` `PrimaryDatas` (Icons, Raritys) and `Services` (e.g. `Services.Enemy._EnemyTypes`) when needed.

### Decision flow (new code)

1. Generic and pure (math, lerp, format)? → **`src/Utils/`**
2. UI/feedback used by multiple systems? → **`src/Modules/`**
3. Belongs to a domain (unit, click, potion, enemy)? → **`src/Services/<Domínio>/`**
4. Global icon, rarity, or item? → **`src/Constants/PrimaryDatas/`**
5. Catalog/list of game entities? → **`src/Constants/Datas/`**

---

## Utils and Modules — reuse before reinventing

**Agent rule:** before implementing number formatting, interpolation, clamp/map, time, UI effects, sounds, popups, transitions, or any repeatable helper, **search for and use** utilities already in the project. Do not duplicate logic inline or recreate wrappers if an equivalent already exists.

### Mandatory workflow

1. **Search** — `grep` / semantic search in `src/Utils/`, `src/Modules/`, `src/Services/<Domínio>/`, `src/Workers/`, and `*Utils.luau`.
2. **Prefer** — domain util (`ClickPowerUtils`) or infra facade (`NumberModule`, `SoundModule`).
3. **Extend** — if a function is missing: generic → `Utils/`; domain → `Services/<Domínio>/`.
4. **Create new** — only when no equivalent exists; correct location:
   - generic and stateless → `src/Utils/`
   - cross-cutting UI/UX infra → `src/Modules/`
   - domain logic, UI, or constant → `src/Services/<Domínio>/`
   - global icon/rarity/item → `src/Constants/PrimaryDatas/`
   - entity catalog → `src/Constants/Datas/`

### Catalog — `src/Utils/` (pure)

| Module | Require | Use |
|---|---|---|
| **`Math`** | `Shareds.Utils.Math` | `clamp`, `map`, `wrap`, `round`, `sign`, `snap`, `pingPong`, 2D/3D distances, angles (`deltaAngleDegrees`, `normalizeAngleDegrees`), `randomRange`, `average`/`sum`/`min`/`max` |
| **`Lerp`** | `Shareds.Utils.Lerp` | `scalar`, `vector2/3`, `color3`, `cframe`, `udim2`, `angleDegrees`, `inverse`, easing helpers |
| **`FormatNumber`** | `Shareds.Utils.FormatNumber` | `formatCompact`, `formatInteger`, `formatExact`, `formatPercent`, `formatDelta`, `formatTime`, `formatCooldown`, `formatSigned` |
| **`Quadtree`** | `Shareds.Utils.Quadtree` | 2D spatial queries (insert, query by bounds/point) |
| **`UIAnimator`** | `Shareds.Utils.UIAnimator` | Hover/press presets, region panel `Show`/`Hide`, ripple, interface blur |

```luau
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const MathUtil = require(ReplicatedStorage.Shareds.Utils.Math)
const Lerp = require(ReplicatedStorage.Shareds.Utils.Lerp)
const FormatNumber = require(ReplicatedStorage.Shareds.Utils.FormatNumber)

-- Prefer NumberModule when you need animation + formatting together
const NumberModule = require(ReplicatedStorage.Shareds.Modules.NumberModule)

local alpha = MathUtil.clamp(elapsed / duration, 0, 1)
local display = Lerp.scalar(from, to, alpha)
label.Text = FormatNumber.formatCompact(display)
```

### Catalog — `src/Modules/` (shared infra)

See the full table in [Where to put code](#where-to-put-code--modules-vs-services-vs-primarydatas). Summary: `GuiModule`, `NotificationModule`, `TransitionModule`, `SoundModule`, `NumberModule`, `PopupModule`, `EzVisualzGradientModule`, `CameraShakeModule`.

### Catalog — `src/Services/<Domínio>/` (examples)

| Domain | Modules / constants |
|---|---|
| **Units** | `UnitsModule`, `UnitCardModule`, `UnitsDenyCodes`, `UnitFollowerServiceUtils` |
| **Click** | `ComboCombatModule`, `ClickBoostModule`, `Click.luau`, `Combo.luau`, `ClickBoostDenyCodes` |
| **Gacha** | `GachaModule`, `Gacha.luau`, `GachaDenyCodes`, `GachaProducts` |
| **Potion** | `PotionHudModule`, `Potions.luau`, `PotionDenyCodes` |
| **Enemy** | `HitIndicatorModule`, `NpcBillboardModule`, `_EnemyTypes`, `_EnemyMake` |
| **Rebirth** | `RebirthModule`, `Rebirth.luau`, `RebirthDenyCodes` |
| **Settings** | `MusicControllerModule`, `SoundSettings`, `InterfaceMusic` |
| **Multiplier** | `Multipliers.luau`, `MultiplierVisualModule`, `MultiplierUtils` |

### Catalog — domain `*Utils`

| Module | Use |
|---|---|
| **`ClickPowerUtils`** | Power per click, rebirth, lucky factor, derived damage |
| **`SoundVolumeUtils`** | Settings percentage → `Sound` volume |
| **`IslandServiceUtils`** | Shared island logic |

### Anti-patterns (utils)

- `string.format` / manual concatenation for large currencies — use `FormatNumber` or `NumberModule`
- Repeated inline `math.clamp` / lerp — use `Math` / `Lerp`
- `TweenService` + numeric counter logic from scratch — use `NumberModule.animateNumber`
- `Instance.new("Sound")` + manual clone — use `SoundModule`
- Custom currency highlight/popup — check `PopupModule` / `Services.Currency.CurrencyVisualModule` first
- Hover/press tweens on buttons — prefer `UIAnimator:BindInteractive` or `GuiModule`

---

## Module header and optimization

### Pattern — every module

```luau
--!strict
```

`--!strict` is **required** on every ModuleScript. Type parameters, returns, and `self`; prefer explicit primitive types (`number`, `string`, `boolean`) and `export type` on public APIs.

### `@native` and `--!native` — hot paths only

Two ways to request native (C++) compilation instead of bytecode:

| Form | Scope | Example |
|---|---|---|
| `@native` | One function | `@native local function encode(buff: buffer): number` |
| `--!native` | Entire file | Second line of the module, after `--!strict` |

```luau
--!strict

@native local function clamp(value: number, min: number, max: number): number
	return math.max(min, math.min(max, value))
end
```

**Use when:** combat, serialization/networking, pathfinding, simulation, loops on `Heartbeat`/`RenderStepped` with hundreds+ of entities — and **only after evidence** of a bottleneck.

**Do not use in:** `Constants/`, UI, boots, handlers, config, deny codes, `Icons`, debug, code that runs once.

Prefer `@native` on **isolated functions** before `--!native` on the whole file — smaller scope, easier debugging.

---

## `const` — immutable bindings

Luau supports `const` for local variables that **cannot be reassigned**. Use it for every value that does not change after initialization.

### When to use `const`

| Use `const` | Use `local` |
|---|---|
| Services cached at the top | Mutable state (`self._initialized`) |
| Module requires | Counters, reusable buffers |
| Numeric / string constants | Loop variables |
| References to `Vector3.zero`, etc. | Fields that change at runtime |
| Configuration read once | Player data |

### Syntax

```luau
--!strict

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Janitor = require(ReplicatedStorage.Packages.janitor)

const MAX_HEALTH: number = 100
const DEFAULT_SPAWN: Vector3 = Vector3.new(0, 5, 0)
const EMPTY_ARRAY: { string } = {}
```

`const` supports type annotation, multi-assignment, and function declaration:

```luau
const a: number, b: number = 1, 2

const function formatCoins(amount: number): string
	return `{amount}`
end
```

### `local function` vs `const function`

Module helpers can be declared either way. **Prefer `const function`** when the function is fixed (will not be reassigned) — most internal helpers.

| Prefer | When |
|---|---|
| **`const function`** | Stable helper: validation, clamp, builders, map sync, lookups |
| **`local function`** | Only if the binding is swapped later (`fn = other`), or legacy pattern already in the file |
| **`function Module.Method`** | Singleton methods / public service API |

```luau
-- Preferred — helper that does not change
const function clampLevel(level: number): number
	return math.max(1, level)
end

const function getTeamsRoot(): Folder?
	-- ...
end

-- OK — mutable binding (rare)
local onTick = function(_dt: number) end
onTick = function(dt: number)
	-- runtime swap
end

-- Service methods — not const function at the top
function GameplayService.StartMatch(self: GameplayService, props: GameplayPropeties)
	-- ...
end
```

**Agent rule:** when creating a new helper in the module, use `const function` by default. Use `local function` only with a reason (reassignment or local consistency with an existing `local` block).

### Binding vs value — `const` vs `table.freeze`

| Mechanism | What it protects |
|---|---|
| `const` | The **binding** — cannot reassign the variable |
| `table.freeze` | The **contents** of the table — cannot add/remove/mutate keys |

```luau
export type CacheKey = string
export type CacheValue = number
export type NumberCache = { [CacheKey]: CacheValue }

const cache: NumberCache = {}
cache["key"] = 1 -- OK: mutable contents
-- cache = {}    -- ERROR: reassignment forbidden

export type DenyCodeName = string
export type DenyCode = number
export type DenyCodeMap = { [DenyCodeName]: DenyCode }

const DENY_CODES: DenyCodeMap = table.freeze({
	Ok = 0,
	NotFound = 2,
})
-- DENY_CODES.Ok = 1  -- ERROR: frozen table
```

**Rule:** `const` is the default for everything that will not be reassigned. **`table.freeze` only when necessary** — do not overuse it.

| Use `table.freeze` | No need for `table.freeze` |
|---|---|
| Save template (`PlayerData`) passed to DataService | `Icons`, read-only catalogs with `const` on the binding |
| Deny codes exported/consumed by multiple modules | Requires cached at the top of the module |
| Public API return that **must not** be mutated by the caller | Internal singleton tables that nobody exports |
| `Networking/Definitions.luau` (channel registry) | Primitive values (`const MAX = 10`) |

For primitives and immutable Roblox instances, `const` is enough:

```luau
const MAX_HEALTH: number = 100
const ZERO = Vector3.zero
const IDENTITY = CFrame.identity
const EMPTY: { string } = {}
```

### Where to apply in the project

```luau
-- Constants/ — const on the binding; semantic types; freeze only if shared
export type IconKey = string
export type IconId = string
export type IconsMap = { [IconKey]: IconId }

const Icons: IconsMap = {
	Coins = "rbxassetid://123",
}

-- Save template — freeze required (shared reference, must not mutate)
export type CoinAmount = number
export type CurrencyBalances = { Coins: CoinAmount }

const PlayerDataTemplate = table.freeze({
	Currencies = table.freeze({ Coins = 0 }),
})

-- Services — const for requires; no freeze
const DataServiceV2 = require(ReplicatedStorage.DataServiceV2)
```

### Agent rule

> Prefer `const` over `local` whenever possible. Prefer `const function` for stable module helpers (instead of `local function`). Use `table.freeze` **only** when the table is shared and needs protection against accidental mutation — do not freeze by default across all of `Constants/`.

---

## Luau typing

### Semantic types — never loose generics

**Forbidden** to use maps/lists with generic primitives when the meaning of the data is known:

```luau
-- Bad
const Icons: { [string]: string } = {}
local cache: { [string]: number } = {}
local players: { [number]: PlayerData } = {}
```

**Required** to name key, value, and the map with `export type`:

```luau
--!strict

export type IconKey = string
export type IconId = string
export type IconsMap = { [IconKey]: IconId }

export type CacheKey = string
export type CacheValue = number
export type NumberCache = { [CacheKey]: CacheValue }

export type UserId = number
export type PlayerSaveMap = { [UserId]: PlayerData }

const Icons: IconsMap = {
	Coins = "rbxassetid://123",
}
```

| Role | Convention | Example |
|---|---|---|
| Map key | `<Domínio>Key` | `IconKey`, `UnitKey`, `CacheKey` |
| Primitive value | `<Domínio><Type>` | `IconId`, `CoinAmount`, `DenyCode` |
| Map/dict | `<Domínio>Map` | `IconsMap`, `DenyCodeMap`, `PlayerSaveMap` |
| Save struct | Descriptive PascalCase | `CurrencyBalances`, `UnitInstanceData` |
| Studio UI types | `_DomainTypes.luau` | `_UnitCardRefs` |

Place types in the domain module (`Icons.luau`, `PlayerData.luau`) or in `Shareds/Types/` when they are cross-cutting. Reuse via `require` — do not duplicate aliases.

Loose primitives (`number`, `string`) are OK **only** in obvious local parameters or already-named fields inside an `export type` struct.

### `export type`

Every Service, Client, and public API must export its type at the top of the module. **No `any`** on `self`, `janitor`, `data`, or paths. When the module is a simple singleton/factory, **prefer `typeof(Module)`** instead of manually duplicating the table shape.

```luau
--!strict

const ServiceTypes = require(ReplicatedStorage.Shareds.Types.ServiceTypes)

type Janitor = ServiceTypes.Janitor

local ExampleService = {
	_initialized = false,
	_janitor = nil :: Janitor?,
}

export type ExampleService = typeof(ExampleService)
```

Shared types:

| Type | Require | Use |
|---|---|---|
| **`ServiceTypes.Janitor`** | `Shareds.Types.ServiceTypes` | `_janitor`, `janitor` parameter |
| **`DataServiceV2.PlayerDataStore`** | `ReplicatedStorage.DataServiceV2` | `WaitForData()` / `Get()` handle |
| **`typeof(Paths.…)`** | `dataservicev2.Paths` | paths in bindings/helpers |

`--!strict` rules in `Services/`:

- Type parameters and return of **every** local function and method.
- `self` uses the module's `export type` — never `self: any`.
- Avoid `:: any` on the singleton; prefer `:: MyService`.
- `unknown` + narrow for network/API values — not `any`.
- Do not ship a module with strict warnings.

### Explicit annotations

```luau
-- Bad
local data = {}
local icons: { [string]: string } = {}

-- Good
export type UserId = number
export type PlayerSaveMap = { [UserId]: PlayerData }

local saves: PlayerSaveMap = {}
```

### Type cast (`::`)

Use to assert the type of a singleton table:

```luau
local Service = {} :: MyServiceType
```

---

## Architecture patterns

### Singleton (Services / Controllers)

```luau
-- require does NOT register listeners
local Service = { _initialized = false } :: MyService

function Service:Init()
	assert(not self._initialized, "MyService already initialized")
	self._initialized = true
	self._janitor = Janitor.new()
end

return Service
```

| Layer | Method | Called by |
|---|---|---|
| Server Service | `:Init()` | `Boot/*.server.luau` |
| Controller | `:Init()` | `Controllers/*.client.luau` |
| `*ServiceClient` | `:init()` | `Boot/ClientServicesBoot.client.luau` |

### Handlers — thin scripts

```luau
-- DomainHandler.server.luau
-- Only connects events and delegates to the Service; logic stays in the Service
```

### Janitor — required with lifecycle

Package API: `janitor:add(...)` and `janitor:destroy()` (methods in **lowercase**).

```luau
const Janitor = require(ReplicatedStorage.Packages.janitor)

self._janitor = Janitor.new()

-- RBXScriptConnection (Players, Instance, QuickNet)
self._janitor:add(Players.PlayerAdded:Connect(handler)) -- infers "Disconnect"

-- DataServiceV2 GetChangedSignal → sleitnick Signal.Connection (table, NOT RBXScriptConnection)
self._janitor:add(data:GetChangedSignal({ "Currencies", "Coins" }):Connect(function(newValue, oldValue)
	-- ...
end)) -- omit methodName → uses "Destroy" on Connection

-- Cleanup / cancel function
self._janitor:add(function()
	cancelAnimation()
end, true)

self._janitor:destroy() -- on teardown
```

#### Connection type → how to register

| Origin | Type returned by `:Connect()` | Correct `janitor:add` | Wrong |
|---|---|---|---|
| `Players`, `Instance`, Roblox events | `RBXScriptConnection` | omit methodName or `"Disconnect"` | — |
| `DataServiceV2` `GetChangedSignal` | `Connection` (sleitnick, **table**) | omit methodName (→ `"Destroy"`) | `"Disconnect"` ❌ |
| QuickNet `Connect` | `QuickNetConnection` | omit methodName or `"Disconnect"` |
| Cleanup function | `function` | `add(fn, true)` |

> **Never** `janitor:add(signalConnection, "Disconnect")` on `GetChangedSignal` — Janitor calls Roblox's global `Disconnect()` and fails at runtime with `invalid argument #1 to 'Disconnect' (RBXScriptConnection expected, got table)`.

#### Per-player Janitor (server)

```luau
self._janitor:add(Players.PlayerRemoving:Connect(function(player: Player)
	local playerJanitor = self._playerJanitors[player]
	if playerJanitor then
		playerJanitor:destroy()
		self._playerJanitors[player] = nil
	end
end), "Disconnect")
```

Prefer `PlayerRemoving` instead of destroying the janitor inside the player's own `AncestryChanged`.

Every `Connect`, tween, cancelable `task.delay`, and network callback → register with Janitor.

---

## DataServiceV2

| File | Role |
|---|---|
| `src/Constants/Datas/PlayerData.luau` | Save template + types |
| `src/Workers/DataServiceV2.luau` | Wrapper with typed `Paths` |
| `src/Boot/Server.server.luau` | Server initialization |
| `src/Boot/Client.client.luau` | Client initialization |

At runtime, the wrapper is required via `ReplicatedStorage.Shareds.Workers.DataServiceV2`.

```luau
-- Server — authorized mutation
const DataServiceV2 = require(ReplicatedStorage.Shareds.Workers.DataServiceV2)
const DataService = DataServiceV2.Server
const Paths = DataServiceV2.Paths

-- Client — read-only + GetChangedSignal
const DataService = DataServiceV2.Client
```

Mutations **only on the server**. Client uses `GetChangedSignal` via Janitor — see the table in [Janitor](#janitor--required-with-lifecycle); do **not** pass `"Disconnect"` on the Signal Connection.

---

## Networking (typed Networker) — gameplay

One Networker **per Service** under `src/Networker/` (`ReplicatedStorage.Shareds.Networker`). leif-style API: client→server whitelist + server→client `fire` calls methods on the client module. **Data typing** = `export type` on method parameters (`GameplayTypes`, `CardsServiceType`, …). Dispatch hot paths use `@native`.

```luau
--!strict
const Networker = require(ReplicatedStorage.Shareds.Networker)

-- Server
self.Networker = Networker.server.new("GameplayService", self)
self.Networker:fire(player, "SetEntityState", state :: GameplayTypes.EntityState)

-- Client
self.Networker = Networker.client.new("GameplayService", self)
-- server calls SetEntityState / SetEnergy / AddUnit on the module itself
```

| Do | Avoid |
|---|---|
| Luau types on method payloads | `fire` with loose tables without `export type` |
| Validate in the Service (whitelist + shape) | Expose every Service method to the client |
| One Networker per Service | Loose manual RemoteEvent / new ByteNet |
| `@native` only on dispatch/fire hot path | `@native` in UI / boots |

Player persistence stays in **DataServiceV2** (not Networker).

## jecs (ECS) — Tower / Unit

Combat and entities in `src/Classes/` in the repo, mounting at `ReplicatedStorage.Shareds.Classes` at runtime. Skill: **`jecs-ecs`**. jecs is **not** OOP — components + factories.

| Folder | Role |
|---|---|
| `Primitives/` | One component per file + `World` |
| `MetaDatas/` | `Tower.new` / `Unit.new` |
| `Entity/Tower`, `Entity/Units` | `{ Config, create }` — **no** spawn in `require` |

`-- How it works:` comment at the top of MetaDatas, defs, and systems (not on every Primitive). Studio/folder layout: skill **`anime-domains-layout`**.

---

## Client vs server

| Client | Server |
|---|---|
| Damage numbers, particles, trails | Action validation |
| Camera shake, UI animations | Economy, inventory, damage |
| `ezvisualz`, `stickybillboard` | DataServiceV2 writes |
| Visual `RenderStepped` / `Heartbeat` | Basic anti-cheat, rate-limit |

---

## Performance

### Allocation and tables

```luau
const buffer = table.create(100)

RunService.Heartbeat:Connect(function()
	table.clear(buffer)
end)
```

| Avoid in loops | Prefer |
|---|---|
| New `{}` every frame | `table.create` + `table.clear` |
| `Vector3.new()` | `const ZERO = Vector3.zero` |
| `Instance.new()` | Object pooling |
| `a .. b .. c` | `table.concat` |

### Tasks and loops

```luau
-- Bad (deprecated)
spawn(fn); wait(); delay(1, fn)

-- Good
task.spawn(fn); task.wait(); task.delay(1, fn)

-- Loop with interval
while task.wait(1) do end
```

On hot paths with dense arrays, prefer numeric loops:

```luau
for i = 1, #list do
	local item = list[i]
end
```

`pairs` / `ipairs` are acceptable outside hot paths.

### Object pooling

Required for high volume: damage numbers, projectiles, NPCs, effects, drops.

```luau
local effect = EffectPool:Get()
EffectPool:Return(effect)
```

### Native compilation

See section [Module header and optimization](#module-header-and-optimization). Summary: `@native` per function > `--!native` per file; never in Constants/UI/config.

---

## Security

1. Validate **all** network inputs on the server
2. Never apply currency/damage/inventory based only on the client
3. Rate-limit frequent actions
4. Sensitive fields in DataServiceV2 `Exclude` (do not replicate)

---

## File conventions

| Suffix | Roblox type | Runs on its own? |
|---|---|---|
| `*.server.luau` | Script | Yes (server) |
| `*.client.luau` | LocalScript | Yes (client) |
| `*.luau` | ModuleScript | No — only via `require` |

- **PascalCase** for folders and modules: `PlayerData`, `InventoryHandler`
- Private fields: `_camelCase`
- Cache `require` with `const` at the top of the module

---

## Agent checklist

When generating or editing code, verify:

1. [ ] Read `.cursor/learnings/index.md` and learnings with tags for the task
2. [ ] `--!strict` on the module
2. [ ] `const` for immutable bindings (services, requires, constants, primitives); `const function` for stable helpers
3. [ ] `table.freeze` **only** on shared tables that must not be mutated (save template, deny codes, API exports)
4. [ ] Semantic types (`IconKey`, `IconId`, `IconsMap`) — never loose `{ [string]: string }`
5. [ ] `export type` on public APIs
6. [ ] Singleton with no side effects in `require`
7. [ ] Idempotent `:Init()` / `:init()` with `assert(not self._initialized)`
8. [ ] Janitor for every connection with a lifecycle
9. [ ] `GetChangedSignal` in Janitor **without** `"Disconnect"` (omit methodName)
10. [ ] Data mutation only on the server (DataServiceV2)
11. [ ] Gameplay networking via typed Networker (`src/Networker/`) + types on methods; save via DataServiceV2
11b. [ ] jecs entities: MetaData + `{ Config, create }` — no spawn in `require`
12. [ ] Visual effects on the client; validation on the server
13. [ ] Pooling for high-volume entities/effects
14. [ ] `@native` / `--!native` only on proven hot paths — never in Constants/UI
15. [ ] Readability first; micro-optimize only with evidence
16. [ ] Character/animations/assets compatible with **R6** (not R15)
17. [ ] Search `src/Utils`, `src/Modules`, `src/Services/<Domínio>`, and `src/Workers` **before** implementing math, time, formatting, sound, popup, wrapper, or UI effect
18. [ ] New domain code in `src/Services/<Domínio>/`; service constants **not** in `src/Constants/PrimaryDatas/`
19. [ ] `src/Modules/` only for cross-cutting infra; `src/Workers/` for shared wrappers/infra
20. [ ] Use `NumberModule` / `FormatNumber` for numbers; `SoundModule` for SFX; `Math` / `Lerp` for calculations — do not duplicate inline
21. [ ] No `any` in `Services/` — use `ServiceTypes.Janitor`, `DataServiceV2.PlayerDataStore`, and a complete `export type` on `self`
22. [ ] Local functions and methods with typed parameters/returns; zero `--!strict` warnings when shipping
23. [ ] If you fixed an error: document in `.cursor/learnings/` and update `index.md`
24. [ ] Did **not** rewrite/reorganize the author's hand style — only the requested change; kept their `const`/`local` and file voice

---

## Anti-patterns

- Fixing an error without documenting in `.cursor/learnings/`
- Duplicating an existing learning instead of updating the file
- Rewriting hand-authored modules to match agent taste / "better organization"
- Changing author `const` ↔ `local` (or helper declaration style) without being asked
- Filling or deleting the author's WIP stubs unless requested
- `{ [string]: string }`, `{ [number]: T }`, or other generic maps — create `export type` with semantic Key/Value/Map
- `local` where `const` would suffice **when writing new code** (still do not rewrite existing author bindings)
- `local function` for a stable helper when `const function` would work **on new helpers**
- Excessive `table.freeze` — `const` already protects the binding; freeze only when shared contents must not mutate
- `@native` / `--!native` in Constants, UI, boots, or handlers
- Reassigning variables that should be constants
- `Instance.new()` in combat/VFX loops
- Replicating the entire inventory on every change
- Economy logic in `StarterPlayerScripts`
- Side effects in the module body (outside functions)
- `while true do wait() end` without an interval
- Manual `RemoteEvent` for new systems (use typed Networker in `src/Networker/`)
- QuickNet / ByteNet for new gameplay in this game (use Networker per Service)
- Spawning a jecs entity in the `require` body — export `{ Config, create }`
- Modeling Tower/Unit as an OOP class with combat methods — use components + systems
- `janitor:add(getChangedSignal:Connect(...), "Disconnect")` — DataService Connection is a table, not `RBXScriptConnection`
- Destroying a player janitor inside that same player's `AncestryChanged` callback — use `Players.PlayerRemoving`
- Premature optimization in setup/config
- "Performance before readability" without an identified hot path
- Number formatting, lerp, clamp, or SFX implemented inline — use existing `src/Utils` / `src/Modules`
- Creating a new generic helper without checking `src/Utils`, `src/Modules`, and `src/Workers` first
- Putting a domain `*Module` in `src/Modules/` — use `src/Services/<Domínio>/`
- Putting a shared wrapper in `src/Services/` when it is not a gameplay domain — use `src/Workers/`
- Putting deny codes, settings, or service tuning in `src/Constants/PrimaryDatas/` — use `src/Services/<Domínio>/`
- `self: any`, `janitor: any`, `data: any`, or `:: any` on `Services/` singletons — use `ServiceTypes.Janitor` and `DataServiceV2.PlayerDataStore`
- Functions without parameter/return typing in `--!strict` modules

---

## References

- Repository architecture: [Docs/FRAMEWORK.md](Docs/FRAMEWORK.md) (when it exists)
- Luau: [luau.org/syntax](https://luau.org/syntax/)
- Networker (inspiration): [leifstout/networker](https://github.com/leifstout/networker)
- jecs: [DevForum](https://devforum.roblox.com/t/jecs-optimizing-declarative-scene-graphs-with-ecs/3263203)
- Janitor: [github.com/1ForeverHD/Janitor](https://github.com/1ForeverHD/Janitor)
- DataServiceV2: `Packages/_Index/.../dataservicev2/README.md`
