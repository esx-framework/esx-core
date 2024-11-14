if Config.CustomInventory ~= "ox" then
    if GetResourceState("ox_inventory") ~= "missing" then
        Config.CustomInventory = "ox"
        Config.OxInventory = true
    else
        return
    end
end

SetConvarReplicated("inventory:framework", "esx")
SetConvarReplicated("inventory:weight", tostring(Config.MaxWeight * 1000))

MySQL.ready(function()
    TriggerEvent("__cfx_export_ox_inventory_Items", function(ref)
        if ref then
            ESX.Items = ref()
        end
    end)

    AddEventHandler("ox_inventory:itemList", function(items)
        ESX.Items = items
    end)
end)

---@diagnostic disable-next-line: duplicate-set-field
ESX.GetItemLabel = function(item)
    item = exports.ox_inventory:Items(item)
    if item then
        return item.label
    end
end

function setPlayerInventory(playerId, xPlayer, inventory, isNew)
    exports.ox_inventory:setPlayerInventory(xPlayer, inventory)
    if isNew then
        local shared = json.decode(GetConvar("inventory:accounts", '["money"]'))

        for i = 1, #shared do
            local name = shared[i]
            local account = Config.StartingAccountMoney[name]
            if account then
                exports.ox_inventory:AddItem(playerId, name, account)
            end
        end
    end
end
