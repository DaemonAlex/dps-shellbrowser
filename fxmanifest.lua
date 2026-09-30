fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Del Perro Sands'
description 'Shell browser: /shells shows every qs-housing shell one at a time, high in the sky, with its model name on screen.'
version '1.0.0'

dependency 'ox_lib'
shared_script '@ox_lib/init.lua'

client_script 'client/main.lua'
server_scripts {
    'server/parse.lua',
    'server/main.lua',
}
