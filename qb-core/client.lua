local callbacks, requestId = {}, 0
local QBCore = { Config = {}, Shared = { Items = {}, Jobs = { unemployed = { label = 'Unemployed' } }, Gangs = {}, Vehicles = {} }, Functions = {} }

QBCore.Functions.GetPlayerData = function() return exports['vanta-core']:GetPlayerData() end
QBCore.Functions.TriggerCallback = function(name, cb, ...)
    requestId = requestId + 1; callbacks[requestId] = cb or function() end
    TriggerServerEvent('QBCore:Server:TriggerCallback', name, requestId, ...)
end
QBCore.Functions.Notify = function(message, kind, duration)
    TriggerEvent('vanta:ui:notify', { description = message, type = kind or 'primary', duration = duration })
end
QBCore.Functions.Progressbar = function(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    exports['vanta-ui']:Progress({ label = label or name, duration = duration or 1000, canCancel = canCancel ~= false }, function(ok)
        if ok then if onFinish then onFinish() end elseif onCancel then onCancel() end
    end)
end
QBCore.Functions.GetCoords = function(entity) return GetEntityCoords(entity) end
QBCore.Functions.HasItem = function(items)
    -- No inventory is bundled yet; return false until an inventory adapter is installed.
    return false
end
RegisterNetEvent('QBCore:Client:TriggerCallback', function(id, ...)
    local cb = callbacks[id]; if cb then cb(...); callbacks[id] = nil end
end)
RegisterNetEvent('QBCore:Notify', function(message, kind, duration) QBCore.Functions.Notify(message, kind, duration) end)
exports('GetCoreObject', function() return QBCore end)
