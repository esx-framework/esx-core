Adjustments = {}
Adjustments.ChangedComponents = {}

function Adjustments:RemoveHudComponent(i)
    if ESX.GetSetting(("HUD:%s"):format(i)) then
        self.ChangedComponents[i] = {
            size = GetHudComponentSize(i),
            position = GetHudComponentPosition(i)
        }
        SetHudComponentSize(i, 0.0, 0.0)
        SetHudComponentPosition(i, 900.0, 900.0)
    else
        if self.ChangedComponents[i] then
            SetHudComponentSize(i, self.ChangedComponents[i].size.x, self.ChangedComponents[i].size.y)
            SetHudComponentPosition(i, self.ChangedComponents[i].position.x, self.ChangedComponents[i].position.y)
            self.ChangedComponents[i] = nil
        end
    end
end

function Adjustments:RemoveHudComponents()
    for i = 1, 22 do
        self:RemoveHudComponent(i)
    end
end

function Adjustments:AimAssist()
    if ESX.GetSetting("AimAssist") then
        SetPlayerTargetingMode(0)
    else
        SetPlayerTargetingMode(3)
    end
end

function Adjustments:NPCDrops()
    local weaponPickups = { `PICKUP_WEAPON_CARBINERIFLE`, `PICKUP_WEAPON_PISTOL`, `PICKUP_WEAPON_PUMPSHOTGUN` }
    local enabled = ESX.GetSetting("NPCDrops") ~= nil and ESX.GetSetting("NPCDrops") or true
    for i = 1, #weaponPickups do
        ToggleUsePickupsForPlayer(ESX.playerId, weaponPickups[i], enabled)
    end
end

AddEventHandler("esx:enteredVehicle", function(vehicle, _, seat)
    if seat > -1 and not ESX.GetSetting("VehicleSeatShuff") then
        SetPedIntoVehicle(ESX.PlayerData.ped, vehicle, seat)
        SetPedConfigFlag(ESX.PlayerData.ped, 184, true)
    end
end)

function Adjustments:HealthRegeneration()
    SetPlayerHealthRechargeMultiplier(ESX.playerId, ESX.GetSetting("HealthRegeneration") and 1.0 or 0.0)
end

CreateThread(function()
    while true do
        local sleep = 1000
        if ESX.PlayerLoaded then
            if not ESX.GetSetting("DisplayAmmo") then
                sleep = 0
                DisplayAmmoThisFrame(false)
            end

            if not ESX.GetSetting("VehicleRewards") then
                sleep = 0
                DisablePlayerVehicleRewards(ESX.playerId)
            end
        end

        Wait(sleep)
    end
end)

function Adjustments:PVP()
    SetCanAttackFriendly(ESX.PlayerData.ped, ESX.GetSetting("PVP") or false, false)
    NetworkSetFriendlyFireOption(ESX.GetSetting("PVP") or false)
end

function Adjustments:DispatchServices()
    for i = 1, 15 do
        EnableDispatchService(i, ESX.GetSetting("DispatchServices") or false)
    end
    SetAudioFlag('PoliceScannerDisabled', ESX.GetSetting("DispatchServices") or false)
end

function Adjustments:Scenarios()
    local scenarios = {
        "WORLD_VEHICLE_ATTRACTOR",
        "WORLD_VEHICLE_AMBULANCE",
        "WORLD_VEHICLE_BICYCLE_BMX",
        "WORLD_VEHICLE_BICYCLE_BMX_BALLAS",
        "WORLD_VEHICLE_BICYCLE_BMX_FAMILY",
        "WORLD_VEHICLE_BICYCLE_BMX_HARMONY",
        "WORLD_VEHICLE_BICYCLE_BMX_VAGOS",
        "WORLD_VEHICLE_BICYCLE_MOUNTAIN",
        "WORLD_VEHICLE_BICYCLE_ROAD",
        "WORLD_VEHICLE_BIKE_OFF_ROAD_RACE",
        "WORLD_VEHICLE_BIKER",
        "WORLD_VEHICLE_BOAT_IDLE",
        "WORLD_VEHICLE_BOAT_IDLE_ALAMO",
        "WORLD_VEHICLE_BOAT_IDLE_MARQUIS",
        "WORLD_VEHICLE_BOAT_IDLE_MARQUIS",
        "WORLD_VEHICLE_BROKEN_DOWN",
        "WORLD_VEHICLE_BUSINESSMEN",
        "WORLD_VEHICLE_HELI_LIFEGUARD",
        "WORLD_VEHICLE_CLUCKIN_BELL_TRAILER",
        "WORLD_VEHICLE_CONSTRUCTION_SOLO",
        "WORLD_VEHICLE_CONSTRUCTION_PASSENGERS",
        "WORLD_VEHICLE_DRIVE_PASSENGERS",
        "WORLD_VEHICLE_DRIVE_PASSENGERS_LIMITED",
        "WORLD_VEHICLE_DRIVE_SOLO",
        "WORLD_VEHICLE_FIRE_TRUCK",
        "WORLD_VEHICLE_EMPTY",
        "WORLD_VEHICLE_MARIACHI",
        "WORLD_VEHICLE_MECHANIC",
        "WORLD_VEHICLE_MILITARY_PLANES_BIG",
        "WORLD_VEHICLE_MILITARY_PLANES_SMALL",
        "WORLD_VEHICLE_PARK_PARALLEL",
        "WORLD_VEHICLE_PARK_PERPENDICULAR_NOSE_IN",
        "WORLD_VEHICLE_PASSENGER_EXIT",
        "WORLD_VEHICLE_POLICE_BIKE",
        "WORLD_VEHICLE_POLICE_CAR",
        "WORLD_VEHICLE_POLICE",
        "WORLD_VEHICLE_POLICE_NEXT_TO_CAR",
        "WORLD_VEHICLE_QUARRY",
        "WORLD_VEHICLE_SALTON",
        "WORLD_VEHICLE_SALTON_DIRT_BIKE",
        "WORLD_VEHICLE_SECURITY_CAR",
        "WORLD_VEHICLE_STREETRACE",
        "WORLD_VEHICLE_TOURBUS",
        "WORLD_VEHICLE_TOURIST",
        "WORLD_VEHICLE_TANDL",
        "WORLD_VEHICLE_TRACTOR",
        "WORLD_VEHICLE_TRACTOR_BEACH",
        "WORLD_VEHICLE_TRUCK_LOGS",
        "WORLD_VEHICLE_TRUCKS_TRAILERS",
        "WORLD_VEHICLE_DISTANT_EMPTY_GROUND",
        "WORLD_HUMAN_PAPARAZZI",
    }

    for i = 1, #scenarios do
        SetScenarioTypeEnabled(scenarios[i], ESX.GetSetting("Scenarios") or false)
    end
end

function Adjustments:AIPlates()
    SetDefaultVehicleNumberPlateTextPattern(-1, ESX.GetSetting("AIPlates") or ".......")
end

local placeHolders = {
    server_name = function()
        return GetConvar("sv_projectName", "ESX-Framework")
    end,
    server_endpoint = function()
        return GetCurrentServerEndpoint() or "localhost:30120"
    end,
    server_players = function()
        return GlobalState.playerCount or 0
    end,
    server_maxplayers = function()
        return GetConvarInt("sv_maxClients", 48)
    end,
    player_name = function()
        return GetPlayerName(ESX.playerId)
    end,
    player_rp_name = function()
        return ESX.PlayerData.name or "John Doe"
    end,
    player_id = function()
        return ESX.serverId
    end,
    player_street = function()
        if not ESX.PlayerData.ped then return "Unknown" end

        local playerCoords = GetEntityCoords(ESX.PlayerData.ped)
        local streetHash = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)

        return GetStreetNameFromHashKey(streetHash) or "Unknown"
    end,
}

function Adjustments:PresencePlaceholders(string)
    local presence = Config.DiscordActivity.presence

    for placeholder, cb in pairs(placeHolders) do
        local success, result = pcall(cb)

        if not success then
            error(("Failed to execute presence placeholder: ^5%s^7"):format(placeholder))
            error(result)
            return "Unknown"
        end

        presence = presence:gsub(("{%s}"):format(placeholder), result)
    end

    return presence
end

CreateThread(function()
    while true do
        if ESX.PlayerLoaded then
            local appId = ESX.GetSetting("discord:appId") or "0"
            if appId and appId ~= "0" then
                SetDiscordAppId(appId)
                SetDiscordRichPresenceAsset(ESX.GetSetting("discord:assetName") or "")
                SetDiscordRichPresenceAssetText(Adjustments:PresencePlaceholders(ESX.GetSetting("discord:assetText") or ""))

                SetDiscordRichPresenceAction(0, ESX.GetSetting("discord:buttonsLabel:1") or "", ESX.GetSetting("discord:buttonsUrl:1")or "")
                SetDiscordRichPresenceAction(1, ESX.GetSetting("discord:buttonsLabel:2") or "", ESX.GetSetting("discord:buttonsUrl:2") or "")

                SetRichPresence(Adjustments:PresencePlaceholders(ESX.GetSetting("presence") or ""))
            end
        end
        Wait(ESX.PlayerLoaded and ESX.GetSetting("discord:refresh") or 60000)
    end
end)

function Adjustments:WantedLevel()
    local setting = ESX.GetSetting("WantedLevel")
    ClearPlayerWantedLevel(ESX.playerId)
    print("Wanted Level is currently", setting, type(setting))
    if setting then
        SetMaxWantedLevel(5)
    else
        SetMaxWantedLevel(0)
    end
end

AddEventHandler("esx:enteredVehicle", function(vehicle)
    if ESX.GetSetting("HUD:16") then
        SetVehRadioStation(vehicle, "OFF")
        SetUserRadioControlEnabled(false)
    end
end)

function Adjustments:Load()
    self:RemoveHudComponents()
    self:AimAssist()
    self:NPCDrops()
    self:HealthRegeneration()
    self:PVP()
    self:DispatchServices()
    self:Scenarios()
    self:AIPlates()
    self:WantedLevel()
end

AddEventHandler("es_extended:settingChanged", function(resource, category, key, value)
    if resource ~= "es_extended" then
        return
    end
    if category == "Adjustments" then
        if Adjustments[key] then
            Adjustments[key](Adjustments)
        else
            Adjustments:Load()
        end
    elseif category == "HUD Components" then
        key = key:gsub("HUD:", "")
        Adjustments:RemoveHudComponent(tonumber(key))
    end
end)
