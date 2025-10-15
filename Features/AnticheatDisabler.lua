return function(Cheat)
    -- // Modules
    local Notifications = REQUIRE_MODULE('Modules/Libraries/Notification.lua')
    local ReplicationUtility = REQUIRE_MODULE('Modules/Libraries/ReplicationUtility.lua')
    local Signal = REQUIRE_MODULE('Modules/Classes/FastSignal.lua')
    local Cameras = Cheat.Framework.require('Libraries', 'Cameras')
    local Interface = Cheat.Framework.require('Libraries', 'Interface')
    local CharacterCamera = Cameras:GetCamera('Character')
    local VehicleGui = Interface:GetGui('Vehicle')

    local Map = Interface:Get('Map')

    Cheat.AntiCheatDisablerSpoofing = false

    local lastDisableTick = 0

    local preSpoofEquippedItem
    local preSpoofLastWorldSet
    local preSpoofCharacterPosition
    local characterString = LPH_ENCSTR("Character")
    local rootPartString = LPH_ENCSTR("RootPart")
    
    local oldStep; oldStep = Cheat:hookAndTostringSpoof(CharacterCamera, 'Step', LPH_NO_VIRTUALIZE(function(self, deltaTime)
        if (Cheat.AntiCheatDisablerSpoofing) then
            -- // Fake Character Class
            local fakeCharacterClass = {}

            setrawmetatable(fakeCharacterClass, {
                __index = function(_, key)
                    if (key == rootPartString) then
                        return {
                            CFrame = preSpoofCharacterPosition
                        }
                    end

                    return self.Character[key]
                end,

                __newindex = function(_, key, value)
                    self.Character[key] = value
                end
            })

            -- // Fake Character Class
            local fakeCameraClass = {}

            setrawmetatable(fakeCameraClass, {
                __index = function(_, key)
                    if (key == characterString) then
                        return fakeCharacterClass
                    end

                    return self[key]
                end,

                __newindex = function(_, key, value)
                    self[key] = value
                end
            })

            return oldStep(fakeCameraClass, deltaTime)
        end

        return oldStep(self, deltaTime)
    end))

    Cheat.oldCameraStep = oldStep

    local LocalPlayer = game:GetService('Players').LocalPlayer
    local Players = Cheat.Framework.require('Classes', 'Players')
    local Network = Cheat.Framework.require('Libraries', 'Network')

    local VehicleEntered = Signal.new()
    local VehicleExited = Signal.new()

    local interactionString = LPH_ENCSTR('Interaction')
    local seatDriverString = LPH_ENCSTR('Seat Driver')
    local cframeString = LPH_ENCSTR('CFrame')

    local oldNamecall, oldNewindex = nil, nil
    local function enableMetaMethodHooks()
        if (oldNamecall) then
            return
        end

        oldNewindex = hookmetamethod(game, '__newindex', LPH_NO_VIRTUALIZE(function(self, idx, val)
            if (idx == 'Visible') and (self == VehicleGui) and (Cheat.AntiCheatDisablerSpoofing) and (not checkcaller()) then
                return
            end
    
            return oldNewindex(self, idx, val)
        end))
    
        oldNamecall = hookmetamethod(game, '__namecall', LPH_NO_VIRTUALIZE(function(self, ...)
            if (not Cheat.AntiCheatDisablerSpoofing) or (getnamecallmethod() ~= 'HasTag') or (select(2, ...) ~= 'Vehicle Interact Ignore') or (checkcaller()) then
                return oldNamecall(self, ...)
            end
    
            return true
        end))
    end

    local function disableMetaMethodHooks()
        if (not oldNamecall) then
            return
        end

        hookmetamethod(game, '__newindex', oldNewindex)
        hookmetamethod(game, '__namecall', oldNamecall)
        oldNewindex = nil
        oldNamecall = nil
    end

    local function enableSpoofing()
        enableMetaMethodHooks()
        Cheat.AntiCheatDisablerSpoofing = true

        local currentGameCamera = Cameras:GetCurrent()
        if (currentGameCamera) and (currentGameCamera.LastWorldSet ~= nil) then
            preSpoofLastWorldSet = currentGameCamera.LastWorldSet
            currentGameCamera.LastWorldSet = math.huge -- prevent world updating
        end

        VehicleGui.Visible = false
        preSpoofCharacterPosition = ReplicationUtility.rootPart.CFrame

        local playerClass = Players.get()

        if (playerClass) and (playerClass.Character) then
            preSpoofEquippedItem = playerClass.Character.EquippedItem -- no, i did not mean to unequip it here, this is intended lmao
            playerClass.Character:Unequip()
        end

        Map:DisableGodview()
    end

    local function disableSpoofing()
        disableMetaMethodHooks()
        local currentGameCamera = Cameras:GetCurrent()
        if (currentGameCamera) and (currentGameCamera.LastWorldSet ~= nil) then
            currentGameCamera.LastWorldSet = preSpoofLastWorldSet -- allow world updating
        end

        preSpoofLastWorldSet = nil

        VehicleGui.Visible = true
        preSpoofCameraPosition = nil

        local playerClass = Players.get()

        if (playerClass) and (playerClass.Character) and (preSpoofEquippedItem) then
            playerClass.Character:Equip(preSpoofEquippedItem)
        end

        preSpoofEquippedItem = nil

        if (Cheat.Library.flags.mapRadar) then
            Map:EnableGodview()
        end

        Cheat.AntiCheatDisablerSpoofing = false
    end

    -- // Functions
    function Cheat:isVehicleOccupied(vehicle)
        if (not vehicle:FindFirstChild('Seats')) then
            return
        end

        local seats = vehicle:FindFirstChild('Seats')

        for _, v in next, seats:GetChildren() do
            local weld = v:FindFirstChildOfClass('Weld')

            if (not weld) then
                continue
            end
                
            if (weld.Part1) then
                return true
            end
        end

        return false
    end

    function Cheat:isVehicleOccupiedByPlayer(vehicle, player)
        if (not vehicle:FindFirstChild('Seats')) then
            return
        end

        if (not player.Character) or (not player.Character.PrimaryPart) then
            return
        end

        local seats = vehicle:FindFirstChild('Seats')

        for _, v in next, seats:GetChildren() do
            local weld = v:FindFirstChildOfClass('Weld')

            if (not weld) then
                continue
            end
                
            if (weld.Part1 == player.Character.PrimaryPart) then
                return true
            end
        end

        return false
    end

    function Cheat:fixWelds(vehicle)
        if (not vehicle:FindFirstChild('Seats')) then
            return
        end

        if (not LocalPlayer.Character) or (not LocalPlayer.Character.PrimaryPart) then
            return
        end

        for i, v in next, vehicle.Seats:GetChildren() do
            local weld = v:FindFirstChildOfClass('Weld')

            if (not weld) then
                continue
            end

            if (weld.Part1 == LocalPlayer.Character.PrimaryPart) then
                weld:Destroy()
            end
        end
    end

    function Cheat:fixAllWelds() -- // potentially expensive operation
        for i, v in next, workspace.Vehicles.Spawned:GetChildren() do
            Cheat:fixWelds(v)
        end
    end

    function Cheat:getClosestVehicle()
        local closest = nil
        local closestDist = math.huge
        local origin = workspace.CurrentCamera.CFrame.Position

        for i,v in next, workspace.Vehicles.Spawned:GetChildren() do
            local PrimaryPart = v.PrimaryPart

            if (PrimaryPart) and (PrimaryPart.Position - origin).Magnitude <= closestDist and v:FindFirstChild('Interaction') and (not Cheat:isVehicleOccupied(v)) then
                closestDist = (PrimaryPart.Position - origin).Magnitude
                closest = v
            end
        end

        return closest, closestDist
    end

    function Cheat:getVehicleWithinRange(range)
        local closest, distance = Cheat:getClosestVehicle()
        if (not closest) or (distance > range) then
            return
        end

        return closest
    end

    function Cheat:getSafeVehicles()
        local vehicles = {}

        for i,v in next, workspace.Vehicles.Spawned:GetChildren() do
            if v:FindFirstChild('Interaction') and (not Cheat:isVehicleOccupied(v)) then
                table.insert(vehicles, v)
            end
        end

        return vehicles
    end

    function Cheat:getRandomVehicle()
        local vehicles = Cheat:getSafeVehicles()

        if #vehicles <= 0 then
            return
        end

        return vehicles[math.random(1, #vehicles)]
    end

    function Cheat:forceDriveVehicle(vehicle)
        if (not ReplicationUtility.rootPart) or (not ReplicationUtility.rootPart.Parent) then return end

        local playerClass = Players.get()
        local success = false
        local heartbeatConn = nil
        local lastTick = 0

        VehicleEntered:Once(LPH_NO_VIRTUALIZE(function()
            if (heartbeatConn) then
                heartbeatConn:Disconnect()
            end

            success = true
        end))

        -- if (not Cheat:Teleport(vehicle[interactionString][seatDriverString][cframeString], nil, true, true)) then
        --     return false
        -- end

        if (success) then
            return true
        end

        heartbeatConn = game:GetService('RunService').Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
            if (not ReplicationUtility.rootPart) or (not ReplicationUtility.rootPart.Parent) then return end
            if (not vehicle) or (not vehicle.PrimaryPart) or (not vehicle:FindFirstChild(interactionString)) or (not vehicle.Interaction:FindFirstChild(seatDriverString)) then return end

            ReplicationUtility:Teleport(vehicle[interactionString][seatDriverString][cframeString])
        end))

        while (ReplicationUtility.rootPart) and (ReplicationUtility.rootPart.Parent) and (vehicle) and (vehicle.PrimaryPart) and (vehicle:FindFirstChild('Interaction')) and (vehicle.Interaction:FindFirstChild('Seat Driver')) and (not success) do
            vehicle.PrimaryPart.Anchored = true

            if (tick() - lastTick >= 0.5) then
                lastTick = tick()

                ReplicationUtility:Teleport(vehicle[interactionString][seatDriverString][cframeString])
                Network:Send('Vehicle Sit In', vehicle, vehicle.Interaction['Seat Driver'])
                Cheat:fixAllWelds()
            end

            Cheat:networkWait(2)
        end

        if (heartbeatConn) then
            heartbeatConn:Disconnect()
        end

        return success
    end

    function Cheat:forceExitVehicle(vehicle)
        local success = false

        VehicleExited:Once(LPH_NO_VIRTUALIZE(function()
            success = true
        end))

        local lastTick = 0

        while (ReplicationUtility.rootPart) and (ReplicationUtility.rootPart.Parent) and (vehicle) and (vehicle.PrimaryPart) and (vehicle:FindFirstChild('Interaction')) and (not success) do
            if (tick() - lastTick >= 0.5) then
                lastTick = tick()
                Network:Send('Vehicle Dismount', vehicle)
            end

            Cheat:networkWait(2)
        end

        if (vehicle and vehicle.PrimaryPart) then
            vehicle.PrimaryPart.Anchored = false
        end

        Cheat:fixAllWelds()
    end

    function Cheat:disableAnticheat()
        -- Cheat:notifyInfo('Disabling anti-cheat, please wait...', 8, true)

        local playerClass = Players.get()

        while true do
            -- if (not Cheat.Library.flags.acBypass) then
            -- if (not Cheat.acBypassed) then
            --     -- Cheat.Library.options.acBypass:SetState(true)

            --     task.wait(5)
                
            --     continue
            -- end

            -- if (not Cheat.acBypassed) then task.wait() continue end
            if (not Cheat.Library.flags.acDisabler) or (Cheat.Library.flags.acDisablerMode ~= 'Full') then break end
            if (tick() - lastDisableTick < 8) then task.wait() continue end
            if (not playerClass) or (not playerClass.Character) then task.wait() continue end
            if (playerClass.Character.Vehicle) then task.wait() continue end

            local vehicle = (if not Cheat.anticheatDisabled then Cheat:getVehicleWithinRange(25) else Cheat:getClosestVehicle())
            if (not vehicle) then Cheat:notifyError('Please be next to a vehicle when enabling Full AC Disabler.', 5, true) break end

            local oldCFrame = ReplicationUtility.rootPart.CFrame

            enableSpoofing()

            playerClass.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

            if (not Cheat:forceDriveVehicle(vehicle)) then
                Cheat:notifyError('Failed disabling anti-cheat, retrying in 5 seconds...', 8, true)

                Cheat.anticheatDisabled = false
                
                playerClass.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                playerClass.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                
                disableSpoofing()   

                task.wait(5)

                continue
            end

            Cheat:forceExitVehicle(vehicle)

            if (not Cheat.anticheatDisabled) then
                Cheat:notifyInfo('Anti-cheat is now disabled!', 8, true)

                Cheat.anticheatDisabled = true
            end

            task.wait(.5)

            if (playerClass.Character) then
                ReplicationUtility:Teleport(oldCFrame)
    
                playerClass.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                playerClass.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end

            disableSpoofing()

            lastDisableTick = tick()

            task.wait()
        end

        Cheat.anticheatDisabled = false
    end

    -- // Hooks
    local oldVehicleCharacterSet = Cheat.NetworkEvents['Vehicle Character Set']
    Cheat.NetworkEvents['Vehicle Character Set'] = function(vehicle, ...)
        if (vehicle) then
            VehicleEntered:Fire()
        else
            VehicleExited:Fire()
        end

        if (not Cheat.AntiCheatDisablerSpoofing) or (Cheat.IsPlayerEnteringVehicle) or (not vehicle) then
            return oldVehicleCharacterSet(vehicle, ...)
        end
    end

    local oldVehicleCameraDisconnect = Cheat.NetworkEvents['Vehicle Camera Disconnect']
    Cheat.NetworkEvents['Vehicle Camera Disconnect'] = function(...)
        if (not Cheat.AntiCheatDisablerSpoofing) or (Cheat.IsPlayerExitingVehicle) then
            return oldVehicleCameraDisconnect(...)
        end
    end
end