-- // TODO: Improve this shitty ass velocity calc

local Prediction = {}
Prediction.Players = {}
Prediction.Cleaner = REQUIRE_MODULE('Modules/Classes/Cleaner.lua').new()

-- // Methods
function Prediction:setEnabled(enabled)
    Prediction.Cleaner:Clean()

    if (enabled) then
        Prediction.Cleaner:AddConnection(game:GetService('RunService').Heartbeat:Connect(LPH_JIT_MAX(function(deltaTime)
            debug.profilebegin('Prediction Velocity Calculation')
        
            for playerObject, predictionData in next, Prediction.Players do
                if (not playerObject.Character) or (not playerObject.Character.PrimaryPart) then
                    predictionData.Velocity = Vector3.zero
                    predictionData.LastPosition = nil
                    predictionData.Position = nil
                    continue
                end
        
                local position = playerObject.Character.PrimaryPart.Position
                if (not predictionData.LastPosition) then
                    predictionData.LastPosition = position
                    predictionData.Position = position
                end
        
                -- // Velocity Calculation
                local distance = (position - predictionData.LastPosition)
                local velocity = (distance / deltaTime)
        
                -- // Write Data
                predictionData.Velocity = predictionData.Velocity
                predictionData.LastPosition = predictionData.Position
                predictionData.Position = position
            end
        
            debug.profileend()
        end)))
    end
end

function Prediction:addPlayer(playerObject)
    Prediction.Players[playerObject] = {
        Velocity = Vector3.zero,
    }
end

function Prediction:removePlayer(playerObject)
    Prediction.Players[playerObject] = nil
end 

Prediction.getVelocity = LPH_NO_VIRTUALIZE(function(self, playerObject)
    local predictionData = Prediction.Players[playerObject]
    return (predictionData and predictionData.Velocity) or (Vector3.zero)
end)

return Prediction