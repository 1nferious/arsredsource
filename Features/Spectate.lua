
return function(Cheat)
    -- // Services
    local LocalPlayer = game:GetService('Players').LocalPlayer
    local UserInputService = game:GetService('UserInputService')
    
    -- // Modules
    local ReplicationUtility = REQUIRE_MODULE('Modules/Libraries/ReplicationUtility.lua')

    local UserSettings = Cheat.Framework.require('Libraries', 'UserSettings')
    local Interface = Cheat.Framework.require('Libraries', 'Interface')
    local Animators = Cheat.Framework.require('Classes', 'Animators')
    local Cameras = Cheat.Framework.require('Libraries', 'Cameras')
    local World = Cheat.Framework.require('Libraries', 'World')

    -- // Variables
    local zOffset = 8
    local spectateTarget = nil
    local defaultCamera = Cameras:GetCamera('Default')
    local realCamera = Cameras:GetCurrent().Name
    local lastWorldSet = tick()

    local InterfaceGui = Interface:GetMasterScreenGui()
    local SpectateUI, Arrow = table.unpack(REQUIRE_MODULE('Modules/Misc/CreateSpectateUI.lua')) -- // This is hacky, I don't care.
    SpectateUI.Parent = InterfaceGui
    Cheat.Spectating = false

    -- // Functions
    function Cheat:Spectate(playerObject)
        if (playerObject == LocalPlayer) then
            Interface:Get('Fade'):Fade(0, 0.25):Wait()

            spectateTarget = nil
            Cheat.Spectating = false
            SpectateUI.Visible = false
            Arrow.Parent = nil
            Cameras:SetCurrent(realCamera)

            -- // UnFade
            if (ReplicationUtility.rootPart) then
                World:Set(ReplicationUtility.rootPart.Position, 'Camera', 100):Wait()
                Interface:Show('Hotbar')
                ReplicationUtility:Anchor(false)
            end

            Interface:Get('Fade'):Fade(1, 0.25)

            return
        end

        Interface:Get('Fade'):Fade(0, 0.25):Wait()
        Interface:Hide('Hotbar')
        Cameras:SetCurrent('Default')

        SpectateUI.TextBox.Text = `{playerObject.Name} - {playerObject.UserId}`
        SpectateUI.TextBox.TextBox.Text = SpectateUI.TextBox.Text
        SpectateUI.Visible = true        
        spectateTarget = playerObject
        Arrow.CFrame = CFrame.identity
        Arrow.Parent = workspace.Effects
        Cheat.Spectating = true

        -- // Anchor Character
        if (ReplicationUtility.rootPart) then
            ReplicationUtility:Anchor(true)
        end

        -- // UnFade
        if (playerObject and playerObject.Character and playerObject.Character.PrimaryPart) then
            local event = World:Set(playerObject.Character.PrimaryPart.Position, 'Camera', 1)
            if (event) then
                event:Wait()
            end
        end
        
        Interface:Get('Fade'):Fade(1, 0.25)
    end

    -- // Hooks
    local oldStep; oldStep = Cheat:hookAndTostringSpoof(defaultCamera, 'Step', LPH_JIT_MAX(function(self, deltaTime)
        if (Cheat.Spectating) then
            -- // Check if player data is valid
            if (not spectateTarget) then
                Cheat.Spectating = false
                return Cheat:Spectate(LocalPlayer)
            end
            
            local character = spectateTarget.Character
            if (not character) or (not character.PrimaryPart) then
                return
            end

            local animator = Animators.find(character)
            if (not animator) then
                return
            end

            -- // Step Camera
            local basePosition = (character.PrimaryPart.Position + Vector3.yAxis)
            local mouseDelta = -UserInputService:GetMouseDelta()
            local pitch, yaw = self.Instance.CFrame:ToOrientation()
            pitch, yaw = math.deg(pitch), math.deg(yaw)

            if (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
                pitch = math.clamp(pitch + mouseDelta.Y, -80, 80)
                yaw += mouseDelta.X
            end

            self.Instance.FieldOfView = UserSettings:GetSetting('Accessibility', 'Camera FOV')
            self.Instance.CFrame = (CFrame.new(basePosition) * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(pitch), 0, 0)) * CFrame.new(0, 0, zOffset)

            -- // Arrow
            Arrow.CFrame = CFrame.lookAt(basePosition, basePosition + animator.States.LookDirection)

            -- // Update UI
            SpectateUI.StatLabels.Menu.Info.Text = `{animator.States.InventorySearch}`
            SpectateUI.StatLabels.MoveSpeed.Info.Text = math.floor(character.PrimaryPart.AssemblyLinearVelocity.Magnitude)
            SpectateUI.StatLabels.Equipped.Info.Text = (character.Equipped:GetChildren()[1] and character.Equipped:GetChildren()[1].Name) or 'Nothing'
            SpectateUI.StatLabels.MoveState.Info.Text = `{animator.States.MoveState}`
            SpectateUI.StatLabels.Zooming.Info.Text = `{animator.States.Zooming}`
            SpectateUI.StatLabels.FirstPerson.Info.Text = `{animator.States.FirstPerson}`

            local stats = spectateTarget:FindFirstChild('Stats')
            if (stats) then
                SpectateUI.StatBars.Health.Padding.Bar.Size = UDim2.fromScale(math.clamp(stats.Health.Value / 100, 0, 1), 1)
                SpectateUI.StatBars.Health.Padding.Booster.Size = UDim2.fromScale(math.clamp(stats.HealthBonus.Value / 100, 0, 1), 1)
                SpectateUI.StatLabels.Ping.Info.Text = math.floor(stats.Ping.Value * 1000)
            end
            
            -- // World Set
            if (tick() - lastWorldSet) >= 5 then
                lastWorldSet = tick()
                World:Set(basePosition, 'Camera', 1)
            end
            
            return
        end

        return oldStep(self, deltaTime)
    end))

    local oldSetCurrent; oldSetCurrent = Cheat:hookAndTostringSpoof(Cameras, 'SetCurrent', LPH_NO_VIRTUALIZE(function(self, name)
        if (not checkcaller()) then
            realCamera = name
        end

        return oldSetCurrent(self, name)
    end))

    -- // Connections
    UserInputService.InputChanged:Connect(LPH_NO_VIRTUALIZE(function(inputObject, gameProcessed)
        if (gameProcessed) or (not Cheat.Spectating) then return end
        if (inputObject.UserInputType ~= Enum.UserInputType.MouseWheel) then return end
        
        zOffset = math.clamp(zOffset - math.sign(inputObject.Position.Z), 0.1, 15)
    end))
end