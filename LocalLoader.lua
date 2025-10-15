-- made this so I can put the rest of the files in workspace and just execute this so I can test faster instead of having to push repeatedly

for i,v in next, getconnections(game:GetService('ScriptContext').Error) do -- // :tm:
    v:Disable()
end

if (getgenv().CheatLoaded) then
	return print('Already Loaded!')
end

getgenv().CheatLoaded = true

if (not LPH_OBFUSCATED) then
    LPH_JIT = function(...) return ... end
    LPH_JIT_MAX = function(...) return ... end
    LPH_NO_VIRTUALIZE = function(...) return ... end
    LPH_ENCSTR = function(...) return ... end
    LPH_ENCNUM = function(...) return ... end
    LPH_NO_UPVALUES = function(...) return ... end
end

-- // Priority List
local priority = {
	"Aimbot.lua",
    "CharacterHooks.lua",
}

-- // Setup Module loader
local directory = 'ars.red-main/'
local cache = {}

REQUIRE_MODULE = function(modulePath)
    if cache[modulePath] then
        return cache[modulePath]
    end
    
    local loadFunc = loadstring(readfile(directory..modulePath), modulePath)
    if (not loadFunc) then print(modulePath, 'has a syntax error') end
    cache[modulePath] = loadFunc()
    
    return cache[modulePath]
end

getgenv().REQUIRE_MODULE = REQUIRE_MODULE

-- // Main.lua File
local main = loadstring(readfile(directory..'main.lua'), 'main.lua')
if (not main) then return error('main.lua file doesnt exist (SYNTAX ERROR IN MAIN LIKELY)') end

local mainEnv = getfenv(main)
mainEnv.serverStaffList = {54043999, 4500054585, 67066901, 1723600293, 3049037264, 3721721733, 4457065726, 79386569, 3094064128, 4316270497, 4604215175, 4461155626, 82304636, 41508395, 2596467, 75823163, 56883177, 18806896, 4410600, 55763779, 632003541, 455392817, 223533685, 877174744, 82740173, 45049680, 8349871, 83438620, 14429234, 117646470, 54028266, 125196014, 7127890, 601932147, 8478698, 14849200, 15265764, 122368002, 10437569, 1603397436, 119539693, 462034, 35044794, 34890700, 58862337, 240436533, 40143471, 128753084, 155816395, 19385253, 97840372, 7766698, 96110061, 15596078, 67241478, 4418132, 63168852, 35794547, 37742885, 48159582, 126196024, 56114350, 28605037, 859474, 18880731, 63245130, 57655443, 43547233, 10717044, 3645709, 2548840, 22303673, 281519}

mainEnv.CHEAT_LOAD_PRIORITY = priority
mainEnv.CHEAT_FEATURES = {}

local localDir = directory..'Features/'
for i, v in next, listfiles(localDir) do
    CHEAT_FEATURES[v:sub(localDir:len() + 1)] = loadstring(readfile(v), v)
    if (not CHEAT_FEATURES[v:sub(localDir:len() + 1)]) then print(v, 'has a syntax error') end
end
-- // Run Main
main()
