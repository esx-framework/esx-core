function ESX.Trace(msg)
  if Config.EnableDebug then
    print(('[^2TRACE^7] %s^7'):format(msg))
  end
end

function ESX.SetTimeout(msec, cb)
  local id = Core.TimeoutCount + 1

  SetTimeout(msec, function()
    if Core.CancelledTimeouts[id] then
      Core.CancelledTimeouts[id] = nil
    else
      cb()
    end
  end)

  Core.TimeoutCount = id

  return id
end

function ESX.RegisterCommand(name, group, cb, allowConsole, suggestion)
  if type(name) == 'table' then
    for k, v in ipairs(name) do
      ESX.RegisterCommand(v, group, cb, allowConsole, suggestion)
    end

    return
  end

  if Core.RegisteredCommands[name] then
    print(('[^3WARNING^7] Command ^5"%s" ^7already registered, overriding command'):format(name))

    if Core.RegisteredCommands[name].suggestion then
      TriggerClientEvent('chat:removeSuggestion', -1, ('/%s'):format(name))
    end
  end

  if suggestion then
    if not suggestion.arguments then
      suggestion.arguments = {}
    end
    if not suggestion.help then
      suggestion.help = ''
    end

    TriggerClientEvent('chat:addSuggestion', -1, ('/%s'):format(name), suggestion.help, suggestion.arguments)
  end

  Core.RegisteredCommands[name] = {group = group, cb = cb, allowConsole = allowConsole, suggestion = suggestion}

  RegisterCommand(name, function(playerId, args, rawCommand)
    local command = Core.RegisteredCommands[name]

    if not command.allowConsole and playerId == 0 then
      print(('[^3WARNING^7] ^5%s'):format(TranslateCap('commanderror_console')))
    else
      local xPlayer, error = ESX.Players[playerId], nil

      if command.suggestion then
        if command.suggestion.validate then
          if #args ~= #command.suggestion.arguments then
            error = TranslateCap('commanderror_argumentmismatch', #args, #command.suggestion.arguments)
          end
        end

        if not error and command.suggestion.arguments then
          local newArgs = {}

          for k, v in ipairs(command.suggestion.arguments) do
            if v.type then
              if v.type == 'number' then
                local newArg = tonumber(args[k])

                if newArg then
                  newArgs[v.name] = newArg
                else
                  error = TranslateCap('commanderror_argumentmismatch_number', k)
                end
              elseif v.type == 'player' or v.type == 'playerId' then
                local targetPlayer = tonumber(args[k])

                if args[k] == 'me' then
                  targetPlayer = playerId
                end

                if targetPlayer then
                  local xTargetPlayer = ESX.GetPlayerFromId(targetPlayer)

                  if xTargetPlayer then
                    if v.type == 'player' then
                      newArgs[v.name] = xTargetPlayer
                    else
                      newArgs[v.name] = targetPlayer
                    end
                  else
                    error = TranslateCap('commanderror_invalidplayerid')
                  end
                else
                  error = TranslateCap('commanderror_argumentmismatch_number', k)
                end
              elseif v.type == 'string' then
                newArgs[v.name] = args[k]
              elseif v.type == 'item' then
                if ESX.Items[args[k]] then
                  newArgs[v.name] = args[k]
                else
                  error = TranslateCap('commanderror_invaliditem')
                end
              elseif v.type == 'weapon' then
                if ESX.GetWeapon(args[k]) then
                  newArgs[v.name] = string.upper(args[k])
                else
                  error = TranslateCap('commanderror_invalidweapon')
                end
              elseif v.type == 'any' then
                newArgs[v.name] = args[k]
              end
            end

            if v.validate == false then
              error = nil
            end

            if error then
              break
            end
          end

          args = newArgs
        end
      end

      if error then
        if playerId == 0 then
          print(('[^3WARNING^7] %s^7'):format(error))
        else
          xPlayer.showNotification(error)
        end
      else
        cb(xPlayer or false, args, function(msg)
          if playerId == 0 then
            print(('[^3WARNING^7] %s^7'):format(msg))
          else
            xPlayer.showNotification(msg)
          end
        end)
      end
    end
  end, true)

  if type(group) == 'table' then
    for k, v in ipairs(group) do
      ExecuteCommand(('add_ace group.%s command.%s allow'):format(v, name))
    end
  else
    ExecuteCommand(('add_ace group.%s command.%s allow'):format(group, name))
  end
end

function ESX.ClearTimeout(id)
  Core.CancelledTimeouts[id] = true
end

function ESX.RegisterServerCallback(name, cb)
  Core.ServerCallbacks[name] = cb
end

function ESX.TriggerServerCallback(name, requestId, source,Invoke, cb, ...)
  if Core.ServerCallbacks[name] then
    Core.ServerCallbacks[name](source, cb, ...)
  else
    print(('[^1ERROR^7] Server callback ^5"%s"^0 does not exist. Please Check ^5%s^7 for Errors!'):format(name, Invoke))
  end
end

function Core.SavePlayer(xPlayer, cb)
  MySQL.prepare(
    'UPDATE `users` SET `accounts` = ?, `job` = ?, `job_grade` = ?, `group` = ?, `position` = ?, `inventory` = ?, `loadout` = ? WHERE `identifier` = ?',
    {json.encode(xPlayer.getAccounts(true)), xPlayer.job.name, xPlayer.job.grade, xPlayer.group, json.encode(xPlayer.getCoords()),
     json.encode(xPlayer.getInventory(true)), json.encode(xPlayer.getLoadout(true)), xPlayer.identifier}, function(affectedRows)
      if affectedRows == 1 then
        print(('[^2INFO^7] Saved player ^5"%s^7"'):format(xPlayer.name))
        TriggerEvent('esx:playerSaved', xPlayer.playerId, xPlayer)
      end
      if cb then
        cb()
      end
    end)
end

function Core.SavePlayers(cb)
  local xPlayers = ESX.GetExtendedPlayers()
  local count = #xPlayers
  if count > 0 then
    local parameters = {}
    local time = os.time()
    for i = 1, count do
      local xPlayer = xPlayers[i]
      parameters[#parameters + 1] = {json.encode(xPlayer.getAccounts(true)), xPlayer.job.name, xPlayer.job.grade, xPlayer.group,
                                     json.encode(xPlayer.getCoords()), json.encode(xPlayer.getInventory(true)), json.encode(xPlayer.getLoadout(true)),
                                     xPlayer.identifier}
    end
    MySQL.prepare(
      "UPDATE `users` SET `accounts` = ?, `job` = ?, `job_grade` = ?, `group` = ?, `position` = ?, `inventory` = ?, `loadout` = ? WHERE `identifier` = ?",
      parameters, function(results)
        if results then
          if type(cb) == 'function' then
            cb()
          else
            print(('[^2INFO^7] Saved ^5%s^7 %s over ^5%s^7 ms'):format(count, count > 1 and 'players' or 'player', ESX.Math.Round((os.time() - time) / 1000000, 2)))
          end
        end
      end)
  end
end

function ESX.GetPlayers()
  local sources = {}

  for k, v in pairs(ESX.Players) do
    sources[#sources + 1] = k
  end

  return sources
end

function ESX.GetExtendedPlayers(key, val)
  local xPlayers = {}
  for k, v in pairs(ESX.Players) do
    if key then
      if (key == 'job' and v.job.name == val) or v[key] == val then
        xPlayers[#xPlayers + 1] = v
      end
    else
      xPlayers[#xPlayers + 1] = v
    end
  end
  return xPlayers
end

function ESX.GetPlayerFromId(source)
  return ESX.Players[tonumber(source)]
end

function ESX.GetPlayerFromIdentifier(identifier)
  for k, v in pairs(ESX.Players) do
    if v.identifier == identifier then
      return v
    end
  end
end

function ESX.GetIdentifier(playerId)
  local fxDk = GetConvarInt('sv_fxdkMode', 0) 
  if fxDk == 1 then
    return "ESX-DEBUG-LICENCE"
  end
  for k, v in ipairs(GetPlayerIdentifiers(playerId)) do
    if string.match(v, 'license:') then
      local identifier = string.gsub(v, 'license:', '')
      return identifier
    end
  end
end

function ESX.GetVehicleType(Vehicle, Player, cb)
  Core.CurrentRequestId = Core.CurrentRequestId < 65535 and Core.CurrentRequestId + 1 or 0
  Core.ClientCallbacks[Core.CurrentRequestId] = cb
  TriggerClientEvent("esx:GetVehicleType", Player, Vehicle, Core.CurrentRequestId)
end

function ESX.DiscordLog(name, title, color, message)

  local webHook = Config.DiscordLogs.Webhooks[name] or Config.DiscordLogs.Webhooks.default
  local embedData = {{
      ['title'] = title,
      ['color'] = Config.DiscordLogs.Colors[color] or Config.DiscordLogs.Colors.default,
      ['footer'] = {
          ['text'] = "| ESX Logs | " .. os.date(),
          ['icon_url'] = "https://cdn.discordapp.com/attachments/944789399852417096/1020099828266586193/blanc-800x800.png"
      },
      ['description'] = message,
      ['author'] = {
          ['name'] = "ESX Framework",
          ['icon_url'] = "https://cdn.discordapp.com/emojis/939245183621558362.webp?size=128&quality=lossless"
      }
  }}
  PerformHttpRequest(webHook, nil, 'POST', json.encode({
      username = 'Logs',
      embeds = embedData
  }), {
      ['Content-Type'] = 'application/json'
  })
end

function ESX.DiscordLogFields(name, title, color, fields)
  local webHook = Config.DiscordLogs.Webhooks[name] or Config.DiscordLogs.Webhooks.default
  local embedData = {{
      ['title'] = title,
      ['color'] = Config.DiscordLogs.Colors[color] or Config.DiscordLogs.Colors.default,
      ['footer'] = {
          ['text'] = "| ESX Logs | " .. os.date(),
          ['icon_url'] = "https://cdn.discordapp.com/attachments/944789399852417096/1020099828266586193/blanc-800x800.png"
      },
      ['fields'] = fields, 
      ['description'] = "",
      ['author'] = {
          ['name'] = "ESX Framework",
          ['icon_url'] = "https://cdn.discordapp.com/emojis/939245183621558362.webp?size=128&quality=lossless"
      }
  }}
  PerformHttpRequest(webHook, nil, 'POST', json.encode({
      username = 'Logs',
      embeds = embedData
  }), {
      ['Content-Type'] = 'application/json'
  })
end

function ESX.RefreshJobs()
  local Jobs = {}
  local jobs = MySQL.query.await('SELECT * FROM jobs')

  for _, v in ipairs(jobs) do
    Jobs[v.name] = v
    Jobs[v.name].grades = {}
  end

  local jobGrades = MySQL.query.await('SELECT * FROM job_grades')

  for _, v in ipairs(jobGrades) do
    if Jobs[v.job_name] then
      Jobs[v.job_name].grades[tostring(v.grade)] = v
    else
      print(('[^3WARNING^7] Ignoring job grades for ^5"%s"^0 due to missing job'):format(v.job_name))
    end
  end

  for _, v in pairs(Jobs) do
    if ESX.Table.SizeOf(v.grades) == 0 then
      Jobs[v.name] = nil
      print(('[^3WARNING^7] Ignoring job ^5"%s"^0 due to no job grades found'):format(v.name))
    end
  end

  if not Jobs then
    -- Fallback data, if no jobs exist
    ESX.Jobs['unemployed'] = {label = 'Unemployed', grades = {['0'] = {grade = 0, label = 'Unemployed', salary = 200, skin_male = {}, skin_female = {}}}}
  else
    ESX.Jobs = Jobs
  end
end

function ESX.AddJob(jobObject)
  if type(jobObject) ~= "table" then
    return false, "invalid_job_object"
  end

  local jobsTable, queries = {}, {}
  local currentJobs = ESX.GetJobs()

  if jobObject.name then
    jobsTable[1] = {
      name = ((jobObject.name and type(jobObject.name) == "string") and jobObject.name) or -1,
      label = ((jobObject.label and type(jobObject.label) == "string") and jobObject.label) or -1,
      whitelisted = ((jobObject.whitelisted ~= nil and (type(jobObject.whitelisted) == "number" or type(jobObject.whitelisted) == "boolean")) and jobObject.whitelisted) or jobObject.whitelisted == nil and -1,
      grades = ((jobObject.grades and type(jobObject.grades) == "table") and jobObject.grades) or -1,
    }
  else
    for index, jobObj in pairs(jobObject) do
      jobsTable[index] = {
        name = ((jobObj.name and type(jobObj.name) == "string") and jobObj.name) or -1,
        label = ((jobObj.label and type(jobObj.label) == "string") and jobObj.label) or -1,
        whitelisted = ((jobObj.whitelisted ~= nil and (type(jobObj.whitelisted) == "number" or type(jobObj.whitelisted) == "boolean")) and jobObj.whitelisted) or jobObj.whitelisted == nil and -1,
        grades = ((jobObj.grades and type(jobObj.grades) == "table") and jobObj.grades) or -1,
      }
    end
  end

  for index, jobObj in pairs(jobsTable) do
    for key, value in pairs(jobObj) do
      if value == -1 then
        return false, ("invalid_job_%s_parameter"):format(key)
      end
      if key == "name" and currentJobs[value] then
        return false, "job_already_exists"
      elseif key == "grades" then
        if type(value) ~= "table" or not next(value) then return false, "invalid_job_grades_object" end
        for gradeKey, gradeObject in pairs(value) do
          local gradeKeyToNumber = tonumber(gradeKey)
          if type(gradeKey) ~= "string" and (gradeKeyToNumber and type(gradeKeyToNumber) ~= "number") then return false, "invalid_job_grade_key" end
          if type(gradeObject) ~= "table" then return false, "invalid_job_grade_object" end
          local gradeObj = {
            grade = gradeKeyToNumber or -1,
            name = ((gradeObject.name and type(gradeObject.name) == "string") and gradeObject.name) or -1,
            label = ((gradeObject.label and type(gradeObject.label) == "string") and gradeObject.label) or -1,
            salary = ((gradeObject.salary and type(gradeObject.salary) == "number") and gradeObject.salary) or -1,
            skin_male = ((gradeObject.skin_male and type(gradeObject.skin_male) == "table") and (next(gradeObject.skin_male) and json.encode(gradeObject.skin_male) or "{}")) or -1,
            skin_female = ((gradeObject.skin_female and type(gradeObject.skin_female) == "table") and (next(gradeObject.skin_female) and json.encode(gradeObject.skin_female) or "{}")) or -1,
          }
          for key2, value2 in pairs(gradeObj) do
            if value2 == -1 then
              return false, ("invalid_grade_%s_%s_parameter"):format(gradeKey, key2)
            end
          end
          queries[#queries+1] = {
            query = "INSERT INTO `job_grades` SET `job_name` = ?, `grade` = ?, `name` = ?, `label` = ?, `salary` = ?, `skin_male` = ?, `skin_female` = ?",
            values = {jobsTable[index].name, gradeObj.grade, gradeObj.name, gradeObj.label, gradeObj.salary, gradeObj.skin_male, gradeObj.skin_female}
          }
          gradeKeyToNumber, gradeObj = nil, nil
        end
      end
    end
    queries[#queries+1] = {
      query = "INSERT INTO `jobs` SET `name` = ?, `label` = ?, `whitelisted` = ?",
      values = {jobsTable[index].name, jobsTable[index].label, jobsTable[index].whitelisted}
    }
  end

  if not MySQL.transaction.await(queries) then
    return false, "error_in_executing_queries"
  end

  for index in pairs(jobsTable) do
    print(('[^2INFO^7] Job ^5"%s"^7 (%s) has been added'):format(jobsTable[index].label, jobsTable[index].name))
  end

  jobObject, jobsTable, queries, currentJobs = nil, nil, nil, nil

  ESX.RefreshJobs()
  return true, "job_added_successfully"
end

function ESX.UpdateJob(jobObject)
  if type(jobObject) ~= "table" then
    return false, "invalid_job_object"
  end

  local jobsTable, queries = {}, {}
  local currentJobs = ESX.GetJobs()

  if jobObject.name then
    if not currentJobs[jobObject.name] then return false, ("job_%s_does_not_exist"):format(jobObject.name) end
    jobsTable[1] = {
      name = ((jobObject.name and type(jobObject.name) == "string") and jobObject.name) or -1,
      label = ((jobObject.label and type(jobObject.label) == "string") and jobObject.label) or currentJobs[jobObject.name].label or -1,
      whitelisted = ((jobObject.whitelisted ~= nil and (type(jobObject.whitelisted) == "number" or type(jobObject.whitelisted) == "boolean")) and jobObject.whitelisted) or jobObject.whitelisted == nil and (currentJobs[jobObject.name].whitelisted or currentJobs[jobObject.name].whitelisted == nil and -1),
      grades = ((jobObject.grades and type(jobObject.grades) == "table") and jobObject.grades) or currentJobs[jobObject.name].grades or -1,
    }
  else
    for index, jobObj in pairs(jobObject) do
      if not currentJobs[jobObj.name] then return false, ("job_%s_does_not_exist"):format(jobObj.name) end
      jobsTable[index] = {
        name = ((jobObj.name and type(jobObj.name) == "string") and jobObj.name) or -1,
        label = ((jobObj.label and type(jobObj.label) == "string") and jobObj.label) or currentJobs[jobObj.name].label or -1,
        whitelisted = ((jobObj.whitelisted ~= nil and (type(jobObj.whitelisted) == "number" or type(jobObj.whitelisted) == "boolean")) and jobObj.whitelisted) or jobObj.whitelisted == nil and (currentJobs[jobObj.name].whitelisted or currentJobs[jobObj.name].whitelisted == nil and -1),
        grades = ((jobObj.grades and type(jobObj.grades) == "table") and jobObj.grades) or currentJobs[jobObj.name].grades or -1,
      }
    end
  end

  for index, jobObj in pairs(jobsTable) do
    for key, value in pairs(jobObj) do
      if value == -1 then
        return false, ("invalid_job_%s_parameter"):format(key)
      end
      if key == "grades" then
        if type(value) ~= "table" or not next(value) then return false, "invalid_job_grades_object" end
        for gradeKey, gradeObject in pairs(value) do
          local gradeKeyToNumber = tonumber(gradeKey)
          if type(gradeKey) ~= "string" and (gradeKeyToNumber and type(gradeKeyToNumber) ~= "number") then return false, "invalid_job_grade_key" end
          if type(gradeObject) ~= "table" then return false, "invalid_job_grade_object" end
          local currentJobGradeObject = currentJobs[jobsTable[index].name].grades[gradeKey]
          local gradeObj = {
            grade = gradeKeyToNumber or -1,
            name = ((gradeObject.name and type(gradeObject.name) == "string") and gradeObject.name) or currentJobGradeObject.name or -1,
            label = ((gradeObject.label and type(gradeObject.label) == "string") and gradeObject.label) or currentJobGradeObject.label or -1,
            salary = ((gradeObject.salary and type(gradeObject.salary) == "number") and gradeObject.salary) or currentJobGradeObject.salary or -1,
            skin_male = ((gradeObject.skin_male and type(gradeObject.skin_male) == "table") and (next(gradeObject.skin_male) and json.encode(gradeObject.skin_male) or "{}")) or currentJobGradeObject.skin_male or -1,
            skin_female = ((gradeObject.skin_female and type(gradeObject.skin_female) == "table") and (next(gradeObject.skin_female) and json.encode(gradeObject.skin_female) or "{}")) or currentJobGradeObject.skin_female or -1,
          }
          for key2, value2 in pairs(gradeObj) do
            if value2 == -1 then
              return false, ("invalid_grade_%s_%s_parameter"):format(gradeKey, key2)
            end
          end
          queries[#queries+1] = {
            query = "DELETE FROM `job_grades` WHERE `job_name` = ? AND `grade` = ?",
            values = {jobsTable[index].name, gradeObj.grade}
          }
          queries[#queries+1] = {
            query = "INSERT INTO `job_grades` SET `job_name` = ?, `grade` = ?, `name` = ?, `label` = ?, `salary` = ?, `skin_male` = ?, `skin_female` = ?",
            values = {jobsTable[index].name, gradeObj.grade, gradeObj.name, gradeObj.label, gradeObj.salary, gradeObj.skin_male, gradeObj.skin_female}
          }
          gradeKeyToNumber, gradeObj = nil, nil
        end
      end
    end
    queries[#queries+1] = {
      query = "REPLACE INTO `jobs` SET `name` = ?, `label` = ?, `whitelisted` = ?",
      values = {jobsTable[index].name, jobsTable[index].label, jobsTable[index].whitelisted}
    }
  end

  if not MySQL.transaction.await(queries) then
    return false, "error_in_executing_queries"
  end

  for index in pairs(jobsTable) do
    print(('[^2INFO^7] Job ^5"%s"^7 (%s) has been updated'):format(jobsTable[index].label, jobsTable[index].name))
  end

  jobObject, jobsTable, queries, currentJobs = nil, nil, nil, nil

  ESX.RefreshJobs()
  return true, "job_updated_successfully"
end

function ESX.RegisterUsableItem(item, cb)
  Core.UsableItemsCallbacks[item] = cb
end

function ESX.UseItem(source, item, ...)
  if ESX.Items[item] then
    local itemCallback = Core.UsableItemsCallbacks[item]

    if itemCallback then
      local success, result = pcall(itemCallback, source, item, ...)

      if not success then
        return result and print(result) or
                 print(('[^3WARNING^7] An error occured when using item ^5"%s"^7! This was not caused by ESX.'):format(item))
      end
    end
  else
    print(('[^3WARNING^7] Item ^5"%s"^7 was used but does not exist!'):format(item))
  end
end

function ESX.RegisterPlayerFunctionOverrides(index, overrides)
  Core.PlayerFunctionOverrides[index] = overrides
end

function ESX.SetPlayerFunctionOverride(index)
  if not index or not Core.PlayerFunctionOverrides[index] then
    return print('[^3WARNING^7] No valid index provided.')
  end

  Config.PlayerFunctionOverride = index
end

function ESX.GetItemLabel(item)
  if Config.OxInventory then
    item = exports.ox_inventory:Items(item)
    if item then
      return item.label
    end
  end

  if ESX.Items[item] then
    return ESX.Items[item].label
  else
    print('[^3WARNING^7] Attemting to get invalid Item -> ^5' .. item .. "^7")
  end
end

function ESX.GetJobs()
  return ESX.Jobs
end

function ESX.GetUsableItems()
  local Usables = {}
  for k in pairs(Core.UsableItemsCallbacks) do
    Usables[k] = true
  end
  return Usables
end

if not Config.OxInventory then
  function ESX.CreatePickup(type, name, count, label, playerId, components, tintIndex)
    local pickupId = (Core.PickupId == 65635 and 0 or Core.PickupId + 1)
    local xPlayer = ESX.Players[playerId]
    local coords = xPlayer.getCoords()

    Core.Pickups[pickupId] = {type = type, name = name, count = count, label = label, coords = coords}

    if type == 'item_weapon' then
      Core.Pickups[pickupId].components = components
      Core.Pickups[pickupId].tintIndex = tintIndex
    end

    TriggerClientEvent('esx:createPickup', -1, pickupId, label, coords, type, name, components, tintIndex)
    Core.PickupId = pickupId
  end
end

function ESX.DoesJobExist(job, grade)
  grade = tostring(grade)

  if job and grade then
    if ESX.Jobs[job] and ESX.Jobs[job].grades[grade] then
      return true
    end
  end

  return false
end

function Core.IsPlayerAdmin(playerId)
  if (IsPlayerAceAllowed(playerId, 'command') or GetConvar('sv_lan', '') == 'true') and true or false then
    return true
  end

  local xPlayer = ESX.Players[playerId]

  if xPlayer then
    if xPlayer.group == 'admin' then
      return true
    end
  end

  return false
end
