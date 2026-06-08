---
name: minecraft-modpack
description: "Create and validate Minecraft Modrinth (.mrpack) modpacks from user requirements. Use when Codex needs to choose a Minecraft version and loader, resolve Modrinth mods and dependencies, avoid incompatible or duplicate mods, generate config.json/build scripts/overrides, or prepare a reproducible Fabric, Forge, NeoForge, or Quilt modpack for release."
---

# Minecraft Modpack Builder

Build reproducible Minecraft modpacks in Modrinth `.mrpack` format from user goals.

---

## Execution Workflow

1. **Analyze requirements**
   - Extract Minecraft version, loader preference, required mods, optional mods, gameplay goals, performance goals, multiplayer needs, client/server target, language/region preferences, and release constraints.
   - If the user asks for a single mod install, launcher troubleshooting, a CurseForge-only pack, or a server-only deployment, handle that task directly instead of generating a `.mrpack`.

2. **Select Minecraft version**
   - Use the user-specified version if provided.
   - Otherwise, query current Modrinth metadata for all required mods and choose the newest stable Minecraft version supported by the full required set.
   - Avoid snapshots, experimental Minecraft builds, and mod versions marked alpha unless the user explicitly requests them.

3. **Select loader**
   - Use the user-specified loader if provided.
   - Otherwise, choose the loader that satisfies all required mods and framework dependencies.
   - Support Fabric, Forge, NeoForge, and Quilt. Do not hardcode one default loader.
   - Stop and ask the user if no loader satisfies all required mods.

4. **Resolve mods and dependencies**
   - Query the Modrinth API for each requested project.
   - Filter versions by selected Minecraft version and loader.
   - Inspect each selected version's `dependencies` array.
   - Recursively include every `dependency_type: "required"` dependency.
   - Include framework mods only when required by the resolved mod list, such as Fabric API, Fabric Language Kotlin, Quilt libraries, Architectury API, Cloth Config, or Forge/NeoForge library mods.
   - Treat optional/user-nice-to-have mods separately and include them only when the user asks for optional content.
   - Print the complete resolved list before final packaging when the request is exploratory or high impact.

5. **Validate compatibility**
   - Verify each selected mod version supports the chosen Minecraft version and loader.
   - Detect dependency conflicts, missing required dependencies, incompatible loaders, and unsupported client/server side declarations.
   - Detect duplicate feature categories before packaging.
   - Prefer coherent, stable packs over large random mod collections.

6. **Run preflight before generating output**
   - Confirm the loader version from current loader metadata or official release data.
   - Confirm every required and transitive dependency is present.
   - Confirm no loader conflicts remain.
   - Confirm no duplicate feature category remains unless the user explicitly accepts it.
   - Confirm no downloadable mod jar is placed in `overrides/`.
   - Fix failures and re-run validation before building.

7. **Generate build files**
   - Generate `modpack/config.json`.
   - Generate `modpack/build.ps1` for Windows users, keeping PowerShell 5.1 compatibility.
   - Generate `modpack/overrides/` only for configs, datapacks, resource packs, shader packs, server defaults, and documentation.
   - Build a temporary zip layout with `modrinth.index.json` and `overrides/`, then rename the archive to `.mrpack`.
   - Verify local SHA1 hashes against Modrinth metadata.

---

## Output Requirements

- `modpack/config.json`
- `modpack/build.ps1` for reproducible local builds
- `modpack/overrides/` for pack-owned files only
- Build instructions, resolved mod list, dependency notes, compatibility notes, and generated file paths

Use this `config.json` shape:

```json
{
  "formatVersion": 1,
  "game": "minecraft",
  "versionId": "1.20.1",
  "name": "Example Pack",
  "summary": "Short user-facing summary.",
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
      "optional": false,
      "note": "Required framework dependency"
    }
  ]
}
```

Default filesystem names should be ASCII, lowercase, and hyphenated. User-facing pack names may use UTF-8 when requested.

---

## PowerShell 5.1 Compatibility Notes

- Use `-Encoding UTF8` for text file reads and writes.
- Avoid PowerShell 7-only syntax and APIs.
- Compress as `.zip`, then rename to `.mrpack`.
- Detect loader from exact dependency keys such as `fabric-loader`, `quilt-loader`, `forge`, or `neoforge`.
- Set `$ErrorActionPreference = "Stop"` and fail the build when a required mod cannot be resolved.

---

## API Resolution Strategy

Use conservative fallback order:

1. Query by loader and Minecraft version.
2. If no result exists, query by Minecraft version only to diagnose whether the loader is the issue.
3. Stop and ask the user or choose a different mod. Never silently relax both loader and Minecraft version constraints.

---

## Feature Deduplication

Select one primary mod per category unless the user explicitly requests overlap:

- Recipe viewer: JEI, EMI, or REI
- Minimap/world map: JourneyMap or Xaero's map family
- Tooltip overlay: Jade or WTHIT
- Inventory management: Inventory Profiles Next or similar
- Claims/teams: Open Parties and Claims, FTB Chunks, or similar
- Optimization: allow complementary combinations, but check incompatibilities among renderer, memory, and server-tick optimizers

---

## Output Format

When generating a modpack, include:

1. Summary and Minecraft version
2. Loader and loader version
3. Resolved mod list with optional mods flagged
4. Transitive dependency list
5. Compatibility notes and any accepted duplicate features
6. Generated file paths
7. Exact build command to run

---

## Modpack Structure

```text
modpack/
|-- config.json
|-- build.ps1
|-- overrides/
|   |-- config/
|   |-- resourcepacks/
|   |-- shaderpacks/
|   |-- server.properties
|   `-- README.md
`-- build/
```

---

## Design Principles

- Prioritize compatibility, stability, reproducibility, and maintainability.
- Keep each mod's purpose clear.
- Avoid unsupported dependencies, unreviewed experimental versions, and excessive mod counts.
- Do not promote bypassing Minecraft account authentication as a default pack feature.
- Keep loader and framework selection data-driven from mod requirements.

---

## Never Do

- Mix incompatible loaders.
- Ignore required or transitive dependencies.
- Include outdated or hardcoded loader/framework versions when current metadata is available.
- Bundle downloadable mod jars in `overrides/`.
- Skip hash verification.
- Build before preflight passes.
- Recommend large mod lists without reviewing interactions.
- Default `server.properties` to `online-mode=false`.
