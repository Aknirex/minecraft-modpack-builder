# Minecraft Modpack Builder

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 一键安装

```bash
npx skills add Aknirex/minecraft-modpack -g -y
```

An AI skill that guides coding agents through building reproducible Minecraft Modrinth `.mrpack` modpacks, modifying existing packs, and diagnosing runtime issues from crash logs. Supports Fabric, Forge, NeoForge, and Quilt loaders with automatic dependency resolution, compatibility validation, and hash verification.

## What This Skill Does

- Resolves Minecraft version and loader from user requirements
- Queries Modrinth API to find compatible mod versions
- Recursively resolves required/transitive dependencies
- Validates loader conflicts, duplicate features, and side restrictions
- Generates `config.json` + `build.ps1` for reproducible local builds
- Packages everything into a `.mrpack` ready for Prism Launcher or Modrinth App
- Modifies existing modpacks — add/remove mods, shaderpacks, or resource packs
- Diagnoses runtime errors from crash reports, logs, and launcher error messages

## Structure

```text
.
├── SKILL.md                # AI skill definition (entry point for npx skills add)
├── README.md               # This file
├── LICENSE                 # MIT
├── .gitignore
└── skill/agents/           # Agent configuration
```

## License

[MIT](LICENSE) © 2025 Aknirex
