const express = require('express');
const cors = require('cors');
const dgram = require('dgram');
const path = require('path');
const CheatManager = require('./cheats');

const app = express();
const HTTP_PORT = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

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

  // Cheat API endpoints
app.get('/api/cheats', (req, res) => {
  if (!proxyServer || !proxyServer.cheatManager) {
    return res.json({ active: [], available: getAllCheats() });
  }
  res.json({ 
    active: proxyServer.cheatManager.getActiveCommands(),
    available: getAllCheats()
  });
});

app.post('/api/cheats/toggle', (req, res) => {
  const { cheat, playerId } = req.body;
  if (!proxyServer || !proxyServer.cheatManager) {
    return res.status(400).json({ error: 'Server not running' });
  }
  // Toggle cheat logic here
  res.json({ success: true, cheat, enabled: true });
});

function getAllCheats() {
  return [
    { id: 'fly', name: 'Fly', description: 'Enable flight mode' },
    { id: 'speed', name: 'Speed', description: 'Movement speed multiplier' },
    { id: 'xray', name: 'X-Ray', description: 'See through blocks' },
    { id: 'reach', name: 'Reach', description: 'Extended reach distance' },
    { id: 'night', name: 'Night Vision', description: 'Permanent night vision' },
    { id: 'nofall', name: 'No Fall', description: 'Disable fall damage' },
    { id: 'killaura', name: 'Kill Aura', description: 'Auto-attack entities' },
    { id: 'autototem', name: 'Auto Totem', description: 'Auto-equip totem' },
    { id: 'fastbreak', name: 'Fast Break', description: 'Instant block breaking' },
    { id: 'step', name: 'Step', description: 'Increased step height' }
  ];
}
  console.log(`Listening on: 0.0.0.0:${config.proxyPort}`);
  
  proxyServer = dgram.createSocket('udp4');
  const clients = new Map();
    const cheatManager = new CheatManager();
  
  proxyServer.on('message', (msg, rinfo) => {
    const clientKey = `${rinfo.address}:${rinfo.port}`;
    console.log(`[CLIENT->PROXY] ${clientKey} sent ${msg.length} bytes`);

        // Inspect packet for cheat commands
    const processedMsg = cheatManager.inspectPacket(msg, rinfo);
    if (processedMsg !== msg) {
      // Command detected, send response packet back to client
      proxyServer.send(processedMsg, rinfo.port, rinfo.address);
      return; // Don't forward command packets to actual server
    }
    
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
  
  const cleanupInterval = setInterval(() => {
    const now = Date.now();
    for (const [key, client] of clients.entries()) {
      if (now - client.lastSeen > 30000) {
        console.log(`Cleaning up stale client: ${key}`);
        client.socket.close();
        clients.delete(key);
      }
    }
  }, 30000);
  
  proxyServer.cleanupInterval = cleanupInterval;
  proxyServer.clients = clients;
}

function stopProxyServer() {
    proxyServer.clients = clients;
  proxyServer.cheatManager = cheatManager;
  if (proxyServer) {
    console.log('Stopping proxy server...');
    if (proxyServer.clients) {
      for (const client of proxyServer.clients.values()) {
        client.socket.close();
      }
    }
    if (proxyServer.cleanupInterval) {
      clearInterval(proxyServer.cleanupInterval);
    }
    proxyServer.close();
    proxyServer = null;
  }
  stopLANBroadcast();
}

function startLANBroadcast() {
  console.log('Starting LAN broadcast for console discovery...');
  const broadcastSocket = dgram.createSocket('udp4');
  broadcastSocket.bind(19133, () => {
    broadcastSocket.setBroadcast(true);
  });
  
  broadcastInterval = setInterval(() => {
    const message = Buffer.from(config.serverName);
    broadcastSocket.send(message, 19132, '255.255.255.255', (err) => {
      if (err) console.error('Broadcast error:', err);
    });
  }, 1500);
  
  if (proxyServer) {
    proxyServer.broadcastSocket = broadcastSocket;
  }
}

function stopLANBroadcast() {
  if (broadcastInterval) {
    clearInterval(broadcastInterval);
    broadcastInterval = null;
  }
  if (proxyServer && proxyServer.broadcastSocket) {
    proxyServer.broadcastSocket.close();
  }
}

app.listen(HTTP_PORT, () => {
  console.log(`\n🎮 Special Bedrock Control Panel: http://localhost:${HTTP_PORT}\n`);
  console.log('Waiting for configuration... Open the web panel to get started!');
});
