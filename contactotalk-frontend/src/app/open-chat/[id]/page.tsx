'use client';

import { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useParams } from 'next/navigation';
import { useAuthStore } from '@/store/auth';
import {
  getOpenChatRoom,
  getOpenChatMessages,
  joinOpenChatRoom,
  leaveOpenChatRoom,
  kickParticipant,
  deleteOpenChatRoom,
} from '@/lib/api/openChat';
import { OpenChatWebSocket } from '@/lib/websocket/openChat';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Button from '@/components/ui/Button';
import { getCountryName } from '@/lib/countries';
import type { OpenChatRoom, Message } from '@/types';

function OpenChatRoomContent() {
  const router = useRouter();
  const params = useParams();
  const roomId = parseInt(params.id as string);

  const { user } = useAuthStore();

  const [room, setRoom] = useState<OpenChatRoom | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showParticipants, setShowParticipants] = useState(false);
  const [password, setPassword] = useState('');
  const [needsPassword, setNeedsPassword] = useState(false);
  const [isJoining, setIsJoining] = useState(false);

  const wsRef = useRef<OpenChatWebSocket | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!roomId || isNaN(roomId)) {
      router.push('/open-chat');
      return;
    }

    loadChatRoom();
  }, [roomId, router]);

  const loadChatRoom = async () => {
    try {
      const data = await getOpenChatRoom(roomId);
      setRoom(data);

      // Check if user is participant
      if (Array.isArray(data.participants) && data.participants.some((p) => p?.id === user?.id)) {
        // Already joined, load messages and connect (only if not already connected)
        loadMessages();
        if (!wsRef.current) {
          connectWebSocket();
        }
      } else {
        // Not joined yet
        if (!data.is_public) {
          setNeedsPassword(true);
        } else {
          // Auto-join public room
          await handleJoinRoom();
        }
      }
    } catch (error) {
      console.error('Failed to load chat room:', error);
      setError('채팅방을 불러오는데 실패했습니다.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleJoinRoom = async () => {
    setIsJoining(true);
    try {
      await joinOpenChatRoom(roomId, password || undefined);
      setNeedsPassword(false);
      // Reload room to get updated participant list
      await loadChatRoom();
    } catch (error: any) {
      console.error('Failed to join room:', error);
      if (error.response?.status === 403) {
        setError('비밀번호가 올바르지 않습니다.');
      } else if (error.response?.status === 400) {
        setError(error.response.data.error || '입장할 수 없습니다.');
      } else {
        setError('채팅방 입장에 실패했습니다.');
      }
    } finally {
      setIsJoining(false);
    }
  };

  const reloadRoomInfo = async () => {
    try {
      const data = await getOpenChatRoom(roomId);
      setRoom(data);
    } catch (error) {
      console.error('Failed to reload room info:', error);
    }
  };

  const connectWebSocket = () => {
    // Disconnect existing connection to prevent duplicates
    if (wsRef.current) {
      wsRef.current.disconnect();
    }

    const token = localStorage.getItem('access_token');
    if (token) {
      const ws = new OpenChatWebSocket(roomId, token);
      ws.connect();

      ws.onMessage((data) => {
        if (data.type === 'message' && data.message) {
          setMessages((prev) => [...prev, data.message!]);
          scrollToBottom();
        } else if (data.type === 'user_joined' && data.user) {
          // Reload room info only (don't reconnect WebSocket)
          reloadRoomInfo();
        } else if (data.type === 'user_left' && data.user) {
          // Reload room info only (don't reconnect WebSocket)
          reloadRoomInfo();
        } else if (data.type === 'user_kicked' && data.user) {
          if (data.user.id === user?.id) {
            alert('채팅방에서 강퇴되었습니다.');
            router.push('/open-chat');
          } else {
            reloadRoomInfo();
          }
        }
      });

      wsRef.current = ws;
    }
  };

  const loadMessages = async () => {
    try {
      const data = await getOpenChatMessages(roomId);
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
      await leaveOpenChatRoom(roomId);
      router.push('/open-chat');
    } catch (error) {
      console.error('Failed to leave room:', error);
      alert('채팅방 나가기에 실패했습니다.');
    }
  };

  const handleKickUser = async (userId: number) => {
    if (!confirm('이 사용자를 강퇴하시겠습니까?')) {
      return;
    }

    try {
      await kickParticipant(roomId, userId);
      loadChatRoom();
    } catch (error) {
      console.error('Failed to kick user:', error);
      alert('강퇴에 실패했습니다.');
    }
  };

  const handleDeleteRoom = async () => {
    if (!confirm('채팅방을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.')) {
      return;
    }

    try {
      await deleteOpenChatRoom(roomId);
      alert('채팅방이 삭제되었습니다.');
      router.push('/open-chat');
    } catch (error) {
      console.error('Failed to delete room:', error);
      alert('채팅방 삭제에 실패했습니다.');
    }
  };

  useEffect(() => {
    return () => {
      if (wsRef.current) {
        wsRef.current.disconnect();
      }
    };
  }, []);

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

  if (!room) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <p className="text-red-600">채팅방을 찾을 수 없습니다.</p>
          <Button onClick={() => router.push('/open-chat')} className="mt-4">
            채팅 목록으로
          </Button>
        </div>
      </div>
    );
  }

  // Password input screen
  if (needsPassword) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
        <div className="bg-white rounded-xl shadow-sm p-8 max-w-md w-full">
          <div className="text-center mb-6">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-blue-100 rounded-full mb-4">
              <svg
                className="w-8 h-8 text-blue-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                />
              </svg>
            </div>
            <h2 className="text-xl font-bold text-gray-900 mb-2">{room.title}</h2>
            <p className="text-gray-600">비공개 채팅방입니다</p>
          </div>

          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-600">{error}</p>
            </div>
          )}

          <form onSubmit={(e) => { e.preventDefault(); handleJoinRoom(); }} className="space-y-4">
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="비밀번호를 입력하세요"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={isJoining}
            />
            <div className="flex gap-3">
              <Button
                type="button"
                variant="outline"
                onClick={() => router.push('/open-chat')}
                fullWidth
              >
                취소
              </Button>
              <Button
                type="submit"
                isLoading={isJoining}
                disabled={!password || isJoining}
                fullWidth
              >
                입장
              </Button>
            </div>
          </form>
        </div>
      </div>
    );
  }

  const isOwner = room.creator?.id === user?.id;

  return (
    <div className="flex flex-col h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-4 py-3 flex items-center justify-between sticky top-0 z-10">
        <div className="flex items-center gap-3 flex-1 min-w-0">
          <button
            onClick={() => router.back()}
            className="text-gray-600 hover:text-gray-900 flex-shrink-0"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div className="flex-1 min-w-0">
            <h2 className="font-semibold text-gray-900 truncate">{room.title}</h2>
            <p className="text-xs text-gray-500">
              참여자 {room.participant_count}/{room.max_participants || '∞'}
            </p>
          </div>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setShowParticipants(!showParticipants)}
            className="text-gray-600 hover:text-blue-600"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
              />
            </svg>
          </button>
          {room.can_delete && (
            <button
              onClick={handleDeleteRoom}
              className="text-gray-600 hover:text-red-600"
              title="채팅방 삭제"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
            </button>
          )}
          <button
            onClick={handleLeaveRoom}
            className="text-gray-600 hover:text-red-600"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
              />
            </svg>
          </button>
        </div>
      </div>

      {/* Participant List Sidebar */}
      {showParticipants && (
        <div className="absolute top-14 right-0 w-64 bg-white border-l border-gray-200 h-[calc(100vh-3.5rem)] overflow-y-auto z-20 shadow-lg">
          <div className="p-4">
            <h3 className="font-semibold text-gray-900 mb-4">
              참여자 목록 ({room.participant_count})
            </h3>
            <div className="space-y-2">
              {Array.isArray(room.participants) && room.participants.map((participant) => (
                <div
                  key={participant.id}
                  className="flex items-center justify-between p-2 rounded-lg hover:bg-gray-50"
                >
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white text-sm font-semibold">
                      {participant.nickname?.[0]?.toUpperCase() || 'U'}
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-900">
                        {participant.nickname}
                        {room.room_type !== 'default' && room.creator && participant.id === room.creator.id && (
                          <span className="ml-2 text-xs text-blue-600">방장</span>
                        )}
                      </p>
                      <p className="text-xs text-gray-500">{getCountryName(participant.country_code)}</p>
                    </div>
                  </div>
                  {isOwner && room.creator && participant.id !== room.creator.id && (
                    <button
                      onClick={() => handleKickUser(participant.id)}
                      className="text-red-600 hover:text-red-700 text-sm"
                    >
                      강퇴
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

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
            const isMyMessage = user && message.sender?.id === user.id;

            return (
              <div
                key={message.id}
                className={`flex ${isMyMessage ? 'justify-end' : 'justify-start'}`}
              >
                <div className="max-w-[70%]">
                  {!isMyMessage && message.sender && (
                    <p className="text-xs text-gray-600 mb-1 ml-1">
                      {message.sender.nickname}
                    </p>
                  )}
                  <div
                    className={`${
                      isMyMessage
                        ? 'bg-blue-600 text-white rounded-l-2xl rounded-tr-2xl'
                        : 'bg-white text-gray-900 rounded-r-2xl rounded-tl-2xl shadow-sm'
                    } px-4 py-2`}
                  >
                    <p className="break-words">{message.content}</p>
                    <span
                      className={`text-xs block mt-1 ${
                        isMyMessage ? 'text-blue-200' : 'text-gray-500'
                      }`}
                    >
                      {new Date(message.created_at).toLocaleTimeString('ko-KR', {
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </span>
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

export default function OpenChatRoomPage() {
  return (
    <ProtectedRoute>
      <OpenChatRoomContent />
    </ProtectedRoute>
  );
}
