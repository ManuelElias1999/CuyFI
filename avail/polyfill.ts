// WebSocket polyfill for Node.js
import { WebSocket } from 'ws';

(globalThis as any).WebSocket = WebSocket;

// Window polyfill for NexusSDK
if (typeof window === 'undefined') {
    (globalThis as any).window = {
        location: {
            protocol: 'https:',
            host: 'localhost:3000',
            origin: 'https://localhost:3000'
        }
    };
}
