import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import { v4 as uuidv4 } from 'uuid';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
const port = process.env.PORT || 7777;

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

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

// Serve static files (frontend)
app.use(express.static(path.join(__dirname, '../public')));

// API Routes

// Get all items
app.get('/api/items', (req, res) => {
  const data = readData();
  res.json(data.items.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
});

// Create new item
app.post('/api/items', (req, res) => {
  const { content, type } = req.body;

  if (!content || !type) {
    return res.status(400).json({ error: 'content and type required' });
  }

  const data = readData();
  const item = {
    id: uuidv4(),
    content,
    type, // 'text' or 'image'
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

app.listen(port, () => {
  console.log(`Scratchpad server running on http://localhost:${port}`);
  console.log(`Data stored in ${dataFile}`);
});
