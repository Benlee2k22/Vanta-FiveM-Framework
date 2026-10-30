# Vanta QBCore

A clean QBCore server setup with Vanta's custom interaction UI and loading screen. QBCore provides the framework and standard gameplay resources; Vanta adds the interface layer.

## Included

The txAdmin recipe starts from the [QBCore txAdmin recipe](https://github.com/qbcore-fivem/txAdminRecipe/blob/main/qbcore.yaml). Editable source copies for qb-core, qb-target, qb-radialmenu, qb-multicharacter, qb-spawn, qb-menu and qb-input are stored under `resources/[qb]` in this repository; the installer replaces those upstream copies with these files. Other QBCore resources still download from the upstream recipe until we add editable copies.

This repository adds:

- `vanta-ui`: bottom-left nearby prompt; press **E** or **Enter** to open, scroll to select, and press **E** or **Enter** to confirm. It also provides theme settings, notifications, progress UI and optional Vanta radial actions on **F2**.
- `vanta-loading`: branded connection screen, progress, tips and optional synthesized ambient music.

QBCore's radial remains on **F1**. The recipe sets `UseTarget false` so QBCore uses its key-based interaction paths and the target eye is not shown. The Vanta menu currently handles actions registered through `exports['vanta-ui']:AddInteraction`; adapting every stock QBCore interaction to this menu is the next integration stage.

## Install

In txAdmin, open **Recipe Deployer**, choose the remote recipe option, and paste:

`https://raw.githubusercontent.com/Benlee2k22/Vanta-FiveM-Framework/main/recipe.yaml`

Enter your Cfx server key and reachable MySQL/MariaDB connection details. Use a fresh test profile and database for the first installation.

The recipe installs the QBCore resources directly from their upstream recipe and then adds the Vanta UI resources from this repository. It does not install a separate Vanta core or QBCore compatibility shim.

## Manual install

1. Install the QBCore resources and dependencies using the upstream recipe.
2. Copy `vanta-ui` and `vanta-loading` into your resources directory.
3. Set `setr UseTarget false` in `server.cfg`.
4. Ensure resources after QBCore:

```cfg
ensure vanta-loading
ensure vanta-ui
```

5. Keep QBCore's `qb-radialmenu` on F1. Vanta's optional radial key is F2.

See [docs/systems.md](docs/systems.md) and [docs/test-checklist.md](docs/test-checklist.md).

## License

The MIT license here applies to Vanta files. QBCore resources are fetched from their upstream repositories and keep their own licenses.
