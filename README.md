# Minecraft Modpack Builder

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An AI skill for designing, validating, and packaging reproducible Minecraft Modrinth `.mrpack` modpacks. It is meant for agents that need to choose a stable Minecraft version and loader, resolve Modrinth projects, include required dependency closures, avoid incompatible or duplicate mods, and produce a lightweight pack that launchers can import.

## Installation

```bash
npx skills add Aknirex/minecraft-modpack -y
```

## What It Does

- Builds Modrinth `.mrpack` packs for Fabric, Forge, NeoForge, and Quilt
- Resolves mods from live Modrinth metadata instead of remembered compatibility rules
- Recursively includes required dependencies and records optional, embedded, and incompatible dependencies
- Validates Minecraft version, loader, side support, hashes, downloads, and safe paths before packaging
- Produces a locked `config.json` plus a PowerShell 5.1 compatible `build.ps1`
- Packages only `modrinth.index.json`, `overrides/`, and `server-overrides/`; mod jars are downloaded by the launcher
- Supports pack modification workflows for adding/removing mods, shaders, resource packs, and config overrides
- Diagnoses runtime issues from crash reports, latest logs, and launcher error dialogs

## Boundaries

This skill targets Modrinth `.mrpack` output. It does not generate CurseForge manifests by default, does not bundle downloaded mod jars, and does not maintain static mod-specific compatibility tables. Loader and framework choices should come from live metadata and pack logs.

## Good Input To Give The Agent

```text
Create a stable client+server exploration pack.
Minecraft version: choose the newest stable version supported by the required mods.
Loader: choose the best compatible loader.
Required: Terralith, Simple Voice Chat, Jade, Sodium-like performance if compatible.
Optional: shader support and a minimap.
Avoid: alpha versions and duplicate recipe viewers.
Author: ExampleUser.
```

For troubleshooting, provide:

- `crash-reports/*.txt` or `logs/latest.log`
- The launcher's error dialog text
- Screenshots for visual issues
- The current `modpack/config.json`

## Generated Pack Structure

```text
modpack/
|-- config.json
|-- build.ps1
|-- overrides/
|   |-- config/
|   |-- resourcepacks/
|   `-- shaderpacks/
|-- server-overrides/
|   `-- config/
`-- build/
    |-- build-tmp/
    |   `-- modrinth.index.json
    |-- build-report.json
    `-- modpack.mrpack
```

The `.mrpack` contains `modrinth.index.json` at the archive root. Launchers such as Modrinth App, Prism Launcher, MultiMC, and ATLauncher use that manifest to download the referenced mod files.

## Repository Structure

```text
.
|-- SKILL.md
|-- README.md
|-- LICENSE
|-- skill/agents/
`-- templates/
    |-- build.ps1.template
    `-- config.json
```

## License

[MIT](LICENSE) © 2025 Aknirex
