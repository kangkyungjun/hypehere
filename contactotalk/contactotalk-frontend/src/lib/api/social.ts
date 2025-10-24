import apiClient from './client';
import type { Post, Comment, PaginatedResponse, User } from '@/types';

// 게시글 목록 조회
export const getPosts = async (params?: {
  page?: number;
  search?: string;
  ordering?: string;
}): Promise<PaginatedResponse<Post>> => {
  const response = await apiClient.get('/social/posts/', { params });
  return response.data;
};

// 팔로잉 피드 조회
export const getFollowingFeed = async (params?: {
  page?: number;
}): Promise<PaginatedResponse<Post>> => {
  const response = await apiClient.get('/social/posts/following/', { params });
  return response.data;
};

// 게시글 상세 조회
export const getPost = async (postId: number): Promise<Post> => {
  const response = await apiClient.get(`/social/posts/${postId}/`);
  return response.data;
};

// 게시글 생성
export const createPost = async (data: FormData): Promise<Post> => {
  const response = await apiClient.post('/social/posts/', data, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return response.data;
};

// 게시글 수정
export const updatePost = async (postId: number, data: FormData): Promise<Post> => {
  const response = await apiClient.patch(`/social/posts/${postId}/`, data, {
    headers: {
      'Content-Type': 'multipart/form-data',
    },
  });
  return response.data;
};

// 게시글 삭제
export const deletePost = async (postId: number): Promise<void> => {
  await apiClient.delete(`/social/posts/${postId}/`);
};

// 게시글 좋아요
export const likePost = async (postId: number): Promise<void> => {
  await apiClient.post(`/social/posts/${postId}/like/`);
};

// 게시글 좋아요 취소
export const unlikePost = async (postId: number): Promise<void> => {
  await apiClient.delete(`/social/posts/${postId}/like/`);
};

// 댓글 목록 조회
export const getComments = async (
  postId: number,
  params?: { page?: number }
): Promise<PaginatedResponse<Comment>> => {
  const response = await apiClient.get(`/social/posts/${postId}/comments/`, {
    params,
  });
  return response.data;
};

// 댓글 생성
export const createComment = async (
  postId: number,
  content: string
): Promise<Comment> => {
  const response = await apiClient.post(`/social/posts/${postId}/comments/`, {
    content,
  });
  return response.data;
};

// 댓글 수정
export const updateComment = async (
  commentId: number,
  content: string
): Promise<Comment> => {
  const response = await apiClient.patch(`/social/comments/${commentId}/`, {
    content,
  });
  return response.data;
};

// 댓글 삭제
export const deleteComment = async (commentId: number): Promise<void> => {
  await apiClient.delete(`/social/comments/${commentId}/`);
};

// 사용자 프로필 조회
export const getUserProfile = async (userId: number): Promise<User> => {
  const response = await apiClient.get(`/social/users/${userId}/profile/`);
  return response.data;
};

// 사용자 게시글 조회
export const getUserPosts = async (
  userId: number,
  params?: { page?: number }
): Promise<PaginatedResponse<Post>> => {
  const response = await apiClient.get(`/social/users/${userId}/posts/`, {
    params,
  });
  return response.data;
};

// 팔로우
export const followUser = async (userId: number): Promise<void> => {
  await apiClient.post(`/social/users/${userId}/follow/`);
};

// 언팔로우
export const unfollowUser = async (userId: number): Promise<void> => {
  await apiClient.delete(`/social/users/${userId}/follow/`);
};

// 팔로워 목록 조회
export const getFollowers = async (
  userId: number,
  params?: { page?: number }
): Promise<PaginatedResponse<User>> => {
  const response = await apiClient.get(`/social/users/${userId}/followers/`, {
    params,
  });
  return response.data;
};

// 팔로잉 목록 조회
export const getFollowing = async (
  userId: number,
  params?: { page?: number }
): Promise<PaginatedResponse<User>> => {
  const response = await apiClient.get(`/social/users/${userId}/following/`, {
    params,
  });
  return response.data;
};
