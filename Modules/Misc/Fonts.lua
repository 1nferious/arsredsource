local Fonts = {}
Fonts.FontData = {}
Fonts.Names = {}

-- // Initialize Fonts
-- function Fonts:Initialize()
--     local drawingFonts = Drawing.Fonts
--     setreadonly(drawingFonts, false)

--     for fontName, fontData in next, Fonts.FontData do
--         local font = Drawing.new('Font', fontName)
--         font.Data = fontData
--         drawingFonts[fontName] = font
--     end

--     setreadonly(drawingFonts, true)
-- end

-- // Font Data
for fontName, fontValue in next, Drawing.Fonts do
    -- // Keep existing fonts (if they dont get overwritten)
    if (table.find(Fonts.Names, fontName)) then
        continue
    end

    table.insert(Fonts.Names, fontName)
end

-- Fonts:Initialize()
return Fonts.Names