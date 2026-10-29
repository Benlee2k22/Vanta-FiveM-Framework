# Vanta Framework for FiveM

Vanta is an original FiveM roleplay framework foundation with a modern, themeable NUI and a QBCore compatibility resource.

> **Status:** early access foundation for development and controlled server trials. It is not yet a complete replacement for every QBCore resource. Inventory, character selection, housing, garages and a full economy remain future module work.

## Included

- `vanta-core`: player persistence, money, jobs, callbacks, notifications, permissions and exports.
- `qb-core` compatibility resource: `exports['qb-core']:GetCoreObject()` with common player, callback, notify and progress APIs.
- `vanta-ui`: original dark glass theme, presets, `/uitheme`, `/uisettings`, E-and-scroll proximity interactions, F1 radial quick actions, notifications and progress bar.
- `vanta-banking`: ATM and branch deposits, withdrawals, online player transfers and account history.
- `vanta-police`: station duty, server-checked cuffs and escort, and backup alerts.
- `vanta-hospital`: paid hospital check-in, EMS duty and nearby treatment.
- `vanta-inventory`: persistent slot inventory with usable food, water and bandages.
- SQL schema and example `server.cfg`.

Compatibility depends on each script's API usage. Standard QBCore calls can be translated; scripts that depend on QBCore internals, inventory/target resources or custom events need a matching adapter/module.

## Requirements

- FXServer with OneSync enabled
- MariaDB/MySQL and [oxmysql](https://github.com/overextended/oxmysql)

## Install

1. Put all six Vanta resources plus `qb-core` in your resources directory. Keep the compatibility folder named **`qb-core`** so existing scripts resolve `exports['qb-core']`.
2. Import `sql/vanta.sql` into the database configured for oxmysql.
3. Set `mysql_connection_string` in `server.cfg`.
4. Ensure resources in this order:

```cfg
ensure oxmysql
ensure vanta-core
ensure vanta-ui
ensure vanta-banking
ensure vanta-police
ensure vanta-hospital
ensure qb-core
ensure vanta-inventory
```

5. Start framework-dependent scripts after those lines. Disable the original QBCore `qb-core` to avoid a resource-name conflict.
6. Connect and use `/uitheme` to open the theme editor. Use `/vantahelp` for commands.
7. Assign development jobs from the console with `/setjob [player id] police 1` or `/setjob [player id] ambulance 1`. In-game use requires the `vanta.admin` ACE permission.
8. Open inventory with **I**. For development, use `/giveitem [player id] water_bottle 3` from the console or with the `vanta.admin` ACE permission.

See [docs/systems.md](docs/systems.md) for current system flows and [docs/test-checklist.md](docs/test-checklist.md) for a practical two-player test session.

## Security

- Treat client events as untrusted. Validate money and gameplay actions server-side.
- Set ACE permissions for admin commands.
- Never commit database credentials or server keys.

## License

MIT. See [LICENSE](LICENSE).
