local activeCalls = {}
local activePayphones = {}
local QBCore = nil
local ESX = nil

Citizen.CreateThread(function()
    if Config.Framework == "esx" then
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    elseif Config.Framework == "esxnew" then
        ESX = exports["es_extended"]:getSharedObject()
    elseif Config.Framework == "qbcore" then
        QBCore = exports['qb-core']:GetCoreObject()
    end
end)

function ResetPlayerCallState(src)
    if not activeCalls[src] then return end
    
    Config.PhoneIntegration.EndCall(src)
    
    if activeCalls[src].payphoneCoords then
        activePayphones[activeCalls[src].payphoneCoords] = nil
    end
    
    activeCalls[src] = nil
    
    TriggerClientEvent('src-payphone:callEnded', src)
end

function GetPlayerPhoneNumber(src)
    local playerNumber = nil
    local success = false
    
    success, playerNumber = pcall(function()
        return Config.PhoneIntegration.GetPhoneNumber(src)
    end)
    
    if not success or not playerNumber then
        playerNumber = "000-0000"
    end
    
    return playerNumber
end

---@param source number         - player id
---@param amount number         - amount of money to remove
---@param removeHandler string  - handler to remove money
---@return boolean              - if money was removed
lib.callback.register('src-payphone:removeMoney', function(source, amount, removeHandler)
    if removeHandler == "ox_inventory" then
        return exports.ox_inventory:RemoveItem(source, "cash", amount)

    elseif removeHandler == "esx" or removeHandler == "esxnew" then
        if ESX then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.removeMoney(amount)
                return true --removeMoney in esx dont return anything
            end
        end

    elseif removeHandler == "qbcore" then
        if QBCore then
            local Player = QBCore.Functions.GetPlayer(source)
            if Player then
                return Player.Functions.RemoveMoney('cash', amount, "payphone-call")
            end
        end

    elseif removeHandler == "qbox" then
        local Player = exports.qbx_core:GetPlayer(source)
        if Player then
            return Player.Functions.RemoveMoney('cash', amount, "payphone-call")
        end

    else
        warn("[src-payphone] Create standalone implementation for removeMoney. Money not removed")
        return true
    end
end)

RegisterNetEvent('src-payphone:startCall')
AddEventHandler('src-payphone:startCall', function(number, company, payphoneCoords)
    local src = source
    
    if activePayphones[payphoneCoords] and activePayphones[payphoneCoords] ~= src then
        TriggerClientEvent('src-payphone:notifyClient', src, _('phone_unavailable'), 'error')
        return
    end
    
    activePayphones[payphoneCoords] = src
    
    if activeCalls[src] then
        ResetPlayerCallState(src)
        Citizen.Wait(500)
    end
    
    local callId = Config.PhoneIntegration.CreateCall(src, number, company)
    
    if not callId then
        TriggerClientEvent('src-payphone:callEnded', src)
        activePayphones[payphoneCoords] = nil
        return
    end
    
    activeCalls[src] = {
        callId = callId,
        number = number,
        company = company,
        active = true,
        answered = false,
        started = os.time(),
        nextPaymentDue = 0,
        timeUntilNextPayment = 0,
        payphoneCoords = payphoneCoords
    }
    
    TriggerClientEvent('src-payphone:callStatus', src, activeCalls[src])
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)
            
            if not DoesPlayerExist(src) then
                ResetPlayerCallState(src)
                break
            end
            
            local inCall = Config.PhoneIntegration.IsInCall(src)
            
            if not inCall then
                ResetPlayerCallState(src)
                break
            end
            
            if activeCalls[src] then
                local call = Config.PhoneIntegration.GetCall(activeCalls[src].callId)
                
                if call then
                    if call.answered and not activeCalls[src].answered then
                        activeCalls[src].answered = true
                        activeCalls[src].nextPaymentDue = os.time() + Config.CheckPaymentInterval
                    end
                    
                    if activeCalls[src].answered then
                        activeCalls[src].timeUntilNextPayment = activeCalls[src].nextPaymentDue - os.time()
                        
                        if activeCalls[src].timeUntilNextPayment <= 0 then
                            local success = lib.callback.await('src-payphone:requestPayment', src, Config.CallCostPer30Seconds)
                            if not success then
                                ResetPlayerCallState(src)
                            end
                            activeCalls[src].nextPaymentDue = os.time() + Config.CheckPaymentInterval
                            activeCalls[src].timeUntilNextPayment = Config.CheckPaymentInterval
                        end
                    end
                    
                    TriggerClientEvent('src-payphone:callStatus', src, activeCalls[src])
                else
                    ResetPlayerCallState(src)
                    break
                end
            else
                break
            end
        end
    end)
end)

RegisterNetEvent('src-payphone:endCall')
AddEventHandler('src-payphone:endCall', function()
    local src = source
    ResetPlayerCallState(src)
end)

RegisterNetEvent('src-payphone:checkCallStatus')
AddEventHandler('src-payphone:checkCallStatus', function()
    local src = source
    
    local inCall = Config.PhoneIntegration.IsInCall(src)
    
    TriggerClientEvent('src-payphone:callStatusCheck', src, inCall)
    
    if not inCall and activeCalls[src] then
        ResetPlayerCallState(src)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    ResetPlayerCallState(src)
end)

function DoesPlayerExist(playerId)
    return GetPlayerPing(playerId) > 0
end

RegisterNetEvent('src-payphone:getContacts')
AddEventHandler('src-payphone:getContacts', function()
    local src = source
    local playerNumber = GetPlayerPhoneNumber(src)
    
    if not playerNumber or playerNumber == "000-0000" then
        TriggerClientEvent('src-payphone:receiveContacts', src, {})
        return
    end
    
    MySQL.Async.fetchAll('SELECT * FROM ' .. Config.DatabaseTable.Contacts .. ' WHERE ' .. Config.DatabaseTable.PhoneNumber .. ' = @phone_number ORDER BY favourite DESC, firstname ASC', {
        ['@phone_number'] = playerNumber
    }, function(contacts)
        if contacts and #contacts > 0 then
            TriggerClientEvent('src-payphone:receiveContacts', src, contacts)
        else
            TriggerClientEvent('src-payphone:receiveContacts', src, {})
        end
    end)
end)

RegisterNetEvent('src-payphone:forceReset')
AddEventHandler('src-payphone:forceReset', function()
    local src = source
    ResetPlayerCallState(src)
end)

RegisterNetEvent('src-payphone:checkPayphoneAvailability')
AddEventHandler('src-payphone:checkPayphoneAvailability', function(coords, company)
    local src = source
    local isAvailable = not activePayphones[coords]
    TriggerClientEvent('src-payphone:payphoneAvailabilityResult', src, isAvailable, company)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        
        for src, _ in pairs(activeCalls) do
            local inCall = Config.PhoneIntegration.IsInCall(src)
            
            if not inCall then
                ResetPlayerCallState(src)
            end
        end
    end
end)
