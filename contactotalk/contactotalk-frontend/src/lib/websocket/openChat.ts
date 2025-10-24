import type { Message } from '@/types';

const WS_BASE_URL = process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:8000/ws';

interface OpenChatWebSocketMessage {
  type: 'message' | 'user_joined' | 'user_left' | 'user_kicked' | 'error';
  message?: Message;
  user?: {
    id: number;
    nickname: string;
  };
  error?: string;
}

type MessageHandler = (data: OpenChatWebSocketMessage) => void;

export class OpenChatWebSocket {
  private ws: WebSocket | null = null;
  private roomId: number;
  private token: string;
  private messageHandlers: MessageHandler[] = [];
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectInterval = 3000;

  constructor(roomId: number, token: string) {
    this.roomId = roomId;
    this.token = token;
  }

  connect(): void {
    const wsUrl = `${WS_BASE_URL}/open-chat/${this.roomId}/?token=${this.token}`;

    try {
      this.ws = new WebSocket(wsUrl);

      this.ws.onopen = () => {
        console.log('Open Chat WebSocket connected');
        this.reconnectAttempts = 0;
      };

      this.ws.onmessage = (event) => {
        try {
          const data: OpenChatWebSocketMessage = JSON.parse(event.data);
          this.messageHandlers.forEach((handler) => handler(data));
        } catch (error) {
          console.error('Failed to parse WebSocket message:', error);
        }
      };

      this.ws.onerror = (error) => {
        console.error('Open Chat WebSocket error:', error);
      };

      this.ws.onclose = () => {
        console.log('Open Chat WebSocket disconnected');
        this.attemptReconnect();
      };
    } catch (error) {
      console.error('Failed to create WebSocket:', error);
    }
  }

  private attemptReconnect(): void {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      console.log(`Reconnecting... Attempt ${this.reconnectAttempts}`);
      setTimeout(() => this.connect(), this.reconnectInterval);
    } else {
      console.error('Max reconnect attempts reached');
    }
  }

  sendMessage(content: string): void {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(
        JSON.stringify({
          type: 'message',
          content,
        })
      );
    } else {
      console.error('WebSocket is not connected');
    }
  }

  onMessage(handler: MessageHandler): void {
    this.messageHandlers.push(handler);
  }

  disconnect(): void {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
    this.messageHandlers = [];
  }
}
