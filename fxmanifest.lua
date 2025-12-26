fx_version 'cerulean'
game 'gta5'

author 'Amir'
description 'GiveCar Script'
version '2.0.0'

shared_script 'config.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    's/server.lua'
}


lua54 'yes'
