# Minecraft Modpack Builder

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Installation

```bash
npx skills add Aknirex/minecraft-modpack -g -y
```

An AI skill that guides coding agents through building reproducible Minecraft Modrinth `.mrpack` modpacks, modifying existing packs, and diagnosing runtime issues from crash logs. Supports Fabric, Forge, NeoForge, and Quilt loaders with automatic dependency resolution and compatibility validation. All mod downloading is delegated to the launcher via `modrinth.index.json` — no `.jar` files are bundled, keeping the `.mrpack` lightweight (~3 KB).

## What This Skill Does

- Resolves Minecraft version and loader from user requirements
- Queries Modrinth API to find compatible mod versions
- Recursively resolves required/transitive dependencies
- Validates loader conflicts, duplicate features, and side restrictions
- Generates `config.json` + download-free `build.ps1` for reproducible local builds (AI generates the script based on `templates/build.ps1.template`)
- Packages a lightweight `.mrpack` (manifest + overrides only) — the launcher handles all mod downloads
- Modifies existing modpacks — add/remove mods, shaderpacks, or resource packs
- Diagnoses runtime errors from crash reports, logs, and launcher error messages

## Structure

```text
.
├── SKILL.md                # AI skill definition (entry point for npx skills add)
├── README.md               # This file
├── LICENSE                 # MIT
├── .gitignore
├── skill/agents/           # Agent configuration
└── templates/              # build.ps1.template and config.json templates
```

## License

[MIT](LICENSE) © 2025 Aknirex
