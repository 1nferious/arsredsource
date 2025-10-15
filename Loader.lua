for i,v in next, getconnections(game:GetService('ScriptContext').Error) do -- // :tm:
    v:Disable()
end

if (getgenv().CheatLoaded) then
	return warn('Already Loaded!')
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

-- // Info
local user = 'FloofyExecutioner'
local repository = 'ar2-fucker-v2'
local branch = 'main'
local token = --[[dont leak this by accident! wasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasdwasd wasd wasd wasd]] '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'

local url = string.format('https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1', user, repository, branch)

-- // Priority List
local priority = {
	"Aimbot.lua",
	"CharacterHooks.lua",
}

function from_base64(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- // I honestly forgot how this code really works, so uhh.... lol
-- // Functions
local function httpRequest(url)
	local res = request({
		Url = url,
		Headers = { ['Authorization'] = 'token '..token, ["Accept-Encoding"] = "gzip, deflate" },
		Method = 'GET'
	})

	return res
end

local function getFileContents(url)
	local response = httpRequest(url)
	local decoded = game:GetService('HttpService'):JSONDecode(response.Body)

	return from_base64(decoded.content)
end

local function removeFileFromPath(path)
	local split = string.split(path, '/')
	local newPathString = ''
	
	for i,v in next, split do
		if (i == #split) then
			continue
		end
		
		if (#newPathString < 1) then
			newPathString ..= v
		else
			newPathString ..=  ('/'..v)
		end
	end
	
	return newPathString, split[#split]
end

local function getDirectory(tree, path)
	if (not path) or (#path < 1) then
		return tree
	end

	local currentTable = tree

	for i,v in next, string.split(path, '/') do
		if (not currentTable[v]) then
			return
		end
		
		currentTable = currentTable[v]
	end

	return currentTable
end

local function createDirectory(tree, path, returnTree)
	local currentTable = tree
	
	for i,v in next, string.split(path, '/') do
		if (not currentTable[v]) then
			currentTable[v] = {}
		end
		
		currentTable = currentTable[v]
	end
	
	return (returnTree and tree) or (currentTable)
end

local function newIndexDirectory(tree, path, index, value)
	getDirectory(tree, path)[index] = value
end

local function indexDirectory(tree, path, index)
	return getDirectory(tree, path)[index]
end

local function createTree(blobs)
    local tree = {}
	
	local running = 0

	for i,v in next, blobs do
		running = running + 1

		task.spawn(function()
			local pathWithoutFile, fileName = removeFileFromPath(v.path)

			if (not getDirectory(tree, pathWithoutFile)) then
				createDirectory(tree, pathWithoutFile)
			end

			local moduleFunc = loadstring(getFileContents(v.url), fileName)
			if (not moduleFunc) then
				getgenv().CheatLoaded = false
				warn(fileName, 'has a syntax error')
				error('Loading aborted')
			end

			newIndexDirectory(tree, pathWithoutFile, fileName, moduleFunc)

			running = running - 1
		end)
	end

	repeat task.wait() until running <= 0
	
	return tree
end

local function getBlobs(decoded)
    local newData = {}
	
	for i,v in next, decoded.tree do
		if (v.type ~= 'blob') then
			continue
		end

        if (not string.match(v.path, '.lua')) then
            continue -- // dont waste requests on files we dont even need lol
        end
		
		table.insert(newData, v)
	end
		
	return newData
end

-- // Fetch Repo data
print('Fetching Cheat Files..')

local response = httpRequest(url)
local decoded = game:GetService('HttpService'):JSONDecode(response.Body)

local blobs = getBlobs(decoded)
local tree = createTree(blobs)

-- // Setup Module loader 
local cache = {}

REQUIRE_MODULE = function(modulePath)
    if cache[modulePath] then
        return cache[modulePath]
    end
    
    cache[modulePath] = getDirectory(tree, modulePath)()
    
    return cache[modulePath]
end

getgenv().REQUIRE_MODULE = REQUIRE_MODULE

-- // Main.lua File
local main = tree['main.lua']
if (not main) then return error('main.lua file doesnt exist (SYNTAX ERROR IN MAIN LIKELY)') end

local mainEnv = getfenv(main)
mainEnv.serverStaffList = {54043999, 4500054585, 67066901, 1723600293, 3049037264, 3721721733, 4457065726, 79386569, 3094064128, 4316270497, 4604215175, 4461155626, 82304636, 41508395, 2596467, 75823163, 56883177, 18806896, 4410600, 55763779, 632003541, 455392817, 223533685, 877174744, 82740173, 45049680, 8349871, 83438620, 14429234, 117646470, 54028266, 125196014, 7127890, 601932147, 8478698, 14849200, 15265764, 122368002, 10437569, 1603397436, 119539693, 462034, 35044794, 34890700, 58862337, 240436533, 40143471, 128753084, 155816395, 19385253, 97840372, 7766698, 96110061, 15596078, 67241478, 4418132, 63168852, 35794547, 37742885, 48159582, 126196024, 56114350, 28605037, 859474, 18880731, 63245130, 57655443, 43547233, 10717044, 3645709, 2548840, 22303673, 281519}

-- // Features
if (tree.Features) then
    mainEnv.CHEAT_LOAD_PRIORITY = priority
    mainEnv.CHEAT_FEATURES = tree.Features
    tree.Features = nil
end

-- // Run Main
main()
