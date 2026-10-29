local callbacks = {}
local QBCore = { Config = {}, Shared = exports['vanta-core']:GetShared(), Functions = {} }

local function playerWrapper(src)
    local data = exports['vanta-core']:GetPlayerData(src)
    if not data then return nil end
    local f = {}
    f.GetName = function() return data.charinfo.firstname .. ' ' .. data.charinfo.lastname end
    f.GetMoney = function(kind) return tonumber(data.money[kind]) or 0 end
    f.AddMoney = function(kind, amount, reason) return exports['vanta-core']:AddMoney(src, kind, amount, reason) end
    f.RemoveMoney = function(kind, amount, reason) return exports['vanta-core']:RemoveMoney(src, kind, amount, reason) end
    f.SetMoney = function(kind, amount, reason) return exports['vanta-core']:SetMoney(src, kind, amount, reason) end
    f.AddItem = function(name, amount, slot, info) return exports['vanta-core']:AddItem(src, name, amount, slot, info) end
    f.RemoveItem = function(name, amount, slot) return exports['vanta-core']:RemoveItem(src, name, amount, slot) end
    f.GetItemByName = function(name) return exports['vanta-core']:GetItemByName(src, name) end
    f.GetItemsByName = function(name) local found = {}; for _, item in ipairs(data.inventory or {}) do if item.name == name then found[#found + 1] = item end end; return found end
    f.HasItem = function(name, amount) local item = f.GetItemByName(name); return item ~= nil and item.amount >= (tonumber(amount) or 1) end
    f.SetJob = function(job, grade) return exports['vanta-core']:SetJob(src, job, grade) end
    f.SetJobDuty = function(onDuty) return exports['vanta-core']:SetDuty(src, onDuty) end
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
QBCore.Functions.CreateUseableItem = function(name, fn) QBCore.UseableItems = QBCore.UseableItems or {}; QBCore.UseableItems[name] = fn end
QBCore.Functions.GetItemByName = function(src, name) return exports['vanta-core']:GetItemByName(src, name) end
QBCore.Functions.AddPermission = function(src, permission)
    if type(permission) ~= 'string' or not permission:match('^[%w_.%-]+$') then return false end
    ExecuteCommand(('add_principal player.%s group.%s'):format(tonumber(src) or 0, permission:gsub('^group%.', '')))
    return true
end
QBCore.Functions.HasPermission = function(src, permission)
    if type(permission) == 'table' then for _, group in pairs(permission) do if QBCore.Functions.HasPermission(src, group) then return true end end; return false end
    if type(permission) ~= 'string' then return false end
    local group = permission:match('^group%.') and permission or 'group.'..permission
    return IsPlayerAceAllowed(src, group) or IsPlayerAceAllowed(src, permission)
end
QBCore.Functions.Notify = function(src, message, kind, duration) TriggerClientEvent('vanta:ui:notify', src, { description = message, type = kind or 'primary', duration = duration }) end

RegisterNetEvent('QBCore:Server:TriggerCallback', function(name, requestId, ...)
    local src, fn = source, callbacks[name]
    if not fn then TriggerClientEvent('QBCore:Client:TriggerCallback', src, requestId, nil); return end
    fn(src, function(...) TriggerClientEvent('QBCore:Client:TriggerCallback', src, requestId, ...) end, ...)
end)
RegisterNetEvent('QBCore:Server:UseItem', function(itemName)
    local src, name = source, type(itemName) == 'table' and itemName.name or itemName
    if type(name) ~= 'string' then return end
    local item = exports['vanta-core']:GetItemByName(src, name)
    local callback = QBCore.UseableItems and QBCore.UseableItems[name]
    if item and item.useable and callback then callback(src, item) end
end)
RegisterNetEvent('QBCore:Server:SetMetaData', function(key, value)
    -- Legacy client event is intentionally ignored. Mutate metadata from trusted server code.
end)

exports('GetCoreObject', function() return QBCore end)

QBCore.Functions.CreateUseableItem('water_bottle', function(src, item)
    local player = QBCore.Functions.GetPlayer(src)
    if not player or not player.Functions.RemoveItem(item.name, 1, item.slot) then return end
    local data = exports['vanta-core']:GetPlayerData(src)
    exports['vanta-core']:SetMetaData(src, 'thirst', math.min(100, (tonumber(data.metadata.thirst) or 0) + 35))
    exports['vanta-core']:SavePlayer(src)
    TriggerClientEvent('vanta:ui:notify', src, { title = 'Inventory', description = 'You drank some water.', type = 'success' })
end)
QBCore.Functions.CreateUseableItem('sandwich', function(src, item)
    local player = QBCore.Functions.GetPlayer(src)
    if not player or not player.Functions.RemoveItem(item.name, 1, item.slot) then return end
    local data = exports['vanta-core']:GetPlayerData(src)
    exports['vanta-core']:SetMetaData(src, 'hunger', math.min(100, (tonumber(data.metadata.hunger) or 0) + 35))
    exports['vanta-core']:SavePlayer(src)
    TriggerClientEvent('vanta:ui:notify', src, { title = 'Inventory', description = 'You ate a sandwich.', type = 'success' })
end)
QBCore.Functions.CreateUseableItem('bandage', function(src, item)
    local player = QBCore.Functions.GetPlayer(src)
    if not player or not player.Functions.RemoveItem(item.name, 1, item.slot) then return end
    TriggerClientEvent('vanta:client:applyBandage', src)
    exports['vanta-core']:SavePlayer(src)
    TriggerClientEvent('vanta:ui:notify', src, { title = 'Inventory', description = 'You used a bandage.', type = 'success' })
end)
