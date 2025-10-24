'use client';

import Link from 'next/link';
import Button from '@/components/ui/Button';

export default function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="text-center max-w-md">
        <div className="mb-8">
          <h1 className="text-9xl font-bold text-blue-600">404</h1>
        </div>
        <h2 className="text-3xl font-bold text-gray-900 mb-4">
          페이지를 찾을 수 없습니다
        </h2>
        <p className="text-gray-600 mb-8">
          요청하신 페이지가 존재하지 않거나 이동되었습니다.
        </p>
        <div className="flex gap-3 justify-center">
          <Link href="/">
            <Button>홈으로 이동</Button>
          </Link>
          <button
            onClick={() => window.history.back()}
            className="px-6 py-2 text-gray-600 hover:text-gray-900 transition-colors"
          >
            뒤로 가기
          </button>
        </div>
      </div>
    </div>
  );
}
