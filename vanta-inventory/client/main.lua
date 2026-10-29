local open = false
local function playerData() return exports['vanta-core']:GetPlayerData() or {} end
local function showInventory()
    if open then return end
    open = true
    SetNuiFocus(true, true)
    local shared = exports['vanta-core']:GetShared()
    SendNUIMessage({ action = 'inventory:open', items = playerData().inventory or {}, maxSlots = shared.Inventory.maxSlots, maxWeight = shared.Inventory.maxWeight })
end
RegisterCommand('inventory', showInventory, false)
RegisterKeyMapping('inventory', 'Open inventory', 'keyboard', 'I')
RegisterNetEvent('vanta:client:inventoryUpdated', function(items)
    if open then SendNUIMessage({ action = 'inventory:update', items = items or {} }) end
end)
RegisterNUICallback('inventory:close', function(_, cb) open = false; SetNuiFocus(false, false); cb({ ok = true }) end)
RegisterNUICallback('inventory:use', function(data, cb)
    if type(data.name) == 'string' then TriggerServerEvent('QBCore:Server:UseItem', data.name) end
    cb({ ok = true })
end)
AddEventHandler('onResourceStop', function(resource) if resource == GetCurrentResourceName() and open then SetNuiFocus(false, false) end end)
