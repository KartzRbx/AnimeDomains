--!strict
-- Behavior: resolves templates in ReplicatedStorage.Assets (Studio, not Rojo)

--[[
	Canonical layout (Studio):

	ReplicatedStorage.Assets/
	├── Miscs/
	├── Models/
	│   └── Gameplay/
	│       ├── Maps/<MapId>
	│       └── Entitys/
	│           ├── Tower/<Id>   -- e.g. Dummy (R6)
	│           └── Unit/<Id>
	├── Animations/
	│   ├── Player/...
	│   └── Gameplay/Entitys/
	│       ├── _Universal/ Idle, Walk
	│       ├── Tower/<Id>/ Attack, ...
	│       └── Units/<Id>/ ...
	├── Effects/
	│   └── Gameplay/Entitys/SpawnEffect
	└── Sounds/
	    ├── Gameplay/
	    │   ├── Attacks/
	    │   └── Effects/TowersSpawned
	    └── Interface/
	        ├── Effects/
	        ├── Interactions/
	        └── Windows/
]]

const ReplicatedStorage = game:GetService("ReplicatedStorage")

export type MiscCategory = string
export type ModelCategory = string
export type TemplateName = string
export type MapName = string
export type SoundName = string
export type AnimationName = string
export type EffectName = string
export type SoundCategory = "Effects" | "Attacks"
export type InterfaceSoundCategory = "Effects" | "Interactions" | "Windows"
export type GameplayModelCategory = string
export type EntityKind = "Tower" | "Unit"
export type EntityId = string
export type AnimName = string

export type AssetsUtils = {
	getMiscTemplate: (category: MiscCategory, templateName: TemplateName) -> Instance,
	getModelTemplate: (category: ModelCategory, templateName: TemplateName) -> Instance,
	getGameplayModel: (category: GameplayModelCategory, templateName: TemplateName) -> Instance,
	getEntityTowerModel: (entityId: EntityId) -> Model,
	getEntityUnitModel: (entityId: EntityId) -> Model,
	getMaps: (mapName: MapName) -> Instance,
	getSound: (soundName: SoundName) -> Instance,
	getAnimation: (animationName: AnimationName) -> Instance,
	getEntityAnimation: (kind: EntityKind, entityId: EntityId, animName: AnimName) -> Animation,
	getEffect: (effectName: EffectName) -> Instance,
	getGameplayEntityEffect: (effectName: EffectName) -> Instance,
	getGameplayEffectSound: (soundName: SoundName) -> Sound,
	getGameplayAttackSound: (soundName: SoundName) -> Sound,
	getGameplaySound: (category: SoundCategory, soundName: SoundName) -> Sound,
	getInterfaceSound: (category: InterfaceSoundCategory, soundName: SoundName) -> Sound,
	getTowerBillboard: () -> BillboardGui,
	getUnitRangeCircle: () -> Model,
}

local AssetsUtils = {} :: AssetsUtils

const function getAssetsRoot(): Folder
	local assets = ReplicatedStorage:WaitForChild("Assets")
	assert(assets:IsA("Folder"), "ReplicatedStorage.Assets must be a Folder")
	return assets
end

const function waitFolder(parent: Instance, name: string): Folder
	local folder = parent:WaitForChild(name)
	assert(folder:IsA("Folder"), `Assets/{name} must be a Folder`)
	return folder
end

const function findTemplate(parent: Instance, templateName: string, pathLabel: string): Instance
	local template = parent:FindFirstChild(templateName)
	assert(template, `Template not found: {pathLabel}/{templateName}`)
	return template
end

const function getGameplayRoot(): Folder
	local models = waitFolder(getAssetsRoot(), "Models")
	return waitFolder(models, "Gameplay")
end

const function getEntityAnimsRoot(): Folder
	local animations = waitFolder(getAssetsRoot(), "Animations")
	local gameplay = waitFolder(animations, "Gameplay")
	return waitFolder(gameplay, "Entitys")
end

-- Miscs/<category>/<template>
function AssetsUtils.getMiscTemplate(category: MiscCategory, templateName: TemplateName): Instance
	local miscs = waitFolder(getAssetsRoot(), "Miscs")
	local categoryFolder = waitFolder(miscs, category)
	return findTemplate(categoryFolder, templateName, `Assets/Miscs/{category}`)
end

function AssetsUtils.getModelTemplate(category: ModelCategory, templateName: TemplateName): Instance
	local models = waitFolder(getAssetsRoot(), "Models")
	local categoryFolder = waitFolder(models, category)
	return findTemplate(categoryFolder, templateName, `Assets/Models/{category}`)
end

function AssetsUtils.getGameplayModel(category: GameplayModelCategory, templateName: TemplateName): Instance
	local gameplay = getGameplayRoot()
	local categoryFolder = waitFolder(gameplay, category)
	return findTemplate(categoryFolder, templateName, `Assets/Models/Gameplay/{category}`)
end

-- Models/Gameplay/Entitys/Tower/<Id>
function AssetsUtils.getEntityTowerModel(entityId: EntityId): Model
	local gameplay = getGameplayRoot()
	local entitys = waitFolder(gameplay, "Entitys")
	local towerFolder = waitFolder(entitys, "Tower")
	local template = findTemplate(towerFolder, entityId, "Assets/Models/Gameplay/Entitys/Tower")
	assert(template:IsA("Model"), `Tower entity must be Model: {entityId}`)
	return template
end

-- Models/Gameplay/Entitys/Unit/<Id>
function AssetsUtils.getEntityUnitModel(entityId: EntityId): Model
	local gameplay = getGameplayRoot()
	local entitys = waitFolder(gameplay, "Entitys")
	local unitFolder = waitFolder(entitys, "Unit")
	local template = findTemplate(unitFolder, entityId, "Assets/Models/Gameplay/Entitys/Unit")
	assert(template:IsA("Model"), `Unit entity must be Model: {entityId}`)
	return template
end

function AssetsUtils.getMaps(mapName: MapName): Instance
	local gameplay = getGameplayRoot()
	local maps = waitFolder(gameplay, "Maps")
	return findTemplate(maps, mapName, "Assets/Models/Gameplay/Maps")
end

function AssetsUtils.getSound(soundName: SoundName): Instance
	local sounds = waitFolder(getAssetsRoot(), "Sounds")
	return findTemplate(sounds, soundName, "Assets/Sounds")
end

function AssetsUtils.getAnimation(animationName: AnimationName): Instance
	local animations = waitFolder(getAssetsRoot(), "Animations")
	return findTemplate(animations, animationName, "Assets/Animations")
end

--[[
	Resolve: Entitys/Tower|<Units>/<Id>/<Anim> if present,
	else Entitys/_Universal/<Anim> (shared Idle/Walk).
	Note: Units folder (plural) under Animations; Unit (singular) under Models.
]]
function AssetsUtils.getEntityAnimation(kind: EntityKind, entityId: EntityId, animName: AnimName): Animation
	local entitys = getEntityAnimsRoot()
	local kindFolderName = if kind == "Tower" then "Tower" else "Units"
	local kindFolder = entitys:FindFirstChild(kindFolderName)

	if kindFolder and kindFolder:IsA("Folder") then
		local idFolder = kindFolder:FindFirstChild(entityId)
		if idFolder and idFolder:IsA("Folder") then
			local specific = idFolder:FindFirstChild(animName)
			if specific and specific:IsA("Animation") then
				return specific
			end
		end
	end

	local universal = waitFolder(entitys, "_Universal")
	local fallback = findTemplate(universal, animName, "Assets/Animations/Gameplay/Entitys/_Universal")
	assert(fallback:IsA("Animation"), `Universal anim missing: {animName}`)
	return fallback
end

function AssetsUtils.getEffect(effectName: EffectName): Instance
	local effects = waitFolder(getAssetsRoot(), "Effects")
	return findTemplate(effects, effectName, "Assets/Effects")
end

-- Effects/Gameplay/Entitys/<name>  e.g. SpawnEffect (Attachment)
function AssetsUtils.getGameplayEntityEffect(effectName: EffectName): Instance
	local effects = waitFolder(getAssetsRoot(), "Effects")
	local gameplay = waitFolder(effects, "Gameplay")
	local entitys = waitFolder(gameplay, "Entitys")
	return findTemplate(entitys, effectName, "Assets/Effects/Gameplay/Entitys")
end

-- Sounds/Gameplay/Effects/<name>  e.g. TowersSpawned
function AssetsUtils.getGameplayEffectSound(soundName: SoundName): Sound
	return AssetsUtils.getGameplaySound("Effects", soundName)
end

-- Sounds/Gameplay/Attacks/<name>
function AssetsUtils.getGameplayAttackSound(soundName: SoundName): Sound
	return AssetsUtils.getGameplaySound("Attacks", soundName)
end

-- Sounds/Gameplay/<Effects|Attacks>/<name>
function AssetsUtils.getGameplaySound(category: SoundCategory, soundName: SoundName): Sound
	local sounds = waitFolder(getAssetsRoot(), "Sounds")
	local gameplay = waitFolder(sounds, "Gameplay")
	local categoryFolder = waitFolder(gameplay, category)
	local template = findTemplate(categoryFolder, soundName, `Assets/Sounds/Gameplay/{category}`)
	assert(template:IsA("Sound"), `Expected Sound: Gameplay/{category}/{soundName}`)
	return template
end

-- Sounds/Interface/<Effects|Interactions|Windows>/<name>
function AssetsUtils.getInterfaceSound(category: InterfaceSoundCategory, soundName: SoundName): Sound
	local sounds = waitFolder(getAssetsRoot(), "Sounds")
	local interfaceFolder = waitFolder(sounds, "Interface")
	local categoryFolder = waitFolder(interfaceFolder, category)
	local template = findTemplate(categoryFolder, soundName, `Assets/Sounds/Interface/{category}`)
	assert(template:IsA("Sound"), `Expected Sound: Interface/{category}/{soundName}`)
	return template
end

-- Miscs/Gameplay/Entitys/Tower/TowerBillBoard
function AssetsUtils.getTowerBillboard(): BillboardGui
	local miscs = waitFolder(getAssetsRoot(), "Miscs")
	local gameplay = waitFolder(miscs, "Gameplay")
	local entitys = waitFolder(gameplay, "Entitys")
	local towerFolder = waitFolder(entitys, "Tower")
	local template = findTemplate(towerFolder, "TowerBillBoard", "Assets/Miscs/Gameplay/Entitys/Tower")
	assert(template:IsA("BillboardGui"), "TowerBillBoard must be BillboardGui")
	return template
end

-- Miscs/Gameplay/Entitys/Units/RangeCircle
function AssetsUtils.getUnitRangeCircle(): Model
	local miscs = waitFolder(getAssetsRoot(), "Miscs")
	local gameplay = waitFolder(miscs, "Gameplay")
	local entitys = waitFolder(gameplay, "Entitys")
	local units = entitys:FindFirstChild("Units") or entitys:FindFirstChild("Unit")
	assert(units and units:IsA("Folder"), "Assets/Miscs/Gameplay/Entitys/Units (or Unit) missing")
	local template = findTemplate(units, "RangeCircle", "Assets/Miscs/Gameplay/Entitys/Units")
	assert(template:IsA("Model"), "RangeCircle must be Model")
	return template
end

return AssetsUtils
