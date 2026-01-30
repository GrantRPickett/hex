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
	$relative = [System.IO.Path]::GetRelativePath($ProjectRoot, $resolved)
	$relative = $relative -replace '\\', '/'
	return "res://$relative"
}

. (Join-Path $PSScriptRoot "ci_config.ps1")
$ciConfig = Get-CiConfig
$extensionListPath = $ciConfig.ExtensionListPath
$backupPath = $null

$projectRoot = Join-Path $PSScriptRoot '..'
$testTarget = if ($Test) { Resolve-TestTarget -Value $Test -ProjectRoot $projectRoot } else { 'res://tests' }




$preferredGodotPath = 'C:\Users\grant\Downloads\Godot_v4.6-stable_win64.exe'
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

	$timeoutSeconds = 30

	$godotArgs = @('--headless', '-s', 'addons/gdUnit4/bin/GdUnitCmdTool.gd', '-a', $testTarget, '--ignoreHeadlessMode')

	# Record start time and existing report folders so we can detect a new report
	$reportsDir = Join-Path $PSScriptRoot '..\reports'
	$startTime = Get-Date
	$existingReports = @{}
	if (Test-Path $reportsDir) {
		Get-ChildItem -Path $reportsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object { $existingReports[$_.Name] = $true }
	}

	$pinfo = New-Object System.Diagnostics.ProcessStartInfo
	$pinfo.FileName = $GodotExe
	$pinfo.Arguments = $godotArgs -join " "
	$pinfo.WorkingDirectory = $projectRoot
	$pinfo.RedirectStandardOutput = $true
	$pinfo.RedirectStandardError = $true
	$pinfo.UseShellExecute = $false
	$pinfo.CreateNoWindow = $true

	$process = New-Object System.Diagnostics.Process
	$process.StartInfo = $pinfo

	$outJob = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -MessageData $quiet -Action {
		if (-not [string]::IsNullOrEmpty($EventArgs.Data)) {
			$line = $EventArgs.Data
			if ($Event.MessageData -and $line -match "\[pass\]") { return }
			Write-Host $line
		}
	}
	$errJob = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action {
		if (-not [string]::IsNullOrEmpty($EventArgs.Data)) { Write-Host $EventArgs.Data -ForegroundColor Red }
	}

	$process.Start() | Out-Null
	$process.BeginOutputReadLine()
	$process.BeginErrorReadLine()

	# Poll for either the Godot process exiting or a new report (results.xml) appearing.
	$deadline = (Get-Date).AddSeconds($timeoutSeconds)
	$reportFound = $false
	$latest = $null
	while ((Get-Date) -lt $deadline) {
		if ($process.HasExited) {
			break
		}

		if (Test-Path $reportsDir) {
			$latest = Get-ChildItem -Path $reportsDir -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
			if ($latest -and -not $existingReports.ContainsKey($latest.Name)) {
				$xmlPath = Join-Path $latest.FullName 'results.xml'
				if (Test-Path $xmlPath) {
					$reportFound = $true
					break
				}
			}
		}

		Start-Sleep -Seconds 1
	}

	if (-not $reportFound -and -not $process.HasExited) {
		try { Stop-Process -Id $process.Id -Force } catch {}
		throw "Godot test run exceeded $timeoutSeconds seconds and was terminated."
	}
	if ($process.HasExited) { $process.WaitForExit() }

	# If we found a report, parse it to determine failures/errors and return a meaningful exit code.
	if ($reportFound) {
		try {
			$xmlPath = Join-Path $latest.FullName 'results.xml'
			[xml]$doc = Get-Content -Path $xmlPath -Raw
			$root = $doc.testsuites
			if ($root -ne $null) {
				$failures = 0
				if ($root.Attributes['failures']) { $failures = [int]$root.Attributes['failures'].Value }
				$errors = 0
				if ($root.Attributes['errors']) { $errors = [int]$root.Attributes['errors'].Value }

				# Kill the running process if still alive
				if (-not $process.HasExited) {
					try { Stop-Process -Id $process.Id -Force } catch {}
				}

				if ($failures -gt 0 -or $errors -gt 0) {
					Write-Host "❌ TESTS FAILED: $failures failures, $errors errors" -ForegroundColor Red
					Write-Host "Report: $($latest.FullName)" -ForegroundColor Yellow
					exit 1
				} else {
					if ($Verbose) {
						Write-Host "✅ All tests passed" -ForegroundColor Green
					}
					exit 0
				}
			}
		} catch {
			# Fall back to process exit code if parsing fails
			if (-not $process.HasExited) { try { Stop-Process -Id $process.Id -Force } catch {} }
			if ($process.ExitCode -ne 0) { exit $process.ExitCode }
		}
	} else {
		if ($process.ExitCode -ne 0) { exit $process.ExitCode }
	}
}
finally {
	if ($outJob) { Unregister-Event -SourceIdentifier $outJob.Name -ErrorAction SilentlyContinue }
	if ($errJob) { Unregister-Event -SourceIdentifier $errJob.Name -ErrorAction SilentlyContinue }

	if ($backupPath -and (Test-Path $backupPath)) {
		Move-Item -Path $backupPath -Destination $extensionListPath -Force
	}

	$pruneScript = Join-Path $PSScriptRoot "prune_reports.ps1"
	if (Test-Path $pruneScript) {
		& $pruneScript
	}
}
