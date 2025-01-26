function StartPayCheck()
    CreateThread(function()
        while true do
            Wait(Config.PaycheckInterval)
            for player, xPlayer in pairs(ESX.Players) do
                local jobLabel = xPlayer.job.label
                local job = xPlayer.job.grade_name
                local onDuty = xPlayer.job.onDuty
                local salary = (job == "unemployed" or onDuty) and xPlayer.job.grade_salary or ESX.Math.Round(xPlayer.job.grade_salary * Config.OffDutyPaycheckMultiplier)

                if xPlayer.paycheckEnabled then
                    if salary > 0 then
                        if job == "unemployed" then -- unemployed
                            xPlayer.addAccountMoney("bank", salary, "Welfare Check")
                            TriggerClientEvent("esx:showNotification", player, TranslateCap("received_help", salary))
                            if Config.LogPaycheck then
                                ESX.DiscordLogFields("Paycheck", "Paycheck - Unemployment Benefits", "green", {
                                    { name = "Player", value = xPlayer.name, inline = true },
                                    { name = "ID", value = xPlayer.source, inline = true },
                                    { name = "Amount", value = salary, inline = true },
                                })
                            end
                        elseif Config.EnableSocietyPayouts then -- possibly a society
                            TriggerEvent("esx_society:getSociety", xPlayer.job.name, function(society)
                                if society ~= nil then -- verified society
                                    TriggerEvent("esx_addonaccount:getSharedAccount", society.account, function(account)
                                        if account.money >= salary then -- does the society money to pay its employees?
                                            xPlayer.addAccountMoney("bank", salary, "Paycheck")
                                            account.removeMoney(salary)
                                            if Config.LogPaycheck then
                                                ESX.DiscordLogFields("Paycheck", "Paycheck - " .. jobLabel, "green", {
                                                    { name = "Player", value = xPlayer.name, inline = true },
                                                    { name = "ID", value = xPlayer.source, inline = true },
                                                    { name = "Amount", value = salary, inline = true },
                                                })
                                            end
                                            TriggerClientEvent("esx:showNotification", player, TranslateCap("received_salary", salary))
                                        else
                                            TriggerClientEvent("esx:showNotification", player, TranslateCap("company_nomoney"))
                                        end
                                    end)
                                else -- not a society
                                    xPlayer.addAccountMoney("bank", salary, "Paycheck")
                                    if Config.LogPaycheck then
                                        ESX.DiscordLogFields("Paycheck", "Paycheck - " .. jobLabel, "green", {
                                            { name = "Player", value = xPlayer.name, inline = true },
                                            { name = "ID", value = xPlayer.source, inline = true },
                                            { name = "Amount", value = salary, inline = true },
                                        })
                                    end
                                    TriggerClientEvent("esx:showNotification", player, TranslateCap("received_salary", salary))
                                end
                            end)
                        else -- generic job
                            xPlayer.addAccountMoney("bank", salary, "Paycheck")
                            if Config.LogPaycheck then
                                ESX.DiscordLogFields("Paycheck", "Paycheck - Generic", "green", {
                                    { name = "Player", value = xPlayer.name, inline = true },
                                    { name = "ID", value = xPlayer.source, inline = true },
                                    { name = "Amount", value = salary, inline = true },
                                })
                            end
                            TriggerClientEvent("esx:showNotification", player, TranslateCap("received_salary", salary))
                        end
                    end
                end
            end
        end
    end)
end
