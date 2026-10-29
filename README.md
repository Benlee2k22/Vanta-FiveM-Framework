# Vanta Framework for FiveM

Vanta is an original FiveM roleplay framework foundation with a modern, themeable NUI and a QBCore compatibility resource.

> **Status:** early access foundation. It is launchable for development and controlled server trials, but is not yet a complete replacement for every QBCore resource. Inventory, character selection, housing, garages, jobs and banking are separate module work.

## Included

- `vanta-core`: player persistence, money, jobs, callbacks, notifications, permissions and exports.
- `qb-core` compatibility resource: `exports['qb-core']:GetCoreObject()` with common player, callback, notify and progress APIs.
- `vanta-ui`: original dark glass theme, presets, `/uitheme`, `/uisettings`, E-and-scroll proximity interactions, F1 radial quick actions, notifications and progress bar.
- SQL schema and example `server.cfg`.

Compatibility depends on each script's API usage. Standard QBCore calls can be translated; scripts that depend on QBCore internals, inventory/target resources or custom events need a matching adapter/module.

## Requirements

- FXServer with OneSync enabled
- MariaDB/MySQL and [oxmysql](https://github.com/overextended/oxmysql)

## Install

1. Put `vanta-core`, `vanta-ui` and `qb-core` in your resources directory. Keep the compatibility folder named **`qb-core`** so existing scripts resolve `exports['qb-core']`.
2. Import `sql/vanta.sql` into the database configured for oxmysql.
3. Set `mysql_connection_string` in `server.cfg`.
4. Ensure resources in this order:

```cfg
ensure oxmysql
ensure vanta-core
ensure vanta-ui
ensure qb-core
```

5. Start framework-dependent scripts after those lines. Disable the original QBCore `qb-core` to avoid a resource-name conflict.
6. Connect and use `/uitheme` to open the theme editor. Use `/vantahelp` for commands.

## Security

- Treat client events as untrusted. Validate money and gameplay actions server-side.
- Set ACE permissions for admin commands.
- Never commit database credentials or server keys.

## License

MIT. See [LICENSE](LICENSE).
