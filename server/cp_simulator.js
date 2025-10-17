const WebSocket = require('ws');
const uuid = require('uuid');

const chargePointIds = ['CP1', 'CP2', 'CP3']; // Все станции
const clients = new Map(); // chargePointId → ws

chargePointIds.forEach(chargePointId => {
    const ws = new WebSocket(`ws://localhost:8080/ocpp/${chargePointId}`);
    clients.set(chargePointId, ws);

    let currentStatus = 'Available';
    let transactionId = null;

    ws.on('open', () => {
        console.log(`${chargePointId} connected to CS`);
        const bootId = uuid.v4();
        ws.send(JSON.stringify([2, bootId, 'BootNotification', { chargePointVendor: 'Simulator', chargePointModel: 'Model1' }]));

        sendStatusNotification(1, 'NoError', currentStatus);
    });

    ws.on('message', (message) => {
        const [type, id, actionOrPayload, payload] = JSON.parse(message);
        if (type === 3) {
            console.log(`Response for ${id} on ${chargePointId}`);
        } else if (type === 2) {
            const action = actionOrPayload;
            if (action === 'RemoteStartTransaction') {
                ws.send(JSON.stringify([3, id, { status: 'Accepted' }]));
                currentStatus = 'Preparing';
                sendStatusNotification(payload.connectorId, 'NoError', currentStatus);
                setTimeout(() => {
                    currentStatus = 'Charging';
                    sendStatusNotification(payload.connectorId, 'NoError', currentStatus);
                    transactionId = 123;
                    const startId = uuid.v4();
                    ws.send(JSON.stringify([2, startId, 'StartTransaction', { connectorId: payload.connectorId, idTag: payload.idTag, meterStart: 0, timestamp: new Date().toISOString() }]));
                }, 2000);
            } else if (action === 'RemoteStopTransaction') {
                if (transactionId === payload.transactionId) {
                    ws.send(JSON.stringify([3, id, { status: 'Accepted' }]));
                    currentStatus = 'Finishing';
                    sendStatusNotification(1, 'NoError', currentStatus);
                    setTimeout(() => {
                        const stopId = uuid.v4();
                        ws.send(JSON.stringify([2, stopId, 'StopTransaction', { transactionId, meterStop: 100, timestamp: new Date().toISOString(), reason: 'Remote' }]));
                        currentStatus = 'Available';
                        sendStatusNotification(1, 'NoError', currentStatus);
                        transactionId = null;
                    }, 2000);
                } else {
                    ws.send(JSON.stringify([3, id, { status: 'Rejected' }]));
                }
            }
        }
    });

    function sendStatusNotification(connectorId, errorCode, status) {
        const msgId = uuid.v4();
        ws.send(JSON.stringify([2, msgId, 'StatusNotification', { connectorId, errorCode, status, timestamp: new Date().toISOString() }]));
    }

    // Heartbeat every 10s for this CP
    setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
            const hbId = uuid.v4();
            ws.send(JSON.stringify([2, hbId, 'Heartbeat', {}]));
        }
    }, 10000);
});