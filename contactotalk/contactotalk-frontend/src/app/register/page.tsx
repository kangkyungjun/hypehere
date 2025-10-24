'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import { getInterests } from '@/lib/api/interests';
import Input from '@/components/ui/Input';
import Button from '@/components/ui/Button';
import CountrySelect from '@/components/ui/CountrySelect';
import type { Interest } from '@/types';

export default function RegisterPage() {
  const router = useRouter();
  const { register, error, clearError } = useAuthStore();

  const [step, setStep] = useState(1);
  const [isLoading, setIsLoading] = useState(false);
  const [interests, setInterests] = useState<Interest[]>([]);
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
    password2: '',
    nickname: '',
    country_code: 'KOR',
    bio: '',
    gender: '' as 'male' | 'female' | 'undisclosed' | '',
    interest_ids: [] as number[],
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    // 관심사 목록 로드
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

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    setErrors((prev) => ({ ...prev, [name]: '' }));
    clearError();
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

  const validateStep1 = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.username.trim()) {
      newErrors.username = '사용자명을 입력해주세요.';
    }

    if (!formData.email.trim()) {
      newErrors.email = '이메일을 입력해주세요.';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = '올바른 이메일 형식이 아닙니다.';
    }

    if (!formData.password) {
      newErrors.password = '비밀번호를 입력해주세요.';
    } else if (formData.password.length < 8) {
      newErrors.password = '비밀번호는 최소 8자 이상이어야 합니다.';
    }

    if (!formData.password2) {
      newErrors.password2 = '비밀번호 확인을 입력해주세요.';
    } else if (formData.password !== formData.password2) {
      newErrors.password2 = '비밀번호가 일치하지 않습니다.';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const validateStep2 = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.nickname.trim()) {
      newErrors.nickname = '닉네임을 입력해주세요.';
    } else if (formData.nickname.length < 2 || formData.nickname.length > 20) {
      newErrors.nickname = '닉네임은 2-20자 사이여야 합니다.';
    }

    if (!formData.country_code) {
      newErrors.country_code = '국가를 선택해주세요.';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const validateStep3 = () => {
    const newErrors: Record<string, string> = {};

    if (formData.interest_ids.length < 3) {
      newErrors.interest_ids = '최소 3개의 관심사를 선택해주세요.';
    } else if (formData.interest_ids.length > 10) {
      newErrors.interest_ids = '최대 10개까지 선택 가능합니다.';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleNext = () => {
    if (step === 1 && validateStep1()) {
      setStep(2);
    } else if (step === 2 && validateStep2()) {
      setStep(3);
    }
  };

  const handleBack = () => {
    if (step > 1) {
      setStep(step - 1);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateStep3()) return;

    setIsLoading(true);

    try {
      // Convert empty string to undefined for gender
      await register({
        ...formData,
        gender: formData.gender || undefined,
      });
      router.push('/chat');
    } catch (error) {
      console.error('Register failed:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const groupedInterests = interests.reduce((acc, interest) => {
    const category = interest.category || 'other';
    if (!acc[category]) {
      acc[category] = [];
    }
    acc[category].push(interest);
    return acc;
  }, {} as Record<string, Interest[]>);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 py-8">
      <div className="max-w-2xl w-full">
        <div className="bg-white rounded-2xl shadow-xl p-8">
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold text-gray-900 mb-2">회원가입</h1>
            <p className="text-gray-600">ConTacToTalk에 가입하고 전 세계 사람들과 소통하세요</p>
          </div>

          <div className="flex items-center justify-center mb-8">
            <div className="flex items-center">
              <div className={`w-10 h-10 rounded-full flex items-center justify-center ${step >= 1 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'}`}>
                1
              </div>
              <div className={`w-16 h-1 ${step >= 2 ? 'bg-blue-600' : 'bg-gray-200'}`}></div>
              <div className={`w-10 h-10 rounded-full flex items-center justify-center ${step >= 2 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'}`}>
                2
              </div>
              <div className={`w-16 h-1 ${step >= 3 ? 'bg-blue-600' : 'bg-gray-200'}`}></div>
              <div className={`w-10 h-10 rounded-full flex items-center justify-center ${step >= 3 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'}`}>
                3
              </div>
            </div>
          </div>

          {error && (
            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-600">{error}</p>
            </div>
          )}

          {step === 1 && (
            <form className="space-y-6">
              <Input
                label="사용자명 (Username)"
                type="text"
                name="username"
                value={formData.username}
                onChange={handleChange}
                error={errors.username}
                placeholder="1자 이상"
                required
              />
              <Input
                label="이메일"
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                error={errors.email}
                placeholder="example@email.com"
                required
              />
              <Input
                label="비밀번호"
                type="password"
                name="password"
                value={formData.password}
                onChange={handleChange}
                error={errors.password}
                placeholder="8자 이상"
                required
              />
              <Input
                label="비밀번호 확인"
                type="password"
                name="password2"
                value={formData.password2}
                onChange={handleChange}
                error={errors.password2}
                placeholder="비밀번호 재입력"
                required
              />
              <Button type="button" onClick={handleNext} fullWidth>
                다음
              </Button>
            </form>
          )}

          {step === 2 && (
            <form className="space-y-6">
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
                <label htmlFor="bio" className="block text-sm font-medium text-gray-700 mb-1">자기소개 (선택)</label>
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
              </div>
              <div className="flex gap-3">
                <Button type="button" variant="outline" onClick={handleBack} fullWidth>이전</Button>
                <Button type="button" onClick={handleNext} fullWidth>다음</Button>
              </div>
            </form>
          )}

          {step === 3 && (
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <h2 className="text-lg font-semibold text-gray-900 mb-4">
                  관심사 선택 ({formData.interest_ids.length}/10) *
                </h2>
                <p className="text-sm text-gray-600 mb-4">최소 3개, 최대 10개의 관심사를 선택해주세요</p>
                <div className="space-y-4 max-h-96 overflow-y-auto">
                  {Object.keys(groupedInterests).map((category) => (
                    <div key={category} className="border border-gray-200 rounded-lg p-4">
                      <h3 className="text-sm font-semibold text-gray-700 mb-3 capitalize">{category}</h3>
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
                {errors.interest_ids && <p className="mt-2 text-sm text-red-600">{errors.interest_ids}</p>}
              </div>
              <div className="flex gap-3">
                <Button type="button" variant="outline" onClick={handleBack} fullWidth>이전</Button>
                <Button type="submit" fullWidth isLoading={isLoading} disabled={formData.interest_ids.length < 3 || formData.interest_ids.length > 10}>
                  가입 완료
                </Button>
              </div>
            </form>
          )}

          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600">
              이미 계정이 있으신가요?{' '}
              <Link href="/login" className="font-semibold text-blue-600 hover:text-blue-700">로그인</Link>
            </p>
          </div>
        </div>
        <div className="mt-6 text-center">
          <Link href="/" className="text-sm text-gray-600 hover:text-gray-900">← 홈으로 돌아가기</Link>
        </div>
      </div>
    </div>
  );
}
