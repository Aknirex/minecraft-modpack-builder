# AGENTS.md — AI Agent Guidelines

## Project Identity

This is a **Minecraft Modrinth modpack builder** that produces `.mrpack` files from a declarative `config.json`. It is also a **Kilo Code AI skill** that guides AI agents through modpack creation workflows.

**Primary use case:** AI agents use this project to generate reproducible Minecraft modpacks with dependency validation, hash verification, and multi-loader support.

## Repository Layout

```
skill/SKILL.md           # AI skill definition — the contract agents follow
skill/agents/openai.yaml  # Agent interface config (display name, invocation policy)
modpack/config.json       # Current modpack: Create+Fabric 1.20.1, 20 mods
modpack/build.ps1         # PowerShell 5.1 build script (download → verify → package)
modpack/overrides/        # Pack-owned files (configs, server.properties, README.md)
```

## Core Conventions

### Skill Development

- `skill/SKILL.md` is the **single source of truth** for how AI agents build modpacks
- The skill defines a 7-step workflow: analyze → select version → select loader → resolve deps → validate → preflight → generate
- All loader decisions must be data-driven; never hardcode a default loader
- Mods are declared with `slug`, `platform: "modrinth"`, `side` (both/client/server), and optional `note`

### Build Script (PowerShell 5.1)

- Must remain **PowerShell 5.1 compatible** — no PowerShell 7-only syntax
- Loader is detected from `config.json` `dependencies` keys: `fabric-loader`, `quilt-loader`, `forge`, `neoforge`
- If no loader key is found, the script MUST fail with `exit 1` — never silently default
- Modrinth API resolution: try loader+version first, fall back to version-only, never silently relax both
- Dependency check (step 3.5) resolves `project_id → slug` via Modrinth project API and validates against known slugs

### File Rules

- `.mrpack`, `.zip`, `build/`, `mods-cache/` → `.gitignore` (never commit build artifacts)
- `.kilocode/`, `.kilo/`, `.docs/` → `.gitignore` (tool-local, not for public repo)
- Downloadable mod JARs → NEVER in `overrides/` (they go in `.mrpack` `files` array with remote URLs)
- `server.properties` → `online-mode` must default to `true`

## Modpack Design Principles

1. **Stability over novelty** — prefer stable mod versions, avoid alphas/snapshots
2. **One mod per feature** — deduplicate: one recipe viewer, one minimap, one claims mod
3. **Required deps must be explicit** — transitive dependencies go in `config.json` mods list
4. **Client/server sides** — mark client-only mods (`side: "client"`) so server env is `unsupported`
5. **No auth bypass** — never recommend or default `online-mode=false`

## Testing & Validation

```powershell
# Cached build: reuse existing downloads and fail if any cache file is missing
.\modpack\build.ps1 -SkipDownload

# Full build with optional mods
.\modpack\build.ps1 -IncludeOptional

# Custom pack name
.\modpack\build.ps1 -PackName "test-pack"
```

Verify the output:
- `modpack/build/*.mrpack` exists
- SHA1 hashes match Modrinth metadata
- `modrinth.index.json` structure is valid

## Common Pitfalls

| Issue | Fix |
|-------|-----|
| `$loader` hardcoded to `forge` | Removed — now reads from config or fails |
| Dependency check `break` in inner loop | Fixed — now resolves `project_id→slug` via API |
| BOM in file output from PowerShell | Use `-Encoding UTF8` (not `UTF8BOM`) |
| `echo.` in PowerShell | Use `Write-Output ""` or `""` alone |
| `&&` chaining in PowerShell | Use `;` separator |

## When AI Agents Should Act

This project is triggered when a user asks to:
- Create a Minecraft modpack (any loader)
- Add/remove mods from an existing pack
- Validate mod compatibility
- Generate `.mrpack` or `config.json`
- Set up a server with specific mods

The skill at `skill/SKILL.md` defines the full execution contract.
