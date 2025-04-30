lua54 'yes'
fx_version 'cerulean'
game 'gta5'

author 'dollar-src'
description 'Payphone'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    --'@qbx_core/modules/playerdata.lua',  -- QBox only
    'bridge.lua',
    'client.lua'
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
} 



ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/styles.css',
    'ui/script.js'
}
