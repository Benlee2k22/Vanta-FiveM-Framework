fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vanta-character'
author 'Vanta'
description 'Vanta character selection, creation and spawn selector'
version '0.1.0'

shared_script 'shared/config.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_script 'client/main.lua'
ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/app.js' }

dependencies { 'oxmysql', 'vanta-core', 'vanta-ui' }
