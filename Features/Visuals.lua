return function(Cheat)
    -- // Modules
    local ESP = REQUIRE_MODULE('Modules/Libraries/ESP.lua')
    local Math = REQUIRE_MODULE('Modules/Libraries/Math.lua')
    local ReplicationUtility = REQUIRE_MODULE('Modules/Libraries/ReplicationUtility.lua')
    local Notifications = REQUIRE_MODULE('Modules/Libraries/Notification.lua')
    local Cleaner = REQUIRE_MODULE('Modules/Classes/Cleaner.lua')
    local Prediction = REQUIRE_MODULE('Modules/Libraries/Prediction.lua')
    local Targeting = REQUIRE_MODULE('Modules/Libraries/Targeting.lua')

    local UserSettings = Cheat.Framework.require('Libraries', 'UserSettings')
    local Interface = Cheat.Framework.require('Libraries', 'Interface')
    local Resources = Cheat.Framework.require('Libraries', 'Resources')
    local AR2Lighting = Cheat.Framework.require('Libraries', 'Lighting')
    local AR2Players = Cheat.Framework.require('Classes', 'Players')
    local Network = Cheat.Framework.require('Libraries', 'Network')
    local FirearmSkinsData = Cheat.Framework.require('Configs', 'FirearmSkinsData')
    local Globals = Cheat.Framework.require('Configs', 'Globals')
    local ItemData = Cheat.Framework.require('Configs', 'ItemData')
    local Discovery = Cheat.Framework.require('Libraries', 'Discovery')
    local ZombieConfigs = Cheat.Framework.require('Libraries', 'ZombieConfigs')
    local Cameras = Cheat.Framework.require('Libraries', 'Cameras')
    local Wardrobe = Cheat.Framework.require('Libraries', 'Wardrobe')
    local CreatorData = Cheat.Framework.require('Configs', 'CreatorData')

    local CharacterCamera = Cameras:GetCamera('Character')
    local Map = Interface:Get('Map')
    local Reticle = Interface:Get('Reticle')

    local RunService = game:GetService('RunService')
    local Lighting = game:GetService('Lighting')
    local Players = game:GetService('Players')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    -- local CoreGui = game:GetService('CoreGui')

    local playerClass = AR2Players.get()
    local maxViolationLevel = 5
    local lastUpdate = tick()
    local oldMaterials = {}

    local Skybox = Instance.new('Sky')
    local Skyboxes = {
        ["Purple Nebula"] = {
            SkyboxBk = "rbxassetid://159454299",
            SkyboxDn = "rbxassetid://159454296",
            SkyboxFt = "rbxassetid://159454293",
            SkyboxLf = "rbxassetid://159454286",
            SkyboxRt = "rbxassetid://159454300",
            SkyboxUp = "rbxassetid://159454288"
        },
        ["Neptune"] = {
            SkyboxBk = "rbxassetid://218955819",
            SkyboxDn = "rbxassetid://218953419",
            SkyboxFt = "rbxassetid://218954524",
            SkyboxLf = "rbxassetid://218958493",
            SkyboxRt = "rbxassetid://218957134",
            SkyboxUp = "rbxassetid://218950090"
        },
        ["Redshift"] = {
            SkyboxBk = "rbxassetid://401664839",
            SkyboxDn = "rbxassetid://401664862",
            SkyboxFt = "rbxassetid://401664960",
            SkyboxLf = "rbxassetid://401664881",
            SkyboxRt = "rbxassetid://401664901",
            SkyboxUp = "rbxassetid://401664936"
        },
        ["Aesthetic Night"] = {
            SkyboxBk = "rbxassetid://1045964490",
            SkyboxDn = "rbxassetid://1045964368",
            SkyboxFt = "rbxassetid://1045964655",
            SkyboxLf = "rbxassetid://1045964655",
            SkyboxRt = "rbxassetid://1045964655",
            SkyboxUp = "rbxassetid://1045962969"
        },
        ["Pink Daylight"] = {
            SkyboxBk = "rbxassetid://271042516",
            SkyboxDn = "rbxassetid://271077243",
            SkyboxFt = "rbxassetid://271042556",
            SkyboxLf = "rbxassetid://271042310",
            SkyboxRt = "rbxassetid://271042467",
            SkyboxUp = "rbxassetid://271077958"
        },
        ["Morning Glow"] = {
            SkyboxBk = "rbxassetid://1417494030",
            SkyboxDn = "rbxassetid://1417494146",
            SkyboxFt = "rbxassetid://1417494253",
            SkyboxLf = "rbxassetid://1417494402",
            SkyboxRt = "rbxassetid://1417494499",
            SkyboxUp = "rbxassetid://1417494643"
        },
        ["Setting Sun"] = {
            SkyboxBk = "rbxassetid://626460377",
            SkyboxDn = "rbxassetid://626460216",
            SkyboxFt = "rbxassetid://626460513",
            SkyboxLf = "rbxassetid://626473032",
            SkyboxRt = "rbxassetid://626458639",
            SkyboxUp = "rbxassetid://626460625"
        },
        ["Fade Blue"] = {
            SkyboxBk = "rbxassetid://153695414",
            SkyboxDn = "rbxassetid://153695352",
            SkyboxFt = "rbxassetid://153695452",
            SkyboxLf = "rbxassetid://153695320",
            SkyboxRt = "rbxassetid://153695383",
            SkyboxUp = "rbxassetid://153695471"
        },
        ["Elegant Morning"] = {
            SkyboxBk = "rbxassetid://153767241",
            SkyboxDn = "rbxassetid://153767216",
            SkyboxFt = "rbxassetid://153767266",
            SkyboxLf = "rbxassetid://153767200",
            SkyboxRt = "rbxassetid://153767231",
            SkyboxUp = "rbxassetid://153767288"
        }
    }

    local Skins = {}

    for _, v in next, FirearmSkinsData:GetSkins() do
        for _, vv in next, v do
            table.insert(Skins, vv.Id)
        end
    end

    local firearmString = LPH_ENCSTR('Firearm')

    local onSkinChanged = LPH_NO_VIRTUALIZE(function()
        if (not AR2Players.get()) then return end
        local characterClass = playerClass.Character
        if (not characterClass) or (not characterClass.EquippedItem) or (characterClass.EquippedItem.Type ~= firearmString) then return end

        if (Cheat.Library.flags.skinChanger) then
            characterClass.EquippedItem.SkinId = Cheat.Library.flags.currentSkin
        else
            characterClass.EquippedItem.SkinId = ''
        end
    end)

    local updateMaterialChams = LPH_NO_VIRTUALIZE(function()
        if (not AR2Players.get()) or (not AR2Players.get().Character) then return end

        local character = ReplicationUtility.rootPart.Parent
        if (character.Head.Material == Enum.Material.Fabric) then Cheat.originalColor = character.Head.Color end

        for _, basePart in next, character:GetChildren() do
            if (not basePart:IsA('BasePart')) then
                continue
            end

            if (Cheat.Library.flags.materialChams) then
                basePart.Material = Enum.Material[Cheat.Library.flags.materialChamsMaterial]
                basePart.Color = Cheat.Library.flags.materialChamsColor
            else
                basePart.Material = Enum.Material.Fabric
                basePart.Color = Cheat.originalColor
            end
        end
    end)

    local getScreenPosition = LPH_NO_VIRTUALIZE(function(worldPosition)
        local screenPosition, onScreen = workspace.CurrentCamera:WorldToViewportPoint(worldPosition)
        return Vector2.new(screenPosition.X, screenPosition.Y), onScreen, (screenPosition.Z < 0)
    end)

    -- // Crosshair Code
    local Outline1 = Drawing.new('Line')
    local Outline2 = Drawing.new('Line')
    local Outline3 = Drawing.new('Line')
    local Outline4 = Drawing.new('Line')
    local Line1 = Drawing.new('Line')
    local Line2 = Drawing.new('Line')
    local Line3 = Drawing.new('Line')
    local Line4 = Drawing.new('Line')

    local updateCrosshair = LPH_NO_VIRTUALIZE(function()
        -- // Pretty messy ngl
        -- // dont ask me how this math works, i dont know. (i wrote this a long time ago, but it works)
        local center = (workspace.CurrentCamera.ViewportSize / 2)

        local xVector = (Vector2.xAxis * Cheat.Library.flags.crosshairSize)
        local yVector = (Vector2.yAxis * Cheat.Library.flags.crosshairSize)

        local xOffset = (Vector2.xAxis * Cheat.Library.flags.crosshairCenterOffset)
        local yOffset = (Vector2.yAxis * Cheat.Library.flags.crosshairCenterOffset)

        if (Cheat.Library.flags.crosshairSpin) then
            local spinCoefficient = (tick() * Cheat.Library.flags.crosshairSpinSpeed)

            local xAngle = math.sin(spinCoefficient)
            local yAngle = math.cos(spinCoefficient)
        
            local xAngle2 = math.sin(spinCoefficient + math.rad(90))
            local yAngle2 = math.cos(spinCoefficient + math.rad(90))

            xVector = Vector2.new(xAngle * Cheat.Library.flags.crosshairSize, yAngle * Cheat.Library.flags.crosshairSize)
            xOffset = Vector2.new(xAngle * Cheat.Library.flags.crosshairCenterOffset, yAngle * Cheat.Library.flags.crosshairCenterOffset)

            yVector = Vector2.new(xAngle2 * Cheat.Library.flags.crosshairSize, yAngle2 * Cheat.Library.flags.crosshairSize)
            yOffset = Vector2.new(xAngle2 * Cheat.Library.flags.crosshairCenterOffset, yAngle2 * Cheat.Library.flags.crosshairCenterOffset)
        end

        Line1.Color = Cheat.Library.flags.crosshairColor
        Line1.From = (center + xOffset) + (xOffset.Magnitude > 0 and xOffset.Unit or Vector2.xAxis)
        Line1.To = (Line1.From + xVector)
        Line1.Transparency = (1 - Cheat.Library.flags['crosshairColor Transparency'])
        Line1.ZIndex = 3
        Line1.Thickness = Cheat.Library.flags.crosshairThickness
        Line1.Visible = true

        Line2.Color = Cheat.Library.flags.crosshairColor
        Line2.From = (center - xOffset)
        Line2.To = (Line2.From - xVector)
        Line2.Transparency = (1 - Cheat.Library.flags['crosshairColor Transparency'])
        Line2.ZIndex = 3
        Line2.Thickness = Cheat.Library.flags.crosshairThickness
        Line2.Visible = true

        Line3.Color = Cheat.Library.flags.crosshairColor
        Line3.From = (center + yOffset)
        Line3.To = (Line3.From + yVector)
        Line3.Transparency = (1 - Cheat.Library.flags['crosshairColor Transparency'])
        Line3.ZIndex = 3
        Line3.Thickness = Cheat.Library.flags.crosshairThickness
        Line3.Visible = true

        Line4.Color = Cheat.Library.flags.crosshairColor
        Line4.From = (center - yOffset)
        Line4.To = (Line4.From - yVector)
        Line4.Transparency = (1 - Cheat.Library.flags['crosshairColor Transparency'])
        Line4.ZIndex = 3
        Line4.Thickness = Cheat.Library.flags.crosshairThickness
        Line4.Visible = true

        -- // Outlines
        Outline1.From = (Line1.From - xVector.Unit)
        Outline1.To = (Line1.To + xVector.Unit)
        Outline1.Thickness = Cheat.Library.flags.crosshairThickness + 2
        Outline1.Color = Cheat.Library.flags.crosshairOutlineColor
        Outline1.Transparency = (1 - Cheat.Library.flags['crosshairOutlineColor Transparency'])
        Outline1.Visible = true

        Outline2.From = (Line2.From + xVector.Unit)
        Outline2.To = (Line2.To - xVector.Unit)
        Outline2.Thickness = Cheat.Library.flags.crosshairThickness + 2
        Outline2.Color = Cheat.Library.flags.crosshairOutlineColor
        Outline2.Transparency = (1 - Cheat.Library.flags['crosshairOutlineColor Transparency'])
        Outline2.Visible = true

        Outline3.From = (Line3.From - yVector.Unit)
        Outline3.To = (Line3.To + yVector.Unit)
        Outline3.Thickness = Cheat.Library.flags.crosshairThickness + 2
        Outline3.Color = Cheat.Library.flags.crosshairOutlineColor
        Outline3.Transparency = (1 - Cheat.Library.flags['crosshairOutlineColor Transparency'])
        Outline3.Visible = true

        Outline4.From = (Line4.From + yVector.Unit)
        Outline4.To = (Line4.To - yVector.Unit)
        Outline4.Thickness = Cheat.Library.flags.crosshairThickness + 2
        Outline4.Color = Cheat.Library.flags.crosshairOutlineColor
        Outline4.Transparency = (1 - Cheat.Library.flags['crosshairOutlineColor Transparency'])
        Outline4.Visible = true

        -- // Magic Bullet Crosshair
        if (Cheat.Library.flags.magicBulletCrosshair and playerClass.Character and playerClass.Character.EquippedItem and playerClass.Character.EquippedItem.Type == firearmString) then
            local item = playerClass.Character.EquippedItem
            local model = playerClass.Character.Instance.Equipped:FindFirstChild(item.Name)
            if (not model) then return end
            
            local target = Targeting:GetAimbotTarget(
                Cheat.SilentFOV.Position,
                Cheat.SilentFOV.Radius,
                (Cheat.Library.flags.silentDistanceCheck and Cheat.Library.flags.silentMaximumDistance),
                Cheat.Library.flags.silentTargetPart,
                Cheat.Library.flags.silentVisibleCheck
            )

            if (not target) then return end
            local origin = Reticle:GetFirearmTargetInfo(playerClass.Character, CharacterCamera, model)
            local _, found = Targeting:FindFirePosition(origin, target)

            if (found) then
                Line1.Color = Cheat.Library.flags.magicBulletCrosshairColor
                Line2.Color = Cheat.Library.flags.magicBulletCrosshairColor
                Line3.Color = Cheat.Library.flags.magicBulletCrosshairColor
                Line4.Color = Cheat.Library.flags.magicBulletCrosshairColor
            else
                Line1.Color = Cheat.Library.flags.magicBulletCrosshairColorCant
                Line2.Color = Cheat.Library.flags.magicBulletCrosshairColorCant
                Line3.Color = Cheat.Library.flags.magicBulletCrosshairColorCant
                Line4.Color = Cheat.Library.flags.magicBulletCrosshairColorCant
            end
        end
    end)

    local hideCrosshair = LPH_NO_VIRTUALIZE(function()
        Line1.Visible = false
        Outline1.Visible = false
        Line2.Visible = false
        Outline2.Visible = false
        Line3.Visible = false
        Outline3.Visible = false
        Line4.Visible = false
        Outline4.Visible = false
    end)

    -- // Vehicle ESP
    local vehicleEsps = {}

    local function vehicleESP(vehicle)
        local nameText = Drawing.new('Text')

        nameText.Visible = false
        nameText.Center = true
        nameText.Outline = true
        nameText.Color = Color3.new(1, 1, 1)
        nameText.Size = 13
        nameText.Text = vehicle.Name
        nameText.Font = Drawing.Fonts[Cheat.Library.flags.drawingFont]

        vehicleEsps[vehicle] = nameText
    end

    local renderVehicleESP = LPH_JIT_MAX(function()
        debug.profilebegin('Vehicle ESP Rendering')

        for vehicle, nameText in next, vehicleEsps do
            if (Cheat.Library.flags.vehicleESPEnabled) then
                if (not vehicle:FindFirstChild('Base')) or (not vehicle:FindFirstChild('Interaction')) then
                    nameText.Visible = false
                    continue
                end

                local distance = (vehicle.Base.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                local screenPosition, onScreen = getScreenPosition(vehicle.Base.Position)
                if (not onScreen) then nameText.Visible = false continue end
                if (Cheat.Library.flags.vehicleESPMaxDist) and (distance > Cheat.Library.flags.vehicleESPDistance) then nameText.Visible = false continue end

                local strings = {}

                if (Cheat.Library.flags.vehicleNames) then
                    table.insert(strings, vehicle.Name)
                end

                if (Cheat.Library.flags.vehicleESPShowDistance) then
                    table.insert(strings, '[' .. tostring(math.floor(distance)) .. ' studs]')
                end

                nameText.Text = table.concat(strings, ' ')
                nameText.Color = Cheat.Library.flags.vehicleNamesColor
                nameText.Transparency = (1 - math.clamp(distance / Cheat.Library.flags.vehicleESPDistance, 0, 0.7))
                nameText.Position = screenPosition
                nameText.Visible = true
            else
                nameText.Visible = false
            end
        end

        debug.profileend()
    end)

    local destroyVehicleESPs = LPH_NO_VIRTUALIZE(function()
        for vehicle, nameText in next, vehicleEsps do
            vehicleEsps[vehicle] = nil
            nameText:Remove()
        end
    end)

    -- // Item ESP
    local itemEsps = {}
    local itemTypes = {'Ammo', 'Accessory', 'Attachment', 'Backpack', 'Belt', 'Clothing', 'Consumable', 'Firearm', 'FuelCan', 'Hat', 'Medical', 'Melee', 'RepairTool', 'Vest', 'Utility'}

    local lootString = LPH_ENCSTR('Loot')
    local connectItemAncestoryChangedSignal = LPH_NO_VIRTUALIZE(function(item, nameText, data)
        local ancestryChanged; ancestryChanged = item.AncestryChanged:Connect(function(_, parent)
            if (not parent) or (parent.Parent.Name ~= lootString) then
                ancestryChanged:Disconnect()
                nameText:Remove()

                local index = table.find(itemEsps, data)
                if (not index) then return end

                table.remove(itemEsps, index)
            end
        end)
    end)

    local itemESP = LPH_JIT_MAX(function(item)
        if (not item:IsA('CFrameValue')) then return end
        local nameText = Drawing.new('Text')

        nameText.Visible = false
        nameText.Center = true
        nameText.Outline = true
        nameText.Color = Color3.new(1, 1, 1)
        nameText.Size = 13
        nameText.Text = item.Name
        nameText.Font = Drawing.Fonts[Cheat.Library.flags.drawingFont]

        local itemData = ItemData[item.Name]
        local data = {
            Type = itemData.Type,
            Text = nameText,
            Item = item,
            IsRare = (itemData.RareItem) or (itemData.EventItem),
        }

        table.insert(itemEsps, data)

        connectItemAncestoryChangedSignal(item, nameText, data)
    end)

    local renderItemESP = LPH_JIT_MAX(function()
        debug.profilebegin('Item ESP Rendering')

        for _, data in next, itemEsps do
            if (Cheat.Library.flags.itemESPEnabled) then
                if (not Cheat.Library.flags.itemESPType[data.Type]) then data.Text.Visible = false continue end
                if (Cheat.Library.flags.itemESPRarity == 'Rare Only') and (not data.IsRare) then data.Text.Visible = false continue end
                local distance = (data.Item.Value.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                local screenPosition, onScreen = getScreenPosition(data.Item.Value.Position)
                if (not onScreen) then data.Text.Visible = false continue end
                if (Cheat.Library.flags.itemESPDistanceCheck) and (distance > Cheat.Library.flags.itemESPMaxDistance) then data.Text.Visible = false continue end

                local strings = {}

                if (Cheat.Library.flags.itemESPTypeEnabled) then
                    table.insert(strings, '[' .. data.Type .. ']')
                end

                if (Cheat.Library.flags.itemESPName) then
                    table.insert(strings, data.Item.Name)
                end

                if (Cheat.Library.flags.itemESPDistance) then
                    table.insert(strings, '[' .. tostring(math.floor(distance)) .. ' studs]')
                end

                data.Text.Text = table.concat(strings, ' ')
                data.Text.Color = (Cheat.Library.flags[data.Type .. 'Color'] or Color3.new(1, 1, 1))
                data.Text.Transparency = (1 - math.clamp(distance / Cheat.Library.flags.itemESPMaxDistance, 0, 0.7))
                data.Text.Position = screenPosition
                data.Text.Visible = true
            else
                data.Text.Visible = false
            end
        end

        debug.profileend()
    end)

    local destroyItemESPs = LPH_NO_VIRTUALIZE(function()
        for item, data in next, itemEsps do
            itemEsps[item] = nil
            data.Text:Remove()
        end
    end)

    -- // Event ESP
    local eventESPs = {}

    local function eventESP(event)
        local nameText = Drawing.new('Text')

        nameText.Visible = false
        nameText.Center = true
        nameText.Outline = true
        nameText.Color = Color3.new(1, 1, 1)
        nameText.Size = 13
        nameText.Font = Drawing.Fonts[Cheat.Library.flags.drawingFont]

        eventESPs[event] = {
            Text = nameText,
            Name = string.gsub(string.gsub(event.Name, '%d', ''), '([a-z])([A-Z])', '%1 %2'),
        }
    end

    local renderEventESP = LPH_JIT_MAX(function()
        debug.profilebegin('Event ESP Rendering')

        for event, eventData in next, eventESPs do
            if (Cheat.Library.flags.eventESPEnabled) then
                if (not Cheat.Library.flags.eventESPType[event.Name]) then eventData.Text.Visible = false continue end
                local distance = (event.Value.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                local screenPosition, onScreen = getScreenPosition(event.Value.Position)
                if (not onScreen) then eventData.Text.Visible = false continue end
                if (Cheat.Library.flags.eventESPDistanceCheck) and (distance > Cheat.Library.flags.eventESPMaxDistance) then eventData.Text.Visible = false continue end

                local strings = {}

                if (Cheat.Library.flags.eventESPNames) then
                    table.insert(strings, eventData.Name)
                end

                if (Cheat.Library.flags.eventESPDistance) then
                    table.insert(strings, '[' .. tostring(math.floor(distance)) .. ' studs]')
                end

                eventData.Text.Text = table.concat(strings, ' ')
                eventData.Text.Color = Cheat.Library.flags.eventESPNamesColor
                eventData.Text.Transparency = (1 - math.clamp(distance / Cheat.Library.flags.eventESPMaxDistance, 0, 0.7))
                eventData.Text.Position = screenPosition
                eventData.Text.Visible = true
            else
                eventData.Text.Visible = false
            end
        end

        debug.profileend()
    end)

    local destroyEventESPs = LPH_NO_VIRTUALIZE(function()
        for event, eventData in next, eventESPs do
            eventESPs[event] = nil
            eventData.Text:Remove()
            table.clear(eventData)
        end
    end)

    -- // Container ESP
    local groupContainersLinkTable = {}
    local groupDrawingObjects = {}
    local ongoingQueries = {}
    local isFetched = {}
    local oldGroups = {}

    local lootbinsOverlapParams = OverlapParams.new()

    lootbinsOverlapParams.FilterType = Enum.RaycastFilterType.Include
    lootbinsOverlapParams.FilterDescendantsInstances = {workspace.Map.Shared.LootBins}

    local function containerESP(group)
        if groupDrawingObjects[group] == nil then
            groupDrawingObjects[group] = false

            local text = Drawing.new('Text')
            text.Visible = true
            text.Center = false
            text.Outline = true
            text.Font = Drawing.Fonts[Cheat.Library.flags.drawingFont]
            text.Size = 13
            text.ZIndex = 2
            text.Color = Color3.fromRGB(255, 255, 255)

            if groupDrawingObjects[group] ~= nil then
                groupDrawingObjects[group] = {
                    Text = text
                }
            else
                text:Remove()
                text = nil
            end
        end
    end

    local deleteDrawings = LPH_NO_VIRTUALIZE(function(drawings)
        for i, drawing in next, drawings do
            drawing:Remove()
            drawings[i] = nil
        end
    end)

    local destroyContainerDrawings = LPH_NO_VIRTUALIZE(function(v)
        if groupDrawingObjects[v] == false then
            repeat task.wait() until groupDrawingObjects[v] ~= false
        end

        deleteDrawings(groupDrawingObjects[v])
        groupDrawingObjects[v] = nil
    end)

    -- // i would recommend minimizing this function
    local renderContainerESP = LPH_JIT_MAX(function()
        if (not playerClass) or (not playerClass.Character) or (not playerClass.Character.Inventory) or (not playerClass.Character.Inventory.Containers) then
            for i, drawings in next, groupDrawingObjects do
                if (not drawings) then
                    continue
                end

                deleteDrawings(drawings)

                groupDrawingObjects[i] = nil
            end
            
            table.clear(groupDrawingObjects)
            table.clear(ongoingQueries)
            table.clear(isFetched)
            table.clear(oldGroups)
            
            return
        end
        
        -- // Find Groups
        local containers = playerClass.Character.Inventory.Containers
        local rootPosition = ReplicationUtility.rootPart.Position
        local nearGroups = {}

        if (Cheat.Library.flags.containerESPEnabled) or (Cheat.Library.flags.unlockAura) then
            local partsInBox = workspace:GetPartBoundsInBox(ReplicationUtility.rootPart.CFrame, Vector3.one * 28, lootbinsOverlapParams)
            for _, v in next, partsInBox do
                if (v.Parent.Name ~= 'Group') or (not v.Parent:GetAttribute('Position')) then
                    continue
                end

                if ((v.Parent:GetAttribute('Position') - rootPosition).Magnitude > 20) then
                    for _, v in next, v.Parent:GetChildren() do
                        local distance = (rootPosition - v.Position).Magnitude
                        if (distance > 20) then continue end

                        if (not table.find(nearGroups, v.Parent)) then
                            table.insert(nearGroups, v.Parent)
                        end
        
                        break
                    end
                    
                    continue
                end

                if (table.find(nearGroups, v.Parent)) then
                    continue
                end

                table.insert(nearGroups, v.Parent)
            end
        end

        -- // Create Drawings
        if (Cheat.Library.flags.containerESPEnabled) then
            debug.profilebegin('Create Container ESP Drawings')

            for _, group in next, nearGroups do
                if (table.find(oldGroups, group)) then
                    continue
                end

                containerESP(group)
            end

            debug.profileend()
        end

        for _, v in next, oldGroups do
            if (table.find(nearGroups, v)) then
                continue
            end

            if (groupDrawingObjects[v]) then
                task.spawn(destroyContainerDrawings, v)
            end
        end

        if #nearGroups <= 0 and #oldGroups > 0 then
            oldGroups = nearGroups

            Network:Send('Inventory Container Group Disconnect')
            table.clear(groupContainersLinkTable)
            table.clear(ongoingQueries)
            table.clear(isFetched)

            return
        end

        oldGroups = nearGroups
        
        for _, v in next, nearGroups do
            if (groupContainersLinkTable[v]) then
                local exists = true

                for _, v in next, groupContainersLinkTable[v] do
                    if (not table.find(containers, v)) then
                        exists = false
                        break
                    end
                end

                if (exists) then
                    continue
                else
                    groupContainersLinkTable[v] = nil
                end
            end

            if (not v:GetAttribute('Position')) then
                continue
            end

            for _, container in next, containers do
                if (container.IsCarried) or (not container.WorldPosition) then
                    continue
                end

                local isMatch = (container.WorldPosition == v:GetAttribute('Position'))

                if (not isMatch) then
                    for _, part in next, v:GetChildren() do
                        if (part.Position == container.WorldPosition) then
                            isMatch = true
                            break
                        end
                    end
                end

                if (isMatch) then
                    if (not groupContainersLinkTable[v]) then
                        groupContainersLinkTable[v] = {}
                    end

                    if (not table.find(groupContainersLinkTable[v], container)) then
                        table.insert(groupContainersLinkTable[v], container)
                    end
                end
            end
        end
    
        for _, v in next, nearGroups do
            if (groupContainersLinkTable[v]) or (ongoingQueries[v]) then
                continue
            end

            ongoingQueries[v] = true
            task.defer(LPH_JIT_MAX(function()
                isFetched[v] = Network:Fetch('Inventory Container Group Connect', v)
                ongoingQueries[v] = nil
            end))
        end

        -- // Unlock Aura
        if (Cheat.Library.flags.unlockAura) then
            for _, container in next, containers do
                if (not container.Occupants) then
                    continue
                end

                for _, item in next, container.Occupants do
                    if (not Globals.CosmeticSlots[item.EquipSlot]) or (Discovery:IsDiscovered(item.Name)) then
                        continue
                    end

                    Network:Send('Inventory Unlock Item', item.Id)
                end
            end
        end

        -- // Render (im not even going to try and make this look nice)
        debug.profilebegin('Container ESP Rendering')

        local camera = workspace.CurrentCamera
        for _, v in next, nearGroups do
            local drawings = groupDrawingObjects[v]

            if (not drawings) then
                continue
            end

            if (not Cheat.Library.flags.containerESPEnabled) then
                drawings.Text.Visible = false
                
                continue
            end

            local itemText = ''

            debug.profilebegin('Item Counter')

            if (isFetched[v] and groupContainersLinkTable[v]) then
                local counts = {}

                for _, v2 in next, groupContainersLinkTable[v] do
                    if v2.Occupants then
                        for _, v3 in next, v2.Occupants do
                            counts[v3.Name] = (counts[v3.Name] or 0) + 1
                        end
                    end
                end

                for i, v2 in next, counts do
                    itemText = (itemText ~= "" and (itemText .. "\n") or itemText) .. "[" .. v2 .. "] " .. i
                end
            end

            debug.profileend()

            itemText = (itemText == '' and 'Empty') or itemText

            if (itemText == 'Empty') and (not Cheat.Library.flags.containerESPShowEmpty) then
                drawings.Text.Visible = false
                continue
            end
        
            debug.profilebegin('Screen Position Calculations')

            local worldPosition = v:GetAttribute("Position")
            local screenPosition, onScreen = camera:WorldToViewportPoint(worldPosition)

            debug.profileend()
            debug.profilebegin('Math')

            local position = Vector2.new(screenPosition.X, screenPosition.Y)
            local cameraDistance = (camera.CFrame.Position - worldPosition).Magnitude
            local mathAbs = math.abs(math.floor(cameraDistance))
            
            if (Cheat.Library.flags.containerESPNames and onScreen) then
                if isFetched[v] then
                    drawings.Text.Text = itemText
                end

                drawings.Text.Position = position + Vector2.new(-(drawings.Text.TextBounds.X / 2), (drawings.Text.TextBounds.Y / 2))
                drawings.Text.Color = Cheat.Library.flags.containerESPNamesColor --library.flags["container_esp_items_color"]
                drawings.Text.Transparency = (1 - Cheat.Library.flags['containerESPNamesColor Transparency'])
                drawings.Text.Visible = true
                drawings.Text.ZIndex = 2 - mathAbs
            else
                drawings.Text.Visible = false
            end

            debug.profileend()
        end

        debug.profileend()
    end)

    -- // Zombie ESP
    local zombieESPs = {}

    local function zombieESP(zombie)
        local nameText = Drawing.new('Text')

        nameText.Visible = false
        nameText.Center = true
        nameText.Outline = true
        nameText.Color = Color3.new(1, 1, 1)
        nameText.Size = 13
        nameText.Text = zombie.Name
        nameText.Font = Drawing.Fonts[Cheat.Library.flags.drawingFont]

        zombieESPs[zombie] = nameText
    end

    local renderZombieESP = LPH_JIT_MAX(function()
        debug.profilebegin('Zombie ESP Rendering')

        for zombie, nameText in next, zombieESPs do
            if (Cheat.Library.flags.zombieESPEnabled) and (zombie.PrimaryPart) then
                if (Cheat.Library.flags.zombieESPBosses) then
                    local oldIdentity = getthreadidentity()
                    setthreadidentity(2)
                    local zombieConfig = ZombieConfigs:Get(zombie.Name)
                    setthreadidentity(oldIdentity)

                    if (zombieConfig and (zombieConfig.CanGetStunned)) and (not zombie.Name:lower():match('boss')) then
                        nameText.Visible = false
                        continue
                    end
                end

                local distance = (zombie.PrimaryPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                local screenPosition, onScreen = getScreenPosition(zombie.PrimaryPart.Position)
                if (not onScreen) then nameText.Visible = false continue end
                if (Cheat.Library.flags.zombieESPDistanceCheck) and (distance > Cheat.Library.flags.zombieESPMaxDistance) then nameText.Visible = false continue end

                local strings = {}

                if (Cheat.Library.flags.zombieESPNames) then
                    table.insert(strings, zombie.Name)
                end

                if (Cheat.Library.flags.zombieESPDistance) then
                    table.insert(strings, '[' .. tostring(math.floor(distance)) .. ' studs]')
                end

                nameText.Text = table.concat(strings, ' ')
                nameText.Color = Cheat.Library.flags.zombieESPNamesColor
                nameText.Transparency = (1 - math.clamp(distance / Cheat.Library.flags.zombieESPMaxDistance, 0, 0.7))
                nameText.Position = screenPosition
                nameText.Visible = true
            else
                nameText.Visible = false
            end
        end

        debug.profileend()
    end)

    local destroyZombieESPs = LPH_NO_VIRTUALIZE(function()
        for zombie, nameText in next, zombieESPs do
            zombieESPs[zombie] = nil
            nameText:Remove()
        end
    end)

    -- // Corpse ESP
    local corpseESPs = {}

    local function corpseESP(corpse)
        local nameText = Drawing.new('Text')

        nameText.Visible = false
        nameText.Center = true
        nameText.Outline = true
        nameText.Color = Color3.new(1, 1, 1)
        nameText.Size = 13
        nameText.Text = corpse.Name
        nameText.Font = Drawing.Fonts[Cheat.Library.flags.drawingFont]

        corpseESPs[corpse] = nameText
    end
    
    local renderCorpseESP = LPH_JIT_MAX(function()
        debug.profilebegin('Corpse ESP Rendering')

        for corpse, nameText in next, corpseESPs do
            if (Cheat.Library.flags.corpseESPEnabled) and (corpse.PrimaryPart) then
                local distance = (corpse.PrimaryPart.Position - workspace.CurrentCamera.CFrame.Position).Magnitude
                local screenPosition, onScreen = getScreenPosition(corpse.PrimaryPart.Position)
                if (not onScreen) then nameText.Visible = false continue end
                if (Cheat.Library.flags.corpseESPDistanceCheck) and (distance > Cheat.Library.flags.corpseESPMaxDistance) then nameText.Visible = false continue end

                local strings = {}

                if (Cheat.Library.flags.corpseESPNames) then
                    table.insert(strings, corpse.Name)
                end

                if (Cheat.Library.flags.corpseESPDistance) then
                    table.insert(strings, '[' .. tostring(math.floor(distance)) .. ' studs]')
                end

                nameText.Text = table.concat(strings, ' ')
                nameText.Color = Cheat.Library.flags.corpseESPNamesColor
                nameText.Transparency = (1 - math.clamp(distance / Cheat.Library.flags.corpseESPMaxDistance, 0, 0.7))
                nameText.Position = screenPosition
                nameText.Visible = true
            else
                nameText.Visible = false
            end
        end

        debug.profileend()
    end)

    local destroyCorpseESPs = LPH_NO_VIRTUALIZE(function()
        for corpse, nameText in next, corpseESPs do
            corpseESPs[corpse] = nil
            nameText:Remove()
        end
    end)

    -- // Library Stuff
    local LeftSide = Cheat.Library.VisualsTab:AddColumn()
    local RightSide = Cheat.Library.VisualsTab:AddColumn()

    -- // ESP
    local ESPSection = LeftSide:AddSection('Player ESP')

    ESPSection:AddToggle({ text = 'Enabled', flag = 'espEnabled', callback = function(state)
        ESP.Config.Enabled = state

        if (not state) then
            -- // this is to hide all the drawings when you disable the ESP
            -- // the reason we don't just step it anyways is cuz it still lags for some reason
            -- // I'm going to do this for every esp so you only have frame impacts for ESPs you have enabled :)
            ESP:renderFrame(1 / 60)
        end
    end }):AddBind({ flag = 'espBind', callback = function(state) Cheat.Library.options.espEnabled:SetState(state) end })
    
    ESPSection:AddToggle({ text = 'Visible Check', flag = 'espVisibleCheck', callback = function(state) ESP.Config.VisibleCheck = state end })
    ESPSection:AddToggle({ text = 'Names', flag = 'espNames', callback = function(state) ESP.Config.Names = state end }):AddColor({ flag = 'espNamesColor', color = Color3.new(1, 1, 1), callback = function(state) ESP.Config.NamesColor = state end })
    ESPSection:AddToggle({ text = 'Boxes', flag = 'espBoxes', callback = function(state) ESP.Config.Boxes = state end }):AddColor({ flag = 'espBoxColor', color = Color3.new(1, 1, 1), callback = function(state) ESP.Config.BoxColor = state end })
    ESPSection:AddToggle({ text = 'Distance', flag = 'espDistance', callback = function(state) ESP.Config.Distance = state end }):AddColor({ flag = 'espDistanceColor', color = Color3.new(1, 1, 1), callback = function(state) ESP.Config.DistanceColor = state end })
    ESPSection:AddToggle({ text = 'Equipped Item', flag = 'espEquippedItem', callback = function(state) ESP.Config.EquippedItem = state end }):AddColor({ flag = 'espItemColor', color = Color3.new(1, 1, 1), callback = function(state) ESP.Config.ItemColor = state end })
    ESPSection:AddToggle({ text = 'Health Text', flag = 'espHealthText', callback = function(state) ESP.Config.HealthText = state end })

    ESPSection:AddToggle({ text = 'Health Bars', flag = 'espHealthBars', callback = function(state) ESP.Config.HealthBar = state end })
        :AddColor({ flag = 'espLowHealthColor', tip = 'Low Health Color', color = Color3.new(1, 0, 0), callback = function(state) ESP.Config.LowHealthColor = state end })
        :AddColor({ flag = 'espNormalHealthColor', tip = 'Normal Health Color', color = Color3.new(0, 1, 0), callback = function(state) ESP.Config.NormalHealthColor = state end })

    ESPSection:AddToggle({ text = 'Out Of View Arrows', flag = 'oovArrows', callback = function(state) ESP.Config.Arrows = state end })
        :AddSlider({ text = 'Radius', flag = 'oovArrowRadius', value = 100, min = 50, max = 1000, callback = function(state) ESP.Config.ArrowRadius = state end })
        :AddColor({ text = 'Color', flag = 'oovArrowColor', color = Color3.new(1, 1, 1), trans = 0.7, callback = function(state)
            ESP.Config.ArrowColor = state
            ESP.Config.ArrowOpacity = (1 - Cheat.Library.flags['oovArrowColor Transparency'])
        end })

    ESPSection:AddToggle({ text = 'Distance Check', flag = 'espDistanceCheck', callback = function(state) ESP.Config.DistanceCheck = state end })
        :AddSlider({ text = 'Maximum Distance', flag = 'espMaxDistance', value = 2000, min = 50, max = 10000, callback = function(state) ESP.Config.MaximumDistance = state end })

    -- // Visuals Settings
    local VisualsSettingsSection = LeftSide:AddSection('Visuals Settings')

    local checkTarget = LPH_NO_VIRTUALIZE(function()
        ESP.Config.Target = nil

        if (not playerClass.Character) or (not playerClass.Character.EquippedItem) then
            return
        end

        -- // Aimbot
        if (Cheat.Library.flags.aimbotEnabled and Cheat.Library.flags.aimbotBind and playerClass.Character.EquippedItem.Type == 'Firearm') then
            local target = Targeting:GetAimbotTarget(
                Cheat.AimbotFOV.Position,
                Cheat.AimbotFOV.Radius,
                (Cheat.Library.flags.aimbotDistanceCheck and Cheat.Library.flags.aimbotMaximumDistance),
                Cheat.Library.flags.aimbotTargetPart,
                Cheat.Library.flags.aimbotVisibleCheck
            )

            if (target) then
                ESP.Config.Target = Players:GetPlayerFromCharacter(target.Parent)
                return
            end
        end

        -- // Silent Aim
        if (Cheat.Library.flags.silentAimEnabled and playerClass.Character.EquippedItem.Type == 'Firearm') then
            local target = Targeting:GetAimbotTarget(
                Cheat.SilentFOV.Position,
                Cheat.SilentFOV.Radius,
                (Cheat.Library.flags.silentDistanceCheck and Cheat.Library.flags.silentMaximumDistance),
                Cheat.Library.flags.silentTargetPart,
                Cheat.Library.flags.silentVisibleCheck
            )

            if (target) then
                ESP.Config.Target = Players:GetPlayerFromCharacter(target.Parent)
                return
            end
        end

        -- // Kill Aura
        if (Cheat.Library.flags.killAura) and (playerClass.Character.EquippedItem.Type == 'Melee' or Cheat.Library.flags.killAuraSilent) then
            local target = Targeting:GetTarget(15)

            if (target) then
                ESP.Config.Target = Players:GetPlayerFromCharacter(target)
                return
            end
        end
    end)

    local changeFonts = LPH_NO_VIRTUALIZE(function(newFont)
        -- // ESP Fonts
        ESP.Config.Font = newFont

        for _, espInstance in next, ESP.Registry do
            for _, espObject in next, espInstance do
                if (typeof(espObject) == 'Instance') or (not getrenderproperty(espObject, 'Text')) then
                    continue
                end

                espObject.Font = Drawing.Fonts[newFont]
            end
        end

        -- // Corpse ESP Fonts
        for _, espObject in next, corpseESPs do
            espObject.Font = Drawing.Fonts[newFont]
        end

        -- // Vehicle ESP Fonts
        for _, espObject in next, vehicleEsps do
            espObject.Font = Drawing.Fonts[newFont]
        end

        -- // Zombie ESP Fonts
        for _, espObject in next, zombieESPs do
            espObject.Font = Drawing.Fonts[newFont]
        end

        -- // Item ESP Fonts
        for _, data in next, itemEsps do
            data.Text.Font = Drawing.Fonts[newFont]
        end

        -- // Event ESP Fonts
        for _, data in next, eventESPs do
            data.Text.Font = Drawing.Fonts[newFont]
        end

        -- // Container ESP Fonts
        for _, data in next, groupDrawingObjects do
            if (not data) then
                -- // since data can be false sometimes
                continue
            end

            data.Text.Font = Drawing.Fonts[newFont]
        end

        -- // Random Text Objects
        for _, text in next, Cheat.TextObjects do
            text.Font = Drawing.Fonts[newFont]
        end

        -- // Notification Font
        Notifications.Font = newFont
    end)

    VisualsSettingsSection:AddList({ text = 'Font', flag = 'drawingFont', values = Cheat.Fonts, value = 'Plex', callback = changeFonts })
    VisualsSettingsSection:AddToggle({ text = 'Highlight ESP Target', tip = 'Highlights the target of Aimbot/SilentAim/KillAura on ESP', flag = 'highlightESPTarget', callback = function(state) if (not state) then ESP.Config.Target = nil end end })
        :AddColor({ flag = 'highlightESPTargetColor', tip = 'Color', color = Color3.new(1, 0, 0), callback = function(state) ESP.Config.TargetColor = state end })

    VisualsSettingsSection:AddToggle({ text = 'Highlight Visible Players', tip = 'Highlights visible players on ESP', flag = 'higlightVisibleESP', callback = function(state) ESP.Config.VisibleColorEnabled = state end })
        :AddColor({ flag = 'visibleESPColor', tip = 'Color', color = Color3.new(1, 0, 0), callback = function(state) ESP.Config.VisibleColor = state end })

    VisualsSettingsSection:AddToggle({ text = 'Dynamic ESP Transparency', tip = 'ESP Objects get more transparent the farther they are', flag = 'espDistanceTransparency', callback = function(state) ESP.Config.DynamicTransparency = state end })
    VisualsSettingsSection:AddToggle({ text = 'Update FPS', tip = 'Limit the rate at which visuals are updated, can improve frames. Lower amounts will make it appear choppier', flag = 'visualsUpdateLimiter' })
        :AddSlider({ text = 'Frame Rate', flag = 'visualsUpdateFPS', value = 40, min = 25, max = 240 })

    -- // Chams
    local ChamSection = LeftSide:AddSection('Chams')

    ChamSection:AddToggle({ text = 'Enabled', flag = 'chamsEnabled', tip = 'Player ESP must also be enabled', callback = function(state) ESP.Config.Chams = state end })
        :AddColor({ text = 'Outline Color', flag = 'chamsOutlineColor', tip = 'Outline Color', color = Color3.new(1, 1, 1), trans = 1, callback = function(state)
            ESP.Config.ChamOutlineColor = state
            ESP.Config.ChamOutlineTransparency = Cheat.Library.flags['chamsOutlineColor Transparency']
        end }):AddColor({ text = 'Fill Color', flag = 'chamsFillColor', tip = 'Fill Color', color = Color3.new(1, 1, 1), trans = 0.5, callback = function(state)
            ESP.Config.ChamFillColor = state
            ESP.Config.ChamFillTransparency = Cheat.Library.flags['chamsFillColor Transparency']
        end })

    ChamSection:AddList({ text = 'Depth Mode', flag = 'chamsDepthMode', values = {'AlwaysOnTop', 'Occluded'}, callback = function(state)
        ESP.Config.ChamDepthMode = Enum.HighlightDepthMode[state]
    end })

    -- // Tracers
    local TracerSection = LeftSide:AddSection('Tracers')

    TracerSection:AddToggle({ text = 'Enabled', flag = 'tracersEnabled', tip = 'Player ESP must also be enabled', callback = function(state) ESP.Config.Tracers = state end }):AddBind({ flag = 'tracerBind', callback = function(state) Cheat.Library.options.tracersEnabled:SetState(state) end })
    TracerSection:AddColor({ text = 'Tracer Color', flag = 'tracerColor', color = Color3.new(1, 1, 1), trans = 0.7, callback = function(state)
        ESP.Config.TracerColor = state
        ESP.Config.TracerOpacity = (1 - Cheat.Library.flags['tracerColor Transparency'])
    end })

    -- // Vehicle ESP
    local VehicleESPSection = LeftSide:AddSection('Vehicle ESP')
    local vehicleCleaner = Cleaner.new()

    VehicleESPSection:AddToggle({ text = 'Enabled', flag = 'vehicleESPEnabled', callback = function(state)
        vehicleCleaner:Clean()

        if (state) then
            vehicleCleaner:AddConnection(workspace.Vehicles.Spawned.ChildAdded:Connect(vehicleESP))
            vehicleCleaner:AddConnection(workspace.Vehicles.Spawned.ChildRemoved:Connect(function(vehicle)
                if (not vehicleEsps[vehicle]) then
                    return
                end
        
                local name = vehicleEsps[vehicle]
        
                vehicleEsps[vehicle] = nil
                name:Remove()
                name = nil
            end))

            for _, vehicle in next, workspace.Vehicles.Spawned:GetChildren() do
                if (vehicleEsps[vehicle]) then
                    continue
                end

                vehicleESP(vehicle)
            end
        else
            destroyVehicleESPs()
        end
    end }):AddBind({ flag = 'vehicleESPBind', callback = function(state) Cheat.Library.options.vehicleESPEnabled:SetState(state) end })

    VehicleESPSection:AddToggle({ text = 'Vehicle Names', flag = 'vehicleNames' }):AddColor({ color = Color3.new(1, 1, 1), flag = 'vehicleNamesColor' })
    VehicleESPSection:AddToggle({ text = 'Vehicle Distance', flag = 'vehicleESPShowDistance' })
    VehicleESPSection:AddToggle({ text = 'Maximum Distance', flag = 'vehicleESPMaxDist' }):AddSlider({ text = 'Distance', flag = 'vehicleESPDistance', value = 1500, min = 0, max = 10000 })

    -- // Item ESP
    local ItemESPSection = LeftSide:AddSection('Item ESP')
    local itemCleaner = Cleaner.new()

    ItemESPSection:AddToggle({ text = 'Enabled', flag = 'itemESPEnabled', callback = LPH_NO_VIRTUALIZE(function(state)
        itemCleaner:Clean()
        
        if (state) then
            for _, v in next, workspace.Loot:GetDescendants() do
                if (itemEsps[v]) then
                    continue
                end

                itemESP(v)
            end

            for _, v in next, workspace.Loot:GetChildren() do
                itemCleaner:AddConnection(v.ChildAdded:Connect(itemESP))
            end
        else
            destroyItemESPs()
        end
    end)}):AddList({ flag = 'itemESPType', multiselect = true, values = itemTypes, max = #itemTypes })
        :AddBind({ flag = 'itemESPBind', callback = function(state) Cheat.Library.options.itemESPEnabled:SetState(state) end })

    ItemESPSection:AddList({ text = 'Rarity', flag = 'itemESPRarity', values = {'Any', 'Rare Only'} })
    ItemESPSection:AddToggle({ text = 'Item Name', flag = 'itemESPName' })
    ItemESPSection:AddToggle({ text = 'Item Type', flag = 'itemESPTypeEnabled' })
    ItemESPSection:AddToggle({ text = 'Item Distance', flag = 'itemESPDistance' })
    ItemESPSection:AddToggle({ text = 'Maximum Distance', flag = 'itemESPDistanceCheck' }):AddSlider({ text = 'Distance', flag = 'itemESPMaxDistance', value = 1500, min = 0, max = 10000 })

    for _, itemType in next, itemTypes do
        ItemESPSection:AddColor({
            text = itemType,
            flag = itemType .. 'Color',
            Color = Color3.new(1, 1, 1),
        })
    end

    -- // Event ESP
    local EventESPSection = LeftSide:AddSection('Event ESP')
    local eventCleaner = Cleaner.new()

    EventESPSection:AddToggle({ text = 'Enabled', flag = 'eventESPEnabled', callback = LPH_NO_VIRTUALIZE(function(state)
        eventCleaner:Clean()

        if (state) then
            eventCleaner:AddConnection(workspace.Map.Shared.Randoms.ChildAdded:Connect(function(event)
                if (event.ClassName ~= 'CFrameValue') then
                    return
                end
        
                eventESP(event)
            end))
        
            eventCleaner:AddConnection(workspace.Map.Shared.Randoms.ChildRemoved:Connect(function(event)
                if (event.ClassName ~= 'CFrameValue') then
                    return
                end
        
                local eventData = eventESPs[event]
        
                eventESPs[event] = nil
                eventData.Text:Remove()
                table.clear(eventData)
            end))

            for _, event in next, workspace.Map.Shared.Randoms:GetChildren() do
                if (event.ClassName ~= 'CFrameValue') or (eventESPs[event]) then
                    continue
                end
        
                eventESP(event)
            end
        else
            destroyEventESPs()
        end
    end) }):AddBind({ flag = 'eventESPBind', callback = function(state) Cheat.Library.options.eventESPEnabled:SetState(state) end })

    EventESPSection:AddToggle({ text = 'Names', flag = 'eventESPNames' }):AddColor({ flag = 'eventESPNamesColor', Color = Color3.new(1, 1, 1) })
    EventESPSection:AddToggle({ text = 'Distance', flag = 'eventESPDistance' })
    EventESPSection:AddToggle({ text = 'Maximum Distance', flag = 'eventESPDistanceCheck' }):AddSlider({ text = 'Distance', flag = 'eventESPMaxDistance', value = 1500, min = 0, max = 10000 })

    -- // Add Event Names
    local eventNames = {}

    for _, event in next, ReplicatedStorage.Chunking.RandomEventModels:GetChildren() do
        table.insert(eventNames, event.Name)
    end

    EventESPSection:AddList({ text = 'Events', flag = 'eventESPType', multiselect = true, values = eventNames, max = 12 })

    -- // Container ESP
    local ContainerESPSection = LeftSide:AddSection('Container ESP')

    ContainerESPSection:AddToggle({ text = 'Enabled', flag = 'containerESPEnabled', callback = function(state)
        if (state) then
            return
        end

        for i, drawings in next, groupDrawingObjects do
            if (not drawings) then
                continue
            end

            drawings.Text:Remove()
            groupDrawingObjects[i] = nil
        end
        
        table.clear(groupDrawingObjects)
        table.clear(ongoingQueries)
        table.clear(isFetched)
        table.clear(oldGroups)
    end }):AddBind({ flag = 'containerESPBind', callback = function(state) Cheat.Library.options.containerESPEnabled:SetState(state) end })

    ContainerESPSection:AddToggle({ text = 'Show Empty', flag = 'containerESPShowEmpty' })
    ContainerESPSection:AddToggle({ text = 'Names', flag = 'containerESPNames' }):AddColor({ flag = 'containerESPNamesColor', Color = Color3.new(1, 1, 1), trans = 1 })

    -- // Zombie ESP
    local ZombieESPSection = LeftSide:AddSection('Zombie ESP')
    local zombieCleaner = Cleaner.new()

    ZombieESPSection:AddToggle({ text = 'Enabled', flag = 'zombieESPEnabled', callback = function(state)
        zombieCleaner:Clean()
        
        if (state) then
            zombieCleaner:AddConnection(workspace.Zombies.Mobs.ChildAdded:Connect(zombieESP))
            zombieCleaner:AddConnection(workspace.Zombies.Mobs.ChildRemoved:Connect(function(zombie)
                local name = zombieESPs[zombie]
        
                zombieESPs[zombie] = nil
                name:Remove()
                name = nil
            end))

            for _, zombie in next, workspace.Zombies.Mobs:GetChildren() do
                if (zombieESPs[zombie]) then
                    continue
                end

                zombieESP(zombie)
            end
        else
            destroyZombieESPs()
        end
    end }):AddBind({ flag = 'zombieESPBind', callback = function(state) Cheat.Library.options.zombieESPEnabled:SetState(state) end })

    ZombieESPSection:AddToggle({ text = 'Boss Zombies Only', flag = 'zombieESPBosses' })
    ZombieESPSection:AddToggle({ text = 'Names', flag = 'zombieESPNames' }):AddColor({ flag = 'zombieESPNamesColor', Color = Color3.new(1, 1, 1) })
    ZombieESPSection:AddToggle({ text = 'Distance', flag = 'zombieESPDistance' })
    ZombieESPSection:AddToggle({ text = 'Maximum Distance', flag = 'zombieESPDistanceCheck' }):AddSlider({ text = 'Distance', flag = 'zombieESPMaxDistance', value = 1500, min = 0, max = 10000 })

    -- // Corpse ESP
    local CorpseESPSection = LeftSide:AddSection('Corpse ESP')
    local corpseCleaner = Cleaner.new()

    CorpseESPSection:AddToggle({ text = 'Enabled', flag = 'corpseESPEnabled', callback = function(state)
        corpseCleaner:Clean()

        if (state) then
            corpseCleaner:AddConnection(workspace.Corpses.ChildAdded:Connect(function(corpse)
                if (corpse.Name == 'Zombie') then
                    return
                end
        
                corpseESP(corpse)
            end))
        
            corpseCleaner:AddConnection(workspace.Corpses.ChildRemoved:Connect(function(corpse)
                if (corpse.Name == 'Zombie') then
                    return
                end
        
                local name = corpseESPs[corpse]
        
                corpseESPs[corpse] = nil
                name:Remove()
                name = nil
            end))
        
            for _, corpse in next, workspace.Corpses:GetChildren() do
                if (corpse.Name == 'Zombie') or (corpseESPs[corpse]) then
                    continue
                end
        
                corpseESP(corpse)
            end
        else
            destroyCorpseESPs()
        end
    end }):AddBind({ flag = 'corpseESPBind', callback = function(state) Cheat.Library.options.corpseESPEnabled:SetState(state) end })
    
    CorpseESPSection:AddToggle({ text = 'Names', flag = 'corpseESPNames' }):AddColor({ flag = 'corpseESPNamesColor', Color = Color3.new(1, 1, 1) })
    CorpseESPSection:AddToggle({ text = 'Distance', flag = 'corpseESPDistance' })
    CorpseESPSection:AddToggle({ text = 'Maximum Distance', flag = 'corpseESPDistanceCheck' }):AddSlider({ text = 'Distance', flag = 'corpseESPMaxDistance', value = 1500, min = 0, max = 10000 })

    -- // World
    local WorldSection = RightSide:AddSection('Effects')
    local GameLighting = nil
    
    for _, v in next, getgc(true) do
        if type(v) == 'table' and typeof(rawget(v, 'Atmosphere')) == 'Instance' then
            GameLighting = v -- Currently no other way of grabbing it :pensive:
            break
        end
    end

    WorldSection:AddToggle({ text = 'Ambient', flag = 'ambient' }):AddColor({ color = Color3.new(1, 1, 1), flag = 'ambientColor' })
    WorldSection:AddToggle({ text = 'Full Bright', flag = 'fullbright' })

    WorldSection:AddToggle({ text = 'No Damage Tint', flag = 'noDamageTint', tip = 'Removes the tint displayed when are low health', callback = function(state)
        Lighting.DamageFade.Enabled = (not state)
    end })

    WorldSection:AddToggle({ text = 'No Fog', flag = 'noFog', callback = function(state)
        if (state) then
            Lighting.FogEnd = math.huge
            GameLighting.Atmosphere.Parent = nil
        else
            Lighting.FogEnd = 2300

            if (UserSettings:GetSetting('Game Quality', 'Lighting Quality') == 'High') then
                GameLighting.Atmosphere.Parent = Lighting
            end
        end
    end })

    WorldSection:AddToggle({ text = 'Custom Time', flag = 'customTime' })
        :AddSlider({ text = 'Time', flag = 'timeValue', value = 12, min = 0, max = 24 })

    WorldSection:AddToggle({ text = 'Sky Box', flag = 'skybox', callback = function(state) Skybox.Parent = (state and Lighting) or nil end })
        :AddList({ text = 'Sky Boxes', values = Skyboxes, max = 8, flag = 'currentSky', callback = function() for index, value in next, Skyboxes[Cheat.Library.flags.currentSky] do Skybox[index] = value end end })

    WorldSection:AddToggle({ text = 'Custom Lighting Mode', flag = 'customLightMode', callback = function(state)
        if (state) then
            return AR2Lighting:SetMode(Cheat.Library.flags.lightingMode or 'Main Menu')  
        end

        AR2Lighting:SetMode(Cheat.actualLightingMode or 'Main Menu')
    end }):AddList({ text = 'Lighting Mode', flag = 'lightingMode', values = ReplicatedStorage.Lighting.Configs:GetChildren(), callback = function(state)
        if (not Cheat.Library.flags.customLightMode) then
            return
        end

        AR2Lighting:SetMode(state)
    end })

    -- // LocalPlayer
    local PlayerSettings = RightSide:AddSection('LocalPlayer')

    PlayerSettings:AddToggle({ text = 'Material Chams', flag = 'materialChams', callback = updateMaterialChams })
        :AddList({ flag = 'materialChamsMaterial', values = {'ForceField', 'Plastic', 'Glass'} })
        :AddColor({ color = Color3.new(1, 1, 1), flag = 'materialChamsColor' })

    PlayerSettings:AddList({ text = 'Set Paid Hair Color', flag = 'paidHairColor', skipflag = true, tip = 'Use while in Character Creator', values = {"Teal", "White", "Pink", "Red", "Lime", "Blue", "Purple", "Yellow"}, callback = function(state)
        if (not Interface:IsVisible('MainMenu')) then
            return Cheat:notifyError('This can only be used in the Main Menu', 5, true)
        end

        task.defer(Network.Send, Network, 'Set Appearance Hair Color', state)
    end })

    -- // Fake Outfit
    function Cheat:updateOutfit(outfit)
        if (not Cheat.PlayerClass.Character) then
            return
        end

        if (not outfit) then
            local OldOutfit = table.clone(Cheat.PlayerClass.Character.Inventory.Equipment)
            OldOutfit.SkinColor = Cheat.SkinColor

            return Wardrobe:DressFromOutfit(Cheat.PlayerClass.Character.Instance, OldOutfit)
        end

        Wardrobe:DressFromOutfit(Cheat.PlayerClass.Character.Instance, outfit)
    end

    PlayerSettings:AddToggle({ text = 'Fake Outfit', flag = 'fakeOutfit', tip = 'Equips a fake outfit client sided', callback = function(state) task.defer(function()
        if (state) then
            local skinColorIndex = tonumber(typeof(Cheat.Library.flags.outfitSkinColors) == 'string' and Cheat.Library.flags.outfitSkinColors:gsub('[^%d]', '')) or 1
            local skinColor = CreatorData.Body.Colors[skinColorIndex]

            Cheat:updateOutfit({
                Top = Cheat.Library.flags.outfitTop,
                Bottom = Cheat.Library.flags.outfitBottom,
                Hat = Cheat.Library.flags.outfitHat,
                Accessory = Cheat.Library.flags.outfitAccessory,
                Vest = Cheat.Library.flags.outfitVest,
                Belt = Cheat.Library.flags.outfitBelt,
                Backpack = (playerClass.Character and playerClass.Character.Inventory and playerClass.Character.Inventory.Equipment.Backpack),
                SkinColor = skinColor,
            })
        else
            Cheat:updateOutfit()
        end
    end) end }):AddBind({ flag = 'fakeOutfitBind', callback = function(state) Cheat.Library.options.fakeOutfit:SetState(state) end })

    PlayerSettings:AddList({ text = 'Skin Color', flag = 'outfitSkinColors', max = 12, values = {}, callback = function() Cheat.Library.options.fakeOutfit.callback(Cheat.Library.flags.fakeOutfit) end })
    PlayerSettings:AddList({ text = 'Hat', flag = 'outfitHat', max = 12, values = {'None'}, callback = Cheat.Library.options.outfitSkinColors.callback })
    PlayerSettings:AddList({ text = 'Accessory', flag = 'outfitAccessory', max = 12, values = {'None'}, callback = Cheat.Library.options.outfitSkinColors.callback })
    PlayerSettings:AddList({ text = 'Shirt', flag = 'outfitTop', max = 12, values = {'None'}, callback = Cheat.Library.options.outfitSkinColors.callback })
    PlayerSettings:AddList({ text = 'Vest', flag = 'outfitVest', max = 12, values = {'None'}, callback = Cheat.Library.options.outfitSkinColors.callback })
    PlayerSettings:AddList({ text = 'Belt', flag = 'outfitBelt', max = 12, values = {'None'}, callback = Cheat.Library.options.outfitSkinColors.callback })
    PlayerSettings:AddList({ text = 'Pants', flag = 'outfitBottom', max = 12, values = {'None'}, callback = Cheat.Library.options.outfitSkinColors.callback })

    do -- // Populate Dropdowns (CANCER CODE DONT UNMINIMIZE)
        for i, color in next, CreatorData.Body.Colors do
            Cheat.Library.options.outfitSkinColors:AddValue(`Skin Color {i}`)
        end

        for _, item in next, ReplicatedStorage.ItemData['Clothing\r']:GetChildren() do
            if (item.Name:match('Shirt')) then
                Cheat.Library.options.outfitTop:AddValue(item.Name:gsub('\r', ''))

                continue
            end

            Cheat.Library.options.outfitBottom:AddValue(item.Name:gsub('\r', ''))
        end

        for _, item in next, ReplicatedStorage.ItemData['Hats\r']:GetChildren() do
            Cheat.Library.options.outfitHat:AddValue(item.Name:gsub('\r', ''))
        end

        for _, item in next, ReplicatedStorage.ItemData['Accessories\r']:GetChildren() do
            Cheat.Library.options.outfitAccessory:AddValue(item.Name:gsub('\r', ''))
        end

        for _, item in next, ReplicatedStorage.ItemData['Vests\r']:GetChildren() do
            Cheat.Library.options.outfitVest:AddValue(item.Name:gsub('\r', ''))
        end

        for _, item in next, ReplicatedStorage.ItemData['Belts\r']:GetChildren() do
            Cheat.Library.options.outfitBelt:AddValue(item.Name:gsub('\r', ''))
        end
    end

    -- // Misc
    local MiscSection = RightSide:AddSection('Misc')

    MiscSection:AddToggle({ text = 'Map Radar', flag = 'mapRadar', callback = function(state)
        if (state) then
            if (Cheat.AntiCheatDisablerSpoofing) then
                return
            end

            Map:EnableGodview()
        else
            Map:DisableGodview()
        end
    end})

    -- this code is ugly so
    do
        local Map = Interface:Get('Map')
        local MapScript = getfenv(Map.Center).script
        local MapStorage = Interface:GetStorage("Map")

        local MouseUnlock = Resources:FindFrom(Map.Gui, "MouseUnlock")
        local ClipBin = Resources:FindFrom(Map.Gui, "ClipBin")
        local ClipBinUIAspectRatioConstraint = Resources:FindFrom(Map.Gui, "ClipBin.UIAspectRatioConstraint")
        local DragBin = Resources:FindFrom(Map.Gui, "ClipBin.DragBin")
        local LocalMarker = Resources:FindFrom(Map.Gui, "ClipBin.DragBin.LocalMarker")
        local GridLineLabels = Resources:FindFrom(Map.Gui, "ClipBin.DragBin.GridLines.Labels")
        local Locations = Resources:FindFrom(Map.Gui, "ClipBin.DragBin.Locations")
        local SquadMarker = Resources:FindFrom(MapStorage, "SquadMarker")

        local clipBinAspectRatio = ClipBinUIAspectRatioConstraint.AspectRatio

        local oldMapPosition = Map.Gui.Position
        local oldMapSize = Map.Gui.Size

        local oldLocalMarkerSize = LocalMarker.Size
        local oldSquadMarkerSize = SquadMarker.Size

        local oldLocationSizes = {}

        for i, v in next, Locations:GetDescendants() do
            if (v:IsA("ImageLabel")) then
                oldLocationSizes[v] = v.Size
            end
        end

        local function resetMapSize()
            Map.Gui.Position = oldMapPosition
            Map.Gui.Size = oldMapSize

            for i, v in next, Locations:GetDescendants() do
                if (v:IsA("ImageLabel")) then
                    v.Size = oldLocationSizes[v]
                end
            end
            
            GridLineLabels.Visible = true
            
            LocalMarker.Size = oldLocalMarkerSize
            SquadMarker.Size = oldSquadMarkerSize
            
            for i, v in next, DragBin:GetChildren() do
                if (v.Name == "SquadMarker") then
                    v.Size = SquadMarker.Size
                end
            end
        end

        local function setMapSizeByScale(scale)
            Map.Gui.Size = UDim2.new(oldMapSize.X.Scale * scale, oldMapSize.X.Offset * scale, oldMapSize.Y.Scale * scale, oldMapSize.Y.Offset * scale)
            Map.Gui.Position = UDim2.new(1 - Map.Gui.Size.X.Scale, Map.Gui.Position.X.Offset, Map.Gui.Position.Y.Scale, Map.Gui.Position.Y.Offset)

            for i, v in next, Locations:GetDescendants() do
                if (v:IsA("ImageLabel")) then
                    v.Size = UDim2.new(oldLocationSizes[v].X.Scale * scale, oldLocationSizes[v].X.Offset * scale, oldLocationSizes[v].Y.Scale * scale, oldLocationSizes[v].Y.Offset * scale)
                end
            end
            
            LocalMarker.Size = UDim2.new(oldLocalMarkerSize.X.Scale * scale, oldLocalMarkerSize.X.Offset * scale, oldLocalMarkerSize.Y.Scale * scale, oldLocalMarkerSize.Y.Offset * scale)
            SquadMarker.Size = UDim2.new(oldSquadMarkerSize.X.Scale * scale, oldSquadMarkerSize.X.Offset * scale, oldSquadMarkerSize.Y.Scale * scale, oldSquadMarkerSize.Y.Offset * scale)

            for i, v in next, DragBin:GetChildren() do
                if (v.Name == 'SquadMarker') then
                    v.Size = SquadMarker.Size
                end
            end

            GridLineLabels.Visible = false
        end

        local function unzoomMap()
            local xMaxSize = math.ceil(DragBin.Parent.AbsoluteSize.X + 2)
            DragBin.Size = UDim2.fromOffset(xMaxSize, xMaxSize / clipBinAspectRatio)
        end

        local clampMapPosition

        for i, v in next, getupvalues(Map.Center) do
            if (type(v) ~= 'function') or (not islclosure(v)) or (isexecutorclosure(v)) then
                continue
            end

            if (getinfo(v).name == 'clampMapPosition') then
                clampMapPosition = v
                break
            end
        end

        local isVisible = Map.Gui.Visible
        local MapGui = Map.Gui

        -- // TODO: Find a better implementation that doesnt involve hooking metamethods
        -- // These shouldnt be that much of a slowdown - but its still a slowdown.
        local oldNewindex; oldNewindex = hookmetamethod(game, '__newindex', LPH_NO_VIRTUALIZE(function(self, idx, val)
            if (idx == 'Visible') and (self == MapGui) and (not checkcaller()) then
                isVisible = val
            end
    
            return oldNewindex(self, idx, val)
        end))

        local oldIndex; oldIndex = hookmetamethod(game, '__index', LPH_NO_VIRTUALIZE(function(self, idx)
            if (idx == 'Visible') and (self == MapGui) and (not checkcaller()) then
                if (Cheat.AntiCheatDisablerSpoofing) and (getfenv(2).script == MapScript) then
                    return false
                end

                if (Cheat.Library.flags.minimap) and (getfenv(2).script == MapScript) then
                    return true
                end

                return isVisible
            end
    
            return oldIndex(self, idx)
        end))
        
        local oldDragBinSize
        local oldDragBinPosition
        local oldGridLineLetterLabelsPosition
        local oldGridLineNumberLabelsPosition

        local function resetMap()
            resetMapSize()
            unzoomMap()
            clampMapPosition()

            MouseUnlock.Visible = true
            Map.Gui.Visible = isVisible
            
            if (oldDragBinSize) then
                DragBin.Size = oldDragBinSize
            end

            if (oldDragBinPosition) then
                DragBin.Position = oldDragBinPosition
            end

            if (oldGridLineLetterLabelsPosition) then
                GridLineLabels.Letters.Position = oldGridLineLetterLabelsPosition
            end

            if (oldGridLineNumberLabelsPosition) then
                GridLineLabels.Numbers.Position = oldGridLineNumberLabelsPosition
            end
        end

        local minimapConn

        MiscSection:AddToggle({ text = 'Minimap', flag = 'minimap', callback = function(state)
            if minimapConn then
                minimapConn:Disconnect()
            end
            
            if (state) then
                oldDragBinSize = DragBin.Size
                oldDragBinPosition = DragBin.Position
                oldGridLineLetterLabelsPosition = GridLineLabels.Letters.Position
                oldGridLineNumberLabelsPosition = GridLineLabels.Numbers.Position

                local wasVisible = false

                minimapConn = RunService.RenderStepped:Connect(LPH_JIT_MAX(function()
                    if (isVisible) then
                        if (wasVisible) then
                            resetMap()
                        end

                        oldDragBinSize = DragBin.Size
                        oldDragBinPosition = DragBin.Position
                        oldGridLineLetterLabelsPosition = GridLineLabels.Letters.Position
                        oldGridLineNumberLabelsPosition = GridLineLabels.Numbers.Position

                        wasVisible = false

                        return
                    end

                    wasVisible = true

                    if (not Interface:IsVisible("GameMenu", "DeathScreen")) then
                        Map.Gui.Visible = true
                    else
                        Map.Gui.Visible = false
                    end

                    MouseUnlock.Visible = false
                    setMapSizeByScale(0.5)
                    unzoomMap()
                    DragBin.Position = UDim2.fromScale(0, 0)
                    clampMapPosition()
                end))
            else
                resetMap()
            end
        end})
    end

    MiscSection:AddToggle({ text = 'Join/Leave Logs', flag = 'joinLogs' })
    MiscSection:AddToggle({ text = 'Setback Detector', flag = 'setbackDetector', tip = 'Displays a notification when the anticheat teleports you back' })
    MiscSection:AddToggle({ text = 'Hit Logs', flag = 'hitLogs', tip = 'Displays a notification when you do damage to anyone' })
    MiscSection:AddToggle({ text = 'Invalid Logs', flag = 'invalidLogs', tip = 'Displays a notification when your shot is denied by the server' })
    
    MiscSection:AddToggle({ text = 'Hide UI', flag = 'hideUI', callback = function(state)
        Cheat.InterfaceGui.Enabled = (not state)
    end }):AddBind({ flag = 'hideUiBind', callback = function(state) Cheat.Library.options.hideUI:SetState(state) end })

    MiscSection:AddToggle({ text = 'Weapon Skin Changer', tip = 'CLIENT SIDED', flag = 'skinChanger', callback = onSkinChanged })
        :AddList({ text = 'Skin', values = Skins, flag = 'currentSkin', max = 12, callback = onSkinChanged})

    -- // Camera
    local CameraSection = LeftSide:AddSection('Camera')

    CameraSection:AddToggle({ text = 'Custom Camera FOV', flag = 'customCamFOV' })
        :AddSlider({ text = 'Field Of View', flag = 'camFOV', value = 90, min = 40, max = 120 })
        :AddBind({ flag = 'customCamFOVBind', callback = function(state) Cheat.Library.options.customCamFOV:SetState(state) end })

    CameraSection:AddToggle({ text = 'Zoom', flag = 'cameraZoom' })
        :AddSlider({ text = 'Field Of View', flag = 'cameraZoomFOV', value = 30, min = 10, max = 70 })
        :AddBind({ flag = 'cameraZoomBind', mode = 'hold' })

    CameraSection:AddToggle({ text = 'Aspect Ratio', flag = 'cancerAspectRatio', tip = 'i dont know why you would want this' })
        :AddBind({ flag = 'cancerAspectRatioBind', callback = function(state) Cheat.Library.options.cancerAspectRatio:SetState(state) end })
    CameraSection:AddSlider({ text = 'Width', flag = 'aspectRatioWidth', value = 1, min = 0, max = 1, float = 0.01 })
    CameraSection:AddSlider({ text = 'Height', flag = 'aspectRatioHeight', value = 1, min = 0, max = 1, float = 0.01 })

    -- // Bullet Tracer
    local BulletSection = RightSide:AddSection('Bullet Tracers')

    BulletSection:AddToggle({ text = 'Enabled', flag = 'bulletTracers' }):AddColor({ color = Color3.new(1, 1, 1), trans = 0.5, flag = 'bulletTracerColor' })
    BulletSection:AddSlider({ text = 'Life Time', flag = 'bulletTracerTime', value = 0.3, min = 0.1, max = 3, float = 0.1 })

    -- // Crosshair
    local CrosshairSection = RightSide:AddSection('Crosshair')

    CrosshairSection:AddToggle({ text = 'Hide In-Game Crosshair', flag = 'hideRegularCrosshair' })
    CrosshairSection:AddToggle({ text = 'Enabled', flag = 'crosshairEnabled', callback = hideCrosshair })
        :AddColor({ text = 'Crosshair Color', color = Color3.new(1, 1, 1), trans = 1, flag = 'crosshairColor', tip = 'Crosshair Color' })
        :AddColor({ text = 'Crosshair Outline Color', color = Color3.new(0, 0, 0), trans = 1, flag = 'crosshairOutlineColor', tip = 'Outline Color' })
    
    CrosshairSection:AddSlider({ text = 'Size', flag = 'crosshairSize', value = 10, min = 1, max = 50 })
    CrosshairSection:AddSlider({ text = 'Thickness', flag = 'crosshairThickness', value = 1, min = 1, max = 10 })
    CrosshairSection:AddSlider({ text = 'Center Offset', flag = 'crosshairCenterOffset', value = 0, min = 0, max = 100, float = 1 })

    CrosshairSection:AddToggle({ text = 'Spin', flag = 'crosshairSpin' })
        :AddSlider({ text = 'Speed', flag = 'crosshairSpinSpeed', value = 5, min = -20, max = 20 })

    CrosshairSection:AddToggle({ text = 'Magic Bullet Status', flag = 'magicBulletCrosshair', tip = 'Change the crosshair color depending on whether magic bullet can wallbang or not' })
        :AddColor({ text = 'Can Wallbang Color', color = Color3.new(0, 1, 0), flag = 'magicBulletCrosshairColor', tip = 'Can Wallbang Color' })
        :AddColor({ text = 'Can\'t Wallbang Color', color = Color3.new(1, 0, 0), flag = 'magicBulletCrosshairColorCant', tip = 'Can\'t Wallbang Color' })

    -- // Hooks
    Cheat.actualLightingMode = debug.getupvalue(AR2Lighting.SetMode, 1)

    local mainMenuString = LPH_ENCSTR('Main Menu')

    local oldSetMode; oldSetMode = Cheat:hookAndTostringSpoof(AR2Lighting, 'SetMode', LPH_JIT_MAX(function(self, mode)
        if (not checkcaller()) then
            Cheat.actualLightingMode = mode
        end

        if (Cheat.Library.flags.customLightMode) then
            mode = (Cheat.Library.flags.lightingMode or mainMenuString)
        end

        return oldSetMode(self, mode)
    end))
    
    local accessibilityString = LPH_ENCSTR('Accessibility')
    local cameraFOVString = LPH_ENCSTR('Camera FOV')
    local userInterfaceString = LPH_ENCSTR('User Interface')
    local crosshairBehaviorString = LPH_ENCSTR('Crosshair Behavior')
    local hiddenString = LPH_ENCSTR('Hidden')

    local oldGetSetting; oldGetSetting = Cheat:hookAndTostringSpoof(UserSettings, 'GetSetting', LPH_NO_VIRTUALIZE(function(self, index, value)
        if (index == accessibilityString) then --cameraZoom
            if (value == cameraFOVString) then
                if (Cheat.Library.flags.cameraZoom and Cheat.Library.flags.cameraZoomBind) then
                    return Cheat.Library.flags.cameraZoomFOV
                elseif (Cheat.Library.flags.customCamFOV) then
                    return Cheat.Library.flags.camFOV
                end
            end
        elseif (index == userInterfaceString) then
            if (value == crosshairBehaviorString) and (Cheat.Library.flags.hideRegularCrosshair) then
                return hiddenString
            end
        end

        return oldGetSetting(self, index, value)
    end))

    local playHitSound = LPH_NO_VIRTUALIZE(function()
        local soundId = Cheat.Library.flags.hitSoundId

        if (isfile(soundId)) then
            soundId = getcustomasset(soundId)
        else
            soundId = 'rbxassetid://'..soundId
        end

        Cheat:playSound(soundId)
    end)

    -- // Network Event Hooks
    local oldBulletDamage = Cheat.NetworkEvents['Bullet Damage']
    Cheat.NetworkEvents['Bullet Damage'] = LPH_JIT_MAX(function(bulletId, hitPosition, damage, ...)
        local shotId = string.split(tostring(bulletId), ' - ')[1]
        local shot = Cheat.Shots[tonumber(shotId)]

        if (shot) then
            -- // Hitlogs
            if (Cheat.Library.flags.hitLogs) then
                local rayResult = shot.rayResult
                local playerObject = Players:GetPlayerFromCharacter(rayResult:FindFirstAncestor('StarterCharacter'))
                local origin = workspace.CurrentCamera.CFrame.Position
        
                if (playerObject) then
                    task.defer(Notifications.Notify, Notifications, 'Hit ' .. playerObject.Name .. ' in the ' .. rayResult.Name .. ' for ' .. tostring(math.floor(damage)) .. ' damage from ' .. tostring(math.floor((origin - rayResult.Position).Magnitude)) .. ' studs(s)', 3, 'Hit Logs', Color3.fromRGB(84, 144, 255))
                end
            end

            Cheat.Shots[tonumber(shotId)] = nil
        end

        -- // Hit Sound
        if (Cheat.Library.flags.hitSound) then
            Cheat:runTask(playHitSound)
        end

        return oldBulletDamage(bulletId, hitPosition, damage, ...)
    end)

    -- // Watermark
    local watermarkA = Drawing.new('Text')

    watermarkA.Size = 13
    watermarkA.Outline = true
    watermarkA.OutlineColor = Color3.fromRGB(0, 0, 0)
    watermarkA.Color = Color3.fromRGB(255, 0, 0)
    watermarkA.Text = 'A'
    watermarkA.Visible = false
    watermarkA.Font = Drawing.Fonts.Plex
    watermarkA.Transparency = 1

    local watermark = Drawing.new('Text')

    watermark.Size = 13
    watermark.Outline = true
    watermark.OutlineColor = Color3.fromRGB(0, 0, 0)
    watermark.Color = Color3.fromRGB(255, 255, 255)
    watermark.Text = 'RS - ' .. os.date("%b. %d, %Y") .. ' - ' .. Cheat.Version .. (LPH_OBFUSCATED and ' Release' or ' Dev')
    watermark.Visible = false
    watermark.Font = Drawing.Fonts.Plex
    watermark.Transparency = 1

    table.insert(Cheat.TextObjects, watermarkA)
    table.insert(Cheat.TextObjects, watermark)

    -- // Connections
    local hasConnectedString = LPH_ENCSTR(' has connected.')
    local playerJoinString = LPH_ENCSTR('JOIN')
    
    Players.PlayerAdded:Connect(LPH_NO_VIRTUALIZE(function(playerObject: Player)
        ESP:addPlayer(playerObject)
        Prediction:addPlayer(playerObject)
        Cheat:addPlayerToLists(playerObject)

        if (Cheat.Library.flags.joinLogs) then
            Notifications:Notify(playerObject.Name .. hasConnectedString, 5, playerJoinString, Color3.fromRGB(0, 250, 170))
        end

        if (Cheat.Library.flags.mapRadar) and (not Cheat.AntiCheatDisablerSpoofing) then
            Map:DisableGodview()
            Map:EnableGodview()
        end
    end))

    local hasDisconnectedString = LPH_ENCSTR(' has disconnected.')
    local playerLeaveString = LPH_ENCSTR('LEAVE')

    Players.PlayerRemoving:Connect(LPH_NO_VIRTUALIZE(function(playerObject: Player)
        ESP:removePlayer(playerObject)
        Prediction:removePlayer(playerObject)
        Cheat:removePlayerFromLists(playerObject)

        if (Cheat.Library.flags.joinLogs) then
            Notifications:Notify(playerObject.Name .. hasDisconnectedString, 5, playerLeaveString, Color3.fromRGB(250, 70, 70))
        end

        if (Cheat.Library.flags.mapRadar) and (not Cheat.AntiCheatDisablerSpoofing) then
            Map:DisableGodview()
            Map:EnableGodview()
        end
    end))

    RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function(deltaTime: number)
        local camera = workspace.CurrentCamera

        -- // Camera Aspect Ratio
        if (Cheat.Library.flags.cancerAspectRatio) then
            camera.CFrame *= CFrame.new(0, 0, 0, Cheat.Library.flags.aspectRatioWidth, 0, 0, 0, Cheat.Library.flags.aspectRatioHeight, 0, 0, 0, 1)
        end

        -- // World Visuals
        if (Cheat.Library.flags.ambient) then
            Lighting.Ambient = Cheat.Library.flags.ambientColor
            Lighting.OutdoorAmbient = Cheat.Library.flags.ambientColor
        end

        if (Cheat.Library.flags.customTime) then
            Lighting.ClockTime = Cheat.Library.flags.timeValue
        end

        if (Cheat.Library.flags.fullbright) then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        end

        -- // Frame Limiter
        if (Cheat.Library.flags.visualsUpdateLimiter) and (tick() - lastUpdate) < (1 / Cheat.Library.flags.visualsUpdateFPS) then
            return
        end

        lastUpdate = tick()
        debug.profilebegin('ARS Visuals RenderStepped')
        
        -- // Step ESP
        if (ESP.Config.Enabled) then
            if (Cheat.Library.flags.highlightESPTarget) then
                checkTarget()
            end
            
            ESP:renderFrame(deltaTime)
        end

        -- // Render Watermark
        if (Cheat.Library.flags.Watermark) then
            watermarkA.Position = Vector2.new(4, 4)
            watermark.Position = Vector2.new(watermarkA.Position.X + watermarkA.TextBounds.X, 4)

            watermarkA.Visible = true
            watermark.Visible = true
        else
            watermarkA.Visible = false
            watermark.Visible = false
        end
    
        -- // Render FOV Circles (if present)
        if (not Cheat.AimbotOutline) then
            return
        end

        debug.profilebegin('FOV Circles')

        local centerOfScreen = (camera.ViewportSize / 2)
        local cameraFOV = (camera.FieldOfView)
        local cameraFOVSetting = (UserSettings:GetSetting('Accessibility', 'Camera FOV') or 70)

        -- // Silent FOV
        Cheat.SilentFOV.Position = centerOfScreen
        Cheat.SilentOutline.Position = centerOfScreen
        Cheat.SilentFOV.Visible = (Cheat.Library.flags.silentShowFOV and Cheat.Library.flags.silentAimEnabled)
        Cheat.SilentOutline.Visible = Cheat.SilentFOV.Visible

        if (Cheat.Library.flags.silentDynamicFOV) then
            Cheat.SilentFOV.Radius = Math:dynamicRadius(Cheat.Library.flags.silentFOV, cameraFOVSetting, cameraFOV)
            Cheat.SilentOutline.Radius = Cheat.SilentFOV.Radius
        else
            Cheat.SilentFOV.Radius = Cheat.Library.flags.silentFOV
            Cheat.SilentOutline.Radius = Cheat.Library.flags.silentFOV
        end

        -- // Aimbot FOV
        Cheat.AimbotFOV.Position = centerOfScreen
        Cheat.AimbotOutline.Position = centerOfScreen
        Cheat.AimbotFOV.Visible = (Cheat.Library.flags.aimbotShowFOV and Cheat.Library.flags.aimbotEnabled)
        Cheat.AimbotOutline.Visible = Cheat.AimbotFOV.Visible

        if (Cheat.Library.flags.aimbotDynamicFOV) then
            Cheat.AimbotFOV.Radius = Math:dynamicRadius(Cheat.Library.flags.aimbotFOV, cameraFOVSetting, cameraFOV)
            Cheat.AimbotOutline.Radius = Cheat.AimbotFOV.Radius
        else
            Cheat.AimbotFOV.Radius = Cheat.Library.flags.aimbotFOV
            Cheat.AimbotOutline.Radius = Cheat.Library.flags.aimbotFOV
        end

        -- // Triggerbot FOV
        Cheat.TriggerbotFOV.Position = centerOfScreen
        Cheat.TriggerbotOutline.Position = centerOfScreen
        Cheat.TriggerbotFOV.Visible = (Cheat.Library.flags.showTriggerbotFOV and Cheat.Library.flags.triggerbotEnabled)
        Cheat.TriggerbotOutline.Visible = Cheat.TriggerbotFOV.Visible

        debug.profileend()
        debug.profilebegin('Misc Visuals')

        -- // Render Crosshair
        if (Cheat.Library.flags.crosshairEnabled) then
            updateCrosshair()
        end

        -- // Render Other ESPs
        if (Cheat.Library.flags.vehicleESPEnabled) then
            renderVehicleESP()
        end

        if (Cheat.Library.flags.itemESPEnabled) then
            renderItemESP()
        end

        if (Cheat.Library.flags.eventESPEnabled) then
            renderEventESP()
        end

        if (Cheat.Library.flags.zombieESPEnabled) then
            renderZombieESP()
        end
        
        if (Cheat.Library.flags.corpseESPEnabled) then
            renderCorpseESP()
        end

        if (Cheat.Library.flags.containerESPEnabled or Cheat.Library.flags.unlockAura) then
            renderContainerESP()
        end

        debug.profileend()
    end))

    RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
        if (Cheat.Library.flags.materialChams) then
            updateMaterialChams()
        end
    end))

    ReplicationUtility.OnSetback:Connect(function()
        Cheat.ViolationLevel += 1

        if (not Cheat.Library.flags.setbackDetector) then
            return
        end

        Cheat:notifyInfo('Anticheat Setback Detected [VL: '..tostring(Cheat.ViolationLevel)..']', 5)

        if (Cheat.ViolationLevel == (maxViolationLevel - 1)) then
            Cheat:notifyWarn('Next Anticheat Violation or more could kick you!', 10)
            --Notifications:Notify('Next Anticheat Violation will kick you!', 10, 'WARNING', Color3.fromRGB(245, 215, 66))
        end
    end)

    -- // Create ESP Objects
    for _, playerObject: Player in next, Players:GetPlayers() do
        if (playerObject == Players.LocalPlayer) then
            continue
        end

        ESP:addPlayer(playerObject)
        Prediction:addPlayer(playerObject)
    end
end
