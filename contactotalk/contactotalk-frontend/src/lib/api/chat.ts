import apiClient from './client';
import type { ChatRoom, Message, PaginatedResponse, MatchHistory, BlockedUser } from '@/types';

// 매칭 시작
export const startMatching = async (
  country_preference?: string | null,
  gender_preference?: string | null
): Promise<void> => {
  await apiClient.post('/chat/matching/start/', {
    country_preference: country_preference || null,
    gender_preference: gender_preference || null,
  });
};

// 매칭 취소
export const cancelMatching = async (): Promise<void> => {
  await apiClient.post('/chat/matching/cancel/');
};

// 매칭 상태 확인
export const getMatchingStatus = async (): Promise<{
  is_matching: boolean;
  matched_room?: number;
}> => {
  const response = await apiClient.get('/chat/matching/status/');
  return response.data;
};

// 채팅방 목록 조회
export const getChatRooms = async (): Promise<ChatRoom[]> => {
  const response = await apiClient.get('/chat/rooms/');
  return response.data;
};

// 채팅방 상세 조회
export const getChatRoom = async (roomId: number): Promise<ChatRoom> => {
  const response = await apiClient.get(`/chat/rooms/${roomId}/`);
  return response.data;
};

// 메시지 목록 조회
export const getMessages = async (
  roomId: number,
  page: number = 1
): Promise<PaginatedResponse<Message>> => {
  const response = await apiClient.get(`/chat/rooms/${roomId}/messages/`, {
    params: { page },
  });
  return response.data;
};

// 메시지 읽음 처리
export const markMessagesAsRead = async (roomId: number): Promise<void> => {
  await apiClient.post(`/chat/rooms/${roomId}/read/`);
};

// 채팅방 나가기
export const leaveChatRoom = async (roomId: number): Promise<void> => {
  await apiClient.post(`/chat/rooms/${roomId}/leave/`);
};

// 매칭 이력 조회 (최근 5일)
export const getMatchHistory = async (): Promise<MatchHistory[]> => {
  const response = await apiClient.get('/chat/match-history/');
  // DRF pagination: {count, next, previous, results}
  return response.data.results || response.data;
};

// 사용자 차단
export const blockUser = async (userId: number, reason?: string): Promise<void> => {
  await apiClient.post('/chat/block/', {
    user_id: userId,
    reason: reason || '',
  });
};

// 차단 해제
export const unblockUser = async (userId: number): Promise<void> => {
  await apiClient.post(`/chat/unblock/${userId}/`);
};

// 차단 목록 조회
export const getBlockedUsers = async (): Promise<BlockedUser[]> => {
  const response = await apiClient.get('/chat/blocked/');
  // DRF pagination: {count, next, previous, results}
  return response.data.results || response.data;
};
