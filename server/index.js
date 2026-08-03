import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import { v4 as uuidv4 } from 'uuid';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import crypto from 'crypto';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
const port = process.env.PORT || 7777;
// Default to loopback only. Set HOST=0.0.0.0 (or a specific interface IP,
// e.g. the Tailscale IP) to accept connections from other machines.
const host = process.env.HOST || '127.0.0.1';
// Optional shared-secret auth. When SCRATCHPAD_TOKEN is set, all /api/*
// requests must include a matching X-Scratchpad-Token header.
const authToken = process.env.SCRATCHPAD_TOKEN || null;

// Storage file for clipboard items
const dataFile = path.join(__dirname, '../data.json');

// Initialize data file
function ensureDataFile() {
  if (!fs.existsSync(dataFile)) {
    fs.writeFileSync(dataFile, JSON.stringify({ items: [] }, null, 2));
  }
}

function readData() {
  try {
    const data = fs.readFileSync(dataFile, 'utf8');
    return JSON.parse(data);
  } catch {
    return { items: [] };
  }
}

function writeData(data) {
  fs.writeFileSync(dataFile, JSON.stringify(data, null, 2));
}

// Allowed origin hostnames: localhost/LAN/tailscale addresses only.
// Tailscale assigns addresses from the 100.64.0.0/10 CGNAT range, not RFC1918,
// so it needs its own pattern alongside the private LAN ranges.
// Each pattern is anchored with ^...$ against the *parsed hostname only*
// (never the raw origin string), so "localhost.evil.com" or "10.evil.com"
// cannot pass by matching a prefix and appending an attacker-controlled suffix.
const ALLOWED_HOSTNAME_PATTERNS = [
  /^localhost$/i,
  /^127\.0\.0\.1$/,
  /^192\.168\.\d{1,3}\.\d{1,3}$/,
  /^10\.\d{1,3}\.\d{1,3}\.\d{1,3}$/,
  /^172\.(1[6-9]|2[0-9]|3[01])\.\d{1,3}\.\d{1,3}$/,
  /^100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.\d{1,3}\.\d{1,3}$/,
  /^\[?[a-f0-9]*::[a-f0-9:]*\]?$/i
];

function isAllowedOrigin(origin) {
  if (!origin) return true;
  let hostname;
  try {
    hostname = new URL(origin).hostname;
  } catch {
    return false;
  }
  return ALLOWED_HOSTNAME_PATTERNS.some(pattern => pattern.test(hostname));
}

// Middleware
app.use(cors({
  origin: function(origin, callback) {
    if (isAllowedOrigin(origin)) {
      callback(null, true);
    } else {
      callback(new Error('CORS not allowed'));
    }
  }
}));
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

// Security headers
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Content-Security-Policy', "default-src 'self'; script-src 'self'; object-src 'none'; style-src 'self' 'unsafe-inline'; img-src 'self' data:");
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  next();
});

// Serve static files (frontend)
app.use(express.static(path.join(__dirname, '../public')));

// Shared-secret auth (optional). No-op when SCRATCHPAD_TOKEN is unset so the
// simple local install path keeps working without any token.
function requireToken(req, res, next) {
  if (!authToken) return next();

  const provided = req.headers['x-scratchpad-token'] || '';
  const expected = Buffer.from(authToken);
  const actual = Buffer.from(String(provided));

  if (expected.length === actual.length && crypto.timingSafeEqual(expected, actual)) {
    return next();
  }

  return res.status(401).json({ error: 'Unauthorized' });
}

app.use('/api', requireToken);

// API Routes

// Get all items
app.get('/api/items', (req, res) => {
  const data = readData();
  res.json(data.items.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
});

// Validate item content based on type
function validateItem(content, type) {
  if (!content || !type) {
    return { valid: false, error: 'content and type required' };
  }

  // Constrain type to enum
  if (!['text', 'image'].includes(type)) {
    return { valid: false, error: 'type must be "text" or "image"' };
  }

  // For images, validate it's a data URI with base64 image content
  if (type === 'image') {
    const imageRegex = /^data:image\/(png|jpe?g|gif|webp);base64,[A-Za-z0-9+/=]+$/;
    if (!imageRegex.test(content)) {
      return { valid: false, error: 'image must be base64-encoded data URI (png, jpg, gif, webp only)' };
    }
  }

  return { valid: true };
}

// Create new item
app.post('/api/items', (req, res) => {
  const { content, type } = req.body;

  const validation = validateItem(content, type);
  if (!validation.valid) {
    return res.status(400).json({ error: validation.error });
  }

  const data = readData();
  const item = {
    id: uuidv4(),
    content,
    type,
    createdAt: new Date().toISOString(),
    hostname: process.env.HOSTNAME || 'unknown'
  };

  data.items.unshift(item);

  // Keep only last 100 items
  if (data.items.length > 100) {
    data.items = data.items.slice(0, 100);
  }

  writeData(data);
  res.json(item);
});

// Get single item
app.get('/api/items/:id', (req, res) => {
  const data = readData();
  const item = data.items.find(i => i.id === req.params.id);

  if (!item) {
    return res.status(404).json({ error: 'Item not found' });
  }

  res.json(item);
});

// Delete item
app.delete('/api/items/:id', (req, res) => {
  const data = readData();
  data.items = data.items.filter(i => i.id !== req.params.id);
  writeData(data);
  res.json({ success: true });
});

// Clear all items
app.post('/api/clear', (req, res) => {
  writeData({ items: [] });
  res.json({ success: true });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

ensureDataFile();

app.listen(port, host, () => {
  console.log(`Scratchpad server running on http://${host}:${port}`);
  console.log(`Data stored in ${dataFile}`);
  console.log(authToken ? 'Shared-secret auth: ENABLED (SCRATCHPAD_TOKEN required on /api/*)' : 'Shared-secret auth: disabled (set SCRATCHPAD_TOKEN to enable)');
});
