'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createOpenChatRoom } from '@/lib/api/openChat';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Button from '@/components/ui/Button';
import Input from '@/components/ui/Input';
import ConfirmModal from '@/components/ui/ConfirmModal';

function CreateOpenChatContent() {
  const router = useRouter();

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: '',
    max_participants: '',
    is_public: true,
    password: '',
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [showErrorModal, setShowErrorModal] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  const categories = [
    { value: 'language', label: '언어 교환' },
    { value: 'hobby', label: '취미' },
    { value: 'study', label: '스터디' },
    { value: 'game', label: '게임' },
    { value: 'other', label: '기타' },
  ];

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.title.trim()) {
      newErrors.title = '채팅방 제목을 입력하세요.';
    } else if (formData.title.length < 2 || formData.title.length > 100) {
      newErrors.title = '제목은 2-100자 사이여야 합니다.';
    }

    if (formData.description && formData.description.length > 500) {
      newErrors.description = '설명은 500자 이하여야 합니다.';
    }

    if (formData.max_participants) {
      const maxPart = parseInt(formData.max_participants);
      if (isNaN(maxPart) || maxPart < 2 || maxPart > 500) {
        newErrors.max_participants = '참여자 수는 2-500명 사이여야 합니다.';
      }
    }

    if (!formData.is_public && !formData.password) {
      newErrors.password = '비공개 채팅방은 비밀번호가 필요합니다.';
    }

    if (formData.password && formData.password.length < 4) {
      newErrors.password = '비밀번호는 4자 이상이어야 합니다.';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);

    try {
      const room = await createOpenChatRoom({
        title: formData.title,
        description: formData.description || undefined,
        category: formData.category || undefined,
        max_participants: formData.max_participants
          ? parseInt(formData.max_participants)
          : undefined,
        is_public: formData.is_public,
        password: formData.password || undefined,
      });

      router.push(`/open-chat/${room.id}`);
    } catch (error: any) {
      console.error('Failed to create room:', error);

      // 백엔드에서 받은 에러 메시지 처리
      if (error.response?.data) {
        const errorData = error.response.data;

        // ValidationError: detail 필드에 메시지가 있는 경우
        if (errorData.detail) {
          setErrorMessage(errorData.detail);
          setShowErrorModal(true);
        }
        // 필드별 에러가 있는 경우
        else if (typeof errorData === 'object') {
          setErrors(errorData);
        }
        else {
          setErrorMessage('채팅방 생성에 실패했습니다.');
          setShowErrorModal(true);
        }
      } else {
        setErrorMessage('채팅방 생성에 실패했습니다.');
        setShowErrorModal(true);
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <div className="flex items-center gap-3">
            <button
              onClick={() => router.back()}
              className="text-gray-600 hover:text-gray-900"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <h1 className="text-xl font-bold text-gray-900">오픈 채팅방 만들기</h1>
          </div>
        </div>
      </div>

      {/* Form */}
      <div className="max-w-2xl mx-auto px-4 py-6">
        <form onSubmit={handleSubmit} className="bg-white rounded-xl shadow-sm p-6 space-y-6">
          {/* Title */}
          <div>
            <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-2">
              채팅방 제목 *
            </label>
            <Input
              id="title"
              type="text"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="채팅방 제목을 입력하세요"
              error={errors.title}
            />
          </div>

          {/* Description */}
          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-2">
              설명
            </label>
            <textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="채팅방 설명 (선택)"
              rows={4}
              className={`w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                errors.description ? 'border-red-500' : 'border-gray-300'
              }`}
            />
            {errors.description && (
              <p className="mt-1 text-sm text-red-600">{errors.description}</p>
            )}
          </div>

          {/* Category */}
          <div>
            <label htmlFor="category" className="block text-sm font-medium text-gray-700 mb-2">
              카테고리
            </label>
            <select
              id="category"
              value={formData.category}
              onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">선택 안함</option>
              {categories.map((cat) => (
                <option key={cat.value} value={cat.value}>
                  {cat.label}
                </option>
              ))}
            </select>
          </div>

          {/* Max Participants */}
          <div>
            <label htmlFor="max_participants" className="block text-sm font-medium text-gray-700 mb-2">
              최대 참여자 수
            </label>
            <Input
              id="max_participants"
              type="number"
              value={formData.max_participants}
              onChange={(e) => setFormData({ ...formData, max_participants: e.target.value })}
              placeholder="제한 없음"
              error={errors.max_participants}
            />
            <p className="mt-1 text-xs text-gray-500">
              비워두면 제한이 없습니다. (2-500명)
            </p>
          </div>

          {/* Public/Private */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">
              공개 설정
            </label>
            <div className="space-y-2">
              <label className="flex items-center p-4 border border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50">
                <input
                  type="radio"
                  name="is_public"
                  checked={formData.is_public}
                  onChange={() => setFormData({ ...formData, is_public: true, password: '' })}
                  className="w-4 h-4 text-blue-600"
                />
                <div className="ml-3">
                  <p className="font-medium text-gray-900">공개</p>
                  <p className="text-sm text-gray-600">누구나 입장할 수 있습니다</p>
                </div>
              </label>
              <label className="flex items-center p-4 border border-gray-300 rounded-lg cursor-pointer hover:bg-gray-50">
                <input
                  type="radio"
                  name="is_public"
                  checked={!formData.is_public}
                  onChange={() => setFormData({ ...formData, is_public: false })}
                  className="w-4 h-4 text-blue-600"
                />
                <div className="ml-3">
                  <p className="font-medium text-gray-900">비공개</p>
                  <p className="text-sm text-gray-600">비밀번호가 필요합니다</p>
                </div>
              </label>
            </div>
          </div>

          {/* Password */}
          {!formData.is_public && (
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                비밀번호 *
              </label>
              <Input
                id="password"
                type="password"
                value={formData.password}
                onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                placeholder="4자 이상"
                error={errors.password}
              />
            </div>
          )}

          {/* Submit */}
          <div className="flex gap-3 pt-4">
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
              isLoading={isSubmitting}
              disabled={isSubmitting}
              fullWidth
            >
              만들기
            </Button>
          </div>
        </form>
      </div>

      {/* Error Modal */}
      <ConfirmModal
        isOpen={showErrorModal}
        message={errorMessage}
        confirmText="확인"
        onConfirm={() => {
          setShowErrorModal(false);
          router.push('/open-chat');
        }}
        onCancel={() => {
          setShowErrorModal(false);
          router.push('/open-chat');
        }}
      />
    </div>
  );
}

export default function CreateOpenChatPage() {
  return (
    <ProtectedRoute>
      <CreateOpenChatContent />
    </ProtectedRoute>
  );
}
