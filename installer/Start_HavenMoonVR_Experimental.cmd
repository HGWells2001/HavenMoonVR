@echo off
title HavenMoonVR OpenVR Input Bridge 1.1 Experimental
cd /d "%~dp0"

echo ==========================================
echo HavenMoonVR OpenVR Input Bridge 1.1 Experimental
echo ==========================================
echo.
echo SteamVR verra' usato se aperto, oppure avviato automaticamente.
echo La finestra restera' aperta anche in caso di errore.
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0HavenMoonVR_InputBridge_Experimental.ps1"
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
