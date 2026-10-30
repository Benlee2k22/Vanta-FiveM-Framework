# Vanta QBCore Add-ons

Vanta is a set of modular FiveM resources built to run on the upstream QBCore framework. It does not replace or fork QBCore's player core.

## What the installer sets up

The txAdmin recipe is based on the [QBCore txAdmin recipe](https://github.com/qbcore-fivem/txAdminRecipe/blob/main/qbcore.yaml). It installs the standard QBCore server resources, including character selection, spawn selection, clothing, police, EMS, inventory and HUD. It adds these Vanta resources:

- `vanta-ui`: boxed bottom-left E prompt, scroll-to-select action menu, notifications, theme editor, progress UI and optional Vanta actions on F2.
- `vanta-loading`: branded loading screen with progress, tips and optional synthesized ambient music.
- `vanta-banking`: bank and ATM interactions, deposits, withdrawals, online transfers and account history using QBCore player money methods.

The QBCore recipe keeps its radial menu on **F1** and sets `UseTarget false`. Vanta's proximity interactions use E and the mouse wheel; they do not require a target eye.

The current Vanta add-on set is an early access foundation. The Vanta banking resource replaces the QBCore recipe's `qb-banking`; QBCore's other included resources provide the standard character, spawn, clothing, police, EMS and inventory flows while Vanta-specific versions are built.

## Install with txAdmin

For a fresh test server:

1. In txAdmin, open **Recipe Deployer** and select the option to enter a remote recipe URL.
2. Paste:

   `https://raw.githubusercontent.com/Benlee2k22/Vanta-FiveM-Framework/qbcore-suite/recipe.yaml`

3. Enter your Cfx server key and reachable MySQL/MariaDB connection details.
4. Run the recipe and start the new profile. Check the server console and F8 console for errors.

Use a fresh test profile and test database. This recipe deploys a QBCore server profile; it will not update a server profile that was installed from the old Vanta custom-core recipe.

## Resource order for manual installs

Install QBCore and its dependencies first. Then add the Vanta resources and ensure them after QBCore:

```cfg
ensure qb-core
ensure [qb]
ensure [standalone]
ensure [voice]
ensure [defaultmaps]

ensure vanta-loading
ensure vanta-ui
ensure vanta-banking
```

Set `UseTarget false` in the QBCore server configuration to use the E-and-scroll interaction flow. Keep QBCore's `qb-radialmenu` on F1; Vanta's optional add-on radial is on F2.

## Compatibility

Vanta resources use QBCore APIs and can be installed separately. They are designed to work alongside common QBCore resources; do not install two resources that provide the same function under the same resource name.

## Security

- Keep money changes and protected actions on the server.
- Do not commit database credentials or server keys.
- Validate any added client event on the server before changing player state.

## License

The MIT license in this repository applies to Vanta code. QBCore resources are downloaded from their upstream repositories during installation and retain their own licenses. See [LICENSE](LICENSE).
