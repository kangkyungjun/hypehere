import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatDate(date: string | Date): string {
  const d = new Date(date);
  return d.toLocaleDateString('ko-KR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

export function formatDateTime(date: string | Date): string {
  const d = new Date(date);
  return d.toLocaleString('ko-KR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export function formatRelativeTime(date: string | Date): string {
  const d = new Date(date);
  const now = new Date();
  const diffInSeconds = Math.floor((now.getTime() - d.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return '방금 전';
  } else if (diffInSeconds < 3600) {
    return `${Math.floor(diffInSeconds / 60)}분 전`;
  } else if (diffInSeconds < 86400) {
    return `${Math.floor(diffInSeconds / 3600)}시간 전`;
  } else if (diffInSeconds < 604800) {
    return `${Math.floor(diffInSeconds / 86400)}일 전`;
  } else {
    return formatDate(d);
  }
}

export function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) {
    return text;
  }
  return text.slice(0, maxLength) + '...';
}

export function getCountryFlag(countryCode: string): string {
  const flagMap: Record<string, string> = {
    KOR: '🇰🇷',
    USA: '🇺🇸',
    JPN: '🇯🇵',
    CHN: '🇨🇳',
    GBR: '🇬🇧',
    FRA: '🇫🇷',
    DEU: '🇩🇪',
    ESP: '🇪🇸',
    ITA: '🇮🇹',
    BRA: '🇧🇷',
    CAN: '🇨🇦',
    AUS: '🇦🇺',
    IND: '🇮🇳',
    RUS: '🇷🇺',
    MEX: '🇲🇽',
  };

  return flagMap[countryCode] || '🌐';
}
