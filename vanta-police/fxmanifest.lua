fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'vanta-police'
author 'Vanta'
description 'Police duty, dispatch and nearby custody actions for Vanta'
version '0.3.0'

shared_script 'shared/config.lua'
server_script 'server/main.lua'
client_script 'client/main.lua'

dependencies { 'vanta-core', 'vanta-ui' }
