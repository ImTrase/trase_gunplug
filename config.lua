---------------------------------------------------
-- For more scripts or support join our discord ---
-- https://discord.gg/trase | https://trase.dev/ --
---------------------------------------------------

Config = {}

Config.Command = 'gunplug' -- The command to redeem the gunplug
Config.Rewards = {
    Type = 1, -- 1 = ESX | 2 = QBCore | 3 = ox_inventory (if using something else you can edit the "giveRewards" function in server.lua)
    ESX = 'es_extended', -- Used for export to get framework
    QBCore = 'qb-core',  -- Used for export to get framework
    OX = 'ox_inventory',  -- Used for export to giveitem via inventory
    Rewards = { -- itemName = rewardCount
        ['WEAPON_APPISTOL'] = 2, -- Gives 1x appistol
        ['WEAPON_PISTOL'] = 1, -- Gives 1x pistol
        ['ammo-9'] = 150, -- Gives 150x 9mm ammo
        ['ammo-45'] = 100, -- Gives 100x .45 ammo
    }
}

Config.DiscordLogs = {
    Enabled = false, -- If enabled, it will send a discord log once a player redeems a gunplug
    Webhook = '',
    Embed = {
        Color = 0, -- Use decimal color code
        Username = 'Gunplug',
        UserIcon = 'https://imgur.com/L2Z2upC.png'
    }
}

Config.Whitelisted = {
    Enabled = true, -- Whitelist command access?
    Type = 1, -- 1 = whitelisted discord role | 2 = whitelisted identifiers
    Discord = { -- Only use if type above is set to "1"
        Resource = 1, -- 1 = Trase_Discord (recommended) | 2 = Badger_Discord_API
        RoleID = 711290935119708260
    },
    Identifiers = { -- Only use if type above is set to "2" (any identifier will work)
        'discord:334259748499357697', -- Trase
    }
}

Config.Cooldown = {
    Enabled = true, -- Cooldown enabled?
    Time = 14, -- Time in days to wait before redeeming again
    Type = 1, -- 1 = MySQL (highly recommended) | 2 = JSON
    Identifier = 'discord' -- Identifier to save it to (discord is default) [discord, license, steam, xbl, live, fivem]
}

Config.Strings = {
    ['Prefix'] = '^1Gunplug',
    ['NotWhitelisted'] = 'You are not whitelisted to use this command!',
    ['Cooldown'] = 'You still need to wait {TIME_REMAINING} more day(s) before claiming again!',
    ['Success'] = 'You have successfully claimed your gunplug!',

    -- Discord log strings
    ['LOGS_Title'] = 'Gunplug Claimed',
    ['LOGS_Description'] = 'A player claimed there gunplug and got there rewards!',
}