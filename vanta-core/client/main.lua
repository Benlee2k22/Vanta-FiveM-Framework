local PlayerData, callbacks, requestId = {}, {}, 0

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data) if type(data) == 'table' then PlayerData = data end end)

RegisterNetEvent('vanta:client:loaded', function(data)
    PlayerData = data or {}
    TriggerEvent('Vanta:Client:OnPlayerLoaded', PlayerData)
end)
RegisterNetEvent('vanta:client:moneyChanged', function(kind, amount, action, reason)
    if PlayerData.money then PlayerData.money[kind] = amount end
    TriggerEvent('Vanta:Client:OnMoneyChange', kind, amount, action, reason)
    TriggerEvent('QBCore:Client:OnMoneyChange', kind, amount, action, reason)
end)
RegisterNetEvent('vanta:client:jobUpdated', function(job)
    PlayerData.job = job; TriggerEvent('Vanta:Client:OnJobUpdate', job); TriggerEvent('QBCore:Client:OnJobUpdate', job)
end)
RegisterNetEvent('vanta:client:inventoryUpdated', function(inventory) PlayerData.inventory = inventory or {}; PlayerData.items = PlayerData.inventory; TriggerEvent('Vanta:Client:OnInventoryUpdate', PlayerData.inventory) end)
RegisterNetEvent('vanta:client:applyBandage', function()
    local ped = PlayerPedId(); SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), GetEntityHealth(ped) + 35))
end)
RegisterNetEvent('vanta:client:callbackResult', function(id, ...) local cb = callbacks[id]; if cb then cb(...); callbacks[id] = nil end end)

VantaClient = {
    GetPlayerData = function() return PlayerData end,
    TriggerCallback = function(name, cb, ...)
        requestId = requestId + 1; callbacks[requestId] = cb or function() end
        TriggerServerEvent('vanta:server:triggerCallback', name, requestId, ...)
    end,
    Notify = function(message, kind, duration) TriggerEvent('vanta:ui:notify', { description = message, type = kind or 'info', duration = duration }) end,
    Progressbar = function(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
        exports['vanta-ui']:Progress({ label = label or name, duration = duration or 1000, canCancel = canCancel ~= false }, function(ok) if ok then if onFinish then onFinish() end elseif onCancel then onCancel() end end)
    end
}
exports('GetPlayerData', VantaClient.GetPlayerData)
exports('GetShared', function() return { Jobs = VantaConfig.Jobs, Items = VantaConfig.Items, Inventory = VantaConfig.Inventory, Gangs = {}, Vehicles = {} } end)
exports('TriggerCallback', VantaClient.TriggerCallback)
exports('Notify', VantaClient.Notify)
exports('Progressbar', VantaClient.Progressbar)

CreateThread(function()
    while true do Wait(30000); if PlayerData.citizenid and LocalPlayer.state.vantaSpawned then TriggerServerEvent('vanta:server:savePosition') end end
end)
