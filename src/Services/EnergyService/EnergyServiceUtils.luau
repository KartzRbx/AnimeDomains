const TweenService = game:GetService("TweenService")
const EnergyServiceUtils = {}


function EnergyServiceUtils.AnimateBar(self: EnergyServiceUtils, bar: Frame, currentEnergy: number, maxEnergy: number)
    local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(bar, tweenInfo, {
        Size = UDim2.new(currentEnergy / maxEnergy, 0, 1, 0)
    })
   return tween:Play() :: Tween
end

export type EnergyServiceUtils = typeof(EnergyServiceUtils)
return EnergyServiceUtils