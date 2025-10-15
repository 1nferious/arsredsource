return function(Cheat)
    -- // Modules
    local Network = Cheat.Framework.require('Libraries', 'Network')
    local Globals = Cheat.Framework.require('Configs', 'Globals')
    local Notifications = REQUIRE_MODULE('Modules/Libraries/Notification.lua')
    local ReplicationUtility = REQUIRE_MODULE('Modules/Libraries/ReplicationUtility.lua')

    Cheat.IsPlayerEnteringVehicle = false
    Cheat.IsPlayerExitingVehicle = false

    local playerClass = Cheat.PlayerClass

    local spoofPing = LPH_JIT_MAX(function()
        local pingSpoof = (Cheat.Library.flags.dbgPingSpoof and Cheat.Library.flags.dbgPingSpoofValue)
        
        -- // SPEED BYPASS
        if (Cheat.Library.flags.acDisabler) and (Cheat.Library.flags.acDisablerMode == 'Partial') then
            local ping = Network:GetPing()
            pingSpoof = math.max(4 + Random.new():NextNumber(0.25, 0.75) - Cheat:getPing(), 0)
        end

        if (pingSpoof) then
            local timeElapsed = 0
            repeat timeElapsed += task.wait() until (timeElapsed >= pingSpoof) or ((not Cheat.Library.flags.acDisabler) and (not Cheat.Library.flags.dbgPingSpoof))
        end
    end)

    -- // Hooks
    local oldSetDebug; oldSetDebug = Cheat:hookAndTostringSpoof(Network, 'SetDebug', function()
        if (not LPH_OBFUSCATED) then
            Notifications:notifyWarn('A developer is trying to tamper with your game', 60, true)
        end

        return
    end)

    oldSetDebug(Network, function(...)
        -- print('======================================================================')
        -- print(...)
    end)

    local oldSend; oldSend = Cheat:hookAndTostringSpoof(Network, 'Send', LPH_JIT_MAX(function(self, Name, ...)
        local data = {...}

        if (Name == 'Character State Report') then
            -- // Arguments: Network:Send("Character State Report", workspace:GetServerTimeNow(), Cameras:GetCamera("Character").FirstPerson, a1.LookDirectionSpring:GetGoal(), a1.MoveState, a1.AtEaseInput, a1.ShoulderSwapped, a1.Zooming, a1.Staggered, a1.Shoving)
            -- // Look Direction Spoof
            if (Cheat.Library.flags.spoofLookDirection and ReplicationUtility.rootPart) then
                data[3] = ReplicationUtility.rootPart.CFrame.LookVector
            end

            if (Cheat.Library.flags.fakeInvis) then
                data[3] = -Vector3.yAxis
            end

            -- // Bypasses
            local disablerActive = (Cheat.acBypassed or Cheat.anticheatDisabled)

            local originalState = data[4]
            local desireState = originalState
            local switchState = originalState
            
            -- // Speedhack
            if (Cheat.Library.flags.speed or Cheat.Library.flags.fly) and (ReplicationUtility.Humanoid and ReplicationUtility.Humanoid.MoveDirection.Magnitude > 0) then
                desireState = (if originalState == 'Swimming' then 'SprintSwimming' else 'Running')
                data[8] = false
            end

            -- // Flight
            local fakeInvisEnabled = Cheat.Library.flags.fakeInvis
            local bypassFlight = (Cheat.Library.flags.fly or Cheat.Library.flags.jumpHack or Cheat.Library.flags.jesus or Cheat.Library.flags.infJump or Cheat.Library.flags.gravityEnabled or fakeInvisEnabled)
            local groundPart = (bypassFlight and Cheat.PlayerClass.Character.GroundPart)
            local usingJesus = (groundPart and groundPart.Name == 'Water')
            local flyDisabled = false

            if (bypassFlight) and (originalState == 'Falling' or usingJesus or fakeInvisEnabled) then
                switchState = 'Climbing'
                desireState = (if Cheat.Library.flags.noFall then 'SprintSwimming' else 'Running')
                flyDisabled = true
            end

            -- // No Fall Damage
            if (Cheat.Library.flags.noFall) and (not flyDisabled) and (originalState == 'Falling' or Cheat.OriginalLastState == 'Falling') then
                desireState = 'SprintSwimming'
                switchState = desireState
                Cheat.NoFallPackets = 2
            end

            if (Cheat.NoFallPackets > 0) then
                Cheat.NoFallPackets -= 1
                desireState = 'SprintSwimming'
                switchState = desireState
            end

            -- // No Sprint Penalty
            if (Cheat.Library.flags.noSprintPenalty) and ((not flyDisabled) or Cheat.anticheatDisabled) and (desireState == 'Running' or desireState == 'SprintSwimming') then
                local newState = (desireState == 'SprintSwimming' and 'Swimming') or 'Walking'
                if (switchState == desireState) or (Cheat.acBypassed) then
                    switchState = newState
                end

                desireState = newState
            end

            -- // Teleport
            if (Cheat.Teleporting) then
                desireState = 'Climbing'
                switchState = 'Climbing'
            end

            -- // Debugger
            if (Cheat.Library.flags.csChanger) then
                originalState = Cheat.Library.flags.cState
                desireState = originalState
                switchState = originalState
            end
            
            data[4] = (Cheat.SwitchState and switchState) or desireState
            Cheat.SwitchState = (not Cheat.SwitchState)
            Cheat.LastState = data[4]
            Cheat.OriginalLastState = originalState
        elseif (Name == 'Character Jumped') then
            if (Cheat.Library.flags.noSprintPenalty) then
                return
            end
        elseif (Name == 'Inventory Container Group Disconnect' or Name == 'Ammo Movement Cancel') then
            if (Cheat.Library.flags.containerPersistence) and (not checkcaller()) then
                return
            end
        elseif (Name == 'Change Firemode') then
            if (Cheat.Library.flags.allFireModes) then
                -- // just having this incase hutch ever decides to do a firemode check
                return
            end
        elseif (Name == 'Camera Report') then
            -- // WARNING: Second arugment is the current camera you are in, so for spectate, SPOOF IT TO CHARACTER OR WHATEVER ITS SUPPOSED TO BE

            if (data[2] == 'FreeCam' or data[2] == 'Default') then
                data[2] = 'Character'
            end

            if (Cheat.Library.flags.spoofLookDirection) and (ReplicationUtility.rootPart) then
                data[1] = CFrame.lookAt(data[1].Position, data[1].Position + ReplicationUtility.rootPart.CFrame.LookVector)
            end
        elseif (Name == 'Vehicle Bumper Impact') then
            if (Cheat.Library.flags.noVehicleDamage) and (data[5] ~= 'Flesh') and (not checkcaller()) then
                return
            end
        elseif (Name == 'Bullet Impact') then
            if (Cheat.Library.flags.hitLogs or Cheat.Library.flags.invalidLogs) and (data[5]:FindFirstAncestor('StarterCharacter')) then
                Cheat.Shots[data[3]] = {
                    rayResult = data[5],
                    position = data[5].Position,
                    origin = (data[5].CFrame * CFrame.new(data[7][1])).Position,
                }
    
                if (Cheat.Library.flags.invalidLogs) then
                    task.defer(function()
                        task.wait(.5)
                        Cheat:networkWait(4)

                        if (Cheat.Shots[data[3]]) then
                            Cheat.Shots[data[3]] = nil
                            
                            Notifications:Notify('Shot rejected', 5, 'Invalid Logs')
                        end
                    end)
                end
            end
        elseif (Name == 'Vehicle Sit In') then
            Cheat.IsPlayerEnteringVehicle = not checkcaller()
        elseif (Name == 'Vehicle Dismount') then
            Cheat.IsPlayerExitingVehicle = not checkcaller()
        elseif (Name == 'Inventory Pickup Item') then
            -- Inventory Pickup Item -> (Inventory Equip Item / Inventory Slot Utility / Inventory Move Item) translation layer
            
            if (playerClass) and (playerClass.Character) and (Cheat.Library.flags.containerPersistence) and (not checkcaller()) then
                local item = playerClass.Character.Inventory:FindItem(data[1])

                if (item) then
                    if (item.EquipSlot ~= nil) and (playerClass.Character.Inventory.Equipment[item.EquipSlot] == nil) then
                        oldSend(self, 'Inventory Equip Item', item.Id)
    
                        return
                    end

                    if (item.Type == "Utility") and (item.CanSlotAsUtility) and (#playerClass.Character.Inventory.Utilities < Globals.UtilitySlotLimit) then
                        local duplicateUtilityType = false

                        for i, v in next, playerClass.Character.Inventory.Utilities do
                            if (v.UtilityType == item.UtilityType) then
                                duplicateUtilityType = true
                                
                                break
                            end
                        end

                        if (not duplicateUtilityType) then
                            oldSend(self, 'Inventory Slot Utility', item.Id)

                            return
                        end
                    end

                    for _, container in next, playerClass.Character.Inventory.Containers do
                        if (container.IsCarried) then
                            local hasSpace, space = container:HasSpace(item.GridSize)

                            if (hasSpace) then
                                oldSend(self, 'Inventory Move Item', item.Id, container.Id, space, item.Rotated)
                                
                                return
                            end
                        end
                    end
                end
            end
        elseif (table.find(Cheat.CrashBanPackets, Name)) then
            local env = getfenv(2)
            local oldTask = env.task

            env.task = { -- // if i start crashing, we know whats up.. lol
                wait = newcclosure(function()
                    env.task = oldTask
                    return
                end)
            }
            return
        elseif (table.find(Cheat.BanPackets, Name)) then
            return
        end

        if (Cheat.Library.flags.logNetwork) then
            local types = {}
            local str = ''

            for i, v in next, data do
                table.insert(types, typeof(v))
                str ..= `[{v}], `
            end

            if (not Cheat.Library.flags.sendIgnoreList[Name]) then
                print('==================================================================')
                print('NETWORK LOG FOR -- // '..Name..' // -- ', table.concat(types, ", "))
                print(str)
            end  
        end
        
        return oldSend(self, Name, table.unpack(data))
    end))

    local oldFetch; oldFetch = Cheat:hookAndTostringSpoof(Network, 'Fetch', LPH_JIT_MAX(function(self, Name, ...)
        local data = {...}

        if (Name == 'Vehicle Report Input') then
            if (Cheat.Library.flags.infiniteFuel) then
                return true
            end
        elseif (Name == 'Get Server Debug State') then
            local result = oldFetch(self, Name, table.unpack(data))
            if (result.UserPing >= 4) and (Cheat.Library.flags.acDisabler) and (not Cheat.acBypassed) then
                Cheat.acBypassed = true

                if (Cheat.Library.flags.acDisablerMode == 'Partial') then
                    Cheat:notifyInfo('You can now use high speedhack values', 5, true)
                end
            end

            local realPing = Cheat:getPing()
            if (result.UserPing - realPing) > 0.1 then
                result.UserPing = realPing
            end
            
            return result
        end
        
        if (Cheat.Library.flags.logFetch) then
            print('==================================================================')
            print('FETCH LOG FOR -- // '..Name..' // --')
            print(...)
        end

        return oldFetch(self, Name, table.unpack(data))
    end))

    -- // Receive Events:tm:
    Cheat.NetworkEvents['Bounce'] = LPH_NO_VIRTUALIZE(function(...)
        spoofPing()
        return oldSend(Network, ...)
    end)

    Cheat.NetworkEvents['Teleport Sequence'] = function()
        if (not playerClass.Character) then return end
        local vehicle = playerClass.Character.Vehicle

        Network:Send('Vehicle Dismount', vehicle)
    end

    -- // Network Add log
    if (not LPH_OBFUSCATED) then
        for i,v in next, Cheat.NetworkEventsRaw do
            if (i == 'Bounce') or (i == 'Character State Update') or (i == 'Inventory Sound Replication') or (i == 'User Statistics Update') or (i == 'Animator Action Run') or (i == 'Player Chatted') then
                continue
            end

            Cheat.NetworkEventsRaw[i] = function(...)
                if (Cheat.Library.flags.logNetAdd) then
                    print('==================================================================')
                    print(`-- // Network Add Log [{i}] // --`)
                    print(...)
                end

                return v(...)
            end
        end
    end
end
