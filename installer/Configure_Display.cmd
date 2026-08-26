@echo off
title HavenMoonVR 1.2.0 Community Patch Display Configuration
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0HavenMoonVR_DisplayConfig.ps1"
echo.
pause
