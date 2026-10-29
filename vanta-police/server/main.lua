local cuffed, escorted = {}, {}
local function getData(src) return exports['vanta-core']:GetPlayerData(src) end
local function isOfficer(src)
    local data = getData(src)
    return data and data.job and data.job.name == VantaPoliceConfig.Job and data.job.onduty == true
end
local function notify(src, message, kind) TriggerClientEvent('vanta:ui:notify', src, { title = 'LSPD', description = message, type = kind or 'info' }) end
local function nearStation(src)
    local ped = GetPlayerPed(src); if ped == 0 then return false end
    local pos = GetEntityCoords(ped)
    for _, station in ipairs(VantaPoliceConfig.Stations) do local c = station.coords; if #(pos - vector3(c.x, c.y, c.z)) <= station.radius then return true end end
    return false
end
local function validTarget(officer, target)
    target = tonumber(target)
    if not target or target == officer or not GetPlayerName(target) or GetPlayerPed(target) == 0 then return nil end
    local a, b = GetEntityCoords(GetPlayerPed(officer)), GetEntityCoords(GetPlayerPed(target))
    if #(a - b) > VantaPoliceConfig.MaxActionDistance then return nil end
    return target
end

RegisterNetEvent('vanta-police:server:toggleDuty', function()
    local src, data = source, getData(source)
    if not nearStation(src) then notify(src, 'You need to be at a police station to change duty.', 'error'); return end
    if not data or data.job.name ~= VantaPoliceConfig.Job then notify(src, 'You are not employed by the police.', 'error'); return end
    local duty = exports['vanta-core']:SetDuty(src, not data.job.onduty)
    notify(src, duty and 'You are now on duty.' or 'You are now off duty.', 'success')
end)

RegisterNetEvent('vanta-police:server:toggleCuffs', function(targetId)
    local src = source
    if not isOfficer(src) then notify(src, 'You must be an on-duty officer.', 'error'); return end
    local target = validTarget(src, targetId)
    if not target then notify(src, 'Move closer to the person.', 'error'); return end
    if cuffed[target] then
        cuffed[target] = nil
        TriggerClientEvent('vanta-police:client:setCuffed', target, false)
        if escorted[target] then TriggerClientEvent('vanta-police:client:setEscorted', target, false); escorted[target] = nil end
        notify(src, 'Cuffs removed.', 'success')
    else
        cuffed[target] = src
        TriggerClientEvent('vanta-police:client:setCuffed', target, true)
        notify(src, 'Person cuffed.', 'success')
    end
end)

RegisterNetEvent('vanta-police:server:toggleEscort', function(targetId)
    local src = source
    if not isOfficer(src) then notify(src, 'You must be an on-duty officer.', 'error'); return end
    local target = validTarget(src, targetId)
    if not target then notify(src, 'Move closer to the person.', 'error'); return end
    if not cuffed[target] then notify(src, 'Cuff the person before escorting them.', 'error'); return end
    if escorted[target] == src then
        escorted[target] = nil; TriggerClientEvent('vanta-police:client:setEscorted', target, false)
        notify(src, 'Person released from escort.', 'success')
    elseif escorted[target] then
        notify(src, 'Another officer is already escorting them.', 'error')
    else
        escorted[target] = src; TriggerClientEvent('vanta-police:client:setEscorted', target, src)
        notify(src, 'Person is being escorted.', 'success')
    end
end)

RegisterNetEvent('vanta-police:server:backup', function()
    local src = source
    if not isOfficer(src) then notify(src, 'You must be an on-duty officer to request backup.', 'error'); return end
    local pos = GetEntityCoords(GetPlayerPed(src))
    for _, id in ipairs(exports['vanta-core']:GetPlayers()) do
        if id ~= src and isOfficer(id) then TriggerClientEvent('vanta-police:client:backupAlert', id, { name = GetPlayerName(src), coords = { x = pos.x, y = pos.y, z = pos.z } }) end
    end
    notify(src, 'Backup requested.', 'success')
end)

AddEventHandler('playerDropped', function()
    local src = source
    cuffed[src] = nil; escorted[src] = nil
    for target, officer in pairs(escorted) do
        if officer == src then escorted[target] = nil; TriggerClientEvent('vanta-police:client:setEscorted', target, false) end
    end
end)
