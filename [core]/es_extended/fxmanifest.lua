fx_version 'cerulean'

game 'gta5'
description 'The Core resource that provides the functionalities for all other resources.'
lua54 'yes'
version '1.12.2'

shared_scripts {
	'locale.lua',

	'shared/config/main.lua',
    'shared/config/weapons.lua',
    'shared/config/adjustments.lua',
    'shared/config/compat.lua',

    'shared/main.lua',
    'shared/functions.lua',
    'shared/modules/*.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
    'shared/config/logs.lua',

	'server/common.lua',
	'server/modules/callback.lua',
	'server/classes/player.lua',
	'server/classes/vehicle.lua',
	'server/classes/overrides/*.lua',
	'server/functions.lua',
	'server/modules/onesync.lua',
	'server/modules/paycheck.lua',

	'server/main.lua',
	'server/modules/commands.lua',

	'server/bridge/**/*.lua',
	'server/modules/npwd.lua',
	'server/modules/createJob.lua'
}

client_scripts {
    'client/main.lua',
	'client/functions.lua',
	'client/modules/wrapper.lua',
	'client/modules/callback.lua',
    'client/modules/adjustments.lua',
	'client/modules/points.lua',

	'client/modules/events.lua',

	'client/modules/actions.lua',
	'client/modules/death.lua',
	'client/modules/npwd.lua',
    'client/modules/interactions.lua',
	'client/modules/scaleform.lua',
	'client/modules/streaming.lua',
}

ui_page {
	'html/ui.html'
}

files {
	'imports.lua',
	'locales/*.lua',
	'locale.js',
	'html/ui.html',

	'html/css/app.css',

	'html/js/mustache.min.js',
	'html/js/wrapper.js',
	'html/js/app.js',

	'html/fonts/pdown.ttf',
	'html/fonts/bankgothic.ttf',
    "client/imports/*.lua",
}

dependencies {
	'/native:0x6AE51D4B',
    '/native:0xA61C8FC6',
	'oxmysql',
}
