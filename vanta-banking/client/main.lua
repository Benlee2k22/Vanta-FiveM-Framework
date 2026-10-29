local open, currentMode = false, 'bank'
local function registerInteractions()
    for _, location in ipairs(VantaBankConfig.Locations) do
        exports['vanta-ui']:AddInteraction('vanta-bank:'..location.id, {
            coords = location.coords, distance = location.radius, label = location.label,
            options = { { label = location.type == 'atm' and 'Use ATM' or 'Access bank', event = 'vanta-banking:client:open', type = 'client', args = { mode = location.type } } }
        })
    end
end
CreateThread(function() while GetResourceState('vanta-ui') ~= 'started' do Wait(250) end; registerInteractions() end)

RegisterNetEvent('vanta-banking:client:open', function(options)
    currentMode = options and options.mode or 'bank'; open = true
    local data = exports['vanta-core']:GetPlayerData() or {}
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'bank:open', mode = currentMode, money = data.money or {} })
    TriggerServerEvent('vanta-banking:server:history')
end)
RegisterNetEvent('vanta-banking:client:history', function(rows) SendNUIMessage({ action = 'bank:history', rows = rows or {} }) end)
RegisterNetEvent('vanta-banking:client:result', function(result)
    SendNUIMessage({ action = 'bank:result', result = result })
    if result and result.message then TriggerEvent('vanta:ui:notify', { title = 'Vanta Bank', description = result.message, type = result.ok and 'success' or 'error' }) end
    if result and result.money then SendNUIMessage({ action = 'bank:money', money = result.money }) end
    if result and result.ok then TriggerServerEvent('vanta-banking:server:history') end
end)
RegisterNUICallback('bank:close', function(_, cb) open = false; SetNuiFocus(false, false); cb({ ok = true }) end)
RegisterNUICallback('bank:submit', function(data, cb)
    if currentMode == 'atm' and data.action == 'transfer' then cb({ ok = false }); return end
    TriggerServerEvent('vanta-banking:server:action', data)
    cb({ ok = true })
end)
AddEventHandler('onResourceStop', function(resource) if resource == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)
