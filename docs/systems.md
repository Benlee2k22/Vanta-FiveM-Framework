# Vanta QBCore add-on systems

## Base QBCore gameplay

The txAdmin recipe installs QBCore and its standard resources. The QBCore resources provide character selection, spawn selection, clothing, police, EMS, inventory, and the standard HUD. Their configuration and lifecycle stay owned by those resources.

## Vanta interaction UI

The Vanta UI displays a boxed prompt near the bottom-left when a registered location is close. Press **E** or **Enter** to open its options, scroll with the mouse wheel, and press **E** or **Enter** to activate the selected action. The UI resource exposes `exports['vanta-ui']:AddInteraction(id, data)` and `RemoveInteraction(id)` for add-on scripts.

The QBCore recipe sets `UseTarget false`, so the target eye is disabled. QBCore's existing radial menu remains on **F1**. Optional Vanta-specific radial actions can be registered through `AddRadialItem` and opened with **F2**.

## Loading screen

The Vanta loading screen displays server connection progress and rotating tips. Its optional ambient pad is generated locally in the browser after the player clicks the music control. QBCore's multicharacter flow calls `ShutdownLoadingScreenNui()` when the character selector opens, so the manual loading screen closes at the expected point in login.

## Vanta banking

The Vanta bank resource replaces `qb-banking` in this recipe to avoid two resources handling the same bank actions. It uses QBCore's player object and money methods for cash and bank changes. At configured branches it supports deposits, withdrawals, transfers to online characters by citizen ID, and a transaction ledger. Configured ATMs support deposits and withdrawals.

The server checks the player's distance, action, amount, balance, transfer target and transaction lock. The ledger table is created when the resource starts. Transfer recipients must be online in this early version. Configure branches, ATMs and transaction limit in `vanta-banking/shared/config.lua`.

## Adding more Vanta scripts

New modules should declare `qb-core` as a dependency and use QBCore player/money/job/inventory APIs. Use the Vanta interaction export where the E-and-scroll UI is wanted. Keep each feature in its own resource, and avoid installing a Vanta replacement and the QBCore resource for the same feature at once.
