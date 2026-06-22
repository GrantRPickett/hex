param(
	[string]$GodotExe,
	[switch]$UpdateTodos,
	[string]$PythonExe = "python",
	[int]$KeepReports = 10,
	[switch]$NoPruneReports,
	[switch]$ShowAll,
	[switch]$Full,
	[switch]$Short
)

$ErrorActionPreference = "Continue"
$quiet = -not $ShowAll

# Define what to run based on flags
$runTests = $true
$runFuncCheck = -not $Short
$runAuditLoc = $Full
$runCheckUids = $Full

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

$results = @{}

if ($runTests) {
	Write-Host "Running GdUnit4 tests..." -ForegroundColor Cyan
	$runTestsScript = Join-Path $PSScriptRoot 'run_tests.ps1'
	$testArgs = @('-NoProfile', '-File', $runTestsScript)
	if ($GodotExe) { $testArgs += @('-GodotExe', $GodotExe) }
	if ($ShowAll) { $testArgs += @('-Verbose') }
	$testResult = Invoke-External -FilePath 'powershell' -Arguments $testArgs
	$results["Tests"] = $testResult
}

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

if ($runFuncCheck) {
	Write-Host "Checking that functions are referenced by tests..." -ForegroundColor Cyan
	$checkScript = Join-Path $PSScriptRoot 'check_function_tests.py'
	$checkResult = Invoke-External -FilePath $PythonExe -Arguments @($checkScript)
	$results["FuncCheck"] = $checkResult
}

if ($runAuditLoc) {
	Write-Host "Auditing localization for hardcoded strings..." -ForegroundColor Cyan
	$auditScript = Join-Path $PSScriptRoot 'audit_localization.py'
	$auditResult = Invoke-External -FilePath $PythonExe -Arguments @($auditScript)
	$results["AuditLoc"] = $auditResult
}

if ($runCheckUids) {
	Write-Host "Checking for UID collisions..." -ForegroundColor Cyan
	$uidScript = Join-Path $PSScriptRoot 'check_uids.py'
	$uidResult = Invoke-External -FilePath $PythonExe -Arguments @($uidScript)
	$results["CheckUids"] = $uidResult
}

$suggestions = New-Object System.Collections.Generic.List[string]
$todos = New-Object System.Collections.Generic.List[string]

# --- Parse Test Results ---
if ($runTests) {
	$latestReport = Get-LatestReportPath
	$xmlFailures = $null
	$xmlErrors = $null
	if ($latestReport) {
		$resultsPath = Join-Path $latestReport 'results.xml'
		if (Test-Path $resultsPath) {
			try {
				[xml]$xml = Get-Content -Path $resultsPath -ErrorAction Stop
				$root = $xml.SelectSingleNode('/testsuites')
				if ($root -ne $null) {
					$xmlFailures = [int]($root.GetAttribute('failures') -as [int])
					$xmlErrors = 0
					if ($root.HasAttribute('errors')) { $xmlErrors = [int]($root.GetAttribute('errors') -as [int]) }
				}
			} catch {
				$xmlFailures = $null; $xmlErrors = $null
			}
		}
	}

	$testErrors = 0
	$testFailures = 0
	if ($xmlFailures -ne $null -or $xmlErrors -ne $null) {
		$testFailures = $xmlFailures -as [int]
		$testErrors = $xmlErrors -as [int]
	} else {
		if ($results["Tests"].ExitCode -ne 0) { $testErrors = 1 }
	}

	if ($testFailures -gt 0 -or $testErrors -gt 0) {
		$reportHint = if ($latestReport) { "See report: $latestReport" } else { "See 'reports' directory for details." }
		$suggestions.Add("Fix failing tests. $reportHint") | Out-Null
		$todos.Add("Investigate and fix failing tests ($reportHint)") | Out-Null
	}
	else {
		$suggestions.Add("All tests passed.") | Out-Null
	}
}

# --- Parse Func Check Results ---
if ($runFuncCheck) {
	$res = $results["FuncCheck"]
	if ($res.ExitCode -ne 0) {
		$lines = ($res.Output | Out-String) -split "`r?`n"
		$bulletLines = @($lines | Where-Object { $_ -match '^\s{2,}.+' })
		if ($bulletLines.Count -gt 0) {
			$suggestions.Add("Add tests referencing new/untested functions:") | Out-Null
			foreach ($bl in $bulletLines) {
				$trim = $bl.Trim()
				$suggestions.Add(" - $trim") | Out-Null
				$todos.Add("Add test: $trim") | Out-Null
			}
		} else {
			$suggestions.Add("Functions missing test references detected.") | Out-Null
			$todos.Add("Ensure all functions are referenced in tests.") | Out-Null
		}
	} else {
		$suggestions.Add("All project functions are referenced in tests.") | Out-Null
	}
}

# --- Parse Audit Loc Results ---
if ($runAuditLoc) {
	$res = $results["AuditLoc"]
	if ($res.ExitCode -ne 0) {
		$suggestions.Add("Fix potential hardcoded strings found by audit_localization.py") | Out-Null
		$todos.Add("Localize hardcoded strings detected by audit.") | Out-Null
	} else {
		$suggestions.Add("Localization audit passed.") | Out-Null
	}
}

# --- Parse UID Check Results ---
if ($runCheckUids) {
	$res = $results["CheckUids"]
	if ($res.ExitCode -ne 0) {
		$suggestions.Add("Investigate and fix UID collisions found by check_uids.py") | Out-Null
		$todos.Add("Resolve UID collisions in project resources.") | Out-Null
	} else {
		$suggestions.Add("UID check passed.") | Out-Null
	}
}

Write-Host ""; Write-Host "=== Validation Summary ===" -ForegroundColor Green
foreach ($key in $results.Keys) {
	$res = $results[$key]
	$status = if ($res.ExitCode -eq 0) { "PASSED" } else { "FAILED" }
	$color = if ($res.ExitCode -eq 0) { "Green" } else { "Red" }
	Write-Host ("{0}: {1} (Exit: {2})" -f $key.PadRight(12), $status, $res.ExitCode) -ForegroundColor $color
}

Write-Host ""
Write-Host "Suggestions:" -ForegroundColor Yellow
foreach ($s in $suggestions) { Write-Host $s }

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

exit 0
