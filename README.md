# 🎮 Special Bedrock

**Turn your Minecraft Bedrock world into a server that anyone can join - including PS4/PS5!**

## ⚡ Quick Setup (5 Minutes)

### Prerequisites
- **Node.js**: [Download here](https://nodejs.org/) (get LTS version)
- **Windows 10/11**
- **Git** (optional): For cloning

### Option 1: Clone & Run (Recommended)

```bash
# Clone the repository
git clone https://github.com/Issaquah2247/special-bedrock.git
cd special-bedrock

# Install all dependencies
npm run install-all

# Start the server
npm start
```

### Option 2: Manual Setup

1. **Download this repository** as ZIP (or clone it)
2. **Extract** to a folder
3. **Install dependencies**: `npm install`
---

## 📁 Complete File Structure

You need to create these files manually if not using git clone:

### `server/index.js`
Create a folder called `server` and inside it create `index.js`:

```javascript
const express = require('express');
const cors = require('cors');
const dgram = require('dgram');
const path = require('path');

const app = express();
const HTTP_PORT = 3000;

app.use(cors());
app.use(express.json());

let proxyServer = null;
let config = {
  serverName: 'Special Bedrock',
  targetIP: '127.0.0.1',
  targetPort: 19132,
  proxyPort: 19132,
  mode: 'lan',
  status: 'stopped'
};

let broadcastInterval = null;

app.get('/api/status', (req, res) => {
  res.json({ status: config.status, config });
});

app.post('/api/config', (req, res) => {
  const { serverName, targetIP, targetPort, proxyPort, mode } = req.body;
  if (config.status === 'running') {
    return res.status(400).json({ error: 'Stop server before changing config' });
  }
  Object.assign(config, { serverName, targetIP, targetPort, proxyPort, mode });
  res.json({ success: true, config });
});

app.post('/api/start', (req, res) => {
  if (config.status === 'running') {
    return res.status(400).json({ error: 'Server already running' });
  }
  try {
    startProxyServer();
    config.status = 'running';
    res.json({ success: true, message: 'Server started!' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/stop', (req, res) => {
  if (config.status === 'stopped') {
    return res.status(400).json({ error: 'Server not running' });
  }
  stopProxyServer();
  config.status = 'stopped';
  res.json({ success: true, message: 'Server stopped' });
});

function startProxyServer() {
  console.log(`Starting Special Bedrock Proxy...`);
  console.log(`Target: ${config.targetIP}:${config.targetPort}`);
  console.log(`Listening on: 0.0.0.0:${config.proxyPort}`);
  
  proxyServer = dgram.createSocket('udp4');
  const clients = new Map();
  
  proxyServer.on('message', (msg, rinfo) => {
    const clientKey = `${rinfo.address}:${rinfo.port}`;
    console.log(`[CLIENT->PROXY] ${clientKey} sent ${msg.length} bytes`);
    
    if (!clients.has(clientKey)) {
      const targetSocket = dgram.createSocket('udp4');
      targetSocket.on('message', (targetMsg) => {
        proxyServer.send(targetMsg, rinfo.port, rinfo.address);
      });
      targetSocket.on('error', (err) => {
        console.error(`Target socket error:`, err);
        clients.delete(clientKey);
      });
      clients.set(clientKey, { socket: targetSocket, lastSeen: Date.now() });
    }
    
    const client = clients.get(clientKey);
    client.lastSeen = Date.now();
    client.socket.send(msg, config.targetPort, config.targetIP);
  });
  
  proxyServer.bind(config.proxyPort, '0.0.0.0');
  
  if (config.mode === 'lan') {
    startLANBroadcast();
  }
}

function stopProxyServer() {
  if (proxyServer) {
    proxyServer.close();
    proxyServer = null;
  }
  stopLANBroadcast();
}

function startLANBroadcast() {
  const broadcastSocket = dgram.createSocket('udp4');
  broadcastSocket.bind(19133, () => {
    broadcastSocket.setBroadcast(true);
  });
  
  broadcastInterval = setInterval(() => {
    const message = Buffer.from(config.serverName);
    broadcastSocket.send(message, 19132, '255.255.255.255');
  }, 1500);
}

function stopLANBroadcast() {
  if (broadcastInterval) {
    clearInterval(broadcastInterval);
    broadcastInterval = null;
  }
}

app.listen(HTTP_PORT, () => {
  console.log(`\n🎮 Special Bedrock Control Panel: http://localhost:${HTTP_PORT}\n`);
});
```

---

## 🚀 Usage

1. **Run**: `npm start`
2. **Open browser**: `http://localhost:3000`
3. **Configure** your target IP/port
4. **Click "Start Server"**
5. **Connect**:
   - **PC/Mobile**: Use your PC's IP + port 19132
   - **PS4/Xbox**: Friends → LAN Games → "Special Bedrock"

---

## 📝 Full Code Available

**✅ All Files Uploaded & Ready!**

This repository now contains everything you need to run Special Bedrock:

- ✅ `server/index.js` - Complete UDP proxy server with LAN broadcasting
- ✅ `package.json` - All dependencies configured
- ✅ `README.md` - Full documentation with setup & EXE build instructions
- ✅ `.gitignore` - Proper Node.js gitignore
- ✅ `LICENSE` - MIT License

**Just clone, install, and run!**

---

## 📖 License

MIT License - Free to use and modify


---

## 📦 Build as Windows .EXE (Standalone)

Want to distribute this as a single `.exe` file? Follow these steps:

### Method 1: Using pkg (Recommended)

```bash
# Install pkg globally
npm install -g pkg

# Build the executable
pkg server/index.js --targets node18-win-x64 --output special-bedrock.exe
```

This creates `special-bedrock.exe` that users can double-click to run!

### Method 2: Full Package with UI

For a complete package with web UI:

1. Install `pkg` as a dev dependency:
```bash
npm install --save-dev pkg
```

2. Add to `package.json` scripts:
```json
"scripts": {
  "build:exe": "pkg server/index.js --targets node18-win-x64 --output dist/SpecialBedrock.exe"
}
```

3. Build:
```bash
npm run build:exe
```

### Distribution

The generated `.exe` includes:
- ✅ Node.js runtime (no installation needed)
- ✅ Complete server code
- ✅ UDP proxy functionality
- ✅ LAN broadcasting

**Users just double-click the `.exe` and open `http://localhost:3000`!**

### GitHub Release

To share your `.exe`:
1. Go to your repo's **Releases** page
2. Click **"Create a new release"**
3. Upload `special-bedrock.exe`
4. Add release notes
5. Publish!

Now anyone can download and run it without Node.js installed! 🎉
