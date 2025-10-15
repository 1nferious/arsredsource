-- // ARS
for _, connection in next, getconnections(game:GetService('ScriptContext').Error) do
    connection:Disable()
end

-- // Variables
local Cheat = { Version = 'v3.1.0', Name = 'ars.red', LoadedMessage = 'ars.red has loaded in %s second(s) // %s', LoadStarted = os.clock() }
local Services = setmetatable({}, {__index = function(self, index) return game:GetService(index) end})
local LocalPlayer = Services.Players.LocalPlayer
local Framework = require(game:GetService('ReplicatedFirst').Framework)

local retardedLoadPhrases = {
    'hutch try not to use 8gb of memory challenge (99% impossible)',
    'hutch try to make an effective movement anti cheat (99% impossible)',
    'hutch spending months on an anticheat update, just to watch it get completely bypassed within a day',
    '"You have been kicked from the experience: Cream of Mushroom" :nerd:',
    'hutch finding out his new anticheat updates were bypassed on fluxus',
    'Bypassing hutch\'s pseudo-anticheat since 2018:TM:',
    '"it\'s just incremental anti cheat updates" LMH_Hutch 2022',
}

-- // Disable Client AC
local tostringSpoof = {}

do 
    local fakeData = {}
    local fakeDataIndexes = { "Classes", "Libraries", "Configs" }
    
    for i, v in next, fakeDataIndexes do
        fakeData[v] = {}
        for i2, v2 in next, Framework[v] do
            fakeData[v][i2] = {}
            if type(v2) == "table" then
                for i3, v3 in next, v2 do
                    if type(v3) == "function" or type(v3) == "table" then
                        fakeData[v][i2][i3] = tostring(v3)
                    end
                end
            end
        end
    end
    
    -- local oldGameNewIndex
    -- oldGameNewIndex = hookmetamethod(game, "__newindex", function(self, idx, val)
    --     if ar2_fucker.ac_disabler_subthread and idx == "Visible" and self == VehicleGui and not checkcaller() then
    --         return
    --     end

    --     return oldGameNewIndex(self, idx, val)
    -- end)
    
    local oldGameNamecall
    oldGameNamecall = hookmetamethod(game, "__namecall", LPH_NO_VIRTUALIZE(function(self, ...)
        -- // NOTE: I tested select()'s speed, its faster than packing the args into a table and getting length
        if (getnamecallmethod() ~= 'FireServer') or (select('#', ...) ~= 1) then
            return oldGameNamecall(self, ...)
        end

        local argument = select(1, ...)
        if (type(argument) ~= 'table') then
            return oldGameNamecall(self, ...)
        end

        argument = fakeData

        return oldGameNamecall(self, argument)
    end))

    local dotMethod = LPH_ENCSTR("Dot")
    local fakeDot = LPH_ENCNUM(1337)
    local dotTraceMatch = LPH_ENCSTR(".Libraries.Cameras")
    local tracebackFunc = debug.traceback
    
    local oldVector3Namecall
    oldVector3Namecall = hookmetamethod(Vector3.new(), "__namecall", LPH_NO_VIRTUALIZE(function(self, ...)
        local method = getnamecallmethod()

        if method == dotMethod and tracebackFunc():find(dotTraceMatch, 1, true) then
            return fakeDot
        end

        return oldVector3Namecall(self, ...)
    end))

    local oldTostring
    oldTostring = hookfunction(tostring, LPH_NO_VIRTUALIZE(function(v, ...)
        if tostringSpoof[v] then
            return tostringSpoof[v]
        end
        return oldTostring(v, ...)
    end))
    
    local oldXPCall
    oldXPCall = hookfunction(xpcall, LPH_NO_VIRTUALIZE(function(...)
        local oldIdentity = getthreadidentity()
        setthreadidentity(2)
        local ret = {oldXPCall(...)}
        setthreadidentity(oldIdentity)
        return table.unpack(ret)
    end))
end

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- // Modules
local Notification = REQUIRE_MODULE('Modules/Libraries/Notification.lua')
local Library = REQUIRE_MODULE('Modules/Libraries/UiLib.lua')
local Signal = REQUIRE_MODULE('Modules/Classes/FastSignal.lua')
local ReplicationUtility = REQUIRE_MODULE('Modules/Libraries/ReplicationUtility.lua')
local Fonts = REQUIRE_MODULE('Modules/Misc/Fonts.lua')
Cheat.Fonts = Fonts

-- local PingEvent = game:GetService('RobloxReplicatedStorage').GetServerType

if (not Framework:IsLoaded()) then
    Notification:Notify('Waiting for the framework to load...', 5, 'INFO', Color3.fromRGB(0, 170, 250))
    Framework:WaitForLoaded()
end

if (LocalPlayer.PlayerGui:FindFirstChild('LoadingGui')) then
    Notification:Notify('Waiting for the game to load...', 5, 'INFO', Color3.fromRGB(0, 170, 250))
    repeat task.wait() until (not LocalPlayer.PlayerGui:FindFirstChild('LoadingGui'))
end

local Network = Framework.require('Libraries', 'Network')
local AR2Players = Framework.require('Classes', 'Players')

if (not AR2Players.get()) then
    Notification:Notify('Waiting for the player to load...', 5, 'INFO', Color3.fromRGB(0, 170, 250))
    repeat task.wait() until AR2Players.get()
end

local World = Framework.require('Libraries', 'World')
local Cameras = Framework.require('Libraries', 'Cameras')
local Interface = Framework.require('Libraries', 'Interface')

-- Interface:GetGui('NetworkDebug'):Destroy()
Notification.ChatGui = Interface:GetPlayerGui():FindFirstChild("Chat")

-- // Setup UI Lib
Library.Cheat = Cheat
Library.AimbotTab = Library:AddTab('Aimbot')
Library.VisualsTab = Library:AddTab('Visuals')
Library.BlatantTab = Library:AddTab('Rage')
Library.TeleportTab = Library:AddTab('Teleport')
Library.MiscTab = Library:AddTab('Misc')

-- // Staff Database
Cheat.Staff = serverStaffList or {} -- served by the whitelist server
Cheat.StaffGroups = {15434910, 4110568}

-- // Set Cheat Values
Cheat.PlayerClass = AR2Players.get()
Cheat.AllFireModesChanged = Signal.new()
Cheat.SkinColor = Color3.fromRGB(255, 207, 170)
Cheat.RealVelocity = Vector3.zero
Cheat.LastState = 'Walking'
Cheat.OriginalLastState = 'Walking'
Cheat.NextSwing = 0
Cheat.LastChat = 0
Cheat.ViolationLevel = 0
Cheat.QueuedMouseDelta = 0
Cheat.NoFallTime = math.huge
Cheat.NoFallPackets = 0
Cheat.Shots = {}
Cheat.Tasks = {}
Cheat.TextObjects = {}
Cheat.PlayerLists = {}
Cheat.Library = Library
Cheat.Framework = Framework
Cheat.InterfaceGui = Interface:GetPlayerGui()
Cheat.NetworkEventsRaw = debug.getupvalue(Network.Add, 1)
Cheat.OriginalNetworkEventsRaw = deepcopy(Cheat.NetworkEventsRaw)
Cheat.NetworkEvents = Cheat.NetworkEventsRaw
Cheat.OriginalNetworkEvents = Cheat.OriginalNetworkEventsRaw
-- Cheat.NetworkEvents = setmetatable({}, {__index = function(self, index)
--     if (game.PlaceId == 10077968348) then 
--         return Cheat.NetworkEventsRaw[index..'\r'] -- // hutch moment
--     else
--         return Cheat.NetworkEventsRaw[index]
--     end
-- end, __newindex = function(self, index, value) -- // 🤯
--     if (game.PlaceId == 10077968348) then 
--         Cheat.NetworkEventsRaw[index..'\r'] = value
--     else
--         Cheat.NetworkEventsRaw[index] = value
--     end
-- end})
-- Cheat.OriginalNetworkEvents = setmetatable({}, {__index = function(self, index)
--     if (game.PlaceId == 10077968348) then 
--         return Cheat.OriginalNetworkEvents[index..'\r'] -- // hutch moment
--     else
--         return Cheat.OriginalNetworkEvents[index]
--     end
-- end, __newindex = function(self, index, value) -- // 🤯
--     if (game.PlaceId == 10077968348) then 
--         Cheat.OriginalNetworkEvents[index..'\r'] = value
--     else
--         Cheat.OriginalNetworkEvents[index] = value
--     end
-- end})

-- // for most ban packets, put them under CrashBanPackets. if the ban attempt doesnt crash your game after, put it under BanPackets
Cheat.CrashBanPackets = { -- // https://media.giphy.com/media/IeuHFWK3TGZ4ZtNwhp/giphy.gif
    'Camera CFrame Report',
    'Zombie Pushback Force Request',
    'Movestate Sync Request',
    'Update Character Position',
    'Map Icon History Sync',
    'Playerlist Staff Icon Get',
    'Request Physics State Sync',
    'Inventory Sync Request',
    'Wardrobe Resync Request',
    'Door Interact ',
    'Sorry Mate, Wrong Path :/',
    'Chat Message Send',
    'Ping Return',
}

Cheat.BanPackets = {
    'Bullet Impact Interaction', -- // Bighead
    'Animation State Fetch',
}

function Cheat:hookAndTostringSpoof(t, index, hookFunction) -- // Example: hookAndTostringSpoof(Network, 'Send', function() end)
    local oldFunction = t[index]

    tostringSpoof[hookFunction] = tostring(oldFunction)
    t[index] = hookFunction

    return oldFunction
end

Cheat.networkWait = LPH_JIT_MAX(function(self, pings)
    Network:Fetch('Get Server Debug State')

    return true
end)

function Cheat:runTask(func, ...)
    -- // this function is for when you have thread identity issues
    table.insert(Cheat.Tasks, {
        func = func,
        args = {...},
    })
end

function Cheat:getPlayer(playerName)
    for _, playerObject in next, Services.Players:GetPlayers() do
        if (playerObject.Name ~= playerName) then
            continue
        end

        return playerObject
    end
end

function Cheat:addPlayerToLists(playerObject)
    for _, v in next, Cheat.PlayerLists do
        v:AddValue(playerObject.Name)
    end
end

function Cheat:removePlayerFromLists(playerObject)
    for _, v in next, Cheat.PlayerLists do
        v:RemoveValue(playerObject.Name)
    end
end

function Cheat:requireFix(module)
    local oldIdentity = getthreadidentity()

    setthreadidentity(2)

    local module = require(module)

    setthreadidentity(oldIdentity)

    return module
end

function Cheat:getPing()
    local oldIdentity = getthreadidentity()

    setthreadidentity(8)

    local ping = Services.Stats.PerformanceStats.Ping:GetValue()
    
    setthreadidentity(oldIdentity)
    
    return (ping / 1000)
end

Cheat.getAllServerData = LPH_JIT_MAX(function()
    local url = 'https://games.roblox.com/v1/games/863266079/servers/Public?sortOrder=Desc&limit=100'
    local nextCursor = nil
    local serverData = {}

    repeat
        local response = request({
            Url = url .. (nextCursor and '&cursor=' .. nextCursor or '')
        })

        local parsedBody = Services.HttpService:JSONDecode(response.Body)

        for _, server in next, parsedBody.data do
            table.insert(serverData, server)
        end

        nextCursor = parsedBody.nextPageCursor

        task.wait()
    until (not nextCursor)

    return serverData
end)

function Cheat:serverHop()
    local rawServers = Cheat:getAllServerData()
    local servers = {}

    -- // Filter
    for _, server in next, rawServers do
        if (server.id == game.JobId) or (server.playing >= server.maxPlayers) then
            continue
        end

        local isLowPop = server.playing < (server.maxPlayers / 1.5)
        local priority = Cheat.Library.flags.serverPriority

        if (priority == 'High Population') and (isLowPop) then
            -- // skip lowpop server
            continue
        elseif (priority == 'Low Population') and (not isLowPop) then
            -- // skip highpop server
            continue
        end

        table.insert(servers, server)
    end

    -- // Hop
    if (#servers == 0) then
        servers = rawServers
    end

    local server = servers[math.random(1, #servers)]
    Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
end

function Cheat:streamSnipe(username)
    if Services.Players:FindFirstChild(username) then
        return Notification:Notify('That player is in your current server.', 10, 'INFO', Color3.fromRGB(0, 170, 250))
    end

    local startSnipe = tick()

    local success, eMsg = pcall(function()
        Notification:Notify('Searching for server...', 10, 'INFO', Color3.fromRGB(0, 170, 250))
        local serverData = Cheat:getAllServerData()

        local getUserReq = request({
            ['Url'] = 'https://users.roblox.com/v1/usernames/users',
            ['Method'] = 'POST',
            ['Body'] = Services.HttpService:JSONEncode({
                ['usernames'] = {
                    username
                },
                ['excludeBannedUsers'] = false
            }),
            ['Headers'] = {
                ['Content-Type'] = 'application/json'
            }
        })

        local getUserBody = Services.HttpService:JSONDecode(getUserReq.Body)

        if (#getUserBody.data <= 0) then
            Notification:Notify('That player doesn\'t exist, please check the username and try again.', 10, 'ERROR', Color3.fromRGB(250, 70, 70))
            return
        end

        local userId = getUserBody.data[1].id

        local avatarHeadshotReq = request({
            ['Url'] = 'https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=' .. tostring(userId) .. '&size=150x150&format=Png'
        })

        local avatarHeadshotBody = Services.HttpService:JSONDecode(avatarHeadshotReq.Body)

        local image = avatarHeadshotBody.data[1].imageUrl

        local totalTokens = 0
        local batches = {}
        local playerTokens = {}
        local nextCursor

        for _, server in next, serverData do
            for _, playerToken in next, server.playerTokens do
                playerTokens[playerToken] = server
                totalTokens = totalTokens + 1

                local batchNumber = math.floor(totalTokens / 100 + 1)

                if (not batches[batchNumber]) then
                    batches[batchNumber] = {}
                end

                table.insert(batches[batchNumber], {
                    ['requestId'] = '0:' .. playerToken .. ':AvatarHeadshot:150x150:png:regular',
                    ['type'] = 'AvatarHeadShot',
                    ['targetId'] = 0,
                    ['token'] = playerToken,
                    ['format'] = 'png',
                    ['size'] = '150x150'
                })
            end
        end

        local found = false
        local done = 0
        for _, batch in next, batches do
            task.spawn(function()
                local playerTokenToThumbnailReq = request({
                    ['Url'] = 'https://thumbnails.roblox.com/v1/batch',
                    ['Method'] = 'POST',
                    ['Headers'] = {
                        ['Content-Type'] = 'application/json'
                    },
                    ['Body'] = Services.HttpService:JSONEncode(batch)
                })

                if (playerTokenToThumbnailReq.StatusCode == 429) then
                    repeat
                        task.wait(1)
                        playerTokenToThumbnailReq = request({
                            ['Url'] = 'https://thumbnails.roblox.com/v1/batch',
                            ['Method'] = 'POST',
                            ['Headers'] = {
                                ['Content-Type'] = 'application/json'
                            },
                            ['Body'] = Services.HttpService:JSONEncode(batch)
                        })
                    until (playerTokenToThumbnailReq.StatusCode == 200)
                end

                local playerTokenToThumbnailBody = Services.HttpService:JSONDecode(playerTokenToThumbnailReq.Body)

                for _, request in next, playerTokenToThumbnailBody.data do
                    if (request.imageUrl == image) then
                        found = true

                        local split = string.split(request.requestId, ':')
                        local playerToken = playerTokens[split[2]]

                        if (playerToken.playing < playerToken.maxPlayers) then
                            local endSnipe = tick() - startSnipe
                            
                            Notification:Notify('Found, teleporting... Took ' .. tostring(math.floor(endSnipe * 100) / 100) .. ' seconds to find.', 10, 'INFO', Color3.fromRGB(0, 170, 250))
                            Services.TeleportService:TeleportToPlaceInstance(863266079, playerToken.id)
                        else
                            Notification:Notify('Can\'t join, server is full.', 10, 'ERROR', Color3.fromRGB(250, 70, 70))
                        end

                        return -- break
                    end
                end

                done = done + 1
            end)
            if found then
                break
            end
        end

        repeat task.wait() until (done == #batches)

        if (not found) then
            Notification:Notify('Couldn\'t find the player, are you sure they are playing?', 10, 'ERROR', Color3.fromRGB(250, 70, 70))
        end
        -- for _, server in next, serverData do
        --     if (server.id == game.JobId) then
        --         table.remove(serverData, table.find(serverData, server))
        --     end
        -- end

        -- local randomServer = serverData[math.random(1, #serverData)]
        -- if (not randomServer) then return end

        -- Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer.id)
    end)

    if (not success) then
        Notification:Notify('Something went wrong, please check the username and try again.', 10, 'ERROR', Color3.fromRGB(250, 70, 70))
    end
end

function Cheat:notifyWarn(message, lifeTime)
    Notification:Notify(message, lifeTime, 'WARNING', Color3.fromRGB(245, 215, 66))
    Cheat:runTask(Cheat.playSound, Cheat, 7383525713, 1.5)
end

function Cheat:notifyInfo(message, lifeTime, playSound)
    Notification:Notify(message, lifeTime, 'INFO', Color3.fromRGB(0, 170, 250))

    if (playSound) then
        Cheat:runTask(Cheat.playSound, Cheat, 7383525713, 1.5)
    end
end

function Cheat:notifyError(message, lifeTime, playSound)
    Notification:Notify(message, lifeTime, 'ERROR', Color3.fromRGB(250, 70, 70))

    if (playSound) then
        Cheat:runTask(Cheat.playSound, Cheat, 7383525713, 1.5)
    end
end

Cheat.playSound = LPH_NO_VIRTUALIZE(function(self, soundId, volume)
    local sound = Instance.new('Sound')

    sound.SoundId = (tonumber(soundId) and 'rbxassetid://'..soundId) or soundId
    sound.Volume = (volume or 0.5)
    sound.Parent = game:GetService('CoreGui')

    sound.Ended:Once(function()
        sound:Destroy()
        sound = nil
    end)

    sound:Play()
end)

Cheat.staffDetection = function(self, staffUserId)
    if (ws) and (connected) and (WhitelistPacketType) and (customTostring) then
        ws:Send(customTostring(WhitelistPacketType.StaffDetection) .. "~" .. customTostring(staffUserId))
    end
end

Cheat.isStaff = LPH_NO_VIRTUALIZE(function(self, playerObject)
    -- // UserId Check
    if (table.find(Cheat.Staff, playerObject.UserId)) then
        return true
    end

    -- // Group Check
    local isInGroup = false

    for _, groupId in next, Cheat.StaffGroups do
        pcall(function()
            isInGroup = playerObject:IsInGroup(groupId)
        end)
        
        if (isInGroup) then
            break
        end
    end

    return isInGroup
end)

local unsortedFeatures = {}
	
for i, _ in next, CHEAT_FEATURES do
    table.insert(unsortedFeatures, i)
end

local sortedFeatures = table.clone(unsortedFeatures)

if (not LPH_OBFUSCATED) then -- not gonna be utilized by the compiler so it's just a vulnerability outside of development
    if (CHEAT_LOAD_PRIORITY) then
        table.sort(sortedFeatures, function(a, b)
            local aOriginalIdx, bOriginalIdx = table.find(unsortedFeatures, a), table.find(unsortedFeatures, b)
            local aPriorityIdx, bPriorityIdx = table.find(CHEAT_LOAD_PRIORITY, a), table.find(CHEAT_LOAD_PRIORITY, b)

            if (not aPriorityIdx) then
                if (bPriorityIdx) then
                    return false
                else
                    return (aOriginalIdx < bOriginalIdx)
                end
            end

            if (not bPriorityIdx) then return true end

            return (aPriorityIdx < bPriorityIdx)
        end)
    end
end

-- // Init Features
for _, name in next, sortedFeatures do -- // FYI this is a table injected into the main.lua env by the Loader.lua file (or compiler)
    if (not LPH_OBFUSCATED) then
        rconsoleprint(`Loading {name}\n`)
    end
    
    local success, errMsg, traceback = true, nil, nil

    xpcall(CHEAT_FEATURES[name](), function(msg)
        success, errMsg, traceback = false, msg, debug.traceback()
    end, Cheat)

    if (not success) then
        print(traceback)
        print('Cheat Module: '..name..' Errored during Initialization! Error: '..tostring(errMsg:gsub('\n', ' ')))
        --rconsolewarn(traceback)
        --rconsoleerr('Cheat Module: '..name..' Errored during Initialization! Error: '..tostring(errMsg:gsub('\n', ' '))) -- // Since debug traceback is really shitty for some reason
    end
end

-- // Add Players to PlayerList
for _, playerObject in next, Services.Players:GetPlayers() do
    Cheat:addPlayerToLists(playerObject)
end

-- // Task Runner
game:GetService('RunService').Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(deltaTime)
    for index, taskData in next, Cheat.Tasks do
        Cheat.Tasks[index] = nil
        task.defer(taskData.func, table.unpack(taskData.args))
    end
end))

-- // Loading complete
Notification:Notify(string.format(Cheat.LoadedMessage, math.floor((os.clock() - Cheat.LoadStarted) * 100) / 100, retardedLoadPhrases[math.random(1, #retardedLoadPhrases)]), 5, 'INFO', Color3.fromRGB(0, 170, 250))
Library:Init()
