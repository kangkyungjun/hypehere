'use client';

import { useState } from 'react';
import Button from '@/components/ui/Button';

interface ReportModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (reason: string, description: string) => Promise<void>;
  title: string;
}

const REPORT_REASONS = [
  { value: 'spam', label: '스팸 또는 광고' },
  { value: 'harassment', label: '괴롭힘 또는 악의적 행위' },
  { value: 'hate_speech', label: '혐오 발언' },
  { value: 'inappropriate', label: '부적절한 콘텐츠' },
  { value: 'violence', label: '폭력적 콘텐츠' },
  { value: 'false_info', label: '거짓 정보' },
  { value: 'other', label: '기타' },
];

export default function ReportModal({
  isOpen,
  onClose,
  onSubmit,
  title,
}: ReportModalProps) {
  const [selectedReason, setSelectedReason] = useState('');
  const [description, setDescription] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!selectedReason) {
      setError('신고 사유를 선택해주세요.');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      await onSubmit(selectedReason, description);
      // Reset form
      setSelectedReason('');
      setDescription('');
      onClose();
    } catch (error: any) {
      console.error('Failed to submit report:', error);
      setError(error.response?.data?.detail || '신고 처리에 실패했습니다.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    if (!isSubmitting) {
      setSelectedReason('');
      setDescription('');
      setError(null);
      onClose();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black bg-opacity-50">
      <div className="bg-white rounded-xl shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-xl font-bold text-gray-900">{title}</h2>
          <button
            onClick={handleClose}
            disabled={isSubmitting}
            className="text-gray-400 hover:text-gray-600"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {error && (
            <div className="p-4 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-600">{error}</p>
            </div>
          )}

          {/* Reason Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">
              신고 사유 *
            </label>
            <div className="space-y-2">
              {REPORT_REASONS.map((reason) => (
                <label
                  key={reason.value}
                  className={`flex items-center p-4 border rounded-lg cursor-pointer transition-colors ${
                    selectedReason === reason.value
                      ? 'border-blue-600 bg-blue-50'
                      : 'border-gray-300 hover:bg-gray-50'
                  }`}
                >
                  <input
                    type="radio"
                    name="reason"
                    value={reason.value}
                    checked={selectedReason === reason.value}
                    onChange={(e) => setSelectedReason(e.target.value)}
                    disabled={isSubmitting}
                    className="w-4 h-4 text-blue-600"
                  />
                  <span className="ml-3 text-gray-900">{reason.label}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Description */}
          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-2">
              상세 설명 (선택)
            </label>
            <textarea
              id="description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="추가 정보를 입력해주세요"
              rows={4}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
              disabled={isSubmitting}
            />
            <p className="mt-1 text-xs text-gray-500">
              {description.length} / 500
            </p>
          </div>

          {/* Notice */}
          <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <p className="text-sm text-yellow-800">
              허위 신고는 제재 대상이 될 수 있습니다. 신중하게 신고해주세요.
            </p>
          </div>

          {/* Buttons */}
          <div className="flex gap-3">
            <Button
              type="button"
              variant="outline"
              onClick={handleClose}
              disabled={isSubmitting}
              fullWidth
            >
              취소
            </Button>
            <Button
              type="submit"
              isLoading={isSubmitting}
              disabled={!selectedReason || isSubmitting}
              fullWidth
            >
              신고하기
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
