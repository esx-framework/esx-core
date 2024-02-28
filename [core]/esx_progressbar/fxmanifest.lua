fx_version 'adamant'

game 'gta5'
author 'ESX-Framework'
lua54 'yes'
version '1.10.5'
description 'A beautiful and simple NUI progress bar for ESX'

client_scripts { 'Progress.lua' }
shared_script '@es_extended/imports.lua'
ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/js/*.js',
    'nui/css/*.css',
}
