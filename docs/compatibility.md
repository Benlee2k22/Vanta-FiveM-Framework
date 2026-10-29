# QBCore compatibility

The resource in `qb-core/` is named `qb-core` deliberately. FiveM resolves `exports['qb-core']` using the resource name, so it must not be renamed after installation. Disable the original QBCore core resource first.

## Interaction style

Vanta uses proximity interactions controlled with **E** and the scroll wheel. A registered nearby interaction appears on the HUD; scroll to select an option and press E to trigger it. There is no eye-target system bundled. Quick actions use a separate radial menu, opened with F1 by default. Other resources can register interaction points and radial entries with the `vanta-ui` exports.

```lua
exports['vanta-ui']:AddInteraction('shop:counter', {
    coords = { x = 24.5, y = -1346.2, z = 29.5 },
    distance = 2.0,
    label = 'Corner shop',
    options = {
        { label = 'Browse shop', event = 'myshop:client:open', type = 'client' },
        { label = 'Speak to cashier', event = 'myshop:client:talk', type = 'client' },
    }
})
exports['vanta-ui']:AddRadialItem('escort', {
    label = 'Escort', icon = '⇄', event = 'myresource:client:toggleEscort', type = 'client'
})
```

## Supported baseline

- `exports['qb-core']:GetCoreObject()`
- Client `Functions.GetPlayerData`, `TriggerCallback`, `Notify`, `Progressbar`, `GetCoords`, `HasItem`
- Server `Functions.GetPlayer`, `GetPlayers`, `GetPlayerByCitizenId`, callbacks, permission checks and notify
- Player data fields for source, citizen ID, license, money, character info, job and metadata
- Player money operations and basic job set operation
- Common player loaded/unloaded and money/job change events

## Known limitations

This is an early compatibility layer, not a drop-in clone of every QBCore release. It does not bundle inventory, shops, gangs, vehicles, multicharacter selection, banking, management, target, clothing, housing, or phone resources. `HasItem` returns false because there is no inventory adapter. `Shared.Items`, `Jobs`, `Gangs` and `Vehicles` are only small placeholders. Scripts that access core internals or rely on custom QBCore events will need an adapter.

Before switching a live server, inventory each resource and replace the old `qb-core` in a staging server. Test player load, save, money, job changes, callbacks and each script's integrations. Back up the database first.

## Example

```lua
local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.TriggerCallback('example:server:getBalance', function(balance)
    QBCore.Functions.Notify(('Balance: $%s'):format(balance), 'success')
end)
```

Server player lookup:

```lua
local QBCore = exports['qb-core']:GetCoreObject()
local Player = QBCore.Functions.GetPlayer(source)
if Player then
    Player.Functions.AddMoney('cash', 100, 'example-reward')
end
```
