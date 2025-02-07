---@class xPlayer
---@field accounts table
---@field coords table
---@field group string
---@field identifier string
---@field inventory table
---@field job table
---@field loadout table
---@field name string
---@field playerId number
---@field source number
---@field variables table
---@field weight number
---@field maxWeight number
---@field metadata table
---@field lastPlaytime number
---@field admin boolean
---@field license string

---@param playerId number
---@param identifier string
---@param group string
---@param accounts table
---@param inventory table
---@param weight number
---@param job table
---@param loadout table
---@param name string
---@param coords table | vector4
---@param metadata table
function CreateExtendedPlayer(playerId, identifier, group, accounts, inventory, weight, job, loadout, name, coords, metadata)
    ---@class xPlayer
    local self = {}

    self.accounts = accounts
    self.coords = coords
    self.group = group
    self.identifier = identifier
    self.inventory = inventory
    self.job = job
    self.loadout = loadout
    self.name = name
    self.playerId = playerId
    self.source = playerId
    self.variables = {}
    self.weight = weight
    self.maxWeight = Config.MaxWeight
    self.metadata = metadata
    self.lastPlaytime = self.metadata.lastPlaytime or 0
    self.paycheckEnabled = true
    self.admin = Core.IsPlayerAdmin(playerId)
    if Config.Multichar then
        local startIndex = identifier:find(":", 1)
        if startIndex then
            self.license = ("%s%s"):format(Config.Identifer, identifier:sub(startIndex, identifier:len()))
        end
    else
        self.license = ("%s:%s"):format(Config.Identifer, identifier)
    end

    if type(self.metadata.jobDuty) ~= "boolean" then
        self.metadata.jobDuty = self.job.name ~= "unemployed" and Config.DefaultJobDuty or false
    end
    job.onDuty = self.metadata.jobDuty

    ExecuteCommand(("add_principal identifier.%s group.%s"):format(self.license, self.group))

    local stateBag = Player(self.source).state
    stateBag:set("identifier", self.identifier, false)
    stateBag:set("license", self.license, false)
    stateBag:set("job", self.job, true)
    stateBag:set("group", self.group, true)
    stateBag:set("name", self.name, true)

    ---@param eventName string
    ---@param ... any
    ---@return nil
    function self.triggerEvent(eventName, ...)
        assert(type(eventName) == "string", "eventName should be string!")
        TriggerClientEvent(eventName, self.source, ...)
    end

    ---@param toggle boolean
    ---@return nil
    function self.togglePaycheck(toggle)
        self.paycheckEnabled = toggle
    end

    ---@return boolean
    function self.isPaycheckEnabled()
        return self.paycheckEnabled
    end

    ---@return boolean
    function self.isAdmin()
        return Core.IsPlayerAdmin(self.source)
    end

    ---@param coordinates vector4 | vector3 | table
    ---@return nil
    function self.setCoords(coordinates)
        local ped <const> = GetPlayerPed(self.source)

        SetEntityCoords(ped, coordinates.x, coordinates.y, coordinates.z, false, false, false, false)
        SetEntityHeading(ped, coordinates.w or coordinates.heading or 0.0)
    end

    ---@param vector boolean
    ---@param heading boolean
    ---@return vector3 | vector4 | table
    function self.getCoords(vector, heading)
        local ped <const> = GetPlayerPed(self.source)
        local entityCoords <const> = GetEntityCoords(ped)
        local entityHeading <const> = GetEntityHeading(ped)

        local coordinates = { x = entityCoords.x, y = entityCoords.y, z = entityCoords.z }

        if vector then
            coordinates = (heading and vector4(entityCoords.x, entityCoords.y, entityCoords.z, entityHeading) or entityCoords)
        else
            if heading then
                coordinates.heading = entityHeading
            end
        end

        return coordinates
    end

    ---@param reason string
    ---@return nil
    function self.kick(reason)
        local source <const> = tostring(self.source)
        DropPlayer(source, reason)
    end

      ---@return number
    function self.getPlayTime()
        -- luacheck: ignore
        return self.lastPlaytime + GetPlayerTimeOnline(self.source)
    end

    ---@param money number
    ---@return nil
    function self.setMoney(money)
        assert(type(money) == "number", "money should be number!")
        money = ESX.Math.Round(money)
        self.setAccountMoney("money", money)
    end

    ---@return number
    function self.getMoney()
        return self.getAccount("money").money
    end

    ---@param money number
    ---@param reason string
    ---@return nil
    function self.addMoney(money, reason)
        money = ESX.Math.Round(money)
        self.addAccountMoney("money", money, reason)
    end

    ---@param money number
    ---@param reason string
    ---@return nil
    function self.removeMoney(money, reason)
        money = ESX.Math.Round(money)
        self.removeAccountMoney("money", money, reason)
    end

    ---@return string
    function self.getIdentifier()
        return self.identifier
    end

    ---@param newGroup string
    ---@return nil
    function self.setGroup(newGroup)
        local lastGroup = self.group

        ExecuteCommand(("remove_principal identifier.%s group.%s"):format(self.license, self.group))

        self.group = newGroup

        TriggerEvent("esx:setGroup", self.source, self.group, lastGroup)
        self.triggerEvent("esx:setGroup", self.group, lastGroup)
        Player(self.source).state:set("group", self.group, true)

        ExecuteCommand(("add_principal identifier.%s group.%s"):format(self.license, self.group))
    end

    ---@return string
    function self.getGroup()
        return self.group
    end

    ---@param k string
    ---@param v any
    ---@return nil
    function self.set(k, v)
        self.variables[k] = v
    end

    ---@param k string
    ---@return any
    function self.get(k)
        return self.variables[k]
    end

    ---@param minimal boolean
    ---@return table
    function self.getAccounts(minimal)
        if not minimal then
            return self.accounts
        end

        local minimalAccounts = {}

        for i = 1, #self.accounts do
            minimalAccounts[self.accounts[i].name] = self.accounts[i].money
        end

        return minimalAccounts
    end

    ---@param account string
    ---@return table | nil
    function self.getAccount(account)
        account = string.lower(account)
        for i = 1, #self.accounts do
            local accountName = string.lower(self.accounts[i].name)
            if accountName == account then
                return self.accounts[i]
            end
        end
        return nil
    end

    ---@param minimal boolean
    ---@return table
    function self.getInventory(minimal)
        if minimal then
            local minimalInventory = {}

            for _, v in ipairs(self.inventory) do
                if v.count > 0 then
                    minimalInventory[v.name] = v.count
                end
            end

            return minimalInventory
        end

        return self.inventory
    end

    ---@return table
    function self.getJob()
        return self.job
    end

    ---@param minimal boolean
    ---@return table
    function self.getLoadout(minimal)
        if not minimal then
            return self.loadout
        end
        local minimalLoadout = {}

        for _, v in ipairs(self.loadout) do
            minimalLoadout[v.name] = { ammo = v.ammo }
            if v.tintIndex > 0 then
                minimalLoadout[v.name].tintIndex = v.tintIndex
            end

            if #v.components > 0 then
                local components = {}

                for _, component in ipairs(v.components) do
                    if component ~= "clip_default" then
                        components[#components + 1] = component
                    end
                end

                if #components > 0 then
                    minimalLoadout[v.name].components = components
                end
            end
        end

        return minimalLoadout
    end

    ---@return string
    function self.getName()
        return self.name
    end

    ---@param newName string
    ---@return nil
    function self.setName(newName)
        self.name = newName
        Player(self.source).state:set("name", self.name, true)
    end

    ---@param accountName string
    ---@param money number
    ---@param reason string | nil
    ---@return nil
    function self.setAccountMoney(accountName, money, reason)
        reason = reason or "unknown"
        if not tonumber(money) then
            error(("Tried To Set Account ^5%s^1 For Player ^5%s^1 To An Invalid Number -> ^5%s^1"):format(accountName, self.playerId, money))
            return
        end
        if money >= 0 then
            local account = self.getAccount(accountName)

            if account then
                money = account.round and ESX.Math.Round(money) or money
                self.accounts[account.index].money = money

                self.triggerEvent("esx:setAccountMoney", account)
                TriggerEvent("esx:setAccountMoney", self.source, accountName, money, reason)
            else
                error(("Tried To Set Invalid Account ^5%s^1 For Player ^5%s^1!"):format(accountName, self.playerId))
            end
        else
            error(("Tried To Set Account ^5%s^1 For Player ^5%s^1 To An Invalid Number -> ^5%s^1"):format(accountName, self.playerId, money))
        end
    end

    ---@param accountName string
    ---@param money number
    ---@param reason string | nil
    ---@return nil
    function self.addAccountMoney(accountName, money, reason)
        reason = reason or "Unknown"
        if not tonumber(money) then
            error(("Tried To Set Account ^5%s^1 For Player ^5%s^1 To An Invalid Number -> ^5%s^1"):format(accountName, self.playerId, money))
            return
        end
        if money > 0 then
            local account = self.getAccount(accountName)
            if account then
                money = account.round and ESX.Math.Round(money) or money
                self.accounts[account.index].money = self.accounts[account.index].money + money

                self.triggerEvent("esx:setAccountMoney", account)
                TriggerEvent("esx:addAccountMoney", self.source, accountName, money, reason)
            else
                error(("Tried To Set Add To Invalid Account ^5%s^1 For Player ^5%s^1!"):format(accountName, self.playerId))
            end
        else
            error(("Tried To Set Account ^5%s^1 For Player ^5%s^1 To An Invalid Number -> ^5%s^1"):format(accountName, self.playerId, money))
        end
    end

    ---@param accountName string
    ---@param money number
    ---@param reason string | nil
    ---@return nil
    function self.removeAccountMoney(accountName, money, reason)
        reason = reason or "Unknown"
        if not tonumber(money) then
            error(("Tried To Set Account ^5%s^1 For Player ^5%s^1 To An Invalid Number -> ^5%s^1"):format(accountName, self.playerId, money))
            return
        end
        if money > 0 then
            local account = self.getAccount(accountName)

            if account then
                money = account.round and ESX.Math.Round(money) or money
                if self.accounts[account.index].money - money > self.accounts[account.index].money then
                    error(("Tried To Underflow Account ^5%s^1 For Player ^5%s^1!"):format(accountName, self.playerId))
                    return
                end
                self.accounts[account.index].money = self.accounts[account.index].money - money

                self.triggerEvent("esx:setAccountMoney", account)
                TriggerEvent("esx:removeAccountMoney", self.source, accountName, money, reason)
            else
                error(("Tried To Set Add To Invalid Account ^5%s^1 For Player ^5%s^1!"):format(accountName, self.playerId))
            end
        else
            error(("Tried To Set Account ^5%s^1 For Player ^5%s^1 To An Invalid Number -> ^5%s^1"):format(accountName, self.playerId, money))
        end
    end

    ---@param itemName string
    ---@return table | nil
    function self.getInventoryItem(itemName)
        for _, v in ipairs(self.inventory) do
            if v.name == itemName then
                return v
            end
        end
        return nil
    end

    ---@param itemName string
    ---@param count number
    ---@return nil
    function self.addInventoryItem(itemName, count)
        local item = self.getInventoryItem(itemName)

        if item then
            count = ESX.Math.Round(count)
            item.count = item.count + count
            self.weight = self.weight + (item.weight * count)

            TriggerEvent("esx:onAddInventoryItem", self.source, item.name, item.count)
            self.triggerEvent("esx:addInventoryItem", item.name, item.count)
        end
    end

    ---@param itemName string
    ---@param count number
    ---@return nil
    function self.removeInventoryItem(itemName, count)
        local item = self.getInventoryItem(itemName)

        if item then
            count = ESX.Math.Round(count)
            if count > 0 then
                local newCount = item.count - count

                if newCount >= 0 then
                    item.count = newCount
                    self.weight = self.weight - (item.weight * count)

                    TriggerEvent("esx:onRemoveInventoryItem", self.source, item.name, item.count)
                    self.triggerEvent("esx:removeInventoryItem", item.name, item.count)
                end
            else
                error(("Player ID:^5%s Tried remove a Invalid count -> %s of %s"):format(self.playerId, count, itemName))
            end
        end
    end

    ---@param itemName string
    ---@param count number
    ---@return nil
    function self.setInventoryItem(itemName, count)
        local item = self.getInventoryItem(itemName)

        if item and count >= 0 then
            count = ESX.Math.Round(count)

            if count > item.count then
                self.addInventoryItem(item.name, count - item.count)
            else
                self.removeInventoryItem(item.name, item.count - count)
            end
        end
    end

    ---@return number
    function self.getWeight()
        return self.weight
    end

    ---@return number
    function self.getSource()
        return self.source
    end
    self.getPlayerId = self.getSource

    ---@return number
    function self.getMaxWeight()
        return self.maxWeight
    end

    ---@param itemName string
    ---@param count number
    ---@return boolean
    function self.canCarryItem(itemName, count)
        if ESX.Items[itemName] then
            local currentWeight, itemWeight = self.weight, ESX.Items[itemName].weight
            local newWeight = currentWeight + (itemWeight * count)

            return newWeight <= self.maxWeight
        else
            print(('[^3WARNING^7] Item ^5"%s"^7 was used but does not exist!'):format(itemName))
            return false
        end
    end

    ---@param firstItem string
    ---@param firstItemCount number
    ---@param testItem string
    ---@param testItemCount number
    ---@return boolean
    function self.canSwapItem(firstItem, firstItemCount, testItem, testItemCount)
        local firstItemObject = self.getInventoryItem(firstItem)
        if not firstItemObject then
            return false
        end
        local testItemObject = self.getInventoryItem(testItem)
        if not testItemObject then
            return false
        end

        if firstItemObject.count >= firstItemCount then
            local weightWithoutFirstItem = ESX.Math.Round(self.weight - (firstItemObject.weight * firstItemCount))
            local weightWithTestItem = ESX.Math.Round(weightWithoutFirstItem + (testItemObject.weight * testItemCount))

            return weightWithTestItem <= self.maxWeight
        end

        return false
    end

    ---@param newWeight number
    ---@return nil
    function self.setMaxWeight(newWeight)
        self.maxWeight = newWeight
        self.triggerEvent("esx:setMaxWeight", self.maxWeight)
    end

    ---@param newJob string
    ---@param grade string
    ---@param onDuty? boolean
    ---@return nil
    function self.setJob(newJob, grade, onDuty)
        grade = tostring(grade)
        local lastJob = self.job

        if not ESX.DoesJobExist(newJob, grade) then
            return print(("[ESX] [^3WARNING^7] Ignoring invalid ^5.setJob()^7 usage for ID: ^5%s^7, Job: ^5%s^7"):format(self.source, newJob))
        end

        if newJob == "unemployed" then
            onDuty = false
        end

        if type(onDuty) ~= "boolean" then
            onDuty = Config.DefaultJobDuty
        end

        local jobObject, gradeObject = ESX.Jobs[newJob], ESX.Jobs[newJob].grades[grade]

        self.job = {
            id = jobObject.id,
            name = jobObject.name,
            label = jobObject.label,
            onDuty = onDuty,

            grade = tonumber(grade),
            grade_name = gradeObject.name,
            grade_label = gradeObject.label,
            grade_salary = gradeObject.salary,

            skin_male = gradeObject.skin_male and json.decode(gradeObject.skin_male) or {},
            skin_female = gradeObject.skin_female and json.decode(gradeObject.skin_female) or {},
        }

        self.metadata.jobDuty = onDuty
        TriggerEvent("esx:setJob", self.source, self.job, lastJob)
        self.triggerEvent("esx:setJob", self.job, lastJob)
        Player(self.source).state:set("job", self.job, true)
    end

    ---@param weaponName string
    ---@param ammo number
    ---@return nil
    function self.addWeapon(weaponName, ammo)
        if not self.hasWeapon(weaponName) then
            local weaponLabel <const> = ESX.GetWeaponLabel(weaponName)

            table.insert(self.loadout, {
                name = weaponName,
                ammo = ammo,
                label = weaponLabel,
                components = {},
                tintIndex = 0,
            })

            GiveWeaponToPed(GetPlayerPed(self.source), joaat(weaponName), ammo, false, false)
            self.triggerEvent("esx:addInventoryItem", weaponLabel, false, true)
        end
    end

    ---@param weaponName string
    ---@param weaponComponent string
    ---@return nil
    function self.addWeaponComponent(weaponName, weaponComponent)
        local loadoutNum <const>, weapon <const> = self.getWeapon(weaponName)

        if weapon then
            local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

            if component then
                if not self.hasWeaponComponent(weaponName, weaponComponent) then
                    self.loadout[loadoutNum].components[#self.loadout[loadoutNum].components + 1] = weaponComponent
                    local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash
                    GiveWeaponComponentToPed(GetPlayerPed(self.source), joaat(weaponName), componentHash)
                    self.triggerEvent("esx:addInventoryItem", component.label, false, true)
                end
            end
        end
    end

    ---@param weaponName string
    ---@param ammoCount number
    ---@return nil
    function self.addWeaponAmmo(weaponName, ammoCount)
        local _, weapon = self.getWeapon(weaponName)

        if weapon then
            weapon.ammo = weapon.ammo + ammoCount
            SetPedAmmo(GetPlayerPed(self.source), joaat(weaponName), weapon.ammo)
        end
    end

    ---@param weaponName string
    ---@param ammoCount number
    ---@return nil
    function self.updateWeaponAmmo(weaponName, ammoCount)
        local _, weapon = self.getWeapon(weaponName)

        if not weapon then
            return
        end

        weapon.ammo = ammoCount

        if weapon.ammo <= 0 then
            local _, weaponConfig = ESX.GetWeapon(weaponName)
            if weaponConfig.throwable then
                self.removeWeapon(weaponName)
            end
        end
    end

    ---@param weaponName string
    ---@param weaponTintIndex number
    ---@return nil
    function self.setWeaponTint(weaponName, weaponTintIndex)
        local loadoutNum <const>, weapon <const> = self.getWeapon(weaponName)

        if weapon then
            local _, weaponObject <const> = ESX.GetWeapon(weaponName)

            if weaponObject.tints and weaponObject.tints[weaponTintIndex] then
                self.loadout[loadoutNum].tintIndex = weaponTintIndex
                self.triggerEvent("esx:setWeaponTint", weaponName, weaponTintIndex)
                self.triggerEvent("esx:addInventoryItem", weaponObject.tints[weaponTintIndex], false, true)
            end
        end
    end

    ---@param weaponName string
    ---@return number
    function self.getWeaponTint(weaponName)
        local _, weapon <const> = self.getWeapon(weaponName)

        if weapon then
            return weapon.tintIndex
        end

        return 0
    end

    ---@param weaponName string
    ---@return nil
    function self.removeWeapon(weaponName)
        local weaponLabel, playerPed <const> = nil, GetPlayerPed(self.source)

        if not playerPed then
            return error("xPlayer.removeWeapon ^5invalid^1 player ped!")
        end

        for k, v in ipairs(self.loadout) do
            if v.name == weaponName then
                weaponLabel = v.label

                for _, v2 in ipairs(v.components) do
                    self.removeWeaponComponent(weaponName, v2)
                end

                local weaponHash = joaat(v.name)
                RemoveWeaponFromPed(playerPed, weaponHash)
                SetPedAmmo(playerPed, weaponHash, 0)

                table.remove(self.loadout, k)
                break
            end
        end

        if weaponLabel then
            self.triggerEvent("esx:removeInventoryItem", weaponLabel, false, true)
        end
    end

    ---@param weaponName string
    ---@param weaponComponent string
    ---@return nil
    function self.removeWeaponComponent(weaponName, weaponComponent)
        local loadoutNum <const>, weapon <const> = self.getWeapon(weaponName)

        if weapon then
            local component <const> = ESX.GetWeaponComponent(weaponName, weaponComponent)

            if component then
                if self.hasWeaponComponent(weaponName, weaponComponent) then
                    for k, v in ipairs(self.loadout[loadoutNum].components) do
                        if v == weaponComponent then
                            table.remove(self.loadout[loadoutNum].components, k)
                            break
                        end
                    end

                    self.triggerEvent("esx:removeWeaponComponent", weaponName, weaponComponent)
                    self.triggerEvent("esx:removeInventoryItem", component.label, false, true)
                end
            end
        end
    end

    ---@param weaponName string
    ---@param ammoCount number
    ---@return nil
    function self.removeWeaponAmmo(weaponName, ammoCount)
        local _, weapon = self.getWeapon(weaponName)

        if weapon then
            weapon.ammo = weapon.ammo - ammoCount
            SetPedAmmo(GetPlayerPed(self.source), joaat(weaponName), weapon.ammo)
        end
    end

    ---@param weaponName string
    ---@param weaponComponent string
    ---@return boolean
    function self.hasWeaponComponent(weaponName, weaponComponent)
        local _, weapon <const> = self.getWeapon(weaponName)

        if weapon then
            for _, v in ipairs(weapon.components) do
                if v == weaponComponent then
                    return true
                end
            end

            return false
        end

        return false
    end

    ---@param weaponName string
    ---@return boolean
    function self.hasWeapon(weaponName)
        for _, v in ipairs(self.loadout) do
            if v.name == weaponName then
                return true
            end
        end

        return false
    end

    ---@param item string
    ---@return table | false, number | nil
    function self.hasItem(item)
        for _, v in ipairs(self.inventory) do
            if v.name == item and v.count >= 1 then
                return v, v.count
            end
        end

        return false
    end

    ---@param weaponName string
    ---@return number | nil, table | nil
    function self.getWeapon(weaponName)
        for k, v in ipairs(self.loadout) do
            if v.name == weaponName then
                return k, v
            end
        end

        return nil, nil
    end

    ---@param msg string
    ---@param notifyType string
    ---@param length number
    ---@return nil
    function self.showNotification(msg, notifyType, length)
        self.triggerEvent("esx:showNotification", msg, notifyType, length)
    end

    ---@param sender string
    ---@param subject string
    ---@param msg string
    ---@param textureDict string
    ---@param iconType string
    ---@param flash boolean
    ---@param saveToBrief boolean
    ---@param hudColorIndex number
    ---@return nil
    function self.showAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
        self.triggerEvent("esx:showAdvancedNotification", sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    end

    ---@param msg string
    ---@param thisFrame boolean
    ---@param beep boolean
    ---@param duration number
    ---@return nil
    function self.showHelpNotification(msg, thisFrame, beep, duration)
        self.triggerEvent("esx:showHelpNotification", msg, thisFrame, beep, duration)
    end

    ---@param index any
    ---@param subIndex any
    ---@return table | nil
    function self.getMeta(index, subIndex)
        if not index then
            return self.metadata
        end

        if type(index) ~= "string" then
            error("xPlayer.getMeta ^5index^1 should be ^5string^1!")
            return
        end

        local metaData = self.metadata[index]
        if metaData == nil then
            return Config.EnableDebug and error(("xPlayer.getMeta ^5%s^1 not exist!"):format(index)) or nil
        end

        if subIndex and type(metaData) == "table" then
            local _type = type(subIndex)

            if _type == "string" then
                local value = metaData[subIndex]
                return value
            end

            if _type == "table" then
                local returnValues = {}

                for i = 1, #subIndex do
                    local key = subIndex[i]
                    if type(key) == "string" then
                        returnValues[key] = self.getMeta(index, key)
                    else
                        error(("xPlayer.getMeta subIndex should be ^5string^1 or ^5table^1! that contains ^5string^1, received ^5%s^1!, skipping..."):format(type(key)))
                    end
                end

                return returnValues
            end

            error(("xPlayer.getMeta subIndex should be ^5string^1 or ^5table^1!, received ^5%s^1!"):format(_type))
            return
        end

        return metaData
    end

    ---@param index any
    ---@param value any
    ---@param subValue any
    ---@return nil
    function self.setMeta(index, value, subValue)
        if not index then
            return error("xPlayer.setMeta ^5index^1 is Missing!")
        end

        if type(index) ~= "string" then
            return error("xPlayer.setMeta ^5index^1 should be ^5string^1!")
        end

        if value == nil then
            return error("xPlayer.setMeta value is missing!")
        end

        local _type = type(value)

        if not subValue then
            if _type ~= "number" and _type ~= "string" and _type ~= "table" then
                return error(("xPlayer.setMeta ^5%s^1 should be ^5number^1 or ^5string^1 or ^5table^1!"):format(value))
            end

            self.metadata[index] = value
        else
            if _type ~= "string" then
                return error(("xPlayer.setMeta ^5value^1 should be ^5string^1 as a subIndex!"):format(value))
            end

            if not self.metadata[index] or type(self.metadata[index]) ~= "table" then
                self.metadata[index] = {}
            end

            self.metadata[index] = type(self.metadata[index]) == "table" and self.metadata[index] or {}
            self.metadata[index][value] = subValue
        end
        self.triggerEvent('esx:updatePlayerData', 'metadata', self.metadata)
    end

    function self.clearMeta(index, subValues)
        if not index then
            return error("xPlayer.clearMeta ^5index^1 is Missing!")
        end

        if type(index) ~= "string" then
            return error("xPlayer.clearMeta ^5index^1 should be ^5string^1!")
        end

        local metaData = self.metadata[index]
        if metaData == nil then
            return Config.EnableDebug and error(("xPlayer.clearMeta ^5%s^1 does not exist!"):format(index)) or nil
        end

        if not subValues then
            -- If no subValues is provided, we will clear the entire value in the metaData table
            self.metadata[index] = nil
        elseif type(subValues) == "string" then
            -- If subValues is a string, we will clear the specific subValue within the table
            if type(metaData) == "table" then
                metaData[subValues] = nil
            else
                return error(("xPlayer.clearMeta ^5%s^1 is not a table! Cannot clear subValue ^5%s^1."):format(index, subValues))
            end
        elseif type(subValues) == "table" then
            -- If subValues is a table, we will clear multiple subValues within the table
            for i = 1, #subValues do
                local subValue = subValues[i]
                if type(subValue) == "string" then
                    if type(metaData) == "table" then
                        metaData[subValue] = nil
                    else
                        error(("xPlayer.clearMeta ^5%s^1 is not a table! Cannot clear subValue ^5%s^1."):format(index, subValue))
                    end
                else
                    error(("xPlayer.clearMeta subValues should contain ^5string^1, received ^5%s^1, skipping..."):format(type(subValue)))
                end
            end
        else
            return error(("xPlayer.clearMeta ^5subValues^1 should be ^5string^1 or ^5table^1, received ^5%s^1!"):format(type(subValues)))
        end
        self.triggerEvent('esx:updatePlayerData', 'metadata', self.metadata)
    end

    for _, funcs in pairs(Core.PlayerFunctionOverrides) do
        for fnName, fn in pairs(funcs) do
            self[fnName] = fn(self)
        end
    end

    return self
end

local function runStaticPlayerMethod(src, method, ...)
    local xPlayer = ESX.Players[src]
    if not xPlayer then
        return
    end

    if not ESX.IsFunctionReference(xPlayer[method]) then
        error(("Attempted to call invalid method on playerId %s: %s"):format(src, method))
    end

    return xPlayer[method](...)
end
exports("RunStaticPlayerMethod", runStaticPlayerMethod)
