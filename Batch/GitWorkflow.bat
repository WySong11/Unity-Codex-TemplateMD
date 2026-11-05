@echo off
setlocal EnableExtensions DisableDelayedExpansion
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0GitWorkflow.ps1" %*
set "RESULT=%ERRORLEVEL%"
if "%~1"=="" pause
endlocal & exit /b %RESULT%
