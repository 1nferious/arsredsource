return function(Cheat)
    -- // TODO: Auto Combine/Spread Ammo
    -- // Modules
    local ReplicationUtility = REQUIRE_MODULE('Modules/Libraries/ReplicationUtility.lua')
    local Cleaner = REQUIRE_MODULE('Modules/Classes/Cleaner.lua')
    local Signal = REQUIRE_MODULE('Modules/Classes/FastSignal.lua')
    local Notifications = REQUIRE_MODULE('Modules/Libraries/Notification.lua')
    local Targeting = REQUIRE_MODULE('Modules/Libraries/Targeting.lua')
    local Hooks = REQUIRE_MODULE('Modules/Libraries/Hooks.lua')

    local Network = Cheat.Framework.require('Libraries', 'Network')
    local Interface = Cheat.Framework.require('Libraries', 'Interface')
    local Cameras = Cheat.Framework.require('Libraries', 'Cameras')
    local Globals = Cheat.Framework.require('Configs', 'Globals')
    local VehicleController = Cheat.Framework.require('Classes', 'VehicleControler')
    local World = Cheat.Framework.require('Libraries', 'World')
    local Animators = Cheat.Framework.require('Classes', 'Animators')

    local animatorInstances = debug.getupvalue(Animators.find, 1)

    local Hotbar = Interface:Get('Hotbar')
    local Fade = Interface:Get('Fade')
    
    local Players = game:GetService('Players')
    local RunService = game:GetService('RunService')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local LocalPlayer = Players.LocalPlayer

    -- // Functions
    local lastAntiZombieUpdate = tick()
    local playerClass = Cheat.PlayerClass
    local originalHeadSize = (Vector3.one * 1.15)
    local interactables = debug.getupvalue(World.GetInteractable, 2)
    local squadUpdateString = LPH_ENCSTR('Squad Update')
    local memberString = LPH_ENCSTR('Member')
    local oldSquadData = Hooks:findUpvalue(Cheat.OriginalNetworkEvents['Squad Update'], function(upvalue)
        -- // Since squadData can only be a table with 1 or less indices
        if (typeof(upvalue) ~= 'table') then return end

        local count = 0
        for index in next, upvalue do
            if (index ~= 'Members') then return end
            count += 1
        end

        if (count > 1) then return end
        return true
    end)

    local originalUsername = Players.LocalPlayer.Name
    local spoofedUsername = originalUsername

    local function deepcopy(orig)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key)] = deepcopy(orig_value)
            end
            setmetatable(copy, deepcopy(getmetatable(orig)))
        else
            copy = orig
        end
        return copy
    end

    local updateSquadData = LPH_NO_VIRTUALIZE(function()
        local squadData = {
            Owner = Players.LocalPlayer,
            Members = {},
        }

        for _, playerObject in next, Players:GetPlayers() do
            squadData.Members[playerObject.Name] = {
                Status = memberString,
            }
        end

        Cheat.NetworkEvents[squadUpdateString](squadData)
    end)

    local updateVehicleMods = LPH_JIT_MAX(function(vehicle)
        if (typeof(vehicle) ~= 'Instance') then
            if (not playerClass.Character) or (not playerClass.Character.Vehicle) then return end

            vehicle = playerClass.Character.Vehicle
        end

        local vehicleController = VehicleController.get(vehicle)
        if (not vehicleController) then return end
        local originalConfig = Cheat:requireFix(vehicleController.Instance.Config)

        if (Cheat.Library.flags.vehicleModsEnabled) then
            vehicleController.Config.Physics.DriveSpeed = (originalConfig.Physics.DriveSpeed) * (Cheat.Library.flags.driveSpeedEnabled and Cheat.Library.flags.vehicleDriveSpeed or 1)
            vehicleController.Config.Physics.ReverseSpeed = (originalConfig.Physics.ReverseSpeed) * (Cheat.Library.flags.reverseSpeedEnabled and Cheat.Library.flags.vehicleReverseSpeed or 1)
            vehicleController.Config.Physics.SteerResponce = (originalConfig.Physics.SteerResponce) * (Cheat.Library.flags.steeringResponseEnabled and Cheat.Library.flags.vehicleSteerResponse or 1)
            vehicleController.SteerSolver.Speed = vehicleController.Config.Physics.SteerResponce
            vehicleController.Config.Physics.ThrottleResponce = (originalConfig.Physics.ThrottleResponce) * (Cheat.Library.flags.throttleReponseEnabled and Cheat.Library.flags.vehicleThrottleResponse or 1)
            vehicleController.ThrottleSolver.Speed = vehicleController.Config.Physics.ThrottleResponce
            vehicleController.Config.Physics.FullSteeringUntil = (originalConfig.Physics.FullSteeringUntil) * (Cheat.Library.flags.fullSteeringEnabled and Cheat.Library.flags.vehicleFullSteering or 1)
            vehicleController.Config.Physics.NoSteeringAfter = (originalConfig.Physics.NoSteeringAfter) * (Cheat.Library.flags.noSteeringEnabled and Cheat.Library.flags.vehicleNoSteering or 1)

            vehicleController.Config.Physics.BoatMode = (Cheat.Library.flags.fakeRepairedVehicle or originalConfig.Physics.BoatMode)

            if (vehicleController.Config.Physics.FloorRaycastCount) then
                vehicleController.Config.Physics.FloorRaycastCount = (originalConfig.Physics.FloorRaycastCount) * (Cheat.Library.flags.floorRayCountEnabled and Cheat.Library.flags.vehicleFloorRaycount or 1)
            end

            for i, v in next, vehicleController.Config.Physics.MaterialGrip do
                v.Friction = (Cheat.Library.flags.frictionEnabled and Cheat.Library.flags.vehicleFrictionValue) or originalConfig.Physics.MaterialGrip[i].Friction
            end

            for i, v in next, vehicleController.Config.Physics.Wheels do
                v.Friction = (Cheat.Library.flags.frictionEnabled and Cheat.Library.flags.vehicleFrictionValue) or originalConfig.Physics.Wheels[i].Friction
            end
        else
            vehicleController.Config.Physics.DriveSpeed = (originalConfig.Physics.DriveSpeed)
            vehicleController.Config.Physics.ReverseSpeed = (originalConfig.Physics.ReverseSpeed)
            vehicleController.Config.Physics.SteerResponce = (originalConfig.Physics.SteerResponce)
            vehicleController.SteerSolver.Speed = vehicleController.Config.Physics.SteerResponce
            vehicleController.Config.Physics.ThrottleResponce = (originalConfig.Physics.ThrottleResponce)
            vehicleController.ThrottleSolver.Speed = vehicleController.Config.Physics.ThrottleResponce
            vehicleController.Config.Physics.FullSteeringUntil = (originalConfig.Physics.FullSteeringUntil)
            vehicleController.Config.Physics.NoSteeringAfter = (originalConfig.Physics.NoSteeringAfter)

            vehicleController.Config.Physics.BoatMode = (originalConfig.Physics.BoatMode)

            if (vehicleController.Config.Physics.FloorRaycastCount) then
                vehicleController.Config.Physics.FloorRaycastCount = (originalConfig.Physics.FloorRaycastCount)
            end

            for i, v in next, vehicleController.Config.Physics.MaterialGrip do
                v.Friction = originalConfig.Physics.MaterialGrip[i].Friction
            end

            for i, v in next, vehicleController.Config.Physics.Wheels do
                v.Friction = originalConfig.Physics.Wheels[i].Friction
            end
        end
    end)

    local headString = LPH_ENCSTR('Head')
    local updateBigHead = LPH_NO_VIRTUALIZE(function()
        for _, character in next, ReplicationUtility:GetCharacters() do
            if (not character:FindFirstChild(headString)) then
                continue
            end

            if (Cheat.Library.flags.bigHead) then
                character.Head.Size = (originalHeadSize * Cheat.Library.flags.bigHeadSize)
                character.Head.CanCollide = false
            else
                character.Head.Size = originalHeadSize
                character.Head.CanCollide = true
            end
        end
    end)

    -- // Library Stuff
    local LeftSide = Cheat.Library.MiscTab:AddColumn()
    local RightSide = Cheat.Library.MiscTab:AddColumn()

    -- // Server Hop Button lol
    Cheat.Library.SettingsMain:AddButton({ text = 'Server Hop', flag = 'serverHop', callback = function() Cheat:serverHop() end })
    Cheat.Library.SettingsMain:AddList({ flag = 'serverPriority', tip = 'Target Server Size', values = {'High Population', 'Low Population'} })

    -- // Stream Sniper Stuff lmao
    local function all_trim(s)
        return string.match(s, "^%s*(.-)%s*$")
    end
    
    Cheat.Library.SettingsMain:AddBox({
        text = "Username",
        flag = "snipeUsername",
        skipflag = true
    })
    Cheat.Library.SettingsMain:AddButton({text = 'Stream Snipe', callback = function() Cheat:streamSnipe(all_trim(Cheat.Library.flags["snipeUsername"])) end})

    -- // Spectate
    local SpectateSection = LeftSide:AddSection('Spectate')
    local freecam = Cameras:GetCamera('FreeCam')
    local freecamUpvalue = debug.getupvalue(freecam.Step, 2)

    SpectateSection:AddToggle({ text = 'Freecam', flag = 'freecamEnabled', callback = function(state)
        if (state) and (not playerClass.Character) then
            Cheat.Library.options.freecamEnabled:SetState(false)
            Cheat:notifyError('Please spawn in to use this feature.', 5, true)
            return
        end 

        if (state) then
            freecamUpvalue.Position.Spring:SnapTo(workspace.CurrentCamera.CFrame.Position, 1)
            ReplicationUtility:Anchor(true)
            Cameras:SetCurrent('FreeCam')
        elseif (playerClass.Character) then
            local currentGameCamera = Cameras:GetCurrent()
            if (currentGameCamera) and (currentGameCamera.LastWorldSet ~= nil) then
                currentGameCamera.LastWorldSet = os.clock()
            end
            World:Set(ReplicationUtility.rootPart.Position, 'Camera', 100):Wait()
            Cameras:SetCurrent('Character')
            ReplicationUtility:Anchor(false)
        end
    end }):AddBind({ flag = 'freecamBind', callback = function(state) Cheat.Library.options.freecamEnabled:SetState(state) end })

    local spectateList = SpectateSection:AddList({ text = 'Spectate Player', flag = 'spectateTarget', max = 12, skipflag = true, callback = function(state) task.defer(Cheat.Spectate, Cheat, Cheat:getPlayer(state)) end })
    table.insert(Cheat.PlayerLists, spectateList)

    SpectateSection:AddToggle({ text = 'Spoof Look Direction', flag = 'spoofLookDirection', tip = 'Spoofs your look direction so that any spectators can\'t see your real look direction' })
    
    -- // Spectate Detection
    local detectedSpectators = {}
    local reportedSpectators = {}
    local lastSpectateCheck = tick()

    if (LPH_OBFUSCATED) then
        -- // this is just to make sure luraph completely deletes the else below for the actual spec detector
    else
        task.defer(function()
            Cheat.Library.options.stopInspectingTheFuckingConfig1.callback = function(state)
                if (not state) then
                    return
                end

                for playerObject, _ in next, detectedSpectators do
                    Cheat:notifyWarn(playerObject.Name .. ' is currently in Spectate.', 10)
                end
            end
        end)

        -- SpectateSection:AddToggle({ text = 'Detect Spectators', flag = 'detectSpectators', tip = 'Detects when staff go into spectate. This does have the potential to false flag, so take any alerts with a grain of salt', callback = function(state)
        --     if (state) then
        --         for playerObject, _ in next, detectedSpectators do
        --             Cheat:notifyWarn(playerObject.Name .. ' is currently in Spectate.', 10)
        --         end
        --     end
        -- end })
    end

    if (game.PlaceId ~= 10077968348) then
        -- // We don't want this running on tourney hub, since it can false flag there.
        RunService.Heartbeat:Connect(LPH_JIT_MAX(function(deltaTime)
            if (tick() - lastSpectateCheck < 0.1) then
                return
            end
    
            lastSpectateCheck = tick()
    
            for _, playerObject in next, Players:GetPlayers() do
                if (playerObject == LocalPlayer) or (not playerObject:FindFirstChild('Stats')) or (playerObject.Parent ~= Players) then
                    continue
                end
    
                if (playerObject.Character) or (playerObject.Stats.Health.Value <= 0) then
                    -- // If they have a character OR are actually dead (no character & 0 health)
                    if (detectedSpectators[playerObject]) then
                        detectedSpectators[playerObject] = nil
    
                        if (Cheat.Library.flags.stopInspectingTheFuckingConfig1) and (not LPH_OBFUSCATED) then
                            Cheat:notifyWarn(playerObject.Name .. ' has exited spectate.', 10)
                        end
                    end
    
                    continue
                end
    
                if (detectedSpectators[playerObject]) then
                    -- // Prevent Spam Notifications
                    continue
                end
    
                -- // If they don't have a Character, and their health isn't 0
                detectedSpectators[playerObject] = true
    
                if (Cheat.Library.flags.stopInspectingTheFuckingConfig1) and (not LPH_OBFUSCATED) then
                    Cheat:notifyWarn(playerObject.Name .. ' has went into spectate.', 10)
                end
    
                -- // Report that nigga
                if (reportedSpectators[playerObject]) or (table.find(Cheat.Staff, playerObject.UserId)) then
                    reportedSpectators[playerObject] = true
                    return
                end
    
                reportedSpectators[playerObject] = true
    
                task.defer(function()
                    task.wait(2)
                    Cheat:networkWait(4)
    
                    if (playerObject) and (playerObject.Parent == Players) and (detectedSpectators[playerObject]) then
                        if (not LPH_OBFUSCATED) and (Cheat.Library.flags.stopInspectingTheFuckingConfig0) then
                            Cheat:notifyWarn('Snitched ' .. playerObject.Name .. ' to ARS servers', 10)
                        end
                        
                        Cheat:staffDetection(playerObject.UserId)
                        return
                    end
    
                    if (playerObject) then
                        reportedSpectators[playerObject] = false
                    end
                end)
            end
        end))
    end

    -- // Misc
    local MiscSection = LeftSide:AddSection('Extra')

    MiscSection:AddToggle({ text = 'Player Stats', flag = 'playerStats', callback = function(state)
        if (state) then
            return updateSquadData()
        end

        if (oldSquadData and oldSquadData.Members) then
            -- // Bug Fix
            local previous = nil
            while true do
                local i, v = next(oldSquadData.Members, previous)

                if (not i) then
                    break
                end

                previous = i
                
                if (typeof(i) ~= 'Instance') then
                    continue
                end
    
                oldSquadData.Members[i] = nil
                previous = i.Name
                oldSquadData.Members[i.Name] = v
            end
        end

        Cheat.NetworkEvents['Squad Update'](oldSquadData)
    end }):AddBind({ flag = 'playerStatsBind', callback = function(state) Cheat.Library.options.playerStats:SetState(state) end })
    
    MiscSection:AddButton({ text = 'Interact All', flag = 'interactAll', unsafe = true, callback = function()
        if (not ReplicationUtility.rootPart) then
            return Cheat:notifyError('Please spawn in to use this feature.', 5, true)
        end

        local position = ReplicationUtility.rootPart.Position
        for _, interactable in next, interactables do
            if (interactable.Destroyed) then
                continue
            end

            task.defer(function()
                for i = 1, 15 do
                    if (interactable.Destroyed) then
                        break
                    end

                    interactable:Interact(position)
                    task.wait(1)
                end
            end)
        end
    end })

    -- MiscSection:AddButton({ text = 'Safe Combat Log', flag = 'safeCombatLog', tip = 'Teleports you out of combat and leaves', callback = function()
    --     if (not playerClass.Character) then
    --         return Notifications:Notify('Please spawn in to use this feature.', 5, 'ERROR')
    --     end

    --     if (not Hotbar.Gui.Combat.Visible) then
    --         return Players.LocalPlayer:Kick('Safe Exited')
    --     end

    --     Fade:SetText('Combat Logging')
    --     Fade:Fade(0, 0.25):Wait()
        
    --     local failed = false
    --     task.defer(function()
    --         failed = (not Cheat:Teleport(ReplicationUtility.rootPart.CFrame * CFrame.new(0, -1000, 0), false, false, true, true))
    --     end)

    --     while (Hotbar.Gui.Combat.Visible) and (ReplicationUtility.rootPart) and (not failed) do
    --         task.wait(0.1)
    --         Cheat:networkWait()
    --     end

    --     -- // Failed Condition
    --     if (failed) then
    --         Fade:Fade(1, 0)
    --         Cheat:notifyError('Safe Combat Log Failed', 10, true)
    --         return
    --     end

    --     return Players.LocalPlayer:Kick('Safe Exited')
    -- end })

    MiscSection:AddToggle({ text = 'Always Map & Compass', flag = 'alwaysMapCompass', tip = 'Always have the map & compass', callback = function(state)
        if (playerClass.Character) then
            playerClass.Character.PerksChanged:Fire()
        end
    end }):AddBind({ flag = 'alwaysMapCompassBind', callback = function(state) Cheat.Library.options.alwaysMapCompass:SetState(state) end })
    
    MiscSection:AddToggle({ text = 'Unlock Aura', flag = 'unlockAura', tip = 'Automatically unlocks cosmetics near you' }):AddBind({ flag = 'unlockAuraBind', callback = function(state) Cheat.Library.options.unlockAura:SetState(state) end })
    MiscSection:AddToggle({ text = 'Auto Consume', flag = 'autoConsume', tip = 'Consumes items in the background. Simply equip and unequip a consumable' }):AddBind({ flag = 'autoConsumeBind', callback = function(state) Cheat.Library.options.autoConsume:SetState(state) end })
    MiscSection:AddToggle({ text = 'Instant Respawn', flag = 'instantRespawn', tip = 'Respawn Instantly' }):AddBind({ flag = 'instantRespawnBind', callback = function(state) Cheat.Library.options.instantRespawn:SetState(state) end })
    MiscSection:AddToggle({ text = 'Keep Containers Open', flag = 'containerPersistence', tip = 'Will keep any container you open in your inventory, even if you close your inventory' }):AddBind({ flag = 'keepContainerBind', callback = function(state) Cheat.Library.options.containerPersistence:SetState(state) end })
    MiscSection:AddToggle({ text = 'Anti Zombie', flag = 'antiZombie', tip = 'Prevents zombies from attacking you', unsafe = true, callback = function(state)
        if (state) then
            return
        end
        
        for _, v in next, workspace.Zombies.Mobs:GetChildren() do
            if (not v:FindFirstChild('HumanoidRootPart')) then
                continue
            end

            v.HumanoidRootPart.Anchored = false
        end
    end}):AddBind({ flag = 'antiZombieBind', callback = function(state) Cheat.Library.options.antiZombie:SetState(state) end })
    MiscSection:AddToggle({ text = 'Instant Interact', flag = 'instantInteract', tip = 'Interact Instantly' }):AddBind({ flag = 'instantInteractBind', callback = function(state) Cheat.Library.options.instantInteract:SetState(state) end })
    
    -- // Staff Detector
    local leaveString = LPH_ENCSTR('Leave')
    local serverHopString = LPH_ENCSTR('Server Hop')
    local staffDetectedString = LPH_ENCSTR('Staff Detected: ')

    local moderatorAction = LPH_NO_VIRTUALIZE(function(staffPlayer)
        if (Cheat.Library.flags.modAction == leaveString) then
            return Players.LocalPlayer:Kick(staffDetectedString..staffPlayer.Name)
        elseif (Cheat.Library.flags.modAction == serverHopString) then
            return Cheat:serverHop()
        end

        Cheat:notifyWarn(staffDetectedString..staffPlayer.Name, 10)
    end)

    local moderatorCheck = LPH_NO_VIRTUALIZE(function()
        for _, playerObject in next, Players:GetPlayers() do
            if (not Cheat:isStaff(playerObject)) then
                continue
            end

            moderatorAction(playerObject)
        end
    end)

    MiscSection:AddToggle({ text = 'Staff Detector', flag = 'modDetector', callback = function(state) 
        if (state) then
            moderatorCheck()
        end
    end }):AddList({ text = 'On Moderator Join', flag = 'modAction', values = {'Notify', 'Leave', 'Server Hop'} })

    -- // Damage Sound
    MiscSection:AddToggle({ text = 'Damage Sound', flag = 'hitSound', tip = 'Play a sound when you deal damage' }):AddBind({ flag = 'hitSoundBind', callback = function(state) Cheat.Library.options.hitSound:SetState(state) end })
    MiscSection:AddBox({ flag = 'hitSoundId', value = '8679627751', tip = 'Put a sound id (number only), or the path to an audio file in your workspace folder' })

    -- // Headshot Sound
    MiscSection:AddToggle({ text = 'Headshot Sound', flag = 'headShotSound', callback = function(state)
        if (state) then
            local soundId = Cheat.Library.flags.headShotSoundId

            if (isfile(soundId)) then
                soundId = getcustomasset(soundId)
            else
                soundId = 'rbxassetid://'..soundId
            end

            ReplicatedStorage.Assets.Sounds.Impact.Headshot.SoundId = soundId
        else
            ReplicatedStorage.Assets.Sounds.Impact.Headshot.SoundId = 'rbxassetid://2062016772'
        end
    end }):AddBind({ flag = 'headShotSoundBind', callback = function(state) Cheat.Library.options.headShotSound:SetState(state) end })

    MiscSection:AddBox({ flag = 'headShotSoundId', value = '5043539486', tip = 'Put a sound id (number only), or the path to an audio file in your workspace folder', callback = function(state)
        Cheat.Library.options.headShotSound.callback(Cheat.Library.flags.headShotSound)
    end })

    -- // Bodyshot Sound
    MiscSection:AddToggle({ text = 'Bodyshot Sound', flag = 'bodyShotSound', callback = function(state)
        if (state) then
            local soundId = Cheat.Library.flags.bodyShotSoundId

            if (isfile(soundId)) then
                soundId = getcustomasset(soundId)
            else
                soundId = 'rbxassetid://'..soundId
            end

            ReplicatedStorage.Assets.Sounds.Impact.Bodyshot.SoundId = soundId
            ReplicatedStorage.Assets.Sounds.Impact.Limbshot.SoundId = soundId
        else
            ReplicatedStorage.Assets.Sounds.Impact.Bodyshot.SoundId = 'rbxassetid://2062015952'
            ReplicatedStorage.Assets.Sounds.Impact.Limbshot.SoundId = 'rbxassetid://6659353525'
        end
    end }):AddBind({ flag = 'bodyShotSoundBind', callback = function(state) Cheat.Library.options.bodyShotSound:SetState(state) end })

    MiscSection:AddBox({ flag = 'bodyShotSoundId', value = '6229978482', tip = 'Put a sound id (number only), or the path to an audio file in your workspace folder', callback = function(state)
        Cheat.Library.options.bodyShotSound.callback(Cheat.Library.flags.bodyShotSound)
    end })

    MiscSection:AddToggle({ text = 'Zombie Circle', flag = 'zombieCircle', tip = 'Disable Anti Zombie to use', unsafe = true })
        :AddBind({ flag = 'zombieCircleBind', callback = function(state) Cheat.Library.options.zombieCircle:SetState(state) end })
    
    MiscSection:AddSlider({ text = 'Zombie Circle Speed', flag = 'zombieCircleSpeed', value = 1, min = 1, max = 10000 })
    MiscSection:AddSlider({ text = 'Zombie Circle Radius', flag = 'zombieCircleRadius', value = 10, min = 7, max = 100 })
    -- MiscSection:AddToggle({ text = 'Fake Lag', flag = 'fakeLag', tip = 'Makes you appear laggy to other players' }):AddBind({ flag = 'fakeLagBind', callback = function(state) Cheat.Library.options.fakeLag:SetState(state) end })

    -- // Spoof Username (AUTISTIC CODE ALERT)
    local addNewPlayerCard = nil

    for _, v in next, getgc() do
        if (typeof(v) ~= 'function') or (not islclosure(v)) then
            continue
        end

        if (getinfo(v).name == 'addNewPlayerCard') then
            addNewPlayerCard = v
            break
        end
    end

    local playerList = debug.getupvalue(addNewPlayerCard, 1)

    MiscSection:AddToggle({ text = 'Streamer Mode', flag = 'streamerMode', tip = 'Changes your name CLIENT SIDED', callback = function(state)
        if (state) then
            spoofedUsername = Cheat.Library.flags.spoofedUsername
        else
            spoofedUsername = originalUsername
        end

        Players.LocalPlayer.Name = spoofedUsername
        Players.LocalPlayer.DisplayName = spoofedUsername

        local selfPlayer = playerList[Players.LocalPlayer]
        if (selfPlayer and selfPlayer.Gui) then
            selfPlayer.Gui.NameButton.NameLabelBin.NameLabel.Text = spoofedUsername
            selfPlayer.Gui.NameButton.NameLabelBin.NameLabel.Backdrop.Text = spoofedUsername
        end
    end }):AddBind({ flag = 'streamerModeBind', callback = function(state) Cheat.Library.options.streamerMode:SetState(state) end })

    MiscSection:AddBox({ text = 'Username', flag = 'spoofedUsername', tip = 'CLIENT SIDED', callback = function(state)
        Cheat.Library.options.streamerMode.callback(Cheat.Library.flags.streamerMode)
    end })
    
    -- // BigHead
    local bigheadCleaner = Cleaner.new()

    MiscSection:AddToggle({ text = 'Enlarge Heads', flag = 'bigHead', callback = function(state)
        bigheadCleaner:Clean()

        if (state) then
            bigheadCleaner:AddConnection(workspace.Characters.ChildAdded:Connect(LPH_NO_VIRTUALIZE(function()
                task.wait()
                updateBigHead()
            end)))
        end

        updateBigHead()
    end}):AddSlider({ flag = 'bigHeadSize', value = 1, min = 1, max = 30, safeMax = 3, callback = updateBigHead })
        :AddBind({ flag = 'bigHeadBind', callback = function(state) Cheat.Library.options.bigHead:SetState(state) end })

    -- // Auto Open Door
    local autoOpenDoorCleaner = Cleaner.new()

    MiscSection:AddToggle({ text = 'Auto Open Door', flag = 'autoOpenDoor', tip = 'wont get you banned 🤑', unsafe = true, callback = function(state)
        autoOpenDoorCleaner:Clean()

        if (not state) then return end

        autoOpenDoorCleaner:AddConnection(RunService.Heartbeat:Connect(function(deltaTime)
            if (not ReplicationUtility.rootPart) then return end
            local rootPosition = ReplicationUtility.rootPart.Position

            for _, interactable in next, interactables do
                if (interactable.Destroyed) or (interactable.Type ~= 'Door') or (interactable.State ~= 'Closed') then
                    continue
                end
                
                if (interactable:GetInteractionPosition() - rootPosition).Magnitude > 15 then
                    continue
                end

                interactable:Interact()
            end
        end))
    end }):AddBind({ flag = 'autoOpenDoorBind', callback = function(state) Cheat.Library.options.autoOpenDoor:SetState(state) end })

    -- // Weapon Cheats
    local WeaponSection = RightSide:AddSection('Weapon Modification')

    WeaponSection:AddToggle({ text = 'Enabled', flag = 'weaponModsEnabled', callback = function(state)
        if (state) then
            Cheat.AllFireModesChanged:Fire(Cheat.Library.flags.allFireModes)
        else
            Cheat.AllFireModesChanged:Fire(false)
        end
    end }):AddBind({ flag = 'weaponModsBind', callback = function(state) Cheat.Library.options.weaponModsEnabled:SetState(state) end })
    
    WeaponSection:AddToggle({ text = 'Weapon Spread', flag = 'spreadMod', tip = 'Modify Weapon Spread' }):AddSlider({ flag = 'spreadValue', value = 100, min = 0, max = 100, suffix = '%' })
    WeaponSection:AddToggle({ text = 'Weapon Recoil', flag = 'recoilMod', tip = 'Modify Weapon Recoil' }):AddSlider({ flag = 'recoilValue', value = 100, min = 0, max = 100, suffix = '%' })

    WeaponSection:AddToggle({ text = 'All Fire Modes', flag = 'allFireModes', tip = 'Use any firemode on any gun. for example: Auto on a Snubnose', callback = function(state)
        if (not Cheat.Library.flags.weaponModsEnabled) then
            return
        end

        Cheat.AllFireModesChanged:Fire(state)
    end }):AddBind({ flag = 'allFireModesBind', callback = function(state) Cheat.Library.options.allFireModes:SetState(state) end })
    
    -- WeaponSection:AddToggle({ text = 'ADS FOV', flag = 'adsFOV', tip = 'Camera Aiming Field of View' }):AddSlider({ flag = 'adsFovValue', value = 85, min = 0, max = 85 })

    WeaponSection:AddToggle({ text = 'No Muzzle Flash', flag = 'noMuzzleFlash', tip = 'Removes muzzle flash when you shoot' }):AddBind({ flag = 'noMuzzleFlashBind', callback = function(state) Cheat.Library.options.noMuzzleFlash:SetState(state) end })
    WeaponSection:AddToggle({ text = 'Instant Reload', flag = 'instantReload', tip = 'Reload instantly' }):AddBind({ flag = 'instantReloadBind', callback = function(state) Cheat.Library.options.instantReload:SetState(state) end })
    WeaponSection:AddToggle({ text = 'Instant Bullets', flag = 'instantBullets', tip = 'Makes bullets travel instantly' }):AddBind({ flag = 'instantBulletsBind', callback = function(state) Cheat.Library.options.instantBullets:SetState(state) end })
    WeaponSection:AddToggle({ text = 'Anti Flinch', flag = 'antiFlinch', tip = 'Prevents your camera from shaking from bullets', callback = function(state) Globals.GlobalFlinchMod = (state and 0) or 1 end }):AddBind({ flag = 'antiFlinchBind', callback = function(state) Cheat.Library.options.antiFlinch:SetState(state) end })
    WeaponSection:AddToggle({ text = 'Auto Reload', flag = 'autoReload', tip = 'Reload automatically' }):AddBind({ flag = 'autoReloadBind', callback = function(state) Cheat.Library.options.autoReload:SetState(state) end })

    -- // Vehicle Cheats
    local VehicleSection = RightSide:AddSection('Vehicle Modification')
    local vehicleBumperImpactString = LPH_ENCSTR('Vehicle Bumper Impact')
    local impactHitboxString = LPH_ENCSTR('Impact Hitbox')
    local genericString = LPH_ENCSTR('Generic')
    local errorString = LPH_ENCSTR('ERROR')
    local notSpawnedErrorString = LPH_ENCSTR('Please spawn in to use this feature.')
    local noVehicleErrorString = LPH_ENCSTR('Please drive a vehicle to use this feature.')

    VehicleSection:AddButton({ text = 'Explode Vehicle', flag = 'explodeTheVehicle', unsafe = true, callback = function()
        if (not playerClass.Character) then
            return Cheat:notifyError(notSpawnedErrorString, 5, true)
        end
        
        if (not playerClass.Character.Vehicle) then
            return Cheat:notifyError(noVehicleErrorString, 5, true)
        end

        -- // Boom
        local vehicle = playerClass.Character.Vehicle
        local interaction = vehicle.Interaction

        for i = 1, 50 do
            Network:Send(vehicleBumperImpactString, vehicle, interaction:FindFirstChild(impactHitboxString), 10, vehicle.PrimaryPart, genericString)
        end
    end}):AddBind({ flag = 'explodeTheVehicleBind', callback = Cheat.Library.options.explodeTheVehicle.callback })

    VehicleSection:AddToggle({ text = 'Anti Flip', flag = 'antiVehicleFlip', tip = 'Prevents your vehicle from flipping over' }):AddBind({ flag = 'antiVehicleFlipBind', callback = function(state) Cheat.Library.options.antiVehicleFlip:SetState(state) end })
    VehicleSection:AddToggle({ text = 'Infinite Fuel', flag = 'infiniteFuel', tip = 'Who needs gas?', unsafe = true }):AddBind({ flag = 'infiniteFuelBind', callback = function(state) Cheat.Library.options.infiniteFuel:SetState(state) end })
    VehicleSection:AddToggle({ text = 'No Vehicle Damage', flag = 'noVehicleDamage', tip = 'Prevents your vehicle from taking damage' }):AddBind({ flag = 'vehicleDamageBind', callback = function(state) Cheat.Library.options.noVehicleDamage:SetState(state) end })
    VehicleSection:AddToggle({ text = 'Enabled', flag = 'vehicleModsEnabled', callback = updateVehicleMods }):AddBind({ flag = 'vehicleModsBind', callback = function(state) Cheat.Library.options.vehicleModsEnabled:SetState(state) end })
    VehicleSection:AddToggle({ text = 'Fake Repaired', flag = 'fakeRepairedVehicle', callback = updateVehicleMods }):AddBind({ flag = 'fakeRepairedVehicleBind', callback = function(state) Cheat.Library.options.fakeRepairedVehicle:SetState(state) end })

    VehicleSection:AddToggle({ text = 'Drive Speed', flag = 'driveSpeedEnabled', callback = updateVehicleMods })
        :AddSlider({ flag = 'vehicleDriveSpeed', value = 1, min = 0, max = 10, float = 0.1, suffix = 'x', safeMax = 1.5, callback = updateVehicleMods })
    
    VehicleSection:AddToggle({ text = 'Reverse Speed', flag = 'reverseSpeedEnabled', callback = updateVehicleMods })
        :AddSlider({ flag = 'vehicleReverseSpeed', value = 1, min = 0, max = 10, float = 0.1, suffix = 'x', safeMax = 1.5, callback = updateVehicleMods })

    VehicleSection:AddToggle({ text = 'Steering Response', flag = 'steeringResponseEnabled', callback = updateVehicleMods })
        :AddSlider({ flag = 'vehicleSteerResponse', value = 1, min = 0, max = 10, float = 0.1, suffix = 'x', callback = updateVehicleMods })
        
    VehicleSection:AddToggle({ text = 'Throttle Response', flag = 'throttleReponseEnabled', callback = updateVehicleMods })
        :AddSlider({ flag = 'vehicleThrottleResponse', value = 1, min = 0, max = 10, float = 0.1, suffix = 'x', safeMax = 2, callback = updateVehicleMods })
    
    VehicleSection:AddToggle({ text = 'Full Steering Until', flag = 'fullSteeringEnabled', callback = updateVehicleMods })
        :AddSlider({ flag = 'vehicleFullSteering', value = 1, min = 0, max = 10, float = 0.1, suffix = 'x', callback = updateVehicleMods })
    
    VehicleSection:AddToggle({ text = 'No Steering After', flag = 'noSteeringEnabled', callback = updateVehicleMods })
        :AddSlider({ flag = 'vehicleNoSteering', value = 1, min = 0, max = 10, float = 0.1, suffix = 'x', callback = updateVehicleMods })
    
    VehicleSection:AddToggle({ text = 'Floor Raycast Count', flag = 'floorRayCountEnabled', callback = updateVehicleMods })
        :AddSlider({ flag = 'vehicleFloorRaycount', value = 1, min = 0, max = 10, float = 0.1, suffix = 'x', callback = updateVehicleMods })

    VehicleSection:AddToggle({ text = 'Friction', flag = 'frictionEnabled', callback = updateVehicleMods })
        :AddSlider({ flag = 'vehicleFrictionValue', value = 1, min = 0, max = 10, float = 0.1, suffix = 'x', callback = updateVehicleMods })

    -- // Hooks
    local findItemData = nil

    for _, v in next, getgc() do
        if (findItemData) then break end
        if (type(v) ~= 'function') or (not islclosure(v)) then continue end
        
        local env = getfenv(v)
        local upvalues = debug.getupvalues(v)

        if (not env.script) then
            continue
        end

        if (env.script.Name == 'Interact') and (getinfo(v).name == 'findItemData') then
            findItemData = v
        end
    end

    local oldFindItemData; oldFindItemData = Hooks:upvalueBypassHook(findItemData, LPH_NO_VIRTUALIZE(function(...)
        local parent, container, getDrawPosition, interactionTime, interactType, interactColor = oldFindItemData(...)

        if (Cheat.Library.flags.instantInteract) then
            interactionTime = 0
        end
    
        return parent, container, getDrawPosition, interactionTime, interactType, interactColor
    end))

    local oldTakeVehicleOwnership; oldTakeVehicleOwnership = Cheat.NetworkEvents['Take Vehicle Ownership']
    Cheat.NetworkEvents['Take Vehicle Ownership'] = function(vehicleInstance, ...)
        local result = oldTakeVehicleOwnership(vehicleInstance, ...)

        -- // Deep copy
        local vehicleController = VehicleController.get(vehicleInstance)

        vehicleController.Config = deepcopy(Cheat:requireFix(vehicleInstance.Config))

        -- // Vehicle Mod
        updateVehicleMods(vehicleInstance)

        return result
    end

    local oldDeathActionLogger = Cheat.NetworkEvents['Death Action Logger']
    Cheat.NetworkEvents['Death Action Logger'] = LPH_NO_VIRTUALIZE(function(deathActionType, deathActionData, ...)
        if (typeof(deathActionData) == 'table') then
            for _, v in next, deathActionData do
                if (v.Text ~= originalUsername) then
                    continue
                end
    
                v.Text = spoofedUsername
            end
        end

        return oldDeathActionLogger(deathActionType, deathActionData, ...)
    end)

    local oldCharacterDead = Cheat.NetworkEvents['Character Dead']
    Cheat.NetworkEvents['Character Dead'] = function(...)
        if (Cheat.Spectating) then
            task.spawn(Cheat.Spectate, Cheat, Players.LocalPlayer)
        end

        -- // fakeInvis
        Cheat.rootCFrame = nil

        -- // Anti-cheat disabler
        Cheat.anticheatDisabled = false

        if (Cheat.Library.flags.instantRespawn) then
            if (playerClass.Character) then
                playerClass.Character.Health:Set(0)
                playerClass:UnloadCharacter()

                Interface:Get('Unlock'):ClearQueue()
                Interface:Hide('GameMenu', 'Compass', 'Map', 'Hotbar', 'Controls', 'Weapon', 'Reticle')
                Cameras:SetCurrent('Default')
                Interface:Get('Unlock'):ClearQueue()
                Interface:Show('Chat', 'PlayerList')
                Fade:SetText('')
                Fade:Fade(0, 0)

                task.delay(.25, function() -- // to avoid any potential detections
                    Network:Send('Set Last Loadout')

                    playerClass.CharacterAdded:Once(function()
                        Fade:Fade(1, .1)
                    end)

                    Network:Send('Spawn In Character')
                end)
            end

            return true
        end

        return oldCharacterDead(...)
    end
    
    local oldSquadUpdate = Cheat.NetworkEvents['Squad Update']
    Cheat.NetworkEvents['Squad Update'] = LPH_NO_VIRTUALIZE(function(squadData)
        if (not checkcaller()) then
            -- // Spoof Username thing
            if (Cheat.Library.flags.streamerMode and squadData) then
                local previous = nil
                while true do
                    local i, v = next(squadData.Members, previous)
    
                    if (not i) then
                        break
                    end
    
                    previous = i
        
                    if (i ~= originalUsername) then
                        continue
                    end

                    squadData.Members[i] = nil
                    squadData.Members[spoofedUsername] = v
                    previous = spoofedUsername
                end
            end

            oldSquadData = squadData
            ReplicationUtility.TeamMates = (squadData and squadData.Members) or {}

            if (Cheat.Library.flags.playerStats) then
                squadData = {
                    Owner = Players.LocalPlayer,
                    Members = {},
                }
        
                for _, playerObject in next, Players:GetPlayers() do
                    squadData.Members[playerObject.Name] = {
                        Status = memberString,
                    }
                end
            end
        end

        return oldSquadUpdate(squadData)
    end)

    -- // Connections
    ReplicationUtility.TeamMates = (oldSquadData and oldSquadData.Members) or {}

    Players.PlayerAdded:Connect(LPH_NO_VIRTUALIZE(function(playerObject)
        -- // Staff Detector
        if (Cheat.Library.flags.modDetector) and (Cheat:isStaff(playerObject)) then
            moderatorAction(playerObject)
        end
        
        -- // Player Stats
        if (Cheat.Library.flags.playerStats) then
            updateSquadData()
        end
    end))

    Players.PlayerRemoving:Connect(LPH_NO_VIRTUALIZE(function(playerObject)
        if (Cheat.Library.flags.playerStats) then
            updateSquadData()
        end
    end))

    local zombies = LPH_ENCSTR('Zombies')
    local mobs = LPH_ENCSTR('Mobs')
    local humanoidRootPart = LPH_ENCSTR('HumanoidRootPart')
    local sleeping = LPH_ENCSTR('Sleeping')
    local anchored = LPH_ENCSTR('Anchored')

    game:GetService('RunService').Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(deltaTime)
        debug.profilebegin('ARS Misc Heartbeat')

        -- // Anti Zombie & Zombie Circle
        if (Cheat.Library.flags.zombieCircle and playerClass.Character) then
            local owned = {}
            local position = ReplicationUtility.rootPart.Position
            
            -- // Get Owned
            for _, v in next, workspace[zombies][mobs]:GetChildren() do
                if (not v:FindFirstChild(humanoidRootPart)) or (not animatorInstances[v]) or (animatorInstances[v][sleeping]) then
                    continue
                end

                v[humanoidRootPart][anchored] = false
                table.insert(owned, v)
            end

            -- // Circle
            for i = 360 / #owned, 360, 360 / #owned do
                local rotation = math.rad((i + tick() * Cheat.Library.flags.zombieCircleSpeed) % 360)

                local x = position.X + math.cos(rotation) * Cheat.Library.flags.zombieCircleRadius
                local z = position.Z + math.sin(rotation) * Cheat.Library.flags.zombieCircleRadius

                local location = math.ceil(#owned * (i / 360))
                local zombie = owned[location]

                if (not zombie) then
                    break
                end

                zombie.PrimaryPart.CFrame = CFrame.new(x, position.Y, z)
            end
        elseif (Cheat.Library.flags.antiZombie) and (tick() - lastAntiZombieUpdate > 0.1) then
            lastAntiZombieUpdate = tick()

            for _, v in next, workspace[zombies][mobs]:GetChildren() do
                if (not v:FindFirstChild(humanoidRootPart)) then
                    continue
                end

                if (not animatorInstances[v]) or (animatorInstances[v][sleeping]) then
                    v[humanoidRootPart][anchored] = false
                    continue
                end

                v[humanoidRootPart][anchored] = true
            end
        end

        -- // Anti Vehicle Flip
        if (Cheat.Library.flags.antiVehicleFlip) and (playerClass.Character and playerClass.Character.Vehicle) then
            local primaryPart = playerClass.Character.Vehicle.PrimaryPart
            local pitch, yaw, roll = primaryPart.CFrame:ToOrientation()

            pitch = math.deg(pitch)
            roll = math.deg(roll)

            if (math.abs(pitch) > 75) or (math.abs(roll) > 30) then
                local velocity = primaryPart.AssemblyAngularVelocity
                primaryPart.AssemblyAngularVelocity = Vector3.new(
                    math.rad(math.clamp(math.deg(velocity.X), -75, 75)),
                    velocity.Y,
                    math.rad(math.clamp(math.deg(velocity.Z), -30, 30))
                )

                primaryPart.CFrame = CFrame.new(primaryPart.Position) * CFrame.Angles(
                    math.rad(math.clamp(pitch, -75, 75)),
                    yaw,
                    math.rad(math.clamp(roll, -30, 30))
                )
            end
        end

        debug.profileend()
    end))

    -- // Vehicle thing
    if (playerClass.Character and playerClass.Character.Vehicle) then
        local vehicleController = VehicleController.get(playerClass.Character.Vehicle)

        vehicleController.Config = deepcopy(Cheat:requireFix(vehicleController.Instance.Config))
    end
end
