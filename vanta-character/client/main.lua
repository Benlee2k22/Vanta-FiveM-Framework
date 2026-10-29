local uiOpen, selectionCam = false, nil
local function setFocus(value) SetNuiFocus(value, value); SetNuiFocusKeepInput(false) end

local function openSelection()
    if uiOpen then return end
    uiOpen = true
    ShutdownLoadingScreenNui()
    local ped = PlayerPedId()
    local point = VantaCharacterConfig.Preview
    SetEntityCoordsNoOffset(ped, point.x, point.y, point.z, false, false, false)
    SetEntityHeading(ped, point.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, true, false)
    SetNuiFocus(true, true)
    selectionCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(selectionCam, point.x + 1.35, point.y + 2.6, point.z + 0.8)
    PointCamAtEntity(selectionCam, ped, 0.0, 0.0, 0.65, true)
    SetCamFov(selectionCam, 36.0)
    RenderScriptCams(true, true, 600, true, true)
    SendNUIMessage({ action = 'character:open' })
    TriggerServerEvent('vanta:character:requestList')
end

RegisterNetEvent('vanta:character:open', openSelection)
RegisterNetEvent('vanta:character:list', function(characters, maxSlots)
    SendNUIMessage({ action = 'character:list', characters = characters or {}, maxSlots = maxSlots or 4 })
end)
RegisterNetEvent('vanta:character:spawns', function(data)
    SendNUIMessage({ action = 'character:spawns', data = data })
end)
RegisterNUICallback('character:refresh', function(_, cb) TriggerServerEvent('vanta:character:requestList'); cb({ ok = true }) end)
RegisterNUICallback('character:create', function(data, cb) TriggerServerEvent('vanta:character:create', data); cb({ ok = true }) end)
RegisterNUICallback('character:delete', function(data, cb) TriggerServerEvent('vanta:character:delete', data.citizenid); cb({ ok = true }) end)
RegisterNUICallback('character:spawns', function(data, cb) TriggerServerEvent('vanta:character:requestSpawns', data.citizenid); cb({ ok = true }) end)
RegisterNUICallback('character:chooseSpawn', function(data, cb) TriggerServerEvent('vanta:character:chooseSpawn', data.citizenid, data.spawnId); cb({ ok = true }) end)

local function applyAppearance(appearance)
    if type(appearance) ~= 'table' then return end
    local ped = PlayerPedId()
    local model = tonumber(appearance.model)
    if not model and appearance.gender ~= nil then model = GetHashKey(tonumber(appearance.gender) == 1 and 'mp_f_freemode_01' or 'mp_m_freemode_01') end
    if model and IsModelInCdimage(model) and IsModelValid(model) then
        RequestModel(model)
        local timeout = GetGameTimer() + 8000
        while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(0) end
        if HasModelLoaded(model) then
            SetPlayerModel(PlayerId(), model)
            SetModelAsNoLongerNeeded(model)
            ped = PlayerPedId()
        end
    end
    for component, item in pairs(appearance.components or {}) do
        local id = tonumber(component)
        if id and type(item) == 'table' then SetPedComponentVariation(ped, id, tonumber(item.drawable) or 0, tonumber(item.texture) or 0, tonumber(item.palette) or 0) end
    end
    for prop, item in pairs(appearance.props or {}) do
        local id = tonumber(prop)
        if id and type(item) == 'table' then
            if (tonumber(item.drawable) or -1) < 0 then ClearPedProp(ped, id)
            else SetPedPropIndex(ped, id, tonumber(item.drawable) or 0, tonumber(item.texture) or 0, true) end
        end
    end
end

RegisterNetEvent('vanta:character:spawnAt', function(data)
    if type(data) ~= 'table' then return end
    DoScreenFadeOut(350)
    while not IsScreenFadedOut() do Wait(0) end
    local ped = PlayerPedId()
    if IsEntityDead(ped) then NetworkResurrectLocalPlayer(data.x, data.y, data.z, data.w, true, false) end
    applyAppearance(data.appearance)
    ped = PlayerPedId()
    RequestCollisionAtCoord(data.x, data.y, data.z)
    SetEntityCoordsNoOffset(ped, data.x, data.y, data.z, false, false, false)
    SetEntityHeading(ped, data.w or 0.0)
    local timeout = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do Wait(0) end
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
    if selectionCam then RenderScriptCams(false, true, 400, true, true); DestroyCam(selectionCam, false); selectionCam = nil end
    uiOpen = false
    SetNuiFocus(false, false); SetNuiFocusKeepInput(false)
    LocalPlayer.state:set('vantaSpawned', true, false)
    TriggerEvent('vanta:client:spawned')
    DoScreenFadeIn(650)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if selectionCam then RenderScriptCams(false, false, 0, true, true); DestroyCam(selectionCam, false) end
        SetNuiFocus(false, false)
        FreezeEntityPosition(PlayerPedId(), false)
    end
end)
