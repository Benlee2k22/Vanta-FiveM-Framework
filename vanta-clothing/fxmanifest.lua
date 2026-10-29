fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vanta-clothing'
author 'Vanta'
description 'Vanta clothing stores, personal wardrobes and saved outfits'
version '0.1.0'

shared_script 'shared/config.lua'
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/main.lua' }
client_script 'client/main.lua'
ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/app.js' }

dependencies { 'oxmysql', 'vanta-core', 'vanta-ui', 'vanta-character' }
