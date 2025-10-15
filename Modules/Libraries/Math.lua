local Math = setmetatable({}, {__index = math})

-- // Linear Equations
function Math:linearTravelTime(origin: Vector3, playerPosition: Vector3, bulletStudsPerSecond: number)
    local playerMagnitude = (origin - playerPosition).Magnitude
    local travelTime = (playerMagnitude / bulletStudsPerSecond)
    return travelTime
end

function Math:linearPredict(origin: Vector3, playerPosition: Vector3, playerVelocity: Vector3, bulletStudsPerSecond: number) -- // linear prediction lol
    return playerVelocity * Math:linearTravelTime(origin, playerPosition, bulletStudsPerSecond)
end

function Math:linearBulletDrop(origin: Vector3, playerPosition: Vector3, bulletStudsPerSecond: number, yStudsReducedPerSecond: number) -- // returns a Y offset to apply to the inputted position
    return Vector3.yAxis * (Math:linearTravelTime(origin, playerPosition, bulletStudsPerSecond) * yStudsReducedPerSecond)
end

-- // Game Specific : AR2
Math.ar2BulletDrop = LPH_JIT_MAX(function(self, origin: Vector3, playerPosition: Vector3, bulletStudsPerSecond: number, projectileGravity: number) -- // projectileGravity is a negative value, so we *-1 to make it positive
    local playerMagnitude = (origin - playerPosition).Magnitude
    return Vector3.new(0, projectileGravity * -1, 0) * ((playerMagnitude / bulletStudsPerSecond) ^ 2)
end)

Math.ar2TravelTime = LPH_JIT_MAX(function(self, origin: Vector3, playerPosition: Vector3, bulletStudsPerSecond: number) 
    local playerMagnitude = (origin - playerPosition).Magnitude
    return math.ceil(playerMagnitude / (bulletStudsPerSecond * 1) / (1 / 60)) * (1 / 60) -- // credit to IHaxU for this math lol
end)

Math.ar2Predict = LPH_JIT_MAX(function(self, origin: Vector3, playerPosition: Vector3, playerVelocity: Vector3, bulletStudsPerSecond: number)
    return playerVelocity * Math:ar2TravelTime(origin, playerPosition, bulletStudsPerSecond)
end)

-- // Game Specific : PF

-- // Misc
Math.HORIZONTAL_VECTOR3 = Vector3.new(1, 0, 1)

Math.randomChance = LPH_NO_VIRTUALIZE(function(self, chance: number) -- // [1 - 100], returns boolean
	return math.random(1, 100) <= chance
end)

Math.dynamicRadius = LPH_NO_VIRTUALIZE(function(self, baseRadius: number, baseCameraFOV: number, cameraFOV: number)
	local factor: number = (baseCameraFOV / cameraFOV)
	return math.max(baseRadius * factor, baseRadius)
end)

Math.clampVectorMagnitude = LPH_NO_VIRTUALIZE(function(self, vector: Vector3, maximumMagnitude: number)
	if (vector == Vector3.zero) then
		return vector
	end
	
	return vector.Unit * math.min(vector.Magnitude, maximumMagnitude)
end)

Math.tweenNumber = LPH_NO_VIRTUALIZE(function(self, before: number, after: number, timeToTake: number, callback: (number) -> any) -- // IHaxU
	local elapsedTime = 0
	local renderSteppedConnection; renderSteppedConnection = game:GetService('RunService').RenderStepped:Connect(function(deltaTime: number)
		elapsedTime += deltaTime
		
		if (elapsedTime >= timeToTake) then
			renderSteppedConnection:Disconnect()
			callback(after)
		else
			callback((after - before) * (elapsedTime / timeToTake) + before)
		end
	end)
end)

return Math