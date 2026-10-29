local theme = { accent = '#8b7bff', surface = '#11131b', radius = 16, scale = 100 }
local activeProgress, radialOpen = false, false
local interactions, radialItems = {}, {}
local activeInteraction, selection, sentSelection = nil, 1, nil
local interactionMenuOpen = false
local function setFocus(value) SetNuiFocus(value, value); SetNuiFocusKeepInput(false) end

RegisterCommand('uitheme', function()
    setFocus(true); SendNUIMessage({ action = 'theme:open', theme = theme })
end, false)
RegisterCommand('uisettings', function()
    theme = { accent = '#8b7bff', surface = '#11131b', radius = 16, scale = 100 }
    SendNUIMessage({ action = 'theme:set', theme = theme })
    TriggerEvent('vanta:ui:notify', { title = 'Appearance', description = 'Your theme has been reset.', type = 'success' })
end, false)
RegisterNetEvent('vanta:ui:notify', function(options) SendNUIMessage({ action = 'notify', data = options or {} }) end)

local function runOption(option)
    if not option then return end
    if option.type == 'server' then TriggerServerEvent(option.event, option.args)
    elseif option.type == 'command' then ExecuteCommand(option.command or option.event)
    elseif option.event then TriggerEvent(option.event, option.args) end
end
local function openRadial()
    local entries = {}
    for id, item in pairs(radialItems) do entries[#entries + 1] = { id = id, label = item.label, icon = item.icon or '•' } end
    table.sort(entries, function(a, b) return a.id < b.id end)
    if #entries == 0 then TriggerEvent('vanta:ui:notify', { title = 'Quick actions', description = 'No radial actions are registered.', type = 'info' }); return end
    radialOpen = true; SetNuiFocus(true, true); SendNUIMessage({ action = 'radial:open', items = entries })
end
RegisterCommand('vantaradial', openRadial, false)
RegisterKeyMapping('vantaradial', 'Open Vanta quick actions', 'keyboard', 'F1')
exports('AddRadialItem', function(id, item) if type(id) == 'string' and type(item) == 'table' then radialItems[id] = item end end)
exports('RemoveRadialItem', function(id) radialItems[id] = nil end)
exports('AddInteraction', function(id, data)
    if type(id) ~= 'string' or type(data) ~= 'table' or type(data.coords) ~= 'table' then return false end
    local options = {}
    for _, option in ipairs(data.options or {}) do options[#options + 1] = option end
    interactions[id] = { coords = vector3(data.coords.x or 0, data.coords.y or 0, data.coords.z or 0), distance = tonumber(data.distance) or 2.0, label = data.label or 'Interact', icon = data.icon or '!', options = options }
    return true
end)
exports('RemoveInteraction', function(id) interactions[id] = nil end)

RegisterNUICallback('radial:select', function(data, cb)
    local item = radialItems[data.id]
    if item then runOption(item) end
    radialOpen = false; SetNuiFocus(false, false); cb({ ok = item ~= nil })
end)
RegisterNUICallback('radial:close', function(_, cb) radialOpen = false; SetNuiFocus(false, false); cb({ ok = true }) end)
RegisterNUICallback('interaction:select', function(data, cb)
    local current = activeInteraction and interactions[activeInteraction]
    if current and current.options[data.index] then runOption(current.options[data.index]) end
    cb({ ok = current ~= nil })
end)

exports('Notify', function(options) TriggerEvent('vanta:ui:notify', options) end)
exports('Progress', function(options, cb)
    if activeProgress then if cb then cb(false) end; return end
    activeProgress = true; options = options or {}
    SendNUIMessage({ action = 'progress:start', data = options })
    CreateThread(function()
        local duration, started, cancelled = math.max(100, tonumber(options.duration) or 1000), GetGameTimer(), false
        while activeProgress and GetGameTimer() - started < duration do
            Wait(0)
            if options.canCancel and IsControlJustPressed(0, 202) then cancelled = true; break end
        end
        if activeProgress then activeProgress = false; SendNUIMessage({ action = 'progress:finish' }) end
        if cb then cb(not cancelled) end
    end)
end)
RegisterNUICallback('close', function(_, cb) setFocus(false); cb({ ok = true }) end)
RegisterNUICallback('theme:set', function(data, cb)
    theme = {
        accent = type(data.accent) == 'string' and data.accent:match('^#[%da-fA-F]+$') and data.accent or theme.accent,
        surface = type(data.surface) == 'string' and data.surface:match('^#[%da-fA-F]+$') and data.surface or theme.surface,
        radius = math.min(24, math.max(4, tonumber(data.radius) or theme.radius)),
        scale = math.min(120, math.max(80, tonumber(data.scale) or theme.scale)),
    }
    SendNUIMessage({ action = 'theme:set', theme = theme }); cb({ ok = true, theme = theme })
end)
RegisterNUICallback('theme:preset', function(data, cb)
    local presets = {
        midnight = { accent = '#8b7bff', surface = '#11131b', radius = 16, scale = 100 },
        emerald = { accent = '#35d39a', surface = '#101813', radius = 14, scale = 100 },
        synthwave = { accent = '#ff63cb', surface = '#191020', radius = 18, scale = 100 },
        ice = { accent = '#58c7ff', surface = '#101820', radius = 12, scale = 100 },
    }
    if presets[data.name] then theme = presets[data.name]; SendNUIMessage({ action = 'theme:set', theme = theme }) end
    cb({ ok = true, theme = theme })
end)
RegisterKeyMapping('uitheme', 'Open Vanta theme editor', 'keyboard', '')
AddEventHandler('onResourceStop', function(resource) if resource == GetCurrentResourceName() then setFocus(false) end end)

local function closeInteractionMenu()
    if interactionMenuOpen then
        interactionMenuOpen = false
        sentSelection = nil
        SendNUIMessage({ action = 'interaction:menu:hide' })
    end
end

CreateThread(function()
    while true do
        local waitTime, ped = 500, PlayerPedId()
        local position, nearest, nearestDistance = GetEntityCoords(ped), nil, 9999.0
        for id, entry in pairs(interactions) do
            local distance = #(position - entry.coords)
            if distance <= entry.distance and distance < nearestDistance then nearest, nearestDistance = id, distance end
        end

        if nearest and not radialOpen and not IsNuiFocused() then
            waitTime = 0
            local entry = interactions[nearest]
            if activeInteraction ~= nearest then
                closeInteractionMenu()
                activeInteraction, selection, sentSelection = nearest, 1, nil
                SendNUIMessage({ action = 'interaction:prompt', label = entry.label, icon = entry.icon })
            end

            if #entry.options > 0 then
                DisableControlAction(0, 38, true)
                DisableControlAction(0, 241, true)
                DisableControlAction(0, 242, true)
                if interactionMenuOpen then DisableControlAction(0, 202, true) end

                if interactionMenuOpen then
                    if IsDisabledControlJustPressed(0, 241) then selection = selection <= 1 and #entry.options or selection - 1 end
                    if IsDisabledControlJustPressed(0, 242) then selection = selection >= #entry.options and 1 or selection + 1 end
                    selection = math.min(selection, #entry.options)

                    if sentSelection ~= selection then
                        sentSelection = selection
                        SendNUIMessage({ action = 'interaction:menu:show', label = entry.label, options = entry.options, selected = selection })
                    end

                    if IsDisabledControlJustPressed(0, 38) then
                        runOption(entry.options[selection])
                        closeInteractionMenu()
                    elseif IsDisabledControlJustPressed(0, 202) then
                        closeInteractionMenu()
                    end
                elseif IsDisabledControlJustPressed(0, 38) then
                    interactionMenuOpen, selection, sentSelection = true, 1, nil
                    SendNUIMessage({ action = 'interaction:menu:show', label = entry.label, options = entry.options, selected = selection })
                    sentSelection = selection
                end
            end
        elseif activeInteraction then
            closeInteractionMenu()
            activeInteraction, sentSelection = nil, nil
            SendNUIMessage({ action = 'interaction:hide' })
        end
        Wait(waitTime)
    end
end)
