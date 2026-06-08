# Minecraft Modpack Builder

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![skills.sh](https://skills.sh/b/aknirex/minecraft-modpack-builder)](https://skills.sh/aknirex/minecraft-modpack-builder)

A skill for creating and validating Minecraft Modrinth `.mrpack` modpacks with AI coding agents.

## Install

```powershell
npx skills add aknirex/minecraft-modpack-builder --skill minecraft-modpack
```

That is it. After installation, ask your agent to use `minecraft-modpack` when you want to create, adjust, validate, or package a Minecraft modpack.

## What This Skill Does

`minecraft-modpack` helps an AI agent build reproducible Modrinth modpacks from plain requirements. It guides the agent to:

- choose a compatible Minecraft version and loader
- support Fabric, Forge, NeoForge, and Quilt
- resolve Modrinth project metadata for requested mods
- check required dependencies and loader compatibility
- avoid duplicate feature categories, such as multiple minimaps or recipe viewers
- generate `config.json`, `build.ps1`, and `overrides/`
- package a `.mrpack` for Prism Launcher or the Modrinth App

This repository also includes a working Fabric 1.20.1 Create modpack example under `modpack/`.

## Example Prompts

```text
Use minecraft-modpack to create a Fabric 1.20.1 Create modpack with performance mods, JEI, Jade, JourneyMap, and multiplayer support.
```

```text
Use minecraft-modpack to review this modpack config and tell me which dependencies or loader conflicts need fixing before release.
```

```text
Use minecraft-modpack to add a claims mod and a minimap to my existing Modrinth pack without duplicating features.
```

## Notes

- The bundled build script targets Windows PowerShell 5.1.
- The example pack downloads mods from the Modrinth API and verifies SHA1 hashes.
- Build outputs, downloaded JARs, and `.mrpack` files are intentionally ignored by Git.
- Required dependencies should be explicit in `config.json`; the build fails if Modrinth metadata reports a missing required dependency.
- `server.properties` defaults to `online-mode=true`.

## Example Pack Build

```powershell
.\modpack\build.ps1
```

Include optional mods:

```powershell
.\modpack\build.ps1 -IncludeOptional
```

The generated `.mrpack` is written to `modpack/build/`.

## License

[MIT](LICENSE) © 2025 Aknirex
