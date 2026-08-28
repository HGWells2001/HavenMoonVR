@echo off
title HavenMoonVR OpenVR Input Bridge 1.2.6 Community Patch
cd /d "%~dp0"

echo ==========================================
echo HavenMoonVR OpenVR Input Bridge 1.2.6 Community Patch
echo ==========================================
echo.
echo SteamVR verra' usato se aperto, oppure avviato automaticamente.
echo La finestra restera' aperta anche in caso di errore.
echo.

rem The OpenVR controller bridge loads SteamVR's 64-bit openvr_api.dll.
rem Sysnative escapes WoW64 redirection when this CMD was started by a
rem 32-bit parent; System32 is correct when the parent is already 64-bit.
set "HMVR_POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "HMVR_POWERSHELL=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

"%HMVR_POWERSHELL%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0HavenMoonVR_InputBridge.ps1"
set "HMVR_EXIT=%ERRORLEVEL%"

echo.
echo ==========================================
echo Il bridge e' terminato.
echo Exit code: %HMVR_EXIT%
echo ==========================================
echo.
echo Copia qui l'eventuale errore mostrato sopra.
echo.
pause
