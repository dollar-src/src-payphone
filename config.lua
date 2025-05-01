Config = {}

-- Framework Settings
Config.Framework = "qbcore" -- Options: "qbcore", "esx", "standalone", "esxnew", "qbox" -> IMPORTANT: QBOX requires uncommenting line in fxmanifest.lua
Config.Target = "ox_target" -- Options: "ox_target", "qb-target"
Config.RemoveMoney = "framework" -- Options: "framework", "ox_inventory"

-- Call settings
Config.CallCostPer30Seconds = 25 -- Cost in dollars per 30 seconds
Config.CheckPaymentInterval = 30 -- Check payment every 30 seconds

-- Animation settings
Config.AnimDict = "anim@scripted@payphone_hits@male@"
Config.PhoneProp = "sf_prop_sf_phonebox_01b_s"

-- Target models
Config.PayphoneModels = {'prop_phonebox_01b', 'prop_phonebox_01c'}

-- Service Definitions
Config.Services = {
    {
        name = "police",
        label = "Police",
        number = "911",
        icon = "fas fa-shield-alt"
    },
    {
        name = "ambulance",
        label = "Ambulance",
        number = "112",
        icon = "fas fa-ambulance"
    },
    {
        name = "taxi",
        label = "Taxi",
        number = "311",
        icon = "fas fa-taxi"
    },
    {
        name = "mechanic",
        label = "Mechanic",
        number = "555",
        icon = "fas fa-wrench"
    }
}

-- Database Settings
Config.DatabaseTable = {
    Contacts = "phone_phone_contacts", -- Table name for phone contacts
    PhoneNumber = "phone_number", -- Column name for phone number in contacts table
    ContactNumber = "contact_phone_number" -- Column name for contact's phone number
}

-- UI Settings
Config.UISettings = {
    NotificationDuration = 3000, -- Duration of notifications in ms
    CallEndedDelay = 1000 -- Delay before hiding UI after call ends in ms
}

-- Debug Settings
Config.Debug = false -- Set to true to enable debug messages
-- Locale settings
Config.Locale = "en" -- Options: "en", "tr", "es", "no"

-- Localization
Config.Locales = {
    ['en'] = {
        ['payphone'] = 'PAYPHONE',
        ['calling'] = 'Calling...',
        ['connected'] = 'Connected',
        ['ended'] = 'Ended',
        ['number'] = 'Number',
        ['call_duration'] = 'Call Duration',
        ['next_payment'] = 'Next payment: in %s seconds',
        ['end_call_key'] = 'Press [BACKSPACE] to end call',
        ['enter_number'] = 'Enter Number',
        ['contacts'] = 'Contacts',
        ['quick_dial'] = 'Quick Dial',
        ['cancel'] = 'Cancel',
        ['call'] = 'Call (%s$)',
        ['call_cost_notice'] = 'Each call will cost %s$.',
        
        ['phone_unavailable'] = 'Phone is currently unavailable',
        ['not_enough_money'] = 'You don\'t have enough money. %s$ required.',
        ['payment_success'] = '%s$ paid. Call continues.',
        ['payment_failed'] = 'Not enough money. Ending call.',
        ['call_ended'] = 'Call ended',
        ['service_not_found'] = 'Service not found',
        ['service_calling'] = 'Calling %s...',
        ['enter_valid_number'] = 'Please enter a valid number'
    },
    ['tr'] = {
        ['payphone'] = 'ANKESÖRLÜ TELEFON',
        ['calling'] = 'Aranıyor...',
        ['connected'] = 'Bağlandı',
        ['ended'] = 'Sonlandırıldı',
        ['number'] = 'Numara',
        ['call_duration'] = 'Arama Süresi',
        ['next_payment'] = 'Sonraki ödeme: %s saniye',
        ['end_call_key'] = 'Aramayı sonlandırmak için [BACKSPACE]',
        ['enter_number'] = 'Numara Girin',
        ['contacts'] = 'Rehber Kişiler',
        ['quick_dial'] = 'Hızlı Arama',
        ['cancel'] = 'İptal',
        ['call'] = 'Ara (%s$)',
        ['call_cost_notice'] = 'Her arama başına %s$ ücret alınacaktır.',
        
        ['phone_unavailable'] = 'Telefon şu anda kullanılamıyor',
        ['not_enough_money'] = 'Arama yapmak için yeterli paranız yok. %s$ gerekiyor.',
        ['payment_success'] = '%s$ ödendi. Arama devam ediyor.',
        ['payment_failed'] = 'Yeterli paranız yok. Arama sonlandırılıyor.',
        ['call_ended'] = 'Arama sonlandırıldı',
        ['service_not_found'] = 'Servis bulunamadı',
        ['service_calling'] = '%s aranıyor...',
        ['enter_valid_number'] = 'Lütfen bir numara girin'
    },
    ['es'] = {
        ['payphone'] = 'TELÉFONO PÚBLICO',
        ['calling'] = 'Llamando...',
        ['connected'] = 'Conectado',
        ['ended'] = 'Finalizado',
        ['number'] = 'Número',
        ['call_duration'] = 'Duración de la llamada',
        ['next_payment'] = 'Próximo pago: en %s segundos',
        ['end_call_key'] = 'Presiona [BACKSPACE] para finalizar la llamada',
        ['enter_number'] = 'Ingresa el número',
        ['contacts'] = 'Contactos',
        ['quick_dial'] = 'Marcación rápida',
        ['cancel'] = 'Cancelar',
        ['call'] = 'Llamar (%s$)',
        ['call_cost_notice'] = 'Cada llamada costará %s$',
        
        ['phone_unavailable'] = 'El teléfono no está disponible en este momento',
        ['not_enough_money'] = 'No tienes suficiente dinero. Se requieren %s$',
        ['payment_success'] = 'Se pagaron %s$. La llamada continúa',
        ['payment_failed'] = 'No hay suficiente dinero. Finalizando llamada',
        ['call_ended'] = 'Llamada finalizada',
        ['service_not_found'] = 'Servicio no encontrado',
        ['service_calling'] = 'Llamando a %s...',
        ['enter_valid_number'] = 'Por favor ingresa un número válido'
    },
    ['no'] = {
        ['payphone'] = 'TELEFONKIOSK',
        ['calling'] = 'Ringer..',
        ['connected'] = 'Tilkoblet',
        ['ended'] = 'Avsluttet',
        ['number'] = 'Nummer',
        ['call_duration'] = 'Samtalelengde',
        ['next_payment'] = 'Neste betaling: om %s sekunder',
        ['end_call_key'] = 'Trykk [BACKSPACE] for å avslutte samtale',
        ['enter_number'] = 'Tast nummer',
        ['contacts'] = 'Kontakter',
        ['quick_dial'] = 'Hastig ring',
        ['cancel'] = 'Avbryt',
        ['call'] = 'Ring (%skr)',
        ['call_cost_notice'] = 'Hver samtale koster %skr.',
        
        ['phone_unavailable'] = 'Telefonen er ikke tilgjengelig',
        ['not_enough_money'] = 'Du har ikke nok pengar. %s$ er nødvendig.',
        ['payment_success'] = '%s$ betalt. Samtalen fortsetter.',
        ['payment_failed'] = 'Du har ikke nok pengar. Samtalen avsluttes.',
        ['call_ended'] = 'Samtalen avsluttet',
        ['service_not_found'] = 'Bedriften finnes ikke',
        ['service_calling'] = 'Ringer %s...',
        ['enter_valid_number'] = 'Vennligst tast et gyldig nummer'
    }
}

-- Phone Integration Functions
Config.PhoneIntegration = {
    -- Get player's phone number
    GetPhoneNumber = function(src)
        local success, phoneNumber = pcall(function()
            return exports["lb-phone"]:GetEquippedPhoneNumber(src)
        end)
        
        if success and phoneNumber then
            return phoneNumber
        else
            return "000-0000"
        end
    end,
    
    -- Check if player is in a call
    IsInCall = function(src)
        local success, inCall = pcall(function()
            return exports["lb-phone"]:IsInCall(src)
        end)
        
        if success then
            return inCall
        else
            return false
        end
    end,
    
    CreateCall = function(src, number, company)
        local options = {
            requirePhone = false,
            hideNumber = false
        }

        if company then
            options.company = company
        end
        
        local success, callId = pcall(function()
            return exports["lb-phone"]:CreateCall({
                phoneNumber = Config.Locales[Config.Locale].payphone,
                source = src
            }, number, options)
        end)
        
        if success and callId then
            return callId
        else
            return "call_" .. math.random(1000, 9999)
        end
    end,
    
    -- End a call
    EndCall = function(src)
        pcall(function()
            exports["lb-phone"]:EndCall(src)
        end)
        return true
    end,
    
    -- Get call details
    GetCall = function(callId)
        local success, call = pcall(function()
            return exports["lb-phone"]:GetCall(callId)
        end)
        
        if success and call then
            return call
        else
            return {
                active = false,
                answered = false
            }
        end
    end
}

function _(key, ...)
    local locale = Config.Locales[Config.Locale] or Config.Locales['en']
    local text = locale[key] or key
    
    if ... then
        text = string.format(text, ...)
    end
    
    return text
end
