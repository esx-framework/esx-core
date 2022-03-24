--[[ FX Information ]]--
fx_version   'cerulean'
use_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'

--[[ Resource Information ]]--
name         'esx_menu_default'
version      '1.6.5'
description  'ESX Menu Default'
author       'esx-legacy'
repository   'https://github.com/esx-framework/esx-legacy/tree/main/%5Besx%5D/esx_menu_default'

--[[ Manifest ]]--
dependency 'es_extended'

client_scripts {
	'@es_extended/imports.lua',
	'client/main.lua'
}

ui_page 'html/ui.html'

files {
	'html/ui.html',
	'html/css/app.css',
	'html/js/mustache.min.js',
	'html/js/app.js'
}