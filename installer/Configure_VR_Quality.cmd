@echo off
title HavenMoonVR 1.1 Experimental VR Quality
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0HavenMoonVR_VRQuality.ps1"
set "HMVR_EXIT=%ERRORLEVEL%"
echo.
if not "%HMVR_EXIT%"=="0" echo Exit code: %HMVR_EXIT%
pause
