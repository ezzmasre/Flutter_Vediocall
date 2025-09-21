const WebSocket = require('ws');
const http = require('http');

// Create HTTP server
const server = http.createServer();
const wss = new WebSocket.Server({ server });

// Store connected clients with room information
const clients = new Map(); // clientId -> { ws, username, roomId }
const rooms = new Map(); // roomId -> Set of clientIds
let clientId = 0;

console.log('WebSocket Chat Server Starting...');

wss.on('connection', function connection(ws, request) {
    const id = ++clientId;
    clients.set(id, { ws: ws, username: null, roomId: null });
    
    console.log(`Client ${id} connected. Total clients: ${clients.size}`);

    ws.on('message', function message(data) {
        try {
            const messageData = JSON.parse(data.toString());
            console.log(`Received from client ${id}:`, messageData);

            // Update client info when user joins a room
            if (messageData.type === 'join') {
                const client = clients.get(id);
                if (client) {
                    // Remove client from old room if they were in one
                    if (client.roomId) {
                        const oldRoom = rooms.get(client.roomId);
                        if (oldRoom) {
                            oldRoom.delete(id);
                            if (oldRoom.size === 0) {
                                rooms.delete(client.roomId);
                            }
                        }
                    }

                    client.username = messageData.username;
                    client.roomId = messageData.roomId;
                    
                    // Add client to new room
                    if (!rooms.has(messageData.roomId)) {
                        rooms.set(messageData.roomId, new Set());
                    }
                    rooms.get(messageData.roomId).add(id);
                    
                    console.log(`Client ${id} (${messageData.username}) joined room: ${messageData.roomId}`);
                    console.log(`Room ${messageData.roomId} now has ${rooms.get(messageData.roomId).size} members`);
                    
                    // Only broadcast join message to users in the SAME room
                    broadcastToRoom(messageData, messageData.roomId, id);
                }
                return; // Don't process join messages further
            }

            // For all other message types, only send to same room
            const client = clients.get(id);
            if (client && client.roomId && messageData.roomId === client.roomId) {
                console.log(`Broadcasting message from ${client.username} in room ${client.roomId}`);
                
                // Handle video call signaling messages
                if (['call-user', 'call-accepted', 'offer', 'answer', 'ice-candidate'].includes(messageData.type)) {
                    console.log(`Video call signaling: ${messageData.type} in room ${client.roomId}`);
                    // For call signaling, send to others in room (not including sender)
                    broadcastToRoom(messageData, client.roomId, id, true);
                } else {
                    // Regular chat messages
                    broadcastToRoom(messageData, client.roomId, id);
                }
            } else {
                console.log(`Message rejected: Client room (${client?.roomId}) doesn't match message room (${messageData.roomId})`);
            }

        } catch (error) {
            console.error('Error parsing message:', error);
        }
    });

    ws.on('close', function close() {
        const client = clients.get(id);
        if (client && client.username && client.roomId) {
            // Send leave message to other clients in the same room
            const leaveMessage = {
                type: 'leave',
                username: client.username,
                roomId: client.roomId,
                timestamp: Date.now()
            };
            broadcastToRoom(leaveMessage, client.roomId, id);
            
            // Remove client from room
            const roomClients = rooms.get(client.roomId);
            if (roomClients) {
                roomClients.delete(id);
                if (roomClients.size === 0) {
                    rooms.delete(client.roomId);
                    console.log(`Room ${client.roomId} deleted (empty)`);
                } else {
                    console.log(`Room ${client.roomId} now has ${roomClients.size} members`);
                }
            }
        }
        
        clients.delete(id);
        console.log(`Client ${id} disconnected. Total clients: ${clients.size}`);
    });

    ws.on('error', function error(err) {
        console.error(`WebSocket error for client ${id}:`, err);
        const client = clients.get(id);
        if (client && client.roomId) {
            const roomClients = rooms.get(client.roomId);
            if (roomClients) {
                roomClients.delete(id);
                if (roomClients.size === 0) {
                    rooms.delete(client.roomId);
                }
            }
        }
        clients.delete(id);
    });

    // Send welcome message
    ws.send(JSON.stringify({
        type: 'system',
        message: 'Connected to chat server',
        timestamp: Date.now()
    }));
});

function broadcastToRoom(messageData, roomId, senderId, excludeSender = false) {
    const messageString = JSON.stringify(messageData);
    const roomClients = rooms.get(roomId);
    
    if (!roomClients) {
        console.log(`Room ${roomId} not found`);
        return;
    }
    
    console.log(`Broadcasting to room ${roomId}:`, messageData);
    console.log(`Room ${roomId} has clients:`, Array.from(roomClients));
    
    let sentCount = 0;
    const disconnectedClients = [];
    
    roomClients.forEach(clientId => {
        // Skip sender if excludeSender is true (for video call signaling)
        if (excludeSender && clientId === senderId) {
            return;
        }
        
        const client = clients.get(clientId);
        if (client && client.ws.readyState === WebSocket.OPEN) {
            // Double check that the client is actually in this room
            if (client.roomId === roomId) {
                try {
                    client.ws.send(messageString);
                    sentCount++;
                    console.log(`Sent message to client ${clientId} (${client.username}) in room ${roomId}`);
                } catch (error) {
                    console.error(`Error sending message to client ${clientId}:`, error);
                    disconnectedClients.push(clientId);
                }
            } else {
                console.log(`Client ${clientId} room mismatch: expected ${roomId}, got ${client.roomId}`);
                disconnectedClients.push(clientId);
            }
        } else {
            console.log(`Client ${clientId} is disconnected, removing from room`);
            disconnectedClients.push(clientId);
        }
    });
    
    // Clean up disconnected clients
    disconnectedClients.forEach(clientId => {
        clients.delete(clientId);
        roomClients.delete(clientId);
    });
    
    // Clean up empty room
    if (roomClients.size === 0) {
        rooms.delete(roomId);
        console.log(`Room ${roomId} deleted (empty)`);
    }
    
    console.log(`Successfully sent message to ${sentCount} clients in room ${roomId}`);
}

// Keep the old function for backward compatibility (system messages)
function broadcastMessage(messageData, senderId) {
    const messageString = JSON.stringify(messageData);
    
    clients.forEach((client, id) => {
        if (client.ws.readyState === WebSocket.OPEN) {
            try {
                client.ws.send(messageString);
            } catch (error) {
                console.error(`Error sending message to client ${id}:`, error);
                clients.delete(id);
            }
        } else {
            // Remove disconnected clients
            clients.delete(id);
        }
    });
    
    console.log(`Broadcasted message to ${clients.size} clients`);
}

// Handle server shutdown gracefully
process.on('SIGTERM', () => {
    console.log('Shutting down server...');
    wss.close(() => {
        server.close(() => {
            process.exit(0);
        });
    });
});

process.on('SIGINT', () => {
    console.log('Shutting down server...');
    wss.close(() => {
        server.close(() => {
            process.exit(0);
        });
    });
});

// Start the server
const PORT = process.env.PORT || 8080;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`WebSocket Chat Server is running on port ${PORT}`);
    console.log(`Server address: ws://localhost:${PORT}`);
    console.log('Waiting for connections...');
});

// Optional: Add basic health check endpoint
server.on('request', (req, res) => {
    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: 'healthy',
            clients: clients.size,
            rooms: rooms.size,
            roomDetails: Array.from(rooms.entries()).map(([roomId, clientIds]) => ({
                roomId,
                members: clientIds.size
            })),
            uptime: process.uptime()
        }));
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});