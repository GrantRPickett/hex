param(
	[switch]$Verbose
)

$targetFile = Join-Path $PSScriptRoot "..\.test_targets"
$projectRoot = Join-Path $PSScriptRoot ".."

if (-not (Test-Path $targetFile)) {
	Write-Host "No .test_targets file found at $targetFile" -ForegroundColor Yellow
	exit 0
}

$targets = Get-Content $targetFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

if ($targets.Count -eq 0) {
	Write-Host ".test_targets is empty." -ForegroundColor Yellow
	exit 0
}

$testArgs = $targets -join ","
$runTestsScript = Join-Path $PSScriptRoot "run_tests.ps1"

$args = @("-Test", $testArgs)
if ($Verbose) {
	$args += "-Verbose"
}

Write-Host "Executing tests for: $testArgs" -ForegroundColor Cyan
pwsh -File $runTestsScript $args
