# Scratchpad - Windows PowerShell installation script
#
# One-line remote install (recommended on Windows - no clone, no .bat quirks):
#   powershell -c "irm https://raw.githubusercontent.com/KetchCyork/scratchpad/main/install.ps1 | iex"
#
# Or from inside a cloned repo:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1

$ErrorActionPreference = 'Stop'
$RepoUrl = 'https://github.com/KetchCyork/scratchpad.git'
$InstallDir = if ($env:SCRATCHPAD_DIR) { $env:SCRATCHPAD_DIR } else { Join-Path $HOME 'scratchpad' }

Write-Host '== Scratchpad - Network Clipboard Installation =='
Write-Host '================================================='

function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

# Check Node.js
if (-not (Test-Command node)) {
    Write-Host '[ERROR] Node.js is not installed.'
    Write-Host 'Please install Node.js from https://nodejs.org/ (v16 or later), then re-run this command.'
    exit 1
}
Write-Host "[OK] Node.js found: $(node -v)"

# Check npm
if (-not (Test-Command npm)) {
    Write-Host '[ERROR] npm is not installed. Please install Node.js with npm.'
    exit 1
}
Write-Host "[OK] npm found: $(npm -v)"

# Decide: running from inside a checkout, or remote (irm | iex)?
$scriptDir = $null
if ($PSCommandPath) { $scriptDir = Split-Path -Parent $PSCommandPath }

if ($scriptDir -and (Test-Path (Join-Path $scriptDir 'package.json'))) {
    $TargetDir = $scriptDir
    Write-Host "Installing from local checkout: $TargetDir"
} else {
    if (-not (Test-Command git)) {
        Write-Host '[ERROR] git is required for the one-line remote install.'
        Write-Host "Install git from https://git-scm.com/download/win, or clone manually:"
        Write-Host "  git clone $RepoUrl"
        Write-Host "  cd scratchpad; .\install.bat"
        exit 1
    }
    # A valid install must have BOTH a .git dir and a checked-out package.json.
    $isValidRepo = (Test-Path (Join-Path $InstallDir '.git')) -and (Test-Path (Join-Path $InstallDir 'package.json'))
    $updated = $false

    if ($isValidRepo) {
        Write-Host "Updating existing install at $InstallDir ..."
        # Do not rely on branch tracking info: a stale clone may be on 'master'
        # with no upstream, which breaks 'git pull'. Fetch and hard-reset to
        # origin/main instead. (data.json is gitignored, so user data is safe.)
        git -C $InstallDir fetch origin 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            git -C $InstallDir checkout -B main origin/main 2>&1 | Out-Null
            git -C $InstallDir reset --hard origin/main 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { $updated = $true }
        }
        if (-not $updated) {
            Write-Host '[WARN] Could not update the existing checkout; re-cloning a fresh copy.'
        }
    }

    if (-not $updated) {
        if (Test-Path $InstallDir) {
            $backup = "$InstallDir.bak"
            if (Test-Path $backup) { Remove-Item -Recurse -Force $backup }
            Write-Host "Moving aside existing folder: $InstallDir -> $backup"
            Move-Item -Force $InstallDir $backup
        }
        Write-Host "Cloning Scratchpad into $InstallDir ..."
        git clone $RepoUrl $InstallDir
        if ($LASTEXITCODE -ne 0) {
            Write-Host '[ERROR] git clone failed. Check your network connection and try again.'
            exit 1
        }
    }
    $TargetDir = $InstallDir
}

# Guard: never run npm install without a package.json (was the Windows failure).
if (-not (Test-Path (Join-Path $TargetDir 'package.json'))) {
    Write-Host "[ERROR] package.json not found in $TargetDir - the install is incomplete."
    Write-Host 'Remove that folder and re-run the installer:'
    Write-Host "  Remove-Item -Recurse -Force '$TargetDir'"
    exit 1
}

Write-Host 'Installing dependencies...'
Push-Location $TargetDir
npm install
$npmExit = $LASTEXITCODE
Pop-Location
if ($npmExit -ne 0) {
    Write-Host '[ERROR] npm install failed. See the npm output above for details.'
    exit 1
}

$Port = if ($env:SCRATCHPAD_PORT) { $env:SCRATCHPAD_PORT } else { '7777' }

Write-Host ''
Write-Host '[OK] Installation complete!'
Write-Host ''
Write-Host 'To start the scratchpad server, run:'
Write-Host "   cd $TargetDir"
Write-Host '   npm start'
Write-Host ''
Write-Host "The app will be available at: http://localhost:$Port"
Write-Host 'By default it only binds to 127.0.0.1 (this machine only).'
Write-Host ''
Write-Host 'To access from other computers on your Tailscale network:'
Write-Host '1. Make sure all computers are on the same Tailscale network'
Write-Host '2. Find your computer''s Tailscale IP (run: tailscale ip -4)'
Write-Host '3. Start bound to that IP (PowerShell): $env:HOST="<tailscale-ip>"; npm start'
Write-Host "4. Access the app at: http://<tailscale-ip>:$Port"
Write-Host ''
Write-Host 'Optional environment variables (PowerShell syntax):'
Write-Host '   $env:PORT="8080"; npm start                    # Use custom port'
Write-Host '   $env:HOST="<tailscale-ip>"; npm start           # Allow LAN/tailnet access'
Write-Host '   $env:SCRATCHPAD_TOKEN="<secret>"; npm start     # Require a shared-secret token'
