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
    else
        print("[src-payphone] Standalone mode initialized")
    end
end)

Bridge = {}

Bridge.HasEnoughMoney = function(amount)
    if Config.Debug then
        return true 
    end
    
    if Config.Framework == "esx" or Config.Framework == "esxnew" then

        local xPlayer = ESX.GetPlayerData()
        return xPlayer.money >= amount
    
    elseif Config.Framework == "qbcore" then
        local Player = QBCore.Functions.GetPlayerData()
        return Player.money.cash >= amount
    else
        
        return true
    end
end

Bridge.RemoveMoney = function(amount)
    if Config.Debug then
        print("[src-payphone] Debug mode: Removing money: " .. amount)
        return true
    end
    
    if Config.Framework == "esx" or Config.Framework == "esxnew" then
        TriggerServerEvent('src-payphone:removeMoney', amount, 'esx')
        return true
    elseif Config.Framework == "qbcore" then
        TriggerServerEvent('src-payphone:removeMoney', amount, 'qbcore')
        return true
    else
        TriggerServerEvent('src-payphone:removeMoney', amount, 'standalone')
        return true
    end
end

Bridge.Notify = function(message, type)
    if Config.Framework == "esx" or Config.Framework == "esxnew" then
        ESX.ShowNotification(message)
    elseif Config.Framework == "qbcore" then
        QBCore.Functions.Notify(message, type)
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
