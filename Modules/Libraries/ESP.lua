local ESP = {
    Registry = {},
    Config = {
        Enabled = false,
        Boxes = false,
        Names = false,
        Distance = false,
        EquippedItem = false,
        HealthText = false,
        HealthBar = false,
        Tracers = false,
        Arrows = false,
        Chams = false,

        BoxColor = Color3.new(1, 1, 1),
        BoxOutlineColor = Color3.new(0, 0, 0),
        
        NamesColor = Color3.new(1, 1, 1),
        DistanceColor = Color3.new(1, 1, 1),
        ItemColor = Color3.new(1, 1, 1),
        HealthTextColor = Color3.new(1, 1, 1),
        NormalHealthColor = Color3.new(0, 1, 0),
        LowHealthColor = Color3.new(1, 0, 0),
        TracerColor = Color3.new(1, 1, 1),
        ArrowColor = Color3.new(1, 1, 1),
        ChamOutlineColor = Color3.new(1, 1, 1),
        ChamFillColor = Color3.new(1, 1, 1),

        ChamOutlineTransparency = 0,
        ChamFillTransparency = 0.5,
        ChamDepthMode = Enum.HighlightDepthMode.AlwaysOnTop,

        ArrowOpacity = 0.3,
        ArrowRadius = 100,

        TracerOpacity = 0.3,

        DistanceCheck = false,
        MaximumDistance = 2000,

        Target = nil,
        TargetColor = Color3.new(1, 0, 0),
        VisibleCheck = false,
        VisibleColorEnabled = false,
        VisibleColor = Color3.new(1, 0, 0),

        Font = 'Plex',
    },
}

local MathConfig = {
    textYOffset = 2, -- // how many pixels to offset the text
    healthTextXOffset = 0, -- // how many pixels to offset the health text from the healthBar/EspBox
	healthBarXOffset = -5, -- // how many pixels to offset the health bar from the left part of the box (negative means it goes left more) (why the fuck am i idiot proofing this)

	headPositionOffset = Vector3.new(0, 1, 0),
	legPositionOffset = Vector3.new(0, -3.5, 0),

    leftArmOffset = CFrame.new(-1.5, 0, 0), -- // rootCFrame * offset (this is how the espbox will determine where ur arm is)
    rightArmOffset = CFrame.new(1.5, 0, 0), -- // rootCFrame * offset (this is how the espbox will determine where ur arm is)

    dynamicXSize = false, -- // dynamically scale the box size x? (false, it will always be the size as if it was facing you; true, will make it fit the scale of the player better)
}

-- // Vars and shit
local Targeting = REQUIRE_MODULE('Modules/Libraries/Targeting.lua')
local localPlayer = game:GetService('Players').LocalPlayer
local rayIncludeList = { workspace.Map }
local chamsContainer = Instance.new('ScreenGui')

chamsContainer.ResetOnSpawn = false
chamsContainer.Enabled = true
chamsContainer.Parent = game:GetService('CoreGui')

local getScreenPosition = LPH_NO_VIRTUALIZE(function(worldPosition, currentCamera)
	local screenPosition, onScreen = currentCamera:WorldToViewportPoint(worldPosition)
    return Vector2.new(screenPosition.X, screenPosition.Y), onScreen, (screenPosition.Z < 0)
end)

local hideDrawings = LPH_NO_VIRTUALIZE(function(espInstance: {})
    for i,v in next, espInstance do
        if (typeof(v) == 'Instance') then
            -- // if its a Highlight
			v.Enabled = false
            continue
        end

		v.Visible = false
    end
end)

local statsString = LPH_ENCSTR('Stats')
local equippedString = LPH_ENCSTR('Equipped')

local doesCharacterExist = LPH_NO_VIRTUALIZE(function(playerObject: Player)
	local character = playerObject.Character
    if (not character) then return end

	local rootPart = character.PrimaryPart
    if (not rootPart) then return end

    -- if (not playerObject:FindFirstChild(statsString)) then return end
    -- if (not character:FindFirstChild(equippedString)) then return end

    return true, character, rootPart
end)

local calculateXSize = LPH_NO_VIRTUALIZE(function(armScreenPositionX, baseScreenPositionX, distanceFromCamera, fieldOfView)
    return math.max(math.abs(armScreenPositionX - baseScreenPositionX) * 3, (500 / distanceFromCamera) / (fieldOfView / 70))
end)

ESP.addPlayerBox = LPH_NO_VIRTUALIZE(function(self, playerObject: Player)
    local espInstance = ESP.Registry[playerObject]

    espInstance.Box = Drawing.new('Square')
    espInstance.BoxOutline = Drawing.new('Square')

    -- // Property Setting : Box, BoxOutline
    espInstance.Box.Visible = false
    espInstance.Box.Thickness = 1
    espInstance.Box.ZIndex = 2
    espInstance.Box.Color = ESP.Config.BoxColor

    espInstance.BoxOutline.Visible = false
    espInstance.BoxOutline.Thickness = 3
    espInstance.BoxOutline.Color = ESP.Config.BoxOutlineColor
end)

ESP.addPlayerName = LPH_NO_VIRTUALIZE(function(self, playerObject: Player)
    local espInstance = ESP.Registry[playerObject]

    espInstance.Name = Drawing.new('Text')

    -- // Property Setting : Name
    espInstance.Name.Visible = false
    espInstance.Name.Size = 13
    espInstance.Name.Outline = true
    espInstance.Name.Text = playerObject.Name
    espInstance.Name.Center = true
    espInstance.Name.Font = Drawing.Fonts[ESP.Config.Font]
    espInstance.Name.Color = ESP.Config.NamesColor
end)

ESP.addPlayerName = LPH_NO_VIRTUALIZE(function(self, playerObject: Player)
    local espInstance = ESP.Registry[playerObject]

    espInstance.Name = Drawing.new('Text')

    -- // Property Setting : Name
    espInstance.Name.Visible = false
    espInstance.Name.Size = 13
    espInstance.Name.Outline = true
    espInstance.Name.Text = playerObject.Name
    espInstance.Name.Center = true
    espInstance.Name.Font = Drawing.Fonts[ESP.Config.Font]
    espInstance.Name.Color = ESP.Config.NamesColor
end)

ESP.addPlayerDistance = LPH_NO_VIRTUALIZE(function(self, playerObject: Player)
    local espInstance = ESP.Registry[playerObject]

    espInstance.Distance = Drawing.new('Text')

    -- // Property Setting : Distance
    espInstance.Distance.Visible = false
    espInstance.Distance.Size = 13
    espInstance.Distance.Outline = true
    espInstance.Distance.Text = 'nil stud(s)'
    espInstance.Distance.Center = true
    espInstance.Distance.Font = Drawing.Fonts[ESP.Config.Font]
    espInstance.Distance.Color = ESP.Config.DistanceColor
end)

ESP.addPlayerEquippedItem = LPH_NO_VIRTUALIZE(function(self, playerObject: Player)
    local espInstance = ESP.Registry[playerObject]

    espInstance.EquippedItem = Drawing.new('Text')

    -- // Property Setting : EquippedItem
    espInstance.EquippedItem.Visible = false
    espInstance.EquippedItem.Size = 13
    espInstance.EquippedItem.Outline = true
    espInstance.EquippedItem.Text = 'nothing'
    espInstance.EquippedItem.Center = true
    espInstance.EquippedItem.Font = Drawing.Fonts[ESP.Config.Font]
    espInstance.EquippedItem.Color = ESP.Config.ItemColor
end)

ESP.addPlayerHealthBar = LPH_NO_VIRTUALIZE(function(self, playerObject: Player)
    local espInstance = ESP.Registry[playerObject]

    espInstance.HealthBar = Drawing.new('Line')
    espInstance.HealthBarBoost = Drawing.new('Line')
    espInstance.HealthBarOutline = Drawing.new('Line')

    -- // Property Setting : HealthBar, HealthBarBoost, HealthBarOutline
    espInstance.HealthBar.Visible = false
    espInstance.HealthBar.Thickness = 3
    espInstance.HealthBar.ZIndex = 2
    espInstance.HealthBar.Color = Color3.new(0, 1, 0)

    espInstance.HealthBarBoost.Visible = false
    espInstance.HealthBarBoost.Thickness = 3
    espInstance.HealthBarBoost.ZIndex = 3
    espInstance.HealthBarBoost.Color = Color3.fromRGB(255, 200, 0)

    espInstance.HealthBarOutline.Visible = false
    espInstance.HealthBarOutline.Thickness = 5
    espInstance.HealthBarOutline.Color = Color3.new(0, 0, 0)
end)

ESP.addPlayerHealthText = LPH_NO_VIRTUALIZE(function(self, playerObject: Player)
    local espInstance = ESP.Registry[playerObject]

    espInstance.HealthText = Drawing.new('Text')

    -- // Property Setting : HealthText
    espInstance.HealthText.Visible = false
    espInstance.HealthText.Size = 13
    espInstance.HealthText.Outline = true
    espInstance.HealthText.Text = 'hp'
    espInstance.HealthText.Center = false
    espInstance.HealthText.Font = Drawing.Fonts[ESP.Config.Font]
    espInstance.HealthText.Color = ESP.Config.HealthTextColor
end)

ESP.addPlayerTracer = LPH_NO_VIRTUALIZE(function(self, playerObject: Player)
    local espInstance = ESP.Registry[playerObject]

    espInstance.Tracer = Drawing.new('Line')

    -- // Property Setting : Tracer
    espInstance.Tracer.Visible = true
    espInstance.Tracer.Thickness = 0.8
end)

ESP.addPlayerArrow = LPH_NO_VIRTUALIZE(function(self, playerObject: Player)
    local espInstance = ESP.Registry[playerObject]

    espInstance.Arrow = Drawing.new('Triangle')

    -- // Property Setting : Arrow
    espInstance.Arrow.Visible = false
end)

ESP.addPlayerCham = LPH_NO_VIRTUALIZE(function(self, playerObject: Player)
    local espInstance = ESP.Registry[playerObject]

    espInstance.Cham = Instance.new('Highlight')

    -- // Property Setting : Cham
    espInstance.Cham.Enabled = false
    espInstance.Cham.Parent = chamsContainer
end)

-- // ESP methods
ESP.addPlayer = LPH_NO_VIRTUALIZE(function(self, playerObject: Player)
    local espInstance = {}

    ESP.Registry[playerObject] = espInstance

    return espInstance
end)

ESP.removePlayer = LPH_NO_VIRTUALIZE(function(self, playerObject: Player)
    local espInstance = ESP.Registry[playerObject]

    ESP.Registry[playerObject] = nil

    for i,v in next, espInstance do
        if (typeof(v) == 'Instance') then
            v:Destroy() -- // Destroy Highlight
            continue
        end

        v:Remove()
    end

    table.clear(espInstance)
end)

local renderFramePlayer = LPH_JIT_MAX(function(self, deltaTime, playerObject, espInstance, currentCamera, currentCameraCFrame, currentCameraFieldOfView)
	-- // this esp code is messy af but it looks good so fuck off
	if (ESP.Config.Enabled) then
		local exists, character, rootPart = doesCharacterExist(playerObject)
		if (not exists) then return hideDrawings(espInstance) end

		local rootCFrame = rootPart.CFrame
		local rootPosition = rootCFrame.Position
		local distanceFromCamera = (currentCameraCFrame.Position - rootPosition).Magnitude

		if (ESP.Config.DistanceCheck) and (distanceFromCamera > ESP.Config.MaximumDistance) then
			return hideDrawings(espInstance)
		end

		-- // Calculations
		local headPosition = character.Head.Position
		local headScreenPosition, baseOnScreen, isBehindCamera = getScreenPosition(headPosition + MathConfig.headPositionOffset, currentCamera)
		if (not baseOnScreen) and (not ESP.Config.Tracers) and (not ESP.Config.Arrows) then return hideDrawings(espInstance) end

		local center = (currentCamera.ViewportSize / 2)
		local baseCFrame = (MathConfig.dynamicXSize and rootCFrame) or CFrame.lookAt(rootPosition, currentCameraCFrame.Position)
		local leftArmPosition, rightArmPosition = (baseCFrame * MathConfig.leftArmOffset).Position, (baseCFrame * MathConfig.rightArmOffset).Position
		local basePosition = rootPosition

		local legScreenPosition = getScreenPosition(basePosition + MathConfig.legPositionOffset, currentCamera)
		local armScreenPosition = getScreenPosition(leftArmPosition, currentCamera)
		local baseScreenPosition = headScreenPosition + ((legScreenPosition - headScreenPosition) / 2)

		local boxSize = Vector2.new(math.max(calculateXSize(armScreenPosition.X, baseScreenPosition.X, distanceFromCamera, currentCameraFieldOfView), 3), math.min(headScreenPosition.Y - legScreenPosition.Y, -4))
		local realBasePosition = Vector2.new(baseScreenPosition.X, headScreenPosition.Y)
		local boxPosition = realBasePosition - Vector2.new(boxSize.X / 2, boxSize.Y) -- // we calculate box size and position no matter what, since different element positions are based off it

		-- // Visuals Calculation
		local customColor = nil
		local isTarget = (ESP.Config.Target and playerObject == ESP.Config.Target)
		local isVisible = (ESP.Config.VisibleColorEnabled or ESP.Config.VisibleCheck) and (not Targeting.Raycasting:CastWithWhiteList(Ray.new(currentCameraCFrame.Position, basePosition - currentCameraCFrame.Position), rayIncludeList))
		local transparency = (ESP.Config.DynamicTransparency and (1 - math.clamp(distanceFromCamera / ESP.Config.MaximumDistance, 0, 0.9))) or 1

		if (ESP.Config.VisibleCheck) and (not isVisible) then
			return hideDrawings(espInstance)
		end

		if (ESP.Config.VisibleColorEnabled and isVisible) then
			customColor = ESP.Config.VisibleColor
		end

		if (isTarget) then
			customColor = ESP.Config.TargetColor
		end

		-- // Player Data
		local Stats = playerObject.Stats
		local Health = Stats.Health.Value
		local HealthBoost = Stats.HealthBonus.Value
		local MaxHealth = 100
		local EquippedItem = character.Equipped:FindFirstChildOfClass('Model')

		-- // ELEMENTS
		-- // TEXT FORMULAS
		-- // TOP: Vector2.new(boxPosition.X + (boxSize.X / 2), (boxPosition.Y + boxSize.Y) - (textBounds.Y + MathConfig.textYOffset))
		-- // BOTTOM: Vector2.new(boxPosition.X + (boxSize.X / 2), (boxPosition.Y + 2) + MathConfig.textYOffset)
		debug.profilebegin('Elements')
		
		if (ESP.Config.Boxes) then
			debug.profilebegin('Boxes')

			if (not espInstance.Box and not espInstance.BoxOutline) then
				self:addPlayerBox(playerObject)
			end

			espInstance.Box.Visible = baseOnScreen
			espInstance.BoxOutline.Visible = baseOnScreen

			if (baseOnScreen) then
				espInstance.Box.Size = boxSize
				espInstance.Box.Position = (boxPosition + Vector2.yAxis)
				espInstance.Box.Color = (customColor) or ESP.Config.BoxColor
				espInstance.Box.Transparency = transparency

				espInstance.BoxOutline.Size = boxSize
				espInstance.BoxOutline.Position = espInstance.Box.Position
				espInstance.BoxOutline.Color = ESP.Config.BoxOutlineColor
				espInstance.BoxOutline.Transparency = transparency
			end

			debug.profileend()
		elseif (espInstance.Box and espInstance.BoxOutline) then
			espInstance.Box:Destroy()
			espInstance.BoxOutline:Destroy()
			
			espInstance.Box = nil
			espInstance.BoxOutline = nil
		end

		if (ESP.Config.Names) then
			debug.profilebegin('Names')

			if (not espInstance.Name) then
				self:addPlayerName(playerObject)
			end

			espInstance.Name.Visible = baseOnScreen

			if (baseOnScreen) then
				espInstance.Name.Position = Vector2.new(boxPosition.X + (boxSize.X / 2), (boxPosition.Y + boxSize.Y) - (espInstance.Name.TextBounds.Y + MathConfig.textYOffset))
				espInstance.Name.Color = (customColor) or ESP.Config.NamesColor
				espInstance.Name.Transparency = transparency
			end

			debug.profileend()
		elseif espInstance.Name then
			espInstance.Name:Destroy()
			espInstance.Name = nil
		end

		if (ESP.Config.Distance) then
			debug.profilebegin('Distance')

			if (not espInstance.Distance) then
				self:addPlayerDistance(playerObject)
			end

			espInstance.Distance.Visible = baseOnScreen

			if (baseOnScreen) then
				espInstance.Distance.Text = `[{math.floor(distanceFromCamera)} studs]`
				espInstance.Distance.Position = Vector2.new(boxPosition.X + (boxSize.X / 2), (boxPosition.Y + 2) + MathConfig.textYOffset)
				espInstance.Distance.Color = (customColor) or ESP.Config.DistanceColor
				espInstance.Distance.Transparency = transparency
			end

			debug.profileend()
		elseif espInstance.Distance then
			espInstance.Distance:Destroy()
			espInstance.Distance = nil
		end

		if (ESP.Config.EquippedItem) then
			debug.profilebegin('EquippedItem')

			if (not espInstance.EquippedItem) then
				self:addPlayerEquippedItem(playerObject)
			end

			espInstance.EquippedItem.Visible = (baseOnScreen and EquippedItem ~= nil)

			if (baseOnScreen and EquippedItem) then
				espInstance.EquippedItem.Text = EquippedItem.Name
				espInstance.EquippedItem.Color = (customColor) or ESP.Config.ItemColor
				espInstance.EquippedItem.Transparency = transparency

				if (ESP.Config.Distance) then
					espInstance.EquippedItem.Position = espInstance.Distance.Position + Vector2.new(0, espInstance.EquippedItem.TextBounds.Y + MathConfig.textYOffset)
				else
					espInstance.EquippedItem.Position = Vector2.new(boxPosition.X + (boxSize.X / 2), (boxPosition.Y + 2) + MathConfig.textYOffset)
				end
			end

			debug.profileend()
		elseif espInstance.EquippedItem then
			espInstance.EquippedItem:Destroy()
			espInstance.EquippedItem = nil
		end

		if (ESP.Config.HealthBar) then
			debug.profilebegin('Health Bar')

			if (not espInstance.HealthBar and not espInstance.HealthBarBoost and not espInstance.HealthBarOutline) then
				self:addPlayerHealthBar(playerObject)
			end

			espInstance.HealthBar.Visible = baseOnScreen
			espInstance.HealthBarBoost.Visible = baseOnScreen
			espInstance.HealthBarOutline.Visible = baseOnScreen

			if (baseOnScreen) then
				local barSize = (boxSize.Y / MaxHealth)
				local from = boxPosition + Vector2.new(MathConfig.healthBarXOffset, 1)
				local to = boxPosition + Vector2.new(MathConfig.healthBarXOffset, barSize * math.clamp(Health, 0, MaxHealth))

				espInstance.HealthBar.From = from
				espInstance.HealthBar.To = to
				espInstance.HealthBar.Color = ESP.Config.LowHealthColor:Lerp(ESP.Config.NormalHealthColor, math.clamp(Health / MaxHealth, 0, 1))
				espInstance.HealthBar.Transparency = transparency

				if (HealthBoost > 0) then
					espInstance.HealthBarBoost.From = from
					espInstance.HealthBarBoost.To = boxPosition + Vector2.new(MathConfig.healthBarXOffset, barSize * math.clamp(HealthBoost, 0, MaxHealth))
					espInstance.HealthBarBoost.Transparency = transparency
				else
					espInstance.HealthBarBoost.Visible = false
				end

				espInstance.HealthBarOutline.From = boxPosition + Vector2.new(MathConfig.healthBarXOffset, 2)
				espInstance.HealthBarOutline.To = boxPosition + Vector2.new(MathConfig.healthBarXOffset, boxSize.Y - 1)
				espInstance.HealthBarOutline.Transparency = transparency
			end

			debug.profileend()
		elseif (espInstance.HealthBar and espInstance.HealthBarBoost and espInstance.HealthBarOutline) then
			espInstance.HealthBar:Destroy()
			espInstance.HealthBarBoost:Destroy()
			espInstance.HealthBarOutline:Destroy()
			
			espInstance.HealthBar = nil
			espInstance.HealthBarBoost = nil
			espInstance.HealthBarOutline = nil
		end

		if (ESP.Config.HealthText) then
			debug.profilebegin('Health Text')

			if (not espInstance.HealthText) then
				self:addPlayerHealthText(playerObject)
			end

			espInstance.HealthText.Visible = baseOnScreen

			if (baseOnScreen) then
				espInstance.HealthText.Text = `{math.floor(Health + HealthBoost)}hp`
				espInstance.HealthText.Transparency = transparency

				if (ESP.Config.HealthBar) then
					espInstance.HealthText.Color = espInstance.HealthBar.Color -- // VERY micro optimization lol
					espInstance.HealthText.Position = (espInstance.HealthBar.To - Vector2.new(espInstance.HealthText.TextBounds.X + espInstance.HealthBarOutline.Thickness + MathConfig.healthTextXOffset, espInstance.HealthText.TextBounds.Y / 2))
				else
					espInstance.HealthText.Color = ESP.Config.LowHealthColor:Lerp(ESP.Config.NormalHealthColor, math.clamp(Health / MaxHealth, 0, 1))
					espInstance.HealthText.Position = (boxPosition + Vector2.new(0, (boxSize.Y / MaxHealth) * math.clamp(Health, 0, MaxHealth))) - Vector2.new(espInstance.HealthText.TextBounds.X + MathConfig.healthTextXOffset, espInstance.HealthText.TextBounds.Y / 2)
				end
			end

			debug.profileend()
		elseif espInstance.HealthText then
			espInstance.HealthText:Destroy()
			espInstance.HealthText = nil
		end

		if (ESP.Config.Tracers) then
			debug.profilebegin('Tracers')

			if (not espInstance.Tracer) then
				self:addPlayerTracer(playerObject)
			end

			local objectPos = currentCameraCFrame:PointToObjectSpace(basePosition)

			if (isBehindCamera) then
				local targetAngle = math.atan2(objectPos.Y, objectPos.X) + math.pi
				objectPos = CFrame.Angles(0, 0, targetAngle):vectorToWorldSpace(CFrame.Angles(0, math.rad(89.9), 0):vectorToWorldSpace(Vector3.new(0, 0, -1)))
			end

			espInstance.Tracer.From = center
			espInstance.Tracer.To = getScreenPosition(currentCameraCFrame:pointToWorldSpace(objectPos), currentCamera)

			espInstance.Tracer.Color = (customColor) or ESP.Config.TracerColor
			espInstance.Tracer.Transparency = ESP.Config.TracerOpacity

			espInstance.Tracer.Visible = true

			debug.profileend()
		elseif espInstance.Tracer then
			espInstance.Tracer:Destroy()
			espInstance.Tracer = nil
		end

		if (ESP.Config.Arrows) then
			debug.profilebegin('Arrows')

			if (not espInstance.Arrow) then
				self:addPlayerArrow(playerObject)
			end

			local relative = currentCameraCFrame:PointToObjectSpace(basePosition)
			local degree = math.deg(math.atan2(-relative.y, relative.x)) * math.pi / 180
			local endPosition = center + (Vector2.new(math.cos(degree), math.sin(degree))) * ESP.Config.ArrowRadius
			local difference = (center - endPosition)

			espInstance.Arrow.PointA = endPosition
			espInstance.Arrow.PointB = endPosition + (-difference.Unit * 15)
			espInstance.Arrow.PointC = endPosition

			espInstance.Arrow.Color = ESP.Config.ArrowColor
			espInstance.Arrow.Transparency = ESP.Config.ArrowOpacity
			espInstance.Arrow.Visible = true

			debug.profileend()
		elseif espInstance.Arrow then
			espInstance.Arrow:Destroy()
			espInstance.Arrow = nil
		end

		if (ESP.Config.Chams) then
			debug.profilebegin('Chams')

			if (not espInstance.Cham) then
				self:addPlayerCham(playerObject)
			end

			espInstance.Cham.Enabled = baseOnScreen

			if (baseOnScreen) then
				espInstance.Cham.DepthMode = ESP.Config.ChamDepthMode
				espInstance.Cham.FillColor = ESP.Config.ChamFillColor
				espInstance.Cham.FillTransparency = ESP.Config.ChamFillTransparency
				espInstance.Cham.OutlineColor = ESP.Config.ChamOutlineColor
				espInstance.Cham.OutlineTransparency = ESP.Config.ChamOutlineTransparency
				espInstance.Cham.Adornee = rootPart.Parent
			end
			
			debug.profileend()
		elseif espInstance.Cham then
			espInstance.Cham:Destroy()
			espInstance.Cham = nil
		end

		debug.profileend()
	else
		for i, v in next, espInstance do
			v:Destroy()
			espInstance[i] = nil
		end
	end
end)

ESP.renderFrame = LPH_NO_VIRTUALIZE(function(self, deltaTime)
    debug.profilebegin('Player ESP Rendering')

	local currentCamera = workspace.CurrentCamera
	local currentCameraCFrame = currentCamera.CFrame
	local currentCameraFieldOfView = currentCamera.FieldOfView

    for playerObject: Player, espInstance: {} in next, ESP.Registry do
		renderFramePlayer(self, deltaTime, playerObject, espInstance, currentCamera, currentCameraCFrame, currentCameraFieldOfView)
    end

    debug.profileend()
end)

return ESP