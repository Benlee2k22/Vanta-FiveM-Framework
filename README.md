# Vanta Framework for FiveM

Vanta is an original FiveM roleplay framework foundation with a modern, themeable NUI and a QBCore compatibility resource.

> **Status:** early access build for development and controlled server trials. Broad QBCore script compatibility, housing, garages and a complete economy remain future work.

## Included

- `vanta-core`: player persistence, money, jobs, callbacks, notifications, permissions and exports.
- `qb-core` compatibility resource: `exports['qb-core']:GetCoreObject()` with common player, callback, notify and progress APIs.
- `vanta-ui`: original dark glass theme, presets, `/uitheme`, `/uisettings`, E-and-scroll proximity interactions, F1 radial quick actions, notifications and progress bar.
- `vanta-banking`: ATM and branch deposits, withdrawals, online player transfers and account history.
- `vanta-police`: station duty, server-checked cuffs and escort, and backup alerts.
- `vanta-hospital`: paid hospital check-in, EMS duty and nearby treatment.
- `vanta-inventory`: persistent slot inventory with usable food, water and bandages.
- `vanta-character`: per-license character slots, character creation/deletion, character-specific data, and a last-location/preset spawn selector.
- `vanta-clothing`: component/prop clothing editor, paid clothing-store purchases, saved character outfits, and wardrobes.
- `vanta-loading`: branded loading screen, connection progress, rotating tips, and optional synthesized ambient music.
- Bottom-left boxed E interaction prompt that opens a scrollable options menu; the F1 radial remains for quick actions.
- SQL schema and example `server.cfg`.

Compatibility depends on each script's API usage. Standard QBCore calls can be translated; scripts that depend on QBCore internals, inventory/target resources or custom events need a matching adapter/module.

## Requirements

- FXServer with OneSync enabled
- MariaDB/MySQL and [oxmysql](https://github.com/overextended/oxmysql)

## Install with txAdmin

Vanta includes a txAdmin remote recipe that installs the framework resources, oxmysql, the default Cfx resources, database tables, and a starter `server.cfg`.

1. In txAdmin, open the Recipe Deployer and choose the option to enter a remote recipe URL.
2. Paste this URL:

   `https://raw.githubusercontent.com/Benlee2k22/Vanta-FiveM-Framework/vanta-next/recipe.yaml`

3. Review the recipe, then continue to the inputs. Enter your Cfx server key and the details for a MySQL/MariaDB database that the server can reach.
4. Run the recipe. It creates a new server profile, imports the Vanta tables, and downloads the new character, clothing and loading resources.
5. When deployment finishes, start the server from txAdmin and check the console for resource errors.

Use a fresh test profile and a test database for the first installation. The recipe configures a resource named `qb-core` for compatibility, so do not add it alongside another resource with the same name.

## Manual install

1. Put the Vanta resources plus `qb-core` in your resources directory. Keep the compatibility folder named **`qb-core`** so existing scripts resolve `exports['qb-core']`.
2. Import `sql/vanta.sql` into the database configured for oxmysql.
3. Set `mysql_connection_string` in `server.cfg`.
4. Ensure resources in this order:

```cfg
ensure oxmysql
ensure vanta-loading
ensure vanta-core
ensure vanta-ui
ensure vanta-character
ensure vanta-clothing
ensure vanta-banking
ensure vanta-police
ensure vanta-hospital
ensure qb-core
ensure vanta-inventory
```

5. Start framework-dependent scripts after those lines. Disable the original QBCore `qb-core` to avoid a resource-name conflict.
6. Connect and use `/uitheme` to open the theme editor. On join, create or select a character, then choose a spawn. Character slots are separate for money, job, inventory, position and appearance. Use `/vantahelp` for commands.
7. Clothing controls use the boxed E prompt at shops and wardrobes. Save shop looks for $250; saved outfits can be worn at a wardrobe. Configure locations and price in `vanta-clothing/shared/config.lua`.
8. Assign development jobs from the console with `/setjob [player id] police 1` or `/setjob [player id] ambulance 1`. In-game use requires the `vanta.admin` ACE permission.
9. Open inventory with **I**. For development, use `/giveitem [player id] water_bottle 3` from the console or with the `vanta.admin` ACE permission.

See [docs/systems.md](docs/systems.md) for current system flows and [docs/test-checklist.md](docs/test-checklist.md) for a practical two-player test session.

## Security

- Treat client events as untrusted. Validate money and gameplay actions server-side.
- Set ACE permissions for admin commands.
- Never commit database credentials or server keys.

## License

MIT. See [LICENSE](LICENSE).
