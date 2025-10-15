return function(Cheat)
    -- // Modules
    local Math = REQUIRE_MODULE('Modules/Libraries/Math.lua')
    local Targeting = REQUIRE_MODULE('Modules/Libraries/Targeting.lua')
    local Hooks = REQUIRE_MODULE('Modules/Libraries/Hooks.lua')
    local Effects = REQUIRE_MODULE('Modules/Misc/Effects.lua')
    local ReplicationUtility = REQUIRE_MODULE('Modules/Libraries/ReplicationUtility.lua')
    local Prediction = REQUIRE_MODULE('Modules/Libraries/Prediction.lua')

    local Bullets = Cheat.Framework.require('Libraries', 'Bullets')
    local Network = Cheat.Framework.require('Libraries', 'Network')
    local AR2Raycasting = Cheat.Framework.require('Libraries', 'Raycasting')
    local Globals = Cheat.Framework.require('Configs', 'Globals')
    local World = Cheat.Framework.require('Libraries', 'World')
    local AR2Players = Cheat.Framework.require('Classes', 'Players')
    local Cameras = Cheat.Framework.require('Libraries', 'Cameras')
    local AR2UserSettings = Cheat.Framework.require('Libraries', 'UserSettings')
    local Keybinds = Cheat.Framework.require('Configs', 'Keybinds')

    local Players = game:GetService('Players')
    Targeting.Raycasting = AR2Raycasting

    local CharacterCamera = Cameras:GetCamera('Character')

    -- // Functions    
    local mouseMoveRad = LPH_NO_VIRTUALIZE(function(x, y)
        if (not Cheat.PlayerClass) or (not Cheat.PlayerClass.Character) then
            return
        end
        
        local multiplier = 1
        local zoomMultiplier = 1
        if (Cheat.PlayerClass.Character.Zooming) then
            multiplier = (Keybinds:GetBind('Aim Down Sights')['First Person Aim Speed'].Value / 100)
            zoomMultiplier = math.clamp(math.tan(math.rad(CharacterCamera.Instance.FieldOfView)) / 2.7474774194546216, 0.2, 1)
        end

        local sensitivity = UserSettings().GameSettings.MouseSensitivity
        local rad = math.rad(0.2) -- // One pixel of mouse movement = 0.2 degrees of rotation
        local frac = (Vector2.new(x / rad, y / rad) / zoomMultiplier) / multiplier
        return mousemoverel(-frac.X / sensitivity, -frac.Y / sensitivity)
    end)

    -- // Create Drawing Objects
    local targetText = Drawing.new('Text')
    targetText.Visible = false
    targetText.Size = 13
    targetText.Outline = true
    targetText.Color = Color3.new(1, 1, 1)
    targetText.Center = true
    targetText.Font = Drawing.Fonts.Plex
    table.insert(Cheat.TextObjects, targetText)

    Cheat.SilentFOV = Drawing.new('Circle')
    Cheat.SilentOutline = Drawing.new('Circle')

    Cheat.SilentFOV.Visible = false
    Cheat.SilentFOV.ZIndex = 2
    Cheat.SilentFOV.NumSides = 16
    Cheat.SilentFOV.Thickness = 1
    Cheat.SilentOutline.Visible = false
    Cheat.SilentOutline.Thickness = (Cheat.SilentFOV.Thickness + 2)
    Cheat.SilentOutline.ZIndex = 1
    Cheat.SilentOutline.NumSides = 16

    Cheat.AimbotFOV = Drawing.new('Circle')
    Cheat.AimbotOutline = Drawing.new('Circle')

    Cheat.AimbotFOV.Visible = false
    Cheat.AimbotFOV.ZIndex = 2
    Cheat.AimbotFOV.NumSides = 16
    Cheat.AimbotFOV.Thickness = 1
    Cheat.AimbotOutline.Visible = false
    Cheat.AimbotOutline.Thickness = (Cheat.AimbotFOV.Thickness + 2)
    Cheat.AimbotOutline.ZIndex = 1
    Cheat.AimbotOutline.NumSides = 16

    Cheat.TriggerbotFOV = Drawing.new('Circle')
    Cheat.TriggerbotOutline = Drawing.new('Circle')

    Cheat.TriggerbotFOV.Visible = false
    Cheat.TriggerbotFOV.ZIndex = 2
    Cheat.TriggerbotFOV.NumSides = 16
    Cheat.TriggerbotFOV.Thickness = 1
    Cheat.TriggerbotOutline.Visible = false
    Cheat.TriggerbotOutline.Thickness = (Cheat.TriggerbotFOV.Thickness + 2)
    Cheat.TriggerbotOutline.ZIndex = 1
    Cheat.TriggerbotOutline.NumSides = 16

    Cheat.AimPoint = Drawing.new('Circle')
    Cheat.AimPoint.Visible = false
    Cheat.AimPoint.ZIndex = 2
    Cheat.AimPoint.NumSides = 16
    Cheat.AimPoint.Radius = 8

    -- // Library Stuff
    do
        local LeftSide = Cheat.Library.AimbotTab:AddColumn()
        local RightSide = Cheat.Library.AimbotTab:AddColumn()
    
        -- // Silent Aim
        local SilentAimSection = LeftSide:AddSection('Silent Aim')
        local silentAimTargetParts = table.clone(Targeting.R15TargetParts)

        table.insert(silentAimTargetParts, 'Random')

        SilentAimSection:AddToggle({ text = 'Enabled', flag = 'silentAimEnabled' }):AddBind({ flag = 'silentAimBind', callback = function(state) Cheat.Library.options.silentAimEnabled:SetState(state) end })
        SilentAimSection:AddToggle({ text = 'Visible Check', flag = 'silentVisibleCheck' })
        SilentAimSection:AddList({ text = 'Target Part', flag = 'silentTargetPart', values = silentAimTargetParts })
        SilentAimSection:AddSlider({ text = 'Hit Chance', flag = 'silentHitChance', value = 100, min = 1, max = 100 })
        SilentAimSection:AddToggle({ text = 'Dynamic FOV', flag = 'silentDynamicFOV', tip = 'FOV will change size based off the camera\'s zoom' })

        SilentAimSection:AddToggle({ text = 'Show FOV', flag = 'silentShowFOV', value = true })
            :AddSlider({ text = 'Field Of View', flag = 'silentFOV', value = 120, min = 1, max = 1000, callback = function(state) Cheat.SilentFOV.Radius = state; Cheat.SilentOutline.Radius = state end })
            :AddColor({ flag = 'silentFOVColor', color = Color3.new(1, 1, 1), trans = 1, callback = function(state)
                Cheat.SilentFOV.Color = state
                Cheat.SilentFOV.Transparency = (1 - Cheat.Library.flags['silentFOVColor Transparency'])
                Cheat.SilentOutline.Transparency = Cheat.SilentFOV.Transparency
            end })
        
        SilentAimSection:AddToggle({ text = 'Distance Check', flag = 'silentDistanceCheck' })
            :AddSlider({ text = 'Maximum Distance', flag = 'silentMaximumDistance', value = 2050, min = 50, max = 2050 })
        
        SilentAimSection:AddToggle({ text = 'Magic Bullet', flag = 'silentMagicBullet', tip = 'Manipulates bullet behavior to try and wallbang' })

        -- // Aimbot
        local AimbotSection = RightSide:AddSection('Aimbot')
    
        AimbotSection:AddToggle({ text = 'Enabled', flag = 'aimbotEnabled' }):AddBind({ text = 'aimbot', flag = 'aimbotBind', mode = 'hold', key = 'MouseButton2' })
        AimbotSection:AddToggle({ text = 'Visible Check', flag = 'aimbotVisibleCheck' })
        AimbotSection:AddSlider({ text = 'Smoothing', flag = 'aimbotSmoothing', value = 1, min = 1, max = 10 })
        AimbotSection:AddList({ text = 'Target Part', flag = 'aimbotTargetPart', values = Targeting.R15TargetParts })
        AimbotSection:AddToggle({ text = 'Dynamic FOV', flag = 'aimbotDynamicFOV', tip = 'FOV will change size based off the camera\'s zoom' })

        AimbotSection:AddToggle({ text = 'Show FOV', flag = 'aimbotShowFOV', value = true })
            :AddSlider({ text = 'Field Of View', flag = 'aimbotFOV', value = 120, min = 1, max = 1000, callback = function(state) Cheat.AimbotFOV.Radius = state; Cheat.AimbotOutline.Radius = state end })
            :AddColor({ flag = 'aimbotFOVColor', color = Color3.new(1, 1, 1), trans = 1, callback = function(state)
                Cheat.AimbotFOV.Color = state
                Cheat.AimbotFOV.Transparency = (1 - Cheat.Library.flags['aimbotFOVColor Transparency'])
                Cheat.AimbotOutline.Transparency = Cheat.AimbotFOV.Transparency
            end })
        
        AimbotSection:AddToggle({ text = 'Distance Check', flag = 'aimbotDistanceCheck' })
            :AddSlider({ text = 'Maximum Distance', flag = 'aimbotMaximumDistance', value = 2050, min = 50, max = 2050 })

        AimbotSection:AddToggle({ text = 'Draw Target Name', flag = 'drawTargetName', callback = function(state) -- // TODO: (when im not tired) update targetText on renderstepped
            if (not state) then
                targetText.Visible = false
            end
        end }):AddColor({ color = Color3.new(1, 1, 1), trans = 1, flag = 'aimbotDrawTargetColor', callback = function(state)
            targetText.Color = state
            targetText.Transparency = (1 - Cheat.Library.flags['aimbotDrawTargetColor Transparency'])
        end })

        -- // Trigger Bot
        local TriggerbotSection = LeftSide:AddSection('Triggerbot')

        TriggerbotSection:AddToggle({ text = 'Enabled', flag = 'triggerbotEnabled' }):AddBind({ flag = 'triggerbotBind', callback = function(state) Cheat.Library.options.triggerbotEnabled:SetState(state) end })
        TriggerbotSection:AddSlider({ text = 'Field Of View', flag = 'triggerbotFOV', value = 120, min = 1, max = 1000, callback = function(state) Cheat.TriggerbotFOV.Radius = state; Cheat.TriggerbotOutline.Radius = state end })
            
        TriggerbotSection:AddToggle({ text = 'Show FOV', flag = 'showTriggerbotFOV', value = true })
            :AddColor({ flag = 'triggerbotFOVColor', color = Color3.new(1, 1, 1), trans = 1, callback = function(state)
                Cheat.TriggerbotFOV.Color = state
                Cheat.TriggerbotFOV.Transparency = (1 - Cheat.Library.flags['triggerbotFOVColor Transparency'])
                Cheat.TriggerbotOutline.Transparency = Cheat.TriggerbotFOV.Transparency
            end })
        
        TriggerbotSection:AddToggle({ text = 'Distance Check', flag = 'triggerbotDistanceCheck' })
            :AddSlider({ text = 'Maximum Distance', flag = 'triggerbotMaximumDistance', value = 2050, min = 50, max = 2050 })

        -- // Prediction
        local PredictionSection = RightSide:AddSection('Prediction')

        PredictionSection:AddToggle({ text = 'Enabled', flag = 'predictionEnabled', tip = 'Don\'t use if you have Instant Bullets enabled', callback = function(state) Prediction:setEnabled(state) end })
        PredictionSection:AddList({ text = 'Velocity Calculation', flag = 'velocityCalculation', tip = 'Use Manual if they are spoofing their velocity', values = {'Normal', 'Manual'} })

        PredictionSection:AddToggle({ text = 'Aim Point', flag = 'aimPointEnabled', tip = 'Draws a circle at where you should aim to hit the player you are aiming at', callback = function(state)
            if (not state) then
                Cheat.AimPoint.Visible = false
            end
        end }):AddColor({ flag = 'aimPointColor', color = Color3.new(1, 1, 1), trans = 1, callback = function(state)
            Cheat.AimPoint.Color = state
            Cheat.AimPoint.Transparency = (1 - Cheat.Library.flags['aimPointColor Transparency'])
        end })

        -- // Recoil Control
        local RecoilSection = RightSide:AddSection('Legit Recoil Control')

        RecoilSection:AddToggle({ text = 'Enabled', flag = 'recoilControlEnabled', tip = 'Compensates camera recoil with mouse movements' }):AddBind({ flag = 'recoilControlBind', callback = function(state) Cheat.Library.options.recoilControlEnabled:SetState(state) end })
        RecoilSection:AddSlider({ text = 'Compensation', flag = 'recoilControlAmount', value = 100, min = 0, max = 100, suffix = '%' })
        RecoilSection:AddSlider({ text = 'Smoothing', flag = 'recoilControlSmoothing', value = 1, min = 1, max = 10 })
    end

    -- // Hooks
    local bulletFireUpvalues = Hooks:findUpvalues(Bullets.Fire, {
        'getSpredAngle',
        'getSpreadVector',
        'castLocalBullet',
        'playShootSound',
        'getFireImpulse'
    })

    local getSpreadAngle = bulletFireUpvalues.getSpredAngle
    local getSpreadVector = bulletFireUpvalues.getSpreadVector
    local castLocalBullet = bulletFireUpvalues.castLocalBullet
    local playShootSound = bulletFireUpvalues.playShootSound
    local getFireImpulse = bulletFireUpvalues.getFireImpulse

    local castLocalBulletUpvalues = Hooks:findUpvalues(castLocalBullet, {
        'impactEffects',
        'tryRicochet'
    })

    local impactEffects = castLocalBulletUpvalues.impactEffects
    local tryRicochet = castLocalBulletUpvalues.tryRicochet

    local characterString = LPH_ENCSTR('Character')
    local zombieString = LPH_ENCSTR('Zombie')
    local vehicleString = LPH_ENCSTR('Vehicle')
    local interactableString = LPH_ENCSTR('Interactable')
    local worldString = LPH_ENCSTR('World')

    local isNetworkableHit = LPH_NO_VIRTUALIZE(function(hitPart)
        if AR2Raycasting:IsHitCharacter(hitPart) then
            return true, characterString
        end
    
        if AR2Raycasting:IsHitZombie(hitPart) then
            return true, zombieString
        end
    
        if AR2Raycasting:IsHitVehicle(hitPart) then
            return true, vehicleString
        end
    
        if World:GetInteractable(hitPart) then 
            return true, interactableString
        end
    
        return false, worldString
    end)

    local getScreenPosition = LPH_NO_VIRTUALIZE(function(worldPosition)
        local screenPosition, onScreen = workspace.CurrentCamera:WorldToViewportPoint(worldPosition)
        return Vector2.new(screenPosition.X, screenPosition.Y), onScreen, (screenPosition.Z < 0)
    end)

    do -- // getSpreadAngle hook
        local fakeInvisString = LPH_ENCSTR('fakeInvis')
        local lastStateString = LPH_ENCSTR('LastState')
        local moveStateString = LPH_ENCSTR('MoveState')

        local oldGetSpreadAngle = getSpreadAngle; getSpreadAngle = LPH_NO_VIRTUALIZE(function(characterClass, ...) -- // so we dont flag the fly spread thing
            local networkedState = Cheat[lastStateString]
            local moveState = characterClass[moveStateString]

            if (moveState ~= networkedState) then
                characterClass[moveStateString] = networkedState
                local result = oldGetSpreadAngle(characterClass, ...)
                characterClass[moveStateString] = moveState

                return result
            end
        
            return oldGetSpreadAngle(characterClass, ...)
        end)
    end

    local oldFire; oldFire = Cheat:hookAndTostringSpoof(Bullets, 'Fire', LPH_JIT_MAX(function(self, characterData, camera, gun, origin, direction)
        if (not Cheat.ShotId) then
            Cheat.ShotId = debug.getupvalue(oldFire, 2)
        end
    
        Cheat.ShotId = (Cheat.ShotId + 1) % 69420
    
        local bulletCount = (Cheat.ShotId)

        if (Cheat.Library.flags.silentAimEnabled) and (Math:randomChance(Cheat.Library.flags.silentHitChance)) then
            local target = Targeting:GetAimbotTarget(
                Cheat.SilentFOV.Position,
                Cheat.SilentFOV.Radius,
                (Cheat.Library.flags.silentDistanceCheck and Cheat.Library.flags.silentMaximumDistance),
                Cheat.Library.flags.silentTargetPart,
                Cheat.Library.flags.silentVisibleCheck
            )
    
            if (Cheat.Library.flags.silentMagicBullet) and (not Cheat.Library.flags.fakeInvis) and (target) then
                origin = Targeting:FindFirePosition(origin, target)
            end
    
            if (target) then
                local targetPosition = target.Position

                if (Cheat.Library.flags.predictionEnabled) then
                    local playerObject = Players:GetPlayerFromCharacter(target.Parent)
                    local velocity = (Cheat.Library.flags.velocityCalculation == 'Normal' and target.Parent.PrimaryPart.AssemblyLinearVelocity) or Prediction:getVelocity(playerObject)
                    local predictionDelta = Math:ar2Predict(ReplicationUtility.rootPart.Position, targetPosition, velocity, gun.FireConfig.MuzzleVelocity)
                
                    targetPosition += predictionDelta
                end

                direction = ((targetPosition + Math:ar2BulletDrop(origin, targetPosition, gun.FireConfig.MuzzleVelocity, Globals.ProjectileGravity)) - origin).Unit
            end
        end
    
        local seed = workspace:GetServerTimeNow()
        local random = Random.new(seed * 10000)
        local suppressed = (gun.SuppressedByDefault)
    
        if (gun.Attachments) then
            for i,v in next, gun.Attachments do
                if (not v.SuppressesFirearm) then
                    continue
                end
    
                suppressed = true
                
                break
            end
        end

        local spreadAngle = getSpreadAngle(characterData, camera, gun)
        local spreadVector = getSpreadVector(random, direction, spreadAngle)
        local pelletCount = math.max(gun.FireConfig.PelletCount, 1)
    
        if (Cheat.Library.flags.weaponModsEnabled) and (Cheat.Library.flags.spreadMod) and (pelletCount == 1) then
            local multiplier = ((100 - Cheat.Library.flags.spreadValue) / 100) -- // invert this because the thing we are multiplying is the delta to no spread

            direction += (direction - spreadVector) * multiplier
            spreadVector = getSpreadVector(Random.new(seed * 10000), direction, spreadAngle)
        end
    
        if (pelletCount > 1) then
            random = Random.new(seed * 10000)
        end
    
        -- // Lagger thing #1
        if (not LPH_OBFUSCATED) then
            if (Cheat.Library.flags.stopInspectingTheFuckingConfig2) then
                direction = Vector3.zero
            end
        end

        for i = 1, pelletCount do
            coroutine.wrap(castLocalBullet)(bulletCount, seed, i, characterData, gun, origin, (pelletCount > 1 and getSpreadVector(random, direction, spreadAngle) or spreadVector), suppressed)
        end

        Network:Send('Bullet Fired', bulletCount, seed, gun.Id, origin, direction)
        playShootSound(gun.Name, origin, suppressed, true)
        characterData.Animator:RunAction('FireImpulse', getFireImpulse(characterData.Animator, gun))

        -- // Auto Reload
        if (Cheat.Library.flags.weaponModsEnabled and Cheat.Library.flags.autoReload) then
            if (gun.FireConfig.InternalMag and gun.WorkingAmount) and (gun.WorkingAmount < 1) then
                gun:OnReload(characterData)
            elseif (gun.Attachments and gun.Attachments.Ammo) and (gun.Attachments.Ammo.WorkingAmount < 1) then
                gun:OnReload(characterData)
            end
        end
    
        return seed
    end))

    local oldCastLocalBullet; oldCastLocalBullet = Hooks:upvalueBypassHook(castLocalBullet, LPH_JIT_MAX(function(bulletId, p65, p66, characterClass, weapon, origin, direction, p71, ...)
        -- // Lagger thing #2
        if (not LPH_OBFUSCATED) then
            if (Cheat.Library.flags.stopInspectingTheFuckingConfig2) then
                return
            end
        end
        
        if (not Cheat.Library.flags.weaponModsEnabled) or (not Cheat.Library.flags.instantBullets) then
            return oldCastLocalBullet(bulletId, p65, p66, characterClass, weapon, origin, direction, p71, ...)
        end

        debug.profilebegin('ARS Instant Bullets')
    
        local ignoreList = {
            characterClass.Instance,
            workspace.Sounds,
            workspace.Effects,
        }
    
        local stepSize = (direction * weapon.FireConfig.MuzzleVelocity) * Globals.MuzzleVelocityMod
        local currentOrigin = origin
    
        local distanceTraveled = 0
        local fakeDelta = 0
    
        while true do
            fakeDelta += (1 / 60)
    
            local bulletRay = Ray.new(currentOrigin, ((origin + (stepSize * fakeDelta)) + (Vector3.new(0, Globals.ProjectileGravity, 0) * (fakeDelta ^ 2))) - currentOrigin)
            local rayResult, rayHitPosition, rayNormal = AR2Raycasting:BulletCast(bulletRay, true, ignoreList, false, true)
    
            distanceTraveled += (currentOrigin - rayHitPosition).Magnitude
            currentOrigin = rayHitPosition
    
            if (rayResult) then
                impactEffects(weapon, rayResult, rayHitPosition, rayNormal, origin, direction, true)
                task.spawn(tryRicochet, weapon.Name, direction, rayResult, rayHitPosition, rayNormal)
    
                if isNetworkableHit(rayResult) then
                    task.delay(fakeDelta, LPH_JIT_MAX(function()
                        Network:Send('Bullet Impact', bulletId, weapon.Id, p65, p66, rayResult, rayHitPosition, {
                            rayResult.CFrame:PointToObjectSpace(bulletRay.Origin),
                            rayResult.CFrame:VectorToObjectSpace(bulletRay.Direction),
                            rayResult.CFrame:PointToObjectSpace(rayHitPosition),
                        })
                    end))
                end
    
                break
            end
    
            if (distanceTraveled > Globals.ShotMaxDistance) then
                break
            end
        end

        debug.profileend()
    end))

    local oldBulletCast; oldBulletCast = Cheat:hookAndTostringSpoof(AR2Raycasting, 'BulletCast', LPH_NO_VIRTUALIZE(function(self, ray, whatIsThis, ignoreList, isVisibleCheck, isCastLocalBullet)
        debug.profilebegin('ARS BulletCast Hook')
        
        local rayResult, rayHitPosition, rayNormal = oldBulletCast(self, ray, whatIsThis, ignoreList)

        -- // Semi-Wallbang
        if (rayResult and Cheat.Library.flags.silentMagicBullet) and (isCastLocalBullet or debug.traceback():match('castLocalBullet')) and (not table.find(Targeting.R15TargetParts, rayResult.Name)) then
            -- // Convert to a regular table, not a dictionary
            local whitelist = {}
            for i,v in next, ReplicationUtility:GetCharacters() do
                table.insert(whitelist, v)
            end

            local rayResult2 = AR2Raycasting:CastWithWhiteList(Ray.new(rayHitPosition, ray.Direction.Unit * 25), whitelist)
            if (rayResult2) then
                if (Cheat.Library.flags.silentTargetPart ~= 'Random') then
                    rayResult = (rayResult2.Parent:FindFirstChild(Cheat.Library.flags.silentTargetPart) or rayResult2)
                else
                    rayResult = rayResult2
                end
            end
        end

        -- // Tracers
        if (Cheat.Library.flags.bulletTracers) and (not isVisibleCheck) then
            task.spawn(Effects.bulletTracer, Effects, ray.Origin, rayHitPosition, Cheat.Library.flags['bulletTracerColor Transparency'], Cheat.Library.flags.bulletTracerColor, Cheat.Library.flags.bulletTracerTime)
        end

        debug.profileend()
        return rayResult, rayHitPosition, rayNormal
    end))

    -- // Recoil Control
    local recoilControlEnabledString = LPH_ENCSTR('recoilControlEnabled')
    local recoilControlAmountString = LPH_ENCSTR('recoilControlAmount')
    local queuedMouseDeltaString = LPH_ENCSTR('QueuedMouseDelta')
    local pitchString = LPH_ENCSTR('Pitch')

    local characterCameraStep = (Cheat.oldCameraStep or CharacterCamera.Step)
    local firearmRecoilProcess = Hooks:findUpvalues(characterCameraStep, {'firearmRecoilProcess'}).firearmRecoilProcess
    local rotationData = debug.getupvalue(firearmRecoilProcess, 1)
    
    local oldFirearmRecoilProcess; oldFirearmRecoilProcess = Hooks:upvalueBypassHook(firearmRecoilProcess, LPH_NO_VIRTUALIZE(function(...)
        if (not Cheat.Library.flags[recoilControlEnabledString]) then
            return oldFirearmRecoilProcess(...)
        end

        local oldPitch = rotationData[pitchString]
        local result = oldFirearmRecoilProcess(...)
        local currPitch = rotationData[pitchString]

        local deltaPitch = (oldPitch - currPitch)
        local multiplier = (Cheat.Library.flags[recoilControlAmountString] / 100)
        
        if (deltaPitch ~= 0) then
            Cheat[queuedMouseDeltaString] += -math.abs(deltaPitch * multiplier)
        end

        return result
    end))

    -- // Connections
    local shouldShoot = false
    local isShooting = false

    local RunService = game:GetService('RunService')
    local UserInputService = game:GetService('UserInputService')

    local getScreenPosition = LPH_NO_VIRTUALIZE(function(worldPosition)
        local screenPosition, onScreen = workspace.CurrentCamera:WorldToViewportPoint(worldPosition)
        return Vector2.new(screenPosition.X, screenPosition.Y), onScreen
    end)

    local recoilControlSmoothingString = LPH_ENCSTR('recoilControlSmoothing')
    game:GetService('RunService'):BindToRenderStep('Recoil Control', 9, LPH_NO_VIRTUALIZE(function()
        if (not Cheat.Library.flags[recoilControlEnabledString]) then
            return
        end
        
        -- // Weird ass code, don't care lol
        -- // Also, order 9 because cameras are stepped on order 10
        local mouseMovement = (Cheat[queuedMouseDeltaString] / Cheat.Library.flags[recoilControlSmoothingString])
        Cheat[queuedMouseDeltaString] -= mouseMovement

        if (mouseMovement ~= 0) then
            mouseMoveRad(0, mouseMovement)
        end
    end))

    game:GetService('RunService').RenderStepped:Connect(LPH_JIT_MAX(function(deltaTime)
        -- // Aim Point
        if (not ReplicationUtility.rootPart) or (not ReplicationUtility.rootPart.Parent) then
            Cheat.AimPoint.Visible = false
            return
        end

        -- // Item-Based features
        local playerClass = Cheat.PlayerClass
        if (not playerClass.Character) or (not playerClass.Character.EquippedItem) or (playerClass.Character.EquippedItem.Type ~= 'Firearm') then Cheat.AimPoint.Visible = false return end
        local item = playerClass.Character.EquippedItem

        if (Cheat.Library.flags.aimPointEnabled and playerClass.Character.Zooming) then
            local target = Targeting:GetAimbotTarget(workspace.CurrentCamera.ViewportSize / 2, 240, 2000, 'Head', true)
            if (target) then
                local targetPosition = target.Position
                targetPosition += Math:ar2Predict(ReplicationUtility.rootPart.Position, targetPosition, target.Parent.PrimaryPart.AssemblyLinearVelocity, item.FireConfig.MuzzleVelocity)
                targetPosition += Math:ar2BulletDrop(ReplicationUtility.rootPart.Position, targetPosition, item.FireConfig.MuzzleVelocity, Globals.ProjectileGravity)

                local screenPosition = getScreenPosition(targetPosition)
                Cheat.AimPoint.Position = screenPosition
                Cheat.AimPoint.Visible = true
            else
                Cheat.AimPoint.Visible = false
            end
        else
            Cheat.AimPoint.Visible = false
        end

        -- // Aimbot
        if (Cheat.Library.flags.aimbotEnabled and Cheat.Library.flags.aimbotBind) then
            debug.profilebegin('ARS Aimbot')

            local target = Targeting:GetAimbotTarget(
                Cheat.AimbotFOV.Position,
                Cheat.AimbotFOV.Radius,
                (Cheat.Library.flags.aimbotDistanceCheck and Cheat.Library.flags.aimbotMaximumDistance),
                Cheat.Library.flags.aimbotTargetPart,
                Cheat.Library.flags.aimbotVisibleCheck
            )
    
            if (target) then
                local playerObject = Players:GetPlayerFromCharacter(target.Parent)
                local targetPosition = target.Position

                if (Cheat.Library.flags.predictionEnabled) then
                    local velocity = (Cheat.Library.flags.velocityCalculation == 'Normal' and target.Parent.PrimaryPart.AssemblyLinearVelocity) or Prediction:getVelocity(playerObject)
                    local predictionDelta = Math:ar2Predict(ReplicationUtility.rootPart.Position, targetPosition, velocity, item.FireConfig.MuzzleVelocity)
                
                    targetPosition += predictionDelta
                end

                local currPitch, currYaw = CharacterCamera.Instance.CFrame:ToOrientation()
                local goalPitch, goalYaw = CFrame.lookAt(
                    CharacterCamera.Instance.CFrame.Position,
                    targetPosition + Math:ar2BulletDrop(ReplicationUtility.rootPart.Position, targetPosition, item.FireConfig.MuzzleVelocity, Globals.ProjectileGravity)
                ):ToOrientation()

                local deltaX, deltaY = (goalYaw - currYaw), (goalPitch - currPitch)
                local smoothing = math.max(1, Cheat.Library.flags.aimbotSmoothing)
                mouseMoveRad(deltaX / smoothing, deltaY / smoothing)
            
                if (Cheat.Library.flags.drawTargetName) then
                    targetText.Text = playerObject.Name
                    targetText.Position = Cheat.AimbotFOV.Position + (Vector2.yAxis * (Cheat.AimbotFOV.Radius + 10))
                    targetText.Visible = true
                end
            else
                targetText.Visible = false
            end
    
            debug.profileend()
        elseif (targetText.Visible) then
            targetText.Visible = false
        end

        -- // Triggerbot
        if (Cheat.Library.flags.triggerbotEnabled) then
            debug.profilebegin('ARS Triggerbot')

            local target = Targeting:GetAimbotTarget(
                Cheat.TriggerbotFOV.Position,
                Cheat.TriggerbotFOV.Radius,
                (Cheat.Library.flags.triggerbotDistanceCheck and Cheat.Library.flags.triggerbotMaximumDistance),
                Targeting.R15TargetParts[2],
                true
            )

            if (target) then
                shouldShoot = true
            else
                shouldShoot = false
            end

            debug.profileend() 
        end

        if (shouldShoot) then
            isShooting = true
            playerClass.Character.Actions.UseItem(playerClass.Character, 'Begin')
        elseif (isShooting) then
            if (not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
                playerClass.Character.Actions.UseItem(playerClass.Character, 'End')
            end
        end
    end))
end
