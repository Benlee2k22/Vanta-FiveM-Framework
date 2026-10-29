local busy = {}
local function notify(src, description, kind) TriggerClientEvent('vanta:ui:notify', src, { title = 'Vanta Bank', description = description, type = kind or 'info' }) end
local function getPlayer(src) return exports['vanta-core']:GetPlayerData(src) end
local function getLocation(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return nil end
    local pos = GetEntityCoords(ped)
    for _, location in ipairs(VantaBankConfig.Locations) do
        local c = location.coords
        if #(pos - vector3(c.x, c.y, c.z)) <= location.radius then return location end
    end
end
local function refresh(src, message, ok)
    local data = getPlayer(src)
    TriggerClientEvent('vanta-banking:client:result', src, { ok = ok, message = message, money = data and data.money or {} })
end

RegisterNetEvent('vanta-banking:server:history', function()
    local src, data = source, getPlayer(source)
    if not data then return end
    local rows = MySQL.query.await('SELECT action, amount, description, reference, created_at FROM vanta_bank_transactions WHERE citizenid = ? ORDER BY id DESC LIMIT 15', { data.citizenid }) or {}
    TriggerClientEvent('vanta-banking:client:history', src, rows)
end)
exports('RecordTransaction', function(src, action, amount, description, reference)
    local data = getPlayer(src)
    if not data then return false end
    local ref = reference or ('V%X%04X'):format(os.time(), math.random(0, 65535))
    return MySQL.insert.await('INSERT INTO vanta_bank_transactions (citizenid, action, amount, description, reference) VALUES (?, ?, ?, ?, ?)', {
        data.citizenid, tostring(action), math.floor(tonumber(amount) or 0), tostring(description or ''), ref
    }) ~= nil
end)

RegisterNetEvent('vanta-banking:server:action', function(payload)
    local src = source
    if busy[src] then return end
    busy[src] = true
    local function finish(message, ok) busy[src] = nil; refresh(src, message, ok) end
    local location, data = getLocation(src), getPlayer(src)
    if not location or not data then finish('Move closer to a bank or ATM.', false); return end
    if payload == nil or type(payload) ~= 'table' then finish('Invalid request.', false); return end
    local action = tostring(payload.action or '')
    local amount = math.floor(tonumber(payload.amount) or 0)
    if amount < 1 or amount > VantaBankConfig.MaxTransaction then finish(('Enter an amount from $1 to $%s.'):format(VantaBankConfig.MaxTransaction), false); return end
    if action == 'transfer' and location.type ~= 'bank' then finish('Transfers are only available inside a bank.', false); return end

    local oldCash, oldBank = tonumber(data.money.cash) or 0, tonumber(data.money.bank) or 0
    local newCash, newBank, description = oldCash, oldBank, nil
    local recipient, recipientData
    if action == 'deposit' then
        if oldCash < amount then finish('You do not have enough cash.', false); return end
        newCash, newBank, description = oldCash - amount, oldBank + amount, location.label
    elseif action == 'withdraw' then
        if oldBank < amount then finish('Your account does not have enough money.', false); return end
        newCash, newBank, description = oldCash + amount, oldBank - amount, location.label
    elseif action == 'transfer' then
        local targetCid = tostring(payload.citizenid or ''):upper()
        if targetCid == '' or targetCid == data.citizenid then finish('Enter another player’s citizen ID.', false); return end
        if oldBank < amount then finish('Your account does not have enough money.', false); return end
        for _, targetSource in ipairs(exports['vanta-core']:GetPlayers()) do
            local candidate = getPlayer(targetSource)
            if candidate and candidate.citizenid == targetCid then recipient, recipientData = targetSource, candidate; break end
        end
        if not recipient then finish('That player must be online to receive a transfer.', false); return end
        if busy[recipient] then finish('That account is processing another transaction. Try again.', false); return end
        busy[recipient] = true
        if (tonumber(recipientData.money.bank) or 0) + amount > 999999999 then busy[recipient] = nil; finish('The recipient account cannot accept that amount.', false); return end
        newBank, description = oldBank - amount, ('Transfer to %s'):format(recipientData.charinfo.firstname or 'player')
    else
        finish('Unknown banking action.', false); return
    end

    local changed = exports['vanta-core']:SetMoney(src, 'cash', newCash, 'banking-'..action)
        and exports['vanta-core']:SetMoney(src, 'bank', newBank, 'banking-'..action)
    if changed and recipient then
        changed = exports['vanta-core']:SetMoney(recipient, 'bank', (tonumber(recipientData.money.bank) or 0) + amount, 'bank-transfer')
    end
    if not changed then
        exports['vanta-core']:SetMoney(src, 'cash', oldCash, 'banking-rollback')
        exports['vanta-core']:SetMoney(src, 'bank', oldBank, 'banking-rollback')
        if recipient then busy[recipient] = nil end
        finish('The transaction could not be completed.', false); return
    end

    local reference = ('V%X%04X'):format(os.time(), math.random(0, 65535))
    local ledger = {
        { 'INSERT INTO vanta_bank_transactions (citizenid, action, amount, description, reference) VALUES (?, ?, ?, ?, ?)', { data.citizenid, action == 'transfer' and 'transfer_out' or action, amount, description, reference } },
    }
    if recipient then ledger[#ledger + 1] = { 'INSERT INTO vanta_bank_transactions (citizenid, action, amount, description, reference) VALUES (?, ?, ?, ?, ?)', { recipientData.citizenid, 'transfer_in', amount, ('Transfer from %s'):format(data.charinfo.firstname or 'player'), reference } } end
    local ok, logged = pcall(function() return MySQL.transaction.await(ledger) end)
    exports['vanta-core']:SavePlayer(src)
    if recipient then exports['vanta-core']:SavePlayer(recipient); busy[recipient] = nil end
    if not ok or not logged then print(('^1[Vanta Bank]^7 Ledger write failed for %s'):format(reference)) end
    finish(action == 'transfer' and ('Transfer of $%s sent.'):format(amount) or (('%s of $%s completed.'):format(action:gsub('^%l', string.upper), amount)), true)
    if recipient then notify(recipient, ('You received $%s.'):format(amount), 'success') end
end)

AddEventHandler('playerDropped', function() busy[source] = nil end)
