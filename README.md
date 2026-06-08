# Minecraft Modpack Builder

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **🤖 If you are an AI coding agent:** start by reading [AGENTS.md](AGENTS.md) for project conventions and constraints, then see [SKILL.md](SKILL.md) for the modpack-building workflow. The current modpack is defined in [modpack/config.json](modpack/config.json).

A declarative Minecraft modpack builder for the Modrinth `.mrpack` format. Define your modpack in `config.json`, then run a single PowerShell script to download, verify, and package everything into a reproducible `.mrpack` file.

## ✨ Features

- **Declarative config** — Define mods in `modpack/config.json`; no manual downloading
- **Dependency validation** — Checks Modrinth metadata and fails the build when required dependencies are missing
- **SHA1 hash verification** — Ensures file integrity after download
- **Multi-loader support** — Fabric, Forge, NeoForge, and Quilt
- **Optional mods** — Mark mods as `optional: true` to skip by default, toggle with `-IncludeOptional`
- **One-command packaging** — Produces a `.mrpack` ready for Prism Launcher or Modrinth App

## 📦 Current Modpack

| Property | Value |
|----------|-------|
| **Name** | Create Modpack (Fabric) |
| **Minecraft** | 1.20.1 |
| **Loader** | Fabric 0.17.2 |
| **Core mod** | Create (机械动力) |
| **Total mods** | 22 (including optional) |

### Mod List

| Category | Mods |
|----------|------|
| Framework | Fabric API, Fabric Language Kotlin, Forge Config API Port, libIPN |
| Core | Create (Fabric), Create: Steam 'n' Rails (optional) |
| Multiplayer | e4mc |
| Claims | Open Parties and Claims |
| Map | JourneyMap |
| Utility | JEI, Jade, AppleSkin, Mouse Tweaks, Clumps, Controlling, Searchables, Just Enough Resources, Inventory Profiles Next |
| Performance | Sodium, Lithium, FerriteCore, ModernFix |

## 🚀 Quick Start

### Prerequisites

- Windows (build script targets PowerShell 5.1)
- Internet connection (Modrinth API access required)

### Build

```powershell
# Basic build (skips optional mods)
.\modpack\build.ps1

# Include optional mods
.\modpack\build.ps1 -IncludeOptional

# Custom output name
.\modpack\build.ps1 -PackName "my-custom-pack"
```

The `.mrpack` output goes to `modpack/build/`.

### Install the Modpack

1. Download and install [Prism Launcher](https://prismlauncher.org/) or [Modrinth App](https://modrinth.com/app)
2. Drag the `.mrpack` file into the launcher window
3. The launcher will automatically install Minecraft, the loader, and all mods

## 📁 Project Structure

```text
.
├── LICENSE                 # MIT license
├── SKILL.md                # AI skill definition (entry point for npx skills add)
├── .gitignore
├── modpack/
│   ├── config.json         # Modpack definition (mods, version, loader)
│   ├── build.ps1           # Build script (PowerShell 5.1)
│   └── overrides/          # Override files
│       ├── config/         # Mod configs
│       ├── server.properties
│       └── README.md       # User guide (Chinese)
└── skill/agents/           # Agent configuration
```

## 🛠 Custom Modpack

Edit `modpack/config.json`:

```json
{
  "formatVersion": 1,
  "game": "minecraft",
  "versionId": "1.20.1",
  "name": "My Modpack",
  "summary": "A short description of the pack.",
  "dependencies": {
    "minecraft": "1.20.1",
    "fabric-loader": "0.17.2"
  },
  "mods": [
    {
      "name": "Fabric API",
      "slug": "fabric-api",
      "platform": "modrinth",
      "side": "both",
      "note": "Required framework dependency"
    }
  ]
}
```

### Loader Keys

| Dependency Key | Loader |
|---------------|--------|
| `fabric-loader` | Fabric |
| `quilt-loader` | Quilt |
| `forge` | Forge |
| `neoforge` | NeoForge |

## 📄 License

[MIT](LICENSE) © 2025 Aknirex
