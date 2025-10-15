local Effects = {}

-- // Modules
local Math = REQUIRE_MODULE('Modules/Libraries/Math.lua')

-- // Methods
Effects.bulletTracer = LPH_NO_VIRTUALIZE(function(self, origin: Vector3, position: Vector3, transparency: number, color: Color3, lifetime: number)
    local beam = Instance.new('Beam')
    local attachment0 = Instance.new('Attachment')
    local attachment1 = Instance.new('Attachment')

    -- // Attachment Properties
    attachment0.Position = origin
    attachment1.Position = position
    attachment0.Parent = workspace.Terrain
    attachment1.Parent = workspace.Terrain

    -- // Beam Properties
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.Texture = 'rbxassetid://2382169232'
    beam.Transparency = NumberSequence.new(transparency)
    beam.Width0 = 0.2
    beam.Width1 = 0.2
    beam.Color = ColorSequence.new(color)
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Parent = workspace.Terrain
    beam.Enabled = true

    -- // Fade out
    task.delay(lifetime / 2, Math.tweenNumber, Math, transparency, 1, lifetime / 2, function(transparency)
        if (transparency >= 1) then
            beam:Destroy()
            attachment0:Destroy()
            attachment1:Destroy()

            return
        end
        
        beam.Transparency = NumberSequence.new(transparency)
    end)
end)

return Effects