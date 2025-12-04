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

1. **Download this repository** as ZIP
2. **Extract** to a folder
3. **Create the following files:**

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

**Due to GitHub's file upload limitations, clone this repo and I'll add all remaining files (React frontend, utilities, batch files) shortly.**

For now, the server code above will get you started!

---

## 📖 License

MIT License - Free to use and modify
