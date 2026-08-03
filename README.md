# 📋 Scratchpad - Network Clipboard

A simple, open-source app to share text and screenshots across computers on a Tailscale network. No more emailing yourself files back and forth!

## Features

- **Cross-platform**: Works on macOS, Linux, and Windows
- **Tailscale integration**: Securely share within your private network
- **Simple web UI**: Beautiful, responsive interface accessible from any browser
- **Text & Images**: Share both text snippets and screenshots
- **One-command install**: Single installer for each platform
- **Zero config**: Just run and it works

## Quick Start

### Installation

#### macOS & Linux

```bash
bash install.sh
```

#### Windows

Double-click `install.bat` or run from Command Prompt:
```cmd
install.bat
```

Both installers will:
1. Check for Node.js (and guide you to install if needed)
2. Install dependencies
3. Show you how to start the server

### Running the Server

#### macOS & Linux
```bash
npm start
```

#### Windows
```cmd
npm start
```

The server will start on `http://localhost:7777`

### Accessing from Other Computers

1. Make sure all computers are on the same Tailscale network
2. Find your computer's Tailscale IP:
   - **macOS/Linux**: `tailscale ip -4`
   - **Windows**: `tailscale ip -4` (in PowerShell or Command Prompt)
3. Access the app from another computer:
   ```
   http://<tailscale-ip>:7777
   ```

### Custom Port

#### macOS & Linux
```bash
PORT=8080 npm start
```

#### Windows
```cmd
set PORT=8080
npm start
```

## How to Use

1. **Add Text**: Paste or type text and click "Add Text"
2. **Upload Image**: Click "Upload Image" and select a screenshot or image
3. **Copy**: Click "Copy" on any item to copy it to your clipboard
4. **Copy Last**: Quickly copy the most recent item
5. **Delete**: Remove individual items
6. **Clear All**: Empty the entire clipboard (with confirmation)

## System Requirements

- **Node.js 16+** ([install here](https://nodejs.org/)) - Required for all platforms
  - Installers automatically detect if Node.js is missing and provide installation links
- **Tailscale** (optional, but recommended for network security)
  - Install from [tailscale.com/download](https://tailscale.com/download)
  - All three installers work on the same Tailscale network regardless of OS

## Architecture

- **Backend**: Node.js + Express.js
- **Frontend**: Vanilla HTML/CSS/JavaScript
- **Storage**: JSON file (auto-persisted)
- **Limit**: Keeps last 100 items

## API Endpoints

### Get All Items
```
GET /api/items
```

### Add Item
```
POST /api/items
Content-Type: application/json

{
  "content": "text or base64 image data",
  "type": "text" or "image"
}
```

### Get Single Item
```
GET /api/items/:id
```

### Delete Item
```
DELETE /api/items/:id
```

### Clear All
```
POST /api/clear
```

### Health Check
```
GET /health
```

## Data Storage

- Items are stored in `data.json` in the app directory
- Automatically keeps the last 100 items
- Each item includes a timestamp and source hostname

## Installation Details by Platform

### Windows Specific Notes

The `install.bat` script:
- Checks for Node.js installation
- Automatically downloads dependencies via npm
- Shows clear error messages if Node.js is missing
- Works from any directory on your system
- Can be run multiple times safely

**To use install.bat:**
1. Download or clone the repository
2. Right-click `install.bat` and select "Run as administrator" (or double-click)
3. Follow the on-screen instructions
4. Once complete, use `npm start` to run the server

### macOS & Linux Specific Notes

The `install.sh` script:
- Detects your OS and Linux distribution
- Provides OS-specific installation instructions for dependencies
- Handles bash and zsh shells
- Works on Debian, Ubuntu, Fedora, Arch, and other distributions

**To use install.sh:**
```bash
bash install.sh
```

## Development

To run in watch mode with auto-reload (all platforms):
```bash
npm run dev
```

## License

MIT

## Troubleshooting

### Can't access from other computers?

1. Check Tailscale is running: `tailscale status`
2. Verify the IP: `tailscale ip -4`
3. Check firewall isn't blocking port 7777
4. Try using the Tailscale IP instead of hostname

### Port already in use?

```bash
PORT=8080 npm start
```

### Images not showing?

Clear your browser cache (Ctrl+Shift+Delete or Cmd+Shift+Delete)

## Contributing

This is an open-source project. Feel free to fork, modify, and submit PRs!

---

Made with ❤️ for the Tailscale community
