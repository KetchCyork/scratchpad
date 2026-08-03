# 📋 Scratchpad - Network Clipboard

A simple, open-source app to share text and screenshots across computers on a Tailscale network. No more emailing yourself files back and forth!

## Features

- **Cross-platform**: Works on macOS, Linux, and Windows
- **Tailscale integration**: Securely share within your private network
- **Simple web UI**: Beautiful, responsive interface accessible from any browser
- **Text & Images**: Share both text snippets and screenshots
- **One-command install**: Single bash command to get started
- **Zero config**: Just run and it works

## Quick Start

### Installation

```bash
bash install.sh
```

This will:
1. Check for Node.js (and guide you to install if needed)
2. Install dependencies
3. Show you how to start the server

### Running the Server

```bash
npm start
```

The server will start on `http://localhost:7777`

### Accessing from Other Computers

1. Make sure all computers are on the same Tailscale network
2. Find your computer's Tailscale IP:
   ```bash
   tailscale ip -4
   ```
3. Access the app from another computer:
   ```
   http://<tailscale-ip>:7777
   ```

### Custom Port

```bash
PORT=8080 npm start
```

## How to Use

1. **Add Text**: Paste or type text and click "Add Text"
2. **Upload Image**: Click "Upload Image" and select a screenshot or image
3. **Copy**: Click "Copy" on any item to copy it to your clipboard
4. **Copy Last**: Quickly copy the most recent item
5. **Delete**: Remove individual items
6. **Clear All**: Empty the entire clipboard (with confirmation)

## System Requirements

- Node.js 16+ ([install here](https://nodejs.org/))
- Tailscale (optional, but recommended for network security)

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

## Development

To run in watch mode with auto-reload:
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
