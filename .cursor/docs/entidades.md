# Sistema de Entidades

O jogo conta com o sistema de Entidade que define as classes de Entidades. Sendo controlada por valores numéricos representativos. Abaixo está a explicação completa do sistema de Entidades.

---

## Aptidão

→ Sistema utiliza o **Jecs** para manter o fluxo de entidades sendo controladas por ID setados.

Link: [Jecs Librarie](https://devforum.roblox.com/t/jecs-optimizing-declarative-scene-graphs-with-ecs/3263203)

No AnimeDomains o World único fica em:

```luau
-- ReplicatedStorage.Shareds.Classes.Mega
const Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
const World = Mega.World -- jecs.World.new(true)
```

- **Template** (`TemplateTag`) = receita da carta/torre (não entra em combate)
- **Instância** = entidade de combate (sem `TemplateTag`), com `UID`, `Model`, `Team`, etc.
- **Autoridade** = servidor. Cliente vê Models / Humanoid / Attributes (espelho via `AttributeMirror`)

---

## Exemplos (padrão Jecs)

```lua
local jecs = require("@jecs")
local world = jecs.World.new()

-- Defina componentes Position e Velocity
local Position = world:component() :: jecs.Id<Vector3>
local Velocity = world:component() :: jecs.Id<Vector3>

-- Defina o sistema Move
local function move(dt)
	for e, pos, vel in world:query(Position, Velocity) do
		pos += vel * dt
		world:set(e, Position, pos)
	end
end

local entity = world:entity()
world:set(entity, Position, Vector3.new(1))
world:set(entity, Velocity, Vector3.new(1, 2, 0))

move(1 / 60)
```

```lua
local world = jecs.World.new()
local pair = jecs.pair
local Name = world:component() :: jecs.Id<string>
local Position = world:component() :: jecs.Id<Vector3>

-- Tags (zero-size): marcadores sem payload
local Star = world:entity()
local Planet = world:entity()
local Moon = world:entity()

local sun = world:entity()
world:add(sun, Star)
world:set(sun, Position, Vector3.one)
world:set(sun, Name, "Sol")

local earth = world:entity()
world:set(earth, Name, "Terra")
world:add(earth, pair(ChildOf, sun))
world:add(earth, Planet)
world:set(earth, Position, Vector3.one * 3)
```

No projeto, o mesmo padrão vira:

```luau
local Mega = require(ReplicatedStorage.Shareds.Classes.Mega)
local World = Mega.World

local UnitTag = require(...Components.Tags.UnitTag)
local Position = require(...Components.Primitives.Position)
local Health = require(...Components.Primitives.Health)

-- Query de combate (ignora templates e mortos)
for entity, pos, health in World:query(Position, Health):with(UnitTag):without(TemplateTag, Dead) do
	-- ...
end
```

---

## Classes de entidade

| Classe | Tag | Datas | Factory | O que é |
|---|---|---|---|---|
| **Unit** | `UnitTag` | `Tree/Datas/Units/*` | `UnitsMetaData` | Tropa colocável (ex.: Sabre) |
| **Tower** | `TowerTag` | `Tree/Datas/Towers/*` | `TowerMetaData` | Torre de combate (ex.: Dummy) — slots Left / Main / Right |

Ambas nascem como **template** (`TemplateTag`) no `EnsureLoaded`, e viram **instância** em `SpawnFromId`.

---

## Parâmetros base (receita / Config)

Valores numéricos e flags que definem a classe. Vêm de `Datas/` e vão para componentes no template.

### Unit (ex.: Sabre)

| Parâmetro | Componente | Controla |
|---|---|---|
| `Id` | `ID` | CardId (`"Sabre"`) — lookup de receita / ataque |
| `Level` | `Level` | Escala de HP/dano no spawn |
| `BaseHealth` | `HealthBase` → `Health` | Vida base / vida atual |
| `BaseDamage` | `BaseDamage` → `Damage` | Dano base / efetivo |
| `BaseRange` | `RangeBase` → `Range` | Alcance de detecção/ataque |
| `DelayAttack` | `DelayAttack` | Tempo da anim / intervalo entre swings (s) |
| `DeployTime` | `DeployTime` | Duração da cutscene de spawn |
| `EnergyCost` | `EnergyCost` | Custo de energia da carta |
| `Walk` | `Walk` | WalkSpeed do Humanoid |
| `Velocity` | `Velocity` | Vetor auxiliar (movimento ECS) |
| `Class` | `Class` | Tier da carta (`"S"`, …) |
| `ModelID` | `ModelID` | Asset do modelo 3D |
| `TargetKind` | `TargetKing` | Quem pode mirar: `Buildings` / `Ground` / `Air` / `All` |
| `CanRetargetTroops` | `CanRetargetTroops` | Se pode aggro em tropas (senão foca building) |

### Tower (ex.: Dummy)

| Parâmetro | Componente | Controla |
|---|---|---|
| `Id` | `ID` | TowerId (`"Dummy"`) |
| `Level` | `Level` | Escala de stats |
| `BaseHealth` / `BaseDamage` / `BaseRange` | `Health*` / `Damage*` / `Range*` | Stats de combate |
| `DelayAttack` | `DelayAttack` | Cadência de tiro da torre |
| `Walk` | `Walk` | Sempre `0` (torre parada) |
| `TargetKind` | `TargetKing` | Filtro de alvos (geralmente `All`) |
| `Upgrade.*PerLevel` | (registry) | Escalamento Clash-style no spawn |

---

## Parâmetros de runtime (instância)

Setados no spawn / pelos systems — não vêm da receita estática.

| Componente | Tipo | Controla |
|---|---|---|
| `UID` | `string` | GUID de rede / lookup (`EntityRegistry`) |
| `Model` | `Model` | Instance Roblox (HRP, Humanoid, atributos) |
| `Owner` | `string` | `Player.Name` ou dono da torre |
| `Team` | `"One" \| "Two"` | Time |
| `Kind` | `string` | `"Unit"` / `"Tower"` |
| `Ready` | `boolean` | Liberada pós-cutscene (só aí move/ataca) |
| `Position` | `Vector3` | Posição autoritativa (HRP → PositionSystem) |
| `Target` | `entity id \| 0` | Alvo atual de combate |
| `BuildingTarget` | `entity id \| 0` | Torre de foco (unidades) |
| `AttackEnabled` | `boolean` | Em range → pode atacar / pausa path |
| `Attacking` | `boolean` | Swing em andamento |
| `LastAttack` | `number` | `os.clock()` do último início de ataque |
| `TowerSlot` | `"Left"\|"Main"\|"Right"` | Slot da torre no mapa |
| `Anchor` | `Model` | Âncora do mapa (não é o corpo de combate) |
| `Dead` (tag) | — | Marcada pra despawn |

---

## O que controla o quê (Systems)

Ordem fixa no servidor (`Tree.Systems.Schedule` → Heartbeat):

```
Position → Targeting → Movement → Attack → Health
```

| System | Lê | Escreve / faz |
|---|---|---|
| **PositionSystem** | `Model` (HRP) | `Position` |
| **TargetingSystem** | `Position`, `Range`, `Team`, `TargetKing`, `Ready` | `Target`, `BuildingTarget`, `AttackEnabled` |
| **MovementSystem** | `Target`, `BuildingTarget`, `AttackEnabled`, `Walk` | Pathfinder / Idle-Walk (pausa se `AttackEnabled`) |
| **AttackSystem** | `AttackEnabled`, `Target`, `DelayAttack`, `LastAttack`, `Attacking` | Dispara ataque; seta `LastAttack` / `Attacking` |
| **HealthSystem** | `Health` | Se `<= 0` → `Dead` → `DespawnEntity` |

### Espelho pra view (Roblox)

`AttributeMirror` copia ECS → Model attributes / Humanoid:

- `Ready`, `AttackEnabled`, Health → Humanoid
- `Attacking` no Model é fonte do swing (limpo no `track.Stopped` do módulo de ataque)

### Lookup

`EntityRegistry`: `UID` ↔ entity ↔ `Model` (O(1)).

---

## Fluxo completo (Unit)

```
Datas/Units/Sabre.luau (Config)
        ↓ EnsureLoaded
UnitsMetaData.registerTemplate  →  entity + UnitTag + TemplateTag
        ↓ CardsEntityManager.newEntity
SpawnFromId + EntityRegistry.Register
        ↓ cutscene
Ready = true
        ↓ Schedule
Targeting escolhe Target / AttackEnabled
Movement anda até range
Attack dispara módulo ATTACK/Server (hitbox + dano)
Health ≤ 0 → Dead → Despawn
```

### Exemplo de spawn (projeto)

```luau
local UnitsMetaData = require(...UnitsMetaData)
local EntityRegistry = require(...EntityRegistry)
local AttributeMirror = require(...AttributeMirror)

local entity = UnitsMetaData.SpawnFromId("Sabre", {
	Position = spawnPos,
	Model = model,
	Level = 12,
	Health = maxHealth,
	UID = uid,
	Owner = player.Name,
	Team = "One",
	Ready = false,
	Kind = "Unit",
})

EntityRegistry.Register(entity, uid, model)
AttributeMirror.SyncEntity(entity)
-- depois da cutscene:
AttributeMirror.SetReady(entity, true)
```

---

## Fluxo completo (Tower)

```
Datas/Towers/Dummy.luau
        ↓
TowerMetaData.SpawnFromId (+ TowerSlot, Anchor)
        ↓
TowerServiceServer coloca no mapa
        ↓
Targeting mira troops → AttackSystem dano direto
        ↓
Left/Right mortas → UnlockEnemyLane
Main morta → TODO EndGame
```

---

## Mapa de pastas

```
src/Classes/
  Mega.luau                          -- World + Jecs
  Tree/
    Build/Components/
      Primitives/                    -- Position, Health, DelayAttack, …
      Tags/                          -- UnitTag, TowerTag, TemplateTag, Dead
    Build/MetaData/                  -- UnitsMetaData, TowerMetaData, Registries
    Datas/Units|Towers/              -- Config puro (sem spawn no require)
    Runtime/                         -- EntityRegistry, AttributeMirror
    Systems/                         -- Schedule + 5 systems
```

---

## Regras rápidas

1. Config em `Datas/` **não** cria entity no `require` — só `EnsureLoaded` / `SpawnFromId`.
2. Systems sempre `:without(TemplateTag, Dead)`.
3. Dano e targeting usam a **entity spawnada** (não só o nome da âncora).
4. Attributes no Model são **espelho**; ECS no servidor é a fonte (exceto `Attacking` no swing).
5. Novo system → pasta `Systems/` + plugar em `Schedule.Start`.

API detalhada: [jecs-tree-runtime.md](./jecs-tree-runtime.md)
