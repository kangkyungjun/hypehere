'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import { startMatching, cancelMatching, getMatchingStatus, getChatRoom } from '@/lib/api/chat';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Button from '@/components/ui/Button';
import { getCountryName, sortedCountries } from '@/lib/countries';
import type { ChatRoom, User, Interest } from '@/types';

function MatchingContent() {
  const router = useRouter();
  const { user } = useAuthStore();

  const [isMatching, setIsMatching] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [matchedRoom, setMatchedRoom] = useState<number | null>(null);
  const [roomData, setRoomData] = useState<ChatRoom | null>(null);
  const [selectedGender, setSelectedGender] = useState<string>('');
  const [selectedCountry, setSelectedCountry] = useState<string>('');

  useEffect(() => {
    // 매칭 상태 확인 (폴링)
    let intervalId: NodeJS.Timeout;

    if (isMatching) {
      intervalId = setInterval(async () => {
        try {
          const status = await getMatchingStatus();
          if (status.matched_room) {
            setMatchedRoom(status.matched_room);
            setIsMatching(false);
            // 매칭 성공 시 채팅방으로 이동
            setTimeout(() => {
              router.push(`/chat/${status.matched_room}`);
            }, 2000);
          }
        } catch (error) {
          console.error('Failed to check matching status:', error);
        }
      }, 3000); // 3초마다 확인
    }

    return () => {
      if (intervalId) {
        clearInterval(intervalId);
      }
    };
  }, [isMatching, router]);

  // 매칭된 방 데이터 가져오기
  useEffect(() => {
    if (matchedRoom) {
      const fetchRoomData = async () => {
        try {
          const room = await getChatRoom(matchedRoom);
          setRoomData(room);
        } catch (error) {
          console.error('Failed to fetch room data:', error);
        }
      };
      fetchRoomData();
    }
  }, [matchedRoom]);

  const handleStartMatching = async () => {
    setError(null);
    setIsMatching(true);

    try {
      await startMatching(selectedCountry || null, selectedGender || null);
    } catch (error: any) {
      console.error('Failed to start matching:', error);
      setError(error.response?.data?.error || '매칭 시작에 실패했습니다.');
      setIsMatching(false);
    }
  };

  const handleCancelMatching = async () => {
    try {
      await cancelMatching();
    } catch (error) {
      console.error('Failed to cancel matching:', error);
    } finally {
      setIsMatching(false);
    }
  };

  if (matchedRoom) {
    // 상대방 정보 계산
    const opponent = roomData?.user1.id === user?.id ? roomData?.user2 : roomData?.user1;

    // 공통 관심사 계산
    const commonInterests = opponent && user ?
      user.interests.filter(userInterest =>
        opponent.interests.some(opponentInterest => opponentInterest.id === userInterest.id)
      ) : [];

    return (
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-100 pb-20">
        {/* Header */}
        <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
          <div className="max-w-4xl mx-auto px-4 py-4">
            <h1 className="text-2xl font-bold text-gray-900">매칭</h1>
          </div>
        </div>

        {/* Content */}
        <div className="flex items-center justify-center min-h-[calc(100vh-140px)] px-4">
          <div className="text-center max-w-md w-full">
            <div className="mb-8">
              <div className="inline-flex items-center justify-center w-24 h-24 bg-green-100 rounded-full">
                <svg
                  className="w-12 h-12 text-green-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M5 13l4 4L19 7"
                  />
                </svg>
              </div>
            </div>
            <h1 className="text-4xl font-bold text-gray-900 mb-4">
              매칭 성공! 🎉
            </h1>
            <p className="text-xl text-gray-600 mb-6">
              새로운 친구와 연결되었습니다
            </p>

            {/* 상대방 정보 카드 */}
            {opponent && (
              <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
                <div className="space-y-3">
                  <div className="flex items-center justify-center gap-2">
                    <span className="text-2xl font-bold text-gray-900">{opponent.nickname}</span>
                    <span className="text-lg">님</span>
                  </div>

                  <div className="space-y-2 text-left">
                    <div className="flex items-center gap-2 p-2 bg-gray-50 rounded">
                      <span className="text-gray-600">성별:</span>
                      <span className="font-medium">
                        {opponent.gender === 'male' ? '👨 남성' : opponent.gender === 'female' ? '👩 여성' : '선택 안함'}
                      </span>
                    </div>

                    <div className="flex items-center gap-2 p-2 bg-gray-50 rounded">
                      <span className="text-gray-600">국적:</span>
                      <span className="font-medium">
                        🌍 {getCountryName(opponent.country_code)}
                      </span>
                    </div>

                    {commonInterests.length > 0 && (
                      <div className="p-2 bg-gray-50 rounded">
                        <div className="flex items-start gap-2">
                          <span className="text-gray-600 whitespace-nowrap">공통 관심사:</span>
                          <span className="font-medium">
                            🎯 {commonInterests.map(i => i.name).join(', ')}
                          </span>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )}

            <p className="text-sm text-gray-500">
              채팅방으로 이동 중...
            </p>
          </div>
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

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 pb-20">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <h1 className="text-2xl font-bold text-gray-900">매칭</h1>
        </div>
      </div>

      {/* Content */}
      <div className="flex items-center justify-center min-h-[calc(100vh-140px)] px-4">
        <div className="max-w-md w-full">
          <div className="bg-white rounded-2xl shadow-xl p-8">
            {/* Header */}
            <div className="text-center mb-8">
              <h1 className="text-3xl font-bold text-gray-900 mb-2">
                1:1 매칭
              </h1>
              <p className="text-gray-600">
                비슷한 관심사를 가진 사람과 연결됩니다
              </p>
            </div>

            {/* User Info */}
            {user && (
              <div className="mb-6 p-4 bg-blue-50 rounded-lg">
                <p className="text-sm text-gray-700">
                  <span className="font-semibold">{user.nickname}</span>님
                </p>
                <p className="text-xs text-gray-500 mt-1">
                  {getCountryName(user.country_code)}
                  {user.gender && (
                    <>
                      {' · '}
                      {user.gender === 'male' ? '남성' : user.gender === 'female' ? '여성' : '선택 안함'}
                    </>
                  )}
                </p>
              </div>
            )}

            {/* Gender Preference */}
            <div className="mb-6">
              <label htmlFor="gender-preference" className="block text-sm font-medium text-gray-700 mb-2">
                매칭 선호 성별
              </label>
              <select
                id="gender-preference"
                value={selectedGender}
                onChange={(e) => setSelectedGender(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
                disabled={isMatching}
              >
                <option value="">👥 모두</option>
                <option value="male">👨 남성</option>
                <option value="female">👩 여성</option>
              </select>
            </div>

            {/* Country Preference */}
            <div className="mb-6">
              <label htmlFor="country-preference" className="block text-sm font-medium text-gray-700 mb-2">
                매칭 선호 국가
              </label>
              <select
                id="country-preference"
                value={selectedCountry}
                onChange={(e) => setSelectedCountry(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
                disabled={isMatching}
              >
                <option value="">🌍 모든 국가</option>
                {sortedCountries.map((country) => (
                  <option key={country.code} value={country.code}>
                    {country.name} ({country.name_en})
                  </option>
                ))}
              </select>
            </div>

            {/* Error Message */}
            {error && (
              <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
                <p className="text-sm text-red-600">{error}</p>
              </div>
            )}

            {/* Matching Animation */}
            {isMatching ? (
              <div className="text-center py-8">
                <div className="relative inline-block">
                  <div className="animate-spin rounded-full h-20 w-20 border-b-4 border-blue-600"></div>
                  <div className="absolute inset-0 flex items-center justify-center">
                    <svg
                      className="w-10 h-10 text-blue-600"
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
                  </div>
                </div>
                <p className="text-lg font-semibold text-gray-900 mt-6">
                  매칭 중...
                </p>
                <div className="mt-8">
                  <Button
                    variant="outline"
                    onClick={handleCancelMatching}
                    fullWidth
                  >
                    매칭 취소
                  </Button>
                </div>
              </div>
            ) : (
              <div className="space-y-6">
                <Button
                  onClick={handleStartMatching}
                  fullWidth
                  size="lg"
                >
                  매칭 시작
                </Button>

                <div className="text-center">
                  <button
                    onClick={() => router.push('/chat')}
                    className="text-sm text-blue-600 hover:text-blue-700"
                  >
                    채팅방 목록으로 이동
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
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

export default function MatchingPage() {
  return (
    <ProtectedRoute>
      <MatchingContent />
    </ProtectedRoute>
  );
}
