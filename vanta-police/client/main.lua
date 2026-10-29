local cuffed, escorted = false, false
local function closestPlayer(maxDistance)
    local myPed, myCoords, best, bestDistance = PlayerPedId(), GetEntityCoords(PlayerPedId()), nil, maxDistance or 2.5
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            local distance = #(myCoords - GetEntityCoords(ped))
            if distance < bestDistance then best, bestDistance = GetPlayerServerId(player), distance end
        end
    end
    return best
end
local function registerStationInteractions()
    for _, station in ipairs(VantaPoliceConfig.Stations) do
        exports['vanta-ui']:AddInteraction('vanta-police:'..station.id, {
            coords = station.coords, distance = station.radius, label = station.label,
            options = {
                { label = 'Clock in / out', event = 'vanta-police:client:toggleDuty', type = 'client' },
                { label = 'Request backup', event = 'vanta-police:client:requestBackup', type = 'client' },
            }
        })
    end
end
CreateThread(function() while GetResourceState('vanta-ui') ~= 'started' do Wait(250) end; registerStationInteractions() end)

RegisterNetEvent('vanta-police:client:toggleDuty', function() TriggerServerEvent('vanta-police:server:toggleDuty') end)
RegisterNetEvent('vanta-police:client:requestBackup', function() TriggerServerEvent('vanta-police:server:backup') end)
RegisterNetEvent('vanta-police:client:cuffNearest', function() local target = closestPlayer(); if target then TriggerServerEvent('vanta-police:server:toggleCuffs', target) else TriggerEvent('vanta:ui:notify', { title = 'LSPD', description = 'No one is close enough.', type = 'error' }) end end)
RegisterNetEvent('vanta-police:client:escortNearest', function() local target = closestPlayer(); if target then TriggerServerEvent('vanta-police:server:toggleEscort', target) else TriggerEvent('vanta:ui:notify', { title = 'LSPD', description = 'No one is close enough.', type = 'error' }) end end)
RegisterNetEvent('vanta-police:client:setCuffed', function(state)
    cuffed = state == true
    local ped = PlayerPedId()
    SetEnableHandcuffs(ped, cuffed)
    if cuffed then TaskHandsUp(ped, -1, 0, -1, true) else ClearPedTasks(ped) end
end)
RegisterNetEvent('vanta-police:client:setEscorted', function(officerId)
    escorted = officerId or false
    local ped = PlayerPedId()
    if not escorted then DetachEntity(ped, true, false); return end
    CreateThread(function()
        while escorted do
            local player = GetPlayerFromServerId(escorted)
            if player ~= -1 then
                local officerPed = GetPlayerPed(player)
                if DoesEntityExist(officerPed) and not IsEntityAttachedToEntity(ped, officerPed) then
                    AttachEntityToEntity(ped, officerPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                end
            end
            Wait(500)
        end
    end)
end)
RegisterNetEvent('vanta-police:client:backupAlert', function(data)
    TriggerEvent('vanta:ui:notify', { title = 'Backup request', description = ('%s requests assistance.'):format(data.name or 'An officer'), type = 'warning', duration = 7000 })
    if data.coords then SetNewWaypoint(data.coords.x, data.coords.y) end
end)

local function setRadialEnabled(enabled)
    if enabled then
        exports['vanta-ui']:AddRadialItem('police:cuff', { label = 'Cuff / Uncuff', icon = '⛓', event = 'vanta-police:client:cuffNearest', type = 'client' })
        exports['vanta-ui']:AddRadialItem('police:escort', { label = 'Escort', icon = '⇄', event = 'vanta-police:client:escortNearest', type = 'client' })
        exports['vanta-ui']:AddRadialItem('police:backup', { label = 'Request backup', icon = '!', event = 'vanta-police:client:requestBackup', type = 'client' })
    else
        exports['vanta-ui']:RemoveRadialItem('police:cuff'); exports['vanta-ui']:RemoveRadialItem('police:escort'); exports['vanta-ui']:RemoveRadialItem('police:backup')
    end
end
local function refreshJob(data)
    local job = data and data.job
    setRadialEnabled(job and job.name == VantaPoliceConfig.Job and job.onduty == true)
end
RegisterNetEvent('vanta:client:loaded', refreshJob)
RegisterNetEvent('vanta:client:jobUpdated', function(job) refreshJob({ job = job }) end)
CreateThread(function() Wait(1000); refreshJob(exports['vanta-core']:GetPlayerData()) end)

CreateThread(function()
    while true do
        if cuffed then
            DisableControlAction(0, 21, true); DisableControlAction(0, 22, true); DisableControlAction(0, 23, true)
            DisableControlAction(0, 24, true); DisableControlAction(0, 25, true); DisableControlAction(0, 37, true)
            DisableControlAction(0, 44, true); DisableControlAction(0, 75, true); DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true); DisableControlAction(0, 142, true); DisableControlAction(0, 143, true)
            Wait(0)
        else Wait(500) end
    end
end)
