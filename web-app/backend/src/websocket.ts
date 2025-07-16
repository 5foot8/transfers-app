import { WebSocketServer, WebSocket } from 'ws';
import { PrismaClient } from '@prisma/client';

interface WebSocketMessage {
  type: string;
  data: any;
}

export const websocketHandler = (wss: WebSocketServer, prisma: PrismaClient) => {
  console.log('🔌 WebSocket server initialized');
  
  wss.on('connection', (ws: WebSocket) => {
    console.log('🔗 New WebSocket connection');
    
    // Send initial data
    ws.send(JSON.stringify({
      type: 'connected',
      data: { message: 'Connected to Flight Transfers WebSocket' }
    }));
    
    ws.on('message', async (message: string) => {
      try {
        const parsedMessage: WebSocketMessage = JSON.parse(message);
        
        switch (parsedMessage.type) {
          case 'subscribe_flights':
            // Send current flight data
            const [incomingFlights, outgoingFlights] = await Promise.all([
              prisma.incomingFlight.findMany({
                include: {
                  outgoingLinks: {
                    include: {
                      outgoingFlight: true
                    }
                  }
                },
                orderBy: { scheduledTime: 'asc' }
              }),
              prisma.outgoingFlight.findMany({
                include: {
                  incomingLinks: {
                    include: {
                      incomingFlight: true
                    }
                  },
                  bagsFromIncoming: true
                },
                orderBy: { scheduledTime: 'asc' }
              })
            ]);
            
            ws.send(JSON.stringify({
              type: 'flights_update',
              data: { incomingFlights, outgoingFlights }
            }));
            break;
            
          case 'subscribe_workflow':
            // Send current workflow data
            const workflowFlights = await prisma.incomingFlight.findMany({
              where: {
                OR: [
                  { collectedTime: { not: null } },
                  { screeningStartTime: { not: null } },
                  { deliveredTime: { not: null } }
                ]
              },
              include: {
                outgoingLinks: {
                  include: {
                    outgoingFlight: true
                  }
                }
              },
              orderBy: { scheduledTime: 'asc' }
            });
            
            ws.send(JSON.stringify({
              type: 'workflow_update',
              data: { flights: workflowFlights }
            }));
            break;
            
          default:
            console.log('Unknown message type:', parsedMessage.type);
        }
      } catch (error) {
        console.error('Error handling WebSocket message:', error);
        ws.send(JSON.stringify({
          type: 'error',
          data: { message: 'Invalid message format' }
        }));
      }
    });
    
    ws.on('close', () => {
      console.log('🔌 WebSocket connection closed');
    });
    
    ws.on('error', (error) => {
      console.error('WebSocket error:', error);
    });
  });
  
  // Broadcast function to send updates to all connected clients
  const broadcast = (message: WebSocketMessage) => {
    wss.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify(message));
      }
    });
  };
  
  // Export broadcast function for use in other parts of the app
  (global as any).broadcastFlightUpdate = (type: string, data: any) => {
    broadcast({ type, data });
  };
  
  return { broadcast };
}; 