return function(Cheat)
    -- // Services
    local TweenService = game:GetService('TweenService')
    local RunService = game:GetService('RunService')

    -- // Modules
    local ReplicationUtility = REQUIRE_MODULE('Modules/Libraries/ReplicationUtility.lua')
    local Notifications = REQUIRE_MODULE('Modules/Libraries/Notification.lua')
    local FastSignal = REQUIRE_MODULE('Modules/Classes/FastSignal.lua')
    local Cleaner = REQUIRE_MODULE('Modules/Classes/Cleaner.lua')

    local Network = Cheat.Framework.require('Libraries', 'Network')
    local Cameras = Cheat.Framework.require('Libraries', 'Cameras')
    local World = Cheat.Framework.require('Libraries', 'World')
    local Animators = Cheat.Framework.require('Classes', 'Animators')

    local animatorInstances = debug.getupvalue(Animators.find, 1)

    -- // Library Stuff
    local LeftSide = Cheat.Library.TeleportTab:AddColumn()
    local RightSide = Cheat.Library.TeleportTab:AddColumn()

    -- // Variables
    local playerClass = Cheat.PlayerClass

    -- // Players
    local PlayersSection = LeftSide:AddSection('Players')
    local PlayerList = PlayersSection:AddList({ flag = 'teleportPlayerOption', max = 12, values = Cheat.Players })

    table.insert(Cheat.PlayerLists, PlayerList)
    
    PlayersSection:AddButton({ text = 'TP to Player', flag = 'teleportToPlayer', tip = 'Won\'t work without Anticheat Disabler', unsafe = true, callback = function()
        local player = Cheat:getPlayer(Cheat.Library.flags.teleportPlayerOption)
        if (not player) then return end
        if (not player.Character) or (not player.Character.PrimaryPart) then return Cheat:notifyError(player.Name .. ' is not spawned', 5, true) end
        
        Cheat:Teleport(player.Character.PrimaryPart.CFrame, false, true)
    end }):AddBind({ mode = 'toggle', flag = 'teleportToPlayerBind', callback = Cheat.Library.options.teleportToPlayer.callback })

    PlayersSection:AddButton({ text = 'Teleport Zombies', flag = 'teleportZombies', unsafe = true, callback = function()
        local player = Cheat:getPlayer(Cheat.Library.flags.teleportPlayerOption)
        if (not player) then return end
        if (not player.Character) or (not player.Character.PrimaryPart) then return Notifications:notifyError(player.Name .. ' is not spawned', 5, true) end
        
        for _, v in next, workspace.Zombies.Mobs:GetChildren() do
            if (v:FindFirstChild('HumanoidRootPart')) and (animatorInstances[v]) and (not animatorInstances[v].Sleeping) then
                v.HumanoidRootPart.Anchored = false
                v.HumanoidRootPart.CFrame = (player.Character.PrimaryPart.CFrame + Vector3.new(0, 10, 0))
            end
        end
    end }):AddBind({ mode = 'toggle', flag = 'teleportZombiesBind', callback = Cheat.Library.options.teleportZombies.callback })

    -- // Locations
    local locations = {}

    for _, location in next, workspace.Locations:GetChildren() do
        if (location.Name:lower():match('exploiter')) then
            continue
        end

        table.insert(locations, location.Name)
    end

    local LocationSection = LeftSide:AddSection('Locations')

    LocationSection:AddList({ flag = 'teleportLocation', max = 12, values = locations })
    LocationSection:AddButton({ text = 'TP to Location', flag = 'teleportToLocation', tip = 'Won\'t work without Anticheat Disabler', unsafe = true, callback = function()
        Cheat:Teleport(workspace.Locations[Cheat.Library.flags.teleportLocation].CFrame, false, true)
    end }):AddBind({ flag = 'teleportToLocationBind', callback = Cheat.Library.options.teleportToLocation.callback })

    -- // Vehicles
    local VehicleSection = RightSide:AddSection('Vehicles')

    VehicleSection:AddList({ flag = 'teleportVehicle', max = 12, values = {} })
    VehicleSection:AddButton({ text = 'TP to Vehicle', flag = 'teleportToVehicle', tip = 'Won\'t work without Anticheat Disabler', unsafe = true, callback = function()
        if (not workspace.Vehicles.Spawned:FindFirstChild(Cheat.Library.flags.teleportVehicle)) then
            return
        end

        Cheat:Teleport(workspace.Vehicles.Spawned[Cheat.Library.flags.teleportVehicle].PrimaryPart.CFrame, false, true)
    end }):AddBind({ flag = 'teleportToVehicleBind', callback = Cheat.Library.options.teleportToVehicle.callback })

    workspace.Vehicles.Spawned.ChildAdded:Connect(LPH_NO_VIRTUALIZE(function(vehicle)
        Cheat.Library.options.teleportVehicle:AddValue(vehicle.Name)
    end))

    workspace.Vehicles.Spawned.ChildRemoved:Connect(LPH_NO_VIRTUALIZE(function(vehicle)
        Cheat.Library.options.teleportVehicle:RemoveValue(vehicle.Name)
    end))

    for _, vehicle in next, workspace.Vehicles.Spawned:GetChildren() do
        Cheat.Library.options.teleportVehicle:AddValue(vehicle.Name)
    end

    -- // Loot
    local LootSection = RightSide:AddSection('Loot')
    local lootCFrames = {}

    LootSection:AddList({ flag = 'teleportLoot', max = 12, values = {} })
    LootSection:AddButton({ text = 'TP to loot', flag = 'teleportToLoot', tip = 'Won\'t work without Anticheat Disabler', unsafe = true, callback = function()
        if (not lootCFrames[Cheat.Library.flags.teleportLoot]) then
            return
        end

        Cheat:Teleport(lootCFrames[Cheat.Library.flags.teleportLoot], false, true)
    end }):AddBind({ flag = 'teleportToLootBind', callback = Cheat.Library.options.teleportToLoot.callback })

    workspace.Loot.DescendantAdded:Connect(LPH_NO_VIRTUALIZE(function(loot)
        if (loot.ClassName ~= 'CFrameValue') then
            return
        end

        lootCFrames[loot.Name] = loot.Value
        Cheat.Library.options.teleportLoot:AddValue(loot.Name)
    end))

    workspace.Loot.DescendantRemoving:Connect(LPH_NO_VIRTUALIZE(function(loot)
        if (loot.ClassName ~= 'CFrameValue') then
            return
        end

        lootCFrames[loot.Name] = nil
        Cheat.Library.options.teleportLoot:RemoveValue(loot.Name)
    end))

    -- // Corpse
    local CorpseSection = LeftSide:AddSection('Player Corpses')

    CorpseSection:AddButton({ text = 'Vest Corpse Pick', flag = 'vestPick', callback = function()
        if (not playerClass.Character) then
            return Cheat:notifyError('Please spawn in to use this feature.', 5, true)
        end

        for _, corpse in next, workspace.Corpses:GetChildren() do
            if (corpse.Name == 'Zombie') or (corpse.PrimaryPart.Position - ReplicationUtility.rootPart.Position).Magnitude > 10 then
                continue
            end

            Network:Fetch('Corpses Container Group Connect', corpse)
        end

        for _, container in next, playerClass.Character.Inventory.Containers do
            if (container.Type ~= 'Corpse') then
                continue
            end

            for _, item in next, container.Occupants do
                Network:Send('Inventory Pickup Item', item.Id)
            end
        end

        Network:Send('Inventory Container Group Disconnect')
    end }):AddBind({ flag = 'teleportToCorpseBind', callback = Cheat.Library.options.vestPick.callback })

    CorpseSection:AddButton({ text = 'Vest Corpse Drop', flag = 'vestDrop', callback = function()
        if (not playerClass.Character) then
            return Cheat:notifyError('Please spawn in to use this feature.', 5, true)
        end

        for _, corpse in next, workspace.Corpses:GetChildren() do
            if (corpse.Name == 'Zombie') or (corpse.PrimaryPart.Position - ReplicationUtility.rootPart.Position).Magnitude > 10 then
                continue
            end

            Network:Fetch('Corpses Container Group Connect', corpse)
        end

        for _, container in next, playerClass.Character.Inventory.Containers do
            if (container.Type ~= 'Corpse') then
                continue
            end

            for _, item in next, container.Occupants do
                Network:Send('Inventory Drop Item', item.Id)
            end
        end

        Network:Send('Inventory Container Group Disconnect')
    end }):AddBind({ flag = 'teleportToCorpseBind', callback = Cheat.Library.options.vestDrop.callback })

    CorpseSection:AddList({ flag = 'teleportCorpse', max = 12, values = {} })
    CorpseSection:AddButton({ text = 'TP to Corpse', flag = 'teleportToCorpse', tip = 'Won\'t work without Anticheat Disabler', unsafe = true, callback = function()
        if (not workspace.Corpses:FindFirstChild(Cheat.Library.flags.teleportCorpse)) then
            return
        end

        Cheat:Teleport(workspace.Corpses[Cheat.Library.flags.teleportCorpse].PrimaryPart.CFrame, false, true)
    end }):AddBind({ flag = 'teleportToCorpseBind', callback = Cheat.Library.options.teleportToCorpse.callback })

    local zombieString = LPH_ENCSTR('Zombie')

    workspace.Corpses.ChildAdded:Connect(LPH_NO_VIRTUALIZE(function(corpse)
        if (corpse.Name == zombieString) then
            return
        end

        Cheat.Library.options.teleportCorpse:AddValue(corpse.Name)
    end))

    workspace.Corpses.ChildRemoved:Connect(LPH_NO_VIRTUALIZE(function(corpse)
        if (corpse.Name == zombieString) then
            return
        end

        Cheat.Library.options.teleportCorpse:RemoveValue(corpse.Name)
    end))

    for _, corpse in next, workspace.Corpses:GetChildren() do
        if (corpse.Name == 'Zombie') then
            continue
        end

        Cheat.Library.options.teleportCorpse:AddValue(corpse.Name)
    end

    -- // Events
    local EventSection = RightSide:AddSection('Events')

    EventSection:AddList({ flag = 'teleportEvent', max = 12, values = {} })
    EventSection:AddButton({ text = 'TP to Event', flag = 'teleportToEvent', tip = 'Won\'t work without Anticheat Disabler', unsafe = true, callback = function()
        if (not workspace.Map.Shared.Randoms:FindFirstChild(Cheat.Library.flags.teleportEvent)) then
            return
        end

        Cheat:Teleport(workspace.Map.Shared.Randoms[Cheat.Library.flags.teleportEvent].Value, false, true)
    end }):AddBind({ flag = 'teleportToEventBind', callback = Cheat.Library.options.teleportToEvent.callback })

    workspace.Map.Shared.Randoms.ChildAdded:Connect(LPH_NO_VIRTUALIZE(function(event)
        Cheat.Library.options.teleportEvent:AddValue(event.Name)
    end))

    workspace.Map.Shared.Randoms.ChildRemoved:Connect(LPH_NO_VIRTUALIZE(function(event)
        Cheat.Library.options.teleportEvent:RemoveValue(event.Name)
    end))

    for _, event in next, workspace.Map.Shared.Randoms:GetChildren() do
        Cheat.Library.options.teleportEvent:AddValue(event.Name)
    end

    -- // Zombies
    local ZombieSection = RightSide:AddSection('Zombies')

    ZombieSection:AddList({ flag = 'teleportZombieValue', max = 12, values = {} })
    ZombieSection:AddButton({ text = 'TP to Zombie', flag = 'teleportToZombie', tip = 'Won\'t work without Anticheat Disabler', unsafe = true, callback = function()
        if (not workspace.Zombies.Mobs:FindFirstChild(Cheat.Library.flags.teleportZombieValue)) then
            return
        end

        Cheat:Teleport(workspace.Zombies.Mobs[Cheat.Library.flags.teleportZombieValue].PrimaryPart.CFrame, false, true)
    end }):AddBind({ flag = 'teleportToZombieBind', callback = Cheat.Library.options.teleportToZombie.callback })

    workspace.Zombies.Mobs.ChildAdded:Connect(LPH_NO_VIRTUALIZE(function(zombie)
        Cheat.Library.options.teleportZombieValue:AddValue(zombie.Name)
    end))

    workspace.Zombies.Mobs.ChildRemoved:Connect(LPH_NO_VIRTUALIZE(function(zombie)
        Cheat.Library.options.teleportZombieValue:RemoveValue(zombie.Name)
    end))

    for _, zombie in next, workspace.Zombies.Mobs:GetChildren() do
        Cheat.Library.options.teleportZombieValue:AddValue(zombie.Name)
    end

    -- // Teleport Functions
    Cheat.TeleportCancelled = FastSignal.new()

    local currentCFrame

    Cheat.Teleport = LPH_JIT_MAX(function(self, teleportCFrame, useTranslateBy, dontSet, noNotif, ignoreACDisabler)
        -- // Guard Clauses
        if (not ReplicationUtility.rootPart) then
            Cheat:notifyError('Please spawn in to use this feature.', 5, true)

            return false
        end

        if (Cheat.Teleporting) then
            Cheat:notifyError('Please wait for the current teleport to finish.', 5, true)

            return false
        end

        if (Cheat.anticheatDisabled) then
            Cheat:InstantTeleport(teleportCFrame, useTranslateBy, dontSet)
            return true
        else
            Cheat:notifyError('Please enable AC Disabler Mode "Full" to use teleport.', 5, true)
            return false
        end
        
        -- if (not Cheat.Library.flags.acDisabler) and (not ignoreACDisabler) then
        --     Cheat:notifyError('Please enable AC Disabler Mode "Full" to use teleport.', 5, true)

        --     return false
        -- end
    
        -- if (not Cheat.acBypassed) and (not ignoreACDisabler) then
        --     Cheat:notifyError('Please wait for the AC Disabler to be ready.', 5, true)

        --     return false
        -- end

        -- if (not noNotif) then
        --     Cheat:notifyInfo('Teleporting, please wait...', 15, true)
        -- end

        -- -- // Teleport
        -- local cleaner = Cleaner.new()
        -- local cancelled = false
        -- local desiredHeight = 0
        -- local invisCFrame = Cheat.rootCFrame
        -- local serverCFrame = Cheat.serverCFrame
        -- local clientCFrame = (invisCFrame or ReplicationUtility.rootPart.CFrame)
        -- local rootCFrame = (serverCFrame or ReplicationUtility.rootPart.CFrame)

        -- currentCFrame = rootCFrame

        -- RunService:BindToRenderStep('HideCharacter', Enum.RenderPriority.First.Value, function()
        --     ReplicationUtility.rootPart.CFrame = clientCFrame
    
        --     RunService.PostSimulation:Once(function()
        --         if (not currentCFrame) then
        --             ReplicationUtility.rootPart.CFrame = teleportCFrame

        --             return
        --         end

        --         ReplicationUtility.rootPart.CFrame = currentCFrame
        --     end)
        -- end)
        
        -- if (not dontSet) then
        --     -- // Disable Chunk Loading
        --     local currentGameCamera = Cameras:GetCurrent()
        --     if (currentGameCamera) and (currentGameCamera.LastWorldSet ~= nil) then
        --         currentGameCamera.LastWorldSet = math.huge -- prevent world updating
        --     end
        -- end

        -- -- // Connections
        -- cleaner:AddConnection(ReplicationUtility.OnSetback:Once(function()
        --     Cheat.TeleportCancelled:Fire()
        --     Cheat:notifyError('Teleport failed, please try again.', 8, true)
        --     cancelled = true
        -- end))

        -- cleaner:AddConnection(Cheat.TeleportCancelled:Once(function()
        --     cancelled = true
        -- end))

        -- -- // Teleports
        -- Cheat.Teleporting = true

        -- Cheat:TweenTeleport(rootCFrame - ((rootCFrame.Y - desiredHeight) * Vector3.yAxis), cleaner, cancelled)
        -- Cheat:TweenTeleport(teleportCFrame - ((teleportCFrame.Y - desiredHeight) * Vector3.yAxis), cleaner, cancelled)
        -- Cheat:TweenTeleport(teleportCFrame, cleaner, cancelled)

        -- RunService:UnbindFromRenderStep('HideCharacter')
        -- currentCFrame = nil
        -- cleaner:Destroy()

        -- if (not cancelled) and (Cheat.rootCFrame) then
        --     Cheat.rootCFrame = teleportCFrame
        --     Cheat.serverCFrame = teleportCFrame
        -- end

        -- -- // Enable Chunk Loading
        -- local currentGameCamera = Cameras:GetCurrent()
        -- if (currentGameCamera) and (currentGameCamera.LastWorldSet ~= nil) then
        --     currentGameCamera.LastWorldSet = os.clock()
        -- end

        -- if (not cancelled) and (not dontSet) then
        --     ReplicationUtility:Anchor(true)
        --     World:Set(teleportCFrame.Position, 'Camera', 100):Wait()
        --     ReplicationUtility:Anchor(false)
        -- end

        -- Cheat.Teleporting = false

        -- return (not cancelled)
    end)
    
    Cheat.TweenTeleport = LPH_JIT_MAX(function(self, teleportCFrame, cleaner, cancelled)
        if (cancelled) or (not ReplicationUtility.rootPart) or (not ReplicationUtility.Humanoid) then
            return
        end
        
        local teleporting = true
        
        local rootCFrame = currentCFrame
        local delta = (teleportCFrame.Position - rootCFrame.Position)
        local direction = delta.Unit
        local magnitude = delta.Magnitude
        local velocity = (direction * 16)
        if (direction ~= direction) then return end -- // NaN Guard

        local speed = (if Network:GetPing() >= 10 then 200 else 100)
        
        local tweenInfo = TweenInfo.new(magnitude / speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
        local timeElapsed = 0
    
        -- // Connections
        local heartbeatConnection = nil
        heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if (not teleporting) or (not ReplicationUtility.rootPart) then
                heartbeatConnection:Disconnect()
                teleporting = false
                return
            end

            timeElapsed += math.min(deltaTime, 1 / 60)

            -- // Tween
            local alpha = math.clamp(TweenService:GetValue(timeElapsed / tweenInfo.Time, tweenInfo.EasingStyle, tweenInfo.EasingDirection), 0, 1)

            ReplicationUtility.rootPart.AssemblyLinearVelocity = velocity
            currentCFrame = rootCFrame:Lerp(teleportCFrame, alpha)

            -- // Finished?
            if (timeElapsed >= tweenInfo.Time) then
                teleporting = false
                ReplicationUtility.rootPart.AssemblyLinearVelocity = Vector3.zero
                heartbeatConnection:Disconnect()
            end
        end)

        cleaner:AddConnection(Cheat.TeleportCancelled:Once(function()
            teleporting = false
            heartbeatConnection:Disconnect()
        end))

        repeat
            RunService.PreRender:Wait()
        until (not teleporting)
    end)
    
    Cheat.InstantTeleport = LPH_JIT_MAX(function(self, teleportPosition, useTranslateBy, dontSet)
        if (typeof(teleportPosition) == 'Vector3') then
            teleportPosition = CFrame.new(teleportPosition)
        end
    
        ReplicationUtility:Teleport(teleportPosition, useTranslateBy)

        if (not dontSet) then 
            ReplicationUtility:Anchor(true)

            local currentGameCamera = Cameras:GetCurrent()
    
            if (currentGameCamera) and (currentGameCamera.LastWorldSet ~= nil) then
                currentGameCamera.LastWorldSet = os.clock()
            end
    
            World:Set(teleportPosition.Position, 'Camera', 100):Wait()

            ReplicationUtility:Anchor(false)
        end

        return true
    end)
    
end