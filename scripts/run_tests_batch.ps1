param(
	[string]$GodotExe,
	[switch]$Verbose,
	[int]$MaxConcurrency = 4,
	[int]$TimeoutSeconds = 120,
	[string[]]$SuiteList,
	[switch]$Targeted,
	[switch]$Force # Run even if pre-flight fails (warning only)
)

$ErrorActionPreference = "Stop"
$projectRoot = Join-Path $PSScriptRoot ".."
$testsDir = Join-Path $projectRoot "tests"
$trackerPath = Join-Path $projectRoot "test_status_tracker.md"
$reportsDir = Join-Path $projectRoot "reports"

# Source pre-flight logic from run_tests.ps1 if possible, or redefine locally for batch
function Invoke-PreFlightBatch {
	param([string]$FilePath)
	$content = Get-Content -Raw -Path $FilePath
	if ($content -match "func before\(\)") { return "Uses 'func before()', needs 'before_test()'" }
	if ($content -notmatch "extends (GdUnitTestSuite|BaseTestSuite)") { return "Does not extend GdUnitTestSuite/BaseTestSuite" }
	return $null
}

if (-not $GodotExe) {
	$preferredGodotPath = "$PSScriptRoot/../.godot-cli/4.6-stable-win/Godot_v4.6-stable_win64_console.exe"
	if (Test-Path $preferredGodotPath) { $GodotExe = $preferredGodotPath }
	else {
		$cliScript = Join-Path $PSScriptRoot "godot_cli.ps1"
		if (-not (Test-Path $cliScript)) { throw "Godot CLI helper script not found" }
		$GodotExe = & $cliScript
	}
}

$testFiles = @()
if ($Targeted) {
	$testFiles = @(
		"test_camera_handler.gd", "test_click_to_move.gd", "test_gameplay_units.gd",
		"test_morale_system.gd", "test_player_roster.gd", "test_pause_workflow.gd",
		"test_animation_request_service.gd", "test_level_builder.gd",
		"test_gameplay_selection_mouse.gd", "test_gameplay_task.gd",
		"test_game_session_builder.gd", "test_pause_menu.gd"
	)
}
elseif ($SuiteList -and $SuiteList.Count -gt 0) {
	if ($SuiteList.Count -eq 1 -and $SuiteList[0].Contains(",")) {
		$testFiles = $SuiteList[0].Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
	} else { $testFiles = $SuiteList }
}
else {
	$testFiles = Get-ChildItem -Path $testsDir -Filter "test_*.gd" | Select-Object -ExpandProperty Name
}

$totalTests = $testFiles.Count
if ($totalTests -eq 0) { Write-Host "No test files found." -ForegroundColor Yellow; exit 0 }

Write-Host "🚀 Starting Batch Test Run (Concurrency: $MaxConcurrency)" -ForegroundColor Cyan

$dateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$trackerHeader = "# Test Status Tracker`n*Last run: $dateStr*`n`n| Suite | Status | Failures | Errors | Time (s) |`n|---|---|---|---|---|`n"
Set-Content -Path $trackerPath -Value $trackerHeader -Encoding UTF8

function Start-TestSuite {
	param([string]$testName)

	$fullPath = Join-Path $testsDir $testName
	$preFlightError = Invoke-PreFlightBatch -FilePath $fullPath
	if ($preFlightError -and -not $Force) {
		return @{
			TestName = $testName; Status = "Pre-flight Fail"; Failures = 0; Errors = 1;
			Duration = 0; LogFile = $null; Exited = $true; PreFlight = $preFlightError
		}
	}

	# Unique report directory for this suite to avoid results.xml collisions
	$suiteReportDir = Join-Path $reportsDir ("run_" + [System.IO.Path]::GetFileNameWithoutExtension($testName))
	if (Test-Path $suiteReportDir) { Remove-Item $suiteReportDir -Recurse -Force }
	New-Item -ItemType Directory -Path $suiteReportDir | Out-Null

	$logFile = Join-Path $suiteReportDir "output.log"
	$cmdArgs = @("--headless", "-s", "addons/gdUnit4/bin/GdUnitCmdTool.gd", "-a", "res://tests/$testName", "--ignoreHeadlessMode")

	$pinfo = New-Object System.Diagnostics.ProcessStartInfo
	$pinfo.FileName = $GodotExe
	$pinfo.Arguments = $cmdArgs -join " "
	$pinfo.WorkingDirectory = $projectRoot
	$pinfo.RedirectStandardOutput = $true
	$pinfo.RedirectStandardError = $true
	$pinfo.UseShellExecute = $false
	$pinfo.CreateNoWindow = $true

	$process = New-Object System.Diagnostics.Process
	$process.StartInfo = $pinfo
	$process.Start() | Out-Null

	$outJob = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action {
		if ($EventArgs.Data) { Add-Content -Path $Event.MessageData -Value $EventArgs.Data }
	} -MessageData $logFile
	$errJob = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action {
		if ($EventArgs.Data) { Add-Content -Path $Event.MessageData -Value $EventArgs.Data }
	} -MessageData $logFile

	$process.BeginOutputReadLine()
	$process.BeginErrorReadLine()

	return @{
		TestName  = $testName
		Process   = $process
		StartTime = Get-Date
		LogFile   = $logFile
		ReportDir = $suiteReportDir
		OutJob	= $outJob
		ErrJob	= $errJob
		Exited	= $false
	}
}

$queue = [System.Collections.Generic.Queue[string]]::new()
foreach ($f in $testFiles) { $queue.Enqueue($f) }
$running = [System.Collections.Generic.List[object]]::new()
$results = [System.Collections.Generic.List[object]]::new()

while ($queue.Count -gt 0 -or $running.Count -gt 0) {
	while ($running.Count -lt $MaxConcurrency -and $queue.Count -gt 0) {
		$suite = $queue.Dequeue()
		$job = Start-TestSuite -testName $suite
		if ($job.Exited) { $results.Add($job) }
		else { $running.Add($job) }
	}

	$stillRunning = [System.Collections.Generic.List[object]]::new()
	foreach ($job in $running) {
		$elapsed = (Get-Date) - $job.StartTime
		if ($job.Process.HasExited) {
			$job.Exited = $true
			$job.Duration = [math]::Round($elapsed.TotalSeconds, 1)

			# Parse results.xml if it exists
			$xmlPath = Get-ChildItem -Path $job.ReportDir -Filter "results.xml" -Recurse | Select-Object -First 1
			if ($xmlPath) {
				try {
					[xml]$doc = Get-Content -Path $xmlPath.FullName -Raw
					$job.Failures = [int]$doc.testsuites.failures
					$job.Errors   = [int]$doc.testsuites.errors
					$job.Status   = if ($job.Failures -gt 0 -or $job.Errors -gt 0) { "Fail" } else { "Pass" }
				} catch {
					$job.Status = "Crash"
					$job.Failures = 0; $job.Errors = 1
				}
			} elseif ($job.Process.ExitCode -eq 0) {
				$job.Status = "Pass"
				$job.Failures = 0; $job.Errors = 0
			} else {
				$job.Status = "Crash"
				$job.Failures = 0; $job.Errors = 1
			}

			Unregister-Event -SourceIdentifier $job.OutJob.Name -ErrorAction SilentlyContinue
			Unregister-Event -SourceIdentifier $job.ErrJob.Name -ErrorAction SilentlyContinue
			$results.Add($job)

			$color = if ($job.Status -eq "Pass") { "Green" } else { "Red" }
			Write-Host ("[{0}/{1}] {2}: {3} ({4}s)" -f ($results.Count), $totalTests, $job.TestName, $job.Status, $job.Duration) -ForegroundColor $color
		}
		elseif ($elapsed.TotalSeconds -gt $TimeoutSeconds) {
			try { Stop-Process -Id $job.Process.Id -Force } catch {}
			$job.Exited = $true
			$job.Status = "Timeout"
			$job.Duration = $TimeoutSeconds
			$job.Failures = 0; $job.Errors = 1
			Unregister-Event -SourceIdentifier $job.OutJob.Name -ErrorAction SilentlyContinue
			Unregister-Event -SourceIdentifier $job.ErrJob.Name -ErrorAction SilentlyContinue
			$results.Add($job)
			Write-Host ("[{0}/{1}] {2}: Timeout" -f ($results.Count), $totalTests, $job.TestName) -ForegroundColor Magenta
		}
		else { $stillRunning.Add($job) }
	}
	$running = $stillRunning
	Start-Sleep -Milliseconds 200
}

# Final report and consolidation
$totalPass = 0; $totalFail = 0; $totalError = 0
foreach ($res in $results) {
	if ($res.Status -eq "Pass") { $totalPass++ } else { $totalFail++ }
	$preMsg = if ($res.PreFlight) { " ($($res.PreFlight))" } else { "" }
	Add-Content -Path $trackerPath -Value ("| {0} | {1}{2} | {3} | {4} | {5} |" -f $res.TestName, $res.Status, $preMsg, $res.Failures, $res.Errors, $res.Duration)
}

$summary = "`n**Summary:** $totalPass Passed | $totalFail Failed/Error/Timeout"
Add-Content -Path $trackerPath -Value $summary
Write-Host "`n✅ Batch run complete. Results updated in $trackerPath" -ForegroundColor Cyan

