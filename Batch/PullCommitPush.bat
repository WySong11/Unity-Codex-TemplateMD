@echo off
setlocal EnableExtensions DisableDelayedExpansion
if /i "%~1"=="--check" goto check
if not "%~1"=="" goto usage
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0GitWorkflow.ps1" -Action PullCommitPush
set "RESULT=%ERRORLEVEL%"
pause
endlocal & exit /b %RESULT%
:check
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0GitWorkflow.ps1" -Action Check
exit /b %ERRORLEVEL%
:usage
echo Usage: PullCommitPush.bat [--check]
exit /b 2
