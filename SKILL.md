---
name: minecraft-modpack
description: "Create, validate, modify, and diagnose reproducible Minecraft Modrinth (.mrpack) modpacks. Use when Codex needs to choose Minecraft versions/loaders, resolve Modrinth mods and transitive dependencies, avoid incompatible frameworks or duplicate feature mods, generate locked config.json/build.ps1/overrides, or prepare Fabric, Forge, NeoForge, or Quilt packs for release."
---

# Minecraft Modpack Builder

Build reproducible Minecraft modpacks in Modrinth `.mrpack` format from user goals. Prefer current metadata over memory: resolve every mod, loader, dependency, side flag, and downloadable file from authoritative sources before generating pack files.

This skill targets Modrinth `.mrpack` packs. Handle single-mod install help, launcher troubleshooting, CurseForge-only packs, or server-only deployment directly when that is what the user asked for.

---

## Source of Truth

Use live metadata whenever network access is available:

- **Mods, versions, dependencies, files, hashes, side support:** Modrinth API, especially project/version endpoints.
- **Fabric loader versions:** Fabric Meta API (`https://meta.fabricmc.net/`).
- **Quilt loader versions:** Quilt Meta API (`https://meta.quiltmc.org/`).
- **Forge loader versions:** official Forge Maven metadata (`https://maven.minecraftforge.net/`).
- **NeoForge loader versions:** official NeoForge Maven metadata (`https://maven.neoforged.net/`).
- **Pack format rules:** Modrinth `.mrpack` format documentation.

Do not hardcode framework rules such as "Mod X always needs Mod Y." Dependencies change by version. Use each selected version's dependency metadata and runtime logs.

---

## Creation Workflow

### 1. Capture intent

Extract:

- Pack name, author, target audience, gameplay theme, required mods, optional mods, excluded mods, language/region needs, multiplayer/server target, performance goals, shaders/resource packs, and release constraints.
- User-specified Minecraft version and loader, if any.
- Whether the result must be client-only, server-compatible, or include both client and server layers.

Ask only for missing product intent that cannot be derived. Do not ask for facts that can be resolved from metadata.

### 2. Select Minecraft version

- Use the user's explicit version when provided.
- Otherwise, query compatible versions for all required mods and choose the newest stable Minecraft release supported by the full required set.
- Prefer versions with strong ecosystem support over a newer version with sparse compatibility.
- Avoid snapshots, experimental builds, alpha mod versions, and unsupported game versions unless explicitly requested.

### 3. Select one loader

- Use the user's explicit loader when provided and compatible.
- Otherwise, choose the single loader that satisfies all required mods and dependencies.
- Supported loader dependency keys in `modrinth.index.json` are `fabric-loader`, `quilt-loader`, `forge`, and `neoforge`.
- Never mix loaders in one pack. Stop and ask for a tradeoff if no loader can satisfy the required set.
- Resolve the loader version from official loader metadata, not from memory or an old example.

### 4. Resolve mods and dependency closure

For every requested Modrinth project:

- Query project versions filtered by selected Minecraft version and loader.
- Prefer `release`, then `beta` when needed; use `alpha` only when the user accepted experimental content.
- Select a concrete version and record its Modrinth version ID.
- Inspect that version's `dependencies` array.
- Recursively include every `dependency_type: "required"` dependency.
- Report `dependency_type: "optional"` dependencies separately; include only when requested or needed for a chosen optional feature.
- Treat `dependency_type: "incompatible"` as a blocking conflict unless the incompatible project is absent.
- Treat `dependency_type: "embedded"` as already bundled by the parent version; do not add a duplicate standalone mod unless metadata or logs prove it is needed.
- Select the primary downloadable file. If no primary file exists, use the first file only after recording a warning.

The generated `config.json` must be locked: each included mod should have `modrinthProjectId`, `versionId`, `lockedFileSha1`, `source`, `side`, `category`, and `reason` where metadata is available. Slug remains acceptable as a human-friendly identifier, but the build script must not choose a newer version at build time.

### 5. Validate compatibility

Run preflight before writing final pack files:

- Exactly one loader key is present, plus `minecraft`.
- Every selected mod version supports the selected Minecraft version and loader.
- Every required transitive dependency is present once.
- No selected version declares an `incompatible` dependency on another selected project.
- Every selected file has HTTPS downloads, SHA1, SHA512 when available, file size, and a safe `mods/*.jar` path.
- Side declarations are valid: `client`, `server`, or `both`.
- The resulting `.mrpack` env values are only `required`, `optional`, or `unsupported`.
- Overrides and manifest paths are relative, do not contain `..`, do not start with `/`, `\`, or a Windows drive, and do not escape the instance directory.
- Downloadable mod jars are never placed in `overrides/`.

If preflight fails, fix the resolved set and re-run. Do not silently remove user-requested mods; explain the conflict and offer concrete alternatives.

### 6. Check feature duplication

Select one primary mod per overlapping feature unless the user explicitly accepts overlap:

- Recipe viewer: JEI, EMI, or REI.
- Minimap/world map: JourneyMap or Xaero-style map families.
- Tooltip overlay: Jade, WTHIT, or equivalent.
- Inventory management: Inventory Profiles Next or equivalent.
- Claims/teams: Open Parties and Claims, FTB Chunks, or equivalent.
- Voice/chat/social: Simple Voice Chat, Plasmo Voice, chat overhauls, proximity chat alternatives.
- Performance/rendering: distinguish renderer, entity culling, memory, network, and server tick optimizers; allow complementary stacks but verify declared incompatibilities.
- Framework/library: include only because dependency metadata requires it, not because it is commonly seen in packs.
- Shader/resource pack: avoid bundling multiple default shader packs or incompatible visual defaults unless intentionally offered as optional choices.

### 7. Generate pack files

Create:

- `modpack/config.json` from the locked config shape.
- `modpack/build.ps1` from `templates/build.ps1.template`.
- `modpack/overrides/` only for pack-owned configs, options, datapacks, resource packs, shader packs, documentation, and client defaults.
- `modpack/server-overrides/` for server-only config that should be applied after normal overrides.

The build script packages a ZIP layout with `modrinth.index.json` at the root and optional `overrides/` and `server-overrides/`, then renames it to `.mrpack`. It must fail fast when locked metadata is missing or invalid.

### 8. Deliver output

When generating a modpack, include:

1. Pack summary and pack version ID
2. Minecraft version
3. Loader and loader version with metadata source
4. Resolved mod list with required/optional flags
5. Transitive dependencies and embedded dependencies
6. Compatibility notes, accepted duplicate features, and warnings
7. Generated file paths
8. Exact build command
9. Import instructions for Modrinth App, Prism Launcher, MultiMC, or ATLauncher

Tell users that launchers download the mod jars from `modrinth.index.json`; the `.mrpack` itself should contain manifest and overrides only.

---

## Locked `config.json` Shape

Use this shape for generated packs:

```json
{
  "formatVersion": 1,
  "game": "minecraft",
  "versionId": "1.0.0",
  "name": "Example Pack",
  "author": "UserName",
  "summary": "Short user-facing summary.",
  "dependencies": {
    "minecraft": "1.20.1",
    "fabric-loader": "0.17.2"
  },
  "metadata": {
    "loaderMetadataSource": "https://meta.fabricmc.net/v2/versions/loader/1.20.1",
    "resolvedAt": "2026-06-09",
    "notes": []
  },
  "mods": [
    {
      "name": "Sodium",
      "slug": "sodium",
      "modrinthProjectId": "AANobbMI",
      "versionId": "exampleVersionId",
      "lockedFileSha1": "exampleSha1",
      "platform": "modrinth",
      "source": "modrinth",
      "side": "client",
      "optional": false,
      "category": "performance/rendering",
      "reason": "Rendering optimization requested by the user",
      "note": "Resolved from Modrinth version metadata"
    }
  ]
}
```

Rules:

- Top-level `versionId` is the pack version identifier used by `.mrpack`; Minecraft version belongs in `dependencies.minecraft`.
- `author` must be present. Use the user's preferred author, then the system username, then `"AI Generated"`.
- Default filesystem names should be ASCII, lowercase, and hyphenated. User-facing pack names may use UTF-8 when requested.
- Each mod entry should be locked with a Modrinth `versionId` and `lockedFileSha1` before build.

---

## Modpack Modification Workflow

Use this workflow when the user wants to change an existing pack.

### 1. Read the current pack

Locate and read `modpack/config.json`. Understand the pack version, Minecraft version, loader, selected mods, optional mods, categories, and dependency notes.

### 2. Plan the change

For adding mods:

- Query Modrinth compatibility for the existing Minecraft version and loader.
- Resolve required dependencies recursively.
- Check `optional`, `incompatible`, and `embedded` dependency records.
- Check duplicate feature categories against the current pack.
- Ask only when the user must choose between incompatible goals.

For removing mods:

- Check whether any remaining selected mod depends on the removed project.
- Refuse to remove required dependencies unless also removing dependents or replacing them.

For shaders/resource packs:

- Put pack-owned files in `modpack/overrides/shaderpacks/` or `modpack/overrides/resourcepacks/`.
- If publishing through Modrinth project files instead, represent them in `modrinth.index.json` with correct env and file type rather than as downloaded jars.

### 3. Apply and rebuild

- Update the locked `config.json`.
- Update overrides or `server-overrides` only for pack-owned files.
- Rebuild with:

```powershell
.\modpack\build.ps1
```

### 4. Deliver to user

Always tell the user:

> The `.mrpack` has been updated. Re-import it in your launcher. If using HMCL/Prism, delete the old instance first or use the launcher's update feature. Test and report any issues.

---

## Runtime Diagnosis Workflow

When the user reports a runtime error, crash, black/purple textures, incompatible mods warning, or failed launch, ask for evidence before changing files:

- `crash-reports/*.txt` or `logs/latest.log`
- Launcher error messages from HMCL, Prism, Modrinth App, MultiMC, or ATLauncher
- Screenshots for visual issues
- The current `modpack/config.json`

Diagnose from evidence:

- Parse stack traces and loader "incompatible mod set" output.
- Match failing mod IDs against the resolved config.
- Identify missing dependencies, wrong loader version, wrong Minecraft version, side-only mods on the wrong target, duplicate libraries, or declared incompatibilities.
- Update locked config by adding/updating/removing the specific resolved project versions.
- Rebuild the `.mrpack`.
- Tell the user to re-import the updated `.mrpack` and test again.

Do not add static compatibility folklore to this skill based on one crash. Keep fixes in the pack config and use logs for future diagnosis.

---

## Build Script Contract

The build script generated from `templates/build.ps1.template`:

- Must remain PowerShell 5.1 compatible.
- Reads UTF-8 `config.json`.
- Uses `dependencies.minecraft` as the Minecraft version.
- Requires exactly one loader key among `fabric-loader`, `quilt-loader`, `forge`, and `neoforge`.
- Requires each mod to have a locked Modrinth version ID before packaging.
- Validates selected version metadata instead of choosing "latest."
- Fails on missing required metadata, side errors, loader/game mismatch, unsafe paths, missing hashes, or missing downloads.
- Copies `overrides/` and `server-overrides/` when present.
- Writes `modrinth.index.json` at ZIP root.
- Writes a build report describing resolved mods, skipped optional mods, warnings, and metadata sources.

---

## Design Principles

- Prioritize compatibility, stability, reproducibility, and maintainability.
- Keep each mod's purpose clear.
- Prefer smaller coherent packs over large random mod lists.
- Keep loader and framework selection data-driven.
- Do not promote bypassing Minecraft account authentication.
- Do not default `server.properties` to `online-mode=false`.
- Do not bundle downloadable mod jars in `overrides/`.
- Do not skip preflight or hash metadata checks.

---

## Never Do

- Mix incompatible loaders.
- Ignore required or transitive dependencies.
- Silently relax Minecraft version or loader filters.
- Include outdated hardcoded loader/framework versions.
- Generate a pack from unresolved slugs only.
- Treat optional dependencies as required without saying why.
- Ignore Modrinth `incompatible` dependency records.
- Put mod jars in `overrides/`.
- Use unsafe manifest or override paths.
- Build before preflight passes.
- Fix runtime errors without crash logs or launcher evidence.
