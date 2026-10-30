local QBCore = exports['qb-core']:GetCoreObject({ 'Functions' })
local busy = {}

local function notify(src, description, kind)
    TriggerClientEvent('vanta:ui:notify', src, { title = 'Vanta Bank', description = description, type = kind or 'info' })
end

local function getPlayer(src)
    return QBCore.Functions.GetPlayer(tonumber(src))
end

local function getMoney(Player)
    if not Player then return { cash = 0, bank = 0 } end
    return {
        cash = tonumber(Player.Functions.GetMoney('cash')) or 0,
        bank = tonumber(Player.Functions.GetMoney('bank')) or 0,
    }
end

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
    local Player = getPlayer(src)
    TriggerClientEvent('vanta-banking:client:result', src, {
        ok = ok, message = message, money = getMoney(Player)
    })
end

RegisterNetEvent('vanta-banking:server:history', function()
    local src, Player = source, getPlayer(source)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local rows = MySQL.query.await(
        'SELECT action, amount, description, reference, created_at FROM vanta_bank_transactions WHERE citizenid = ? ORDER BY id DESC LIMIT 15',
        { citizenid }
    ) or {}
    TriggerClientEvent('vanta-banking:client:history', src, rows)
end)

exports('RecordTransaction', function(src, action, amount, description, reference)
    local Player = getPlayer(src)
    if not Player then return false end
    local ref = reference or ('V%X%04X'):format(os.time(), math.random(0, 65535))
    return MySQL.insert.await(
        'INSERT INTO vanta_bank_transactions (citizenid, action, amount, description, reference) VALUES (?, ?, ?, ?, ?)',
        { Player.PlayerData.citizenid, tostring(action), math.floor(tonumber(amount) or 0), tostring(description or ''), ref }
    ) ~= nil
end)

RegisterNetEvent('vanta-banking:server:action', function(payload)
    local src = source
    if busy[src] then return end
    busy[src] = true

    local function finish(message, ok)
        busy[src] = nil
        refresh(src, message, ok)
    end

    local location, Player = getLocation(src), getPlayer(src)
    if not location or not Player then finish('Move closer to a bank or ATM.', false); return end
    if type(payload) ~= 'table' then finish('Invalid request.', false); return end

    local action = tostring(payload.action or '')
    local amount = math.floor(tonumber(payload.amount) or 0)
    if amount < 1 or amount > VantaBankConfig.MaxTransaction then
        finish(('Enter an amount from $1 to $%s.'):format(VantaBankConfig.MaxTransaction), false)
        return
    end
    if action == 'transfer' and location.type ~= 'bank' then
        finish('Transfers are only available inside a bank.', false)
        return
    end

    local recipient
    if action == 'transfer' then
        local targetCid = tostring(payload.citizenid or ''):upper()
        if targetCid == '' or targetCid == Player.PlayerData.citizenid then
            finish('Enter another player’s citizen ID.', false)
            return
        end
        for _, targetSource in ipairs(QBCore.Functions.GetPlayers()) do
            local candidate = getPlayer(targetSource)
            if candidate and candidate.PlayerData.citizenid == targetCid then
                recipient = candidate
                break
            end
        end
        if not recipient then finish('That player must be online to receive a transfer.', false); return end
        if busy[recipient.PlayerData.source] then finish('That account is processing another transaction. Try again.', false); return end
        busy[recipient.PlayerData.source] = true
    end

    local senderMoney, recipientMoney = getMoney(Player), getMoney(recipient)
    local changed, description = false, location.label

    if action == 'deposit' then
        if senderMoney.cash < amount then finish('You do not have enough cash.', false); return end
        local removed = Player.Functions.RemoveMoney('cash', amount, 'vanta-bank-deposit')
        local added = removed and Player.Functions.AddMoney('bank', amount, 'vanta-bank-deposit')
        if removed and not added then Player.Functions.AddMoney('cash', amount, 'vanta-bank-deposit-rollback') end
        changed = removed and added
    elseif action == 'withdraw' then
        if senderMoney.bank < amount then finish('Your account does not have enough money.', false); return end
        local removed = Player.Functions.RemoveMoney('bank', amount, 'vanta-bank-withdrawal')
        local added = removed and Player.Functions.AddMoney('cash', amount, 'vanta-bank-withdrawal')
        if removed and not added then Player.Functions.AddMoney('bank', amount, 'vanta-bank-withdrawal-rollback') end
        changed = removed and added
    elseif action == 'transfer' then
        if senderMoney.bank < amount then
            busy[recipient.PlayerData.source] = nil
            finish('Your account does not have enough money.', false)
            return
        end
        if recipientMoney.bank + amount > 999999999 then
            busy[recipient.PlayerData.source] = nil
            finish('The recipient account cannot accept that amount.', false)
            return
        end
        local removed = Player.Functions.RemoveMoney('bank', amount, 'vanta-bank-transfer')
        local added = removed and recipient.Functions.AddMoney('bank', amount, 'vanta-bank-transfer')
        if removed and not added then Player.Functions.AddMoney('bank', amount, 'vanta-bank-transfer-rollback') end
        changed = removed and added
        description = ('Transfer to %s'):format(Player.PlayerData.charinfo.firstname or 'player')
    else
        if recipient then busy[recipient.PlayerData.source] = nil end
        finish('Unknown banking action.', false)
        return
    end

    if not changed then
        if recipient then busy[recipient.PlayerData.source] = nil end
        finish('The transaction could not be completed.', false)
        return
    end

    local reference = ('V%X%04X'):format(os.time(), math.random(0, 65535))
    local ledger = {
        { 'INSERT INTO vanta_bank_transactions (citizenid, action, amount, description, reference) VALUES (?, ?, ?, ?, ?)', {
            Player.PlayerData.citizenid, action == 'transfer' and 'transfer_out' or action, amount, description, reference
        } },
    }
    if recipient then
        ledger[#ledger + 1] = { 'INSERT INTO vanta_bank_transactions (citizenid, action, amount, description, reference) VALUES (?, ?, ?, ?, ?)', {
            recipient.PlayerData.citizenid, 'transfer_in', amount,
            ('Transfer from %s'):format(Player.PlayerData.charinfo.firstname or 'player'), reference
        } }
    end
    local ok, logged = pcall(function() return MySQL.transaction.await(ledger) end)
    if not ok or not logged then print(('^1[Vanta Bank]^7 Ledger write failed for %s'):format(reference)) end

    if recipient then
        busy[recipient.PlayerData.source] = nil
        notify(recipient.PlayerData.source, ('You received $%s.'):format(amount), 'success')
    end
    finish(action == 'transfer' and ('Transfer of $%s sent.'):format(amount)
        or ('%s of $%s completed.'):format(action:gsub('^%l', string.upper), amount), true)
end)

AddEventHandler('playerDropped', function() busy[source] = nil end)
