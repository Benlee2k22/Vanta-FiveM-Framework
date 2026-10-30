fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vanta-banking'
author 'Vanta'
description 'QBCore-native banking with the Vanta E-interaction UI'
version '0.4.0'

shared_script 'shared/config.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_script 'client/main.lua'
ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/app.js' }

dependencies { 'qb-core', 'oxmysql', 'vanta-ui' }
