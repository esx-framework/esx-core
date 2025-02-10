Settings = {}
Settings.stored = {}

function Settings:Fetch()
    self.stored = ESX.AwaitServerCallback("esx:getSettings")
end

function Settings:Get(resource, key)
    return self.stored[resource][key]
end

function Settings:Set(resource, key, value)
    self.stored[resource][key] = value
end

ESX.SecureNetEvent("es_extended:internal:SettingChanged", function(resource, category, key, value)
    Settings:Set(resource, key, value)
    TriggerEvent("es_extended:settingChanged", resource, category, key, value)
end)
