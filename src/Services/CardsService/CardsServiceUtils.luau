const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const PlayerData = require(ReplicatedStorage.Shareds.Constants.Datas.PlayerData)
const DataServiceV2 = require(ReplicatedStorage.Shareds.Workers.DataServiceV2)

const CardsServiceUtils = {}


export type CardData = {Id: string, Level: number}

function CardsServiceUtils._GetCardDataWithID(CardId, toPlayer: Player?):(string?, CardData?)
    const Paths = DataServiceV2.Paths

    local resultUID, resulCardData 

    if RunService:IsClient() and Players.LocalPlayer then
        const DataService = DataServiceV2.Client

        const data = DataService:WaitForData()
        const Cards = data:Get(Paths.Game.Cards)

        for UID, cardData in Cards do
            if cardData.Id == CardId then
                resultUID = UID
                resulCardData = cardData
                break
            end
        end
    else
        const Data = DataServiceV2.Server:WaitFor(toPlayer)
        const Cards = Data:Get(Paths.Game.Cards)
            
        for UID, cardData in Cards do
            if cardData.Id == CardId then
                resultUID = UID
                resulCardData = cardData
                break
            end
        end
    end

    return resultUID, resulCardData
end


return CardsServiceUtils