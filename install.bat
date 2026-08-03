@echo off
REM Scratchpad - Windows installation script
REM Installs and starts the scratchpad clipboard sharing app

setlocal enabledelayedexpansion

echo.
echo 🚀 Scratchpad - Network Clipboard Installation
echo =============================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed.
    echo.
    echo Please install Node.js from https://nodejs.org/ ^(v16 or later^)
    echo.
    echo After installing Node.js, run this script again.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('node -v') do set NODE_VERSION=%%i
echo ✓ Node.js found: %NODE_VERSION%

REM Check if npm is installed
where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ npm is not installed. Please install Node.js with npm.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('npm -v') do set NPM_VERSION=%%i
echo ✓ npm found: %NPM_VERSION%

REM Get the script directory
set SCRIPT_DIR=%~dp0
echo.
echo Installation directory: %SCRIPT_DIR%

REM Install dependencies
echo.
echo 📦 Installing dependencies...
cd /d "%SCRIPT_DIR%"
call npm install

if %errorlevel% neq 0 (
    echo.
    echo ❌ Error installing dependencies
    pause
    exit /b 1
)

set PORT=7777

echo.
echo ✅ Installation complete!
echo.
echo 🎉 To start the scratchpad server, run:
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
