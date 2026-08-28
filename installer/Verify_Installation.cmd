@echo off
title HavenMoonVR 1.2.6 Community Patch Verification
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0HavenMoonVR_Patcher.ps1" -Mode Verify %*
echo.
pause
