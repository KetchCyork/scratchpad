const API_URL = window.location.origin + '/api';

// Wraps fetch to attach the shared-secret token (if the server has one
// configured) and to prompt for it on a 401 so the UI stays usable when
// SCRATCHPAD_TOKEN is set.
async function apiFetch(url, options = {}) {
  const token = localStorage.getItem('scratchpadToken');
  const headers = { ...(options.headers || {}) };
  if (token) headers['X-Scratchpad-Token'] = token;

  const response = await fetch(url, { ...options, headers });
  if (response.status !== 401) return response;

  const entered = prompt('This server requires a Scratchpad token. Enter it:');
  if (!entered) return response;

  localStorage.setItem('scratchpadToken', entered);
  headers['X-Scratchpad-Token'] = entered;
  return fetch(url, { ...options, headers });
}

async function loadItems() {
  try {
    const response = await apiFetch(`${API_URL}/items`);
    const items = await response.json();
    renderItems(items);
  } catch (error) {
    console.error('Error loading items:', error);
  }
}

function renderItems(items) {
  const container = document.getElementById('itemsContainer');

  if (items.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <div class="empty-state-icon">📭</div>
        <h2>No items yet</h2>
        <p>Start by adding text or uploading an image</p>
      </div>
    `;
    return;
  }

  // Build DOM safely - never use innerHTML with user data
  container.innerHTML = '';
  items.forEach(item => {
    const card = document.createElement('div');
    card.className = 'item-card';

    const header = document.createElement('div');
    header.className = 'item-header';

    const typeLabel = document.createElement('span');
    typeLabel.className = 'item-type ' + (item.type === 'image' ? 'image' : 'text');
    typeLabel.textContent = item.type === 'image' ? '🖼️ Image' : '📝 Text';

    const timeLabel = document.createElement('span');
    timeLabel.className = 'item-time';
    timeLabel.textContent = new Date(item.createdAt).toLocaleTimeString();

    header.appendChild(typeLabel);
    header.appendChild(timeLabel);

    const content = document.createElement('div');
    content.className = 'item-content';

    if (item.type === 'image') {
      const img = document.createElement('img');
      img.src = item.content;
      img.alt = 'Shared image';
      content.appendChild(img);
    } else {
      const pre = document.createElement('pre');
      pre.textContent = item.content;
      content.appendChild(pre);
    }

    const hostname = document.createElement('div');
    hostname.className = 'hostname';
    hostname.textContent = 'From: ' + item.hostname;

    const footer = document.createElement('div');
    footer.className = 'item-footer';

    const copyBtn = document.createElement('button');
    copyBtn.className = 'btn-small btn-copy';
    copyBtn.textContent = 'Copy';
    copyBtn.onclick = () => copyItem(item.id, item.type);

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'btn-small btn-delete';
    deleteBtn.textContent = 'Delete';
    deleteBtn.onclick = () => deleteItem(item.id);

    footer.appendChild(copyBtn);
    footer.appendChild(deleteBtn);

    card.appendChild(header);
    card.appendChild(content);
    card.appendChild(hostname);
    card.appendChild(footer);

    container.appendChild(card);
  });
}

async function addText() {
  const text = document.getElementById('textInput').value.trim();

  if (!text) {
    showToast('Please enter some text');
    return;
  }

  try {
    const response = await apiFetch(`${API_URL}/items`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content: text, type: 'text' })
    });

    if (response.ok) {
      document.getElementById('textInput').value = '';
      showToast('Text added!');
      loadItems();
    }
  } catch (error) {
    showToast('Error adding text');
    console.error(error);
  }
}

async function addImage() {
  const input = document.getElementById('imageInput');
  const file = input.files[0];

  if (!file) return;

  const reader = new FileReader();
  reader.onload = async (e) => {
    try {
      const response = await apiFetch(`${API_URL}/items`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content: e.target.result, type: 'image' })
      });

      if (response.ok) {
        input.value = '';
        showToast('Image uploaded!');
        loadItems();
      }
    } catch (error) {
      showToast('Error uploading image');
      console.error(error);
    }
  };
  reader.readAsDataURL(file);
}

async function copyItem(itemId, type) {
  try {
    const response = await apiFetch(`${API_URL}/items/${itemId}`);
    const item = await response.json();

    if (type === 'text') {
      await navigator.clipboard.writeText(item.content);
    } else {
      // For images, we can't copy to clipboard directly in browser, but we can show a note
      showToast('Image copied to clipboard (if supported)');
      const img = new Image();
      img.src = item.content;
      img.onload = () => {
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0);
        canvas.toBlob(blob => {
          navigator.clipboard.write([
            new ClipboardItem({ 'image/png': blob })
          ]).catch(() => showToast('Image copied (browser limitation)'));
        });
      };
    }
    showToast(`${type === 'text' ? 'Text' : 'Image'} copied!`);
  } catch (error) {
    showToast('Error copying item');
    console.error(error);
  }
}

async function copyLastItem() {
  try {
    const response = await apiFetch(`${API_URL}/items`);
    const items = await response.json();
    if (items.length > 0) {
      await copyItem(items[0].id, items[0].type);
    } else {
      showToast('No items to copy');
    }
  } catch (error) {
    console.error(error);
  }
}

async function deleteItem(itemId) {
  try {
    await apiFetch(`${API_URL}/items/${itemId}`, { method: 'DELETE' });
    showToast('Item deleted');
    loadItems();
  } catch (error) {
    console.error(error);
  }
}

async function clearAll() {
  if (confirm('Are you sure you want to clear all items?')) {
    try {
      await apiFetch(`${API_URL}/clear`, { method: 'POST' });
      showToast('All items cleared');
      loadItems();
    } catch (error) {
      console.error(error);
    }
  }
}

function showToast(message) {
  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.textContent = message;
  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 3000);
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

document.getElementById('addTextBtn').addEventListener('click', addText);
document.getElementById('uploadImageBtn').addEventListener('click', () => {
  document.getElementById('imageInput').click();
});
document.getElementById('imageInput').addEventListener('change', addImage);
document.getElementById('copyLastBtn').addEventListener('click', copyLastItem);
document.getElementById('clearAllBtn').addEventListener('click', clearAll);

// Load items on page load
loadItems();

// Refresh items every 2 seconds
setInterval(loadItems, 2000);

// Allow Enter key to submit text
document.getElementById('textInput').addEventListener('keydown', (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
    addText();
  }
});
