param(
    [string]$GodotExe
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "ci_config.ps1")
$ciConfig = Get-CiConfig
$extensionListPath = $ciConfig.ExtensionListPath

$ErrorActionPreference = "Stop"

$extensionListPath = Join-Path $PSScriptRoot "..\.godot\extension_list.cfg"
$backupPath = $null

if (-not $GodotExe) {
    $cliScript = Join-Path $PSScriptRoot "godot_cli.ps1"
    if (-not (Test-Path $cliScript)) {
        throw "Godot CLI helper script not found at $cliScript"
    }
    $GodotExe = & $cliScript
    Write-Host "Using downloaded Godot CLI at $GodotExe" -ForegroundColor Yellow
}

try {
    if (Test-Path $extensionListPath) {
        $backupPath = "$extensionListPath.bak"
        Copy-Item -Path $extensionListPath -Destination $backupPath -Force
        Set-Content -Path $extensionListPath -Value "" -NoNewline
    }

    & $GodotExe --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    if ($backupPath -and (Test-Path $backupPath)) {
        Move-Item -Path $backupPath -Destination $extensionListPath -Force
    }
}
