# =============================================================================
# Minecraft Modpack Builder (Download-Free)
# Queries Modrinth API for mod metadata ONLY - zero .jar downloads.
# The launcher handles all mod downloading from index.json URLs.
# Usage: .\build.ps1 [-IncludeOptional]
# =============================================================================

param(
    [string]$ConfigPath = "",
    [string]$OutputDir = "",
    [string]$PackName = "modpack",
    [switch]$IncludeOptional
)

if ($ConfigPath -eq "") {
    $ConfigPath = Join-Path $PSScriptRoot "config.json"
}
if ($OutputDir -eq "") {
    $OutputDir = Join-Path $PSScriptRoot "build"
}

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ---- [1/5] Read config ----
Write-Host "[1/5] Reading config..." -ForegroundColor Cyan
$configContent = Get-Content $ConfigPath -Raw -Encoding UTF8
$config = $configContent | ConvertFrom-Json

$mcVersion = $config.versionId

# Detect loader from dependencies keys
$loader = "forge"
$loaderVersion = "47.3.0"
if ($config.dependencies -ne $null) {
    $depProps = $config.dependencies.PSObject.Properties
    foreach ($prop in $depProps) {
        $name = $prop.Name
        if ($name -eq "forge" -or $name -eq "neoforge") {
            $loader = $name
            $loaderVersion = $prop.Value
            break
        }
        if ($name -eq "fabric-loader" -or $name -eq "fabric") {
            $loader = "fabric"
            $loaderVersion = $prop.Value
            break
        }
        if ($name -eq "quilt-loader" -or $name -eq "quilt") {
            $loader = "quilt"
            $loaderVersion = $prop.Value
            break
        }
    }
}

Write-Host ("  Minecraft: " + $mcVersion)
Write-Host ("  Loader: " + $loader + " " + $loaderVersion)
Write-Host ("  Mods in config: " + $config.mods.Count)

# ---- [2/5] Query Modrinth API (metadata only, no downloads) ----
Write-Host ""
Write-Host "[2/5] Querying Modrinth API for mod metadata..." -ForegroundColor Cyan

$fileEntries = @()
$apiBase = "https://api.modrinth.com/v2"

foreach ($mod in $config.mods) {
    $isOptional = $false
    if ($mod.optional -eq $true) {
        $isOptional = $true
    }
    if ($isOptional -and (-not $IncludeOptional)) {
        Write-Host ("  Skipping optional: " + $mod.name) -ForegroundColor DarkYellow
        continue
    }

    $slug = $mod.slug
    Write-Host ("  Processing: " + $mod.name + " (" + $slug + ")") -ForegroundColor Yellow

    $failed = $false
    $versions = $null

    # Build query URL
    $encodedLoader = [System.Web.HttpUtility]::UrlEncode('["' + $loader + '"]')
    $encodedMc = [System.Web.HttpUtility]::UrlEncode('["' + $mcVersion + '"]')
    $queryUrl = $apiBase + "/project/" + $slug + "/version?loaders=" + $encodedLoader + "&game_versions=" + $encodedMc

    Write-Host ("    API: " + $queryUrl) -ForegroundColor DarkGray

    try {
        $versions = Invoke-RestMethod -Uri $queryUrl -ContentType "application/json" -ErrorAction Stop
    }
    catch {
        Write-Host ("    API call failed: " + $_.Exception.Message) -ForegroundColor Red
        $failed = $true
    }

    # Fallback: retry without loader filter
    if ((-not $failed) -and ($versions.Count -eq 0)) {
        Write-Host ("    No versions for " + $loader + " " + $mcVersion + ", retrying without loader filter...") -ForegroundColor DarkYellow
        $queryUrl2 = $apiBase + "/project/" + $slug + "/version?game_versions=" + $encodedMc
        try {
            $versions = Invoke-RestMethod -Uri $queryUrl2 -ContentType "application/json" -ErrorAction Stop
        }
        catch {
            Write-Host ("    Retry API call failed: " + $_.Exception.Message) -ForegroundColor Red
            $failed = $true
        }
    }

    if ($failed) {
        Write-Host ("    ERROR: API failure for " + $mod.name + ", skipping") -ForegroundColor Red
        continue
    }

    if ($versions.Count -eq 0) {
        Write-Host ("    ERROR: No versions found for " + $mcVersion + ", skipping") -ForegroundColor Red
        continue
    }

    $latest = $versions[0]
    $verNum = $latest.version_number
    $fname = $latest.files[0].filename
    $durl = $latest.files[0].url
    $fsize = $latest.files[0].size
    $sha1 = $latest.files[0].hashes.sha1
    $sha512 = $latest.files[0].hashes.sha512

    $sizeMB = [math]::Round($fsize / 1048576, 2)
    Write-Host ("    Version: " + $verNum + " | File: " + $fname + " | Size: " + $sizeMB + " MB")

    # Build env object from side declaration
    $clientEnv = "required"
    $serverEnv = "required"
    if ($mod.side -eq "client") {
        $serverEnv = "unsupported"
    }
    elseif ($mod.side -eq "server") {
        $clientEnv = "unsupported"
    }

    # Use API metadata directly - no local file download or hash verification
    $entry = @{
        path      = ("mods/" + $fname)
        hashes    = @{ sha1 = $sha1; sha512 = $sha512 }
        env       = @{ client = $clientEnv; server = $serverEnv }
        downloads = @($durl)
        fileSize  = [int64]$fsize
    }

    $fileEntries += $entry

    Write-Host ("    SHA1: " + $sha1) -ForegroundColor DarkGray
}

Write-Host ""
Write-Host ("  Resolved: " + $fileEntries.Count + " mods") -ForegroundColor Green

if ($fileEntries.Count -eq 0) {
    Write-Host "FATAL: No mods resolved, exiting" -ForegroundColor Red
    exit 1
}

# ---- [3/5] Generate modrinth.index.json ----
Write-Host ""
Write-Host "[3/5] Generating modrinth.index.json..." -ForegroundColor Cyan

$depObj = @{}
if ($config.dependencies -ne $null) {
    $depProps = $config.dependencies.PSObject.Properties
    foreach ($prop in $depProps) {
        $depObj[$prop.Name] = $prop.Value
    }
}

$indexObj = @{
    formatVersion = [int]$config.formatVersion
    game          = $config.game
    versionId     = $config.versionId
    name          = $config.name
    summary       = $config.summary
    files         = $fileEntries
    dependencies  = $depObj
}

$buildDir = Join-Path $OutputDir "build-tmp"
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$indexPath = Join-Path $buildDir "modrinth.index.json"
$indexObj | ConvertTo-Json -Depth 10 | Out-File -FilePath $indexPath -Encoding UTF8

Write-Host ("  Generated: " + $indexPath) -ForegroundColor Green

# ---- [4/5] Copy overrides ----
Write-Host ""
Write-Host "[4/5] Copying override files..." -ForegroundColor Cyan

$overridesDir = Join-Path $buildDir "overrides"
New-Item -ItemType Directory -Force -Path $overridesDir | Out-Null

# Override config directory
$sourceOverrideConfig = Join-Path $PSScriptRoot "overrides\config"
if (Test-Path $sourceOverrideConfig) {
    $destConfigDir = Join-Path $overridesDir "config"
    New-Item -ItemType Directory -Force -Path $destConfigDir | Out-Null
    Copy-Item -Path (Join-Path $sourceOverrideConfig "*") -Destination $destConfigDir -Recurse -Force
    Write-Host "  Copied override configs" -ForegroundColor Gray
}
else {
    $configReadme = Join-Path $overridesDir "config\README.txt"
    New-Item -ItemType Directory -Force -Path (Split-Path $configReadme -Parent) | Out-Null
    "# Config directory for this modpack" | Out-File -FilePath $configReadme -Encoding UTF8
}

# Server properties
$sourceServerProps = Join-Path $PSScriptRoot "overrides\server.properties"
if (Test-Path $sourceServerProps) {
    Copy-Item -Path $sourceServerProps -Destination $overridesDir -Force
    Write-Host "  Copied server.properties" -ForegroundColor Gray
}

# Options.txt (game defaults)
$sourceOptions = Join-Path $PSScriptRoot "overrides\options.txt"
if (Test-Path $sourceOptions) {
    Copy-Item -Path $sourceOptions -Destination $overridesDir -Force
    Write-Host "  Copied options.txt" -ForegroundColor Gray
}

# ---- [5/5] Package .mrpack ----
Write-Host ""
Write-Host "[5/5] Packaging .mrpack..." -ForegroundColor Cyan

$packFile = Join-Path $OutputDir ($PackName + ".mrpack")
$packParent = Split-Path $packFile -Parent
New-Item -ItemType Directory -Force -Path $packParent | Out-Null

if (Test-Path $packFile) {
    Remove-Item $packFile -Force
}

# Compress to .zip then rename (PS 5.1 workaround)
Push-Location $buildDir
$tempZip = Join-Path $OutputDir ($PackName + ".zip")
try {
    $compressParams = @{
        Path             = "modrinth.index.json", "overrides"
        DestinationPath  = $tempZip
        CompressionLevel = "Optimal"
        Force            = $true
    }
    Compress-Archive @compressParams
    if (Test-Path $packFile) {
        Remove-Item $packFile -Force
    }
    Move-Item -Path $tempZip -Destination $packFile -Force
    Write-Host ("  Packaged: " + $packFile) -ForegroundColor Green
}
catch {
    Write-Host ("  Packaging failed: " + $_.Exception.Message) -ForegroundColor Red
    if (Test-Path $tempZip) {
        Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
    }
}
Pop-Location

# ---- Report ----
$packSize = (Get-Item $packFile).Length
$packSizeKB = [math]::Round($packSize / 1024, 1)

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Build complete!" -ForegroundColor Green
Write-Host ("  Output: " + $packFile) -ForegroundColor White
Write-Host ("  Size: " + $packSizeKB + " KB") -ForegroundColor White
Write-Host ("  Mods: " + $fileEntries.Count) -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green

Write-Host ""
Write-Host "  Resolved mods:" -ForegroundColor Cyan
$idx = 1
foreach ($mod in $config.mods) {
    $isOptional = $false
    if ($mod.optional -eq $true) { $isOptional = $true }
    if ($isOptional -and (-not $IncludeOptional)) { continue }
    Write-Host ("  " + $idx + ". " + $mod.name)
    $idx = $idx + 1
}

Write-Host ""
Write-Host ("  Temp build dir: " + $buildDir) -ForegroundColor DarkGray
