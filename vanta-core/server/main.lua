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
    self.PlayerData.job = { name = name, label = name, grade = grade, gradeName = 'Grade '..grade, onduty = false, type = 'none' }
    TriggerClientEvent('vanta:client:jobUpdated', self.source, self.PlayerData.job)
    TriggerEvent('vanta:server:jobUpdated', self.source, self.PlayerData.job)
    return true
end
function Player:SetMetaData(key, value) self.PlayerData.metadata[key] = value end
function Player:Save()
    local d = self.PlayerData
    MySQL.update.await('UPDATE vanta_players SET name=?, money=?, charinfo=?, job=?, metadata=?, position=? WHERE citizenid=?', {
        GetPlayerName(self.source) or d.name, json.encode(d.money), json.encode(d.charinfo), json.encode(d.job), json.encode(d.metadata), json.encode(d.position), d.citizenid
    })
end

local function makePlayer(src, row)
    local data = {
        source = src, citizenid = row.citizenid, license = row.license, name = GetPlayerName(src) or row.name,
        money = json.decode(row.money or '{}') or {}, charinfo = json.decode(row.charinfo or '{}') or {},
        job = json.decode(row.job or '{}') or {}, metadata = json.decode(row.metadata or '{}') or {},
        position = json.decode(row.position or 'null') or VantaConfig.StartingPosition,
    }
    data.money.cash = tonumber(data.money.cash) or VantaConfig.DefaultMoney.cash
    data.money.bank = tonumber(data.money.bank) or VantaConfig.DefaultMoney.bank
    if not data.job.name then data.job = copy(VantaConfig.DefaultJob) end
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
    if p then p:Save(); TriggerEvent('vanta:server:playerUnloaded', src, p); TriggerClientEvent('QBCore:Client:OnPlayerUnload', src); Vanta.Players[src] = nil end
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
exports('GetPlayerData', function(src) local p = Vanta.GetPlayer(src); return p and copy(p.PlayerData) or nil end)
exports('AddMoney', function(src, kind, amount, reason) local p = Vanta.GetPlayer(src); return p and p:AddMoney(kind, amount, reason) or false end)
exports('RemoveMoney', function(src, kind, amount, reason) local p = Vanta.GetPlayer(src); return p and p:RemoveMoney(kind, amount, reason) or false end)
exports('SetMoney', function(src, kind, amount, reason) local p = Vanta.GetPlayer(src); return p and p:SetMoney(kind, amount, reason) or false end)
exports('SetJob', function(src, name, grade) local p = Vanta.GetPlayer(src); return p and p:SetJob(name, grade) or false end)
exports('SetMetaData', function(src, key, value) local p = Vanta.GetPlayer(src); if p and type(key) == 'string' then p:SetMetaData(key, value); return true end; return false end)

RegisterCommand('vantahelp', function(src)
    if src == 0 then log('Commands: /uitheme, /uisettings, /vantahelp'); return end
    TriggerClientEvent('vanta:ui:notify', src, { title = 'Vanta', description = 'Commands: /uitheme opens theme editor; /uisettings resets your local theme.', type = 'info' })
end, false)

CreateThread(function()
    while true do Wait((VantaConfig.SaveIntervalMinutes or 5) * 60000); for _, player in pairs(Vanta.Players) do player:Save() end end
end)
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then math.randomseed(os.time()); log('Core started. Import sql/vanta.sql before joining.') end
end)
