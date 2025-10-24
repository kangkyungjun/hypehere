'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import { getChatRooms } from '@/lib/api/chat';
import { formatRelativeTime } from '@/lib/utils';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Button from '@/components/ui/Button';
import type { ChatRoom } from '@/types';

function ChatListContent() {
  const router = useRouter();
  const { user, loadUser } = useAuthStore();

  const [chatRooms, setChatRooms] = useState<ChatRoom[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadChatRooms();

    // 30초마다 자동 새로고침
    const intervalId = setInterval(loadChatRooms, 30000);

    return () => clearInterval(intervalId);
  }, []);

  const loadChatRooms = async () => {
    try {
      const data = await getChatRooms();
      setChatRooms(Array.isArray(data) ? data : []);
      setError(null);
    } catch (error) {
      console.error('Failed to load chat rooms:', error);
      setError('채팅방 목록을 불러오는데 실패했습니다.');
      setChatRooms([]);
    } finally {
      setIsLoading(false);
    }
  };

  const getOtherUser = (room: ChatRoom) => {
    if (!user) return null;
    return room.user1.id === user.id ? room.user2 : room.user1;
  };

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

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-bold text-gray-900">채팅</h1>
            <Link href="/matching">
              <Button size="sm">
                <svg
                  className="w-5 h-5 mr-2"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                새 매칭
              </Button>
            </Link>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto px-4 py-6">
        {error && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {Array.isArray(chatRooms) && chatRooms.length === 0 ? (
          <div className="bg-white rounded-xl shadow-sm p-12 text-center">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-gray-100 rounded-full mb-4">
              <svg
                className="w-10 h-10 text-gray-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              아직 채팅방이 없습니다
            </h3>
            <p className="text-gray-600 mb-6">
              매칭을 시작하여 새로운 친구를 만나보세요
            </p>
            <Link href="/matching">
              <Button>매칭 시작하기</Button>
            </Link>
          </div>
        ) : (
          <div className="space-y-2">
            {Array.isArray(chatRooms) && chatRooms.map((room) => {
              const otherUser = getOtherUser(room);
              if (!otherUser) return null;

              return (
                <Link
                  key={room.id}
                  href={`/chat/${room.id}`}
                  className="block bg-white rounded-xl shadow-sm hover:shadow-md transition-shadow p-4"
                >
                  <div className="flex items-center gap-4">
                    {/* Avatar */}
                    <div className="flex-shrink-0">
                      <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white font-semibold text-xl">
                        {otherUser.nickname?.[0]?.toUpperCase() || 'U'}
                      </div>
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between mb-1">
                        <h3 className="font-semibold text-gray-900 truncate">
                          {otherUser.nickname}
                        </h3>
                        {room.last_message && (
                          <span className="text-xs text-gray-500 flex-shrink-0 ml-2">
                            {formatRelativeTime(room.last_message.created_at)}
                          </span>
                        )}
                      </div>
                      <div className="flex items-center justify-between">
                        <p className="text-sm text-gray-600 truncate">
                          {room.last_message
                            ? room.last_message.content
                            : '메시지가 없습니다'}
                        </p>
                        {room.unread_count > 0 && (
                          <span className="flex-shrink-0 ml-2 inline-flex items-center justify-center w-6 h-6 bg-blue-600 text-white text-xs font-semibold rounded-full">
                            {room.unread_count}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                </Link>
              );
            })}
          </div>
        )}
      </div>

      {/* Bottom Navigation */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 py-2">
        <div className="max-w-4xl mx-auto px-4">
          <div className="grid grid-cols-4 gap-2">
            <Link
              href="/"
              className="flex flex-col items-center py-2 text-gray-600 hover:text-blue-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              <span className="text-xs mt-1">홈</span>
            </Link>
            <Link
              href="/chat"
              className="flex flex-col items-center py-2 text-blue-600"
            >
              <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                <path d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
              <span className="text-xs mt-1 font-semibold">채팅</span>
            </Link>
            <Link
              href="/open-chat"
              className="flex flex-col items-center py-2 text-gray-600 hover:text-blue-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
              <span className="text-xs mt-1">오픈채팅</span>
            </Link>
            <Link
              href="/profile"
              className="flex flex-col items-center py-2 text-gray-600 hover:text-blue-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              <span className="text-xs mt-1">프로필</span>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function ChatListPage() {
  return (
    <ProtectedRoute>
      <ChatListContent />
    </ProtectedRoute>
  );
}
