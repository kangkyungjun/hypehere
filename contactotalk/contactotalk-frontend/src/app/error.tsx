'use client';

import { useEffect } from 'react';
import Button from '@/components/ui/Button';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error('Error:', error);
  }, [error]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="text-center max-w-md">
        <div className="inline-flex items-center justify-center w-20 h-20 bg-red-100 rounded-full mb-6">
          <svg
            className="w-10 h-10 text-red-600"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
        </div>
        <h1 className="text-2xl font-bold text-gray-900 mb-2">
          문제가 발생했습니다
        </h1>
        <p className="text-gray-600 mb-6">
          일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.
        </p>
        {process.env.NODE_ENV === 'development' && (
          <pre className="text-left text-xs text-red-600 bg-red-50 p-4 rounded-lg mb-6 overflow-auto max-h-40">
            {error.message}
          </pre>
        )}
        <div className="flex gap-3 justify-center">
          <Button variant="outline" onClick={() => (window.location.href = '/')}>
            홈으로
          </Button>
          <Button onClick={reset}>다시 시도</Button>
        </div>
      </div>
    </div>
  );
}
