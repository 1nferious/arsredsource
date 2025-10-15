local Targeting = {}
local ReplicationUtility = REQUIRE_MODULE('Modules/Libraries/ReplicationUtility.lua')
local Players = game:GetService('Players')

-- // Target Stuff
Targeting.Raycasting = nil

Targeting.R6TargetParts = { 'Head', 'Torso', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg' }
Targeting.R15TargetParts = { 'Head', 'UpperTorso', 'LeftUpperArm', 'RightUpperArm', 'LeftLowerLeg', 'RightLowerLeg' } -- // only the key target parts
Targeting.IgnoreList = {}
Targeting.IgnoreType = 'Exclude'

Targeting.ScanOffsets = {
    CFrame.new(0, 0, -5.5), -- // Forward
    CFrame.new(0, 0, 5.5), -- // Backward
    CFrame.new(0, 5.5, 0), -- // Up
    CFrame.new(0, -5.5, 0), -- // Down
    CFrame.new(-5.5, 0, 0), -- // Left
    CFrame.new(5.5, 0, 0), -- // Right
}

-- // Functions
local getScreenPosition = LPH_NO_VIRTUALIZE(function(worldPosition: Vector3)
    local screenPosition, onScreen = workspace.CurrentCamera:WorldToViewportPoint(worldPosition)
    return Vector2.new(screenPosition.X, screenPosition.Y), onScreen
end)

local seatsString = LPH_ENCSTR('Seats')

local isInVehicle = LPH_NO_VIRTUALIZE(function(character)
    local rootPart = character.PrimaryPart
    if (not rootPart) then return end

    for _, v in next, workspace.Vehicles.Spawned:GetChildren() do
        local seats = v:FindFirstChild(seatsString)
        if (not seats) then continue end

        for _, seat in next, seats:GetChildren() do
            local weld = seat:FindFirstChildOfClass('Weld')
            if (not weld) then continue end

            if (weld.Part1 == rootPart) then
                return true
            end
        end
    end
end)

-- // Methods
Targeting.isDead = LPH_NO_VIRTUALIZE(function(self, character: Model)
    local playerObject = Players:GetPlayerFromCharacter(character)
    if (not playerObject) then return end
    if (not playerObject:FindFirstChild('Stats')) then return end

    return playerObject.Stats.Health.Value <= 0
    
    -- local position = character.PrimaryPart.Position
    -- local playerName = Players:GetPlayerFromCharacter(character).Name

    -- for _, body in next, workspace.Corpses:GetChildren() do
    --     if (body.Name ~= playerName) or (not body.PrimaryPart) then
    --         continue
    --     end

    --     if ((body.PrimaryPart.Position - position).Magnitude < 15) then
    --         return true
    --     end
    -- end

    -- return false
end)

Targeting.isVisibleFrom = LPH_NO_VIRTUALIZE(function(self, origin: Vector3 | CFrame, targetPosition: Vector3, IgnoreList: {Instance?}, IgnoreType: string?)
    if (typeof(origin) == 'CFrame') then
        origin = origin.Position
    end
    
    if (Targeting.Raycasting:BulletCast(Ray.new(origin, targetPosition - origin), true, IgnoreList, true)) then
        return false
    end

    return true
end)

Targeting.FindFirePosition = LPH_NO_VIRTUALIZE(function(self, origin: Vector3, target: BasePart)
    for _, offset in next, Targeting.ScanOffsets do
        local scanOrigin = (CFrame.lookAt(origin, target.Position) * offset).Position
        if (not Targeting:isVisibleFrom(scanOrigin, target.Position, {workspace.Effects, workspace.Sounds, workspace.Characters, Players.LocalPlayer.Character})) then continue end

        return scanOrigin, true
    end

    return origin
end)

Targeting.GetAimbotTarget = LPH_NO_VIRTUALIZE(function(self, fovPosition: Vector2?, radius: number, maximumDistance: number, targetPart: string, visibleCheck: boolean): BasePart?
    if (not fovPosition) then
        fovPosition = (workspace.CurrentCamera.ViewportSize / 2)
    end
    
    local targets: {Model?} = (visibleCheck and Targeting:GetVisibleTargets(maximumDistance)) or Targeting:GetTargets(maximumDistance)
    local targetPart: string = (targetPart == 'Random' and Targeting.R15TargetParts[math.random(1, #Targeting.R15TargetParts)]) or targetPart
    
    local closestTarget = nil
    local closestDistance = math.huge
    
    for _, Character: Model in next, targets do
        local foundTargetPart: Instance? = Character:FindFirstChild(targetPart)
        if (not foundTargetPart) then continue end

        local screenPosition, onScreen = getScreenPosition(foundTargetPart.Position)
        if (not onScreen) then continue end
        
        local distanceFromFOV: Vector2 = (screenPosition - fovPosition).Magnitude
        if (distanceFromFOV > closestDistance) then continue end
        if (distanceFromFOV > radius) then continue end

        closestTarget = foundTargetPart
        closestDistance = distanceFromFOV
    end

    return closestTarget
end)

Targeting.GetTargets = LPH_NO_VIRTUALIZE(function(self, targetDistance: number?, targetZombies: boolean?)
    if (not ReplicationUtility.rootPart) then
        return {}
    end

    if (not targetDistance) then
        targetDistance = math.huge
    end

    -- // Players
    local targets = {}
    local currentPosition: Vector3 = ReplicationUtility.rootPart.Position

    for i,v in next, ReplicationUtility:GetCharacters() do
        if (v.PrimaryPart.Position - currentPosition).Magnitude > targetDistance then
            continue
        end

        table.insert(targets, v)
    end

    -- // Zombies
    if (targetZombies) then
        for i,v in next, workspace.Zombies.Mobs:GetChildren() do
            if (not v.PrimaryPart) or (v.PrimaryPart.Position - currentPosition).Magnitude > targetDistance then
                continue
            end
    
            table.insert(targets, v)
        end
    end

    return targets
end)

Targeting.GetVisibleTargets = LPH_NO_VIRTUALIZE(function(self, targetDistance: number?)
    if (not ReplicationUtility.rootPart) then
        return {}
    end

    if (not targetDistance) then
        targetDistance = math.huge
    end

    local targets = {}
    local currentPosition: Vector3 = ReplicationUtility.rootPart.Position

    for i,v in next, ReplicationUtility:GetCharacters() do
        if (v.PrimaryPart.Position - currentPosition).Magnitude > targetDistance then
            continue
        end

        if (not Targeting:isVisibleFrom(workspace.CurrentCamera.CFrame.Position, v.PrimaryPart.Position, {workspace.Effects, workspace.Sounds, workspace.Characters, Players.LocalPlayer.Character})) then
            continue
        end

        table.insert(targets, v)
    end

    return targets
end)

Targeting.GetSafeTargets = LPH_NO_VIRTUALIZE(function(self, targetDistance)
    if (not ReplicationUtility.rootPart) then
        return {}
    end

    if (not targetDistance) then
        targetDistance = math.huge
    end

    local targets = {}
    local currentPosition: Vector3 = ReplicationUtility.rootPart.Position

    for i,v in next, ReplicationUtility:GetCharacters() do
        if isInVehicle(v) or (v.PrimaryPart.Position - currentPosition).Magnitude > targetDistance then
            continue
        end

        table.insert(targets, v)
    end

    return targets
end)

Targeting.GetTarget = LPH_NO_VIRTUALIZE(function(self, distance: number, targetZombies: boolean?)
    if (not ReplicationUtility.rootPart) then
        return
    end

    local currentPosition: Vector3 = ReplicationUtility.rootPart.Position
    local targets = Targeting:GetTargets(distance, targetZombies)
    local closest = nil
    local closestDistance = math.huge

    for i,v in next, targets do
        local distance = (currentPosition - v.PrimaryPart.Position).Magnitude
        if (distance >= closestDistance) or (Targeting:isDead(v)) then continue end

        closest = v
        closestDistance = distance
    end

    return closest
end)

Targeting.GetSafeTarget = LPH_NO_VIRTUALIZE(function(self, distance: number)
    if (not ReplicationUtility.rootPart) then
        return
    end

    local currentPosition: Vector3 = ReplicationUtility.rootPart.Position
    local targets = Targeting:GetSafeTargets(distance)
    local closest = nil
    local closestDistance = math.huge

    for i,v in next, targets do
        local distance = (currentPosition - v.PrimaryPart.Position).Magnitude
        if (distance >= closestDistance) or (Targeting:isDead(v)) then continue end

        closest = v
        closestDistance = distance
    end

    return closest
end)

return Targeting