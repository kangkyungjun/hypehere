import apiClient from './client';
import type { Country, Interest } from '@/types';

// 국가 목록 조회
export const getCountries = async (): Promise<Country[]> => {
  const response = await apiClient.get('/accounts/countries/');
  return response.data;
};

// 관심사 목록 조회
export const getInterests = async (): Promise<Interest[]> => {
  const response = await apiClient.get('/accounts/interests/');
  return response.data;
};

// 사용자 관심사 선택
export const selectInterests = async (interestIds: number[]): Promise<void> => {
  await apiClient.post('/accounts/interests/select/', {
    interests: interestIds,
  });
};
