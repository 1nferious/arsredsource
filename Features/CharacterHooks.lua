return function(Cheat)
    -- // Modules
    local ReplicationUtility = REQUIRE_MODULE('Modules/Libraries/ReplicationUtility.lua')
    local Hooks = REQUIRE_MODULE('Modules/Libraries/Hooks.lua')
    local Signal = REQUIRE_MODULE('Modules/Classes/FastSignal.lua')
    
    local Interface = Cheat.Framework.require('Libraries', 'Interface')
    local Characters = Cheat.Framework.require('Classes', 'Characters')
    local Cameras = Cheat.Framework.require('Libraries', 'Cameras')
    local Bullets = Cheat.Framework.require('Libraries', 'Bullets')
    local Network = Cheat.Framework.require('Libraries', 'Network')
    local Players = Cheat.Framework.require('Classes', 'Players')
    local Maids = Cheat.Framework.require('Classes', 'Maids')

    local Consumable = Cheat:requireFix(game:GetService('ReplicatedStorage').Client.Abstracts.ItemInitializers.Consumable)
    local Firearm = Cheat:requireFix(game:GetService('ReplicatedStorage').Client.Abstracts.ItemInitializers.Firearm)
    local CharacterAnimator = Cheat:requireFix(game:GetService('ReplicatedStorage').Client.Abstracts.Animators.Character)

    local CharacterCamera = Cameras:GetCamera('Character')
    local Reticle = Interface:Get('Reticle')

    local ContainerChangedSignal = Signal.new()

    -- // Functions
    local firemodeConnection = nil
    local recoilNames = {'KickUpSpeed', 'KickUpForce', 'KickUpBounce', 'KickUpGunInfluence', 'KickUpCameraInfluence', 'ShiftForce', 'RaiseForce'}
    local fireModes = {'Automatic', 'Semiautomatic', 'Burst'}

    local updateAmmoText = LPH_NO_VIRTUALIZE(function(firearm)
        local workingAmount = 0
        local magSize = 0

        if (firearm.Attachments and firearm.Attachments.Ammo) then
            workingAmount = firearm.Attachments.Ammo.WorkingAmount
            magSize = firearm.Attachments.Ammo.Capacity
        elseif (firearm.FireConfig and firearm.FireConfig.InternalMag) then
            workingAmount = firearm.WorkingAmount
            magSize = firearm.FireConfig.InternalMagSize
        end
        
        local weaponInterface = Interface:Get('Weapon')
        weaponInterface.Gui.Frame.Ammo.Text = string.format('%d/%d', workingAmount, magSize)
        weaponInterface.Gui.Frame.Ammo.Backdrop.Text = weaponInterface.Gui.Frame.Ammo.Text
    end)

    local isBlacklistedSignal = LPH_NO_VIRTUALIZE(function(characterClass, blacklistedSignals, signal)
        for _, signalName in next, blacklistedSignals do
            if (characterClass[signalName] ~= signal) then
                continue
            end

            return true
        end
    end)

    local animatedConsumeString = LPH_ENCSTR('animatedConsume')

    local function fakeMaid(blacklistedSignals, name, oldMaidNew)
        local maid = {}
        local realMaid = oldMaidNew() --Maids.new()

        function maid.Give(self, conn)
            if (name == animatedConsumeString and Cheat.Library.flags.autoConsume) or (Cheat.Library.flags.equipAnywhere and isBlacklistedSignal(Players.get().Character, blacklistedSignals, conn._signal)) then
                conn:Disconnect()

                return
            end

            return realMaid:Give(conn)
        end

        function maid.Destroy()
            return realMaid:Destroy()
        end

        return maid
    end

    local firearmString = LPH_ENCSTR('Firearm')
    local hookWeapon = LPH_NO_VIRTUALIZE(function(weapon)
        if (weapon.Type ~= firearmString) then return end
   
        setreadonly(weapon, false)

        -- // Firemode
        local oldFireModes = weapon.FireModes

        if (firemodeConnection) then
            firemodeConnection:Disconnect()
            firemodeConnection = nil
        end

        firemodeConnection = Cheat.AllFireModesChanged:Connect(function(state)
            if (state) then
                weapon.FireModes = fireModes
            else
                weapon.FireModes = oldFireModes
            end
        end)

        if (Cheat.Library.flags.allFireModes) then
            weapon.FireModes = fireModes
        end

        -- // Hooked Check
        if (weapon.__HOOKED) then return end

        local oldRecoilData = weapon.RecoilData

        -- // Recoil
        setreadonly(weapon.RecoilData, false)
        
        weapon.RecoilData = setmetatable({}, {__index = function(self, index)
            if (Cheat.Library.flags.weaponModsEnabled) and (Cheat.Library.flags.recoilMod) and (table.find(recoilNames, index)) then
                return (oldRecoilData[index] * (Cheat.Library.flags.recoilValue / 100))
            end
            
            return oldRecoilData[index]
        end})

        weapon.__HOOKED = true
    end)

    -- // Hooks
    local oldContainerChanged = Cheat.NetworkEvents['Container Changed']
    Cheat.NetworkEvents['Container Changed'] = LPH_NO_VIRTUALIZE(function(...)
        local results = {oldContainerChanged(...)}

        ContainerChangedSignal:Fire()

        return table.unpack(results)
    end)

    -- // Bullet Lag Fix
    local fireBullet = Hooks:findUpvalue(Firearm, 'fireBullet')
    Hooks:upvalueBypassHook(fireBullet, LPH_NO_VIRTUALIZE(function(firearm, characterClass, var)
        if ((firearm.FireConfig and firearm.FireConfig.InternalMag) and (firearm.WorkingAmount and (firearm.WorkingAmount >= 1))) then
            firearm.WorkingAmount -= 1
        else
            if ((firearm.Attachments and firearm.Attachments.Ammo) and (firearm.Attachments.Ammo.WorkingAmount >= 1)) then
                firearm.Attachments.Ammo.WorkingAmount -= 1
            else
                return false
            end
        end
        
        updateAmmoText(firearm)

        local origin, direction = Reticle:GetFirearmTargetInfo(characterClass, CharacterCamera, var)
        rawset(firearm, 'LastShot', Bullets:Fire(characterClass, CharacterCamera, firearm, origin, direction))
        return true
    end))

    local animateMuzzleFlash = Hooks:findUpvalue(CharacterAnimator, 'animateMuzzleFlash')
    local noMuzzleFlashString = LPH_ENCSTR('noMuzzleFlash')
    local weaponModsEnabledString = LPH_ENCSTR('weaponModsEnabled')
    local oldAnimateMuzzleFlash; oldAnimateMuzzleFlash = Hooks:upvalueBypassHook(animateMuzzleFlash, LPH_NO_VIRTUALIZE(function(...)
        if (Cheat.Library.flags[weaponModsEnabledString] and Cheat.Library.flags[noMuzzleFlashString]) then
            return
        end

        return oldAnimateMuzzleFlash(...)
    end))

    local moveStateString = LPH_ENCSTR('MoveState')
    local walkingString = LPH_ENCSTR('Walking')
    local climbingString = LPH_ENCSTR('Climbing')
    local mountingString = LPH_ENCSTR('Mounting')
    local dismountingString = LPH_ENCSTR('Dismounting')
    local sittingString = LPH_ENCSTR('Sitting')
    local isInCitadelArenaString = LPH_ENCSTR('IsInCitadelArena')

    local newEquipFakeCharacterClass = LPH_NO_VIRTUALIZE(function(self)
        local fakeCharacterClass = {}

        setrawmetatable(fakeCharacterClass, {
            __index = function(_, idx)
                if (idx == moveStateString) then
                    return walkingString
                elseif (idx == climbingString) then
                    return false
                elseif (idx == mountingString) then
                    return false
                elseif (idx == dismountingString) then
                    return false
                elseif (idx == sittingString) then
                    return false
                elseif (idx == isInCitadelArenaString) then
                    return false
                end

                return self[idx]
            end,

            __newindex = function(_, idx, val)
                self[idx] = val
            end
        })
        
        return fakeCharacterClass
    end)

    local oldEquip; oldEquip = Hooks:upvalueBypassHook(Characters.Equip, LPH_JIT_MAX(function(self, item, ...)
        local result = nil

        -- // Skin Changer
        if (Cheat.Library.flags.skinChanger) and (item.Type == firearmString) then
            item.SkinId = Cheat.Library.flags.currentSkin
        end
        
        -- // Weapon Hooks
        hookWeapon(item)

        -- // Equip Anywhere
        if (Cheat.Library.flags.equipAnywhere) then
            result = oldEquip(newEquipFakeCharacterClass(self), item, ...)
        else
            result = oldEquip(self, item, ...)
        end

        -- // Auto Consume
        if (Cheat.Library.flags.autoConsume) and (result) and (item) and (item.ConsumeConfig) and (item.Type == 'Consumable' or item.Type == 'Medical') then
            task.spawn(LPH_JIT_MAX(function()
                if (item.Type == 'Medical') and (not item.Name:match('Health Booster')) and (self.Health.Value >= 100) then
                    return
                end

                Network:Send('Register Consume', item.Id) 
                self.Animator:RunAction("Play Consume Animation", item.Name, 1)

                local track = self.Animator:GetTrack(item.ConsumeConfig.Animation)

                if (not track) then
                    repeat
                        task.wait()
                        track = self.Animator:GetTrack(item.ConsumeConfig.Animation)
                    until track
                end

                self.Animator:RunAction("Cancel Consume Animation", item.Name)
                
                task.wait(track.Length)

                Interface:Get("Hotbar"):FindReplacement(item)
                Network:Send('Inventory Use Item', item.Id)
                ContainerChangedSignal:Wait()
                self.EquipmentChanged:Fire("Unequipped")
                Interface:Get("Controls"):Refresh(self)
                Interface:Get("Weapon"):Refresh(self)
            end))
        end

        return result
    end))

    local characterLogicStepString = LPH_ENCSTR('characterLogicStep')
    local findLadderString = LPH_ENCSTR('findLadder')
    local hotbarString = LPH_ENCSTR('Hotbar')

    local oldUnequip; oldUnequip = Hooks:upvalueBypassHook(Characters.Unequip, LPH_NO_VIRTUALIZE(function(self, ...)
        if (Cheat.Library.flags.equipAnywhere) then
            local traceback = debug.traceback()

            if (not traceback:find(hotbarString, 1, true)) and (traceback:find(characterLogicStepString, 1, true) or traceback:find(animatedConsumeString, 1, true) or traceback:find(findLadderString, 1, true)) then
                return
            end
        end

        if (firemodeConnection) then
            firemodeConnection:Disconnect()
            firemodeConnection = nil
        end

        return oldUnequip(self, ...)
    end))

    local compassString = LPH_ENCSTR('Compass')
    local mapString = LPH_ENCSTR('Map')

    local oldHasPerk; oldHasPerk = Hooks:upvalueBypassHook(Characters.HasPerk, LPH_NO_VIRTUALIZE(function(self, Name, ...)
        local data = {oldHasPerk(self, Name, ...)}

        if (Cheat.Library.flags.alwaysMapCompass) and (Name == compassString or Name == mapString) then
            return true, data[2]
        end

        return table.unpack(data)
    end))

    local isItemUsable = Hooks:findUpvalue(Characters.EquipOverwriteUseSequence, 'isItemUsable')
    local oldIsItemUsable; oldIsItemUsable = Hooks:upvalueBypassHook(isItemUsable, LPH_NO_VIRTUALIZE(function(self, item)
        if (Cheat.Library.flags.equipAnywhere) then
            if (self.UsingItem) or (not item.OnUse) then
                return false
            end
        
            return true
        end
        
        return oldIsItemUsable(self, item)
    end))

    -- // Character Class Hooks
    -- // This code is pretty ass, ngl
    task.spawn(function()
        if (not Players.get()) then
            repeat
                task.wait()
            until Players.get()
        end

        local playerClass = Players.get()
        if (not playerClass.Character) then
            repeat
                task.wait()
            until playerClass.Character
        end

        local characterClass = playerClass.Character

        local hookGun = nil
        local setMoveVectorInput = Hooks:findUpvalue(characterClass.Actions.Aim, 'setMoveVectorInput')

        local newOnReloadFakeCharacterClass = LPH_NO_VIRTUALIZE(function(charClass)
            local fakeCharacterClass = {}

            setrawmetatable(fakeCharacterClass, {
                __index = function(_, key)
                    if (key == 'Sitting') then
                        return nil
                    else
                        return charClass[key]
                    end
                end,

                __newindex = function(_, key, value)
                    charClass[key] = value
                end
            })

            return fakeCharacterClass
        end)

        local hkOnReload = LPH_JIT_MAX(function(oldFunc, findReloadAmmo, gun, charClass, itemData, ...)
            if (Cheat.Library.flags.instantReload) then
                local AmmoSelection = findReloadAmmo(gun, charClass, itemData)
        
                if (AmmoSelection) then
                    Network:Send('Character Reload Firearm Initiated', gun.Id, AmmoSelection.Id)

                    if (gun.FireConfig.InternalMag) then
                        for i = 1, gun.FireConfig.InternalMagSize do
                            Network:Send('Character Reload Firearm Committed', gun.Id, AmmoSelection.Id)
                        end
                    else
                        Network:Send('Character Reload Firearm Committed', gun.Id, AmmoSelection.Id)
                    end

                    Network:Send('Character Reload Firearm Clear', gun.Id, AmmoSelection.Id)
                end
        
                return true
            elseif (Cheat.Library.flags.equipAnywhere) then
                return oldFunc(gun, newOnReloadFakeCharacterClass(charClass), itemData, ...)
            end
    
            return oldFunc(gun, charClass, itemData, ...)
        end)

        local isReloadPlayingString = LPH_ENCSTR('IsReloadPlaying')
        local animatorString = LPH_ENCSTR('Animator')

        local hkOnUse = LPH_NO_VIRTUALIZE(function(oldFunc, self, charClass, ...)
            if (Cheat.Library.flags.equipAnywhere) then
                -- // Fake Animator Class
                local fakeAnimatorClass = {}

                setrawmetatable(fakeAnimatorClass, {
                    __index = function(_, key)
                        if (key == isReloadPlayingString) then
                            return function(...)
                                return false
                            end
                        end

                        return charClass.Animator[key]
                    end,

                    __newindex = function(_, key, value)
                        charClass.Animator[key] = value
                    end
                })

                -- // Fake Character Class
                local fakeCharacterClass = {}

                setrawmetatable(fakeCharacterClass, {
                    __index = function(_, idx)
                        if (idx == animatorString) then
                            return fakeAnimatorClass
                        end

                        return charClass[idx]
                    end,
                    __newindex = function(_, idx, val)
                        charClass[idx] = val
                    end
                })

                return oldFunc(self, fakeCharacterClass, ...)
            end

            return oldFunc(self, charClass, ...)
        end)

        local function hookCharacter(newCharacterClass)
            characterClass = newCharacterClass

            if (hookGun) then
                hookGun:Disconnect()
                hookGun = nil
            end

            local findReloadAmmoString = LPH_ENCSTR('findReloadAmmo')

            hookGun = characterClass.EquipmentChanged:Connect(LPH_NO_VIRTUALIZE(function(event, equippedItem)
                if (event ~= "Equipped") then
                    return
                end

                if (equippedItem.Type ~= firearmString) then
                    return
                end

                local oldOnReload = equippedItem.OnReload
                local oldOnUse = equippedItem.OnUse

                if (oldOnReload) then
                    local findReloadAmmo = Hooks:findUpvalue(oldOnReload, findReloadAmmoString)

                    -- cant do upvalueBypassHook since krampus bug causes crash
                    oldOnReload = Cheat:hookAndTostringSpoof(equippedItem, 'OnReload', function(...)
                        return hkOnReload(oldOnReload, findReloadAmmo, ...)
                    end)
                end

                if (oldOnUse) then
                    oldOnUse = Cheat:hookAndTostringSpoof(equippedItem, 'OnUse', function(...)
                        return hkOnUse(oldOnUse, ...)
                    end)
                end

                -- if (oldOnUse) and (not isfunctionhooked(oldOnUse)) then
                --     oldOnUse = Hooks:upvalueBypassHook(oldOnUse, function(...)
                --         return hkOnUse(oldOnUse, ...)
                --     end)
                -- end
            end))
            
            local oldRawStepFunction = characterClass.Animator.RawStepFunction
            characterClass.Animator.RawStepFunction = LPH_NO_VIRTUALIZE(function(...)
                if (Cheat.Library.flags.speed or Cheat.Library.flags.fly or Cheat.Library.flags.noFootstepSounds or Cheat.Library.flags.noSprintPenalty) then
                    ReplicationUtility.rootPart.AssemblyLinearVelocity = Cheat.RealVelocity
                end
                
                return oldRawStepFunction(...)
            end)

            -- // Apply Fake Outfit
            Cheat.SkinColor = characterClass.Instance.Head.Color

            if (Cheat.Library.flags.fakeOutfit) then
                Cheat.Library.options.fakeOutfit.callback(true)
            end
        end

        hookCharacter(characterClass)

        -- // Connections
        playerClass.CharacterAdded:Connect(function(characterClass)
            hookCharacter(characterClass)
        end)

        -- // Hooks
        local fallImpactString = LPH_ENCSTR('Fall Impact')

        local oldRunAnimation; oldRunAnimation = Hooks:upvalueBypassHook(characterClass.Animator.RunAction, LPH_NO_VIRTUALIZE(function(self, Name, ...)
            if (Cheat.Library.flags.antiDebuff) and (Name == fallImpactString) then
                return
            end

            return oldRunAnimation(self, Name, ...)
        end))

        local vaultingString = LPH_ENCSTR('Vaulting')

        local oldSetShoulderSwap; oldSetShoulderSwap = Hooks:upvalueBypassHook(characterClass.Actions.ShoulderSwap, LPH_NO_VIRTUALIZE(function(self, ...)
            if (Cheat.Library.flags.equipAnywhere) then
                local fakeCharacterClass = {}

                setrawmetatable(fakeCharacterClass, {
                    __index = function(_, idx)
                        if (idx == moveStateString) then
                            return walkingString
                        elseif (idx == climbingString) then
                            return false
                        elseif (idx == vaultingString) then
                            return false
                        end
            
                        return self[idx]
                    end,

                    __newindex = function(_, idx, val)
                        self[idx] = val
                    end
                })
            
                return oldSetShoulderSwap(fakeCharacterClass, ...)
            end
        
            return oldSetShoulderSwap(self, ...)
        end))

        local runningInputString = LPH_ENCSTR('RunningInput')

        local oldAim; oldAim = Hooks:upvalueBypassHook(characterClass.Actions.Aim, LPH_NO_VIRTUALIZE(function(self, ...)
            if (Cheat.Library.flags.equipAnywhere) then
                local fakeCharacterClass = {}

                setrawmetatable(fakeCharacterClass, {
                    __index = function(_, idx)
                        if (idx == moveStateString) then
                            return walkingString
                        end
            
                        return self[idx]
                    end,

                    __newindex = function(_, idx, val)
                        if (idx == runningInputString) then
                            return
                        end
                        
                        self[idx] = val
                    end
                })
            
                return oldAim(fakeCharacterClass, ...)
            end

            return oldAim(self, ...)
        end))

        local oldAtEase; oldAtEase = Hooks:upvalueBypassHook(characterClass.Actions.AtEase, LPH_NO_VIRTUALIZE(function(self, ...)
            if (Cheat.Library.flags.equipAnywhere) then
                local fakeCharacterClass = {}

                setrawmetatable(fakeCharacterClass, {
                    __index = function(_, idx)
                        if (idx == moveStateString) then
                            return walkingString
                        end
            
                        return self[idx]
                    end,

                    __newindex = function(_, idx, val)
                        self[idx] = val
                    end
                })
            
                return oldAtEase(fakeCharacterClass, ...)
            end

            return oldAtEase(self, ...)
        end))

        local aimingInputString = LPH_ENCSTR('AimingInput')

        local oldReload; oldReload = Hooks:upvalueBypassHook(characterClass.Actions.Reload, LPH_NO_VIRTUALIZE(function(self, ...)
            if (Cheat.Library.flags.equipAnywhere) then
                local fakeCharacterClass = {}

                setrawmetatable(fakeCharacterClass, {
                    __index = function(_, idx)
                        return self[idx]
                    end,

                    __newindex = function(_, idx, val)
                        if (idx == aimingInputString) then
                            return
                        end
            
                        self[idx] = val
                    end
                })
            
                return oldReload(fakeCharacterClass, ...)
            end
            
            return oldReload(self, ...)
        end))

        local oldUseItem; oldUseItem = Hooks:upvalueBypassHook(characterClass.Actions.UseItem, LPH_NO_VIRTUALIZE(function(self, ...)
            if (Cheat.Library.flags.equipAnywhere) then
                local fakeCharacterClass = {}

                setrawmetatable(fakeCharacterClass, {
                    __index = function(_, idx)
                        return self[idx]
                    end,

                    __newindex = function(_, idx, val)
                        if (idx == RunningInput) then
                            return
                        end
            
                        self[idx] = val
                    end
                })
            
                return oldUseItem(fakeCharacterClass, ...)
            end

            return oldUseItem(self, ...)
        end))
        
        local animatedConsume = Hooks:findUpvalue(Consumable, 'animatedConsume')
        local animatedReload = Hooks:findUpvalue(Firearm, 'animatedReload')

        local fallingString = LPH_ENCSTR('Falling')
        local moveStateChangedString = LPH_ENCSTR('MoveStateChanged')
        local aimInputChangedString = LPH_ENCSTR('AimInputChanged')
        local sprintInputChangedString = LPH_ENCSTR('SprintInputChanged')
        
        local oldNewMaid; oldNewMaid = Cheat:hookAndTostringSpoof(Maids, 'new', LPH_NO_VIRTUALIZE(function(...)
            local func = debug.getinfo(2).func
            
            if (func == animatedReload) then
                return fakeMaid({moveStateChangedString, fallingString, aimInputChangedString, sprintInputChangedString}, animatedReloadString, oldNewMaid)
            elseif (func == animatedConsume) then
                return fakeMaid({moveStateChangedString, fallingString}, animatedConsumeString, oldNewMaid)
            end
            
            return oldNewMaid(...)
        end))

        local bindSignals = Hooks:findUpvalue(Characters.new, 'bindSignals')
        local characterLogicStep = Hooks:findUpvalue(bindSignals, 'characterLogicStep')
        local atEaseInputString = LPH_ENCSTR('AtEaseInput')
        local zoomingString = LPH_ENCSTR('Zooming')

        local oldCharacterLogicStep; oldCharacterLogicStep = Hooks:upvalueBypassHook(characterLogicStep, LPH_NO_VIRTUALIZE(function(self, ...)
            if (Cheat.Library.flags.equipAnywhere) then
                debug.profilebegin('ARS Logic Step Hook')

                local fakeCharacterClass = {}

                setrawmetatable(fakeCharacterClass, {
                    __index = function(_, idx)
                        return self[idx]
                    end,

                    __newindex = function(_, idx, val)
                        if (idx == atEaseInputString) then
                            return
                        elseif (idx == zoomingString) then
                            return
                        end
            
                        self[idx] = val
                    end
                })
            
                local oldZooming = self.Zooming
                local equippedItem = self.EquippedItem

                if (equippedItem) then
                    local hasAimFOV = false
            
                    if (equippedItem.AimFieldOfView) then
                        hasAimFOV = true
                    end
            
                    if (hasAimFOV and self.AimingInput) then
                        self.Zooming = true
                    else
                        self.Zooming = false
                    end
                else
                    self.Zooming = false
                end
            
                if (self.Zooming ~= oldZooming) then
                    self.AimInputChanged:Fire(self.Zooming)
                end

                debug.profileend()
            
                return oldCharacterLogicStep(fakeCharacterClass, ...)
            end

            return oldCharacterLogicStep(self, ...)
        end))

        local canCharacterShoot = Hooks:findUpvalue(Firearm, 'canCharacterShoot')
        local isAnimationPlayingString = LPH_ENCSTR('IsAnimationPlaying')
        local isEquipFadingString = LPH_ENCSTR('IsEquipFading')
        local reloadingString = LPH_ENCSTR('Reloading')

        local oldCanCharacterShoot; oldCanCharacterShoot = Hooks:upvalueBypassHook(canCharacterShoot, LPH_NO_VIRTUALIZE(function(charClass, gun, gunModel, p26, ...)
            -- Hutch forgot this lmao
            if (not gunModel) then
                return false
            end

            if (Cheat.Library.flags.equipAnywhere) then
                -- this is better since most checks in canCharacterShoot is for avoiding errors either way and we want to still keep them

                -- // Fake Animator Class
                local fakeAnimatorClass = {}

                setrawmetatable(fakeAnimatorClass, {
                    __index = function(_, key)
                        if (key == isAnimationPlayingString) then
                            return function(...)
                                return false
                            end
                        elseif (key == isEquipFadingString) then
                            return function(...)
                                return false
                            end
                        end

                        return charClass.Animator[key]
                    end,

                    __newindex = function(_, key, value)
                        charClass.Animator[key] = value
                    end
                })

                -- // Fake Character Class
                local fakeCharacterClass = {}

                setrawmetatable(fakeCharacterClass, {
                    __index = function(_, idx)
                        if (idx == animatorString) then
                            return fakeAnimatorClass
                        elseif (idx == reloadingString) then
                            return false
                        end

                        return charClass[idx]
                    end,

                    __newindex = function(_, idx, val)
                        charClass[idx] = val
                    end
                })

                return oldCanCharacterShoot(fakeCharacterClass, gun, gunModel, p26, ...)
            end

            return oldCanCharacterShoot(charClass, gun, gunModel, p26, ...)
        end))
    end)
end
