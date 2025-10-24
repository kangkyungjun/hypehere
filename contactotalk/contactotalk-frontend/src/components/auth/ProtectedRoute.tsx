'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requireAuth?: boolean;
  redirectTo?: string;
}

export default function ProtectedRoute({
  children,
  requireAuth = true,
  redirectTo = '/login',
}: ProtectedRouteProps) {
  const router = useRouter();
  const { isAuthenticated, isLoading, _hasHydrated } = useAuthStore();

  useEffect(() => {
    // Persist 복원이 완료될 때까지 대기
    if (!_hasHydrated) return;

    // 로딩 중일 때는 리다이렉트하지 않음 (API 응답 대기)
    if (isLoading) return;

    // 인증 필요한 페이지인데 인증되지 않은 경우
    if (requireAuth && !isAuthenticated) {
      // 토큰 확인
      const token = typeof window !== 'undefined' ? localStorage.getItem('access_token') : null;

      // 토큰도 없으면 로그인 페이지로
      if (!token) {
        router.push(redirectTo);
      }
    }
  }, [_hasHydrated, isLoading, isAuthenticated, requireAuth, redirectTo, router]);

  // Persist 복원 대기 중
  if (!_hasHydrated) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">로딩 중...</p>
        </div>
      </div>
    );
  }

  // 사용자 정보 로딩 중
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

  // 인증 필요한데 인증 안 된 경우
  if (requireAuth && !isAuthenticated) {
    return null; // 리다이렉트 처리됨
  }

  return <>{children}</>;
}
