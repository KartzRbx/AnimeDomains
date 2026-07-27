--!strict
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const AssetsUtils = require(ReplicatedStorage.Shareds.Utils.AssetsUtils)
const EntityHelper = require(ReplicatedStorage.Shareds.Workers.EntityHelper)
const CardsCutscenes = require(script.Parent.CardsCutscenes)
const CardsServiceUtils = require(script.Parent.CardsServiceUtils)
const CardsServiceType = require(script.Parent.CardsServiceType)

const CardsEntityManager = {}


const PATH_ENTITY_NAME = '_Entitys'
const _EntityCache = workspace:WaitForChild('Game'):FindFirstChild(PATH_ENTITY_NAME)

const Entitys: CardsServiceType.CardEntityMap = {}



-----------------------------------------------
---------- << < SERVER_CALLS > >> -------------
-----------------------------------------------
function CardsEntityManager.newEntity(self: CardsEntityManager, payload: CardsServiceType.NewEntityCardData): CardsServiceType.CardEntityEntry?
    assert(RunService:IsServer(), 'Cannot sended for client')
    --[[
          00:16:21.003   ▼  {
                    ["CardId"] = "PlaceholderSix",
                    ["Player"] = KartzBro,
                    ["Position"] =  ▼  {
                       ["X"] = 217.4166259765625,
                       ["Y"] = 59.7091064453125,
                       ["Z"] = 136.0999908447266
                    }
                 }  -  Servidor - CardsEntityManager:10
    ]]

    const entry = `{payload.Player.Name}_{payload.CardId}`


    const function HasEntryData(): boolean
        return Entitys[entry] ~= nil
    end

    if HasEntryData() then
        warn('This Entity has in game')
        return
    end

    const function BuildEntryData()
        const data: CardsServiceType.CardEntityEntry = {
            CardId = payload.CardId,
            Ready = false,
            Attacking = false,
            Player = payload.Player,
            Position = payload.Position,
        }
        Entitys[entry] = data
    end
    BuildEntryData()

    const function GetEntryData(): CardsServiceType.CardEntityEntry
        return Entitys[entry]
    end

    return GetEntryData()
end


-----------------------------------------------
---------- << < CLIENT_CALLS > >> -------------
-----------------------------------------------

function CardsEntityManager.updateEntity(self: CardsEntityManager, props : CardsServiceType.CardEntityEntry)
    assert(RunService:IsClient(), 'Cannot sended for server.')

    const entityName = `{props.Player.Name}_{props.CardId}`
    local EntityTemplate = _EntityCache:FindFirstChild(entityName)

	const entityData = EntityHelper.GetEntityDataByCardId(props.CardId)
	if not entityData then
		return
	end

    if not EntityTemplate then
        -- Create entity at a neutral position; cutscene moves it to the spawn point
        const EntityModel = AssetsUtils.getEntityUnitModel(entityData.ModelID)
        if not EntityModel then
            warn('Entity model not found in assets!')
            return
        end

        EntityTemplate = EntityModel:Clone() :: Model
        EntityTemplate.Name = entityName
        EntityTemplate.Parent = _EntityCache
        EntityTemplate:PivotTo(CFrame.new(Vector3.zero))
    end

    -- Floor hit from server; cutscene lifts by the pet's floor offset
    const spawnPos = Vector3.new(props.Position.X, props.Position.Y, props.Position.Z)
    local SpawnToCutscenePosition = CFrame.new(spawnPos)

    const enemyTowerPosition = CardsServiceUtils.GetEnemyTowerPosition(props.Player)
    if enemyTowerPosition then
        SpawnToCutscenePosition = CFrame.lookAt(
            spawnPos,
            Vector3.new(enemyTowerPosition.X, spawnPos.Y, enemyTowerPosition.Z)
        )
    end

    const Callbacks = CardsCutscenes:SpawnEntityInPosition(EntityTemplate, SpawnToCutscenePosition, entityData.DeployTime) :: CardsServiceType.SpawnEntityCallback
    Callbacks.Completed:Connect(function()
        print('Cutscene is ready')
        -- Make a pathfinding
    end)
end


export type EntityProps = {
    Position: Vector3
}
export type CardsEntityManager = typeof(CardsEntityManager)
return CardsEntityManager
