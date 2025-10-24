import apiClient from './client';
import type { Report, PaginatedResponse } from '@/types';

// 게시글 신고
export const reportPost = async (
  postId: number,
  reason: string,
  description?: string
): Promise<Report> => {
  const response = await apiClient.post('/moderation/reports/', {
    content_type: 'post',
    object_id: postId,
    reason,
    description,
  });
  return response.data;
};

// 댓글 신고
export const reportComment = async (
  commentId: number,
  reason: string,
  description?: string
): Promise<Report> => {
  const response = await apiClient.post('/moderation/reports/', {
    content_type: 'comment',
    object_id: commentId,
    reason,
    description,
  });
  return response.data;
};

// 사용자 신고
export const reportUser = async (
  userId: number,
  reason: string,
  description?: string
): Promise<Report> => {
  const response = await apiClient.post('/moderation/reports/', {
    content_type: 'user',
    object_id: userId,
    reason,
    description,
  });
  return response.data;
};

// 채팅방 신고
export const reportChatRoom = async (
  roomId: number,
  reason: string,
  description?: string
): Promise<Report> => {
  const response = await apiClient.post('/moderation/reports/', {
    content_type: 'chatroom',
    object_id: roomId,
    reason,
    description,
  });
  return response.data;
};

// 오픈 채팅방 신고
export const reportOpenChatRoom = async (
  roomId: number,
  reason: string,
  description?: string
): Promise<Report> => {
  const response = await apiClient.post('/moderation/reports/', {
    content_type: 'openchatroom',
    object_id: roomId,
    reason,
    description,
  });
  return response.data;
};

// 사용자 차단
export const blockUser = async (userId: number): Promise<void> => {
  await apiClient.post('/moderation/blocks/', {
    blocked_user_id: userId,
  });
};

// 사용자 차단 해제
export const unblockUser = async (blockId: number): Promise<void> => {
  await apiClient.delete(`/moderation/blocks/${blockId}/`);
};

// 차단 목록 조회
export const getBlockedUsers = async (
  params?: { page?: number }
): Promise<PaginatedResponse<any>> => {
  const response = await apiClient.get('/moderation/blocks/', { params });
  return response.data;
};

// 내 신고 내역 조회
export const getMyReports = async (
  params?: { page?: number }
): Promise<PaginatedResponse<Report>> => {
  const response = await apiClient.get('/moderation/reports/my/', { params });
  return response.data;
};
