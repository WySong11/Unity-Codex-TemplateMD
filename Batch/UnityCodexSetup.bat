@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS_EXE%" (
    echo ERROR: Windows PowerShell was not found.
    exit /b 1
)
"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0UnityCodexSetup.ps1" %*
set "RESULT=%ERRORLEVEL%"
if "%~1"=="" pause
endlocal & exit /b %RESULT%
