local createdProp = nil
local entity = nil
local heading = 0
local callActive = false
local callTimer = 0
local targetNumber = nil
local isEndingCall = false
local uiOpen = false
local isPhoneAvailable = true
local lastServerCheck = 0
local currentPayphoneCoords = nil
local ped = cache.ped

---@param newPed number - update cached ped if needed
lib.onCache("ped", function(newPed)
    ped = newPed
end)

local keybind = lib.addKeybind({
    name = 'endPayphoneCall',
    description = 'End payphone call',
    defaultKey = 'BACK',
    disabled = true,
    onPressed = function()
        if callActive and not isEndingCall then
            EndCall()
        end
    end
})

function ResetAllStates()
    if createdProp then
        DeleteEntity(createdProp)
        createdProp = nil
    end
    
    if entity then
        SetEntityVisible(entity, true, 0)
        entity = nil
    end
    
    heading = 0
    callActive = false
    keybind:disable(true)
    callTimer = 0
    targetNumber = nil
    isEndingCall = false
    currentPayphoneCoords = nil
    
    HideCallStatus()
    HideInputDialog()
    uiOpen = false
    
    ClearPedTasks(ped)
    
    Citizen.SetTimeout(2000, function()
        isPhoneAvailable = true
    end)
end

function CheckPlayerHasEnoughMoney()
    local callCost = Config.CallCostPer30Seconds
    if Bridge.HasEnoughMoney(callCost) then
        return true
    else
        Bridge.Notify(_('not_enough_money', callCost), "error")
        HideCallStatus()

        return false
    end
end

function CreatePayphoneProp(data, number, company)
    if not isPhoneAvailable or callActive or isEndingCall then 
        Bridge.Notify(_('phone_unavailable'), "error")
        HideCallStatus()
        return 
    end
    
    if not CheckPlayerHasEnoughMoney() then
        return
    end
    
    local coords = GetEntityCoords(data.entity)
    local coordsString = string.format("%.2f,%.2f,%.2f", coords.x, coords.y, coords.z)
    
    TriggerServerEvent('src-payphone:checkPayphoneAvailability', coordsString, company)
    
    currentPayphoneCoords = coordsString
    isPhoneAvailable = false
end


RegisterNetEvent('src-payphone:payphoneAvailabilityResult')
AddEventHandler('src-payphone:payphoneAvailabilityResult', function(isAvailable, company)
    if not isAvailable then
        Bridge.Notify(_('phone_unavailable'), "error")
        HideCallStatus()
        isPhoneAvailable = true
        currentPayphoneCoords = nil
        return
    end
    
    if not entity or not currentPayphoneCoords then
        isPhoneAvailable = true
        return
    end
    
    if createdProp then
        DeleteEntity(createdProp)
        createdProp = nil
    end
    
    if entity then
        SetEntityVisible(entity, false, 0)
    end
    
    local coords = GetEntityCoords(entity)
    
    createdProp = CreateObjectNoOffset(GetHashKey(Config.PhoneProp), coords.x, coords.y, coords.z, true, true, true)
    SetEntityHeading(createdProp, GetEntityHeading(entity))
    SetEntityCompletelyDisableCollision(createdProp, false, false)
    
    heading = GetEntityHeading(entity)
    
    local offset = GetOffsetFromEntityInWorldCoords(entity, -0.10, -0.85, 0.0)
    SetEntityCoords(ped, offset.x, offset.y, offset.z, false, false, false, false)
    SetEntityHeading(ped, heading)
    
    StartPhoneAnimation()
    
    Bridge.RemoveMoney(Config.CallCostPer30Seconds)
    
    targetNumber = targetNumber
    TriggerServerEvent('src-payphone:startCall', targetNumber, company, currentPayphoneCoords)
    
    ShowCallStatus({
        number = targetNumber,
        company = company,
        answered = false
    })
    
    callActive = true
    keybind:disable(false)
    callTimer = 0
    isEndingCall = false
    lastServerCheck = GetGameTimer()
    
    Citizen.CreateThread(function()
        while callActive and not isEndingCall do
            Citizen.Wait(2000)
            TriggerServerEvent('src-payphone:checkCallStatus')
            lastServerCheck = GetGameTimer()
        end
    end)
end)

function StartPhoneAnimation()
    RequestAnimDict(Config.AnimDict)
    while not HasAnimDictLoaded(Config.AnimDict) do
        Wait(10)
    end
    
    PlayEntityAnim(createdProp, "fxfr_pcn_1_intro_phone", Config.AnimDict, 10.0, true, true, true, 0.0, false)
    TaskPlayAnim(ped, Config.AnimDict, "fxfr_phl_1_intro_male", 8.0, 8.0, -1, 14, 0, false, false, false)
end

function EndCall()
    if not callActive or isEndingCall then return end
    
    isEndingCall = true
    isPhoneAvailable = false
    
    TriggerServerEvent('src-payphone:endCall')
    
    SendNUIMessage({
        action = 'callEnded'
    })
    
    RequestAnimDict(Config.AnimDict)
    while not HasAnimDictLoaded(Config.AnimDict) do
        Wait(10)
    end
    
    TaskPlayAnim(ped, Config.AnimDict, "exit_left_male", 8.0, 8.0, -1, 1, 0, false, false, false)
    Wait(200)
    
    if createdProp then
        StopEntityAnim(createdProp, "fxfr_pcn_1_intro_phone", Config.AnimDict, 1000.0)
    end
    StopAnimTask(ped, Config.AnimDict, "fxfr_ptj_1_male", 1.0)
    
    Wait(2800)
    
    ResetAllStates()
    
    TriggerServerEvent('src-payphone:forceReset')
end

function FetchPlayerContacts()
    TriggerServerEvent('src-payphone:getContacts')
end

RegisterNetEvent('src-payphone:callStatus')
AddEventHandler('src-payphone:callStatus', function(status)
    if not callActive then return end
    
    lastServerCheck = GetGameTimer()
    
    if status.active then
        ShowCallStatus({
            number = targetNumber,
            answered = status.answered,
            timeUntilNextPayment = status.timeUntilNextPayment
        })
    else
        EndCall()
    end
end)

RegisterNetEvent('src-payphone:callStatusCheck')
AddEventHandler('src-payphone:callStatusCheck', function(isStillActive)
    if not callActive then return end
    
    lastServerCheck = GetGameTimer()
    
    if not isStillActive then
        EndCall()
    end
end)

RegisterNetEvent('src-payphone:callEnded')
AddEventHandler('src-payphone:callEnded', function()
    SendNUIMessage({
        action = 'callEnded'
    })
    
    if callActive then
        EndCall()
    else
        ResetAllStates()
    end
end)

---@param amount number         - amount of money to remove
---@return boolean              - if player has enough money
lib.callback.register('src-payphone:requestPayment', function(amount)
    if Bridge.HasEnoughMoney(amount) then
        Bridge.RemoveMoney(amount)
        Bridge.Notify(_('payment_success', amount), 'success')
        return true
    else
        Bridge.Notify(_('payment_failed'), 'error')
        return false
    end
end)

RegisterNetEvent('src-payphone:receiveContacts')
AddEventHandler('src-payphone:receiveContacts', function(contactList)
    SendNUIMessage({
        action = 'setContacts',
        contacts = contactList
    })
end)

RegisterNetEvent('src-payphone:usePayphone')
AddEventHandler('src-payphone:usePayphone', function(data)
    if not isPhoneAvailable or callActive or isEndingCall then
        Bridge.Notify(_('phone_unavailable'), "error")
        return
    end
    
    entity = data.entity
    ShowInputDialog()
end)

RegisterNetEvent('src-payphone:notifyClient')
AddEventHandler('src-payphone:notifyClient', function(message, type)
    Bridge.Notify(message, type)
end)

function ShowCallStatus(data)
    SendNUIMessage({
        action = 'showCallStatus',
        number = data.number,
        answered = data.answered,
        timeUntilNextPayment = data.timeUntilNextPayment,
        company = data.company,
        locale = Config.Locale,
        locales = Config.Locales
    })
    SetNuiFocus(false, false)
    uiOpen = true
end

function HideCallStatus()
    SendNUIMessage({
        action = 'hideCallStatus'
    })
    SetNuiFocus(false, false)
    uiOpen = false
end

function SendServicesToUI()
    SendNUIMessage({
        action = 'setServices',
        services = Config.Services
    })
end

function ShowInputDialog()
    if not isPhoneAvailable then
        Bridge.Notify(_('phone_unavailable'), "error")
        return
    end
    
    FetchPlayerContacts()
    SendServicesToUI()
    
    SendNUIMessage({
        action = 'showInputDialog',
        callCost = Config.CallCostPer30Seconds,
        locale = Config.Locale,
        locales = Config.Locales
    })
    SetNuiFocus(true, true)
    uiOpen = true
end

function HideInputDialog()
    SendNUIMessage({
        action = 'hideInputDialog'
    })
    SetNuiFocus(false, false)
    uiOpen = false
end

RegisterNUICallback('inputSubmit', function(data, cb)
    local number = data.number
    if number and entity then
        if CheckPlayerHasEnoughMoney() then
            targetNumber = number
            CreatePayphoneProp({entity = entity}, number)
        end
    end
    cb('ok')
end)

RegisterNUICallback('inputCancel', function(data, cb)
    HideInputDialog()
    cb('ok')
end)

RegisterNUICallback('escapePressed', function(data, cb)
    if uiOpen then
        HideInputDialog()
    end
    cb('ok')
end)

RegisterNUICallback('backspacePressed', function(data, cb)
    if callActive then
        EndCall()
    end
    cb('ok')
end)

RegisterNUICallback('endCall', function(data, cb)
    if callActive then
        EndCall()
    end
    cb('ok')
end)

RegisterNUICallback('getContacts', function(data, cb)
    FetchPlayerContacts()
    cb('ok')
end)

RegisterNUICallback('callCompany', function(data, cb)
    local companyName = data.company
    if companyName and entity then
        if not CheckPlayerHasEnoughMoney() then
            cb('ok')
            return
        end
        
        local selectedService = nil
        for _, service in ipairs(Config.Services) do
            if service.name == companyName then
                selectedService = service
                break
            end
        end
        
        if selectedService then
            targetNumber = selectedService.number
            CreatePayphoneProp({entity = entity}, selectedService.number, selectedService.name)
            Bridge.Notify(_('service_calling', selectedService.label), "info")
        else
            Bridge.Notify(_('service_not_found'), "error")
        end
    end
    cb('ok')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ResetAllStates()
        
        if callActive then
            TriggerServerEvent('src-payphone:endCall')
        end
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ResetAllStates()
        
        SendServicesToUI()
        
        Citizen.SetTimeout(1000, function()
            local options = {
                {
                    name = 'payphone',
                    icon = 'fas fa-phone',
                    label = _('payphone'),
                    onSelect = function(data)
                        if not isPhoneAvailable or callActive or isEndingCall then
                            Bridge.Notify(_('phone_unavailable'), "error")
                            return
                        end
                        
                        entity = data.entity
                        ShowInputDialog()
                    end,
                }
            }
            
            Bridge.RegisterTarget(Config.PayphoneModels, options)
        end)
    end
end)

RegisterNUICallback('getServices', function(data, cb)
    SendServicesToUI()
    cb('ok')
end)
