local QBCore = nil
local ESX = nil

Citizen.CreateThread(function()
    if Config.Framework == "esx" then
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(0)
        end
        print("[src-payphone] ESX Framework initialized")
    elseif Config.Framework == "esxnew" then
        ESX = exports["es_extended"]:getSharedObject()

        print("[src-payphone] ESX New Framework initialized")
    elseif Config.Framework == "qbcore" then
        QBCore = exports['qb-core']:GetCoreObject()
        print("[src-payphone] QBCore Framework initialized")
    elseif Config.Framework == "qbox" then
        if not QBX then return error("^4[src-payphone]^7 ^1QBX not found.^7 ^2Uncomment line in fxmanifest.lua^7") end
        print("[src-payphone] QBox Framework initialized")
    else
        print("[src-payphone] Standalone mode initialized")
    end
end)

Bridge = {}

Bridge.HasEnoughMoney = function(amount)
    if Config.Debug then
        return true 
    end


    if Config.RemoveMoney == "ox_inventory" then
        return exports.ox_inventory:GetItemCount("cash") >= amount

    elseif Config.Framework == "esx" or Config.Framework == "esxnew" then
        local xPlayer = ESX.GetPlayerData()
        return xPlayer.money >= amount

    elseif Config.Framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayerData()
        return Player.money.cash >= amount

    elseif Config.Framework == "qbox" then
        return QBX.PlayerData.money.cash >= amount
    else

        return true
    end
end

Bridge.RemoveMoney = function(amount)
    if Config.Debug then
        print("[src-payphone] Debug mode: Removing money: " .. amount)
        return true
    end

    if Config.RemoveMoney == "ox_inventory" then
        return lib.callback.await('src-payphone:removeMoney', false, amount, "ox_inventory")
    else
        return lib.callback.await('src-payphone:removeMoney', false, amount, Config.Framework)
    end
end

Bridge.Notify = function(message, type)
    if Config.Framework == "esx" or Config.Framework == "esxnew" then
        ESX.ShowNotification(message)
    elseif Config.Framework == "qbcore" then
        QBCore.Functions.Notify(message, type)
    elseif Config.Framework == "qbox" then
        exports.qbx_core:Notify(message, type)
    else
        lib.notify({
            title = 'Payphone',
            description = message,
            type = type or 'info'
        })
    end
end

Bridge.RegisterTarget = function(models, options)
    if Config.Target == "ox_target" then
        exports.ox_target:addModel(models, options)
    elseif Config.Target == "qb-target" then
        local qbOptions = {
            options = {},
            distance = 2.0
        }
        
        for _, option in ipairs(options) do
            table.insert(qbOptions.options, {
                type = "client",
                event = "src-payphone:usePayphone",
                icon = option.icon,
                label = option.label,
                entity = option.entity,
                canInteract = function(entity)
                    entity = entity
                    return true
                end
            })
        end
        
        exports['qb-target']:AddTargetModel(models, qbOptions)
    else
        print("[src-payphone] No target system specified in config")
    end
end

function splitString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end
