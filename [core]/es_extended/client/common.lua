Core = {}
ESX.PlayerData = {}
ESX.playerId = PlayerId()
ESX.serverId = GetPlayerServerId(ESX.playerId)
ESX.PlayerLoaded = false
Core.Input = {}
ESX.UI = {}
ESX.UI.Menu = {}
ESX.UI.Menu.RegisteredTypes = {}
ESX.UI.Menu.Opened = {}

ESX.Game = {}
ESX.Game.Utils = {}

ESX.Scaleform = {}
ESX.Scaleform.Utils = {}

ESX.Streaming = {}

CreateThread(function()
    while not Config.Multichar do
        Wait(100)

        if NetworkIsPlayerActive(ESX.playerId) then
            ESX.DisableSpawnManager()
            DoScreenFadeOut(0)
            Wait(500)
            TriggerServerEvent("esx:onPlayerJoined")
            break
        end
    end
end)
