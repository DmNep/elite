@echo off
title ELITE
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Elite.ps1"
if errorlevel 1 (
    echo.
    echo The game stopped because of an error.
    pause
)
