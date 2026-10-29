# Vanta test systems

## Interaction HUD

The interaction HUD places a boxed red action icon and **E** prompt at the lower left when a registered point is nearby. Press **E** to open that point's option list, scroll to select, and press **E** again to activate. The F1 radial stays separate for quick actions. Resources register points through `exports['vanta-ui']:AddInteraction`; configure locations in each module's `shared/config.lua`.

## Characters and spawning

The character resource supports up to four character slots per FiveM license. Create a character with a name, date of birth, nationality and freemode gender, select or delete a character, then choose its saved last location or a configured preset spawn. Money, job, inventory, metadata, position and appearance load per citizen ID. The first login for an older Vanta database migrates its existing player row into slot one.

Spawn presets and the selection scene are in `vanta-character/shared/config.lua`. Appearance selection starts with male/female freemode models. The clothing module stores native ped components and props for each citizen ID.

## Clothing and wardrobes

At a configured clothing shop, use the E prompt, select **Browse clothing**, and use the clothing panel to change components, textures and props. Saving a shop look costs the configured price (default $250) and persists it as both the active appearance and a saved outfit. At a configured wardrobe, browse saved outfits, wear one, or delete it. Store points, wardrobe points, garment categories and price are in `vanta-clothing/shared/config.lua`.

## Loading screen

The `vanta-loading` resource uses FiveM's loading-screen NUI with the platform's progress messages. It shows Vanta branding, rotating tips and a progress bar. The music toggle starts a locally synthesized ambient pad after the player clicks it; no external music file is required. The loading screen closes when the character selector is ready.

## Banking

At configured bank branches, players can deposit cash, withdraw cash, transfer to an online player using their citizen ID, and view the last 15 ledger entries. Configured ATMs allow deposits and withdrawals; transfers are branch-only. The server validates player location, amount and balances. Transactions are recorded in `vanta_bank_transactions`.

Transfers require the recipient to be online in this release. Locations and the maximum transaction amount are in `vanta-banking/shared/config.lua`.

## Inventory

Press **I** or use `/inventory` to open the persistent slot inventory. Starter items include water, sandwiches and bandages; `/giveitem [player id] [item] [amount]` grants test items. Items and stack counts are saved in `vanta_inventories`. Weight and slots are configurable in `vanta-core/shared/config.lua`.

## Police

The starter `police` job has Cadet, Officer, Sergeant, Lieutenant and Chief grades. Officers change duty at a configured station. On duty, the F1 radial menu offers nearby cuff/uncuff, escort and backup actions. Server handlers check the officer's job and duty, target identity and distance; escort requires the target to be cuffed.

Assign a job from the server console with `/setjob [server id] police [grade]`, for example `/setjob 1 police 1`. In-game use requires `add_ace group.admin vanta.admin allow` and membership in `group.admin`.

## Hospital and EMS

The starter `ambulance` job has four grades. Players can check in at configured reception points for a $500 bank charge. On-duty EMS can clock in at hospital reception and choose **Treat nearby** from the F1 radial menu. Check-in revives/heals the player's ped and moves them to a configured bed. EMS treatment revives/heals the nearby target at their current position.

This initial medical loop does not include injury/death integration, stretcher animations, ambulance vehicles, dispatch paging or medical inventory yet.

## Development server scope

These are early access systems for a development server. Third-party scripts may need adapters. Review map locations, economy values and ACE permissions before opening the server to players. Back up the database before importing schema updates.
