@echo off
title HavenMoonVR 1.2.1 Community Patch Installer
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0HavenMoonVR_Patcher.ps1" -Mode Install -HeightOffset -1.00 %*
echo.
pause
