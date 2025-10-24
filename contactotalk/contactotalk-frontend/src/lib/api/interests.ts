import apiClient from './client';
import type { Interest } from '@/types';

// 관심사 목록 조회
export const getInterests = async (category?: string): Promise<Interest[]> => {
  const params = category ? { category } : {};
  const response = await apiClient.get('/accounts/interests/', { params });
  return response.data;
};
