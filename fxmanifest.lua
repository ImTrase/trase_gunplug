---------------------------------------------------
-- For more scripts or support join our discord ---
-- https://discord.gg/trase | https://trase.dev/ --
---------------------------------------------------

fx_version 'cerulean'
games { 'gta5' }
author 'Trase'
lua54 'yes'

server_scripts {
    '@mysql-async/lib/MySQL.lua', -- If not using SQL, remove this line
    'config.lua',
    'server/server.lua'
}