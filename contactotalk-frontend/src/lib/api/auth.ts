import apiClient from './client';
import type { User, AuthTokens, LoginRequest, RegisterRequest, ProfileUpdateRequest, UserStats } from '@/types';

// 로그인
export const login = async (data: LoginRequest): Promise<{ user: User; tokens: AuthTokens }> => {
  const response = await apiClient.post('/accounts/login/', data);

  // 토큰 저장 (백엔드는 tokens 객체 안에 토큰을 반환)
  if (typeof window !== 'undefined') {
    localStorage.setItem('access_token', response.data.tokens.access);
    localStorage.setItem('refresh_token', response.data.tokens.refresh);
  }

  return response.data;
};

// 회원가입
export const register = async (data: RegisterRequest): Promise<{ user: User; tokens: AuthTokens }> => {
  const response = await apiClient.post('/accounts/register/', data);

  // 토큰 저장 (백엔드는 tokens 객체 안에 토큰을 반환)
  if (typeof window !== 'undefined') {
    localStorage.setItem('access_token', response.data.tokens.access);
    localStorage.setItem('refresh_token', response.data.tokens.refresh);
  }

  return response.data;
};

// 로그아웃
export const logout = async (): Promise<void> => {
  try {
    // 1. 먼저 활성 채팅방 조회
    try {
      const rooms = await apiClient.get('/chat/rooms/');

      // 2. 모든 활성 방에서 나가기
      if (rooms.data && Array.isArray(rooms.data)) {
        await Promise.allSettled(
          rooms.data.map((room: any) =>
            apiClient.post(`/chat/rooms/${room.id}/leave/`).catch(err => {
              console.warn(`Failed to leave room ${room.id}:`, err);
            })
          )
        );
      }
    } catch (error) {
      console.warn('Failed to leave chat rooms during logout:', error);
    }

    // 3. 로그아웃 API 호출
    await apiClient.post('/accounts/logout/');
  } finally {
    // 4. 토큰 삭제
    if (typeof window !== 'undefined') {
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
    }
  }
};

// 현재 사용자 정보 조회
export const getCurrentUser = async (): Promise<User> => {
  const response = await apiClient.get('/accounts/profile/');
  return response.data;
};

// 프로필 업데이트
export const updateProfile = async (data: ProfileUpdateRequest): Promise<User> => {
  const response = await apiClient.patch('/accounts/profile/update/', data);
  return response.data;
};

// 토큰 갱신
export const refreshToken = async (refresh: string): Promise<AuthTokens> => {
  const response = await apiClient.post('/accounts/token/refresh/', {
    refresh,
  });

  // 새 토큰 저장
  if (typeof window !== 'undefined') {
    localStorage.setItem('access_token', response.data.access);
  }

  return response.data;
};

// 토큰 검증
export const verifyToken = async (token: string): Promise<boolean> => {
  try {
    await apiClient.post('/accounts/token/verify/', {
      token,
    });
    return true;
  } catch {
    return false;
  }
};

// 사용자 통계 조회
export const getUserStats = async (): Promise<UserStats> => {
  const response = await apiClient.get('/accounts/stats/');
  return response.data;
};
