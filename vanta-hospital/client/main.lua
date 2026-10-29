local function closestPlayer(maxDistance)
    local coords, closest, best = GetEntityCoords(PlayerPedId()), nil, maxDistance or VantaHospitalConfig.MaxTreatmentDistance
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then local ped = GetPlayerPed(player); local distance = #(coords - GetEntityCoords(ped)); if distance < best then closest, best = GetPlayerServerId(player), distance end end
    end
    return closest
end
local function registerInteractions()
    for _, hospital in ipairs(VantaHospitalConfig.Hospitals) do
        exports['vanta-ui']:AddInteraction('vanta-hospital:'..hospital.id, {
            coords = hospital.checkin, distance = hospital.radius, label = hospital.label,
            options = {
                { label = ('Check in for treatment · $%s'):format(VantaHospitalConfig.TreatmentCost), event = 'vanta-hospital:client:checkIn', type = 'client', args = hospital.id },
                { label = 'EMS clock in / out', event = 'vanta-hospital:client:toggleDuty', type = 'client', args = hospital.id },
            }
        })
    end
end
CreateThread(function() while GetResourceState('vanta-ui') ~= 'started' do Wait(250) end; registerInteractions() end)
RegisterNetEvent('vanta-hospital:client:checkIn', function(id) TriggerServerEvent('vanta-hospital:server:checkIn', id) end)
RegisterNetEvent('vanta-hospital:client:toggleDuty', function(id) TriggerServerEvent('vanta-hospital:server:toggleDuty', id) end)
RegisterNetEvent('vanta-hospital:client:treatNearest', function()
    local target = closestPlayer()
    if target then TriggerServerEvent('vanta-hospital:server:treatNearest', target)
    else TriggerEvent('vanta:ui:notify', { title = 'Medical', description = 'No patient nearby.', type = 'error' }) end
end)
RegisterNetEvent('vanta-hospital:client:heal', function(coords)
    local ped = PlayerPedId()
    DoScreenFadeOut(500); Wait(700)
    if IsEntityDead(ped) then NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.w or 0.0, true, false) else SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false); SetEntityHeading(ped, coords.w or 0.0) end
    ClearPedTasksImmediately(ped); ClearPedBloodDamage(ped); SetEntityHealth(ped, GetEntityMaxHealth(ped))
    Wait(300); DoScreenFadeIn(700)
end)

local function refreshJob(data)
    local job = data and data.job
    if job and job.name == VantaHospitalConfig.Job and job.onduty then
        exports['vanta-ui']:AddRadialItem('ems:treat', { label = 'Treat nearby', icon = '✚', event = 'vanta-hospital:client:treatNearest', type = 'client' })
    else
        exports['vanta-ui']:RemoveRadialItem('ems:treat')
    end
end
RegisterNetEvent('vanta:client:loaded', refreshJob)
RegisterNetEvent('vanta:client:jobUpdated', function(job) refreshJob({ job = job }) end)
CreateThread(function() Wait(1000); refreshJob(exports['vanta-core']:GetPlayerData()) end)
