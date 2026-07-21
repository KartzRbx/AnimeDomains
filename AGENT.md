# Agent Guide — Estilo Luau / Roblox

Guia obrigatório para agentes de IA e desenvolvedores que trabalham em repositórios que seguem este estilo de programação. Descreve **convenções, prioridades e comportamento do agente** — não um jogo ou produto específico.

Para arquitetura detalhada do repositório atual, consulte [Docs/FRAMEWORK.md](Docs/FRAMEWORK.md) quando existir no projeto.

---

## Bootstrap — recriar o ambiente completo

Este `AGENT.md` é a **fonte da verdade** do estilo. Com um único comando o agente recria o workspace inteiro (Rojo, Rokit, Wally, Selene, `sourcemap`, `src/`, `.cursor/`, docs).

### Comandos que disparam bootstrap

- `bootstrap framework`
- `setup framework` / `inicie o ambiente` / `configurar framework`
- `criar projeto roblox` / `scaffold framework`

### O que o agente deve fazer

1. Ler e executar **`.cursor/skills/bootstrap-framework/SKILL.md`**
2. Copiar templates de `.cursor/skills/bootstrap-framework/templates/` para a raiz do projeto
3. Substituir `{{PROJECT_NAME}}` e `{{WALLY_PACKAGE}}` nos configs
4. Rodar: `rokit install` → `wally install` → `rojo sourcemap default.project.json -o sourcemap.json` → `rojo build` (verificar) → `rojo plugin install`

### Seed mínimo (repositório novo / vazio)

Copiar só estes dois itens para a pasta do projeto:

```
AGENT.md
.cursor/skills/bootstrap-framework/    # inclui templates/
```

Depois: **bootstrap framework**. O agente entrega o resto.

### Entregável esperado após bootstrap

| Item | Origem |
|---|---|
| `default.project.json`, `rokit.toml`, `wally.toml`, `selene.toml`, `.gitignore` | templates |
| `src/` skeleton (Boots, PlayerData, DataServiceV2, Networking, …) | templates |
| `Docs/FRAMEWORK.md`, `AGENT.md` | templates |
| `.cursor/skills/` + `.cursor/learnings/` | templates |
| `Packages/` | `wally install` (gitignored) |
| `wally.lock` | `wally install` |
| `sourcemap.json` | `rojo sourcemap` |

**Manter templates atualizados:** ao evoluir o framework neste repositório canônico, sincronizar `.cursor/skills/bootstrap-framework/templates/` com as mudanças.

---

## Visão geral

Projetos com este estilo são jogos **Roblox (Luau)** sincronizados via **Rojo**, com camadas explícitas e tipagem estrita. Prioridades ao gerar código:

1. Arquitetura em camadas (Boot → Services → Handlers / Controllers)
2. Tipagem estrita (`--!strict`, `export type` semântico, `const`)
3. Ciclo de vida explícito (`:Init()` / `:init()` — nunca side effects no `require`)
4. Performance em hot paths (pooling, cache, rede mínima)
5. Servidor como fonte da verdade

**Regra central:** `require` **não** registra listeners, **não** muta dados e **não** toca em instâncias do jogo. Tudo isso acontece somente após `:Init()` (servidor/controllers) ou `:init()` (`*ServiceClient`).

---

## Skills do Cursor

### Organização do `.cursor/`

Estrutura padrão do repositório. **Nunca** criar skills em `~/.cursor/skills-cursor/` (reservado ao Cursor).

```
.cursor/
├── skills/                    # Skills do projeto (versionadas no git)
│   ├── bootstrap-framework/   # Recriar ambiente completo — templates/
│   ├── roblox-framework/      # Entrada — ler primeiro em tarefas Luau
│   │   └── SKILL.md
│   ├── add-domain/
│   ├── luau-style/
│   ├── jecs-ecs/              # Entities Tower/Unit (jecs ECS)
│   ├── anime-domains-layout/  # Onde colocar arquivos neste jogo
│   ├── arena-maps/            # Padrão FlorestMap / Maps Clash-like
│   ├── entity-animations/     # Idle/Walk + AnimationResolveUtils / Signal
│   ├── quicknet-handler/      # Legado — gameplay usa Networker tipada
│   ├── extend-player-data/
│   ├── learning-mode/         # Modo aprendizado — sempre ativo
│   └── <nova-skill>/          # Uma pasta por skill
│       ├── SKILL.md           # Obrigatório
│       ├── reference.md       # Opcional — detalhes longos
│       └── examples.md        # Opcional — exemplos
└── learnings/                 # Erros corrigidos (modo aprendizado)
    ├── index.md               # Índice — ler antes de codificar
    └── <slug>.md              # Um arquivo por lição aprendida
```

#### Regras para criar ou editar skills

| Regra | Detalhe |
|---|---|
| **Local** | Só em `.cursor/skills/<nome>/` |
| **Nome** | lowercase, hífens, máx. 64 chars (`add-domain`, `luau-style`) |
| **SKILL.md** | Frontmatter YAML com `name` + `description` (terceira pessoa, WHEN + WHAT) |
| **Tamanho** | SKILL.md conciso (< 500 linhas); detalhes em `reference.md` |
| **Escopo** | Uma skill = um workflow ou domínio claro |
| **Duplicação** | Não repetir `AGENT.md` inteiro — resumir e linkar |
| **Nova skill** | Preferir estender skill existente; criar nova só se workflow distinto |
| **Promoção** | Padrão repetido 3× em `learnings/` → subir para skill ou `AGENT.md` |

#### Quando criar nova skill vs learning

| Situação | Onde registrar |
|---|---|
| Erro corrigido uma vez | `.cursor/learnings/<slug>.md` |
| Workflow novo (ex.: deploy, migração save) | `.cursor/skills/<nome>/SKILL.md` |
| Regra pontual que se repete | `learnings/` primeiro → promover para skill |
| Regra global do estilo | `AGENT.md` ou `Docs/FRAMEWORK.md` |

#### Ordem de leitura (tarefas de código)

1. `.cursor/learnings/index.md` (+ arquivos relevantes)
2. `.cursor/skills/roblox-framework`
3. Skill específica (`add-domain`, `quicknet-handler`, …)
4. `.cursor/skills/learning-mode` (se corrigindo erro)
5. `AGENT.md` → `Docs/FRAMEWORK.md`

---

### Modo aprendizado (sempre ativo)

Sempre que **corrigir um erro** (runtime, strict, review do usuário, build falho), o agente deve:

1. Identificar a **causa raiz** — não só o sintoma
2. Corrigir o código
3. Documentar em `.cursor/learnings/<slug>.md` usando o template da skill `learning-mode`
4. Atualizar `.cursor/learnings/index.md` com uma linha na tabela
5. Se o mesmo padrão aparecer **3 vezes**, promover a regra para a skill ou `AGENT.md` correspondente

**Antes de codificar:** ler `index.md` e learnings com tags relacionadas à tarefa.

---

### Skills do projeto (`.cursor/skills/`)

Ler o `SKILL.md` antes de aplicar. Estas skills são **específicas deste framework** e têm prioridade em tarefas de código Luau.

| Skill | Quando usar |
|---|---|
| **bootstrap-framework** | `bootstrap framework` — recriar workspace do zero |
| **roblox-framework** | Qualquer código em `src/` — ler primeiro |
| **anime-domains-layout** | Onde colocar arquivo / mapa Studio / fluxo match |
| **arena-maps** | Novo mapa / FlorestMap / Build+Teams / BuildMap |
| **entity-animations** | Anims entity + AnimationResolveUtils + Signal |
| **jecs-ecs** | Tower, Unit, Primitive, MetaData, World jecs |
| **add-domain** | Novo sistema/domínio (shop, inventário, units, …) |
| **luau-style** | Criar ou editar módulos `.luau` |
| **quicknet-handler** | Legado / DataService — gameplay usa **Networker** tipada |
| **extend-player-data** | Novos campos no save / `PlayerData.luau` |
| **learning-mode** | Sempre ativo — documentar correções, ler learnings antes de codificar |

**Ordem:** `learnings/index.md` → `roblox-framework` → `anime-domains-layout` (se layout) → skill específica → `AGENT.md` / `Docs/FRAMEWORK.md`.

### Skills built-in do Cursor (`~/.cursor/skills-cursor/`)

Usar quando a tarefa pedir ou encaixar — ler `SKILL.md` antes de invocar.

| Skill | Quando usar |
|---|---|
| **babysit** | PR com comentários pendentes, CI falhando, conflitos de merge — deixar merge-ready |
| **review-bugbot** | Usuário pede review de código / `/review-bugbot` — lançar subagent Bugbot |
| **review-security** | Usuário pede security review das mudanças locais |
| **split-to-prs** | Dividir branch ou trabalho grande em PRs pequenos e revisáveis |
| **create-rule** | Criar ou atualizar regras em `.cursor/rules/` ou `AGENT.md` do projeto |
| **create-skill** | Autorar nova skill personalizada (`SKILL.md`) |
| **create-hook** | Automatizar eventos do agente via `hooks.json` |
| **canvas** | Entregável analítico rico (tabelas, timelines, auditorias, dados de MCP) |

### Usar só se o usuário pedir explicitamente

| Skill | Quando usar |
|---|---|
| **sdk** | Integração com `@cursor/sdk` / `cursor-sdk` fora do IDE |
| **automate** | Criar Cursor Automations |
| **loop** | Prompt recorrente (`/loop`) |
| **statusline** | Customizar status line do CLI |
| **update-cursor-settings** | Alterar `settings.json` do editor |
| **migrate-to-skills** | Migrar regras antigas para formato skill |

### Não usar por padrão em código Luau

Não invocar skills de tooling/editor quando a tarefa for implementar features — use as skills do projeto acima.

**Ordem de leitura em tarefas de código:** `.cursor/learnings/index.md` → `roblox-framework` → skill específica → `learning-mode` (ao corrigir) → `AGENT.md` → `Docs/FRAMEWORK.md`.

---

## Personagem (R6)

Projetos com este estilo assumem **rig R6** — não R15.

| Configuração | Valor |
|---|---|
| **Rig** | R6 (`StarterPlayer` → `Character Rig Type` = R6 no Studio) |
| **Partes** | `Head`, `Torso`, `Left Arm`, `Right Arm`, `Left Leg`, `Right Leg` |
| **Humanoid** | `RigType = Enum.HumanoidRigType.R6` |

**Regras para código e assets:**

- Animações, meshes e acessórios compatíveis com **R6** apenas.
- Não referenciar partes exclusivas de R15 (`UpperTorso`, `LowerTorso`, `LeftUpperArm`, …).
- Weld/attach em `Torso` ou membros R6; `HumanoidRootPart` existe, mas membros visíveis seguem o esqueleto R6.
- NPCs e pets que imitam jogador devem usar o mesmo formato R6.

---

## Toolchain

| Ferramenta | Arquivo | Uso |
|---|---|---|
| **Rojo** | `default.project.json` | Sync filesystem ↔ Studio |
| **Rokit** | `rokit.toml` | Gerenciador de CLI (rojo, wally) |
| **Wally** | `wally.toml` | Dependências Luau → `Packages/` |
| **Selene** | `selene.toml` | Linter (std Roblox) |

```bash
rokit install
wally install
rojo serve
rojo plugin install   # manter plugin Studio na mesma versão do CLI
```

---

## Stack de pacotes (Wally)

Quando o repositório usa Wally, acessar via `ReplicatedStorage.Packages`. Wrapper local de persistência via `ReplicatedStorage.DataServiceV2` (não usar o pacote cru no código do jogo).

| Pacote | Require | Uso |
|---|---|---|
| `dataservicev2` | `ReplicatedStorage.DataServiceV2` | Persistência + réplica de dados do jogador |
| `jecs` | `Packages.jecs` | ECS — `src/Classes` (Tower, Unit, Primitives) |
| `signal` | `Packages.signal` | Eventos custom (AnimationPlayer Played/Paused) |
| `janitor` | `Packages.janitor` | Limpar conexões, tweens e callbacks |
| `simplepath` | `Packages.simplepath` | Path de Units (`Path:Run` / `Stop`) |
| `cmdr` | servidor + boot cliente | Console admin (dev/ops) |
| `ezvisualz` | `Packages.ezvisualz` | Gradientes e shine em UI |
| `spring` | `Packages.spring` | Animações com mola |
| `display` | `Packages.display` | Helpers de display |
| `module3d` | `Packages.module3d` | Manipulação 3D |
| `stickybillboard` | `Packages.stickybillboard` | Billboards ancorados |
| `formatnumber` | `Packages.formatnumber` ou `Utils.FormatNumber` | Formatação numérica |
| `vfx-util` | `Packages.vfx-util` | Utilitários de VFX |
| `topbarplus` | `Packages.topbarplus` | Botões na topbar do cliente |

```luau
--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Janitor = require(ReplicatedStorage.Packages.janitor)
const Networker = require(ReplicatedStorage.Shareds.Networker)
const jecs = require(ReplicatedStorage.Packages.jecs)
const Signal = require(ReplicatedStorage.Packages.signal)
const DataServiceV2 = require(ReplicatedStorage.DataServiceV2)
```

> **Anime Domains:** gameplay net = Networker tipada (`src/Networker/`, estilo leif + tipos Luau + `@native` nos hot paths); combate = jecs; anim events = Signal. QuickNet não é dependência de gameplay (pode existir só dentro do DataServiceV2). Conferir `wally.toml`.

---

## Estrutura do projeto

### Regra importante: filesystem != árvore final no Studio

A organização nova deste repositório é **flat em `src/`**. O agente deve decidir onde salvar arquivos olhando primeiro para o **filesystem**, e só depois considerar onde o `default.project.json` monta isso no DataModel do Roblox.

```
src/
├── Boot/                           # Entradas .server/.client
├── Classes/                        # ECS / árvore de components / metadata
├── Constants/
│   ├── Datas/                      # Catálogos de gameplay + PlayerData
│   └── PrimaryDatas/               # Ícones, raridades, itens globais
├── Controllers/                    # Placeholder para LocalScripts/controllers
├── Handlers/                       # Placeholder para scripts finos de integração
├── Modules/                        # Infra compartilhada / cross-cutting
├── Networker/                      # Networker tipada (estilo leif) — um remote por Service
├── Services/                       # Serviços de domínio
├── Utils/                          # Helpers puros
└── Workers/                        # Wrappers/infra compartilhada (ex.: DataServiceV2)
```

### Mapeamento atual para o Studio (`default.project.json`)

| Filesystem | Runtime no Studio | Papel |
|---|---|---|
| `src/Boot/Server.server.luau` | `ServerScriptService.Boot.Server` | Boot do servidor |
| `src/Boot/Client.client.luau` | `StarterPlayer.StarterPlayerScripts.Boot.Client` | Boot do cliente |
| `src/Services/` | `ReplicatedStorage.Shareds.Services` | Domínios e services compartilhados |
| `src/Constants/` | `ReplicatedStorage.Shareds.Constants` | Dados estáticos |
| `src/Classes/` | `ReplicatedStorage.Shareds.Classes` | jecs, primitives, metadata |
| `src/Modules/` | `ReplicatedStorage.Shareds.Modules` | Infra compartilhada |
| `src/Networker/` | `ReplicatedStorage.Shareds.Networker` | Networker server/client tipada |
| `src/Workers/` | `ReplicatedStorage.Shareds.Workers` | Wrappers como `DataServiceV2` |
| `src/Utils/` | `ReplicatedStorage.Shareds.Utils` | Helpers puros |

### Como decidir onde editar

| Camada | Path no repo | Path em runtime | Responsabilidade |
|---|---|---|---|
| **Boot** | `src/Boot/` | `ServerScriptService.Boot` / `StarterPlayerScripts.Boot` | Ponto de entrada único; chama `:Init()` / `:init()` |
| **Services** | `src/Services/` | `ReplicatedStorage.Shareds.Services` | Autoridade e lógica de domínio |
| **Handlers** | `src/Handlers/` | hoje ainda não montado | Scripts finos que conectam plataforma/rede → Service |
| **Controllers** | `src/Controllers/` | hoje ainda não montado | Infra local e orquestração de cliente |
| **Classes** | `src/Classes/` | `ReplicatedStorage.Shareds.Classes` | jecs: components, metadata, helpers de entity |
| **Constants** | `src/Constants/` | `ReplicatedStorage.Shareds.Constants` | Catálogos, save template, dados estáticos |
| **Modules** | `src/Modules/` | `ReplicatedStorage.Shareds.Modules` | Infra UI/UX cross-cutting |
| **Utils** | `src/Utils/` | `ReplicatedStorage.Shareds.Utils` | Funções puras genéricas |
| **Workers** | `src/Workers/` | `ReplicatedStorage.Shareds.Workers` | Wrappers e infraestrutura compartilhada |

**Regra do agente:** ao falar de caminho para criação/edição, preferir `src/...`. Ao mostrar `require`, usar o caminho **runtime** real em `ReplicatedStorage.Shareds...`.

---

## Onde colocar código — Modules vs Services vs PrimaryDatas

Regra central na organização nova: **domínio vai em `src/Services/`**; **dados gerais do jogo em `src/Constants/PrimaryDatas/`**; **`src/Modules/` só para infra compartilhada**. Em runtime isso continua aparecendo sob `ReplicatedStorage.Shareds.*`.

### `src/Modules/` — infra compartilhada

Somente facades cross-cutting de UI/UX/feedback usados por **vários** domínios:

| Módulo | Uso |
|---|---|
| **`GuiModule`** | Hover, abertura/fechamento de interfaces centrais |
| **`NotificationModule`** | Toasts e fila de notificações |
| **`TransitionModule`** | Transição fullscreen em grid (In/Out) |
| **`SoundModule`** | `playInterface`, `playClick`, `playGame`, `playMovement` |
| **`NumberModule`** | Formatação + animação numérica (`animateNumber`, `playDropEffect`) |
| **`PopupModule`** | Popups físicos e de moeda |
| **`EzVisualzGradientModule`** | Shine/gradient em `GuiObject` |
| **`CameraShakeModule`** | Shake de câmera reutilizável |

**Não** colocar aqui: `UnitsModule`, `GachaModule`, `ComboCombatModule`, `PotionHudModule`, deny codes, settings de serviço, etc.

### `src/Services/<Domínio>/` — tudo do domínio

Cada pasta de domínio (`Units`, `Click`, `Gacha`, `Potion`, `Enemy`, `Rebirth`, `Island`, `Settings`, `Movement`, …) agrupa:

| Tipo | Exemplos |
|---|---|
| **Singleton cliente** | `UnitsServiceClient`, `ClickServiceClient`, `GachaServiceClient` |
| **Utils** | `UnitFollowerServiceUtils`, `ClickPowerUtils`, `EnemyServiceUtils` |
| **Module de domínio** | `UnitsModule`, `GachaModule`, `ComboCombatModule`, `PotionHudModule` |
| **Constantes do serviço** | `PotionDenyCodes`, `UnitsDenyCodes`, `Click.luau`, `Combo.luau`, `Gacha.luau`, `Rebirth.luau`, `Multipliers.luau` |

```luau
const UnitsModule = require(ReplicatedStorage.Shareds.Services.Units.UnitsModule)
const PotionDenyCodes = require(ReplicatedStorage.Shareds.Services.Potion.PotionDenyCodes)
const ComboSettings = require(ReplicatedStorage.Shareds.Services.Click.Combo)
```

### `src/Constants/PrimaryDatas/` — dados gerais do jogo

Somente catálogos e assets **transversais**, sem acoplamento a um service:

| Arquivo | Uso |
|---|---|
| **`Icons`** | Asset IDs de ícones (moedas, ilhas, potions, HUD, …) |
| **`Raritys`** | Definições de raridade (cor, nome, ordem) |
| **`Items`** | Catálogo global de itens (referencia Icons + Raritys) |
| **`Notifications`** | Duração, gradientes e limites das notificações |
| **`_RobuxIcon`**, **`_PremiumIcon`**, **`_VerifiedIcon`** | Ícones de badge reutilizáveis |

Pastas de conteúdo/template (`Enemys/EggHead`, `Units/Overrides`) também ficam aqui.

**Não** colocar: deny codes, tuning de combo/click, config de gacha/rebirth, `Multipliers`, `Potions` (settings), `_EnemyTypes`, etc.

### `src/Constants/Datas/` — catálogos de gameplay

Listas e definições que compõem o jogo: `Units`, `Gachas`, `Enemys`, `Islands`, `Ranks`, `PlayerData`. Podem `require` `PrimaryDatas` (Icons, Raritys) e `Services` (ex.: `Services.Enemy._EnemyTypes`) quando necessário.

### Fluxo de decisão (novo código)

1. Genérico e puro (math, lerp, format)? → **`src/Utils/`**
2. UI/feedback usado por vários sistemas? → **`src/Modules/`**
3. Pertence a um domínio (unit, click, potion, enemy)? → **`src/Services/<Domínio>/`**
4. Ícone, raridade ou item global? → **`src/Constants/PrimaryDatas/`**
5. Catálogo/lista de entidades do jogo? → **`src/Constants/Datas/`**

---

## Utils e Modules — reutilizar antes de reinventar

**Regra do agente:** antes de implementar formatação numérica, interpolação, clamp/map, tempo, efeitos de UI, sons, popups, transições ou qualquer helper repetível, **buscar e usar** os utilitários já existentes no projeto. Não duplicar lógica inline nem recriar wrappers se já houver equivalente.

### Workflow obrigatório

1. **Buscar** — `grep` / busca semântica em `src/Utils/`, `src/Modules/`, `src/Services/<Domínio>/`, `src/Workers/` e `*Utils.luau`.
2. **Preferir** — util de domínio (`ClickPowerUtils`) ou facade de infra (`NumberModule`, `SoundModule`).
3. **Estender** — se faltar uma função: genérica → `Utils/`; de domínio → `Services/<Domínio>/`.
4. **Criar novo** — somente quando não existir equivalente; local correto:
   - genérico e sem estado → `src/Utils/`
   - infra UI/UX cross-cutting → `src/Modules/`
   - lógica, UI ou constante de domínio → `src/Services/<Domínio>/`
   - ícone/raridade/item global → `src/Constants/PrimaryDatas/`
   - catálogo de entidades → `src/Constants/Datas/`

### Catálogo — `src/Utils/` (puros)

| Módulo | Require | Uso |
|---|---|---|
| **`Math`** | `Shareds.Utils.Math` | `clamp`, `map`, `wrap`, `round`, `sign`, `snap`, `pingPong`, distâncias 2D/3D, ângulos (`deltaAngleDegrees`, `normalizeAngleDegrees`), `randomRange`, `average`/`sum`/`min`/`max` |
| **`Lerp`** | `Shareds.Utils.Lerp` | `scalar`, `vector2/3`, `color3`, `cframe`, `udim2`, `angleDegrees`, `inverse`, easing helpers |
| **`FormatNumber`** | `Shareds.Utils.FormatNumber` | `formatCompact`, `formatInteger`, `formatExact`, `formatPercent`, `formatDelta`, `formatTime`, `formatCooldown`, `formatSigned` |
| **`Quadtree`** | `Shareds.Utils.Quadtree` | Consultas espaciais 2D (inserção, query por bounds/ponto) |
| **`UIAnimator`** | `Shareds.Utils.UIAnimator` | Hover/press presets, `Show`/`Hide` de painéis por região, ripple, blur de interface |

```luau
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const MathUtil = require(ReplicatedStorage.Shareds.Utils.Math)
const Lerp = require(ReplicatedStorage.Shareds.Utils.Lerp)
const FormatNumber = require(ReplicatedStorage.Shareds.Utils.FormatNumber)

-- Preferir NumberModule quando precisar de animação + formatação juntas
const NumberModule = require(ReplicatedStorage.Shareds.Modules.NumberModule)

local alpha = MathUtil.clamp(elapsed / duration, 0, 1)
local display = Lerp.scalar(from, to, alpha)
label.Text = FormatNumber.formatCompact(display)
```

### Catálogo — `src/Modules/` (infra compartilhada)

Ver tabela completa em [Onde colocar código](#onde-colocar-código--modules-vs-services-vs-primarydatas). Resumo: `GuiModule`, `NotificationModule`, `TransitionModule`, `SoundModule`, `NumberModule`, `PopupModule`, `EzVisualzGradientModule`, `CameraShakeModule`.

### Catálogo — `src/Services/<Domínio>/` (exemplos)

| Domínio | Módulos / constantes |
|---|---|
| **Units** | `UnitsModule`, `UnitCardModule`, `UnitsDenyCodes`, `UnitFollowerServiceUtils` |
| **Click** | `ComboCombatModule`, `ClickBoostModule`, `Click.luau`, `Combo.luau`, `ClickBoostDenyCodes` |
| **Gacha** | `GachaModule`, `Gacha.luau`, `GachaDenyCodes`, `GachaProducts` |
| **Potion** | `PotionHudModule`, `Potions.luau`, `PotionDenyCodes` |
| **Enemy** | `HitIndicatorModule`, `NpcBillboardModule`, `_EnemyTypes`, `_EnemyMake` |
| **Rebirth** | `RebirthModule`, `Rebirth.luau`, `RebirthDenyCodes` |
| **Settings** | `MusicControllerModule`, `SoundSettings`, `InterfaceMusic` |
| **Multiplier** | `Multipliers.luau`, `MultiplierVisualModule`, `MultiplierUtils` |

### Catálogo — `*Utils` por domínio

| Módulo | Uso |
|---|---|
| **`ClickPowerUtils`** | Power por click, rebirth, lucky factor, dano derivado |
| **`SoundVolumeUtils`** | Percentual de settings → volume de `Sound` |
| **`IslandServiceUtils`** | Lógica compartilhada de ilhas |

### Anti-patterns (utils)

- `string.format` / concatenação manual para moedas grandes — usar `FormatNumber` ou `NumberModule`
- `math.clamp` / lerp inline repetido — usar `Math` / `Lerp`
- `TweenService` + lógica de contador numérico do zero — usar `NumberModule.animateNumber`
- `Instance.new("Sound")` + clone manual — usar `SoundModule`
- Highlight/popup de moeda customizado — verificar `PopupModule` / `Services.Currency.CurrencyVisualModule` primeiro
- Tweens de hover/press em botões — preferir `UIAnimator:BindInteractive` ou `GuiModule`

---

## Cabeçalho e otimização de módulo

### Padrão — todo módulo

```luau
--!strict
```

`--!strict` é **obrigatório** em todo ModuleScript. Tipar parâmetros, retornos e `self`; preferir tipos primitivos explícitos (`number`, `string`, `boolean`) e `export type` em APIs públicas.

### `@native` e `--!native` — somente hot paths

Duas formas de pedir compilação nativa (C++) em vez de bytecode:

| Forma | Escopo | Exemplo |
|---|---|---|
| `@native` | Uma função | `@native local function encode(buff: buffer): number` |
| `--!native` | Arquivo inteiro | Segunda linha do módulo, após `--!strict` |

```luau
--!strict

@native local function clamp(value: number, min: number, max: number): number
	return math.max(min, math.min(max, value))
end
```

**Usar quando:** combate, serialização/rede, pathfinding, simulação, loops em `Heartbeat`/`RenderStepped` com centenas+ de entidades — e **só após evidência** de gargalo.

**Não usar em:** `Constants/`, UI, boots, handlers, config, deny codes, `Icons`, debug, código que roda uma vez.

Preferir `@native` em **funções isoladas** antes de `--!native` no arquivo inteiro — escopo menor, debug mais fácil.

---

## `const` — bindings imutáveis

Luau suporta `const` para variáveis locais que **não podem ser reatribuídas**. Use em todo valor que não muda após a inicialização.

### Quando usar `const`

| Use `const` | Use `local` |
|---|---|
| Services cacheados no topo | Estado mutável (`self._initialized`) |
| Requires de módulos | Contadores, buffers reutilizáveis |
| Constantes numéricas / strings | Variáveis de loop |
| Referências a `Vector3.zero`, etc. | Campos que mudam em runtime |
| Configuração lida uma vez | Dados do jogador |

### Sintaxe

```luau
--!strict

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Janitor = require(ReplicatedStorage.Packages.janitor)

const MAX_HEALTH: number = 100
const DEFAULT_SPAWN: Vector3 = Vector3.new(0, 5, 0)
const EMPTY_ARRAY: { string } = {}
```

`const` suporta anotação de tipo, multi-atribuição e declaração de função:

```luau
const a: number, b: number = 1, 2

const function formatCoins(amount: number): string
	return `{amount}`
end
```

### `local function` vs `const function`

Helpers do módulo podem ser declarados das duas formas. **Preferir `const function`** quando a função é fixa (não será reatribuída) — a maioria dos helpers internos.

| Preferir | Quando |
|---|---|
| **`const function`** | Helper estável: validação, clamp, builders, sync de mapa, lookups |
| **`local function`** | Só se o binding for trocado depois (`fn = outra`), ou padrão legado já no arquivo |
| **`function Modulo.Metodo`** | Métodos de singleton / API pública do service |

```luau
-- Preferido — helper que não muda
const function clampLevel(level: number): number
	return math.max(1, level)
end

const function getTeamsRoot(): Folder?
	-- ...
end

-- OK — binding mutável (raro)
local onTick = function(_dt: number) end
onTick = function(dt: number)
	-- swap em runtime
end

-- Métodos do service — não são const function no topo
function GameplayService.StartMatch(self: GameplayService, props: GameplayPropeties)
	-- ...
end
```

**Regra do agente:** ao criar helper novo no módulo, usar `const function` por padrão. Usar `local function` só com motivo (reatribuição ou consistência pontual com bloco já `local`).

### Binding vs valor — `const` vs `table.freeze`

| Mecanismo | O que protege |
|---|---|
| `const` | O **binding** — não pode reatribuir a variável |
| `table.freeze` | O **conteúdo** da tabela — não pode adicionar/remover/mutar chaves |

```luau
export type CacheKey = string
export type CacheValue = number
export type NumberCache = { [CacheKey]: CacheValue }

const cache: NumberCache = {}
cache["key"] = 1 -- OK: conteúdo mutável
-- cache = {}    -- ERRO: reatribuição proibida

export type DenyCodeName = string
export type DenyCode = number
export type DenyCodeMap = { [DenyCodeName]: DenyCode }

const DENY_CODES: DenyCodeMap = table.freeze({
	Ok = 0,
	NotFound = 2,
})
-- DENY_CODES.Ok = 1  -- ERRO: tabela congelada
```

**Regra:** `const` é o padrão para tudo que não será reatribuído. **`table.freeze` só quando necessário** — não usar em excesso.

| Use `table.freeze` | Não precisa de `table.freeze` |
|---|---|
| Template de save (`PlayerData`) passado ao DataService | `Icons`, catálogos read-only com `const` no binding |
| Deny codes exportados/consumidos por vários módulos | Requires cacheados no topo do módulo |
| Retorno de API pública que **não pode** ser mutado pelo caller | Tabelas internas de singleton que ninguém exporta |
| `Networking/Definitions.luau` (registro de canais) | Valores primitivos (`const MAX = 10`) |

Para primitivos e instâncias Roblox imutáveis, `const` basta:

```luau
const MAX_HEALTH: number = 100
const ZERO = Vector3.zero
const IDENTITY = CFrame.identity
const EMPTY: { string } = {}
```

### Onde aplicar no projeto

```luau
-- Constants/ — const no binding; tipos semânticos; freeze só se compartilhado
export type IconKey = string
export type IconId = string
export type IconsMap = { [IconKey]: IconId }

const Icons: IconsMap = {
	Coins = "rbxassetid://123",
}

-- Template de save — freeze necessário (referência compartilhada, não pode mutar)
export type CoinAmount = number
export type CurrencyBalances = { Coins: CoinAmount }

const PlayerDataTemplate = table.freeze({
	Currencies = table.freeze({ Coins = 0 }),
})

-- Services — const para requires; sem freeze
const DataServiceV2 = require(ReplicatedStorage.DataServiceV2)
```

### Regra do agente

> Prefira `const` sobre `local` sempre que possível. Preferir `const function` para helpers estáveis do módulo (em vez de `local function`). Use `table.freeze` **apenas** quando a tabela é compartilhada e precisa ser protegida contra mutação acidental — não congele por padrão em todo `Constants/`.

---

## Tipagem Luau

### Tipos semânticos — nunca genéricos soltos

**Proibido** usar mapas/listas com primitivos genéricos quando o significado do dado é conhecido:

```luau
-- Ruim
const Icons: { [string]: string } = {}
local cache: { [string]: number } = {}
local players: { [number]: PlayerData } = {}
```

**Obrigatório** nomear chave, valor e o mapa com `export type`:

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

| Papel | Convenção | Exemplo |
|---|---|---|
| Chave de mapa | `<Domínio>Key` | `IconKey`, `UnitKey`, `CacheKey` |
| Valor primitivo | `<Domínio><Tipo>` | `IconId`, `CoinAmount`, `DenyCode` |
| Mapa/dict | `<Domínio>Map` | `IconsMap`, `DenyCodeMap`, `PlayerSaveMap` |
| Struct de save | PascalCase descritivo | `CurrencyBalances`, `UnitInstanceData` |
| Tipos de UI Studio | `_DomainTypes.luau` | `_UnitCardRefs` |

Colocar tipos no módulo do domínio (`Icons.luau`, `PlayerData.luau`) ou em `Shareds/Types/` quando forem transversais. Reutilizar via `require` — não duplicar alias.

Primitivos soltos (`number`, `string`) são OK **só** em parâmetros locais óbvios ou campos já nomeados dentro de um `export type` struct.

### `export type`

Todo Service, Client e API pública deve exportar seu tipo no topo do módulo. **Sem `any`** em `self`, `janitor`, `data` ou paths. Quando o módulo é um singleton/factory simples, **preferir `typeof(Modulo)`** em vez de duplicar manualmente a shape da tabela.

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

Tipos compartilhados:

| Tipo | Require | Uso |
|---|---|---|
| **`ServiceTypes.Janitor`** | `Shareds.Types.ServiceTypes` | `_janitor`, parâmetro `janitor` |
| **`DataServiceV2.PlayerDataStore`** | `ReplicatedStorage.DataServiceV2` | handle de `WaitForData()` / `Get()` |
| **`typeof(Paths.…)`** | `dataservicev2.Paths` | paths em bindings/helpers |

Regras `--!strict` em `Services/`:

- Tipar parâmetros e retorno de **toda** função local e método.
- `self` usa o `export type` do módulo — nunca `self: any`.
- Evitar `:: any` no singleton; preferir `:: MeuService`.
- `unknown` + narrow em valores de rede/API — não `any`.
- Não entregar módulo com warnings do strict.

### Anotações explícitas

```luau
-- Ruim
local data = {}
local icons: { [string]: string } = {}

-- Bom
export type UserId = number
export type PlayerSaveMap = { [UserId]: PlayerData }

local saves: PlayerSaveMap = {}
```

### Type cast (`::`)

Use para afirmar o tipo de uma tabela singleton:

```luau
local Service = {} :: MyServiceType
```

---

## Padrões de arquitetura

### Singleton (Services / Controllers)

```luau
-- require NÃO registra listeners
local Service = { _initialized = false } :: MyService

function Service:Init()
	assert(not self._initialized, "MyService already initialized")
	self._initialized = true
	self._janitor = Janitor.new()
end

return Service
```

| Camada | Método | Chamado por |
|---|---|---|
| Service servidor | `:Init()` | `Boot/*.server.luau` |
| Controller | `:Init()` | `Controllers/*.client.luau` |
| `*ServiceClient` | `:init()` | `Boot/ClientServicesBoot.client.luau` |

### Handlers — scripts finos

```luau
-- DomainHandler.server.luau
-- Apenas conecta eventos e delega ao Service; lógica fica no Service
```

### Janitor — obrigatório com ciclo de vida

API do pacote: `janitor:add(...)` e `janitor:destroy()` (métodos em **minúsculas**).

```luau
const Janitor = require(ReplicatedStorage.Packages.janitor)

self._janitor = Janitor.new()

-- RBXScriptConnection (Players, Instance, QuickNet)
self._janitor:add(Players.PlayerAdded:Connect(handler)) -- infere "Disconnect"

-- DataServiceV2 GetChangedSignal → sleitnick Signal.Connection (tabela, NÃO RBXScriptConnection)
self._janitor:add(data:GetChangedSignal({ "Currencies", "Coins" }):Connect(function(newValue, oldValue)
	-- ...
end)) -- omitir methodName → usa "Destroy" na Connection

-- Função de cleanup / cancel
self._janitor:add(function()
	cancelAnimation()
end, true)

self._janitor:destroy() -- ao desmontar
```

#### Tipo de conexão → como registrar

| Origem | Tipo retornado por `:Connect()` | `janitor:add` correto | Errado |
|---|---|---|---|
| `Players`, `Instance`, eventos Roblox | `RBXScriptConnection` | omitir methodName ou `"Disconnect"` | — |
| `DataServiceV2` `GetChangedSignal` | `Connection` (sleitnick, **tabela**) | omitir methodName (→ `"Destroy"`) | `"Disconnect"` ❌ |
| QuickNet `Connect` | `QuickNetConnection` | omitir methodName ou `"Disconnect"` |
| Função de cleanup | `function` | `add(fn, true)` |

> **Nunca** `janitor:add(signalConnection, "Disconnect")` em `GetChangedSignal` — o Janitor chama `Disconnect()` global do Roblox e quebra em runtime com `invalid argument #1 to 'Disconnect' (RBXScriptConnection expected, got table)`.

#### Janitor por jogador (servidor)

```luau
self._janitor:add(Players.PlayerRemoving:Connect(function(player: Player)
	local playerJanitor = self._playerJanitors[player]
	if playerJanitor then
		playerJanitor:destroy()
		self._playerJanitors[player] = nil
	end
end), "Disconnect")
```

Preferir `PlayerRemoving` em vez de destruir o janitor dentro de `AncestryChanged` do próprio jogador.

Todo `Connect`, tween, `task.delay` cancelável e callback de rede → registrar no Janitor.

---

## DataServiceV2

| Arquivo | Papel |
|---|---|
| `src/Constants/Datas/PlayerData.luau` | Template + tipos do save |
| `src/Workers/DataServiceV2.luau` | Wrapper com `Paths` tipados |
| `src/Boot/Server.server.luau` | Inicialização do servidor |
| `src/Boot/Client.client.luau` | Inicialização do cliente |

No runtime, o wrapper é requerido por `ReplicatedStorage.Shareds.Workers.DataServiceV2`.

```luau
-- Servidor — mutação autorizada
const DataServiceV2 = require(ReplicatedStorage.Shareds.Workers.DataServiceV2)
const DataService = DataServiceV2.Server
const Paths = DataServiceV2.Paths

-- Cliente — somente leitura + GetChangedSignal
const DataService = DataServiceV2.Client
```

Mutações **somente no servidor**. Cliente usa `GetChangedSignal` via Janitor — ver tabela em [Janitor](#janitor--obrigatório-com-ciclo-de-vida); **não** passar `"Disconnect"` na Connection do Signal.

---

## Rede (Networker tipada) — gameplay

Um Networker **por Service** em `src/Networker/` (`ReplicatedStorage.Shareds.Networker`). API estilo leif: whitelist client→server + `fire` server→client chama métodos do módulo client. **Tipagem de dados** = `export type` nos parâmetros dos métodos (`GameplayTypes`, `CardsServiceType`, …). Hot paths de dispatch usam `@native`.

```luau
--!strict
const Networker = require(ReplicatedStorage.Shareds.Networker)

-- Server
self.Networker = Networker.server.new("GameplayService", self)
self.Networker:fire(player, "SetEntityState", state :: GameplayTypes.EntityState)

-- Client
self.Networker = Networker.client.new("GameplayService", self)
-- server chama SetEntityState / SetEnergy / AddUnit no próprio módulo
```

| Faça | Evite |
|---|---|
| Tipos Luau nos payloads dos métodos | `fire` com tabelas soltas sem `export type` |
| Validar no Service (whitelist + shape) | Expor todo método do Service ao client |
| Um Networker por Service | RemoteEvent manual solto / ByteNet novo |
| `@native` só no dispatch/fire hot path | `@native` em UI / boots |

Persistência do jogador continua em **DataServiceV2** (não Networker).

## jecs (ECS) — Tower / Unit

Combate e entities em `src/Classes/` no repo, montando em `ReplicatedStorage.Shareds.Classes` no runtime. Skill: **`jecs-ecs`**. jecs **não** é OOP — components + factories.

| Pasta | Papel |
|---|---|
| `Primitives/` | Um component por arquivo + `World` |
| `MetaDatas/` | `Tower.new` / `Unit.new` |
| `Entity/Tower`, `Entity/Units` | `{ Config, create }` — **sem** spawn no `require` |

Comentário `-- Funcionamento:` no topo de MetaDatas, defs e systems (não em todo Primitive). Layout Studio/pastas: skill **`anime-domains-layout`**.

---

## Cliente vs servidor

| Cliente | Servidor |
|---|---|
| Damage numbers, partículas, trails | Validação de ações |
| Camera shake, animações UI | Economia, inventário, dano |
| `ezvisualz`, `stickybillboard` | DataServiceV2 writes |
| `RenderStepped` / `Heartbeat` visual | Anti-cheat básico, rate-limit |

---

## Performance

### Alocação e tabelas

```luau
const buffer = table.create(100)

RunService.Heartbeat:Connect(function()
	table.clear(buffer)
end)
```

| Evitar em loops | Preferir |
|---|---|
| `{}` novo a cada frame | `table.create` + `table.clear` |
| `Vector3.new()` | `const ZERO = Vector3.zero` |
| `Instance.new()` | Object pooling |
| `a .. b .. c` | `table.concat` |

### Tarefas e loops

```luau
-- Ruim (deprecated)
spawn(fn); wait(); delay(1, fn)

-- Bom
task.spawn(fn); task.wait(); task.delay(1, fn)

-- Loop com intervalo
while task.wait(1) do end
```

Em hot paths com arrays densos, preferir loop numérico:

```luau
for i = 1, #list do
	local item = list[i]
end
```

`pairs` / `ipairs` são aceitáveis fora de hot paths.

### Object pooling

Obrigatório para alto volume: damage numbers, projéteis, NPCs, efeitos, drops.

```luau
local effect = EffectPool:Get()
EffectPool:Return(effect)
```

### Compilação nativa

Ver seção [Cabeçalho e otimização de módulo](#cabeçalho-e-otimização-de-módulo). Resumo: `@native` por função > `--!native` por arquivo; nunca em Constants/UI/config.

---

## Segurança

1. Validar **todos** os inputs de rede no servidor
2. Nunca aplicar moeda/dano/inventário só com base no cliente
3. Rate-limit em ações frequentes
4. Campos sensíveis em `Exclude` do DataServiceV2 (não replicam)

---

## Convenções de arquivos

| Sufixo | Tipo Roblox | Executa sozinho? |
|---|---|---|
| `*.server.luau` | Script | Sim (servidor) |
| `*.client.luau` | LocalScript | Sim (cliente) |
| `*.luau` | ModuleScript | Não — só via `require` |

- **PascalCase** para pastas e módulos: `PlayerData`, `InventoryHandler`
- Campos privados: `_camelCase`
- `require` cacheado com `const` no topo do módulo

---

## Checklist do agente

Ao gerar ou editar código, verificar:

1. [ ] Ler `.cursor/learnings/index.md` e learnings com tags da tarefa
2. [ ] `--!strict` no módulo
2. [ ] `const` para bindings imutáveis (services, requires, constantes, primitivos); `const function` para helpers estáveis
3. [ ] `table.freeze` **somente** em tabelas compartilhadas que não podem ser mutadas (save template, deny codes, exports de API)
4. [ ] Tipos semânticos (`IconKey`, `IconId`, `IconsMap`) — nunca `{ [string]: string }` solto
5. [ ] `export type` em APIs públicas
6. [ ] Singleton sem side effects no `require`
7. [ ] `:Init()` / `:init()` idempotente com `assert(not self._initialized)`
8. [ ] Janitor para toda conexão com ciclo de vida
9. [ ] `GetChangedSignal` no Janitor **sem** `"Disconnect"` (usar methodName omitido)
10. [ ] Mutação de dados só no servidor (DataServiceV2)
11. [ ] Rede gameplay via Networker tipada (`src/Networker/`) + tipos nos métodos; save via DataServiceV2
11b. [ ] Entities jecs: MetaData + `{ Config, create }` — sem spawn no `require`
12. [ ] Efeitos visuais no cliente; validação no servidor
13. [ ] Pooling para entidades/efeitos de alto volume
14. [ ] `@native` / `--!native` apenas em hot paths comprovados — nunca em Constants/UI
15. [ ] Legibilidade primeiro; micro-otimizar só com evidência
16. [ ] Personagem/animações/assets compatíveis com **R6** (não R15)
17. [ ] Buscar `src/Utils`, `src/Modules`, `src/Services/<Domínio>` e `src/Workers` **antes** de implementar math, tempo, formatação, som, popup, wrapper ou efeito de UI
18. [ ] Novo código de domínio em `src/Services/<Domínio>/`; constantes de serviço **não** em `src/Constants/PrimaryDatas/`
19. [ ] `src/Modules/` só para infra cross-cutting; `src/Workers/` para wrappers/infra compartilhada
20. [ ] Usar `NumberModule` / `FormatNumber` para números; `SoundModule` para SFX; `Math` / `Lerp` para cálculos — não duplicar inline
21. [ ] Sem `any` em `Services/` — usar `ServiceTypes.Janitor`, `DataServiceV2.PlayerDataStore` e `export type` completo no `self`
22. [ ] Funções locais e métodos com parâmetros/retorno tipados; zero warnings do `--!strict` ao entregar
23. [ ] Se corrigiu erro: documentar em `.cursor/learnings/` e atualizar `index.md`

---

## Anti-patterns

- Corrigir erro sem documentar em `.cursor/learnings/`
- Duplicar learning existente em vez de atualizar o arquivo
- `{ [string]: string }`, `{ [number]: T }` ou outros mapas genéricos — criar `export type` com Key/Value/Map semânticos
- `local` onde `const` bastaria
- `local function` em helper estável quando `const function` serviria
- `table.freeze` em excesso — `const` já protege o binding; freeze só quando o conteúdo compartilhado não pode mutar
- `@native` / `--!native` em Constants, UI, boots ou handlers
- Reatribuir variáveis que deveriam ser constantes
- `Instance.new()` em loops de combate/VFX
- Replicar inventário inteiro a cada mudança
- Lógica de economia em `StarterPlayerScripts`
- Side effects no corpo do módulo (fora de funções)
- `while true do wait() end` sem intervalo
- `RemoteEvent` manual para sistemas novos (usar Networker tipada em `src/Networker/`)
- QuickNet / ByteNet para gameplay novo deste jogo (usar Networker por Service)
- Spawn de entity jecs no corpo do `require` — exportar `{ Config, create }`
- Modelar Tower/Unit como classe OOP com métodos de combate — usar components + systems
- `janitor:add(getChangedSignal:Connect(...), "Disconnect")` — Connection do DataService é tabela, não `RBXScriptConnection`
- Destruir janitor de jogador dentro do callback `AncestryChanged` do mesmo jogador — usar `Players.PlayerRemoving`
- Otimização prematura em setup/config
- "Performance antes da legibilidade" sem hot path identificado
- Formatação numérica, lerp, clamp ou SFX implementados inline — usar `src/Utils` / `src/Modules` existentes
- Criar novo helper genérico sem verificar `src/Utils`, `src/Modules` e `src/Workers` primeiro
- Colocar `*Module` de domínio em `src/Modules/` — usar `src/Services/<Domínio>/`
- Colocar wrapper compartilhado em `src/Services/` quando ele não é domínio de gameplay — usar `src/Workers/`
- Colocar deny codes, settings ou tuning de serviço em `src/Constants/PrimaryDatas/` — usar `src/Services/<Domínio>/`
- `self: any`, `janitor: any`, `data: any` ou `:: any` em singletons de `Services/` — usar `ServiceTypes.Janitor` e `DataServiceV2.PlayerDataStore`
- Funções sem tipagem de parâmetro/retorno em módulos `--!strict`

---

## Referências

- Arquitetura do repositório: [Docs/FRAMEWORK.md](Docs/FRAMEWORK.md) (quando existir)
- Luau: [luau.org/syntax](https://luau.org/syntax/)
- Networker (inspiração): [leifstout/networker](https://github.com/leifstout/networker)
- jecs: [DevForum](https://devforum.roblox.com/t/jecs-optimizing-declarative-scene-graphs-with-ecs/3263203)
- Janitor: [github.com/1ForeverHD/Janitor](https://github.com/1ForeverHD/Janitor)
- DataServiceV2: `Packages/_Index/.../dataservicev2/README.md`
