local uiOpen, mode, selected = false, 'shop', { kind = 'component', id = 11 }
local function capture()
    local ped = PlayerPedId()
    local appearance = { model = GetEntityModel(ped), components = {}, props = {} }
    for id = 0, 11 do
        appearance.components[tostring(id)] = { drawable = GetPedDrawableVariation(ped, id), texture = GetPedTextureVariation(ped, id), palette = GetPedPaletteVariation(ped, id) }
    end
    for _, id in ipairs({ 0, 1, 2, 6, 7 }) do
        appearance.props[tostring(id)] = { drawable = GetPedPropIndex(ped, id), texture = GetPedPropTextureIndex(ped, id) }
    end
    return appearance
end

local function apply(appearance)
    if type(appearance) ~= 'table' then return end
    local model = tonumber(appearance.model)
    if model and IsModelInCdimage(model) and IsModelValid(model) and GetEntityModel(PlayerPedId()) ~= model then
        RequestModel(model)
        local timeout = GetGameTimer() + 8000
        while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
        if HasModelLoaded(model) then SetPlayerModel(PlayerId(), model); SetModelAsNoLongerNeeded(model) end
    end
    local ped = PlayerPedId()
    for id, item in pairs(appearance.components or {}) do
        id = tonumber(id)
        if id and type(item) == 'table' then SetPedComponentVariation(ped, id, tonumber(item.drawable) or 0, tonumber(item.texture) or 0, tonumber(item.palette) or 0) end
    end
    for id, item in pairs(appearance.props or {}) do
        id = tonumber(id)
        if id and type(item) == 'table' then
            if (tonumber(item.drawable) or -1) < 0 then ClearPedProp(ped, id) else SetPedPropIndex(ped, id, tonumber(item.drawable) or 0, tonumber(item.texture) or 0, true) end
        end
    end
end

local function state()
    local ped, appearance = PlayerPedId(), capture()
    local components, props = {}, {}
    for id, label in pairs(VantaClothingConfig.Components) do
        local drawable = GetPedDrawableVariation(ped, id)
        components[#components + 1] = { kind = 'component', id = id, label = label, drawable = drawable, texture = GetPedTextureVariation(ped, id), maxDrawable = math.max(0, GetNumberOfPedDrawableVariations(ped, id) - 1), maxTexture = math.max(0, GetNumberOfPedTextureVariations(ped, id, drawable) - 1) }
    end
    for id, label in pairs(VantaClothingConfig.Props) do
        local drawable = GetPedPropIndex(ped, id)
        props[#props + 1] = { kind = 'prop', id = id, label = label, drawable = drawable, texture = drawable < 0 and 0 or GetPedPropTextureIndex(ped, id), maxDrawable = math.max(-1, GetNumberOfPedPropDrawableVariations(ped, id) - 1), maxTexture = drawable < 0 and 0 or math.max(0, GetNumberOfPedPropTextureVariations(ped, id, drawable) - 1) }
    end
    table.sort(components, function(a,b) return a.id < b.id end)
    table.sort(props, function(a,b) return a.id < b.id end)
    return { components = components, props = props, appearance = appearance, mode = mode, price = VantaClothingConfig.ShopPrice }
end

local function open(modeValue)
    if uiOpen then return end
    uiOpen, mode = true, modeValue == 'wardrobe' and 'wardrobe' or 'shop'
    SetNuiFocus(true, true); SendNUIMessage({ action = 'clothing:open', state = state() })
    if mode == 'wardrobe' then TriggerServerEvent('vanta:clothing:requestOutfits') end
end
RegisterNetEvent('vanta:clothing:openShop', function() open('shop') end)
RegisterNetEvent('vanta:clothing:openWardrobe', function() open('wardrobe') end)
RegisterNetEvent('vanta:clothing:outfits', function(rows) SendNUIMessage({ action = 'clothing:outfits', outfits = rows or {} }) end)
RegisterNetEvent('vanta:clothing:refreshOutfits', function() TriggerServerEvent('vanta:clothing:requestOutfits') end)
RegisterNetEvent('vanta:clothing:apply', function(appearance) apply(appearance); SendNUIMessage({ action = 'clothing:state', state = state() }) end)

local function adjust(kind, id, field, delta)
    local ped = PlayerPedId()
    id, delta = tonumber(id), tonumber(delta) or 0
    if not id or math.abs(delta) > 1 then return end
    if kind == 'component' and id >= 0 and id <= 11 then
        local drawable = GetPedDrawableVariation(ped, id)
        if field == 'drawable' then
            local count = GetNumberOfPedDrawableVariations(ped, id)
            if count > 0 then drawable = (drawable + delta) % count; SetPedComponentVariation(ped, id, drawable, 0, GetPedPaletteVariation(ped, id)) end
        elseif field == 'texture' then
            local count = GetNumberOfPedTextureVariations(ped, id, drawable)
            if count > 0 then SetPedComponentVariation(ped, id, drawable, (GetPedTextureVariation(ped, id) + delta) % count, GetPedPaletteVariation(ped, id)) end
        end
    elseif kind == 'prop' and ({ [0]=true,[1]=true,[2]=true,[6]=true,[7]=true })[id] then
        local drawable = GetPedPropIndex(ped, id)
        if field == 'drawable' then
            local count = GetNumberOfPedPropDrawableVariations(ped, id)
            local nextValue = drawable + delta
            if nextValue < -1 then nextValue = count - 1 elseif nextValue >= count then nextValue = -1 end
            if nextValue < 0 then ClearPedProp(ped, id) else SetPedPropIndex(ped, id, nextValue, 0, true) end
        elseif field == 'texture' and drawable >= 0 then
            local count = GetNumberOfPedPropTextureVariations(ped, id, drawable)
            if count > 0 then SetPedPropIndex(ped, id, drawable, (GetPedPropTextureIndex(ped, id) + delta) % count, true) end
        end
    end
    SendNUIMessage({ action = 'clothing:state', state = state() })
end

RegisterNUICallback('clothing:adjust', function(data, cb) adjust(data.kind, data.id, data.field, data.delta); cb({ ok = true }) end)
RegisterNUICallback('clothing:save', function(data, cb)
    TriggerServerEvent('vanta:clothing:saveOutfit', data.label, capture(), mode)
    cb({ ok = true })
end)
RegisterNUICallback('clothing:wear', function(data, cb) TriggerServerEvent('vanta:clothing:wearOutfit', data.id); cb({ ok = true }) end)
RegisterNUICallback('clothing:delete', function(data, cb) TriggerServerEvent('vanta:clothing:deleteOutfit', data.id); cb({ ok = true }) end)
RegisterNUICallback('clothing:close', function(_, cb) uiOpen = false; SetNuiFocus(false, false); cb({ ok = true }) end)

CreateThread(function()
    Wait(1000)
    for _, point in ipairs(VantaClothingConfig.Shops) do
        exports['vanta-ui']:AddInteraction('clothing-shop-' .. point.id, {
            coords = point, distance = VantaClothingConfig.InteractionDistance, label = point.label, icon = '✂',
            options = { { label = ('Browse clothing ($%s to buy)'):format(VantaClothingConfig.ShopPrice), event = 'vanta:clothing:openShop' } },
        })
    end
    for _, point in ipairs(VantaClothingConfig.Wardrobes) do
        exports['vanta-ui']:AddInteraction('clothing-wardrobe-' .. point.id, {
            coords = point, distance = VantaClothingConfig.InteractionDistance, label = point.label, icon = '⌂',
            options = { { label = 'Open wardrobe', event = 'vanta:clothing:openWardrobe' } },
        })
    end
end)
