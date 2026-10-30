# Vanta interface systems

## Nearby interactions

Register a location from a client resource with:

```lua
exports['vanta-ui']:AddInteraction('example:desk', {
    coords = { x = 0.0, y = 0.0, z = 0.0 },
    distance = 2.0,
    label = 'Service desk',
    icon = '!',
    options = {
        { label = 'Open service menu', event = 'example:client:open', type = 'client' },
    },
})
```

The lower-left prompt appears in range. Press **E** or **Enter** to open it, scroll the options, and press **E** or **Enter** to run the selected action. The server must still validate any protected action.

## QBCore integration

The txAdmin recipe sets `UseTarget false` and downloads the standard QBCore resources. This turns off the target-eye interaction mode. QBCore's F1 radial, character selection, spawn selector, clothing, banking, police, EMS and inventory resources remain in place.

The Vanta prompt is available to Vanta-aware resources through `AddInteraction`. The current clean baseline has not yet replaced every stock QBCore prompt; the adapter for those interactions will be built against this baseline.

## Loading screen

The Vanta loading screen displays the connection progress, rotating tips and an optional locally synthesized ambient pad. QBCore's multicharacter resource closes the manual loading screen when character selection opens.
