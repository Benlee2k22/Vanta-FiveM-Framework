local cooldown = {}
local processing = {}
local function playerData(src) return exports['vanta-core']:GetPlayerData(src) end
local function notify(src, message, kind) TriggerClientEvent('vanta:ui:notify', src, { title = 'Medical', description = message, type = kind or 'info' }) end
local function getHospital(src, id)
    local ped = GetPlayerPed(src); if ped == 0 then return nil end
    local pos = GetEntityCoords(ped)
    for _, hospital in ipairs(VantaHospitalConfig.Hospitals) do
        if hospital.id == id and #(pos - vector3(hospital.checkin.x, hospital.checkin.y, hospital.checkin.z)) <= hospital.radius then return hospital end
    end
end
local function isMedic(src)
    local data = playerData(src)
    return data and data.job and data.job.name == VantaHospitalConfig.Job and data.job.onduty == true
end
local function payTreatment(src)
    local data = playerData(src)
    if not data then return false end
    local bank = tonumber(data.money.bank) or 0
    if bank < VantaHospitalConfig.TreatmentCost then return false end
    if not exports['vanta-core']:SetMoney(src, 'bank', bank - VantaHospitalConfig.TreatmentCost, 'hospital-treatment') then return false end
    exports['vanta-core']:SavePlayer(src)
    return true
end

RegisterNetEvent('vanta-hospital:server:checkIn', function(hospitalId)
    local src = source
    if processing[src] then return end
    if cooldown[src] and GetGameTimer() - cooldown[src] < 5000 then notify(src, 'Please wait before requesting treatment again.', 'error'); return end
    local hospital = getHospital(src, tostring(hospitalId or ''))
    if not hospital then notify(src, 'You need to be at the hospital reception.', 'error'); return end
    processing[src] = true
    if not payTreatment(src) then processing[src] = nil; notify(src, ('Treatment costs $%s. Check your bank balance.'):format(VantaHospitalConfig.TreatmentCost), 'error'); return end
    exports['vanta-banking']:RecordTransaction(src, 'hospital', VantaHospitalConfig.TreatmentCost, hospital.label)
    cooldown[src] = GetGameTimer()
    TriggerClientEvent('vanta-hospital:client:heal', src, hospital.bed)
    exports['vanta-core']:SetMetaData(src, 'isdead', false)
    exports['vanta-core']:SetMetaData(src, 'inlaststand', false)
    exports['vanta-core']:SavePlayer(src)
    processing[src] = nil
    notify(src, ('Treatment paid: $%s.'):format(VantaHospitalConfig.TreatmentCost), 'success')
end)

RegisterNetEvent('vanta-hospital:server:toggleDuty', function(hospitalId)
    local src, data = source, playerData(source)
    local hospital = getHospital(src, tostring(hospitalId or ''))
    if not hospital then notify(src, 'You need to be at a hospital to change duty.', 'error'); return end
    if not data or data.job.name ~= VantaHospitalConfig.Job then notify(src, 'You are not employed by EMS.', 'error'); return end
    local duty = exports['vanta-core']:SetDuty(src, not data.job.onduty)
    notify(src, duty and 'You are now on EMS duty.' or 'You are now off duty.', 'success')
end)

RegisterNetEvent('vanta-hospital:server:treatNearest', function(targetId)
    local src, target = source, tonumber(targetId)
    if not isMedic(src) then notify(src, 'You must be an on-duty EMS worker.', 'error'); return end
    if not target or target == src or not GetPlayerName(target) or GetPlayerPed(target) == 0 then notify(src, 'No patient nearby.', 'error'); return end
    local distance = #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target)))
    if distance > VantaHospitalConfig.MaxTreatmentDistance then notify(src, 'Move closer to the patient.', 'error'); return end
    local pos = GetEntityCoords(GetPlayerPed(target))
    TriggerClientEvent('vanta-hospital:client:heal', target, { x = pos.x, y = pos.y, z = pos.z, w = GetEntityHeading(GetPlayerPed(target)) })
    exports['vanta-core']:SetMetaData(target, 'isdead', false)
    exports['vanta-core']:SetMetaData(target, 'inlaststand', false)
    exports['vanta-core']:SavePlayer(target)
    notify(src, 'Patient treated.', 'success')
    notify(target, 'An EMS worker treated you.', 'success')
end)

AddEventHandler('playerDropped', function() cooldown[source] = nil; processing[source] = nil end)
