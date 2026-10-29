fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vanta-core'
author 'Vanta'
description 'Vanta FiveM framework core'
version '0.3.0'

shared_script 'shared/config.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_script 'client/main.lua'

dependency 'oxmysql'
