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

#### macOS & Linux — one command

Paste this into a terminal. It fetches the code into `~/scratchpad`, installs
dependencies, and tells you how to start the server. No manual clone needed:

```bash
curl -fsSL https://raw.githubusercontent.com/KetchCyork/scratchpad/main/install.sh | bash
```

> **Got `install.sh: command not found`?** That happens when `install.sh` is
> typed as a bare command. Use the one-liner above, or if you've already cloned
> the repo, run it *through* bash from inside the folder: `bash install.sh`
> (not `install.sh` or `./install.sh` without the `bash` prefix).

Prefer to clone first? That works too:

```bash
git clone https://github.com/KetchCyork/scratchpad.git
cd scratchpad
bash install.sh
```

#### Windows

**Recommended — one-line install (PowerShell):** paste this into a PowerShell
window. It clones into `%USERPROFILE%\scratchpad`, installs dependencies, and
prints how to start the server. This avoids the `.\` prompt and console-encoding
quirks of the `.bat` file.
```powershell
powershell -c "irm https://raw.githubusercontent.com/KetchCyork/scratchpad/main/install.ps1 | iex"
```

**Or, from a cloned repo:**
- **Command Prompt (cmd):** `install.bat`
- **PowerShell:** `.\install.bat` — PowerShell will not run a script from the
  current folder without the leading `.\`. (If you type just `install.bat` it
  reports *"not recognized as the name of a cmdlet..."* — add `.\`.)

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

The server will start on `http://127.0.0.1:7777` — reachable only from the same machine by default.

### Accessing from Other Computers

See [Network Binding & Access Control](#network-binding--access-control) below for how to expose the server to your Tailscale network (or LAN) and optionally require a shared-secret token.

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

### Network Binding & Access Control

By default the server binds to `127.0.0.1` (loopback only) — **it is not reachable from any other machine, even on your LAN or tailnet, unless you explicitly opt in.**

#### Allow access from other machines on your Tailscale network (recommended)

Bind to your Tailscale IP specifically, so only tailnet traffic reaches the server:

```bash
# macOS/Linux
HOST=$(tailscale ip -4) npm start
```
```cmd
:: Windows (PowerShell)
$env:HOST = (tailscale ip -4); npm start
```

#### Allow access from any interface (less safe)

```bash
HOST=0.0.0.0 npm start
```

**Tradeoff:** binding to `0.0.0.0` exposes the clipboard to *every* network the machine is connected to — including shared/public wifi (coffee shops, offices, airports), not just your tailnet. Prefer binding to the Tailscale IP above unless you have another network-level control (firewall rules) in place. If you must expose the server beyond your tailnet, enable the shared-secret token below.

#### Optional shared-secret token

For defense-in-depth beyond network binding, set `SCRATCHPAD_TOKEN` to require a matching token on every `/api/*` request (including clear/delete):

```bash
# macOS/Linux
SCRATCHPAD_TOKEN=your-long-random-secret npm start
```
```cmd
:: Windows
set SCRATCHPAD_TOKEN=your-long-random-secret
npm start
```

When set, every API client (including the web UI itself) must send it as a header:

```
X-Scratchpad-Token: your-long-random-secret
```

The web UI handles this automatically: on a `401` it prompts you for the token once and remembers it in the browser's `localStorage` for subsequent requests. Leave `SCRATCHPAD_TOKEN` unset to keep the zero-config local/tailnet flow.

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
2. Right-click `install.bat` and select "Run as administrator" (or double-click) —
   or if launching from a terminal, see below
3. Follow the on-screen instructions
4. Once complete, use `npm start` to run the server

> **Running from a terminal?** In **PowerShell** you must type `.\install.bat`
> (not just `install.bat`) or it fails with *"not recognized..."* — this is
> PowerShell's own current-directory rule, not a bug in the script. In
> **cmd.exe**, plain `install.bat` works fine.

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

1. Make sure you started the server with `HOST` set (see [Network Binding & Access Control](#network-binding--access-control)) — by default it only binds to `127.0.0.1` and won't accept connections from anywhere else.
2. Check Tailscale is running: `tailscale status`
3. Verify the IP: `tailscale ip -4`
4. Check firewall isn't blocking port 7777
5. If `SCRATCHPAD_TOKEN` is set, make sure the client is sending the matching `X-Scratchpad-Token` header
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
