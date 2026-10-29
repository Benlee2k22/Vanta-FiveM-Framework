Vanta = { Players = {}, Callbacks = {} }
local function copy(value) return json.decode(json.encode(value)) end
local function log(message) print(('^5[Vanta]^7 %s'):format(message)) end

local Player = {}
Player.__index = Player

local function citizenId() return ('V%s%s'):format(os.time(), math.random(10000, 99999)) end
local function licenseFor(src)
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 8) == 'license:' then return identifier end
    end
    return GetPlayerIdentifier(src, 0)
end

function Player:GetData() return self.PlayerData end
function Player:GetMoney(kind) return tonumber(self.PlayerData.money[kind]) or 0 end
function Player:AddMoney(kind, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or self.PlayerData.money[kind] == nil then return false end
    self.PlayerData.money[kind] = self:GetMoney(kind) + amount
    TriggerClientEvent('vanta:client:moneyChanged', self.source, kind, self:GetMoney(kind), 'add', reason or 'unknown')
    TriggerEvent('vanta:server:moneyChanged', self.source, kind, amount, 'add', reason or 'unknown')
    return true
end
function Player:RemoveMoney(kind, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or self.PlayerData.money[kind] == nil or self:GetMoney(kind) < amount then return false end
    self.PlayerData.money[kind] = self:GetMoney(kind) - amount
    TriggerClientEvent('vanta:client:moneyChanged', self.source, kind, self:GetMoney(kind), 'remove', reason or 'unknown')
    TriggerEvent('vanta:server:moneyChanged', self.source, kind, amount, 'remove', reason or 'unknown')
    return true
end
function Player:SetMoney(kind, amount, reason)
    amount = math.floor(tonumber(amount) or -1)
    if amount < 0 or self.PlayerData.money[kind] == nil then return false end
    local delta = amount - self:GetMoney(kind)
    self.PlayerData.money[kind] = amount
    TriggerClientEvent('vanta:client:moneyChanged', self.source, kind, amount, 'set', reason or 'unknown')
    TriggerEvent('vanta:server:moneyChanged', self.source, kind, delta, 'set', reason or 'unknown')
    return true
end
function Player:SetJob(name, grade)
    name, grade = tostring(name), tonumber(grade) or 0
    local definition = VantaConfig.Jobs[name]
    if not definition then return false end
    local rank = definition.grades[grade] or definition.grades[tostring(grade)]
    if not rank then return false end
    self.PlayerData.job = {
        name = name, label = definition.label, type = definition.type or 'none',
        grade = { name = rank.name, level = grade }, onduty = definition.defaultDuty == true,
        isboss = rank.isboss == true,
    }
    TriggerClientEvent('vanta:client:jobUpdated', self.source, self.PlayerData.job)
    TriggerClientEvent('QBCore:Client:OnJobUpdate', self.source, self.PlayerData.job)
    TriggerEvent('vanta:server:jobUpdated', self.source, self.PlayerData.job)
    return true
end
function Player:SetDuty(value)
    self.PlayerData.job.onduty = value == true
    TriggerClientEvent('vanta:client:jobUpdated', self.source, self.PlayerData.job)
    TriggerClientEvent('QBCore:Client:SetDuty', self.source, self.PlayerData.job.onduty)
    TriggerEvent('vanta:server:dutyUpdated', self.source, self.PlayerData.job.onduty)
    return self.PlayerData.job.onduty
end
function Player:SetMetaData(key, value) self.PlayerData.metadata[key] = value end
function Player:GetItemByName(name)
    for _, item in ipairs(self.PlayerData.inventory) do if item.name == name then return copy(item) end end
    return nil
end
function Player:AddItem(name, amount, slot, info)
    local definition = VantaConfig.Items[name]
    amount = math.floor(tonumber(amount) or 0)
    if not definition or amount < 1 then return false end
    local inventory, currentWeight = self.PlayerData.inventory, 0
    for _, item in ipairs(inventory) do currentWeight = currentWeight + (tonumber(item.weight) or 0) * (tonumber(item.amount) or 0) end
    if currentWeight + (definition.weight or 0) * amount > VantaConfig.Inventory.maxWeight then return false end
    if not definition.unique then
        for _, item in ipairs(inventory) do
            if item.name == name and (not slot or tonumber(slot) == item.slot) then item.amount = item.amount + amount; TriggerClientEvent('vanta:client:inventoryUpdated', self.source, copy(inventory)); return true end
        end
    end
    local used = {}; for _, item in ipairs(inventory) do used[item.slot] = true end
    slot = tonumber(slot)
    if slot and slot < 1 then slot = nil end
    if not slot or used[slot] then slot = 1; while used[slot] and slot <= VantaConfig.Inventory.maxSlots do slot = slot + 1 end end
    if slot > VantaConfig.Inventory.maxSlots then return false end
    local item = copy(definition); item.amount = amount; item.slot = slot; item.info = info or {}
    inventory[#inventory + 1] = item
    TriggerClientEvent('vanta:client:inventoryUpdated', self.source, copy(inventory))
    return true
end
function Player:RemoveItem(name, amount, slot)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 then return false end
    local inventory, available = self.PlayerData.inventory, 0
    for _, item in ipairs(inventory) do if item.name == name and (not slot or item.slot == tonumber(slot)) then available = available + item.amount end end
    if available < amount then return false end
    for i = #inventory, 1, -1 do
        local item = inventory[i]
        if item.name == name and (not slot or item.slot == tonumber(slot)) then
            local take = math.min(item.amount, amount); item.amount = item.amount - take; amount = amount - take
            if item.amount <= 0 then table.remove(inventory, i) end
            if amount == 0 then break end
        end
    end
    TriggerClientEvent('vanta:client:inventoryUpdated', self.source, copy(inventory))
    return true
end
function Player:Save()
    local d = self.PlayerData
    MySQL.update.await('UPDATE vanta_players SET name=?, money=?, charinfo=?, job=?, metadata=?, position=? WHERE citizenid=?', {
        GetPlayerName(self.source) or d.name, json.encode(d.money), json.encode(d.charinfo), json.encode(d.job), json.encode(d.metadata), json.encode(d.position), d.citizenid
    })
    MySQL.insert.await('INSERT INTO vanta_inventories (citizenid, items) VALUES (?, ?) ON DUPLICATE KEY UPDATE items = VALUES(items)', { d.citizenid, json.encode(d.inventory) })
end

local function makePlayer(src, row)
    local data = {
        source = src, citizenid = row.citizenid, license = row.license, name = GetPlayerName(src) or row.name,
        money = json.decode(row.money or '{}') or {}, charinfo = json.decode(row.charinfo or '{}') or {},
        job = json.decode(row.job or '{}') or {}, metadata = json.decode(row.metadata or '{}') or {},
        position = json.decode(row.position or 'null') or VantaConfig.StartingPosition,
        inventory = json.decode(row.inventory or '[]') or {},
    }
    data.money.cash = tonumber(data.money.cash) or VantaConfig.DefaultMoney.cash
    data.money.bank = tonumber(data.money.bank) or VantaConfig.DefaultMoney.bank
    data.items = data.inventory
    local storedJob = data.job
    local jobName = storedJob.name or 'unemployed'
    local jobDefinition = VantaConfig.Jobs[jobName]
    local rawGrade = type(storedJob.grade) == 'table' and storedJob.grade.level or storedJob.grade
    local jobGrade = tonumber(rawGrade) or 0
    local gradeDefinition = jobDefinition and (jobDefinition.grades[jobGrade] or jobDefinition.grades[tostring(jobGrade)])
    if jobDefinition and gradeDefinition then
        data.job = { name = jobName, label = jobDefinition.label, type = jobDefinition.type or 'none', grade = { name = gradeDefinition.name, level = jobGrade }, onduty = storedJob.onduty == true, isboss = gradeDefinition.isboss == true }
    else
        data.job = copy(VantaConfig.DefaultJob)
    end
    for key, value in pairs({ hunger = 100, thirst = 100, stress = 0, isdead = false, inlaststand = false }) do
        if data.metadata[key] == nil then data.metadata[key] = value end
    end
    local p = setmetatable({ source = src, PlayerData = data }, Player)
    Vanta.Players[src] = p
    TriggerClientEvent('vanta:client:loaded', src, copy(data))
    TriggerEvent('vanta:server:playerLoaded', src, p)
    TriggerClientEvent('QBCore:Client:OnPlayerLoaded', src)
    log(('%s loaded (%s)'):format(data.name, data.citizenid))
end

local function loadPlayer(src)
    local license = licenseFor(src)
    if not license then DropPlayer(src, 'Could not identify your license.'); return end
    local row = MySQL.single.await('SELECT * FROM vanta_players WHERE license = ?', { license })
    if not row then
        local cid = citizenId()
        local info = { firstname = GetPlayerName(src) or 'New', lastname = 'Player', birthdate = '2000-01-01', gender = 0, nationality = 'Unknown' }
        local money, job, metadata = copy(VantaConfig.DefaultMoney), copy(VantaConfig.DefaultJob), { hunger = 100, thirst = 100, stress = 0 }
        MySQL.insert.await('INSERT INTO vanta_players (citizenid, license, name, money, charinfo, job, metadata, position) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            cid, license, GetPlayerName(src) or 'Unknown', json.encode(money), json.encode(info), json.encode(job), json.encode(metadata), json.encode(VantaConfig.StartingPosition)
        })
        row = { citizenid = cid, license = license, name = GetPlayerName(src) or 'Unknown', money = json.encode(money), charinfo = json.encode(info), job = json.encode(job), metadata = json.encode(metadata), position = json.encode(VantaConfig.StartingPosition) }
    end
    local inventory = MySQL.single.await('SELECT items FROM vanta_inventories WHERE citizenid = ?', { row.citizenid })
    row.inventory = inventory and inventory.items or '[]'
    makePlayer(src, row)
end

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function()
        local tries = 0
        while not GetPlayerName(src) and tries < 50 do Wait(100); tries = tries + 1 end
        if GetPlayerName(src) then loadPlayer(src) end
    end)
end)
AddEventHandler('playerDropped', function()
    local src, p = source, Vanta.Players[source]
    if p then
        local ped = GetPlayerPed(src)
        if ped ~= 0 then local pos = GetEntityCoords(ped); p.PlayerData.position = { x = pos.x, y = pos.y, z = pos.z, w = GetEntityHeading(ped) } end
        p:Save(); TriggerEvent('vanta:server:playerUnloaded', src, p); TriggerClientEvent('QBCore:Client:OnPlayerUnload', src); Vanta.Players[src] = nil
    end
end)
RegisterNetEvent('vanta:server:savePosition', function()
    local src, player = source, Vanta.GetPlayer(source)
    if not player then return end
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local pos = GetEntityCoords(ped)
    if math.abs(pos.x) > 6000 or math.abs(pos.y) > 6000 or pos.z < -200 or pos.z > 2000 then return end
    player.PlayerData.position = { x = pos.x, y = pos.y, z = pos.z, w = GetEntityHeading(ped) }
end)

function Vanta.GetPlayer(src) return Vanta.Players[tonumber(src)] end
function Vanta.GetPlayers() local out = {}; for src in pairs(Vanta.Players) do out[#out + 1] = src end; return out end
function Vanta.RegisterCallback(name, fn) Vanta.Callbacks[name] = fn end
RegisterNetEvent('vanta:server:triggerCallback', function(name, requestId, ...)
    local src, callback = source, Vanta.Callbacks[name]
    if not callback then TriggerClientEvent('vanta:client:callbackResult', src, requestId, nil); return end
    callback(src, function(...) TriggerClientEvent('vanta:client:callbackResult', src, requestId, ...) end, ...)
end)

exports('GetPlayer', Vanta.GetPlayer)
exports('GetPlayers', Vanta.GetPlayers)
exports('RegisterCallback', Vanta.RegisterCallback)
exports('GetCoreObject', function() return Vanta end)
exports('GetShared', function() return { Jobs = VantaConfig.Jobs, Items = VantaConfig.Items, Inventory = VantaConfig.Inventory, Gangs = {}, Vehicles = {} } end)
exports('GetPlayerData', function(src) local p = Vanta.GetPlayer(src); return p and copy(p.PlayerData) or nil end)
exports('AddMoney', function(src, kind, amount, reason) local p = Vanta.GetPlayer(src); return p and p:AddMoney(kind, amount, reason) or false end)
exports('RemoveMoney', function(src, kind, amount, reason) local p = Vanta.GetPlayer(src); return p and p:RemoveMoney(kind, amount, reason) or false end)
exports('SetMoney', function(src, kind, amount, reason) local p = Vanta.GetPlayer(src); return p and p:SetMoney(kind, amount, reason) or false end)
exports('SetJob', function(src, name, grade) local p = Vanta.GetPlayer(src); return p and p:SetJob(name, grade) or false end)
exports('SetDuty', function(src, value) local p = Vanta.GetPlayer(src); return p and p:SetDuty(value) or false end)
exports('SetMetaData', function(src, key, value) local p = Vanta.GetPlayer(src); if p and type(key) == 'string' then p:SetMetaData(key, value); return true end; return false end)
exports('SavePlayer', function(src) local p = Vanta.GetPlayer(src); if p then p:Save(); return true end; return false end)
exports('AddItem', function(src, name, amount, slot, info) local p = Vanta.GetPlayer(src); return p and p:AddItem(name, amount, slot, info) or false end)
exports('RemoveItem', function(src, name, amount, slot) local p = Vanta.GetPlayer(src); return p and p:RemoveItem(name, amount, slot) or false end)
exports('GetItemByName', function(src, name) local p = Vanta.GetPlayer(src); return p and p:GetItemByName(name) or nil end)

RegisterCommand('vantahelp', function(src)
    if src == 0 then log('Commands: /uitheme, /uisettings, /vantaradial, /inventory, /setjob, /giveitem, /vantahelp'); return end
    TriggerClientEvent('vanta:ui:notify', src, { title = 'Vanta', description = 'Commands: /uitheme, /vantaradial, /inventory, /setjob and /vantahelp.', type = 'info' })
end, false)

RegisterCommand('giveitem', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'vanta.admin') then return end
    local target, itemName, amount = tonumber(args[1]), args[2], tonumber(args[3]) or 1
    local player = target and Vanta.GetPlayer(target)
    if not player or not itemName or not player:AddItem(itemName, amount) then
        if src > 0 then TriggerClientEvent('vanta:ui:notify', src, { title = 'Vanta', description = 'Usage: /giveitem [player id] [item] [amount]', type = 'error' }) end
        return
    end
    player:Save()
    if src > 0 then TriggerClientEvent('vanta:ui:notify', src, { title = 'Vanta', description = ('Gave %sx %s.'):format(amount, itemName), type = 'success' }) end
end, false)

RegisterCommand('setjob', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'vanta.admin') then return end
    local target, job, grade = tonumber(args[1]), args[2], tonumber(args[3]) or 0
    local player = target and Vanta.GetPlayer(target)
    if not player or not job or not player:SetJob(job, grade) then
        if src > 0 then TriggerClientEvent('vanta:ui:notify', src, { title = 'Vanta', description = 'Usage: /setjob [player id] [job] [grade]', type = 'error' }) end
        return
    end
    player:Save()
    if src > 0 then TriggerClientEvent('vanta:ui:notify', src, { title = 'Vanta', description = ('Assigned %s to %s.'):format(job, player.PlayerData.name), type = 'success' }) end
end, false)

CreateThread(function()
    while true do
        Wait((VantaConfig.SaveIntervalMinutes or 5) * 60000)
        for _, player in pairs(Vanta.Players) do player:Save() end
    end
end)
CreateThread(function()
    local paycheckInterval = (VantaConfig.PaycheckIntervalMinutes or 15) * 60000
    while true do
        Wait(paycheckInterval)
        for src, player in pairs(Vanta.Players) do
            local job = player.PlayerData.job
            local definition = VantaConfig.Jobs[job.name]
            local grade = definition and (definition.grades[job.grade.level] or definition.grades[tostring(job.grade.level)])
            if job.onduty and grade and (tonumber(grade.payment) or 0) > 0 then
                player:AddMoney('bank', grade.payment, 'paycheck')
                TriggerClientEvent('vanta:ui:notify', src, { title = 'Payroll', description = ('You received $%s for your shift.'):format(grade.payment), type = 'success' })
                player:Save()
            end
        end
    end
end)
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then math.randomseed(os.time()); log('Core started. Import sql/vanta.sql before joining.') end
end)
