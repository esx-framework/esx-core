SettingsHandler = {}
SettingsHandler.stored = {}

function SettingsHandler:Get(resource, key)
    if not self.stored[resource] then
        return nil
    end
    if not self.stored[resource][key] then
        return nil
    end
    return self.stored[resource][key].value
end

function SettingsHandler:Set(resource, key, value)
    if not self.stored[resource] or not self.stored[resource][key] then
        return
    end

    local data = self.stored[resource][key]
    if value == data.value then
        return
    end

    if data.dataType == "number" then
        value = tonumber(value)
    elseif data.dataType == "boolean" then
        value = value == "true"
    elseif data.dataType == "string" then
        value = tostring(value)
    end

    self.stored[resource][key].value = value

    TriggerEvent("es_extended:SettingChanged", resource, data.category, key, value)
    TriggerClientEvent("es_extended:internal:SettingChanged", -1, resource, data.category, key, value)
end

function SettingsHandler:RegisterSetting(resource, key, name, category, value)
    if not self.stored[resource] then
        self.stored[resource] = {}
    end
    if not self.stored[resource][key] then
        self.stored[resource][key] = {
            name = name,
            category = category,
            value = value,
            dataType = type(value)
        }
    end
end

---@param key string
---@param name string
---@param category string
---@param value any
---@return nil
function ESX.RegisterSetting(key, name, category, value)
    SettingsHandler:RegisterSetting(GetInvokingResource() or "es_extended", key,name, category, value)
end

---@param key string
---@param value any
---@return nil
function ESX.SetSetting(key, value)
    SettingsHandler:Set(GetInvokingResource() or "es_extended", key, value)
end

ESX.RegisterServerCallback("esx:getSettings", function(_, cb)
    local settings = {}
    for resource, keys in pairs(SettingsHandler.stored) do
        settings[resource] = {}
        for key, data in pairs(keys) do
            settings[resource][key] = data.value
        end
    end
    cb(settings)
end)

function SettingsHandler:Load()
    local file = LoadResourceFile("es_extended", "data/settings.json")
    if file then
        local settings = json.decode(file)
        for resource, keys in pairs(settings) do
            if not self.stored[resource] then
                self.stored[resource] = {}
            end
            for key, value in pairs(keys) do
                self.stored[resource][key] = value
            end
        end
    end
end

function SettingsHandler:Save()
    SaveResourceFile("es_extended", "data/settings.json", json.encode(self.stored, { indent = true }), -1)
end

SettingsHandler:Load()
