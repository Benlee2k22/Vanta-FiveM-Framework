fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vanta-hospital'
author 'Vanta'
description 'Hospital check-in and EMS treatment for Vanta'
version '0.3.0'

shared_script 'shared/config.lua'
server_script 'server/main.lua'
client_script 'client/main.lua'

dependencies { 'vanta-core', 'vanta-ui', 'vanta-banking' }
