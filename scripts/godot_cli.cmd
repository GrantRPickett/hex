@echo off

setlocal

set "SCRIPT_DIR=%~dp0"

call :find_shell || exit /b 1

"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%godot_cli.ps1" %*

exit /b %ERRORLEVEL%



:find_shell

for %%P in (pwsh powershell) do (

	where %%P >nul 2>nul && set "PS_EXE=%%P" && goto :eof

)

echo Neither 'pwsh' nor 'powershell' is available in PATH.

exit /b 1

