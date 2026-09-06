@echo off
setlocal EnableDelayedExpansion
title SultraByte AI Studio - Initializing Gateway

:: Memastikan Working Directory Terkunci ke Folder Skrip
cd /d "%~dp0"

:: Pengecekan Hak Akses Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Meminta eskalasi hak akses Administrator...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: 1. Menjalankan Smart Validator & Auto-Installer
echo [*] Memulai verifikasi lingkungan SultraByte AI Studio...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\file-requirement.ps1"

if %errorLevel% neq 0 (
    echo.
    echo [X] Terjadi kesalahan pada validasi environment.
    pause
    exit /b %errorLevel%
)

:: 2. Menjalankan Master Router TUI (Dengan Penahan Anti-Close)
echo [*] Membuka Master Router TUI...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\vault_manager.ps1"

if %errorLevel% neq 0 (
    echo.
    echo [!] SultraByte Master Router terhenti.
    pause
)