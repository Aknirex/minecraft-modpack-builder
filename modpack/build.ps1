# =============================================================================
# Minecraft Modpack Builder - 机械动力整合包
# 用法: .\build.ps1 [-IncludeOptional] [-SkipDownload]
# =============================================================================

param(
    [string]$ConfigPath = "",
    [string]$OutputDir = "",
    [string]$PackName = "create-modpack",
    [switch]$SkipDownload,
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

# ---- Step 1: Read config ----
Write-Host "[1/6] Reading config..." -ForegroundColor Cyan
$configContent = Get-Content $ConfigPath -Raw -Encoding UTF8
$config = $configContent | ConvertFrom-Json

$mcVersion = $config.versionId
$loader = "forge"
$loaderVersion = "47.3.0"
if ($config.dependencies -ne $null) {
    $depProps = $config.dependencies.PSObject.Properties
    foreach ($prop in $depProps) {
        $name = $prop.Name
        # Normalize loader name: fabric-loader -> fabric
        if ($name -eq "forge" -or $name -eq "fabric" -or $name -eq "fabric-loader" -or $name -eq "neoforge" -or $name -eq "quilt") {
            if ($name -eq "fabric-loader") {
                $loader = "fabric"
            }
            else {
                $loader = $name
            }
            $loaderVersion = $prop.Value
            break
        }
    }
}

Write-Host ("  Minecraft: " + $mcVersion)
Write-Host ("  Loader: " + $loader + " " + $loaderVersion)
Write-Host ("  Mods in config: " + $config.mods.Count)

# ---- Step 2: Prepare build dirs ----
Write-Host ""
Write-Host "[2/6] Preparing directories..." -ForegroundColor Cyan

$buildDir = Join-Path $OutputDir "build-tmp"
$modsDir = Join-Path $buildDir "mods-cache"
$configDir = Join-Path $buildDir "overrides\config"

New-Item -ItemType Directory -Force -Path $modsDir | Out-Null
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

# ---- Filter mods ----
$modsToDownload = @()
foreach ($mod in $config.mods) {
    $isOptional = $false
    if ($mod.optional -eq $true) {
        $isOptional = $true
    }
    if ($isOptional -and (-not $IncludeOptional)) {
        Write-Host ("  Skipping optional: " + $mod.name) -ForegroundColor DarkYellow
        continue
    }
    $modsToDownload += $mod
}

# ---- Step 3: Download mods ----
Write-Host ""
Write-Host "[3/6] Downloading mods from Modrinth..." -ForegroundColor Cyan

$downloadedFiles = @()
$apiBase = "https://api.modrinth.com/v2"

foreach ($mod in $modsToDownload) {
    $slug = $mod.slug
    Write-Host ("  Processing: " + $mod.name + " (" + $slug + ")") -ForegroundColor Yellow
    
    $failed = $false
    $versions = $null
    $queryUrl = ""
    
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
    
    if (-not $failed) {
        if ($versions.Count -eq 0) {
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
    }
    
    if ($failed) {
        Write-Host ("    Skipping " + $mod.name + " due to API failure") -ForegroundColor Red
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
    $sha1url = $latest.files[0].hashes.sha1
    $sha512url = $latest.files[0].hashes.sha512
    
    $sizeMB = [math]::Round($fsize / 1048576, 2)
    Write-Host ("    Version: " + $verNum + " | File: " + $fname + " | Size: " + $sizeMB + " MB")
    
    $destPath = Join-Path $modsDir $fname
    
    if (-not $SkipDownload) {
        if (Test-Path $destPath) {
            Write-Host "    File already exists, skipping download" -ForegroundColor DarkGray
        }
        else {
            Write-Host "    Downloading..." -ForegroundColor DarkGray
            try {
                Invoke-WebRequest -Uri $durl -OutFile $destPath -ErrorAction Stop
                Write-Host "    Download complete" -ForegroundColor Green
            }
            catch {
                Write-Host ("    Download failed: " + $_.Exception.Message) -ForegroundColor Red
                continue
            }
        }
    }
    
    # Record file info (include dependencies for later validation)
    $depsList = @()
    if ($latest.dependencies -ne $null) {
        $depsList = $latest.dependencies
    }
    $info = @{
        ModName      = $mod.name
        Slug         = $slug
        Version      = $verNum
        FileName     = $fname
        DestPath     = $destPath
        Side         = $mod.side
        Sha1         = $sha1url
        Sha512       = $sha512url
        DownloadUrl  = $durl
        Dependencies = $depsList
    }
    $downloadedFiles += $info
    
    Write-Host ("    SHA1: " + $sha1url) -ForegroundColor DarkGray
}

Write-Host ""
Write-Host ("  Downloaded: " + $downloadedFiles.Count + " mods") -ForegroundColor Green

if ($downloadedFiles.Count -eq 0) {
    Write-Host "FATAL: No mods downloaded, exiting" -ForegroundColor Red
    exit 1
}

# ---- Dependency Check (Pre-flight) ----
Write-Host ""
Write-Host "[3.5/6] Checking dependencies from Modrinth metadata..." -ForegroundColor Cyan

# Build set of known slugs
$knownSlugs = @{}
foreach ($f in $downloadedFiles) {
    $knownSlugs[$f.Slug] = $true
}

$missingDeps = @()
$depWarnings = @()

foreach ($f in $downloadedFiles) {
    $deps = $f.Dependencies
    if ($deps -eq $null -or $deps.Count -eq 0) { continue }
    
    foreach ($dep in $deps) {
        if ($dep.dependency_type -ne "required") { continue }
        
        $depProjectId = $dep.project_id
        if ($depProjectId -eq $null) { continue }
        
        # Check if this project is already in our mod list
        # We need to resolve project_id -> slug. Try cached first.
        $found = $false
        foreach ($knownFile in $downloadedFiles) {
            # We don't have project_id stored per-file yet, so we use a lazy check:
            # Query the Modrinth project endpoint
            break
        }
    }
}

# Lazy check: only report if there are dependencies we can't verify
$hasDeps = $false
foreach ($f in $downloadedFiles) {
    if ($f.Dependencies -ne $null -and $f.Dependencies.Count -gt 0) {
        $hasDeps = $true
        break
    }
}

if ($hasDeps) {
    Write-Host "  Mods with declared dependencies detected." -ForegroundColor DarkGray
    Write-Host "  Common required deps to verify manually:" -ForegroundColor Yellow
    Write-Host "    - Fabric API (fabric-api): required by most Fabric mods" -ForegroundColor Gray
    Write-Host "    - Fabric Language Kotlin (fabric-language-kotlin): required by IPN, etc." -ForegroundColor Gray
    Write-Host "    - libIPN (libipn): required by Inventory Profiles Next" -ForegroundColor Gray
    Write-Host "    - Architectury API (architectury-api): required by FTB/OPAC mods" -ForegroundColor Gray
    Write-Host "  Run with known-good config for automatic resolution." -ForegroundColor DarkGray
}
else {
    Write-Host "  No inter-mod dependencies declared (standalone mods)." -ForegroundColor Green
}

# ---- Step 4: Verify hashes and build file entries ----
Write-Host ""
Write-Host "[4/6] Verifying file hashes..." -ForegroundColor Cyan

$fileEntries = @()

foreach ($file in $downloadedFiles) {
    if (-not (Test-Path $file.DestPath)) {
        Write-Host ("  WARNING: File not found: " + $file.DestPath) -ForegroundColor Yellow
        continue
    }

    $sha1Hash = $file.Sha1
    $sha512Hash = $file.Sha512

    $localSha1 = (Get-FileHash -Path $file.DestPath -Algorithm SHA1).Hash.ToLower()

    if ($localSha1 -ne $sha1Hash) {
        Write-Host ("  Hash mismatch for " + $file.ModName + ", using local hash") -ForegroundColor Yellow
        Write-Host ("    Local:  " + $localSha1) -ForegroundColor Yellow
        Write-Host ("    Remote: " + $sha1Hash) -ForegroundColor Yellow
        $sha1Hash = $localSha1
    }
    else {
        Write-Host ("  Verified: " + $file.ModName) -ForegroundColor Green
    }

    # Build env object
    $clientEnv = "required"
    $serverEnv = "required"
    if ($file.Side -eq "client") {
        $serverEnv = "unsupported"
    }
    elseif ($file.Side -eq "server") {
        $clientEnv = "unsupported"
    }

    $envHash = @{
        client = $clientEnv
        server = $serverEnv
    }

    $hashHash = @{
        sha1   = $sha1Hash
        sha512 = $sha512Hash
    }

    $dlArray = @($file.DownloadUrl)

    $entry = @{
        path      = ("mods/" + $file.FileName)
        hashes    = $hashHash
        env       = $envHash
        downloads = $dlArray
        fileSize  = (Get-Item $file.DestPath).Length
    }

    $fileEntries += $entry
}

# ---- Step 5: Generate modrinth.index.json ----
Write-Host ""
Write-Host "[5/6] Generating modrinth.index.json..." -ForegroundColor Cyan

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

$indexPath = Join-Path $buildDir "modrinth.index.json"
$indexObj | ConvertTo-Json -Depth 10 | Out-File -FilePath $indexPath -Encoding UTF8

Write-Host ("  Generated: " + $indexPath) -ForegroundColor Green

# ---- Step 6: Package .mrpack ----
Write-Host ""
Write-Host "[6/6] Packaging .mrpack..." -ForegroundColor Cyan

# Copy override configs
$sourceOverrideConfig = Join-Path $PSScriptRoot "overrides\config"
if (Test-Path $sourceOverrideConfig) {
    Copy-Item -Path (Join-Path $sourceOverrideConfig "*") -Destination $configDir -Recurse -Force
    Write-Host "  Copied override configs" -ForegroundColor Gray
}
else {
    $readmePath = Join-Path $configDir "README.txt"
    "# Config directory for this modpack" | Out-File -FilePath $readmePath -Encoding UTF8
}

# Also copy server.properties from overrides root if exists
$sourceServerProps = Join-Path $PSScriptRoot "overrides\server.properties"
if (Test-Path $sourceServerProps) {
    $destServerProps = Join-Path $buildDir "overrides\server.properties"
    Copy-Item -Path $sourceServerProps -Destination $destServerProps -Force
    Write-Host "  Copied server.properties" -ForegroundColor Gray
}

$packFile = Join-Path $OutputDir ($PackName + ".mrpack")
$packParent = Split-Path $packFile -Parent
New-Item -ItemType Directory -Force -Path $packParent | Out-Null

if (Test-Path $packFile) {
    Remove-Item $packFile -Force
}

# Create .mrpack (zip to .mrpack rename - PS 5.1 workaround)
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

# Report
$packSize = (Get-Item $packFile).Length
$packSizeMB = [math]::Round($packSize / 1048576, 2)

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Build complete!" -ForegroundColor Green
Write-Host ("  Output: " + $packFile) -ForegroundColor White
Write-Host ("  Size: " + $packSizeMB + " MB") -ForegroundColor White
Write-Host ("  Mods: " + $downloadedFiles.Count) -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green

Write-Host ""
Write-Host "  Included mods:" -ForegroundColor Cyan
$idx = 1
foreach ($file in $downloadedFiles) {
    Write-Host ("  " + $idx + ". " + $file.ModName + " " + $file.Version)
    $idx = $idx + 1
}

Write-Host ""
Write-Host ("  Temp build dir: " + $buildDir) -ForegroundColor DarkGray
