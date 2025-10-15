local ReplicationUtility = {}

local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local LocalPlayer = Players.LocalPlayer
local Signal = REQUIRE_MODULE('Modules/Classes/FastSignal.lua')

-- // local functions
local onCharacterAdded = LPH_NO_VIRTUALIZE(function(characterObject: Model)
	ReplicationUtility.Character = characterObject
	ReplicationUtility.Humanoid = characterObject:WaitForChild('Humanoid')
	ReplicationUtility.rootPart = characterObject:WaitForChild('HumanoidRootPart')

	ReplicationUtility.rootPart:GetPropertyChangedSignal('Anchored'):Connect(function()
		if (not ReplicationUtility.rootPart.Anchored) or (os.clock() - ReplicationUtility.LastAnchor < 0.1) then
			return
		end

		ReplicationUtility.OnSetback:Fire()
	end)
	
	table.clear(ReplicationUtility.History)
end)

-- // Properties
ReplicationUtility.LastClientTeleportPosition = Vector3.zero
ReplicationUtility.LastClientTeleport = os.clock()
ReplicationUtility.LastAnchor = os.clock()
ReplicationUtility.OnSetback = Signal.new()
ReplicationUtility.TeamMates = {}
ReplicationUtility.History = {}

-- // Methods
ReplicationUtility.GetCharacters = LPH_NO_VIRTUALIZE(function()
	local characters = {}

	for _, playerObject: Player in next, Players:GetPlayers() do
		if (playerObject == Players.LocalPlayer) or (ReplicationUtility.TeamMates[playerObject.Name]) then
			continue
		end

		if (not playerObject.Character) or (not playerObject.Character.PrimaryPart) then
			continue
		end

		characters[playerObject] = playerObject.Character
	end

	return characters :: {Model?}
end)

ReplicationUtility.Teleport = LPH_NO_VIRTUALIZE(function(self, teleportPosition: CFrame, useTranslateBy: boolean?)
	if (typeof(teleportPosition) == 'Vector3') then
		teleportPosition = CFrame.new(teleportPosition)
	end

	if (not ReplicationUtility.rootPart) then
		return
	end

	ReplicationUtility.LastClientTeleport = os.clock()
	ReplicationUtility.LastClientTeleportPosition = teleportPosition.Position
	ReplicationUtility.rootPart.CFrame = teleportPosition
end)

ReplicationUtility.Strafe = LPH_NO_VIRTUALIZE(function(self, strafeSpeed: number)
	if (not ReplicationUtility.rootPart) or (not ReplicationUtility.Humanoid) then
		return
	end

	local rootPart: BasePart = ReplicationUtility.rootPart
	local Humanoid: Humanoid = ReplicationUtility.Humanoid

	local rootVelocity: Vector3 = rootPart.AssemblyLinearVelocity
	local moveDirection: Vector3 = Humanoid.MoveDirection * strafeSpeed

	rootPart.AssemblyLinearVelocity = moveDirection + (Vector3.yAxis * rootVelocity.Y)
end)

ReplicationUtility.Fly = LPH_NO_VIRTUALIZE(function(self, flySpeed: number)--, deltaTime: number)
	if (not ReplicationUtility.rootPart) or (not ReplicationUtility.Humanoid) or (not ReplicationUtility.rootPart.Parent) then
		return
	end

	local rootPart: BasePart = ReplicationUtility.rootPart
	local Humanoid: Humanoid = ReplicationUtility.Humanoid

	local verticalMoveDirection: Vector3 = (workspace.CurrentCamera.CFrame.LookVector * Vector3.yAxis) * Humanoid.MoveDirection.Magnitude
	local moveDirection: Vector3 = (Humanoid.MoveDirection + verticalMoveDirection) * flySpeed

	if (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)) then
		moveDirection -= (Vector3.yAxis * (flySpeed + 10))
	elseif (UserInputService:IsKeyDown(Enum.KeyCode.Space)) then
		moveDirection += (Vector3.yAxis * (flySpeed + 10))
	end

	rootPart.AssemblyLinearVelocity = moveDirection
	-- rootPart.Parent:TranslateBy(moveDirection * deltaTime)
end)

ReplicationUtility.Anchor = LPH_NO_VIRTUALIZE(function(self, anchored: boolean)
	if (not ReplicationUtility.rootPart) then
		return
	end

	if (anchored) then
		ReplicationUtility.LastAnchor = os.clock()
	end

	ReplicationUtility.rootPart.Anchored = anchored
end)

ReplicationUtility.GetServerCFrame = LPH_NO_VIRTUALIZE(function()
	if (not ReplicationUtility.rootPart) then
		return
	end

	local currentTime = (os.clock() - (1 / 6))
	local closestOffset = math.huge
	local closest = nil
	
	for time, cframe in next, ReplicationUtility.History do
		if (time < currentTime) then continue end
		if (time - currentTime) > closestOffset then continue end
		
		closestOffset = (time - currentTime)
		closest = cframe
	end
	
	return (closest or ReplicationUtility.rootPart.CFrame)
end)


-- // Signal Connections
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
	if (not ReplicationUtility.rootPart) then
		return
	end
	
	local time = os.clock()
	
	-- // Cache
	ReplicationUtility.History[time] = ReplicationUtility.rootPart.CFrame
	
	-- // Clear old entries
	for recordTime, _ in next, ReplicationUtility.History do
		if (time - recordTime) < 0.5 then
			continue
		end
		
		ReplicationUtility.History[recordTime] = nil
	end
end))

if (LocalPlayer.Character) then
	task.spawn(onCharacterAdded, LocalPlayer.Character)
end

return ReplicationUtility