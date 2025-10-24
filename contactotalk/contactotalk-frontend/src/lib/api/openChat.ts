import apiClient from './client';
import type { OpenChatRoom, Message, PaginatedResponse } from '@/types';

// 오픈 채팅방 목록 조회
export const getOpenChatRooms = async (params?: {
  page?: number;
  search?: string;
  category?: string;
  user_filter?: string;
  ordering?: string;
}): Promise<PaginatedResponse<OpenChatRoom>> => {
  const response = await apiClient.get('/chat/open/rooms/', { params });
  return response.data;
};

// 오픈 채팅방 생성
export const createOpenChatRoom = async (data: {
  title: string;
  description?: string;
  category?: string;
  max_participants?: number;
  is_public: boolean;
  password?: string;
}): Promise<OpenChatRoom> => {
  const response = await apiClient.post('/chat/open/rooms/', data);
  return response.data;
};

// 오픈 채팅방 상세 조회
export const getOpenChatRoom = async (roomId: number): Promise<OpenChatRoom> => {
  const response = await apiClient.get(`/chat/open/rooms/${roomId}/`);
  return response.data;
};

// 오픈 채팅방 수정
export const updateOpenChatRoom = async (
  roomId: number,
  data: Partial<{
    title: string;
    description: string;
    category: string;
    max_participants: number;
    is_public: boolean;
    password: string;
  }>
): Promise<OpenChatRoom> => {
  const response = await apiClient.patch(`/chat/open/rooms/${roomId}/`, data);
  return response.data;
};

// 오픈 채팅방 삭제
export const deleteOpenChatRoom = async (roomId: number): Promise<void> => {
  await apiClient.delete(`/chat/open/rooms/${roomId}/delete/`);
};

// 오픈 채팅방 메시지 조회
export const getOpenChatMessages = async (
  roomId: number,
  page: number = 1
): Promise<PaginatedResponse<Message>> => {
  const response = await apiClient.get(`/chat/open/rooms/${roomId}/messages/`, {
    params: { page },
  });
  return response.data;
};

// 오픈 채팅방 입장
export const joinOpenChatRoom = async (
  roomId: number,
  password?: string
): Promise<void> => {
  await apiClient.post(`/chat/open/rooms/${roomId}/join/`, { password });
};

// 오픈 채팅방 나가기
export const leaveOpenChatRoom = async (roomId: number): Promise<void> => {
  await apiClient.post(`/chat/open/rooms/${roomId}/leave/`);
};

// 참여자 강퇴 (방장만 가능)
export const kickParticipant = async (
  roomId: number,
  userId: number
): Promise<void> => {
  await apiClient.post(`/chat/open/rooms/${roomId}/kick/`, { user_id: userId });
};
