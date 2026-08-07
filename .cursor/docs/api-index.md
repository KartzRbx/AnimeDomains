# AnimeDomains — Index de Utils / APIs

Índice imenso de funções utilitárias e APIs públicas do jogo (Cards, Tower, Gameplay, Energy, Workers, Utils, Tree ECS).

**Convenção de require (runtime):**
- Disco `src/X` → `ReplicatedStorage.Shareds.X` (client/shared)
- Services server → `ServerScriptService.Source.Services.<Name>` (mapeado no Rojo)

---

## Sumário

1. [Workers](#1-workers)
2. [Utils (Shareds.Utils)](#2-utils-sharedsutils)
3. [CardsService](#3-cardsservice)
4. [TowerService](#4-towerservice)
5. [GameplayService](#5-gameplayservice)
6. [EnergyService](#6-energyservice)
7. [Tree ECS (Classes)](#7-tree-ecs-classes)
8. [Attacks / Combate](#8-attacks--combate)
9. [Modules / UI](#9-modules--ui)
10. [Constants / Datas](#10-constants--datas)

---

## 1. Workers

### EntityHelper
**Require:** `ReplicatedStorage.Shareds.Workers.EntityHelper`

| Função | Retorno | Descrição |
|---|---|---|
| `GetHealthPerLevel(BaseHealth)` | `number` | ~10% do HP base por nível |
| `GetDamagePerLevel(BaseDamage)` | `number` | ~10% do dano base por nível |
| `GetEntityFloorOffset(Entity)` | `number` | Offset Y pé → pivot |
| `CalculateDamage(props)` | `number` | Dano com level / bonus / multiplier |
| `CalculateHealth(props)` | `number` | HP com level / bonus / multiplier |
| `CalculateRange(props)` | `number` | Range com bonus / multiplier (sem level) |
| `GetTowerAnchor(tower)` | `Vector3?` | GripEntity ou pivot |
| `GetEntityCharacterForUID(uid)` | `Model?` | Model por UID (registry → `_Entitys` → Teams) |
| `GetSpawnedTowerForAnchor(anchor)` | `Model?` | Âncora → entity spawnada (`TowerSlot`) |
| `GetCombatTargetForId(targetId)` | `Model?` | UID ou nome de âncora → model combatível |
| `IsTowerAlive(tower)` | `boolean` | Destroyed / Humanoid / spawn |
| `GetTowerAnchorForSpawned(spawned)` | `Model?` | Entity → âncora Left/Main/Right |
| `IsMainTowerTargetable(leftAlive, rightAlive)` | `boolean` | Main liberada se alguma side caiu |
| `GetTargetableEnemyTowers(teamName)` | `{ Model }` | Âncoras inimigas atacáveis |
| `GetClosestEnemyTower(teamName, fromPos)` | `Model?` | Torre inimiga mais próxima |
| `GetEnemyMainTower(teamName)` | `Model?` | Âncora Main inimiga |
| `GetEnemyMainTowerPosition(teamName)` | `Vector3?` | Posição Main inimiga |
| `GetTowerDetectionRadius(tower, unitRange)` | `number` | Raio de detecção vs torre |
| `GetTowerApproachStopRadius(tower, unitRange)` | `number` | Onde a unit para ao aproximar |
| `GetTowerApproachPosition(tower, fromPos, stopRadius)` | `Vector3` | Ponto de approach no chão |
| `GetPathAgentParameters(model)` | `table` | Params PathfindingService |
| `GetEnemyTowerPosition(teamName, fromPos?)` | `Vector3?` | Closest ou Main |
| `GetTowerDataById(towerId)` | `TowerEntityData?` | Receita torre (registry) |
| `GetEntityDataByCardId(cardId)` | `EntityData?` | Receita unit (registry) |
| `GetEntityForName(Name, Kind?)` | `(EntityDef?, EntityType?)` | Def antiga Tree/Datas por nome |

### CombateStateHandler
**Require:** `ReplicatedStorage.Shareds.Workers.CombateStateHandler`

| Função | Retorno | Descrição |
|---|---|---|
| `RegisterAttackSession(uid, targetUID, config)` | — | Sessão de hit claim |
| `ProcessAttackHitClaim(player, uid, targetUID, hitIndex, hitTime)` | `AttackHitClaimResult` | Valida hit cliente |
| `PlayerCanEmitAttackForCardID(player, UID, CardID)` | `PlayerCanEmitAttackResult` | Pode emitir ataque? |
| `ApplyDamageToTarget(target, damage, meta?)` | `boolean` | Aplica dano (ECS Health / Humanoid) |
| `ManagerEntityForPlayer(player, CardId)` | — | Stub |

### DataServiceV2 (facade)
**Require:** `ReplicatedStorage.Shareds.Workers.DataServiceV2`

| Campo | Descrição |
|---|---|
| `Server` | API server kartzrbx DataServiceV2 |
| `Client` | API client |
| `Paths` | Schema PlayerData tipado |
| `Enums` | Enums do package |

Uso típico server: `DataServiceV2.Server:WaitFor(player)`, `Get` / `Set` com `Paths`.

---

## 2. Utils (`Shareds.Utils`)

### PlacementZoneUtil
**Require:** `…Utils.PlacementZoneUtil`

| Função | Retorno | Descrição |
|---|---|---|
| `RequiresEntitySpawnZone(kind)` | `boolean` | Unit/Structure precisam de zona |
| `GetEnemyTeam(teamName)` | `TeamName` | One↔Two |
| `GetZonePart(teamName, zoneId)` | `BasePart?` | Main/Left/Right/Base |
| `IsLaneUnlocked(attackerTeam, lane)` | `boolean` | Lane liberada? |
| `GetUnlocks(attackerTeam)` | `TeamUnlocks` | `{ Left, Right }` |
| `GetEnemyBlockOverlayId(attackerTeam)` | `OverlayId` | Overlay de limitação ativo |
| `GetEnemySpawnZoneParts(enemyTeam)` | `{ BasePart }` | Todas as parts da zona |
| `UnlockEnemyLane(attackerTeam, lane)` | — | Libera lane + attr Unlocked |
| `ResetUnlocks()` | — | Reset match (lanes + Destroyed anchors) |
| `GetEntitySpawn(teamName)` | `BasePart?` | Zona Main do time |
| `GetEntityLimitations()` | `Instance?` | Barreiras do Build |
| `IsOnBlockedEnemyFloor(attackerTeam, worldPos)` | `boolean` | Em overlay bloqueado? |
| `IsInsideEntityBarrier(worldPos)` | `boolean` | Dentro de EntityLimitations? |
| `IsTooCloseToTower(worldPos)` | `boolean` | Perto demais de torre |
| `GetZonesForTeam(teamName)` | `{ ZonePart }` | Zonas próprias (Main) |
| `IsPointInPart(worldPos, part)` | `boolean` | AABB local |
| `IsPointInZone(worldPos, part)` | `boolean` | Zona (Union surface-aware) |
| `CanPlace(teamName, worldPos, kind)` | `boolean` | Pode dropar carta aqui? |

### AssetsUtils
**Require:** `…Utils.AssetsUtils`

| Função | Retorno | Descrição |
|---|---|---|
| `getMiscTemplate(category, templateName)` | `Instance` | Misc templates |
| `getModelTemplate(category, templateName)` | `Instance` | Model templates |
| `getGameplayModel(category, templateName)` | `Instance` | Gameplay models |
| `getEntityTowerModel(entityId)` | `Model` | Modelo torre |
| `getEntityUnitModel(entityId)` | `Model` | Modelo unit |
| `getMaps(mapName)` | `Instance` | Mapa |
| `getSound(soundName)` | `Instance` | Som genérico |
| `getAnimation(animationName)` | `Animation` | Anim genérica |
| `getEntityAnimation(kind, entityId, animName)` | `Animation?` | Anim Tower/Unit |
| `GetEntityAnimationForUID(uid, animName)` | `Animation?` | Anim por UID |
| `GetDefaultEntityAnimation(animationName)` | `Animation` | Fallback `_Universal` |
| `GetCardIdForEntityUID(uid)` | `string?` | CardId do model |
| `getEffect(effectName)` | `Instance` | Effect |
| `getGameplayEntityEffect(effectName)` | `Instance` | VFX entity |
| `getGameplayEffectSound(soundName)` | `Sound` | SFX effect |
| `getGameplayAttackSound(soundName)` | `Sound` | SFX attack |
| `getGameplaySound(category, soundName)` | `Sound` | SFX gameplay |
| `getInterfaceSound(category, soundName)` | `Sound` | SFX UI |
| `getTowerBillboard()` | `BillboardGui` | Template billboard torre |
| `getUnitRangeCircle()` | `Model` | Círculo de range |

### AnimationUtil
**Require:** `…Utils.AnimationUtil`

| Função | Retorno | Descrição |
|---|---|---|
| `PrepareModel(model)` | `Animator` | Unanchor + Animator |
| `ResolveAnimation(kind, entityId, animName)` | `Animation` | Resolve asset |
| `ResolveAnimationForUID(uid, animName)` | `Animation?` | Por UID |
| `ResolveDefaultAnimation(animName)` | `Animation` | Universal |
| `LoadTrackForUID(model, uid, animName)` | `AnimationTrack?` | Load novo track |
| `GetOrLoadTrackForUID(model, uid, animName)` | `AnimationTrack?` | Cache por UID |
| `ClearTrackCacheForUID(uid)` | — | Limpa cache |
| `PlayEntityAnimationForUID(model, uid, animName, fadeTime?)` | `AnimationTrack?` | Play |
| `Bind(model, kind, entityId)` | `AnimationPlayer` | Player Idle/Walk/… |

### AttackUtils
**Require:** `…Utils.AttackUtils`

| Função | Retorno | Descrição |
|---|---|---|
| `FindAttachment(attacker, names?)` | `Attachment?` | Acha attachment hitbox |
| `GetDefaultHitBoxCFrame(attacker)` | `CFrame` | CF default hitbox |
| `NewHitBox(options)` | `AttackHitBox` | Cria hitbox part |
| `BindTrackHitBox(options)` | `janitor` | Liga hits no TimePosition do track |

### CollisionGroupUtil
**Require:** `…Utils.CollisionGroupUtil`

| Função | Retorno | Descrição |
|---|---|---|
| `Init()` | — | Cria groups + regras |
| `AssignEntity(model)` | — | Group Entities |
| `AssignEntityBarriers(root)` | — | Group EntityBarriers + PathfindingModifier |

Campos: `Players`, `Entities`, `EntityBarriers`.

### MathUtils
**Require:** `…Utils.MathUtils`

| Função | Retorno | Descrição |
|---|---|---|
| `cubicBezier(t, start, finish)` | `Vector3` | Bezier cubica |
| `spaceshipHover(elapsed, anchor, lookTarget)` | `CFrame` | Hover animado |
| `float(elapsed, anchor, lookTarget)` | `CFrame` | Float suave |

### NumberFormater
**Require:** `…Utils.NumberFormater`

| Função | Retorno | Descrição |
|---|---|---|
| `formatInteger(value)` | `string` | Inteiro |
| `formatExact(value)` | `string` | Exato |
| `formatCompact(value)` | `string` | Compacto (1.2K) |
| `formatSigned(value)` | `string` | Com sinal |
| `formatDelta(value)` | `string` | Delta |
| `formatPercent(value, decimals?)` | `string` | % |
| `WithDots(value)` | `string` | Separador milhar |
| `formatTime(totalSeconds)` | `string` | Tempo |
| `TimeMS(totalSeconds)` | `string` | MM:SS |
| `TimeCompact(totalSeconds)` | `string` | Compacto |
| `formatCooldown(totalSeconds)` | `string` | Cooldown UI |
| `Date(input)` | `string` | Data |
| `DateTime(input)` | `string` | Data+hora |
| `DateTimeFull(input)` | `string` | Completo |

### VFXUtil
**Require:** `…Utils.VFXUtil` (export `VisualEffectsUtils` / similar)

| Função | Retorno | Descrição |
|---|---|---|
| `EmitAll(source, parent)` | `EffectPlayback` | Emit todos emitters |
| `EmitFor(source, parent, filter)` | `EffectPlayback` | Emit filtrado |
| `EmitExcluded(source, parent, exclude)` | `EffectPlayback` | Emit excluindo nomes |

### HumanoidManager
**Require:** `…Utils.HumanoidManager`

| Função | Retorno | Descrição |
|---|---|---|
| `new(model, config?)` | `HumanoidManager` | Slots Idle/Walk |
| `:StopAll(fadeTime?)` | — | Para anims |
| `:Destroy()` | — | Cleanup |

Slots: `Hum.Idle:Play()`, `Hum.Walk:Play()`.

### PlayerUtils
**Require:** `…Utils.PlayerUtils`

| Função | Retorno | Descrição |
|---|---|---|
| `getPlayerGui(player?)` | `PlayerGui` | |
| `waitMain(player?)` | `ScreenGui` | Espera Main |
| `wait(path, player?, timeout?)` | `Instance` | Wait path UI |
| `find(path, player?)` | `Instance?` | Find path UI |
| `getInterface(path, player?, timeout?)` | `GuiObject` | Wait tipado |
| `findInterface(path, player?)` | `GuiObject?` | Find tipado |

---

## 3. CardsService

### CardsServiceUtils
**Require:** `…Services.CardsService.CardsServiceUtils`

| Função | Retorno | Descrição |
|---|---|---|
| `NormalizeDeck(deck)` | `{ string }` | Normaliza deck |
| `CreateMatchCardState(deck)` | `MatchCardState` | Estado mão + next |
| `PlayCardFromHand(state, slotIndex, cardId)` | `(boolean, string?)` | Consome carta da mão |
| `ToSyncPayload(state)` | `{ Hand, NextCard }` | Payload sync client |
| `_GetCardDataWithID(CardId, toPlayer?)` | `PlayerCardData?` | Dados da carta do player |
| `GetPlayerTeam(player)` | `TeamName?` | Time via Character.Parent |
| `GetEntityLookCFrame(player, spawnPos)` | `CFrame` | Look toward enemy tower |
| `GetEntityGoalCFrame(player, spawnPos, model)` | `CFrame` | Spawn no chão + look |

### CardsServiceServer
**Require:** `ServerScriptService.Source.Services.CardsService`

| Função | Retorno | Descrição |
|---|---|---|
| `BindPlayerHand(player, deck)` | — | Cria mão do match |
| `ClearPlayerHand(player)` | — | Limpa mão |
| `GetPlayerHand(player)` | `MatchCardState?` | Estado atual |
| `PutCardInPlace(...)` | — | Drop carta → spawn entity |
| `StateChangeReadyForUID(ownerPlayer, UID, CardId)` | — | Ready pós-cutscene |
| `Init()` | `self` | Boot remotes |

### CardsServiceClient
| Função | Descrição |
|---|---|
| `Init()` | Boot client |

### CardsEntityManager
**Require:** `…CardsService.Api.CardsEntityManager`

| Função | Descrição |
|---|---|
| `_GetEntityWithUID(UID)` | Entry por UID |
| `_UpdateUnitBillboard(props)` | Atualiza billboard HP |
| `_RemoveUnitBillboard(props)` | Remove billboard |
| `_PlayEntityDeathPresentationServer(model, uid)` | Death server → delay |
| `_PlayEntityDeathPresentationClient(model, uid)` | Death client VFX |
| `BuildEntityPath(OwnerPlayer, Model, CardId, UID, spawnPos)` | Pathfinder + Attack bind |
| `BuildTowerAttack(model, towerData, uid, teamName)` | Hooks Died torre |
| `StopEntityPath(UID)` | Para path |
| `_OnTowerDefeated(model)` | Lane unlock / EndGame Main |
| `DespawnEntity(uid, model)` | Despawn completo |
| `newEntity(payload)` | Spawn server entity |
| `updateEntity(props)` | Cutscene client + Ready fire |
| `BindAttackReplicated()` | Replica ataque client |
| `InitAttackValidation()` | Validação hits |
| `PlayerCanEmitAttackForCardID(...)` | Facade combate |
| `_MakeAttackValidationKey(uid, cardId)` | Key validação |
| `_PlayAttackVisual(payload)` | Visual ataque |

### CardsCutscenes
**Require:** `…CardsService.Api.CardsCutscenes`

| Função | Descrição |
|---|---|
| `ClockTimeEffect(Entity, deployTime)` | Relógio deploy |
| `EmitSpawnEffect(...)` | VFX spawn |
| `SpawnEntityInPosition(Entity, CFrame, deploytime)` | Cutscene queda → Completed |

### PreviewModelManager
| Função | Descrição |
|---|---|
| `onBindRaycast(teamName, payload)` | Preview no chão + overlay + CanPlace |

### CardsServiceInterface (client UI)
| Função | Descrição |
|---|---|
| `ResolveHud()` | Frame HUD |
| `ClearDeck()` | Limpa slots |
| `ManagerInsertCardHandle(...)` | Insere card handle |
| `RenderNextCard(cardId, animate)` | Next card UI |
| `ReplaceSlot(...)` | Troca slot |
| `RenderHandState(state)` | Render mão |
| `OnSyncCardHand(state)` | Sync remote |
| `OnEntityState(state)` | Resolve time local |
| `Init()` | Boot UI |

### CardLayout / Palette / Shine
| Módulo | Função | Descrição |
|---|---|---|
| `CardLayout` | `Card.Make(cardData, enabledCardLevelBar?)` | Cria card handle |
| `PaletteLib` | `GetBackgroundCanvas(card)` | CanvasGroup Background |
| `PaletteLib` | `ExtractFromFrontAsync(card)` | Paleta async |
| `PaletteLib` | `ExtractFromFront(card)` | Paleta front |
| `PaletteLib` | `ExtractFromBackground(card)` | Paleta background |
| `PaletteLib` | `Extract(card)` | Paleta default |
| `PaletteLib` | `ClearCache()` | Limpa cache |
| `ShineLib` | `ApplyShine(...)` | Shine UI |

---

## 4. TowerService

### TowerServiceUtils
**Require:** `…TowerService.TowerServiceUtils`

| Função | Retorno | Descrição |
|---|---|---|
| `GetSlotModelName(slot)` | `TowerSlotModelName?` | `"Left"` → `"LeftTower"` |
| `GetSlotFromModelName(modelName)` | `TowerSlot?` | `"LeftTower"` → `"Left"` |
| `GetAllSlots()` | `{ TowerSlot }` | Left, Main, Right |

### TowerServiceServer
**Require:** `ServerScriptService.Source.Services.TowerService`

| Função | Descrição |
|---|---|
| `SpawnMatchTowers(entityState)` | Spawna torres One/Two |
| `Init()` | Boot |

### TowerServiceClient
| Função | Descrição |
|---|---|
| `updateTowerBillboard(...)` | HP billboard |
| `bindTowerVisuals(towerModel)` | Bind visuals |
| `ResolveTowerEntitys()` | Resolve spawnados |
| `Init()` | Boot |

---

## 5. GameplayService

### GameplayServiceServer
**Require:** `ServerScriptService.Source.Services.GameplayService`

| Função | Retorno | Descrição |
|---|---|---|
| `CreateMatchId()` | `MatchId` | ID único |
| `CreateDefaultProperties(player)` | `GameplayProperties` | Props default single |
| `GetDefaultTeamData(owner)` | `TeamData` | Owner + Towers + Deck |
| `GetEntityStateForPlayer(player)` | `EntityState` | One/Two TeamData |
| `BuildMap(mapId)` | `Result` | Clona mapa |
| `SendMatchState(player)` | — | Fire EntityState |
| `TeleportPlayer(player, teamName)` | — | TP spawn do time |
| `StartMatch(props)` | `Match` | Inicia match |
| `StartMatchCommand(mapName, gamemode, players)` | — | Cmdr |
| `EndMatchCommand(players)` | — | Cmdr |
| `OnEnemyTowerDestroyed(attackerTeam, towerSide)` | — | Unlock lane |
| `GetMatchByPlayer(player)` | `Match?` | Match do player |
| `GetOwnerByTeam(teamName)` | `string?` | Dono do time (`One`/`Two`) |
| `EndMatch(matchId)` | `Result` | Finaliza match |
| `EndPlayerMatch(player)` | `Result` | Finaliza pelo player |
| `Init()` | `self` | Boot |

### GameplayServiceClient
| Função | Descrição |
|---|---|
| `ToVector3(position)` | Vec3Data → Vector3 |
| `SetEntityState(state)` | Guarda + UI |
| `EnableGameplayInterface()` | Liga HUD gameplay |
| `SetEnergy(energy)` | Energy UI |
| `AddUnit(unit)` | (stub/net) |
| `UpdateUnit(unit)` | |
| `RemoveUnit(netId)` | |
| `Init()` | Boot remotes |

### GameplayBuildMap
**Require:** `…GameplayService.GameplayBuildMap`

| Função | Descrição |
|---|---|
| `BuildMap(mapModel)` | Sync Build + Teams |
| `BindForMap(mapId)` | Resolve island + BuildMap |

---

## 6. EnergyService

### EnergyServiceServer
**Require:** `ServerScriptService.Source.Services.EnergyService` (ou path Rojo)

| Função | Retorno | Descrição |
|---|---|---|
| `SetMultiplierMode(mode)` | — | Modo regen |
| `RenderEnergyLoop()` | — | Loop regen |
| `FetchPlayerEnergy(player)` | — | Sync energy client |
| `GetPlayerEnergy(target)` | `number?` | Energia atual |
| `SetPlayerEnergy(target, targetEnergy)` | `any` | Seta energia |
| `Init()` | `self` | Boot |

### EnergyServiceClient
| Função | Descrição |
|---|---|
| `FetchPlayerEnergy(currentEnergy)` | Atualiza barra |
| `Init()` | Boot |

### EnergyServiceUtils
| Função | Descrição |
|---|---|
| `AnimateBar(bar, currentEnergy, maxEnergy)` | Tween barra |

---

## 7. Tree ECS (Classes)

### Mega
**Require:** `…Classes.Mega`

| Campo / função | Descrição |
|---|---|
| `World` | `jecs.World` único |
| `Jecs` | Package jecs |
| `Utils.GetUnitMetadataWithID(UnitID)` | Template entity por ID |

### EntityRegistry
**Require:** `…Tree.Runtime.EntityRegistry`

| Função | Descrição |
|---|---|
| `Register(entity, uid, model?)` | Indexa UID/Model |
| `GetByUid(uid)` | entity? |
| `GetByModel(model)` | entity? |
| `GetModel(entity)` | Model? |
| `GetUid(entity)` | string? |
| `Unregister(entity)` | Limpa maps |
| `Delete(entity)` | Unregister + World:delete |

### AttributeMirror
**Require:** `…Tree.Runtime.AttributeMirror`

| Função | Descrição |
|---|---|
| `SyncEntity(entity)` | ECS → attrs/Humanoid |
| `SetReady(entity, ready)` | |
| `SetAttackEnabled(entity, enabled)` | |
| `SetAttacking(entity, attacking)` | |
| `SetHealth(entity, health)` | |

### UnitsMetaData
**Require:** `…Tree.Build.MetaData.UnitsMetaData`

| Função | Descrição |
|---|---|
| `new(config)` / `registerTemplate(config)` | Registra template |
| `EnsureLoaded()` | Carrega Datas/Units |
| `GetCardParams(unitId)` | Params carta |
| `GetTemplate(unitId)` | Entity template |
| `SpawnFromId(unitId, options?)` | Instância runtime |

### TowerMetaData
**Require:** `…Tree.Build.MetaData.TowerMetaData`

| Função | Descrição |
|---|---|
| `new` / `registerTemplate` | Template torre |
| `EnsureLoaded()` | Carrega Datas/Towers |
| `GetCardParams(towerId)` | Params torre |
| `GetTemplate(towerId)` | Entity template |
| `SpawnFromId(towerId, options?)` | Instância (+ Anchor/Slot) |

### UnitCardRegistry / TowerCardRegistry
| Função | Descrição |
|---|---|
| `Set(id, params)` | Grava |
| `Get(id)` | Lê |
| `MarkLoaded()` | Flag |
| `IsLoaded()` | boolean |
| `EnsureLoaded()` | Carrega MetaData |

### Systems
**Require:** `…Tree.Systems.<Name>`

| System | Funções | Descrição |
|---|---|---|
| `Schedule` | `Start()`, `Stop()` | Heartbeat runner |
| `PositionSystem` | `Update(dt)` | HRP → Position |
| `TargetingSystem` | `Update(dt)` | Target / AttackEnabled |
| `MovementSystem` | `RegisterUnit`, `Unregister`, `Update` | Pathfinder |
| `AttackSystem` | `BindUnitAttack`, `Unbind`, `Update` | Ataques |
| `HealthSystem` | `Update(dt)` | Dead → Despawn |

---

## 8. Attacks / Combate

### EntityActionManager
**Require:** `…Constants.PrimaryDatas.AttacksData.EntityActionManager`

| Função | Descrição |
|---|---|
| `GetUnitAttack(UID)` | MetaTable CanAttack/Attack/Destroy |
| `RunUnitAttackClient(payload)` | Roda Client attack module |

MetaTable: `AttackName`, `UID`, `TargetUID`, `CanAttack`, `Changed`, `:Attack()`, `:Destroy()`.

### Módulos por carta
`…AttacksData.Units.<CardId>.Attack.Server` / `.Client` / `.Config` — factory de handler.

---

## 9. Modules / UI

### UIModule
**Require:** `…Modules.UIModule`

| Função | Descrição |
|---|---|
| `GetMainGui()` | ScreenGui Main |
| `Init()` | Boot UI module |
| `RegisterInterface(Name, Frame, Region?)` | Registra frame |
| `GetInterface(Name)` | Frame? |
| `IsOpen(Name)` | boolean |
| `ShowInterface(Name)` | |
| `HideInterface(Name)` | |
| `ToggleInterface(Name)` | |
| `HideAllInterfaces()` | |
| `MouseClickEffect(ScreenPosition, Config?)` | Ripple click |
| `CancelButtonScale(Button)` | |
| `HoverButton(Button, Config?)` | Hover scale |
| `ClickButton(Button, Config?)` | Click scale |
| `BindButton(Button, OnClick?, Config?)` | Hover+Click |
| `BindGlobalPointerClicks(Config?)` | Click effect global |

---

## 10. Constants / Datas

### Islands
**Require:** `…Constants.Datas.Islands`

| Função | Descrição |
|---|---|
| `GetMapWithId(IslandId)` | Model do mapa |
| `IslandList` | Lista de islands |

### PlayerData
**Require:** `…Constants.Datas.PlayerData` — schema (não funções); usado via `DataServiceV2.Paths`.

---

## Cheat-sheet rápido (os mais usados)

```luau
-- Time / dono
CardsServiceUtils.GetPlayerTeam(player)
GameplayService:GetOwnerByTeam("One"|"Two")
PlacementZoneUtils.GetEnemyTeam(teamName)

-- Energia
EnergyService:GetPlayerEnergy(player)
EnergyService:SetPlayerEnergy(player, value)
EnergyService:FetchPlayerEnergy(player)

-- Entity lookup
EntityHelper.GetEntityCharacterForUID(uid)
EntityRegistry.GetByUid(uid)
EntityHelper.GetCombatTargetForId(id)
EntityHelper.GetEntityDataByCardId(cardId)
EntityHelper.GetTowerDataById(towerId)

-- Stats
EntityHelper.CalculateDamage({ BaseDamage, Level, ... })
EntityHelper.CalculateHealth({ BaseHealth, Level, HealthPerLevel, ... })

-- Placement
PlacementZoneUtils.CanPlace(team, pos, "Unit")
PlacementZoneUtils.UnlockEnemyLane(attackerTeam, "Left"|"Right")
PlacementZoneUtils.IsLaneUnlocked(attackerTeam, lane)

-- Combate
CombateStateHandler:ApplyDamageToTarget(model, damage, meta)
CombateStateHandler:PlayerCanEmitAttackForCardID(player, uid, cardId)
AttributeMirror.SetHealth(entity, hp)
AttributeMirror.SetReady(entity, true)

-- Assets / anim
AssetsUtils.getEntityUnitModel(id)
AnimationUtil.GetOrLoadTrackForUID(model, uid, "Attack")
AnimationUtil.PlayEntityAnimationForUID(model, uid, "Idle")
```

---

*Gerado a partir do source em `src/`. Para detalhes ECS: [entidades.md](./entidades.md) · [jecs-tree-runtime.md](./jecs-tree-runtime.md).*
