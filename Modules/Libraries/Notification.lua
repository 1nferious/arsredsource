local Notifications = {}
Notifications.Font = 'Plex'
Notifications.ChatGui = nil

local yOffset = 15
local defaultPosition = Vector2.new(15, 327)
local watermarkFormat = '[%s]'
local notifs = {}

local Notification = LPH_NO_VIRTUALIZE(function(waittime, text, mode, color)
    task.spawn(function()
        local selfIdx = 0

        for i, v in next, notifs do
            selfIdx = math.max(selfIdx, v)
        end
        
        selfIdx += 1

        table.insert(notifs, selfIdx)
        
        -- // Mode
        local modeShadow = Drawing.new("Text")
        modeShadow.Font = Drawing.Fonts[Notifications.Font]
        -- modeShadow.Font = 2
        modeShadow.Size = 13
        modeShadow.Outline = false
        modeShadow.Color = Color3.fromRGB(0, 0, 0)
        modeShadow.Text = mode
        modeShadow.Visible = true
        modeShadow.Transparency = 0
        -- modeShadow.Position = Vector2.new(14, game:GetService("Players").LocalPlayer.PlayerGui["Interface Main"].Chat.Input.Position.Y.Offset + 26)

        local yPosition = 10
        if (Notifications.ChatGui) then
            yPosition = Notifications.ChatGui:WaitForChild("Input").Position.Y.Offset
        end

        modeShadow.Position = Vector2.new(-10, yPosition + 26) + (Vector2.new(0, 12) * (selfIdx - 1))

        local modeTxt = Drawing.new("Text")
        modeTxt.Font = Drawing.Fonts[Notifications.Font]
        -- modeTxt.Font = 2
        modeTxt.Size = 13
        modeTxt.Outline = false
        modeTxt.Color = color
        modeTxt.Text = mode
        modeTxt.Visible = true
        modeTxt.Transparency = 0
        -- modeTxt.ZIndex = 2
        modeTxt.Position = modeShadow.Position - Vector2.new(1, 1)

        -- // Text
        local textShadow = Drawing.new("Text")
        textShadow.Font = Drawing.Fonts[Notifications.Font]
        -- textShadow.Font = 2
        textShadow.Size = 13
        textShadow.Outline = false
        textShadow.Color = Color3.fromRGB(0, 0, 0)
        textShadow.Text = text
        textShadow.Visible = true
        textShadow.Transparency = 0
        textShadow.Position = modeShadow.Position + Vector2.new(modeShadow.TextBounds.X + 4, 0)

        local textTxt = Drawing.new("Text")
        textTxt.Font = Drawing.Fonts[Notifications.Font]
        -- textTxt.Font = 2
        textTxt.Size = 13
        textTxt.Outline = false
        textTxt.Color = Color3.fromRGB(235, 235, 235)
        textTxt.Text = text
        textTxt.Visible = true
        textTxt.Transparency = 0
        -- textTxt.ZIndex = 2
        textTxt.Position = textShadow.Position - Vector2.new(1, 1)

        for i = 0, 10, 2.5 do
            task.wait()
            modeShadow.Transparency = modeShadow.Transparency + 0.25
            textShadow.Transparency = textShadow.Transparency + 0.25
            modeTxt.Transparency = modeTxt.Transparency + 0.25
            textTxt.Transparency = textTxt.Transparency + 0.25

            modeShadow.Position = Vector2.new(modeShadow.Position.X + i, modeShadow.Position.Y)
            textShadow.Position = Vector2.new(textShadow.Position.X + i, textShadow.Position.Y)
            modeTxt.Position = Vector2.new(modeTxt.Position.X + i, modeTxt.Position.Y)
            textTxt.Position = Vector2.new(textTxt.Position.X + i, textTxt.Position.Y)
        end

        task.wait(tonumber(waittime))

        for i = 1, 0, -0.25 do
            task.wait()
            modeShadow.Transparency = i
            textShadow.Transparency = i
            modeTxt.Transparency = i
            textTxt.Transparency = i
        end
        
        modeShadow:Remove()
        textShadow:Remove()
        modeTxt:Remove()
        textTxt:Remove()
        
        table.remove(notifs, table.find(notifs, selfIdx))
    end)
end)

Notifications.Notify = LPH_NO_VIRTUALIZE(function(self, message: string, lifeTime: number, cheatName: string, cheatColor: Color3?) -- ihaxu fixed my code ✅
    return Notification(lifeTime, message, cheatName, cheatColor or Color3.fromRGB(255, 73, 73))
end)

return Notifications