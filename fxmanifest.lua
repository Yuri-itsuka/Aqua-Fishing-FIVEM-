fx_version 'cerulean'
game 'gta5'

author 'ChatGPT'
description 'ESX Fishing Complete Script'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}
