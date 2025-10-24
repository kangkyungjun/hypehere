'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import { getOpenChatRooms } from '@/lib/api/openChat';
import { formatRelativeTime } from '@/lib/utils';
import Button from '@/components/ui/Button';
import ConfirmModal from '@/components/ui/ConfirmModal';
import type { OpenChatRoom } from '@/types';

export default function OpenChatListPage() {
  const router = useRouter();
  const { isAuthenticated, user, loadUser } = useAuthStore();

  const [rooms, setRooms] = useState<OpenChatRoom[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [category, setCategory] = useState('');
  const [userFilter, setUserFilter] = useState('');
  const [viewMode, setViewMode] = useState('all');
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);

  const observerTarget = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadUser();
  }, [loadUser]);

  const loadRooms = useCallback(async (pageNum: number, reset: boolean = false) => {
    if (reset) {
      setIsLoading(true);
    } else {
      setIsLoadingMore(true);
    }

    try {
      const data = await getOpenChatRooms({
        page: pageNum,
        search: searchTerm || undefined,
        category: category || undefined,
        user_filter: userFilter || undefined,
        ordering: viewMode === 'popular' ? 'popular' : 'recent',
      });

      if (reset) {
        setRooms(data.results);
      } else {
        setRooms((prev) => [...prev, ...data.results]);
      }

      setHasMore(!!data.next);
      setError(null);
    } catch (error) {
      console.error('Failed to load open chat rooms:', error);
      setError('오픈 채팅방 목록을 불러오는데 실패했습니다.');
    } finally {
      setIsLoading(false);
      setIsLoadingMore(false);
    }
  }, [searchTerm, category, userFilter, viewMode]);

  useEffect(() => {
    // 검색어나 카테고리 변경 시 초기화
    setRooms([]);
    setPage(1);
    setHasMore(true);
    setIsLoading(true);
    loadRooms(1, true);
  }, [searchTerm, category, loadRooms]);

  const loadMoreRooms = useCallback(() => {
    if (!isLoadingMore && hasMore) {
      setPage((prevPage) => {
        const nextPage = prevPage + 1;
        loadRooms(nextPage, false);
        return nextPage;
      });
    }
  }, [isLoadingMore, hasMore, loadRooms, page]);

  // Check if observer target is already visible after initial load
  useEffect(() => {
    if (!isLoading && !isLoadingMore && hasMore && observerTarget.current) {
      const rect = observerTarget.current.getBoundingClientRect();
      const isVisible = rect.top < window.innerHeight;
      if (isVisible) {
        loadMoreRooms();
      }
    }
  }, [isLoading, isLoadingMore, hasMore, loadMoreRooms]);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && hasMore && !isLoadingMore) {
          loadMoreRooms();
        }
      },
      { threshold: 0.5 }
    );

    const currentTarget = observerTarget.current;
    if (currentTarget) {
      observer.observe(currentTarget);
    }

    return () => {
      if (currentTarget) {
        observer.unobserve(currentTarget);
      }
    };
  }, [hasMore, isLoadingMore, loadMoreRooms, rooms.length]);

  const handleCreateRoom = () => {
    if (!isAuthenticated) {
      setShowAuthModal(true);
      return;
    }

    // 일반 사용자(USER)는 1개만 생성 가능 - 사전 검증
    if (user && user.role === 'user') {
      // 현재 로드된 방 목록에서 본인이 만든 USER_CREATED 방이 있는지 확인
      const hasUserCreatedRoom = rooms.some(
        (room) => room.room_type === 'user_created' && room.creator?.id === user.id
      );

      if (hasUserCreatedRoom) {
        alert('이미 오픈 채팅방을 생성하셨습니다. 일반 사용자는 1개만 생성할 수 있습니다.');
        return;
      }
    }

    router.push('/open-chat/create');
  };

  const handleRoomClick = (e: React.MouseEvent, roomId: number) => {
    if (!isAuthenticated) {
      e.preventDefault();
      router.push('/login');
    } else {
      router.push(`/open-chat/${roomId}`);
    }
  };

  const handleConfirm = () => {
    setShowAuthModal(false);
    router.push('/login');
  };

  const handleCancel = () => {
    setShowAuthModal(false);
  };

  const categories = [
    { value: '', label: '전체' },
    { value: 'language', label: '언어 교환' },
    { value: 'hobby', label: '취미' },
    { value: 'study', label: '스터디' },
    { value: 'game', label: '게임' },
    { value: 'other', label: '기타' },
  ];

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
          <div className="flex items-center justify-between mb-4">
            <h1 className="text-2xl font-bold text-gray-900">오픈 채팅</h1>
            <div className="flex items-center gap-2">
              <select
                value={userFilter}
                onChange={(e) => setUserFilter(e.target.value)}
                className="px-3 py-1.5 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
              >
                <option value="">전체 방</option>
                <option value="joined">내가 속한 방</option>
                <option value="created">내가 만든 방</option>
              </select>
              <Button size="sm" onClick={handleCreateRoom}>
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
                방 만들기
              </Button>
            </div>
          </div>

          {/* Search */}
          <div className="mb-3">
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="채팅방 검색..."
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* View Mode Tabs */}
          <div className="flex gap-2 mb-3 border-b border-gray-200">
            <button
              onClick={() => setViewMode('all')}
              className={`px-4 py-2 font-medium transition-colors ${
                viewMode === 'all'
                  ? 'text-blue-600 border-b-2 border-blue-600'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              전체
            </button>
            <button
              onClick={() => setViewMode('popular')}
              className={`px-4 py-2 font-medium transition-colors ${
                viewMode === 'popular'
                  ? 'text-blue-600 border-b-2 border-blue-600'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              추천 (인기순)
            </button>
          </div>

          {/* Category Filter - Only visible in 'all' mode */}
          {viewMode === 'all' && (
            <div className="flex gap-2 overflow-x-auto pb-2">
              {categories.map((cat) => (
                <button
                  key={cat.value}
                  onClick={() => setCategory(cat.value)}
                  className={`flex-shrink-0 px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                    category === cat.value
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {cat.label}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto px-4 py-6">
        {error && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {rooms.length === 0 ? (
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
                  d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              채팅방이 없습니다
            </h3>
            <p className="text-gray-600 mb-6">
              새로운 오픈 채팅방을 만들어보세요
            </p>
            <Button onClick={handleCreateRoom}>
              방 만들기
            </Button>
          </div>
        ) : (
          <>
            <div className="space-y-3">
              {rooms.map((room) => (
                <button
                  key={room.id}
                  onClick={(e) => handleRoomClick(e, room.id)}
                  className="block w-full text-left bg-white rounded-xl shadow-sm hover:shadow-md transition-shadow p-4"
                >
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-semibold text-gray-900 truncate">
                          {room.title}
                        </h3>
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
                        <p className="text-sm text-gray-600 line-clamp-2 mb-2">
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
                            {
                              categories.find((c) => c.value === room.category)
                                ?.label
                            }
                          </span>
                        )}
                        <span>{formatRelativeTime(room.created_at)}</span>
                      </div>
                    </div>
                  </div>
                </button>
              ))}
            </div>

            {/* Infinite Scroll Observer Target */}
            <div ref={observerTarget} className="py-8">
              {isLoadingMore && (
                <div className="flex flex-col items-center justify-center">
                  <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600 mb-2"></div>
                  <p className="text-sm text-gray-500">채팅방 불러오는 중...</p>
                </div>
              )}
              {!hasMore && rooms.length > 0 && (
                <div className="flex flex-col items-center justify-center space-y-2">
                  <svg
                    className="w-12 h-12 text-gray-300"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <p className="text-sm font-medium text-gray-600">
                    모든 채팅방을 불러왔습니다
                  </p>
                  <p className="text-xs text-gray-400">
                    총 {rooms.length}개의 채팅방
                  </p>
                </div>
              )}
            </div>
          </>
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
              className="flex flex-col items-center py-2 text-gray-600 hover:text-blue-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
              <span className="text-xs mt-1">채팅</span>
            </Link>
            <Link
              href="/open-chat"
              className="flex flex-col items-center py-2 text-blue-600"
            >
              <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                <path d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
              <span className="text-xs mt-1 font-semibold">오픈채팅</span>
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
