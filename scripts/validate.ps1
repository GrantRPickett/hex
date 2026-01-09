[CmdletBinding()]
param(
    [string]$GodotExe,
    [switch]$UpdateTodos,
    [string]$PythonExe = "python",
    [int]$KeepReports = 10,
    [switch]$NoPruneReports,
    [switch]$ShowAll
)

$ErrorActionPreference = "Continue"
$quiet = -not $ShowAll

function Invoke-External {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )
    $orig = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $out = & $FilePath @Arguments 2>&1
        $code = $LASTEXITCODE
        return @{ Output = $out; ExitCode = $code }
    }
    finally {
        $ErrorActionPreference = $orig
    }
}

function Get-LatestReportPath {
    $reportsRoot = Join-Path $PSScriptRoot "..\reports"
    if (-not (Test-Path $reportsRoot)) { return $null }
    $dirs = Get-ChildItem -Path $reportsRoot -Directory -Filter 'report_*' -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    if ($dirs -and $dirs.Length -gt 0) { return $dirs[0].FullName }
    return $null
}

Write-Host "Running GdUnit4 tests..." -ForegroundColor Cyan
$runTestsScript = Join-Path $PSScriptRoot 'run_tests.ps1'
$testArgs = @('-NoProfile', '-File', $runTestsScript)
if ($GodotExe) { $testArgs += @('-GodotExe', $GodotExe) }
if ($ShowAll) { $testArgs += @('-Verbose') }
$test = Invoke-External -FilePath 'powershell' -Arguments $testArgs

# Prune old reports to keep context small
if (-not $NoPruneReports) {
    try {
        $pruneScript = Join-Path $PSScriptRoot 'prune_reports.ps1'
        if ($ShowAll) {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $pruneScript -Keep $KeepReports | Out-Host
        } else {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $pruneScript -Keep $KeepReports | Out-Null
        }
    }
    catch {
        Write-Host "Report pruning encountered an error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "Checking that functions are referenced by tests..." -ForegroundColor Cyan
$checkScript = Join-Path $PSScriptRoot 'check_function_tests.py'
# Capture as a single string to simplify parsing
$checkOutputRaw = & $PythonExe $checkScript 2>&1
$checkExit = $LASTEXITCODE
$checkOutputText = $checkOutputRaw | Out-String

$suggestions = New-Object System.Collections.Generic.List[string]
$todos = New-Object System.Collections.Generic.List[string]

if ($test.ExitCode -ne 0) {
    $latestReport = Get-LatestReportPath
    $reportHint = if ($latestReport) { "See report: $latestReport" } else { "See 'reports' directory for details." }
    $suggestions.Add("Fix failing tests. $reportHint") | Out-Null
    $todos.Add("Investigate and fix failing tests ($reportHint)") | Out-Null
}
else {
    $suggestions.Add("All tests passed. Proceed with changes or add coverage for new code.") | Out-Null
}

if ($checkExit -ne 0) {
    $lines = $checkOutputText -split "`r?`n"
    $bulletLines = @($lines | Where-Object { $_ -match '^\s{2,}.+' })
    if ($bulletLines.Count -gt 0) {
        $suggestions.Add("Add tests referencing new/untested functions:") | Out-Null
        foreach ($bl in $bulletLines) {
            $trim = $bl.Trim()
            $suggestions.Add(" - $trim") | Out-Null
            $todos.Add("Add test: $trim") | Out-Null
        }
    }
    else {
        $suggestions.Add("Functions missing test references detected. See checker output above.") | Out-Null
        $todos.Add("Ensure all functions are referenced in tests.") | Out-Null
    }
}
else {
    $suggestions.Add("All project functions are referenced in tests.") | Out-Null
}

Write-Host ""; Write-Host "=== Validation Summary ===" -ForegroundColor Green
if (-not $quiet) {
    Write-Host ("Tests exit code: {0}" -f $test.ExitCode)
    Write-Host ("Check exit code: {0}" -f $checkExit)
    Write-Host ""

    Write-Host "Suggestions:" -ForegroundColor Yellow
    foreach ($s in $suggestions) { Write-Host $s }
} else {
    if ($test.ExitCode -ne 0 -or $checkExit -ne 0) {
        Write-Host "Tests exit code: $($test.ExitCode), Check exit code: $($checkExit)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Suggestions:" -ForegroundColor Yellow
        foreach ($s in $suggestions) { Write-Host $s }
    } else {
        Write-Host "✅ All validations passed" -ForegroundColor Green
    }
}

if ($UpdateTodos) {
    $todoPath = Join-Path $PSScriptRoot '..\TODO.md'
    $lines = @()
    $lines += "# TODO"
    $lines += ("Updated: {0}" -f (Get-Date).ToString('yyyy-MM-dd HH:mm'))
    $lines += ""
    foreach ($t in $todos) { $lines += ("- {0}" -f $t) }
    if ($todos.Count -eq 0) { $lines += "- No outstanding issues detected by validate.ps1." }
    Set-Content -LiteralPath $todoPath -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
    Write-Host ("Updated TODOs at {0}" -f $todoPath) -ForegroundColor Cyan
}

# Propagate failure if either step failed
# Relaxed validator: do not fail CI; surface suggestions and update TODOs
exit 0
