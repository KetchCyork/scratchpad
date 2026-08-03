#!/bin/bash

# Scratchpad - Cross-platform installation script
# Installs the scratchpad clipboard sharing app.
#
# Two ways to run it:
#   1. One-line remote install (no clone needed):
#        curl -fsSL https://raw.githubusercontent.com/KetchCyork/scratchpad/main/install.sh | bash
#   2. From inside a cloned repo:
#        bash install.sh

set -e

REPO_URL="https://github.com/KetchCyork/scratchpad.git"
INSTALL_DIR="${SCRATCHPAD_DIR:-$HOME/scratchpad}"

echo "🚀 Scratchpad - Network Clipboard Installation"
echo "=============================================="

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS="linux"
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  OS="windows"
else
  OS="unknown"
fi

echo "Detected OS: $OS"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
  echo ""
  echo "❌ Node.js is not installed."
  echo ""
  echo "Please install Node.js from https://nodejs.org/ (v16 or later)"
  echo ""

  if [ "$OS" = "macos" ]; then
    echo "Or install using Homebrew: brew install node"
  elif [ "$OS" = "linux" ]; then
    if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
      echo "Or install using apt: sudo apt install nodejs npm"
    elif [[ "$DISTRO" == "fedora" ]]; then
      echo "Or install using dnf: sudo dnf install nodejs npm"
    elif [[ "$DISTRO" == "arch" ]]; then
      echo "Or install using pacman: sudo pacman -S nodejs npm"
    fi
  fi

  exit 1
fi

NODE_VERSION=$(node -v)
echo "✓ Node.js found: $NODE_VERSION"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
  echo "❌ npm is not installed. Please install Node.js with npm."
  exit 1
fi

NPM_VERSION=$(npm -v)
echo "✓ npm found: $NPM_VERSION"

# Figure out whether we are running from inside the repo (local run) or being
# piped through bash from curl (remote run). When piped, BASH_SOURCE is not a
# real file on disk, so we clone the repo ourselves.
SOURCE="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [ -n "$SOURCE" ] && [ -f "$SOURCE" ]; then
  SCRIPT_DIR="$( cd "$( dirname "$SOURCE" )" && pwd )"
fi

if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/package.json" ]; then
  # Running from inside a cloned repo
  TARGET_DIR="$SCRIPT_DIR"
  echo ""
  echo "Installing from local checkout: $TARGET_DIR"
else
  # Remote (curl | bash) run — we need git to fetch the code
  if ! command -v git &> /dev/null; then
    echo ""
    echo "❌ git is required for the one-line remote install."
    echo "   Install git, or clone the repo manually and run 'bash install.sh' from inside it:"
    echo "     git clone $REPO_URL"
    echo "     cd scratchpad && bash install.sh"
    exit 1
  fi

  # Recover IN PLACE — never move or delete the target folder. The user's shell
  # may be CWD'd inside it, which makes a move fail (and rm surprising). Instead
  # turn whatever is at $INSTALL_DIR into a clean origin/main checkout without
  # relocating it. data.json is gitignored, so the saved clipboard survives.
  if [ -d "$INSTALL_DIR/.git" ]; then
    echo ""
    echo "📥 Updating existing checkout at $INSTALL_DIR ..."
    git -C "$INSTALL_DIR" remote set-url origin "$REPO_URL" 2>/dev/null \
      || git -C "$INSTALL_DIR" remote add origin "$REPO_URL"
  elif [ -e "$INSTALL_DIR" ]; then
    echo ""
    echo "🔧 Repairing existing folder in place: $INSTALL_DIR ..."
    git init "$INSTALL_DIR" >/dev/null
    git -C "$INSTALL_DIR" remote remove origin 2>/dev/null || true
    git -C "$INSTALL_DIR" remote add origin "$REPO_URL"
  else
    echo ""
    echo "📥 Cloning Scratchpad into $INSTALL_DIR ..."
    git init "$INSTALL_DIR" >/dev/null
    git -C "$INSTALL_DIR" remote add origin "$REPO_URL"
  fi

  if ! git -C "$INSTALL_DIR" fetch origin; then
    echo "❌ git fetch failed. Check your network connection and try again."
    exit 1
  fi
  git -C "$INSTALL_DIR" checkout -B main origin/main --force
  git -C "$INSTALL_DIR" reset --hard origin/main
  TARGET_DIR="$INSTALL_DIR"
fi

# Guard: never run npm install without a package.json.
if [ ! -f "$TARGET_DIR/package.json" ]; then
  echo ""
  echo "❌ package.json not found in $TARGET_DIR - the install is incomplete."
  echo "   Remove that folder and re-run the installer:"
  echo "     rm -rf \"$TARGET_DIR\""
  exit 1
fi

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
cd "$TARGET_DIR"
npm install

# Determine port (default 7777)
PORT=${SCRATCHPAD_PORT:-7777}

echo ""
echo "✅ Installation complete!"
echo ""
echo "🎉 To start the scratchpad server, run:"
echo ""
echo "   cd $TARGET_DIR"
echo "   npm start"
echo ""
echo "The app will be available at: http://localhost:$PORT"
echo "By default it only binds to 127.0.0.1 (this machine only)."
echo ""
echo "To access from other computers on your Tailscale network:"
echo "1. Make sure all computers are on the same Tailscale network"
echo "2. Find your computer's Tailscale IP (run: tailscale ip -4)"
echo "3. Start the server bound to that IP: HOST=<tailscale-ip> npm start"
echo "4. Access the app at: http://<tailscale-ip>:$PORT"
echo ""
echo "Optional environment variables:"
echo "   PORT=8080 npm start                      # Use custom port"
echo "   HOSTNAME=mycomputer npm start             # Set custom hostname"
echo "   HOST=<tailscale-ip> npm start             # Allow LAN/tailnet access (default: 127.0.0.1 only)"
echo "   SCRATCHPAD_TOKEN=<secret> npm start        # Require a shared-secret token on /api/* requests"
echo ""
echo "See README.md 'Network Binding & Access Control' for details and tradeoffs."
echo ""
