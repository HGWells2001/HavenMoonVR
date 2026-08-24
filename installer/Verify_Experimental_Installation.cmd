@echo off
title HavenMoonVR 1.1.1 Experimental Verification
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0HavenMoonVR_Patcher.ps1" -Mode Verify %*
echo.
pause
