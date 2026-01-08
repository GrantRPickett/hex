[CmdletBinding()]
param(
    [string]$Version,
    [ValidateSet("auto", "win", "linux", "mac")]
    [string]$Platform = "auto",
    [string]$Channel = "stable",
    [int]$MajorVersion = 4,
    [string]$InstallRoot,
    [switch]$ForceDownload,
    [switch]$Run,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GodotArgs
)

function Resolve-Platform([string]$Requested) {
    if ($Requested -ne "auto") {
        return $Requested
    }
    if ($IsWindows -or $PSVersionTable.PSEdition -eq 'Desktop') {
        return "win"
    }
    if ($IsLinux) {
        return "linux"
    }
    if ($IsMacOS) {
        return "mac"
    }
    throw "Unable to detect platform. Specify -Platform explicitly."
}

function Ensure-Directory([string]$PathValue) {
    if (-not (Test-Path $PathValue)) {
        New-Item -ItemType Directory -Path $PathValue | Out-Null
    }
}

function Get-LatestGodotRelease {
    param(
        [int]$MajorVersion,
        [string]$Channel,
        [string]$UserAgent
    )

    $escapedChannel = [System.Text.RegularExpressions.Regex]::Escape($Channel)
    $pattern = "^{0}\.\d+(\.\d+)?-{1}$" -f $MajorVersion, $escapedChannel
    $url = "https://api.github.com/repos/godotengine/godot-builds/releases?per_page=100"
    try {
        $releases = Invoke-RestMethod -Uri $url -Headers @{ "User-Agent" = $UserAgent }
    }
    catch {
        throw "Failed to query GitHub for Godot releases: $($_.Exception.Message)"
    }

    foreach ($release in $releases) {
        $tag = $release.tag_name
        if ($tag -match $pattern) {
            $versionNumber = $tag -replace ("-$escapedChannel$"), ""
            return @{ version = $versionNumber; tag = $tag }
        }
    }
    throw "Unable to locate a $Channel release for Godot $MajorVersion.x from the Godot builds API."
}

function Get-EnvBinaryCandidate {
    param([string[]]$EnvKeys)
    foreach ($key in $EnvKeys) {
        $value = (Get-Item -Path "Env:$key" -ErrorAction SilentlyContinue).Value
        if ($value -and (Test-Path $value)) {
            return (Get-Item $value).FullName
        }
    }
    return $null
}

function Find-DownloadsBinary {
    param(
        [string]$ReleaseTag,
        [string]$PlatformKey,
        [hashtable]$PlatformConfig
    )

    if ($PlatformKey -ne "win") {
        return $null
    }
    $downloads = Join-Path $env:USERPROFILE "Downloads"
    if (-not (Test-Path $downloads)) {
        return $null
    }
    $baseName = "Godot_v$ReleaseTag"
    $primaryName = "$baseName_$($PlatformConfig.binary)"
    $consoleName = $null
    if ($primaryName -like '*.exe') {
        $consoleName = $primaryName -replace '\.exe$', '_console.exe'
    }
    $searchDirs = @($downloads)
    $expandedDir = Join-Path $downloads "$baseName_$($PlatformConfig.suffix)"
    if (Test-Path $expandedDir) {
        $searchDirs += $expandedDir
    }
    foreach ($dir in $searchDirs) {
        foreach ($candidate in @($consoleName, $primaryName)) {
            if ($candidate) {
                $candidatePath = Join-Path $dir $candidate
                if (Test-Path $candidatePath) {
                    return (Get-Item $candidatePath).FullName
                }
            }
        }
    }
    return $null
}

if (-not $InstallRoot) {
    $InstallRoot = Join-Path $PSScriptRoot "..\.godot-cli"
}

$platformKey = Resolve-Platform $Platform
$channel = $Channel.ToLowerInvariant()
$userAgent = "hex-godot-cli"

if ([string]::IsNullOrWhiteSpace($Version)) {
    $release = Get-LatestGodotRelease -MajorVersion $MajorVersion -Channel $channel -UserAgent $userAgent
    $Version = $release.version
    $releaseTag = $release.tag
    Write-Host "Resolved Godot release $releaseTag (major $MajorVersion)." -ForegroundColor Green
}
else {
    if ($Version -match "^(?<number>[^-]+)-(?<suffix>.+)$") {
        $Version = $Matches.number
        $channel = $Matches.suffix.ToLowerInvariant()
        $releaseTag = "$Version-$channel"
    }
    else {
        $releaseTag = "$Version-$channel"
    }
}

$platformConfig = @{
    win = @{ suffix = "win64.exe"; binary = "win64.exe" }
    linux = @{ suffix = "linux.x86_64"; binary = "linux.x86_64" }
    mac = @{ suffix = "macos.universal"; binary = "macos.universal" }
}
if (-not $platformConfig.ContainsKey($platformKey)) {
    throw "Unsupported platform '$platformKey'."
}
$platformConfig = $platformConfig[$platformKey]

$installDir = Join-Path $InstallRoot "${releaseTag}-$platformKey"
$archiveName = "Godot_v${releaseTag}_$($platformConfig.suffix).zip"
$binaryName = "Godot_v${releaseTag}_$($platformConfig.binary)"
$binaryPath = $null

if (-not $ForceDownload) {
    $binaryPath = Get-EnvBinaryCandidate -EnvKeys @('HEX_GODOT_EXE', 'GODOT4_EXE', 'GODOT_EXE')
    if (-not $binaryPath) {
        $binaryPath = Find-DownloadsBinary -ReleaseTag $releaseTag -PlatformKey $platformKey -PlatformConfig $platformConfig
    }
    if ($binaryPath) {
        Write-Host "Using existing Godot binary at $binaryPath" -ForegroundColor Yellow
    }
}

if (-not $binaryPath) {
    Ensure-Directory $InstallRoot
    $binaryPath = Join-Path $installDir $binaryName
    $needsInstall = $ForceDownload -or -not (Test-Path $binaryPath)
    if ($needsInstall) {
        if (Test-Path $installDir) {
            Remove-Item -Path $installDir -Recurse -Force
        }
        Ensure-Directory $installDir
        $downloadUrl = "https://github.com/godotengine/godot-builds/releases/download/$releaseTag/$archiveName"
        $tempArchive = Join-Path ([System.IO.Path]::GetTempPath()) $archiveName
        Write-Host "Downloading Godot $releaseTag ($platformKey)..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempArchive -Headers @{ "User-Agent" = $userAgent }
        try {
            Expand-Archive -LiteralPath $tempArchive -DestinationPath $installDir -Force
        }
        finally {
            if (Test-Path $tempArchive) {
                Remove-Item $tempArchive -Force
            }
        }
    }
}

if (-not (Test-Path $binaryPath)) {
    throw "Godot binary was not found at $binaryPath even after download."
}

$_argsProvided = $GodotArgs -and $GodotArgs.Count -gt 0
if ($Run -or $_argsProvided) {
    & $binaryPath @GodotArgs
    exit $LASTEXITCODE
}

Write-Output $binaryPath
