# Vanta test systems

## E-and-scroll interactions

Nearby resources register points through `exports['vanta-ui']:AddInteraction`. The HUD prompt shows available options; use the mouse wheel to change selection and press **E** to activate it. There is no eye-target resource. Edit locations and interaction distances in each module's `shared/config.lua`.

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

These are starter systems for a development server. Third-party scripts may need adapters. Review map locations, economy values and ACE permissions before opening the server to players. Back up the database before importing schema updates.
