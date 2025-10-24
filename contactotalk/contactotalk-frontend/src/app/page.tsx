'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import { getChatRooms } from '@/lib/api/chat';
import { getOpenChatRooms } from '@/lib/api/openChat';
import { formatRelativeTime } from '@/lib/utils';
import Button from '@/components/ui/Button';
import ConfirmModal from '@/components/ui/ConfirmModal';
import type { ChatRoom, OpenChatRoom } from '@/types';

export default function HomePage() {
  const router = useRouter();
  const { user, isAuthenticated, isLoading: authLoading, loadUser } = useAuthStore();

  const [chatRooms, setChatRooms] = useState<ChatRoom[]>([]);
  const [openChatRooms, setOpenChatRooms] = useState<OpenChatRoom[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showCreateLimitModal, setShowCreateLimitModal] = useState(false);
  const [showAuthModal, setShowAuthModal] = useState(false);

  useEffect(() => {
    loadUser();
  }, [loadUser]);

  useEffect(() => {
    if (!authLoading) {
      loadData();
    }
  }, [isAuthenticated, authLoading]);

  const loadData = async () => {
    try {
      if (isAuthenticated) {
        // 로그인 사용자: 1:1 채팅 + 오픈 채팅 모두 로드
        const [chatData, openChatData] = await Promise.all([
          getChatRooms(),
          getOpenChatRooms({ ordering: '-created_at' }),
        ]);
        setChatRooms(chatData.slice(0, 5)); // 최근 5개
        setOpenChatRooms(openChatData.results.slice(0, 3)); // 최근 3개
      } else {
        // 비로그인 사용자: 오픈 채팅만 로드
        const openChatData = await getOpenChatRooms({ ordering: '-created_at' });
        setOpenChatRooms(openChatData.results.slice(0, 3));
      }
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateRoomClick = async (e: React.MouseEvent) => {
    e.preventDefault();
    
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }
    
    try {
      const response = await getOpenChatRooms({ user_filter: 'created' });
      
      if (response.results.length > 0) {
        setShowCreateLimitModal(true);
      } else {
        router.push('/open-chat/create');
      }
    } catch (error) {
      console.error('Failed to check room limit:', error);
      router.push('/open-chat/create');
    }
  };

  const handleActionClick = (e: React.MouseEvent, path: string) => {
    if (!isAuthenticated) {
      e.preventDefault();
      setShowAuthModal(true);
    } else {
      router.push(path);
    }
  };

  const handleConfirm = () => {
    setShowAuthModal(false);
    router.push('/login');
  };

  const handleCancel = () => {
    setShowAuthModal(false);
  };

  const getOtherUser = (room: ChatRoom) => {
    if (!user) return null;
    return room.user1.id === user.id ? room.user2 : room.user1;
  };

  const categories = [
    { value: 'language', label: '언어 교환' },
    { value: 'hobby', label: '취미' },
    { value: 'study', label: '스터디' },
    { value: 'game', label: '게임' },
    { value: 'other', label: '기타' },
  ];

  if (authLoading || isLoading) {
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
            <h1 className="text-2xl font-bold text-gray-900">ConTacToTalk</h1>
            {isAuthenticated ? (
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
            ) : (
              <div className="flex gap-2">
                <Link href="/login">
                  <Button size="sm" variant="outline">
                    로그인
                  </Button>
                </Link>
                <Link href="/register">
                  <Button size="sm">
                    회원가입
                  </Button>
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto px-4 py-6">
        {!isAuthenticated ? (
          /* 비로그인 사용자용 홈 */
          <div className="space-y-6">
            {/* Hero Section */}
            <div className="bg-gradient-to-br from-blue-500 to-indigo-600 rounded-xl shadow-lg p-8 text-white text-center">
              <h2 className="text-3xl font-bold mb-4">
                전 세계 친구들과 소통하세요
              </h2>
              <p className="text-lg mb-6 text-blue-50">
                관심사 기반 매칭으로 새로운 친구를 만나보세요
              </p>
              <div className="flex gap-3 justify-center">
                <Link href="/register">
                  <Button
                    size="lg"
                    variant="outline"
                    className="bg-white text-blue-600 hover:bg-blue-50 border-white"
                  >
                    회원가입하기
                  </Button>
                </Link>
                <Link href="/login">
                  <Button size="lg" className="bg-blue-700 hover:bg-blue-800 text-white">
                    로그인
                  </Button>
                </Link>
              </div>
            </div>

            {/* Matching CTA */}
            <div className="bg-white rounded-xl shadow-sm p-6">
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <h3 className="text-lg font-bold text-gray-900 mb-1">
                    1:1 매칭 시작하기
                  </h3>
                  <p className="text-sm text-gray-600">
                    관심사가 맞는 전 세계 친구와 연결되세요
                  </p>
                </div>
                <button
                  onClick={(e) => handleActionClick(e, '/matching')}
                  className="flex-shrink-0 ml-4"
                >
                  <Button>시작하기</Button>
                </button>
              </div>
            </div>

            {/* Open Chat Preview */}
            <div className="bg-white rounded-xl shadow-sm p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-bold text-gray-900">인기 오픈 채팅</h3>
                <Link href="/open-chat" className="text-sm text-blue-600 hover:text-blue-700 font-medium">
                  전체보기 →
                </Link>
              </div>

              {openChatRooms.length === 0 ? (
                <p className="text-center text-gray-500 py-8">
                  아직 오픈 채팅방이 없습니다
                </p>
              ) : (
                <div className="space-y-3">
                  {openChatRooms.map((room) => (
                    <button
                      key={room.id}
                      onClick={(e) => handleActionClick(e, `/open-chat/${room.id}`)}
                      className="block w-full text-left bg-gray-50 rounded-lg p-4 hover:bg-gray-100 transition-colors"
                    >
                      <div className="flex items-start justify-between mb-2">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <h4 className="font-semibold text-gray-900 truncate">
                              {room.title}
                            </h4>
                            {!room.is_public && (
                              <svg
                                className="w-4 h-4 text-gray-500 flex-shrink-0"
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
                            )}
                          </div>
                          {room.description && (
                            <p className="text-sm text-gray-600 line-clamp-1 mb-2">
                              {room.description}
                            </p>
                          )}
                          <div className="flex items-center gap-3 text-xs text-gray-500">
                            <span className="flex items-center gap-1">
                              <svg
                                className="w-4 h-4"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                              >
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  strokeWidth={2}
                                  d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                                />
                              </svg>
                              {room.participant_count}/{room.max_participants || '∞'}
                            </span>
                            {room.category && (
                              <span className="px-2 py-1 bg-blue-50 text-blue-600 rounded-full">
                                {categories.find((c) => c.value === room.category)?.label}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Features */}
            <div className="grid md:grid-cols-3 gap-6">
              <div className="bg-white p-6 rounded-xl shadow-sm">
                <div className="text-4xl mb-4">💬</div>
                <h3 className="text-xl font-bold mb-2 text-gray-900">실시간 채팅</h3>
                <p className="text-gray-600">
                  1:1 매칭과 오픈 채팅으로 전 세계 사람들과 소통하세요
                </p>
              </div>

              <div className="bg-white p-6 rounded-xl shadow-sm">
                <div className="text-4xl mb-4">🌍</div>
                <h3 className="text-xl font-bold mb-2 text-gray-900">글로벌 매칭</h3>
                <p className="text-gray-600">
                  관심사 기반 스마트 매칭으로 새로운 친구를 만나보세요
                </p>
              </div>

              <div className="bg-white p-6 rounded-xl shadow-sm">
                <div className="text-4xl mb-4">📱</div>
                <h3 className="text-xl font-bold mb-2 text-gray-900">SNS 기능</h3>
                <p className="text-gray-600">
                  게시글, 댓글, 팔로우로 더 깊은 소통을 경험하세요
                </p>
              </div>
            </div>
          </div>
        ) : (
          /* 로그인 사용자용 홈 */
          <div className="space-y-6">
            {/* Quick Actions */}
            <div className="grid md:grid-cols-2 gap-4">
              <Link href="/matching">
                <div className="bg-gradient-to-br from-blue-500 to-indigo-600 rounded-xl shadow-sm p-6 text-white hover:shadow-md transition-shadow cursor-pointer">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center">
                      <svg
                        className="w-6 h-6"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                        />
                      </svg>
                    </div>
                    <div className="flex-1">
                      <h3 className="text-lg font-bold mb-1">1:1 매칭</h3>
                      <p className="text-sm text-blue-50">새로운 친구 만나기</p>
                    </div>
                  </div>
                </div>
              </Link>

              <button onClick={handleCreateRoomClick} className="w-full text-left">
                <div className="bg-gradient-to-br from-purple-500 to-pink-600 rounded-xl shadow-sm p-6 text-white hover:shadow-md transition-shadow cursor-pointer">
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center">
                      <svg
                        className="w-6 h-6"
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
                    </div>
                    <div className="flex-1">
                      <h3 className="text-lg font-bold mb-1">방 만들기</h3>
                      <p className="text-sm text-purple-50">오픈 채팅방 생성</p>
                    </div>
                  </div>
                </div>
              </button>
            </div>

            {/* Recent 1:1 Chats */}
            <div className="bg-white rounded-xl shadow-sm p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-bold text-gray-900">최근 채팅</h3>
                <Link href="/chat" className="text-sm text-blue-600 hover:text-blue-700 font-medium">
                  전체보기 →
                </Link>
              </div>

              {chatRooms.length === 0 ? (
                <div className="text-center py-8">
                  <p className="text-gray-500 mb-4">아직 채팅방이 없습니다</p>
                  <Link href="/matching">
                    <Button size="sm">매칭 시작하기</Button>
                  </Link>
                </div>
              ) : (
                <div className="space-y-2">
                  {chatRooms.map((room) => {
                    const otherUser = getOtherUser(room);
                    if (!otherUser) return null;

                    return (
                      <Link
                        key={room.id}
                        href={`/chat/${room.id}`}
                        className="block bg-gray-50 rounded-lg p-3 hover:bg-gray-100 transition-colors"
                      >
                        <div className="flex items-center gap-3">
                          <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white font-semibold flex-shrink-0">
                            {otherUser.nickname?.[0]?.toUpperCase() || 'U'}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center justify-between mb-1">
                              <h4 className="font-semibold text-gray-900 truncate">
                                {otherUser.nickname}
                              </h4>
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
                                <span className="flex-shrink-0 ml-2 inline-flex items-center justify-center w-5 h-5 bg-blue-600 text-white text-xs font-semibold rounded-full">
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

            {/* Recent Open Chats */}
            <div className="bg-white rounded-xl shadow-sm p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-bold text-gray-900">인기 오픈 채팅</h3>
                <Link href="/open-chat" className="text-sm text-blue-600 hover:text-blue-700 font-medium">
                  전체보기 →
                </Link>
              </div>

              {openChatRooms.length === 0 ? (
                <div className="text-center py-8">
                  <p className="text-gray-500 mb-4">아직 오픈 채팅방이 없습니다</p>
                  <Button size="sm" onClick={handleCreateRoomClick}>
                    방 만들기
                  </Button>
                </div>
              ) : (
                <div className="space-y-3">
                  {openChatRooms.map((room) => (
                    <Link
                      key={room.id}
                      href={`/open-chat/${room.id}`}
                      className="block bg-gray-50 rounded-lg p-4 hover:bg-gray-100 transition-colors"
                    >
                      <div className="flex items-start justify-between mb-2">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <h4 className="font-semibold text-gray-900 truncate">
                              {room.title}
                            </h4>
                            {!room.is_public && (
                              <svg
                                className="w-4 h-4 text-gray-500 flex-shrink-0"
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
                            )}
                          </div>
                          {room.description && (
                            <p className="text-sm text-gray-600 line-clamp-1 mb-2">
                              {room.description}
                            </p>
                          )}
                          <div className="flex items-center gap-3 text-xs text-gray-500">
                            <span className="flex items-center gap-1">
                              <svg
                                className="w-4 h-4"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                              >
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  strokeWidth={2}
                                  d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                                />
                              </svg>
                              {room.participant_count}/{room.max_participants || '∞'}
                            </span>
                            {room.category && (
                              <span className="px-2 py-1 bg-blue-50 text-blue-600 rounded-full">
                                {categories.find((c) => c.value === room.category)?.label}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    </Link>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Bottom Navigation */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 py-2">
        <div className="max-w-4xl mx-auto px-4">
          <div className="grid grid-cols-4 gap-2">
            <Link
              href="/"
              className="flex flex-col items-center py-2 text-blue-600"
            >
              <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                <path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              <span className="text-xs mt-1 font-semibold">홈</span>
            </Link>
            <button
              onClick={(e) => handleActionClick(e, '/chat')}
              className="flex flex-col items-center py-2 text-gray-600 hover:text-blue-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
              <span className="text-xs mt-1">채팅</span>
            </button>
            <button
              onClick={(e) => handleActionClick(e, '/open-chat')}
              className="flex flex-col items-center py-2 text-gray-600 hover:text-blue-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
              <span className="text-xs mt-1">오픈채팅</span>
            </button>
            <button
              onClick={(e) => handleActionClick(e, '/profile')}
              className="flex flex-col items-center py-2 text-gray-600 hover:text-blue-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              <span className="text-xs mt-1">프로필</span>
            </button>
          </div>
        </div>
      </div>

      {/* Create Limit Modal */}
      <ConfirmModal
        isOpen={showCreateLimitModal}
        message="오픈 채팅방은 1개만 생성 가능합니다."
        confirmText="내 채팅방 보기"
        onConfirm={() => {
          setShowCreateLimitModal(false);
          router.push('/open-chat?user_filter=created');
        }}
        onCancel={() => {
          setShowCreateLimitModal(false);
        }}
      />

      {/* Auth Required Modal */}
      <ConfirmModal
        isOpen={showAuthModal}
        message="로그인이 필요한 기능입니다"
        confirmText="확인"
        cancelText="취소"
        onConfirm={handleConfirm}
        onCancel={handleCancel}
      />
    </div>
  );
}
