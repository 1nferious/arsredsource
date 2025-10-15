return function(Cheat)
    -- // Modules
    local ReplicationUtility = REQUIRE_MODULE('Modules/Libraries/ReplicationUtility.lua')
    local Notifications = REQUIRE_MODULE('Modules/Libraries/Notification.lua')
    local Targeting = REQUIRE_MODULE('Modules/Libraries/Targeting.lua')
    local Math = REQUIRE_MODULE('Modules/Libraries/Math.lua')

    local Network = Cheat.Framework.require('Libraries', 'Network')
    local Cameras = Cheat.Framework.require('Libraries', 'Cameras')
    local Interface = Cheat.Framework.require('Libraries', 'Interface')

    local Reticle = Interface:Get('Reticle')

    local LocalPlayer = game:GetService('Players').LocalPlayer
    local Mouse = LocalPlayer:GetMouse()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local RunService = game:GetService('RunService')
    local CharacterCamera = Cameras:GetCamera('Character')

    -- // Functions
    local playerClass = Cheat.PlayerClass
    local killInsults = {
        '%s was pwned by ars.red 😂',
        '%s imagine being so bad',
        '%s didnt have ars.red',
        'Smoking that %s pack 😂',
        '%s Instead of putting effort into trying to kill me, you should put some effort into that job application!',
        '%s you\'re the sort of person to get 3rd place in a 1v1',
        '%s were you born in the streets? because that is where most accidents happen.',
        '%s to which foundation do i need to donate to help you',
        '%s stormtroopers aim better than you.',
        'you\'re a disgrace to your family, %s',
        '%s Dogged on by ARS.red LAWL!',
        '%s The world would have been better off if your father had pulled out.',
        "%s got wrecked by ars.red 😂",
        "Can %s even spell 'competent'? 🤔",
        "%s is like a lost puppy without ars.red. 🐶",
        "Hey %s, instead of trying to beat me, try beating your own record of failure. 🥇",
        "%s, you're the kind of person who trips over their own shadow. 🌑",
        "%s, were you raised by a pack of wild clowns? 🤡",
        "Which foundation should I donate to in order to save %s from embarrassment? 💸",
        "Even a blindfolded archer has better aim than %s. 🏹",
        "Your family must be regretting their life choices, %s. 👨‍👩‍👧‍👦",
        "%s just got obliterated by ARS.red LAWL! 😆",
        "If only %s's father had invested in a better gene pool... 👨‍👦",
        "%s must be allergic to winning. 🤧",
        "Is %s allergic to success or just highly resistant? 🤷‍♂️",
        "%s's performance is like watching a train wreck in slow motion. 🚂💥",
        "Did %s forget to drink their confidence potion this morning? 🧪",
        "%s, did your brain take a vacation without you? 🧠🏖️",
        "I've seen more coordination from a toddler on roller skates than from %s. 👶⛸️",
        "Do you need a GPS to find your own competence, %s? 🗺️",
        "%s's skill level is on par with a malfunctioning toaster. 🍞🔥",
        "Is %s a professional underachiever or just a natural talent? 🏆",
        "When life gives %s lemons, they probably make orange juice and cry about it. 🍋🥤😢",
        "%s, were you dropped on your head as a child or did you fall off the stupid tree and hit every branch on the way down? 🌳😵",
        "I didn't realize %s's hobby was collecting failures. 🏆🚫",
        "Did %s forget to turn on their brain this morning? 🧠🚫",
        "You're a walking cautionary tale, %s. ⚠️",
        "%s, were you born incompetent or did you achieve it through years of dedicated practice? 👶👎",
        "Is %s aiming for a world record in mediocrity? 🌍🎖️",
        "If ignorance is bliss, %s must be ecstatic. 😌",
        "I bet %s's parents pretend they adopted them whenever they introduce them to someone. 👨‍👩‍👧‍👦🤫",
        "Did %s skip the tutorial on how to be competent? 📚🚫",
        "You're a masterpiece of incompetence, %s. 🎨👎",
        "I've seen more grace in a falling brick than in %s's actions. 🧱😬",
        "%s, were you born this incompetent or did you have to work at it? 👶👎",
        "You're the reason we have warning labels, %s. ⚠️",
        "%s's existence is a monument to failure. 🗿😬",
        "I didn't know it was possible to fail upwards until I met %s. ⬆️👎",
        "Is %s the result of a failed science experiment? 🧪👎",
        "Do you need a map to find your own talent, %s? 🗺️👎",
        "I didn't realize it was bring your incompetence to work day, %s. 💼👎",
        "%s, are you trying to set a record for most failures in a single day? 🏆👎",
        "Is there a support group for people like %s, or are they on their own? 🤝👎",
        "I bet %s's guardian angel goes to therapy. 😇🛋️🧘‍♂️",
        "%s, did you misplace your skillset or were you never issued one? 🧳👎",
        "I've seen more potential in a potato than in %s. 🥔👎",
        "If stupidity were a superpower, %s would be invincible. 🦸‍♂️💥",
        "You're a walking advertisement for birth control, %s. 🚫👶",
        "Is %s allergic to success or just highly resistant? 🤧🥇",
        "If %s's brain was dynamite, they wouldn't have enough to blow their nose. 💣👃",
        "I've seen more ambition in a sloth than in %s. 🦥💤",
    }

    local spoofCFrame = LPH_NO_VIRTUALIZE(function()
        if (not Cheat.rootCFrame) then
            Cheat.rootCFrame = ReplicationUtility.rootPart.CFrame
        end

        ReplicationUtility.rootPart.CFrame = Cheat.rootCFrame

        Cheat.rootCFrame = nil

        -- // fakeInvis Spoof Server CFrame
        -- // basically: before render, position rootPart to normal CFrame
        -- // then, on PostSimulation (before networking), set normal cframe to rootPart cframe, then position rootPart to spoofCFrame
        RunService.PostSimulation:Once(function()
            Cheat.rootCFrame = ReplicationUtility.rootPart.CFrame
            Cheat.serverCFrame = CFrame.new(Cheat.rootCFrame.Position) * CFrame.new(0, -Cheat.Library.flags.fakeInvisAmount, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            ReplicationUtility.rootPart.CFrame = Cheat.serverCFrame
        end)
    end)

    local function noDisablerOrBypass(state)
        if (not state) or (Cheat.Library.flags.acDisabler) then
            return
        end

        Cheat:notifyWarn('AC Disabler Mode "Partial" OR "Full" is required for this feature to work!', 5)
    end

    local function noDisabler(state)
        if (not state) or (Cheat.Library.flags.acDisabler) and (Cheat.Library.flags.acDisablerMode == 'Full') then
            return
        end

        Cheat:notifyWarn('AC Disabler Mode "Full" is required for this feature to work!', 5)
    end

    -- // Library Stuff
    local LeftSide = Cheat.Library.BlatantTab:AddColumn()
    local RightSide = Cheat.Library.BlatantTab:AddColumn()

    -- // Movement
    local MovementSection = LeftSide:AddSection('Character')

    MovementSection:AddToggle({ text = 'Speed Hack', flag = 'speed', tip = 'USE AC DISABLER FOR VALUES HIGHER THAN 50', unsafe = true })
        :AddSlider({ text = 'Speed', flag = 'speedAmount', value = 32, min = 1, max = 80, tip = 'USE AC DISABLER FOR VALUES HIGHER THAN 50' })
        :AddBind({ flag = 'speedBind', callback = function(state) Cheat.Library.options.speed:SetState(state) end })

    MovementSection:AddToggle({ text = 'Jump Hack', flag = 'jumpHack', tip = 'Change jump power', unsafe = true })
        :AddSlider({ text = 'Jump Power', flag = 'jumpPower', value = 50, min = 0, max = 175 })
        :AddBind({ flag = 'jumpHackBind', callback = function(state) Cheat.Library.options.jumpHack:SetState(state) end })

    MovementSection:AddToggle({ text = 'Flight', flag = 'fly', tip = 'USE AC DISABLER FOR VALUES HIGHER THAN 50', unsafe = true })
        :AddSlider({ text = 'Speed', flag = 'flyAmount', value = 16, min = 1, max = 67, tip = 'USE AC DISABLER FOR VALUES HIGHER THAN 50' })
        :AddBind({ text = 'fly', flag = 'flyBind', callback = function(state)
            if (Cheat.Library.flags.flyBindMode == 'Hold') then return end

            Cheat.Library.options.fly:SetState(state)
        end })

    MovementSection:AddList({ text = 'Fly Bind Mode', flag = 'flyBindMode', values = {'Toggle', 'Hold'}, callback = function(state)
        Cheat.Library.options.flyBind:SetMode(string.lower(state))
    end })

    MovementSection:AddToggle({ text = 'Noclip', flag = 'noclip', tip = '[FULL AC DISABLER REQUIRED] Walk through walls', unsafe = true, callback = function(state) task.defer(noDisabler, state) end }):AddBind({ flag = 'noclipBind', callback = function(state) Cheat.Library.options.noclip:SetState(state) end })
    MovementSection:AddToggle({ text = 'Jesus', flag = 'jesus', tip = 'Walk on water', unsafe = true, callback = function(state)
        for _, v in next, workspace.Map.Sea:GetDescendants() do
            if (v:IsA('BasePart')) and (v.Name == 'Water') then
                v.CanCollide = state
            end
        end
    end}):AddBind({ flag = 'jesusBind', callback = function(state) Cheat.Library.options.jesus:SetState(state) end })
    
    MovementSection:AddToggle({ text = 'Click TP', flag = 'clickTP', tip = 'FULL AC DISABLER REQUIRED', unsafe = true, callback = function(state) task.defer(noDisabler, state) end }):AddBind({ flag = 'clickTpBind', mode = 'hold' })
    MovementSection:AddToggle({ text = 'Infinite Jump', flag = 'infJump', tip = 'Jump mid air, without cooldowns', unsafe = true }):AddBind({ flag = 'infJumpBind', callback = function(state) Cheat.Library.options.infJump:SetState(state) end })
    MovementSection:AddToggle({ text = 'No Fall Damage', flag = 'noFall', tip = 'Removes fall damage', unsafe = true }):AddBind({ flag = 'noFallBind', callback = function(state) Cheat.Library.options.noFall:SetState(state) end })
    MovementSection:AddToggle({ text = 'No Sprint Penalty', flag = 'noSprintPenalty', tip = 'Removes the sprinting and penalty', unsafe = true }):AddBind({ flag = 'noSpringPenBind', callback = function(state) Cheat.Library.options.noSprintPenalty:SetState(state) end })
    MovementSection:AddToggle({ text = 'No Footstep Sounds', flag = 'noFootstepSounds', tip = '[AC DISABLER REQUIRED] Removes your serverside footstep sounds, still present on client side', unsafe = true, callback = function(state) task.defer(noDisablerOrBypass, state) end }):AddBind({ flag = 'noFootstepBind', callback = function(state) Cheat.Library.options.noFootstepSounds:SetState(state) end })
    MovementSection:AddToggle({ text = 'Anti Debuff', flag = 'antiDebuff', tip = 'Prevents you from staggering after falling, also removes jump cooldown' }):AddBind({ flag = 'antiDebuffBind', callback = function(state) Cheat.Library.options.antiDebuff:SetState(state) end })

    -- // Disablers
    local DisablerSection = LeftSide:AddSection('Exploits')

    DisablerSection:AddToggle({ text = 'AC Disabler', flag = 'acDisabler', skipflag = false, unsafe = true, tip = 'Partially or fully disables the character anticheat', callback = function(state)
        if (not state) then
            Cheat.acBypassed = false
            return
        end
        
        local mode = Cheat.Library.flags.acDisablerMode
        if (mode == 'Partial') then
            -- // Notify
            if (not Cheat.acBypassed) then
                Cheat:notifyInfo('Disabling the anti-cheat, please wait...', 2, true)
            end

            return
        end

        Cheat:disableAnticheat()
        return
    end })
        :AddList({ flag = 'acDisablerMode', values = { 'Partial', 'Full' }, value = 'Partial', skipflag = true, tip = 'Partial is the fastest, but doesn\'t fully disable.', callback = function() Cheat.Library.options.acDisabler.callback(Cheat.Library.flags.acDisabler) end })    
        :AddBind({ flag = 'acDisablerBind', callback = function(state) Cheat.Library.options.acDisabler:SetState(state) end })

    DisablerSection:AddSlider({ text = 'Speedhack Speed', flag = 'disabledSpeedAmount', value = 100, min = 1, max = 1000, tip = 'THIS IS ONLY WHEN THE ANTICHEAT IS FULLY DISABLED' })
    DisablerSection:AddSlider({ text = 'Fly Speed', flag = 'disabledFlyAmount', value = 100, min = 1, max = 1000, tip = 'THIS IS ONLY WHEN THE ANTICHEAT IS FULLY DISABLED' })

    -- // Aura
    local AuraSection = RightSide:AddSection('Kill Aura')

    AuraSection:AddToggle({ text = 'Enabled', flag = 'killAura', tip = 'Automatically melee people around you' }):AddBind({ flag = 'killAuraBind', callback = function(state) Cheat.Library.options.killAura:SetState(state) end })
    AuraSection:AddToggle({ text = 'Instant', flag = 'killAuraFirerate', tip = 'Kill people instantly', unsafe = true }):AddBind({ flag = 'instantAuraBind', callback = function(state) Cheat.Library.options.killAuraFirerate:SetState(state) end })
    AuraSection:AddToggle({ text = 'Silent', flag = 'killAuraSilent', tip = 'Kill people without holding the melee (Requires Instant to be enabled)', unsafe = true }):AddBind({ flag = 'killAuraSilentBind', callback = function(state) Cheat.Library.options.killAuraSilent:SetState(state) end })
    
    -- // Misc
    local MiscSection = RightSide:AddSection('Misc')
    local oldGravity = workspace.Gravity

    MiscSection:AddToggle({ text = 'Fake Invis', flag = 'fakeInvis', unsafe = true, tip = '[FULL AC DISABLER REQUIRED] Hides your character in the ground', callback = function(state)
        -- // Guard Clauses
        if (state) and (not Cheat.anticheatDisabled) then
            Cheat:notifyError('AC Disabler Mode "Full" is required for this feature to work!', 8, true)
            return Cheat.Library.options.fakeInvis:SetState(false)
        end
        
        -- // Connections
        RunService:UnbindFromRenderStep('FakeInvis')

        if (state) then
            RunService:BindToRenderStep('FakeInvis', Enum.RenderPriority.First.Value, LPH_NO_VIRTUALIZE(function()
                if (not ReplicationUtility.rootPart) or (Cheat.Teleporting) or (Cheat.AntiCheatDisablerSpoofing) then
                    Cheat.rootCFrame = nil
                    Cheat.serverCFrame = nil

                    return
                end

                spoofCFrame()
            end))
        elseif (not state) and (ReplicationUtility.rootPart and Cheat.rootCFrame) then
            ReplicationUtility.rootPart.CFrame = Cheat.rootCFrame
            Cheat.serverCFrame = nil
            Cheat.rootCFrame = nil
        end

        Cheat:notifyInfo(`Fake Invis Enabled: {state}`, 5)
    end }):AddSlider({ text = 'Lower Amount', flag = 'fakeInvisAmount', value = 6, min = 4, max = 7 })
    :AddBind({ flag = 'fakeInvisBind', callback = function(state) Cheat.Library.options.fakeInvis:SetState(state) end })
    
    MiscSection:AddToggle({ text = 'Equip Anywhere', flag = 'equipAnywhere', unsafe = true }):AddBind({ flag = 'equipAnywhereBind', callback = function(state) Cheat.Library.options.equipAnywhere:SetState(state) end })
    MiscSection:AddToggle({ text = 'Chat Spam', flag = 'chatSpam', skipflag = true, unsafe = true })
    MiscSection:AddToggle({ text = 'Kill All', flag = 'killAll', tip = 'Automatically teleport to people and kill them. Won\'t do anything without AC Disabler.', skipflag = true, unsafe = true }):AddBind({ flag = 'killAllBind', callback = function(state) Cheat.Library.options.killAll:SetState(state) end })
    MiscSection:AddToggle({ text = 'Vehicle Kill Aura', flag = 'vehicleAura', unsafe = true }):AddBind({ flag = 'vehicleAuraBind', callback = function(state) Cheat.Library.options.vehicleAura:SetState(state) end })
    MiscSection:AddToggle({ text = 'Shove Aura', flag = 'shoveAura', unsafe = true }):AddBind({ flag = 'shoveAuraBind', callback = function(state) Cheat.Library.options.shoveAura:SetState(state) end })

    MiscSection:AddToggle({ text = 'Gravity Hack', flag = 'gravityEnabled', unsafe = true, callback = function(state) if (not state) then workspace.Gravity = oldGravity end end })
        :AddSlider({ text = 'Gravity', flag = 'gravityAmount', value = oldGravity, min = 1, max = 500 })
        :AddBind({ flag = 'gravityBind', callback = function(state) Cheat.Library.options.gravityEnabled:SetState(state) end })

    MiscSection:AddToggle({ text = 'Kill Say', flag = 'killInsults', tip = 'Automatically insult someone after killing them', unsafe = true })
        :AddBind({ flag = 'killInsultsBind', callback = function(state) Cheat.Library.options.killInsults:SetState(state) end })

    -- // Hooks
    local collectionService = game:GetService('CollectionService')

    local hasTagIndex = LPH_ENCSTR('HasTag')
    local jesusTag = LPH_ENCSTR('World Water Part')
    local mapString = LPH_ENCSTR('Map')
    local nameString = LPH_ENCSTR('Name')
    local waterString = LPH_ENCSTR('Water')
    local seaString = LPH_ENCSTR('Sea')
    local sea = workspace.Map.Sea

    local oldNamecall; oldNamecall = hookmetamethod(game, '__namecall', LPH_NO_VIRTUALIZE(function(self, ...)
        if (not Cheat.Library.flags.jesus) or (getnamecallmethod() ~= hasTagIndex) then
            return oldNamecall(self, ...)
        end

        local firstArg, secondArg = select(1, ...), select(2, ...)
        if (secondArg ~= jesusTag) or (firstArg.Name ~= waterString) or (not firstArg.IsDescendantOf(firstArg, sea)) then
            return oldNamecall(self, ...)
        end

        return false
    end))

    local killedString = LPH_ENCSTR('killed')
    local playerChattedString = LPH_ENCSTR('Player Chatted')
    local globalString = LPH_ENCSTR('Global')

    local oldDeathActionLogger = Cheat.NetworkEvents['Death Action Logger']
    Cheat.NetworkEvents['Death Action Logger'] = LPH_NO_VIRTUALIZE(function(deathActionType, deathActionData, ...)
        if (Cheat.Library.flags.killInsults) and (deathActionData[1].Text == LocalPlayer.Name) and (deathActionData[2] and deathActionData[2].Text == killedString) then
            local insult = killInsults[math.random(1, #killInsults)]

            if (insult) then
                Network:Send(playerChattedString, globalString, string.format(insult, deathActionData[3].Text))
            end
        end

        return oldDeathActionLogger(deathActionType, deathActionData, ...)
    end)

    local castWorldReticleString = LPH_ENCSTR('castWorldReticle')
    local debugTraceback = debug.traceback

    local oldGetTargetInfo; oldGetTargetInfo = Cheat:hookAndTostringSpoof(Reticle, 'GetFirearmTargetInfo', LPH_NO_VIRTUALIZE(function(...)
        if (Cheat.Library.flags.fakeInvis) and (not debugTraceback():match(castWorldReticleString)) then
            local oldRootCFrame = ReplicationUtility.rootPart.CFrame
            local visibleCFrame = Cheat.rootCFrame

            ReplicationUtility.rootPart.CFrame = visibleCFrame

            local data = {oldGetTargetInfo(...)}

            ReplicationUtility.rootPart.CFrame = oldRootCFrame

            return table.unpack(data)
        end
        
        return oldGetTargetInfo(...)
    end))

    -- // Connections
    local partsToUndo = {}
    local spamMessages = {
        "legit ars player 💸💸💸",
        "gaming carpet user 💀🤣",
        "get good get ars 💪",
        "imagine not using ars 🤡",
        "reported bozo 🤡🤡🤡",
        "1nferious smarter😝",
        "ars is cool 😎",
        "buy ars.red 🤑",
        "ars winning😘",
        "ihaxu is big brain 🧠",
        "scream is scream😱",
        "floofyexecutioner #1 movement bypasses🤯",
    }

    local getSwingTime = LPH_NO_VIRTUALIZE(function(equipped, comboIndex)
        local length = 0
        local animation = ReplicatedStorage.Assets.Animations.Melees:FindFirstChild(string.split(equipped.AttackConfig[comboIndex].Animation, 'Melees.')[2])

        if (animation) and (animation:GetAttribute('Length')) then
            length = animation:GetAttribute('Length') / equipped.AttackConfig[comboIndex].PlaybackSpeedMod
        end

        return length
    end)

    local killAura = LPH_JIT_MAX(function()
        if (tick() < Cheat.NextSwing) then
            return
        end

        if (not ReplicationUtility.rootPart) or (not playerClass.Character) then return end
        local RealEquippedItem = playerClass.Character.EquippedItem
        local Melee = (Cheat.Library.flags.killAuraSilent and playerClass.Character.Inventory.Equipment.Melee) or (RealEquippedItem)
        if (not Melee) or (Melee.Type ~= 'Melee') then return end

        local weaponId = Melee.Id
        local target = Targeting:GetTarget(15, true)
        if (not target) then return end

        -- // Send attack packet
        local swingId = workspace:GetServerTimeNow()

        if (Cheat.Library.flags.killAuraFirerate or Cheat.Library.flags.killAuraSilent) then
            if (RealEquippedItem) then
                Network:Send('Character Unequip Item', RealEquippedItem.Id)
            end
            
            Network:Send('Character Equip Item', weaponId, {})
        end

        local clock = os.clock();

        if Melee.ComboAfter <= clock and clock <= Melee.ComboLimit then
            Melee.ComboIndex = Melee.ComboIndex + 1
            if #Melee.AttackConfig < Melee.ComboIndex then
                Melee.ComboIndex = 1
            end
        elseif Melee.ComboAfter < clock then
            Melee.ComboIndex = 1
        end

        local swingTime = getSwingTime(Melee, Melee.ComboIndex)

        Melee.ComboAfter = os.clock() + swingTime - 0.1
        Melee.ComboLimit = Melee.ComboAfter + 0.2

        Network:Send('Melee Swing', swingId, weaponId, Melee.ComboIndex)
        Network:Send('Melee Hit Register', weaponId, swingId, target.PrimaryPart, nil --[['Flesh']], false)

        -- // Re Equip actual item
        if (Cheat.Library.flags.killAuraSilent) then
            Network:Send('Character Unequip Item', weaponId)

            if (RealEquippedItem) then
                Network:Send('Character Equip Item', RealEquippedItem.Id, {})
            end
        end

        -- // Set Cooldown
        Cheat.NextSwing = (Cheat.Library.flags.killAuraFirerate and 0) or (tick() + swingTime)
    end)

    local function killAll()
        local target = Targeting:GetSafeTarget()
        if (not target) then return end

        if (not Cheat.AntiCheatDisablerSpoofing) then
            ReplicationUtility:Teleport(target.PrimaryPart.CFrame + Vector3.new(0, 3, 0))
        end

        Cheat.Library.options.killAura:SetState(true)
        Cheat.Library.options.chatSpam:SetState(true)
    end

    local meleeShoveString = LPH_ENCSTR('Melee Shove')
    local vehicleBumperImpactString = LPH_ENCSTR('Vehicle Bumper Impact')
    local interactionString = LPH_ENCSTR('Interaction')
    local impactHitbox = LPH_ENCSTR('Impact Hitbox')
    local fleshString = LPH_ENCSTR('Flesh')

    RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(deltaTime)
        debug.profilebegin('ARS Blatant Heartbeat')

        -- // Speedhack & Fly
        if (Cheat.Library.flags.speed) and (not Cheat.Library.flags.fly) and (playerClass.Character) and (not playerClass.Character.Vehicle) then
            ReplicationUtility:Strafe(Cheat.anticheatDisabled and Cheat.Library.flags.disabledSpeedAmount or Cheat.Library.flags.speedAmount * (if playerClass.Character.MoveState == 'Falling' then 0.85 else 1))
        end

        if (Cheat.Library.flags.fly) and ((Cheat.Library.flags.flyBindMode == 'Hold' and Cheat.Library.flags.flyBind) or Cheat.Library.flags.flyBindMode == 'Toggle') then
            ReplicationUtility:Fly(Cheat.anticheatDisabled and Cheat.Library.flags.disabledFlyAmount or Cheat.Library.flags.flyAmount)
        end

        -- // Kill Aura
        if (Cheat.Library.flags.killAura) and (not Cheat.AntiCheatDisablerSpoofing) then
            killAura()
        end

        -- // Kill All
        if (Cheat.Library.flags.killAll) and (Cheat.anticheatDisabled) and (not Cheat.AntiCheatDisablerSpoofing) then
            killAll()
        end

        -- // Vehicle Kill Aura
        if (Cheat.Library.flags.vehicleAura) and (playerClass.Character) and (playerClass.Character.Vehicle) then
            local vehicle = playerClass.Character.Vehicle
            local interaction = vehicle:FindFirstChild(interactionString)
            local targets = Targeting:GetTargets(50)

            for _, target in next, targets do
                Network:Send(vehicleBumperImpactString, vehicle, interaction:FindFirstChild(impactHitbox), 10, target, fleshString)
            end
        end

        -- // Shove Aura
        if (Cheat.Library.flags.shoveAura) and (ReplicationUtility.rootPart) and (ReplicationUtility.rootPart.Parent) then
            local target = Targeting:GetTarget(10)
            
            if (target) then
                Network:Send(meleeShoveString, target.PrimaryPart.Position, target.PrimaryPart, fleshString)
            end
        end

        -- // Chat Spam
        if (Cheat.Library.flags.chatSpam) and ((tick() - Cheat.LastChat) > 0.65) then
            Cheat.LastChat = tick()
            Network:Send(playerChattedString, globalString, spamMessages[math.random(1, #spamMessages)])
        end
        
        debug.profileend()

        -- // Velocity Check Bypass
        if (not Cheat.Library.flags.speed) and (not Cheat.Library.flags.fly) and (not Cheat.Library.flags.noFootstepSounds) and (not Cheat.Library.flags.noSprintPenalty) and (Cheat.NoFallPackets == 0) then
            return
        end

        if (not ReplicationUtility.rootPart) then
            return
        end

        Cheat.RealVelocity = ReplicationUtility.rootPart.AssemblyLinearVelocity

        if (Cheat.Library.flags.noFootstepSounds) then
            ReplicationUtility.rootPart.AssemblyLinearVelocity = Vector3.zero
            return
        end

        ReplicationUtility.rootPart.AssemblyLinearVelocity = Math:clampVectorMagnitude(Cheat.RealVelocity, 14)
    end))

    RunService.Stepped:Connect(LPH_NO_VIRTUALIZE(function(deltaTime)
        debug.profilebegin('ARS Blatant Stepped')

        -- // Jump Power
        if (Cheat.Library.flags.jumpHack) and (playerClass.Character) then
            ReplicationUtility.Humanoid.JumpPower = Cheat.Library.flags.jumpPower
        end

        -- // Noclip
        if (Cheat.Library.flags.noclip) and (ReplicationUtility.rootPart) and (ReplicationUtility.rootPart.Parent) then
            for _, v in next, ReplicationUtility.rootPart.Parent:GetDescendants() do
                if (not v:IsA('BasePart')) then
                    continue
                end

                if (table.find(partsToUndo, v)) or (not v.CanCollide) then
                    continue
                end

                v.CanCollide = false
                table.insert(partsToUndo, v)
            end
        elseif (#partsToUndo > 0) then
            for _, v in next, partsToUndo do
                v.CanCollide = true
            end

            table.clear(partsToUndo)
        end

        -- // Gravity
        if (Cheat.Library.flags.gravityEnabled) then
            workspace.Gravity = Cheat.Library.flags.gravityAmount
        end

        -- // No Jump Delay
        if (Cheat.Library.flags.antiDebuff) and (playerClass.Character) then
            playerClass.Character.JumpDebounce = 0
        end

        debug.profileend()
    end))

    RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function(deltaTime)
        -- // Velocity Check Bypass
        if (not Cheat.Library.flags.speed) and (not Cheat.Library.flags.flyDisabler) and (not Cheat.Library.flags.noFootstepSounds) and (not Cheat.Library.flags.noSprintPenalty) and (Cheat.NoFallPackets == 0) then
            return
        end

        if (not ReplicationUtility.rootPart) then
            return
        end

        ReplicationUtility.rootPart.AssemblyLinearVelocity = Cheat.RealVelocity
    end))

    game:GetService('UserInputService').InputBegan:Connect(LPH_NO_VIRTUALIZE(function(inputObject, gameProcessed)
        if (gameProcessed) then
            return
        end

        if (inputObject.KeyCode == Enum.KeyCode.Space) and (Cheat.Library.flags.infJump) and (ReplicationUtility.Humanoid) then
            ReplicationUtility.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        elseif (inputObject.UserInputType == Enum.UserInputType.MouseButton1) and (Cheat.Library.flags.clickTP and Cheat.Library.flags.clickTpBind and ReplicationUtility.rootPart) then
            Mouse.TargetFilter = ReplicationUtility.rootPart.Parent

            local rootPosition = ReplicationUtility.rootPart.Position
            local hitPosition = Mouse.Hit.Position

            if (rootPosition - hitPosition).Magnitude > 2000 then
                return
            end

            ReplicationUtility:Teleport(hitPosition)
        end
    end))
end