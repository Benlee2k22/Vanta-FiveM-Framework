local callbacks = {}
local QBCore = { Config = {}, Shared = { Items = {}, Jobs = { unemployed = { label = 'Unemployed', grades = { ['0'] = { name = 'Trainee' } } } }, Gangs = {}, Vehicles = {} }, Functions = {} }

local function playerWrapper(src)
    local data = exports['vanta-core']:GetPlayerData(src)
    if not data then return nil end
    local f = {}
    f.GetName = function() return data.charinfo.firstname .. ' ' .. data.charinfo.lastname end
    f.GetMoney = function(kind) return tonumber(data.money[kind]) or 0 end
    f.AddMoney = function(kind, amount, reason) return exports['vanta-core']:AddMoney(src, kind, amount, reason) end
    f.RemoveMoney = function(kind, amount, reason) return exports['vanta-core']:RemoveMoney(src, kind, amount, reason) end
    f.SetMoney = function(kind, amount, reason) return exports['vanta-core']:SetMoney(src, kind, amount, reason) end
    f.SetJob = function(job, grade) return exports['vanta-core']:SetJob(src, job, grade) end
    f.SetMetaData = function(key, value) return exports['vanta-core']:SetMetaData(src, key, value) end
    f.GetMetaData = function(key) return data.metadata[key] end
    return { PlayerData = data, Functions = f }
end

QBCore.Functions.GetPlayer = playerWrapper
QBCore.Functions.GetPlayers = function() return exports['vanta-core']:GetPlayers() end
QBCore.Functions.GetPlayerByCitizenId = function(cid)
    for _, src in ipairs(exports['vanta-core']:GetPlayers()) do local p = playerWrapper(src); if p and p.PlayerData.citizenid == cid then return p end end
end
QBCore.Functions.CreateCallback = function(name, fn) callbacks[name] = fn end
QBCore.Functions.AddPermission = function(src, permission) return IsPlayerAceAllowed(src, permission) end
QBCore.Functions.HasPermission = function(src, permission) return IsPlayerAceAllowed(src, permission) end
QBCore.Functions.Notify = function(src, message, kind, duration) TriggerClientEvent('vanta:ui:notify', src, { description = message, type = kind or 'primary', duration = duration }) end

RegisterNetEvent('QBCore:Server:TriggerCallback', function(name, requestId, ...)
    local src, fn = source, callbacks[name]
    if not fn then TriggerClientEvent('QBCore:Client:TriggerCallback', src, requestId, nil); return end
    fn(src, function(...) TriggerClientEvent('QBCore:Client:TriggerCallback', src, requestId, ...) end, ...)
end)
RegisterNetEvent('QBCore:Server:SetMetaData', function(key, value)
    -- Legacy client event is intentionally ignored. Mutate metadata from trusted server code.
end)

exports('GetCoreObject', function() return QBCore end)
