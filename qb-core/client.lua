local callbacks, requestId = {}, 0
local QBCore = { Config = {}, Shared = exports['vanta-core']:GetShared(), Functions = {} }

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
    local data = exports['vanta-core']:GetPlayerData() or {}
    local inventory = data.inventory or data.items or {}
    local function contains(name) for _, item in ipairs(inventory) do if item.name == name and (tonumber(item.amount) or 0) > 0 then return true end end; return false end
    if type(items) == 'string' then return contains(items) end
    if type(items) == 'table' then for name, required in pairs(items) do if type(name) == 'number' then name, required = required, 1 end; local found = false; for _, item in ipairs(inventory) do if item.name == name and (tonumber(item.amount) or 0) >= (tonumber(required) or 1) then found = true; break end end; if not found then return false end end; return true end
    return false
end
RegisterNetEvent('QBCore:Client:TriggerCallback', function(id, ...)
    local cb = callbacks[id]; if cb then cb(...); callbacks[id] = nil end
end)
RegisterNetEvent('QBCore:Notify', function(message, kind, duration) QBCore.Functions.Notify(message, kind, duration) end)
exports('GetCoreObject', function() return QBCore end)
