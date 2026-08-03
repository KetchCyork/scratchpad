#!/bin/bash

# Scratchpad - Cross-platform installation script
# Installs and starts the scratchpad clipboard sharing app

set -e

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

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo ""
echo "Installation directory: $SCRIPT_DIR"

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
cd "$SCRIPT_DIR"
npm install

# Determine port (default 7777)
PORT=${SCRATCHPAD_PORT:-7777}

echo ""
echo "✅ Installation complete!"
echo ""
echo "🎉 To start the scratchpad server, run:"
echo ""
echo "   cd $SCRIPT_DIR"
echo "   npm start"
echo ""
echo "The app will be available at: http://localhost:$PORT"
echo ""
echo "To access from other computers on your Tailscale network:"
echo "1. Make sure all computers are on the same Tailscale network"
echo "2. Find your computer's Tailscale IP (run: tailscale ip -4)"
echo "3. Access the app at: http://<tailscale-ip>:$PORT"
echo ""
echo "Optional environment variables:"
echo "   PORT=8080 npm start        # Use custom port"
echo "   HOSTNAME=mycomputer npm start  # Set custom hostname"
echo ""
