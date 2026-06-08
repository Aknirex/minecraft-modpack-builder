# Minecraft Modpack Builder

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **🤖 If you are an AI coding agent:** start by reading [AGENTS.md](AGENTS.md) for project conventions and constraints, then see [SKILL.md](SKILL.md) for the modpack-building workflow.

An AI skill that guides coding agents through building reproducible Minecraft Modrinth `.mrpack` modpacks. Supports Fabric, Forge, NeoForge, and Quilt loaders with automatic dependency resolution, compatibility validation, and hash verification.

## ✨ What This Skill Does

- Resolves Minecraft version and loader from user requirements
- Queries Modrinth API to find compatible mod versions
- Recursively resolves required/transitive dependencies
- Validates loader conflicts, duplicate features, and side restrictions
- Generates `config.json` + `build.ps1` for reproducible local builds
- Packages everything into a `.mrpack` ready for Prism Launcher or Modrinth App

## 🚀 Install

```bash
npx skills add Aknirex/minecraft-modpack-builder -g -y
```

## 📁 Structure

```text
.
├── SKILL.md                # AI skill definition (entry point for npx skills add)
├── AGENTS.md               # AI agent conventions and constraints
├── README.md               # This file
├── LICENSE                 # MIT
├── .gitignore
└── skill/agents/           # Agent configuration
```

## 📄 License

[MIT](LICENSE) © 2025 Aknirex
