@echo off
title HavenMoonVR 1.1 Experimental Display Configuration
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0HavenMoonVR_Experimental_DisplayConfig.ps1"
echo.
pause
