'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth';
import { getInterests } from '@/lib/api/interests';
import { updateProfile } from '@/lib/api/auth';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Input from '@/components/ui/Input';
import Button from '@/components/ui/Button';
import CountrySelect from '@/components/ui/CountrySelect';
import { getCountryName } from '@/lib/countries';
import type { Interest } from '@/types';

function ProfileEditContent() {
  const router = useRouter();
  const { user, loadUser } = useAuthStore();

  const [isLoading, setIsLoading] = useState(false);
  const [interests, setInterests] = useState<Interest[]>([]);
  const [formData, setFormData] = useState({
    nickname: '',
    bio: '',
    gender: '' as 'male' | 'female' | 'undisclosed' | '',
    country_code: 'KOR',
    interest_ids: [] as number[],
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (user) {
      setFormData({
        nickname: user.nickname || '',
        bio: user.bio || '',
        gender: user.gender || '',
        country_code: user.country_code || 'KOR',
        interest_ids: user.interests?.map((interest) => interest.id) || [],
      });
    }
  }, [user]);

  useEffect(() => {
    const loadInterests = async () => {
      try {
        const data = await getInterests();
        setInterests(data);
      } catch (error) {
        console.error('Failed to load interests:', error);
      }
    };
    loadInterests();
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    setErrors((prev) => ({ ...prev, [name]: '' }));
  };

  const toggleInterest = (interestId: number) => {
    setFormData((prev) => {
      const isSelected = prev.interest_ids.includes(interestId);
      const newInterestIds = isSelected
        ? prev.interest_ids.filter((id) => id !== interestId)
        : [...prev.interest_ids, interestId];
      return { ...prev, interest_ids: newInterestIds };
    });
    setErrors((prev) => ({ ...prev, interest_ids: '' }));
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.nickname.trim()) {
      newErrors.nickname = '닉네임을 입력해주세요.';
    } else if (formData.nickname.length < 2 || formData.nickname.length > 20) {
      newErrors.nickname = '닉네임은 2-20자 사이여야 합니다.';
    }

    if (formData.bio && formData.bio.length > 500) {
      newErrors.bio = '자기소개는 최대 500자까지 입력 가능합니다.';
    }

    if (formData.interest_ids.length < 3) {
      newErrors.interest_ids = '최소 3개의 관심사를 선택해주세요.';
    } else if (formData.interest_ids.length > 10) {
      newErrors.interest_ids = '최대 10개까지 선택 가능합니다.';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) return;

    setIsLoading(true);

    try {
      // Convert empty string to undefined for gender
      const profileData = {
        ...formData,
        gender: formData.gender || undefined,
      };
      await updateProfile(profileData);
      await loadUser();
      router.push('/profile');
    } catch (error) {
      console.error('Failed to update profile:', error);
      setErrors({ submit: '프로필 업데이트에 실패했습니다.' });
    } finally {
      setIsLoading(false);
    }
  };

  const groupedInterests = Array.isArray(interests)
    ? interests.reduce((acc, interest) => {
        const category = interest.category || 'other';
        if (!acc[category]) {
          acc[category] = [];
        }
        acc[category].push(interest);
        return acc;
      }, {} as Record<string, Interest[]>)
    : {};

  if (!user) {
    return null;
  }

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <button
                onClick={() => router.back()}
                className="text-gray-600 hover:text-gray-900"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
              </button>
              <h1 className="text-2xl font-bold text-gray-900">프로필 수정</h1>
            </div>
          </div>
        </div>
      </div>

      {/* Form */}
      <div className="max-w-2xl mx-auto px-4 py-6">
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Profile Info Card */}
          <div className="bg-white rounded-xl shadow-sm p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">기본 정보</h2>

            <div className="space-y-4">
              <Input
                label="닉네임"
                type="text"
                name="nickname"
                value={formData.nickname}
                onChange={handleChange}
                error={errors.nickname}
                placeholder="2-20자"
                required
              />

              <CountrySelect
                label="국가"
                value={formData.country_code}
                onChange={(value) => setFormData((prev) => ({ ...prev, country_code: value }))}
                error={errors.country_code}
                required
              />

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">성별 (선택)</label>
                <div className="flex gap-3">
                  <button
                    type="button"
                    onClick={() => setFormData((prev) => ({ ...prev, gender: 'male' }))}
                    className={`flex-1 px-4 py-2 border rounded-lg transition-colors ${
                      formData.gender === 'male'
                        ? 'bg-blue-600 text-white border-blue-600'
                        : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    남성
                  </button>
                  <button
                    type="button"
                    onClick={() => setFormData((prev) => ({ ...prev, gender: 'female' }))}
                    className={`flex-1 px-4 py-2 border rounded-lg transition-colors ${
                      formData.gender === 'female'
                        ? 'bg-blue-600 text-white border-blue-600'
                        : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    여성
                  </button>
                  <button
                    type="button"
                    onClick={() => setFormData((prev) => ({ ...prev, gender: 'undisclosed' }))}
                    className={`flex-1 px-4 py-2 border rounded-lg transition-colors ${
                      formData.gender === 'undisclosed'
                        ? 'bg-blue-600 text-white border-blue-600'
                        : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    선택 안함
                  </button>
                </div>
              </div>

              <div>
                <label htmlFor="bio" className="block text-sm font-medium text-gray-700 mb-1">
                  자기소개
                </label>
                <textarea
                  id="bio"
                  name="bio"
                  value={formData.bio}
                  onChange={handleChange}
                  rows={4}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                  placeholder="자신을 소개해주세요"
                  maxLength={500}
                />
                <div className="flex justify-between items-center mt-1">
                  {errors.bio && <p className="text-sm text-red-600">{errors.bio}</p>}
                  <p className="text-sm text-gray-500 ml-auto">
                    {formData.bio.length}/500
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Interests Card */}
          <div className="bg-white rounded-xl shadow-sm p-6">
            <div className="mb-4">
              <h2 className="text-lg font-semibold text-gray-900 mb-1">
                관심사 ({formData.interest_ids.length}/10)
              </h2>
              <p className="text-sm text-gray-600">최소 3개, 최대 10개의 관심사를 선택해주세요</p>
            </div>

            <div className="space-y-4 max-h-96 overflow-y-auto">
              {Object.keys(groupedInterests).map((category) => (
                <div key={category} className="border border-gray-200 rounded-lg p-4">
                  <h3 className="text-sm font-semibold text-gray-700 mb-3 capitalize">
                    {category}
                  </h3>
                  <div className="flex flex-wrap gap-2">
                    {groupedInterests[category].map((interest) => (
                      <button
                        key={interest.id}
                        type="button"
                        onClick={() => toggleInterest(interest.id)}
                        className={`px-3 py-1.5 rounded-lg text-sm transition-colors ${
                          formData.interest_ids.includes(interest.id)
                            ? 'bg-blue-600 text-white'
                            : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        }`}
                      >
                        {interest.name_ko}
                      </button>
                    ))}
                  </div>
                </div>
              ))}
            </div>
            {errors.interest_ids && (
              <p className="mt-2 text-sm text-red-600">{errors.interest_ids}</p>
            )}
          </div>

          {/* Error Message */}
          {errors.submit && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <p className="text-sm text-red-600">{errors.submit}</p>
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex gap-3">
            <Button
              type="button"
              variant="outline"
              onClick={() => router.back()}
              fullWidth
            >
              취소
            </Button>
            <Button
              type="submit"
              fullWidth
              isLoading={isLoading}
              disabled={formData.interest_ids.length < 3 || formData.interest_ids.length > 10}
            >
              저장
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function ProfileEditPage() {
  return (
    <ProtectedRoute>
      <ProfileEditContent />
    </ProtectedRoute>
  );
}
