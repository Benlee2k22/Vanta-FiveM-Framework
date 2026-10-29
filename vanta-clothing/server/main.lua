local function createTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS vanta_outfits (
          id bigint unsigned NOT NULL AUTO_INCREMENT,
          citizenid varchar(50) NOT NULL,
          label varchar(40) NOT NULL,
          appearance longtext NOT NULL,
          created_at timestamp NOT NULL DEFAULT current_timestamp(),
          PRIMARY KEY (id),
          KEY idx_vanta_outfit_citizen (citizenid, id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

local function closeTo(src, list)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local pos = GetEntityCoords(ped)
    for _, point in ipairs(list) do
        if #(pos - vector3(point.x, point.y, point.z)) <= 4.0 then return true end
    end
    return false
end

local function cleanAppearance(value)
    if type(value) ~= 'table' or type(value.components) ~= 'table' or type(value.props) ~= 'table' then return nil end
    local out = { model = math.floor(tonumber(value.model) or 0), components = {}, props = {} }
    for id = 0, 11 do
        local item = value.components[tostring(id)] or value.components[id]
        if type(item) == 'table' then
            out.components[tostring(id)] = {
                drawable = math.max(0, math.min(500, math.floor(tonumber(item.drawable) or 0))),
                texture = math.max(0, math.min(100, math.floor(tonumber(item.texture) or 0))),
                palette = math.max(0, math.min(3, math.floor(tonumber(item.palette) or 0))),
            }
        end
    end
    for _, id in ipairs({ 0, 1, 2, 6, 7 }) do
        local item = value.props[tostring(id)] or value.props[id]
        if type(item) == 'table' then
            out.props[tostring(id)] = {
                drawable = math.max(-1, math.min(500, math.floor(tonumber(item.drawable) or -1))),
                texture = math.max(0, math.min(100, math.floor(tonumber(item.texture) or 0))),
            }
        end
    end
    if out.model == 0 then return nil end
    return out
end

RegisterNetEvent('vanta:clothing:requestOutfits', function()
    local src = source
    local data = exports['vanta-core']:GetPlayerData(src)
    if not data or not closeTo(src, VantaClothingConfig.Wardrobes) then return end
    local rows = MySQL.query.await('SELECT id, label, appearance FROM vanta_outfits WHERE citizenid = ? ORDER BY id DESC', { data.citizenid }) or {}
    for _, row in ipairs(rows) do
        local ok, decoded = pcall(json.decode, row.appearance)
        row.appearance = ok and decoded or {}
    end
    TriggerClientEvent('vanta:clothing:outfits', src, rows)
end)

RegisterNetEvent('vanta:clothing:saveOutfit', function(label, appearance, mode)
    local src = source
    local data = exports['vanta-core']:GetPlayerData(src)
    if not data then return end
    mode = mode == 'shop' and 'shop' or 'wardrobe'
    if mode == 'shop' then
        if not closeTo(src, VantaClothingConfig.Shops) then return end
        if not exports['vanta-core']:RemoveMoney(src, 'cash', VantaClothingConfig.ShopPrice, 'clothing') then
            TriggerClientEvent('vanta:ui:notify', src, { title = 'Clothing store', description = 'You do not have enough cash for this outfit.', type = 'error' })
            return
        end
    elseif not closeTo(src, VantaClothingConfig.Wardrobes) then return end

    local appearanceData = cleanAppearance(appearance)
    if not appearanceData then return end
    label = type(label) == 'string' and label:gsub('[^%w%s%-]', ''):gsub('^%s+', ''):gsub('%s+$', '') or 'Saved outfit'
    if #label < 2 then label = 'Saved outfit' end
    label = label:sub(1, 40)
    MySQL.insert.await('INSERT INTO vanta_outfits (citizenid, label, appearance) VALUES (?, ?, ?)', { data.citizenid, label, json.encode(appearanceData) })
    MySQL.update.await('UPDATE vanta_characters SET appearance = ? WHERE citizenid = ?', { json.encode(appearanceData), data.citizenid })
    exports['vanta-core']:SavePlayer(src)
    TriggerClientEvent('vanta:ui:notify', src, { title = 'Outfit saved', description = mode == 'shop' and ('Saved and purchased for $%s.'):format(VantaClothingConfig.ShopPrice) or 'Your outfit was saved.', type = 'success' })
    TriggerClientEvent('vanta:clothing:refreshOutfits', src)
end)

RegisterNetEvent('vanta:clothing:wearOutfit', function(outfitId)
    local src = source
    local data = exports['vanta-core']:GetPlayerData(src)
    if not data or not closeTo(src, VantaClothingConfig.Wardrobes) then return end
    local row = MySQL.single.await('SELECT appearance FROM vanta_outfits WHERE id = ? AND citizenid = ?', { tonumber(outfitId), data.citizenid })
    if not row then return end
    local ok, appearance = pcall(json.decode, row.appearance)
    if not ok then return end
    local clean = cleanAppearance(appearance)
    if not clean then return end
    TriggerClientEvent('vanta:clothing:apply', src, clean)
    MySQL.update.await('UPDATE vanta_characters SET appearance = ? WHERE citizenid = ?', { json.encode(clean), data.citizenid })
end)

RegisterNetEvent('vanta:clothing:deleteOutfit', function(outfitId)
    local src = source
    local data = exports['vanta-core']:GetPlayerData(src)
    if not data or not closeTo(src, VantaClothingConfig.Wardrobes) then return end
    MySQL.query.await('DELETE FROM vanta_outfits WHERE id = ? AND citizenid = ?', { tonumber(outfitId), data.citizenid })
    TriggerClientEvent('vanta:clothing:refreshOutfits', src)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then createTable() end
end)
