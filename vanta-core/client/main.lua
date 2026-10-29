local PlayerData, callbacks, requestId = {}, {}, 0

RegisterNetEvent('vanta:client:loaded', function(data) PlayerData = data or {}; TriggerEvent('Vanta:Client:OnPlayerLoaded', PlayerData) end)
RegisterNetEvent('vanta:client:moneyChanged', function(kind, amount, action, reason) if PlayerData.money then PlayerData.money[kind] = amount end; TriggerEvent('Vanta:Client:OnMoneyChange', kind, amount, action, reason) end)
RegisterNetEvent('vanta:client:jobUpdated', function(job) PlayerData.job = job; TriggerEvent('Vanta:Client:OnJobUpdate', job) end)
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
exports('TriggerCallback', VantaClient.TriggerCallback)
exports('Notify', VantaClient.Notify)
exports('Progressbar', VantaClient.Progressbar)
