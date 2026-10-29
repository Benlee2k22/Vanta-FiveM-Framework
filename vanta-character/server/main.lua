local pendingSpawn = {}
local function licenseFor(src)
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 8) == 'license:' then return identifier end
    end
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 9) == 'license2:' then return identifier end
    end
end

local function ensureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS vanta_characters (
          citizenid varchar(50) NOT NULL,
          license varchar(80) NOT NULL,
          slot int NOT NULL,
          firstname varchar(32) NOT NULL,
          lastname varchar(32) NOT NULL,
          birthdate varchar(10) NOT NULL,
          gender tinyint NOT NULL DEFAULT 0,
          nationality varchar(32) NOT NULL DEFAULT 'American',
          appearance longtext DEFAULT NULL,
          created_at timestamp NOT NULL DEFAULT current_timestamp(),
          PRIMARY KEY (citizenid),
          UNIQUE KEY uq_vanta_character_slot (license, slot),
          KEY idx_vanta_character_license (license)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

local function decode(value, fallback)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' then return fallback end
    local ok, result = pcall(json.decode, value)
    return ok and type(result) == 'table' and result or fallback
end

local function migrateLegacy(license)
    local found = MySQL.scalar.await('SELECT citizenid FROM vanta_characters WHERE license = ? LIMIT 1', { license })
    if found then return end
    local row = MySQL.single.await('SELECT * FROM vanta_players WHERE license = ? LIMIT 1', { license })
    if not row then return end
    local info = decode(row.charinfo, {})
    local slot = 1
    MySQL.insert.await('INSERT IGNORE INTO vanta_characters (citizenid, license, slot, firstname, lastname, birthdate, gender, nationality) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        row.citizenid, license, slot, info.firstname or 'New', info.lastname or 'Player',
        info.birthdate or '2000-01-01', tonumber(info.gender) or 0, info.nationality or 'Unknown'
    })
    -- Keep the legacy unique license index usable while assigning each character its own row.
    MySQL.update.await('UPDATE vanta_players SET license = ? WHERE citizenid = ?', { license .. '#' .. row.citizenid, row.citizenid })
end

local function getCharacters(src)
    local license = licenseFor(src)
    if not license then return {} end
    migrateLegacy(license)
    local rows = MySQL.query.await([[
        SELECT c.citizenid, c.slot, c.firstname, c.lastname, c.birthdate, c.gender,
               c.nationality, c.appearance, p.money, p.job, p.position
        FROM vanta_characters c
        LEFT JOIN vanta_players p ON p.citizenid = c.citizenid
        WHERE c.license = ? ORDER BY c.slot ASC
    ]], { license }) or {}
    local characters = {}
    for _, row in ipairs(rows) do
        local money, job, position = decode(row.money, {}), decode(row.job, {}), decode(row.position, {})
        characters[#characters + 1] = {
            citizenid = row.citizenid, slot = tonumber(row.slot),
            firstname = row.firstname, lastname = row.lastname,
            birthdate = row.birthdate, gender = tonumber(row.gender) or 0,
            nationality = row.nationality, job = job.label or job.name or 'Unemployed',
            bank = tonumber(money.bank) or 0, position = position,
            appearance = decode(row.appearance, nil),
        }
    end
    return characters
end

local function pushCharacters(src)
    TriggerClientEvent('vanta:character:list', src, getCharacters(src), VantaCharacterConfig.MaxSlots)
end

local function validText(value, min, max)
    if type(value) ~= 'string' then return nil end
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    if #value < min or #value > max or not value:match("^[%a%s%-']+$") then return nil end
    return value
end

RegisterNetEvent('vanta:character:requestList', function()
    local src = source
    pushCharacters(src)
end)

RegisterNetEvent('vanta:character:create', function(form)
    local src, license = source, licenseFor(source)
    if not license or type(form) ~= 'table' or Vanta.GetPlayer(src) then return end
    migrateLegacy(license)
    local existing = MySQL.scalar.await('SELECT COUNT(*) FROM vanta_characters WHERE license = ?', { license }) or 0
    existing = tonumber(existing) or 0
    if existing >= VantaCharacterConfig.MaxSlots then
        TriggerClientEvent('vanta:ui:notify', src, { title = 'Characters', description = 'You have used all available character slots.', type = 'error' })
        return
    end
    local firstname, lastname = validText(form.firstname, 2, 24), validText(form.lastname, 2, 24)
    local birthdate = type(form.birthdate) == 'string' and form.birthdate or ''
    local year, month, day = birthdate:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    if not firstname or not lastname or not year or tonumber(month) < 1 or tonumber(month) > 12 or tonumber(day) < 1 or tonumber(day) > 31 then
        TriggerClientEvent('vanta:ui:notify', src, { title = 'Character details', description = 'Enter a valid first name, last name and date of birth.', type = 'error' })
        return
    end
    local gender = tonumber(form.gender) == 1 and 1 or 0
    local nationality = validText(form.nationality or 'American', 2, 24) or 'American'
    local slot = 1
    while MySQL.scalar.await('SELECT citizenid FROM vanta_characters WHERE license = ? AND slot = ?', { license, slot }) do slot = slot + 1 end
    local cid = ('V%s%s'):format(os.time(), math.random(10000, 99999))
    local money = VantaCharacterConfig.DefaultMoney
    local job = { name = 'unemployed', label = 'Unemployed', grade = { name = 'Trainee', level = 0 }, onduty = false, type = 'none', isboss = false }
    local metadata = { hunger = 100, thirst = 100, stress = 0, isdead = false, inlaststand = false }
    local info = { firstname = firstname, lastname = lastname, birthdate = birthdate, gender = gender, nationality = nationality }
    local dbLicense = license .. '#' .. cid
    local position = VantaCharacterConfig.SpawnPoints[VantaCharacterConfig.DefaultSpawn]
    MySQL.insert.await('INSERT INTO vanta_players (citizenid, license, name, money, charinfo, job, metadata, position) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        cid, dbLicense, firstname .. ' ' .. lastname, json.encode(money), json.encode(info), json.encode(job), json.encode(metadata), json.encode(position)
    })
    MySQL.insert.await('INSERT INTO vanta_characters (citizenid, license, slot, firstname, lastname, birthdate, gender, nationality, appearance) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        cid, license, slot, firstname, lastname, birthdate, gender, nationality, json.encode({ gender = gender })
    })
    pushCharacters(src)
end)

RegisterNetEvent('vanta:character:delete', function(citizenid)
    local src, license = source, licenseFor(source)
    if not license or type(citizenid) ~= 'string' or Vanta.GetPlayer(src) then return end
    local owned = MySQL.scalar.await('SELECT citizenid FROM vanta_characters WHERE citizenid = ? AND license = ?', { citizenid, license })
    if not owned then return end
    MySQL.query.await('DELETE FROM vanta_bank_transactions WHERE citizenid = ?', { citizenid })
    MySQL.query.await('DELETE FROM vanta_inventories WHERE citizenid = ?', { citizenid })
    pcall(function() MySQL.query.await('DELETE FROM vanta_outfits WHERE citizenid = ?', { citizenid }) end)
    MySQL.query.await('DELETE FROM vanta_players WHERE citizenid = ?', { citizenid })
    MySQL.query.await('DELETE FROM vanta_characters WHERE citizenid = ? AND license = ?', { citizenid, license })
    pushCharacters(src)
end)

RegisterNetEvent('vanta:character:requestSpawns', function(citizenid)
    local src, license = source, licenseFor(source)
    if not license or type(citizenid) ~= 'string' or Vanta.GetPlayer(src) then return end
    migrateLegacy(license)
    local row = MySQL.single.await('SELECT c.citizenid, c.firstname, c.lastname, c.appearance, p.position FROM vanta_characters c JOIN vanta_players p ON p.citizenid = c.citizenid WHERE c.citizenid = ? AND c.license = ?', { citizenid, license })
    if not row then return end
    pendingSpawn[src] = citizenid
    TriggerClientEvent('vanta:character:spawns', src, {
        citizenid = citizenid, name = row.firstname .. ' ' .. row.lastname,
        last = decode(row.position, nil), appearance = decode(row.appearance, nil),
        points = VantaCharacterConfig.SpawnPoints,
    })
end)

RegisterNetEvent('vanta:character:chooseSpawn', function(citizenid, spawnId)
    local src, license = source, licenseFor(source)
    if not license or pendingSpawn[src] ~= citizenid or type(citizenid) ~= 'string' or type(spawnId) ~= 'string' then return end
    local row = MySQL.single.await('SELECT c.appearance, p.position FROM vanta_characters c JOIN vanta_players p ON p.citizenid = c.citizenid WHERE c.citizenid = ? AND c.license = ?', { citizenid, license })
    if not row then pendingSpawn[src] = nil; return end
    local spawn = spawnId == 'last' and decode(row.position, nil) or VantaCharacterConfig.SpawnPoints[spawnId]
    if type(spawn) ~= 'table' or not tonumber(spawn.x) or not tonumber(spawn.y) or not tonumber(spawn.z) then return end
    local ok = pcall(function() return exports['vanta-core']:LoadCharacter(src, citizenid, license) end)
    if not ok or not Vanta.GetPlayer(src) then return end
    pendingSpawn[src] = nil
    TriggerClientEvent('vanta:character:spawnAt', src, {
        x = tonumber(spawn.x), y = tonumber(spawn.y), z = tonumber(spawn.z), w = tonumber(spawn.w) or 0.0,
        appearance = decode(row.appearance, nil),
    })
end)

AddEventHandler('playerDropped', function() pendingSpawn[source] = nil end)
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ensureTables()
    Wait(500)
    for _, raw in ipairs(GetPlayers()) do
        local src = tonumber(raw)
        TriggerClientEvent('vanta:character:open', src)
    end
    print('^5[Vanta Character]^7 Character selector ready.')
end)
