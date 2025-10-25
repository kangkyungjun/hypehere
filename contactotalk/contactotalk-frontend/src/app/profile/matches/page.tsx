'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth';
import { getMatchHistory } from '@/lib/api/chat';
import { formatRelativeTime } from '@/lib/utils';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Button from '@/components/ui/Button';
import type { MatchHistory } from '@/types';

function RecentMatchesContent() {
  const router = useRouter();
  const { user } = useAuthStore();

  const [matches, setMatches] = useState<MatchHistory[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadRecentMatches();
  }, []);

  const loadRecentMatches = async () => {
    try {
      setIsLoading(true);
      const data = await getMatchHistory();  // 백엔드에서 이미 5일 필터링됨
      setMatches(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error('Failed to load match history:', error);
      setError('최근 매칭 목록을 불러오는데 실패했습니다.');
    } finally {
      setIsLoading(false);
    }
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
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <div className="flex items-center gap-3">
            <button
              onClick={() => router.back()}
              className="text-gray-600 hover:text-gray-900 transition-colors"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <h1 className="text-xl font-bold text-gray-900">최근 5일 매칭</h1>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto">
        {error && (
          <div className="mx-4 mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {matches.length === 0 ? (
          <div className="mx-4 mt-6 bg-white rounded-xl shadow-sm p-12 text-center">
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
                  d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"
                />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              최근 5일 이내 매칭이 없습니다
            </h3>
            <p className="text-gray-600 mb-6">
              새로운 사람과 매칭하여 대화를 시작해보세요
            </p>
            <Button onClick={() => router.push('/matching')}>
              새 매칭 시작하기
            </Button>
          </div>
        ) : (
          <div className="bg-white">
            {matches.map((history) => {
              const matchedUser = history.matched_user;
              if (!matchedUser) return null;

              return (
                <div
                  key={history.id}
                  className="flex items-center gap-4 px-4 py-4 border-b border-gray-100 last:border-b-0"
                >
                  {/* Avatar */}
                  <div className="flex-shrink-0 w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white font-bold text-lg">
                    {matchedUser.nickname[0].toUpperCase()}
                  </div>

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-semibold text-gray-900 truncate">
                        {matchedUser.nickname}
                      </span>
                      <span className="text-sm text-gray-500">·</span>
                      <span className="text-sm text-gray-500 flex-shrink-0">
                        {matchedUser.country_code}
                      </span>
                    </div>
                    {history.last_message_preview && (
                      <p className="text-sm text-gray-600 truncate">
                        {history.last_message_preview}
                      </p>
                    )}
                  </div>

                  {/* Time */}
                  <div className="flex-shrink-0">
                    <span className="text-xs text-gray-500">
                      {formatRelativeTime(history.matched_at)}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

export default function RecentMatchesPage() {
  return (
    <ProtectedRoute>
      <RecentMatchesContent />
    </ProtectedRoute>
  );
}
