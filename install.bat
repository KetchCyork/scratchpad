@echo off
chcp 65001 >nul
REM Scratchpad - Windows installation script
REM Installs and starts the scratchpad clipboard sharing app
REM
REM Run from a Command Prompt (cmd) OR PowerShell:
REM   cmd:         install.bat
REM   PowerShell:  .\install.bat   (PowerShell will not run a script from the
REM                                 current folder without the leading .\ )

setlocal enabledelayedexpansion

echo.
echo == Scratchpad - Network Clipboard Installation ==
echo =================================================
echo.

REM Check if Node.js is installed (node --version is more reliable than "where")
node --version >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Node.js is not installed.
    echo.
    echo Please install Node.js from https://nodejs.org/ ^(v16 or later^)
    echo.
    echo After installing Node.js, close this window, open a new one, and run this script again.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('node -v') do set NODE_VERSION=%%i
echo [OK] Node.js found: %NODE_VERSION%

REM Check if npm is installed
npm --version >nul 2>nul
if errorlevel 1 (
    echo [ERROR] npm is not installed. Please install Node.js with npm.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('npm -v') do set NPM_VERSION=%%i
echo [OK] npm found: %NPM_VERSION%

REM Get the script directory (the folder this .bat lives in)
set SCRIPT_DIR=%~dp0
echo.
echo Installation directory: %SCRIPT_DIR%

REM Install dependencies
echo.
echo Installing dependencies...
cd /d "%SCRIPT_DIR%"
call npm install
if errorlevel 1 (
    echo.
    echo [ERROR] Error installing dependencies
    pause
    exit /b 1
)

set PORT=7777

echo.
echo [OK] Installation complete!
echo.
echo To start the scratchpad server, run:
echo.
echo    cd %SCRIPT_DIR%
echo    npm start
echo.
echo The app will be available at: http://localhost:%PORT%
echo By default it only binds to 127.0.0.1 ^(this machine only^).
echo.
echo To access from other computers on your Tailscale network:
echo 1. Make sure all computers are on the same Tailscale network
echo 2. Find your computer's Tailscale IP ^(run: tailscale ip -4^)
echo 3. Start the server bound to that IP: set HOST=^<tailscale-ip^> ^& npm start
echo 4. Access the app at: http^://^<tailscale-ip^>:%PORT%
echo.
echo Optional environment variables:
echo    set PORT=8080 ^& npm start                   # Use custom port
echo    set HOSTNAME=mycomputer ^& npm start          # Set custom hostname
echo    set HOST=^<tailscale-ip^> ^& npm start         # Allow LAN/tailnet access (default: 127.0.0.1 only)
echo    set SCRATCHPAD_TOKEN=^<secret^> ^& npm start   # Require a shared-secret token on /api/* requests
echo.
echo See README.md 'Network Binding ^& Access Control' for details and tradeoffs.
echo.
pause
