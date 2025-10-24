'use client';

import { useEffect } from 'react';
import { useAuthStore } from '@/store/auth';

export default function AuthProvider({ children }: { children: React.ReactNode }) {
  const { _hasHydrated, isAuthenticated, loadUser } = useAuthStore();

  useEffect(() => {
    // Persist 복원 완료 후에만 실행
    if (!_hasHydrated) return;

    // 토큰 확인
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('access_token');

      // 토큰이 있지만 인증 상태가 아닌 경우 (새로고침 후 첫 로드)
      if (token && !isAuthenticated) {
        loadUser();
      }
      // 토큰이 없는데 인증 상태인 경우 (비정상 상태)
      else if (!token && isAuthenticated) {
        // 상태 초기화
        useAuthStore.setState({ user: null, isAuthenticated: false });
      }
    }
  }, [_hasHydrated, isAuthenticated, loadUser]);

  return <>{children}</>;
}
