'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useParams } from 'next/navigation';
import { useAuthStore } from '@/store/auth';
import { getChatRoom, getMessages, markMessagesAsRead, leaveChatRoom } from '@/lib/api/chat';
import { ChatWebSocket } from '@/lib/websocket/chat';
import { formatDateTime } from '@/lib/utils';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Button from '@/components/ui/Button';
import type { ChatRoom, Message } from '@/types';

function ChatRoomContent() {
  const router = useRouter();
  const params = useParams();
  const roomId = parseInt(params.id as string);

  const { user } = useAuthStore();

  const [room, setRoom] = useState<ChatRoom | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const wsRef = useRef<ChatWebSocket | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!roomId || isNaN(roomId)) {
      router.push('/chat');
      return;
    }

    loadChatRoom();
    loadMessages();

    // WebSocket 연결
    const token = localStorage.getItem('access_token');
    if (token) {
      const ws = new ChatWebSocket(roomId, token);
      ws.connect();

      ws.onMessage((data) => {
        if (data.type === 'message' && data.message) {
          setMessages((prev) => [...prev, data.message!]);
          scrollToBottom();
        }
      });

      wsRef.current = ws;
    }

    // 메시지 읽음 처리
    markMessagesAsRead(roomId);

    return () => {
      if (wsRef.current) {
        wsRef.current.disconnect();
      }
    };
  }, [roomId, router]);

  const loadChatRoom = async () => {
    try {
      const data = await getChatRoom(roomId);
      setRoom(data);
    } catch (error) {
      console.error('Failed to load chat room:', error);
      setError('채팅방을 불러오는데 실패했습니다.');
    } finally {
      setIsLoading(false);
    }
  };

  const loadMessages = async () => {
    try {
      const data = await getMessages(roomId);
      setMessages(data.results);
      scrollToBottom();
    } catch (error) {
      console.error('Failed to load messages:', error);
    }
  };

  const scrollToBottom = () => {
    setTimeout(() => {
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, 100);
  };

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!newMessage.trim() || !wsRef.current || isSending) {
      return;
    }

    setIsSending(true);

    try {
      wsRef.current.sendMessage(newMessage);
      setNewMessage('');
    } catch (error) {
      console.error('Failed to send message:', error);
      setError('메시지 전송에 실패했습니다.');
    } finally {
      setIsSending(false);
    }
  };

  const handleLeaveRoom = async () => {
    if (!confirm('채팅방을 나가시겠습니까?')) {
      return;
    }

    try {
      await leaveChatRoom(roomId);
      router.push('/chat');
    } catch (error) {
      console.error('Failed to leave room:', error);
      alert('채팅방 나가기에 실패했습니다.');
    }
  };

  const getOtherUser = () => {
    if (!room || !user) return null;
    return room.user1.id === user.id ? room.user2 : room.user1;
  };

  const otherUser = getOtherUser();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">로딩 중...</p>
        </div>
      </div>
    );
  }

  if (!room || !otherUser) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <p className="text-red-600">채팅방을 찾을 수 없습니다.</p>
          <Button onClick={() => router.push('/chat')} className="mt-4">
            채팅 목록으로
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-4 py-3 flex items-center justify-between sticky top-0 z-10">
        <div className="flex items-center gap-3">
          <button
            onClick={() => router.back()}
            className="text-gray-600 hover:text-gray-900"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white font-semibold">
            {otherUser.nickname[0].toUpperCase()}
          </div>
          <div>
            <h2 className="font-semibold text-gray-900">{otherUser.nickname}</h2>
            <p className="text-xs text-gray-500">{otherUser.country_code}</p>
          </div>
        </div>
        <button
          onClick={handleLeaveRoom}
          className="text-gray-600 hover:text-red-600"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg>
        </button>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-6 space-y-4">
        {error && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {messages.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-500">아직 메시지가 없습니다</p>
            <p className="text-sm text-gray-400 mt-2">첫 메시지를 보내보세요!</p>
          </div>
        ) : (
          messages.map((message) => {
            const isMyMessage = user && message.sender.id === user.id;

            return (
              <div
                key={message.id}
                className={`flex ${isMyMessage ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[70%] ${
                    isMyMessage
                      ? 'bg-blue-600 text-white rounded-l-2xl rounded-tr-2xl'
                      : 'bg-white text-gray-900 rounded-r-2xl rounded-tl-2xl shadow-sm'
                  } px-4 py-2`}
                >
                  {message.message_type === 'text' ? (
                    <p className="break-words">{message.content}</p>
                  ) : message.message_type === 'image' && message.image ? (
                    <div>
                      <img
                        src={message.image}
                        alt="Sent image"
                        className="rounded-lg max-w-full"
                      />
                      {message.content && (
                        <p className="mt-2 break-words">{message.content}</p>
                      )}
                    </div>
                  ) : (
                    <p className="text-gray-500 italic">{message.content}</p>
                  )}
                  <div className="flex items-center justify-end gap-2 mt-1">
                    <span
                      className={`text-xs ${
                        isMyMessage ? 'text-blue-200' : 'text-gray-500'
                      }`}
                    >
                      {new Date(message.created_at).toLocaleTimeString('ko-KR', {
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </span>
                    {isMyMessage && message.is_read && (
                      <span className="text-xs text-blue-200">읽음</span>
                    )}
                  </div>
                </div>
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <div className="bg-white border-t border-gray-200 px-4 py-3 sticky bottom-0">
        <form onSubmit={handleSendMessage} className="flex items-center gap-2">
          <input
            type="text"
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            placeholder="메시지를 입력하세요..."
            className="flex-1 px-4 py-2 border border-gray-300 rounded-full focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            disabled={isSending}
          />
          <button
            type="submit"
            disabled={!newMessage.trim() || isSending}
            className="flex-shrink-0 w-10 h-10 bg-blue-600 text-white rounded-full flex items-center justify-center hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {isSending ? (
              <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
            ) : (
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
              </svg>
            )}
          </button>
        </form>
      </div>
    </div>
  );
}

export default function ChatRoomPage() {
  return (
    <ProtectedRoute>
      <ChatRoomContent />
    </ProtectedRoute>
  );
}
