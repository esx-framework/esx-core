---@diagnostic disable: duplicate-set-field

Callbacks = {}

Callbacks.requests = {}
Callbacks.storage = {}
Callbacks.id = 0

function Callbacks:Trigger(event, cb, invoker, ...)

    self.requests[self.id] = {
        await = type(cb) == "boolean",
        cb = cb or promise:new()
    }
    local table = self.requests[self.id]

    TriggerServerEvent("esx:triggerServerCallback", event, self.id, invoker, ...)

    self.id += 1

    return table.cb
end

function Callbacks:Execute(cb, id, ...)
    local success, errorString = pcall(cb, ...)

    if not success then
        print(("[^1ERROR^7] Failed to execute Callback with RequestId: ^5%s^7"):format(id))
        error(errorString)
        return
    end
end

function Callbacks:ServerRecieve(requestId, invoker, ...)
    if not self.requests[requestId] then
        return error(("Server Callback with requestId ^5%s^1 Was Called by ^5%s^1 but does not exist."):format(requestId, invoker))
    end

    local callback = self.requests[requestId]

    self.requests[requestId] = nil

    if callback.await then
        callback.cb:resolve({...})
    else
        self:Execute(callback.cb, requestId, ...)
    end
end

function Callbacks:Register(name, cb)
    self.storage[name] = cb
end

function Callbacks:ClientRecieve(eventName, requestId, invoker, ...)

    if not self.storage[eventName] then
        return error(("Client Callback with requestId ^5%s^1 Was Called by ^5%s^1 but does not exist."):format(eventName, invoker))
    end

    local returnCb = function(...)
        TriggerServerEvent("esx:clientCallback", requestId, invoker, ...)
    end
    local callback = self.storage[eventName]

    self:Execute(callback, requestId, returnCb, ...)
end

---@param eventName string
---@param callback function
---@param ... any
---@return nil
ESX.TriggerServerCallback = function(eventName, callback, ...)
    local invokingResource = GetInvokingResource()
    local invoker = (invokingResource and invokingResource ~= "unknown") and invokingResource or "es_extended"

    Callbacks:Trigger(eventName, callback, invoker, ...)
end

---@param eventName string
---@param ... any
---@return any
ESX.AwaitServerCallback = function(eventName, ...)
    local invokingResource = GetInvokingResource()
    local invoker = (invokingResource and invokingResource ~= "unknown") and invokingResource or "es_extended"

    local p = Callbacks:Trigger(eventName, false, invoker, ...)
    if not p then return end

    -- if the server callback takes longer than 15 seconds to respond, reject the promise
    SetTimeout(15000, function()
        if p.state == "pending" then
            p:reject("Server Callback Timed Out")
        end
    end)

    Citizen.Await(p)

    return table.unpack(p.value)
end

ESX.SecureNetEvent("esx:serverCallback", function(...)
    Callbacks:ServerRecieve(...)
end)

---@param eventName string
---@param callback function
---@return nil
ESX.RegisterClientCallback = function(eventName, callback)
    Callbacks:Register(eventName, callback)
end

ESX.SecureNetEvent("esx:triggerClientCallback", function(...)
    Callbacks:ClientRecieve(...)
end)
