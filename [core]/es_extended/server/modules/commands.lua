ESX.RegisterCommand(
    { "setcoords", "tp" },
    "admin",
    function(xPlayer, args)
        xPlayer.setCoords({ x = args.x, y = args.y, z = args.z })
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Set Coordinates /setcoords Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "X Coord", value = args.x, inline = true },
                { name = "Y Coord", value = args.y, inline = true },
                { name = "Z Coord", value = args.z, inline = true },
            })
        end
    end,
    false,
    {
        help = TranslateCap("command_setcoords"),
        validate = true,
        arguments = {
            { name = "x", help = TranslateCap("command_setcoords_x"), type = "coordinate" },
            { name = "y", help = TranslateCap("command_setcoords_y"), type = "coordinate" },
            { name = "z", help = TranslateCap("command_setcoords_z"), type = "coordinate" },
        },
    }
)

ESX.RegisterCommand(
    "setjob",
    "admin",
    function(xPlayer, args, showError)
        if not ESX.DoesJobExist(args.job, args.grade) then
            return showError(TranslateCap("command_setjob_invalid"))
        end

        args.playerId.setJob(args.job, args.grade)
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Set Job /setjob Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
                { name = "Job", value = args.job, inline = true },
                { name = "Grade", value = args.grade, inline = true },
            })
        end
    end,
    true,
    {
        help = TranslateCap("command_setjob"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
            { name = "job", help = TranslateCap("command_setjob_job"), type = "string" },
            { name = "grade", help = TranslateCap("command_setjob_grade"), type = "number" },
        },
    }
)

local upgrades = Config.SpawnVehMaxUpgrades and {
    plate = "ADMINCAR",
    modEngine = 3,
    modBrakes = 2,
    modTransmission = 2,
    modSuspension = 3,
    modArmor = true,
    windowTint = 1,
} or {}

ESX.RegisterCommand(
    "car",
    "admin",
    function(xPlayer, args, showError)
        if not xPlayer then
            return showError("[^1ERROR^7] The xPlayer value is nil")
        end

        local playerPed = GetPlayerPed(xPlayer.source)
        local playerCoords = GetEntityCoords(playerPed)
        local playerHeading = GetEntityHeading(playerPed)
        local playerVehicle = GetVehiclePedIsIn(playerPed, false)

        if not args.car or type(args.car) ~= "string" then
            args.car = "adder"
        end

        if playerVehicle then
            DeleteEntity(playerVehicle)
        end

        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Spawn Car /car Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Vehicle", value = args.car, inline = true },
            })
        end

        local xRoutingBucket = GetPlayerRoutingBucket(xPlayer.source)

        ESX.OneSync.SpawnVehicle(args.car, playerCoords, playerHeading, upgrades, function(networkId)
            if networkId then
                local vehicle = NetworkGetEntityFromNetworkId(networkId)

                if xRoutingBucket ~= 0 then
                    SetEntityRoutingBucket(vehicle, xRoutingBucket)
                end

                for _ = 1, 100 do
                    Wait(0)
                    SetPedIntoVehicle(playerPed, vehicle, -1)

                    if GetVehiclePedIsIn(playerPed, false) == vehicle then
                        break
                    end
                end

                if GetVehiclePedIsIn(playerPed, false) ~= vehicle then
                    showError("[^1ERROR^7] The player could not be seated in the vehicle")
                end
            end
        end)
    end,
    false,
    {
        help = TranslateCap("command_car"),
        validate = false,
        arguments = {
            { name = "car", validate = false, help = TranslateCap("command_car_car"), type = "string" },
        },
    }
)

ESX.RegisterCommand(
    { "cardel", "dv" },
    "admin",
    function(xPlayer, args)
        local ped = GetPlayerPed(xPlayer.source)
        local pedVehicle = GetVehiclePedIsIn(ped, false)

        if DoesEntityExist(pedVehicle) then
            DeleteEntity(pedVehicle)
        end

        local coords = GetEntityCoords(ped)
        local Vehicles = ESX.OneSync.GetVehiclesInArea(coords, tonumber(args.radius) or 5.0)
        for i = 1, #Vehicles do
            local Vehicle = NetworkGetEntityFromNetworkId(Vehicles[i])
            if DoesEntityExist(Vehicle) then
                DeleteEntity(Vehicle)
            end
        end
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Delete Vehicle /dv Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
            })
        end
    end,
    false,
    {
        help = TranslateCap("command_cardel"),
        validate = false,
        arguments = {
            { name = "radius", validate = false, help = TranslateCap("command_cardel_radius"), type = "number" },
        },
    }
)

ESX.RegisterCommand(
    { "fix", "repair" },
    "admin",
    function(xPlayer, args, showError)
        local xTarget = args.playerId
        local ped = GetPlayerPed(xTarget.source)
        local pedVehicle = GetVehiclePedIsIn(ped, false)
        if not pedVehicle or GetPedInVehicleSeat(pedVehicle, -1) ~= ped then
            showError(TranslateCap("not_in_vehicle"))
            return
        end
        xTarget.triggerEvent("esx:repairPedVehicle")
        xPlayer.showNotification(TranslateCap("command_repair_success"), true, false, 140)
        if xPlayer.source ~= xTarget.source then
            xTarget.showNotification(TranslateCap("command_repair_success_target"), true, false, 140)
        end
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Fix Vehicle /fix Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = xTarget.name, inline = true },
            })
        end
    end,
    true,
    {
        help = TranslateCap("command_repair"),
        validate = false,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
        },
    }
)

ESX.RegisterCommand(
    "setaccountmoney",
    "admin",
    function(xPlayer, args, showError)
        if not args.playerId.getAccount(args.account) then
            return showError(TranslateCap("command_giveaccountmoney_invalid"))
        end
        args.playerId.setAccountMoney(args.account, args.amount, "Government Grant")
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Set Account Money /setaccountmoney Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
                { name = "Account", value = args.account, inline = true },
                { name = "Amount", value = args.amount, inline = true },
            })
        end
    end,
    true,
    {
        help = TranslateCap("command_setaccountmoney"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
            { name = "account", help = TranslateCap("command_giveaccountmoney_account"), type = "string" },
            { name = "amount", help = TranslateCap("command_setaccountmoney_amount"), type = "number" },
        },
    }
)

ESX.RegisterCommand(
    "giveaccountmoney",
    "admin",
    function(xPlayer, args, showError)
        if not args.playerId.getAccount(args.account) then
            return showError(TranslateCap("command_giveaccountmoney_invalid"))
        end
        args.playerId.addAccountMoney(args.account, args.amount, "Government Grant")
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Give Account Money /giveaccountmoney Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
                { name = "Account", value = args.account, inline = true },
                { name = "Amount", value = args.amount, inline = true },
            })
        end
    end,
    true,
    {
        help = TranslateCap("command_giveaccountmoney"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
            { name = "account", help = TranslateCap("command_giveaccountmoney_account"), type = "string" },
            { name = "amount", help = TranslateCap("command_giveaccountmoney_amount"), type = "number" },
        },
    }
)

ESX.RegisterCommand(
    "removeaccountmoney",
    "admin",
    function(xPlayer, args, showError)
        if not args.playerId.getAccount(args.account) then
            return showError(TranslateCap("command_removeaccountmoney_invalid"))
        end
        args.playerId.removeAccountMoney(args.account, args.amount, "Government Tax")
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Remove Account Money /removeaccountmoney Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
                { name = "Account", value = args.account, inline = true },
                { name = "Amount", value = args.amount, inline = true },
            })
        end
    end,
    true,
    {
        help = TranslateCap("command_removeaccountmoney"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
            { name = "account", help = TranslateCap("command_removeaccountmoney_account"), type = "string" },
            { name = "amount", help = TranslateCap("command_removeaccountmoney_amount"), type = "number" },
        },
    }
)

if not Config.CustomInventory then
    ESX.RegisterCommand(
        "giveitem",
        "admin",
        function(xPlayer, args)
            args.playerId.addInventoryItem(args.item, args.count)
            if Config.AdminLogging then
                ESX.DiscordLogFields("UserActions", "Give Item /giveitem Triggered!", "pink", {
                    { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                    { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                    { name = "Target", value = args.playerId.name, inline = true },
                    { name = "Item", value = args.item, inline = true },
                    { name = "Quantity", value = args.count, inline = true },
                })
            end
        end,
        true,
        {
            help = TranslateCap("command_giveitem"),
            validate = true,
            arguments = {
                { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
                { name = "item", help = TranslateCap("command_giveitem_item"), type = "item" },
                { name = "count", help = TranslateCap("command_giveitem_count"), type = "number" },
            },
        }
    )

    ESX.RegisterCommand(
        "giveweapon",
        "admin",
        function(xPlayer, args, showError)
            if args.playerId.hasWeapon(args.weapon) then
                return showError(TranslateCap("command_giveweapon_hasalready"))
            end
            args.playerId.addWeapon(args.weapon, args.ammo)
            if Config.AdminLogging then
                ESX.DiscordLogFields("UserActions", "Give Weapon /giveweapon Triggered!", "pink", {
                    { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                    { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                    { name = "Target", value = args.playerId.name, inline = true },
                    { name = "Weapon", value = args.weapon, inline = true },
                    { name = "Ammo", value = args.ammo, inline = true },
                })
            end
        end,
        true,
        {
            help = TranslateCap("command_giveweapon"),
            validate = true,
            arguments = {
                { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
                { name = "weapon", help = TranslateCap("command_giveweapon_weapon"), type = "weapon" },
                { name = "ammo", help = TranslateCap("command_giveweapon_ammo"), type = "number" },
            },
        }
    )

    ESX.RegisterCommand(
        "giveammo",
        "admin",
        function(xPlayer, args, showError)
            if not args.playerId.hasWeapon(args.weapon) then
                return showError(TranslateCap("command_giveammo_noweapon_found"))
            end
            args.playerId.addWeaponAmmo(args.weapon, args.ammo)
            if Config.AdminLogging then
                ESX.DiscordLogFields("UserActions", "Give Ammunition /giveammo Triggered!", "pink", {
                    { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                    { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                    { name = "Target", value = args.playerId.name, inline = true },
                    { name = "Weapon", value = args.weapon, inline = true },
                    { name = "Ammo", value = args.ammo, inline = true },
                })
            end
        end,
        true,
        {
            help = TranslateCap("command_giveweapon"),
            validate = false,
            arguments = {
                { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
                { name = "weapon", help = TranslateCap("command_giveammo_weapon"), type = "weapon" },
                { name = "ammo", help = TranslateCap("command_giveammo_ammo"), type = "number" },
            },
        }
    )

    ESX.RegisterCommand(
        "giveweaponcomponent",
        "admin",
        function(xPlayer, args, showError)
            if args.playerId.hasWeapon(args.weaponName) then
                local component = ESX.GetWeaponComponent(args.weaponName, args.componentName)

                if component then
                    if args.playerId.hasWeaponComponent(args.weaponName, args.componentName) then
                        showError(TranslateCap("command_giveweaponcomponent_hasalready"))
                    else
                        args.playerId.addWeaponComponent(args.weaponName, args.componentName)
                        if Config.AdminLogging then
                            ESX.DiscordLogFields("UserActions", "Give Weapon Component /giveweaponcomponent Triggered!", "pink", {
                                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                                { name = "Target", value = args.playerId.name, inline = true },
                                { name = "Weapon", value = args.weaponName, inline = true },
                                { name = "Component", value = args.componentName, inline = true },
                            })
                        end
                    end
                else
                    showError(TranslateCap("command_giveweaponcomponent_invalid"))
                end
            else
                showError(TranslateCap("command_giveweaponcomponent_missingweapon"))
            end
        end,
        true,
        {
            help = TranslateCap("command_giveweaponcomponent"),
            validate = true,
            arguments = {
                { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
                { name = "weaponName", help = TranslateCap("command_giveweapon_weapon"), type = "weapon" },
                { name = "componentName", help = TranslateCap("command_giveweaponcomponent_component"), type = "string" },
            },
        }
    )
end

ESX.RegisterCommand({ "clear", "cls" }, "user", function(xPlayer)
    xPlayer.triggerEvent("chat:clear")
end, false, { help = TranslateCap("command_clear") })

ESX.RegisterCommand({ "clearall", "clsall" }, "admin", function(xPlayer)
    TriggerClientEvent("chat:clear", -1)
    if Config.AdminLogging then
        ESX.DiscordLogFields("UserActions", "Clear Chat /clearall Triggered!", "pink", {
            { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
            { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
        })
    end
end, true, { help = TranslateCap("command_clearall") })

ESX.RegisterCommand("refreshjobs", "admin", function()
    ESX.RefreshJobs()
end, true, { help = TranslateCap("command_clearall") })

if not Config.CustomInventory then
    ESX.RegisterCommand(
        "clearinventory",
        "admin",
        function(xPlayer, args)
            for _, v in ipairs(args.playerId.inventory) do
                if v.count > 0 then
                    args.playerId.setInventoryItem(v.name, 0)
                end
            end
            TriggerEvent("esx:playerInventoryCleared", args.playerId)
            if Config.AdminLogging then
                ESX.DiscordLogFields("UserActions", "Clear Inventory /clearinventory Triggered!", "pink", {
                    { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                    { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                    { name = "Target", value = args.playerId.name, inline = true },
                })
            end
        end,
        true,
        {
            help = TranslateCap("command_clearinventory"),
            validate = true,
            arguments = {
                { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
            },
        }
    )

    ESX.RegisterCommand(
        "clearloadout",
        "admin",
        function(xPlayer, args)
            for i = #args.playerId.loadout, 1, -1 do
                args.playerId.removeWeapon(args.playerId.loadout[i].name)
            end
            TriggerEvent("esx:playerLoadoutCleared", args.playerId)
            if Config.AdminLogging then
                ESX.DiscordLogFields("UserActions", "/clearloadout Triggered!", "pink", {
                    { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                    { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                    { name = "Target", value = args.playerId.name, inline = true },
                })
            end
        end,
        true,
        {
            help = TranslateCap("command_clearloadout"),
            validate = true,
            arguments = {
                { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
            },
        }
    )
end

ESX.RegisterCommand(
    "setgroup",
    "admin",
    function(xPlayer, args)
        if not args.playerId then
            args.playerId = xPlayer.source
        end
        if args.group == "superadmin" then
            args.group = "admin"
            print("[^3WARNING^7] ^5Superadmin^7 detected, setting group to ^5admin^7")
        end
        args.playerId.setGroup(args.group)
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "/setgroup Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
                { name = "Group", value = args.group, inline = true },
            })
        end
    end,
    true,
    {
        help = TranslateCap("command_setgroup"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
            { name = "group", help = TranslateCap("command_setgroup_group"), type = "string" },
        },
    }
)

ESX.RegisterCommand(
    "save",
    "admin",
    function(_, args)
        Core.SavePlayer(args.playerId)
        print(("[^2Info^0] Saved Player - ^5%s^0"):format(args.playerId.source))
    end,
    true,
    {
        help = TranslateCap("command_save"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
        },
    }
)

ESX.RegisterCommand("saveall", "admin", function()
    Core.SavePlayers()
end, true, { help = TranslateCap("command_saveall") })

ESX.RegisterCommand("group", { "user", "admin" }, function(xPlayer, _, _)
    print(("%s, you are currently: ^5%s^0"):format(xPlayer.getName(), xPlayer.getGroup()))
end, true)

ESX.RegisterCommand("job", { "user", "admin" }, function(xPlayer, _, _)
	local job = xPlayer.getJob()

    print(("%s, your job is: ^5%s^0 - ^5%s^0 - ^5%s^0"):format(xPlayer.getName(), job.name, job.grade_label, job.onDuty and "On Duty" or "Off Duty"))
end, false)

ESX.RegisterCommand("info", { "user", "admin" }, function(xPlayer)
    local job = xPlayer.getJob().name
    print(("^2ID: ^5%s^0 | ^2Name: ^5%s^0 | ^2Group: ^5%s^0 | ^2Job: ^5%s^0"):format(xPlayer.source, xPlayer.getName(), xPlayer.getGroup(), job))
end, false)

ESX.RegisterCommand("playtime", { "user", "admin" }, function(xPlayer)
    local playtime = xPlayer.getPlayTime()
    local days = math.floor(playtime / 86400)
    local hours = math.floor((playtime % 86400) / 3600)
    local minutes = math.floor((playtime % 3600) / 60)
    print(("Playtime: ^5%s^0 Days | ^5%s^0 Hours | ^5%s^0 Minutes"):format(days, hours, minutes))
end, false)

ESX.RegisterCommand("coords", "admin", function(xPlayer)
    local ped = GetPlayerPed(xPlayer.source)
    local coords = GetEntityCoords(ped, false)
    local heading = GetEntityHeading(ped)
    print(("Coords - Vector3: ^5%s^0"):format(vector3(coords.x, coords.y, coords.z)))
    print(("Coords - Vector4: ^5%s^0"):format(vector4(coords.x, coords.y, coords.z, heading)))
end, false)

ESX.RegisterCommand("tpm", "admin", function(xPlayer)
    xPlayer.triggerEvent("esx:tpm")
    if Config.AdminLogging then
        ESX.DiscordLogFields("UserActions", "Admin Teleport /tpm Triggered!", "pink", {
            { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
            { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
        })
    end
end, false)

ESX.RegisterCommand(
    "goto",
    "admin",
    function(xPlayer, args)
        local targetCoords = args.playerId.getCoords()
        local srcDim = GetPlayerRoutingBucket(xPlayer.source)
        local targetDim = GetPlayerRoutingBucket(args.playerId.source)

        if srcDim ~= targetDim then
            SetPlayerRoutingBucket(xPlayer.source, targetDim)
        end
        xPlayer.setCoords(targetCoords)
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Admin Teleport /goto Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
                { name = "Target Coords", value = targetCoords, inline = true },
            })
        end
    end,
    false,
    {
        help = TranslateCap("command_goto"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
        },
    }
)

ESX.RegisterCommand(
    "bring",
    "admin",
    function(xPlayer, args)
        local targetCoords = args.playerId.getCoords()
        local playerCoords = xPlayer.getCoords()
        local targetDim = GetPlayerRoutingBucket(args.playerId.source)
        local srcDim = GetPlayerRoutingBucket(xPlayer.source)

        if targetDim ~= srcDim then
            SetPlayerRoutingBucket(args.playerId.source, srcDim)
        end
        args.playerId.setCoords(playerCoords)
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Admin Teleport /bring Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
                { name = "Target Coords", value = targetCoords, inline = true },
            })
        end
    end,
    false,
    {
        help = TranslateCap("command_bring"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
        },
    }
)

ESX.RegisterCommand(
    "kill",
    "admin",
    function(xPlayer, args)
        args.playerId.triggerEvent("esx:killPlayer")
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Kill Command /kill Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
            })
        end
    end,
    true,
    {
        help = TranslateCap("command_kill"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
        },
    }
)

ESX.RegisterCommand(
    "freeze",
    "admin",
    function(xPlayer, args)
        args.playerId.triggerEvent("esx:freezePlayer", "freeze")
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Admin Freeze /freeze Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
            })
        end
    end,
    true,
    {
        help = TranslateCap("command_freeze"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
        },
    }
)

ESX.RegisterCommand(
    "unfreeze",
    "admin",
    function(xPlayer, args)
        args.playerId.triggerEvent("esx:freezePlayer", "unfreeze")
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Admin UnFreeze /unfreeze Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
            })
        end
    end,
    true,
    {
        help = TranslateCap("command_unfreeze"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
        },
    }
)

ESX.RegisterCommand("noclip", "admin", function(xPlayer)
    xPlayer.triggerEvent("esx:noclip")
    if Config.AdminLogging then
        ESX.DiscordLogFields("UserActions", "Admin NoClip /noclip Triggered!", "pink", {
            { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
            { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
        })
    end
end, false)

ESX.RegisterCommand("players", "admin", function()
    local xPlayers = ESX.GetExtendedPlayers() -- Returns all xPlayers
    print(("^5%s^2 online player(s)^0"):format(#xPlayers))
    for i = 1, #xPlayers do
        local xPlayer = xPlayers[i]
        print(("^1[^2ID: ^5%s^0 | ^2Name : ^5%s^0 | ^2Group : ^5%s^0 | ^2Identifier : ^5%s^1]^0\n"):format(xPlayer.source, xPlayer.getName(), xPlayer.getGroup(), xPlayer.identifier))
    end
end, true)

ESX.RegisterCommand(
    {"setdim", "setbucket"},
    "admin",
    function(xPlayer, args)
        SetPlayerRoutingBucket(args.playerId.source, args.dimension)
        if Config.AdminLogging then
            ESX.DiscordLogFields("UserActions", "Admin Set Dim /setdim Triggered!", "pink", {
                { name = "Player", value = xPlayer and xPlayer.name or "Server Console", inline = true },
                { name = "ID", value = xPlayer and xPlayer.source or "Unknown ID", inline = true },
                { name = "Target", value = args.playerId.name, inline = true },
                { name = "Dimension", value = args.dimension, inline = true },
            })
        end
    end,
    true,
    {
        help = TranslateCap("command_setdim"),
        validate = true,
        arguments = {
            { name = "playerId", help = TranslateCap("commandgeneric_playerid"), type = "player" },
            { name = "dimension", help = TranslateCap("commandgeneric_dimension"), type = "number" },
        },
    }
)

ESX.RegisterCommand(
    "changeSetting",
    "admin",
    function(_, args)
        args.value = args.value:sub(2)
        print(("[^2Info^0] Setting ^5%s^0 changed to ^5%s^0 for ^5%s^0 "):format(args.key, args.value, args.resource))
        SettingsHandler:Set(args.resource, args.key, args.value)
    end,
    true,
    {
        help = "Change Settings Value",
        validate = false,
        arguments = {
            { name = "resource", help = "Resource Name", type = "string" },
            { name = "key", help = "Settings Key", type = "string" },
            { name = "value", help = TranslateCap("commandgeneric_playerid"), type = "merge" },
        },
    }
)

ESX.RegisterCommand(
    "checkSetting",
    "admin",
    function(_, args)
        local value = SettingsHandler:Get(args.resource, args.key)
        print(("[^2Info^0] Setting ^5%s^0 - ^5%s^0: ^5%s^0 "):format(args.resource, args.key, value))
    end,
    true,
    {
        help = "Change Settings Value",
        validate = true,
        arguments = {
            { name = "resource", help = "Resource Name", type = "string" },
            { name = "key", help = "Settings Key", type = "string" },
        },
    }
)

