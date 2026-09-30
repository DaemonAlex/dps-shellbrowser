fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Del Perro Sands'
description 'Shell browser (/shells) and shell portals (/portal): doors in the world that lead into qs-housing shells.'
version '1.1.0'

dependency 'ox_lib'
shared_script '@ox_lib/init.lua'

client_scripts {
    'client/main.lua',
    'client/portals.lua',
}
server_scripts {
    'server/parse.lua',
    'server/main.lua',
}
