
$files = Get-ChildItem -Recurse -Filter *.gd | Where-Object { $_.FullName -notmatch "addons" -and $_.FullName -notmatch "tests" }
foreach ($file in $files) {
    $lines = (Get-Content $file.FullName).Count
    if ($lines -ge 400) {
        Write-Output "$lines : $($file.FullName)"
    }
}
