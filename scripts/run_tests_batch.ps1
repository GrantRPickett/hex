param(
    [string]$GodotExe,
    [switch]$Verbose,
    [int]$MaxConcurrency = 8,
    [int]$TimeoutSeconds = 600,
    [string[]]$SuiteList,
    [switch]$Targeted
)

$ErrorActionPreference = "Stop"
$projectRoot = Join-Path $PSScriptRoot ".."
$testsDir = Join-Path $projectRoot "tests"
$trackerPath = Join-Path $projectRoot "test_status_tracker.md"
$reportsDir = Join-Path $projectRoot "reports"

if (-not $GodotExe) {
    $preferredGodotPath = "C:\Users\grant\Downloads\Godot_v4.6-stable_win64.exe"
    if (Test-Path $preferredGodotPath) {
        $GodotExe = $preferredGodotPath
    }
    else {
        $cliScript = Join-Path $PSScriptRoot "godot_cli.ps1"
        if (-not (Test-Path $cliScript)) { throw "Godot CLI helper script not found at $cliScript" }
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
    Write-Host "Running 12 targeted suites." -ForegroundColor Cyan
}
elseif ($SuiteList -and $SuiteList.Count -gt 0) {
    if ($SuiteList.Count -eq 1 -and $SuiteList[0].Contains(",")) {
        $testFiles = $SuiteList[0].Split(",") | ForEach-Object { $f = $_; $f.Trim() } | Where-Object { $_ -ne "" }
    }
    else {
        $testFiles = $SuiteList
    }
    Write-Host ("Using provided list of {0} test suites." -f $testFiles.Count) -ForegroundColor Cyan
}
else {
    $testFiles = Get-ChildItem -Path $testsDir -Filter "test_*.gd" | Select-Object -ExpandProperty Name
    Write-Host ("Discovered {0} test suites." -f $testFiles.Count) -ForegroundColor Cyan
}

$totalTests = $testFiles.Count
if ($totalTests -eq 0) {
    Write-Host "No test files found." -ForegroundColor Yellow
    exit 0
}

Write-Host ("Running tests with concurrency {0}..." -f $MaxConcurrency) -ForegroundColor Cyan

$dateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$trackerHeader = "# Test Status Tracker`n*Last run: $dateStr*`n`n| Suite | Status | Failures | Errors | Time (s) |`n|---|---|---|---|---|`n"
Set-Content -Path $trackerPath -Value $trackerHeader -Encoding UTF8

function Start-TestProcess {
    param([string[]]$testNames)
    $primaryTest = $testNames[0]
    $testTargets = New-Object 'System.Collections.Generic.List[string]'
    foreach ($name in $testNames) {
        $testTargets.Add("-a")
        $testTargets.Add("res://tests/$name")
    }
    $baseArgs = @("--headless", "-s", "addons/gdUnit4/bin/GdUnitCmdTool.gd")
    $cmdArgs = $baseArgs + $testTargets.ToArray() + @("--ignoreHeadlessMode")
    $logFile = Join-Path $reportsDir ("{0}.log" -f $primaryTest)
    if (Test-Path $logFile) { Remove-Item $logFile }

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
        TestNames = $testNames
        Process   = $process
        StartTime = Get-Date
        LogFile   = $logFile
        OutJob    = $outJob
        ErrJob    = $errJob
    }
}

$completedCount = 0
$totalPass = 0
$totalFail = 0
$totalTimeout = 0
$chunks = New-Object 'System.Collections.Generic.List[System.Object]'
if ($totalTests -gt 0) {
    $eff = if ($MaxConcurrency -lt $totalTests) { $MaxConcurrency } else { $totalTests }
    for ($i = 0; $i -lt $eff; $i++) { $chunks.Add((New-Object 'System.Collections.Generic.List[string]')) }
    for ($i = 0; $i -lt $totalTests; $i++) { $chunks[$i % $eff].Add($testFiles[$i]) }
}

$queue = New-Object 'System.Collections.Generic.Queue[object]'
foreach ($chunk in $chunks) { if ($chunk.Count -gt 0) { $queue.Enqueue($chunk.ToArray()) } }
$running = New-Object 'System.Collections.Generic.List[object]'

while ($queue.Count -gt 0 -or $running.Count -gt 0) {
    while ($running.Count -lt $MaxConcurrency -and $queue.Count -gt 0) {
        $nextBatch = $queue.Dequeue()
        $running.Add((Start-TestProcess -testNames $nextBatch))
    }
    $stillRunning = New-Object 'System.Collections.Generic.List[object]'
    foreach ($job in $running) {
        $process = $job.Process
        $elapsed = (Get-Date) - $job.StartTime
        if ($process.HasExited) {
            $duration = [math]::Round($elapsed.TotalSeconds, 1)
            $logContent = ""
            if (Test-Path -LiteralPath $job.LogFile) { $logContent = Get-Content -Path $job.LogFile -Raw -ErrorAction SilentlyContinue }
            foreach ($testName in $job.TestNames) {
                $escaped = [regex]::Escape($testName)
                $isPass = ($logContent -match ("PASSED.*" + $escaped)) -or ($process.ExitCode -eq 0 -and $logContent -match $escaped -and -not ($logContent -match "FAILURE|ERRORS"))
                if ($isPass) {
                    $totalPass++; $statusStr = "Pass"
                    Write-Host ("[{0}/{1}] {2}: Pass ({3}s)" -f ($completedCount + 1), $totalTests, $testName, $duration) -ForegroundColor Green
                }
                else {
                    $totalFail++; $statusStr = "Fail"
                    Write-Host ("[{0}/{1}] {2}: Fail ({3}s)" -f ($completedCount + 1), $totalTests, $testName, $duration) -ForegroundColor Red
                }
                Add-Content -Path $trackerPath -Value ("| {0} | {1} | ? | ? | {2} |" -f $testName, $statusStr, $duration)
                $completedCount++
            }
            Unregister-Event -SourceIdentifier $job.OutJob.Name -ErrorAction SilentlyContinue
            Unregister-Event -SourceIdentifier $job.ErrJob.Name -ErrorAction SilentlyContinue
        }
        elseif ($elapsed.TotalSeconds -gt $TimeoutSeconds) {
            try { Stop-Process -Id $process.Id -Force } catch {}
            foreach ($testName in $job.TestNames) {
                Write-Host ("[{0}/{1}] {2}: Timeout" -f ($completedCount + 1), $totalTests, $testName) -ForegroundColor Magenta
                Add-Content -Path $trackerPath -Value ("| {0} | Timeout | - | - | >{1} |" -f $testName, $TimeoutSeconds)
                $completedCount++; $totalTimeout++
            }
            Unregister-Event -SourceIdentifier $job.OutJob.Name -ErrorAction SilentlyContinue
            Unregister-Event -SourceIdentifier $job.ErrJob.Name -ErrorAction SilentlyContinue
        }
        else {
            $stillRunning.Add($job)
        }
    }
    $running = $stillRunning
    Start-Sleep -Milliseconds 250
}

$summ = "`n**Summary:** {0} Passed | {1} Failed | {2} Timed Out" -f $totalPass, $totalFail, $totalTimeout
Add-Content -Path $trackerPath -Value $summ
Write-Host ("`nBatch test run complete. See {0} for results." -f $trackerPath) -ForegroundColor Cyan
