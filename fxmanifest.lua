--[[ 
  Legendary Animals Resource for RedM
  Created by Nt_Legendary_Animals
--]]

fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'Legendary Animals System for RedM'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
    'shared/configAnimals.lua',
}

client_scripts {
    'client/client.lua',
    'client/spawn.lua',
    'client/cleanup.lua',
    'client/time.lua',
    'client/weather.lua',
    'client/blip.lua',
    'client/notifications.lua'
}

server_scripts {
    'server/server.lua'
}

dependency 'ox_lib'