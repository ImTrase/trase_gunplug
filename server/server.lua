---------------------------------------------------
-- For more scripts or support join our discord ---
-- https://discord.gg/trase | https://trase.dev/ --
---------------------------------------------------

-- Declare native variables
local RegisterCommand <const> = RegisterCommand
local TriggerClientEvent <const> = TriggerClientEvent
local GetPlayerIdentifiers <const> = GetPlayerIdentifiers
local CreateThread <const> = CreateThread
local split <const> = string.strsplit
local find <const> = string.find
local pairs <const> = pairs
local floor <const> = math.floor
local print <const> = print
local Config <const> = Config

local organizedRewards = ''

-- Feel free to change this function if none is supported
local function giveRewards(target)
    if (Config.Rewards.Type == 1) then -- ESX
        if (not ESX) then
            return print('^4[Trase_Gunplug] ^1[ERROR]^0: ESX is not loaded correctly! Please make sure you have the correct export set in config.lua')
        end

        local xPlayer = ESX.GetPlayerFromId(target)
        if (not xPlayer) then
            return print('^4[Trase_Gunplug] ^1[ERROR]^0: xPlayer was not found! Please make sure you have the correct ESX export set in config.lua')
        end

        for k, v in pairs(type(Config.Rewards.Rewards) == 'table' and Config.Rewards.Rewards or {}) do
            if (find(k, 'WEAPON_')) then
                xPlayer.addInventoryItem(k, v)
                --[[for i = 1, v do  -- Change to this if on older version of ESX and its not working? I tested this on version 1.10.2 and xPlayer.addWeapon was not working.
                    xPlayer.addWeapon(k, 0)
                end]]--
            else
                xPlayer.addInventoryItem(k, v)
            end
        end
    elseif (Config.Rewards.Type == 2) then
        if (not QBCore) then
            return print('^4[Trase_Gunplug] ^1[ERROR]^0: QBCore is not loaded correctly! Please make sure you have the correct export set in config.lua')
        end

        local Player = QBCore.Functions.GetPlayer(target)
        if (not Player) then
            return print('^4[Trase_Gunplug] ^1[ERROR]^0: Player was not found! Please make sure you have the correct QBCore export set in config.lua')
        end

        for k, v in pairs(type(Config.Rewards.Rewards) == 'table' and Config.Rewards.Rewards or {}) do
            if (find(k, 'WEAPON_')) then
                Player.Functions.AddWeapon(k, 0)
            else
                Player.Functions.AddItem(k, v)
            end
        end
    elseif (Config.Rewards.Type == 3) then
        for k, v in pairs(type(Config.Rewards.Rewards) == 'table' and Config.Rewards.Rewards or {}) do
            exports[Config.Rewards.OX]:AddItem(target, k, v)
        end
    else
        print('^4[Trase_Gunplug] ^1[ERROR]^0: Config.Rewards type is not set correctly!')
    end
end

local function getIdentifiers(target, splitThem)
    local t = {}

    if target then
        local identifiers = GetPlayerIdentifiers(target)

        for i=1, #identifiers do
            local prefix, identifier = split(':', identifiers[i])
            t[prefix] = splitThem and identifier or identifiers[i]
        end
    end

    return t
end

local function tableMatch(table, value)
    for k, v in pairs(table) do
        if (v == value) then return true end
    end

    return false
end

local function sendNotification(target, msg)
    TriggerClientEvent('chat:addMessage', target, {
        args = {Config.Strings['Prefix'], msg}
    })
end

local function isPlayerWhitelisted(target)
    if (Config.Whitelisted.Type == 1) then -- Discord
        if (Config.Whitelisted.Discord.Resource == 1) then
            if (GetResourceState('trase_discord') ~= 'started') then
                print('^4[Trase_Gunplug] ^1[ERROR]^0: Trase_Discord is not started! Please make sure you have the resource started or change the resource in the config.lua')
                return false
            end

            local valid = exports.trase_discord:hasRole(target, Config.Whitelisted.Discord.RoleID, false)
            return valid
        elseif (Config.Whitelisted.Discord.Resource == 2) then
            if (GetResourceState('Badger_Discord_API') ~= 'started') then
                print('^4[Trase_Gunplug] ^1[ERROR]^0: Badger_Discord_API is not started! Please make sure you have the resource started or change the resource in the config.lua')
                return false
            end

            local roleIDs = exports.Badger_Discord_API:GetDiscordRoles(target)
            for i = 1, #roleIDs do
				if exports.Badger_Discord_API:CheckEqual(roleIDs[i], Config.Whitelisted.Discord.RoleID) then
                    return true
                end
			end

            return false
        else
            print('^4[Trase_Gunplug] ^1[ERROR]^0: Config.Whitelisted.Discord type is not set correctly!')
        end
    elseif (Config.Whitelisted.Type == 2) then -- Identifiers
        local identifiers = getIdentifiers(target)
        for i = 1, #Config.Whitelisted.Identifiers do
            local found = tableMatch(identifiers, Config.Whitelisted.Identifiers[i])

            if (found) then
                return true
            end
        end
    else
        print('^4[Trase_Gunplug] ^1[ERROR]^0: Config.Whitelisted type is not set correctly!')
    end

    return false
end

local function loadCache()
    if Config.Cooldown.Enabled then
        if Config.Cooldown.Type == 2 then -- JSON
            local cached = LoadResourceFile(GetCurrentResourceName(), 'server/cache.json')
            local cache = json.decode(cached)
            if (not cache) then
                -- Create cache
                print('^4[Trase_Gunplug] ^3[WARNING]^0: Config.Cooldown type is set to JSON, no json found creating now!')
                local timeOld = os.microtime()
                SaveResourceFile(GetCurrentResourceName(), 'server/cache.json', json.encode({}), -1)
                local took = os.microtime() - timeOld
                print('^4[Trase_Gunplug] ^2[SUCCESS]^0: JSON file created in '..took..'ms!')
                return {}
            else
                return cache
            end
        else
            if (not MySQL) then
                print('^4[Trase_Gunplug] ^1[ERROR]^0: Config.Cooldown type is set to MySQL, but MySQL is not loaded correctly!')
                return {}
            end

            local success, result = pcall(function()
                return MySQL.Sync.fetchAll('SELECT * FROM gunplug')
            end)

            if (not success) then
                print('^4[Trase_Gunplug] ^3[WARNING]^0: Config.Cooldown type is set to MySQL, but no table was found! Creating now!')
                local timeOld = os.microtime()
                MySQL.Sync.execute('CREATE TABLE IF NOT EXISTS gunplug (identifier VARCHAR(50), time INT)')
                local took = os.microtime() - timeOld
                print('^4[Trase_Gunplug] ^2[SUCCESS]^0: Database table created in '..took..'ms!')
                return {}
            end

            return result
        end
    end
end

local function canRedeem(target)
    if Config.Cooldown.Type == 1 then -- MySQL
        local identifier = getIdentifiers(target)[Config.Cooldown.Identifier]
        local result = MySQL.Sync.fetchAll('SELECT * FROM gunplug WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        })

        if (next(result)) then
            local redeemed = result[1].time
            local timeNow = os.time()
            local timeDiff = timeNow - redeemed
            local timeLeft = Config.Cooldown.Time * 86400 - timeDiff
            local timeindays = floor(timeLeft / 86400)
            
            -- Check if time is up
            if (timeDiff >= Config.Cooldown.Time * 86400) then
                MySQL.Sync.execute('DELETE FROM gunplug WHERE identifier = @identifier', {
                    ['@identifier'] = identifier
                })

                MySQL.Sync.execute('INSERT INTO gunplug (identifier, time) VALUES (@identifier, @time)', {
                    ['@identifier'] = identifier,
                    ['@time'] = os.time()
                })

                return true
            else
                sendNotification(target, Config.Strings['Cooldown']:gsub('{TIME_REMAINING}', timeindays))
                return false
            end
        else
            MySQL.Sync.execute('INSERT INTO gunplug (identifier, time) VALUES (@identifier, @time)', {
                ['@identifier'] = identifier,
                ['@time'] = os.time()
            })
            return true
        end
    elseif Config.Cooldown.Type == 2 then -- JSON
        local cache = loadCache()
        local identifier = getIdentifiers(target)[Config.Cooldown.Identifier]
        for i = 1, #cache do
            local v = cache[i]
            if (v.identifier == identifier) then
                local redeemed = v.time
                local timeNow = os.time()
                local timeDiff = timeNow - redeemed
                local timeLeft = Config.Cooldown.Time * 86400 - timeDiff
                local timeindays = floor(timeLeft / 86400)
                
                -- Check if time is up
                if (timeDiff >= Config.Cooldown.Time * 86400) then
                    cache[i] = nil
                else
                    sendNotification(target, Config.Strings['Cooldown']:gsub('{TIME_REMAINING}', timeindays))
                    return false
                end
            end
        end

        cache[#cache +1] = { identifier = identifier, time = os.time() }
        SaveResourceFile(GetCurrentResourceName(), 'server/cache.json', json.encode(cache), -1)
        return true
    else
        print('^4[Trase_Gunplug] ^1[ERROR]^0: Config.Cooldown type is not set correctly!')
    end
end

local function organizeRewards()
    local rewardsString = ''
    for k, v in pairs(Config.Rewards.Rewards) do
        local fixedString = ('**%s** - x%s'):format(k, v)
        rewardsString = rewardsString .. fixedString .. "\n"
    end

    organizedRewards = rewardsString
end

local function orgainizeIdentifiers(target)
    local t = {}

    local identifiers = getIdentifiers(target, true)

    for k, v in pairs(identifiers) do
        if k == 'steam' then
            t[#t+1] = ('Steam: [%s](https://steamcommunity.com/profiles/%s)'):format(v, tonumber(v, 16))
        elseif k == 'discord' then
            t[#t+1] = ('Discord: <@%s>'):format(v)
        elseif k == 'license' then
            t[#t+1] = ('License: %s'):format(v)
        elseif k == 'license2' then
            t[#t+1] = ('License 2: %s'):format(v)
        elseif k == 'fivem' then
            t[#t+1] = ('FiveM: %s'):format(v)
        elseif k == 'xbl' then
            t[#t+1] = ('Xbox: %s'):format(v)
        elseif k == 'live' then
            t[#t+1] = ('Live: %s'):format(v)
        end
    end

    return table.concat(t, '\n')
end

local function logRewards(target)
    if (not Config.DiscordLogs.Enabled) then return end
    if (Config.DiscordLogs.Webhook == '') then
        return print('^4[Trase_Gunplug] ^3[WARNING]^0: Config.DiscordLogs was enabled but a webhook is not set!')
    end

    local fields = {}
    fields[#fields+1] = { name = 'Player', value = ('%s (ID: %s)'):format(GetPlayerName(target), target), inline = false }
    fields[#fields+1] = { name = 'Rewards Received', value = organizedRewards, inline = false }
    fields[#fields+1] = { name = 'Player Identifiers', value = orgainizeIdentifiers(target), inline = false }

    local embed = {
        color = Config.DiscordLogs.Embed.Color,
        type = 'rich',
        title = Config.Strings['LOGS_Title'],
        description = Config.Strings['LOGS_Description'],
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S'),
        fields = fields,
        footer = {
            text = 'Trase.Dev',
            icon_url = 'https://imgur.com/L2Z2upC.png'
        }
    }

    local encodedData = {
        username = Config.DiscordLogs.Embed.Username,
        avatar_url = Config.DiscordLogs.Embed.UserIcon,
        embeds = { embed }
    }

    PerformHttpRequest(Config.DiscordLogs.Webhook, function(statusCode, responseText, headers)
    end, 'POST', json.encode(encodedData), { ['Content-Type'] = 'application/json' })
end

RegisterCommand(Config.Command, function(src)
    if (Config.Whitelisted.Enabled) then
        local whitelisted = isPlayerWhitelisted(src)
        if (not whitelisted) then
            return sendNotification(src, Config.Strings['NotWhitelisted'])
        end
    end

    if (Config.Cooldown.Enabled and not canRedeem(src)) then return end

    giveRewards(src)
    if (Config.DiscordLogs.Enabled) then logRewards(src) end
    sendNotification(src, Config.Strings['Success'])
end, false)

CreateThread(function()
    loadCache()

    local timeOld = os.microtime()

    if (Config.Rewards.Type == 1) then -- ESX
        ESX = exports[Config.Rewards.ESX]:getSharedObject()
    elseif (Config.Rewards.Type == 2) then
        QBCore = exports[Config.Rewards.QBCore]:GetCoreObject()
    elseif (Config.Rewards.Type == 3) then
        local success, hasExport = pcall(function()
            return exports[Config.Rewards.OX] and exports[Config.Rewards.OX].AddItem ~= nil
        end)

        if not success or not hasExport then
            print('^4[Trase_Gunplug] ^1[ERROR]^0: OX_Inventory is not loaded correctly! Please make sure you have the correct export set in config.lua')
        end
    else
        print('^4[Trase_Gunplug] ^1[ERROR]^0: Config.Rewards type is not set correctly!')
    end

    if (Config.DiscordLogs.Enabled) then organizeRewards() end

    local took = os.microtime() - timeOld
    print('^4[Trase_Gunplug] ^2[SUCCESS]^0: Framework loaded in '..took..'ms!')
end)