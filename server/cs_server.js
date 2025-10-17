const WebSocket = require('ws');
const express = require('express');
const uuid = require('uuid');
const app = express();
app.use(express.json());

const wss = new WebSocket.Server({ port: 8080 });
const clients = new Map(); // chargePointId -> ws client
const statuses = new Map(); // chargePointId -> status

wss.on('connection', (ws, req) => {
  const chargePointId = req.url.split('/')[2]; // e.g., /ocpp/CP1 -> CP1
  console.log(`CP connected: ${chargePointId}`);
  clients.set(chargePointId, ws);
  statuses.set(chargePointId, 'Available');

  ws.on('message', (message) => {
    const [type, id, action, payload] = JSON.parse(message);
    console.log(`Received from ${chargePointId}: ${action}`);

    if (type === 2) { // Call
      if (action === 'BootNotification') {
        ws.send(JSON.stringify([3, id, { status: 'Accepted' }]));
      } else if (action === 'Heartbeat') {
        ws.send(JSON.stringify([3, id, { currentTime: new Date().toISOString() }]));
      } else if (action === 'StatusNotification') {
        statuses.set(chargePointId, payload.status);
        ws.send(JSON.stringify([3, id, {}]));
      } else if (action === 'StartTransaction') {
        ws.send(JSON.stringify([3, id, { transactionId: 123, idTagInfo: { status: 'Accepted' } }]));
      } else if (action === 'StopTransaction') {
        ws.send(JSON.stringify([3, id, { idTagInfo: { status: 'Accepted' } }]));
      }
    }
  });

  ws.on('close', () => {
    clients.delete(chargePointId);
    statuses.delete(chargePointId);
    console.log(`CP disconnected: ${chargePointId}`);
  });
});

// REST API для Flutter
app.post('/remote-start', (req, res) => {
  const { chargePointId, connectorId, idTag } = req.body;
  const ws = clients.get(chargePointId);
  if (ws) {
    const msgId = uuid.v4();
    ws.send(JSON.stringify([2, msgId, 'RemoteStartTransaction', { connectorId, idTag }]));
    res.send({ success: true });
  } else {
    res.status(404).send({ error: 'CP not connected' });
  }
});

app.post('/remote-stop', (req, res) => {
  const { chargePointId, transactionId } = req.body;
  const ws = clients.get(chargePointId);
  if (ws) {
    const msgId = uuid.v4();
    ws.send(JSON.stringify([2, msgId, 'RemoteStopTransaction', { transactionId }]));
    res.send({ success: true });
  } else {
    res.status(404).send({ error: 'CP not connected' });
  }
});

app.get('/status', (req, res) => {
  const { chargePointId } = req.query;
  const status = statuses.get(chargePointId) || 'Unknown';
  res.send({ status });
});

app.listen(3000, () => console.log('CS REST API on http://localhost:3000'));