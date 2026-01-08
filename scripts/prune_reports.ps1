[CmdletBinding()]
param(
    [int]$Keep = 10,
    [string]$ReportsRoot,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

if (-not $ReportsRoot) {
    $ReportsRoot = Join-Path $PSScriptRoot "..\reports"
}

if (-not (Test-Path $ReportsRoot)) {
    Write-Host "Reports folder not found at $ReportsRoot. Nothing to prune." -ForegroundColor Yellow
    exit 0
}

$dirs = Get-ChildItem -Path $ReportsRoot -Directory -Filter 'report_*' -ErrorAction SilentlyContinue
if (-not $dirs -or $dirs.Count -le $Keep) {
    Write-Host "Found $($dirs.Count) report folders; at or under limit ($Keep)." -ForegroundColor Green
    exit 0
}

$info = foreach ($d in $dirs) {
    $n = -1
    if ($d.Name -match '^report_(\d+)$') { $n = [int]$Matches[1] }
    [pscustomobject]@{
        Dir = $d
        Number = $n
        Time = $d.LastWriteTimeUtc
    }
}

$ordered = $info | Sort-Object -Property @{ Expression = 'Number'; Descending = $true }, @{ Expression = 'Time'; Descending = $true }
$toRemove = @()
if ($ordered.Count -gt $Keep) {
    $toRemove = $ordered[$Keep..($ordered.Count - 1)]
}

if ($toRemove.Count -eq 0) {
    Write-Host "No old reports to delete." -ForegroundColor Green
    exit 0
}

Write-Host ("Deleting {0} old report folder(s), keeping latest {1}." -f $toRemove.Count, $Keep) -ForegroundColor Cyan
foreach ($entry in $toRemove) {
    $path = $entry.Dir.FullName
    if ($WhatIf) {
        Write-Host "Would delete: $path" -ForegroundColor Yellow
    }
    else {
        Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Deleted: $path" -ForegroundColor DarkGray
    }
}

exit 0

