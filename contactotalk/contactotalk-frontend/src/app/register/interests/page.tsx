'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth';
import { getInterests, selectInterests } from '@/lib/api/accounts';
import Button from '@/components/ui/Button';
import type { Interest } from '@/types';

export default function InterestsPage() {
  const router = useRouter();
  const { user, isAuthenticated } = useAuthStore();

  const [interests, setInterests] = useState<Interest[]>([]);
  const [selectedInterests, setSelectedInterests] = useState<number[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // 인증되지 않은 경우 로그인 페이지로 리다이렉트
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }

    // 관심사 목록 로드
    const loadInterests = async () => {
      try {
        const data = await getInterests();
        setInterests(data);
      } catch (error) {
        console.error('Failed to load interests:', error);
        setError('관심사 목록을 불러오는데 실패했습니다.');
      }
    };
    loadInterests();
  }, [isAuthenticated, router]);

  const toggleInterest = (interestId: number) => {
    setSelectedInterests((prev) =>
      prev.includes(interestId)
        ? prev.filter((id) => id !== interestId)
        : [...prev, interestId]
    );
    setError(null);
  };

  const handleSubmit = async () => {
    if (selectedInterests.length < 3) {
      setError('최소 3개 이상의 관심사를 선택해주세요.');
      return;
    }

    if (selectedInterests.length > 10) {
      setError('최대 10개까지 선택 가능합니다.');
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      await selectInterests(selectedInterests);
      // 관심사 선택 완료 후 홈으로 이동
      router.push('/');
    } catch (error) {
      console.error('Failed to select interests:', error);
      setError('관심사 선택에 실패했습니다. 다시 시도해주세요.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSkip = () => {
    router.push('/');
  };

  // 카테고리별로 관심사 그룹화
  const groupedInterests = interests.reduce((acc, interest) => {
    if (!acc[interest.category]) {
      acc[interest.category] = [];
    }
    acc[interest.category].push(interest);
    return acc;
  }, {} as Record<string, Interest[]>);

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 px-4 py-12">
      <div className="max-w-4xl mx-auto">
        <div className="bg-white rounded-2xl shadow-xl p-8">
          {/* Header */}
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold text-gray-900 mb-2">
              관심사 선택
            </h1>
            <p className="text-gray-600">
              당신의 관심사를 선택하여 더 나은 매칭을 경험하세요
            </p>
            <p className="text-sm text-gray-500 mt-2">
              최소 3개, 최대 10개까지 선택 가능합니다 (현재: {selectedInterests.length}개)
            </p>
          </div>

          {/* Error Message */}
          {error && (
            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-600">{error}</p>
            </div>
          )}

          {/* Interests Grid */}
          <div className="space-y-8">
            {Object.entries(groupedInterests).map(([category, categoryInterests]) => (
              <div key={category}>
                <h2 className="text-lg font-semibold text-gray-900 mb-4">
                  {category}
                </h2>
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
                  {categoryInterests.map((interest) => (
                    <button
                      key={interest.id}
                      onClick={() => toggleInterest(interest.id)}
                      className={`
                        px-4 py-3 rounded-lg font-medium text-sm transition-all
                        ${
                          selectedInterests.includes(interest.id)
                            ? 'bg-blue-600 text-white shadow-md scale-105'
                            : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        }
                      `}
                    >
                      {interest.name_ko}
                    </button>
                  ))}
                </div>
              </div>
            ))}
          </div>

          {/* Actions */}
          <div className="mt-8 flex gap-4">
            <Button
              variant="outline"
              fullWidth
              onClick={handleSkip}
              disabled={isLoading}
            >
              나중에 선택하기
            </Button>
            <Button
              fullWidth
              onClick={handleSubmit}
              isLoading={isLoading}
              disabled={selectedInterests.length < 3}
            >
              완료
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
