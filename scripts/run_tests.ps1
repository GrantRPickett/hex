param(
	[string]$GodotExe,
	[switch]$Verbose,
	[string]$Test
)

$ErrorActionPreference = "Stop"
$quiet = -not $Verbose

function Resolve-TestTarget {
	param(
		[string]$Value,
		[string]$ProjectRoot
	)
	if ([string]::IsNullOrWhiteSpace($Value)) {
		return 'res://tests'
	}
	if ($Value.StartsWith('res://')) {
		return $Value
	}
	$candidate = $Value
	if (-not (Test-Path -LiteralPath $candidate)) {
		$candidate = Join-Path $ProjectRoot $Value
		if (-not (Test-Path -LiteralPath $candidate)) {
			throw "Unable to find test path '$Value'. Use a res:// path or a path relative to the project root."
		}
	}
	$resolved = (Resolve-Path -LiteralPath $candidate).ProviderPath
	$fullProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
	$fullResolved = [System.IO.Path]::GetFullPath($resolved)

	if ($fullResolved.StartsWith($fullProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
		$relative = $fullResolved.Substring($fullProjectRoot.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar)
		$relative = $relative -replace '\\', '/'
		return "res://$relative"
	}
	return $Value
}

function Invoke-PreFlightChecks {
	param(
		[string]$TestPath,
		[string]$ProjectRoot
	)
	if (-not $TestPath.StartsWith("res://")) { return }

	$localPath = $TestPath -replace "res://", ""
	$fullPath = Join-Path $ProjectRoot $localPath
	if (-not (Test-Path -LiteralPath $fullPath)) { return }

	$content = Get-Content -Raw -Path $fullPath
	$hasError = $false

	# 1. Check for 'func before()' which should be 'before_test()'
	if ($content -match "func before\(\)") {
		Write-Host "⚠️ PRE-FLIGHT ERROR: '$TestPath' uses 'func before()'. GDUnit4 requires 'before_test()' for per-test setup." -ForegroundColor Red
		$hasError = $true
	}

	# 2. Check for missing extends
	if ($content -notmatch 'extends\s+(GdUnitTestSuite|BaseTestSuite|GdUnitTestSuite |"base_test_suite.gd")') {
		Write-Host "⚠️ PRE-FLIGHT ERROR: '$TestPath' does not extend GdUnitTestSuite or BaseTestSuite." -ForegroundColor Red
		$hasError = $true
	}

	# 3. Basic UID check in project.godot if referenced (stub)
	$projectGodot = Join-Path $ProjectRoot "project.godot"
	if (Test-Path $projectGodot) {
		$pgContent = Get-Content -Raw -Path $projectGodot
		if ($pgContent -match "uid://") {
			Write-Host "⚠️ PRE-FLIGHT WARNING: 'project.godot' contains UIDs. These can cause parse errors in headless mode. Consider 'res://' paths." -ForegroundColor Yellow
		}
	}

	if ($hasError) {
		throw "Pre-flight checks failed for $TestPath"
	}
}

. (Join-Path $PSScriptRoot "ci_config.ps1")
$ciConfig = Get-CiConfig
$extensionListPath = $ciConfig.ExtensionListPath
$backupPath = $null

$projectRoot = Join-Path $PSScriptRoot '..'
$testTarget = if ($Test) { Resolve-TestTarget -Value $Test -ProjectRoot $projectRoot } else { 'res://tests' }

# Run Pre-flight checks on target
if ($testTarget.EndsWith(".gd")) {
	Invoke-PreFlightChecks -TestPath $testTarget -ProjectRoot $projectRoot
}




$preferredGodotPath = "$PSScriptRoot/../.godot-cli/4.6-stable-win/Godot_v4.6-stable_win64_console.exe"
if (-not $GodotExe -and (Test-Path $preferredGodotPath)) {
	$GodotExe = $preferredGodotPath
	if ($Verbose) {
		Write-Host "Using preferred Godot binary at $preferredGodotPath" -ForegroundColor Yellow
	}
}

if (-not $GodotExe) {

	$cliScript = Join-Path $PSScriptRoot "godot_cli.ps1"

	if (-not (Test-Path $cliScript)) {

		throw "Godot CLI helper script not found at $cliScript"

	}

	$GodotExe = & $cliScript

	if ($Verbose) {
		Write-Host "Using downloaded Godot CLI at $GodotExe" -ForegroundColor Yellow
	}

}



try {
	if (Test-Path $extensionListPath) {
		$backupPath = "$extensionListPath.bak"
		Copy-Item -Path $extensionListPath -Destination $backupPath -Force
		Set-Content -Path $extensionListPath -Value "" -NoNewline
	}

	$timeoutSeconds = 120

	$godotArgs = @('--headless', '-s', 'addons/gdUnit4/bin/GdUnitCmdTool.gd', '-a', $testTarget, '--ignoreHeadlessMode')

	$reportsDir = Join-Path $PSScriptRoot '..\reports'

	function Invoke-GodotTestRun {
		$outPath = Join-Path ([System.IO.Path]::GetTempPath()) "godot_test_out_$pid.log"
		$errPath = Join-Path ([System.IO.Path]::GetTempPath()) "godot_test_err_$pid.log"

		$process = Start-Process -FilePath $GodotExe -ArgumentList $godotArgs -WorkingDirectory $projectRoot -RedirectStandardOutput $outPath -RedirectStandardError $errPath -NoNewWindow -PassThru

		$exited = $process.WaitForExit($timeoutSeconds * 1000)
		if (-not $exited) {
			try { Stop-Process -Id $process.Id -Force } catch {}
			throw "Godot test run exceeded $timeoutSeconds seconds and was terminated."
		}

		$stdout = if (Test-Path $outPath) { Get-Content $outPath -Raw } else { "" }
		$stderr = if (Test-Path $errPath) { Get-Content $errPath -Raw } else { "" }

		if ($outPath) { Remove-Item $outPath -ErrorAction SilentlyContinue }
		if ($errPath) { Remove-Item $errPath -ErrorAction SilentlyContinue }

		# Save to persistent log for easy debugging
		$latestLogPath = Join-Path $reportsDir "latest_run.log"
		"--- NEW RUN $(Get-Date) ---`nSTDOUT:`n$stdout`nSTDERR:`n$stderr" | Out-File -FilePath $latestLogPath -Encoding utf8

		return @{
			Stdout   = $stdout
			Stderr   = $stderr
			ExitCode = $process.ExitCode
		}
	}

	# Record existing reports
	$existingReports = @{}
	if (Test-Path $reportsDir) {
		Get-ChildItem -Path $reportsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object { $existingReports[$_.Name] = $true }
	}

	$runResult = Invoke-GodotTestRun

	$outputStr = [string]$runResult.Stdout + "`n" + [string]$runResult.Stderr

	# Cache repair check for GDUnit missing reference
	if ($outputStr -match "Could not find type `"GdUnitTestCIRunner`"") {
		Write-Host "⚠️ Detected corrupt GDUnit4 cache. Rebuilding `.godot` folder..." -ForegroundColor Yellow
		$rebuildArgs = @('--headless', '--editor', '--quit')
		Start-Process -FilePath $GodotExe -ArgumentList $rebuildArgs -WorkingDirectory $projectRoot -NoNewWindow -Wait
		Write-Host "♻️ Retrying tests..." -ForegroundColor Cyan

		# Ensure we look for a new report by refreshing existing
		$existingReports = @{}
		if (Test-Path $reportsDir) {
			Get-ChildItem -Path $reportsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object { $existingReports[$_.Name] = $true }
		}

		$runResult = Invoke-GodotTestRun
		$outputStr = [string]$runResult.Stdout + "`n" + [string]$runResult.Stderr
	}

	if (-not $quiet) {
		# Cleanly print output avoiding pass messages to reduce spam
		$lines = $outputStr -split "`n"
		foreach ($line in $lines) {
			$cleanLine = $line -replace "[\x1B\x9B]\[[0-?]*[ -/]*[@-~]", ""
			if ($cleanLine -match "\[pass\]|PASSED") { continue }
			if ([string]::IsNullOrWhiteSpace($cleanLine)) { continue }
			Write-Host $cleanLine
		}
	}

	# Find the new report
	$latest = $null
	if (Test-Path $reportsDir) {
		$newDirs = Get-ChildItem -Path $reportsDir -Directory -ErrorAction SilentlyContinue | Where-Object { -not $existingReports.ContainsKey($_.Name) }
		if ($newDirs) {
			$latest = $newDirs | Sort-Object CreationTime -Descending | Select-Object -First 1
		}
	}

	if ($latest -and (Test-Path (Join-Path $latest.FullName 'results.xml'))) {
		try {
			$xmlPath = Join-Path $latest.FullName 'results.xml'
			[xml]$doc = Get-Content -Path $xmlPath -Raw
			$root = $doc.testsuites
			if ($root -ne $null) {
				$failures = 0
				if ($root.Attributes['failures']) { $failures = [int]$root.Attributes['failures'].Value }
				$errors = 0
				if ($root.Attributes['errors']) { $errors = [int]$root.Attributes['errors'].Value }

				if ($failures -gt 0 -or $errors -gt 0) {
					Write-Host "`n❌ TESTS FAILED: $failures failures, $errors errors" -ForegroundColor Red
					Write-Host "Report: $($latest.FullName)" -ForegroundColor Yellow
					$failedCases = $doc.SelectNodes("//testcase[failure or error]")
					if ($failedCases) {
						Write-Host "`nFailing tests:" -ForegroundColor Red
						foreach ($fc in $failedCases) {
							Write-Host "  - $($fc.name)" -ForegroundColor Red
						}
					}
					exit 1
				}
				else {
					if ($Verbose) {
						Write-Host "`n✅ All tests passed" -ForegroundColor Green
					}
					exit 0
				}
			}
		}
		catch {
			if ($runResult.ExitCode -ne 0) { exit $runResult.ExitCode }
		}
	}
	else {
		# No report generated, meaning an engine crash or failure before standard test runner finished.
		if ($runResult.ExitCode -ne 0) {
			Write-Host "`n❌ ERROR: Godot exited with code $($runResult.ExitCode) but no GdUnit report was found. See the log above for clues." -ForegroundColor Red
			# Print raw log unconditionally if there was a full on crash
			if ($quiet) { Write-Host $outputStr }
			exit $runResult.ExitCode
		}
	}
}
finally {
	if ($backupPath -and (Test-Path $backupPath)) {
		Move-Item -Path $backupPath -Destination $extensionListPath -Force
	}

	$pruneScript = Join-Path $PSScriptRoot "prune_reports.ps1"
	if (Test-Path $pruneScript) {
		& $pruneScript
	}
}
