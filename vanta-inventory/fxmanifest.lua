fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vanta-inventory'
author 'Vanta'
description 'Persistent slot inventory for Vanta'
version '0.3.0'

client_script 'client/main.lua'
ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/app.js' }

dependencies { 'vanta-core', 'qb-core' }
