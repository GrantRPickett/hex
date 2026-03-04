param(
    [string]$GodotExe,
    [switch]$Verbose,
    [int]$MaxConcurrency = 4,
    [int]$TimeoutSeconds = 60
)

$ErrorActionPreference = "Stop"
$quiet = -not $Verbose
$projectRoot = Join-Path $PSScriptRoot '..'
$testsDir = Join-Path $projectRoot 'tests'
$trackerPath = Join-Path $projectRoot 'test_status_tracker.md'
$reportsDir = Join-Path $projectRoot 'reports'

if (-not $GodotExe) {
    $preferredGodotPath = 'C:\Users\grant\Downloads\Godot_v4.6-stable_win64.exe'
    if (Test-Path $preferredGodotPath) {
        $GodotExe = $preferredGodotPath
    }
    else {
        $cliScript = Join-Path $PSScriptRoot "godot_cli.ps1"
        if (-not (Test-Path $cliScript)) { throw "Godot CLI helper script not found at $cliScript" }
        $GodotExe = & $cliScript
    }
}

# Discover all test suites
$testFiles = Get-ChildItem -Path $testsDir -Filter "test_*.gd" | Select-Object -ExpandProperty Name
$totalTests = $testFiles.Count

if ($totalTests -eq 0) {
    Write-Host "No test files found in $testsDir" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $totalTests test suites. Running with concurrency $MaxConcurrency..." -ForegroundColor Cyan

# Prepare formatting for Tracker
$dateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$trackerHeader = @"
# Test Status Tracker
*Last run: $dateStr*

| Suite | Status | Failures | Errors | Time (s) |
|---|---|---|---|---|
"@
Set-Content -Path $trackerPath -Value $trackerHeader -Encoding UTF8

$running = @()
$results = @{}

function Start-TestProcess {
    param([string]$testName)

    $testTarget = "res://tests/$testName"
    $cmdArgs = @('--headless', '-s', 'addons/gdUnit4/bin/GdUnitCmdTool.gd', '-a', $testTarget, '--ignoreHeadlessMode')

    $logFile = Join-Path $reportsDir "$testName.log"

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

    # To isolate reports, we don't know the exact folder easily if running in parallel,
    # but we can rely on exit codes or parse all new results at the end if Godot exit code is ambiguous.
    # Actually, gdUnit4 reliably exits with code > 0 on failure.

    $process.Start() | Out-Null

    # Read streams asynchronously so buffers don't fill and block Godot
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
        OutJob    = $outJob
        ErrJob    = $errJob
    }
}

$completedCount = 0
$totalPass = 0
$totalFail = 0
$totalTimeout = 0
$queue = New-Object System.Collections.Generic.Queue[string]
foreach ($t in $testFiles) { $queue.Enqueue($t) }

$running = @()

while ($queue.Count -gt 0 -or $running.Count -gt 0) {
    # Fill up runners
    while ($running.Count -lt $MaxConcurrency -and $queue.Count -gt 0) {
        $nextTest = $queue.Dequeue()
        $running += Start-TestProcess -testName $nextTest
    }

    # Check runners
    $stillRunning = @()
    foreach ($job in $running) {
        $process = $job.Process
        $elapsed = (Get-Date) - $job.StartTime

        if ($process.HasExited) {
            $exitCode = $process.ExitCode

            $failedNames = @()
            $logContent = $null
            if (Test-Path -LiteralPath $job.LogFile) {
                $logContent = Get-Content -Path $job.LogFile -Raw -ErrorAction SilentlyContinue
                if ($logContent) {
                    $xmlMatch = [regex]::Match($logContent, "Open XML Report at: file://([^\r\n]*)")
                    if ($xmlMatch.Success) {
                        $xmlPathStr = $xmlMatch.Groups[1].Value
                        if (Test-Path -LiteralPath $xmlPathStr) {
                            try {
                                [xml]$doc = Get-Content -Path $xmlPathStr -Raw
                                $failedCases = $doc.SelectNodes("//testcase[failure or error]")
                                if ($failedCases) {
                                    foreach ($fc in $failedCases) {
                                        $failedNames += $fc.name
                                    }
                                }
                            }
                            catch {}
                        }
                    }
                }
            }

            $duration = [math]::Round($elapsed.TotalSeconds, 1)

            if ($exitCode -eq 0 -and $failedNames.Count -eq 0) {
                $totalPass++
                $statusSymbol = "✅ Pass"
                Write-Host "[$($completedCount + 1)/$totalTests] $($job.TestName): $statusSymbol (${duration}s)" -ForegroundColor Green
                Set-Content -Path $job.LogFile -Value "Passed. Log omitted to save space."
            }
            else {
                $totalFail++
                $statusSymbol = "❌ Fail"
                $failText = $job.TestName
                if ($failedNames.Count -gt 0) {
                    $failText += "<br><ul>"
                    $failedNames | ForEach-Object { $failText += "<li>$_</li>" }
                    $failText += "</ul>"
                }

                Write-Host "[$($completedCount + 1)/$totalTests] $($job.TestName): $statusSymbol (${duration}s)" -ForegroundColor Red

                $line = "| $failText | $statusSymbol | ? | ? | $duration |"
                Add-Content -Path $trackerPath -Value $line

                if ($logContent) {
                    $cleanLog = $logContent -replace "[\x1B\x9B]\[[0-?]*[ -/]*[@-~]", ""
                    Set-Content -Path $job.LogFile -Value $cleanLog
                }
            }

            $completedCount++
            Unregister-Event -SourceIdentifier $job.OutJob.Name -ErrorAction SilentlyContinue
            Unregister-Event -SourceIdentifier $job.ErrJob.Name -ErrorAction SilentlyContinue
        }
        elseif ($elapsed.TotalSeconds -gt $TimeoutSeconds) {
            try { Stop-Process -Id $process.Id -Force } catch {}
            Write-Host "[$($completedCount + 1)/$totalTests] $($job.TestName): ⏱️ Timeout (${TimeoutSeconds}s)" -ForegroundColor Magenta
            $line = "| $($job.TestName) | ⏱️ Timeout | - | - | >$TimeoutSeconds |"
            Add-Content -Path $trackerPath -Value $line
            $completedCount++
            $totalTimeout++
            Unregister-Event -SourceIdentifier $job.OutJob.Name -ErrorAction SilentlyContinue
            Unregister-Event -SourceIdentifier $job.ErrJob.Name -ErrorAction SilentlyContinue
        }
        else {
            $stillRunning += $job
        }
    }
    $running = $stillRunning

    Start-Sleep -Milliseconds 250
}

$summaryLine = "`n**Summary:** ✅ $totalPass Passed | ❌ $totalFail Failed | ⏱️ $totalTimeout Timed Out (Total: $totalTests Suites)"
Add-Content -Path $trackerPath -Value $summaryLine

Write-Host "`nBatch test run complete. $($totalPass) Passed, $($totalFail) Failed, $($totalTimeout) Timeouts." -ForegroundColor Cyan
Write-Host "See $($trackerPath) for full results." -ForegroundColor Cyan
