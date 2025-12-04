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
