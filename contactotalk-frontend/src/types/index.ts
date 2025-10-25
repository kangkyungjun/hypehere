// ============================================================================
// User & Auth Types
// ============================================================================

export interface Country {
  id: number;
  code: string;
  name: string;
}

export interface Interest {
  id: number;
  name: string;
  name_ko: string;
  name_en: string;
  category: string;
  icon?: string;
}

export interface User {
  id: number;
  username: string;
  email: string;
  nickname: string;
  country_code: string;
  bio?: string;
  gender?: 'male' | 'female' | 'undisclosed';
  role: 'visitor' | 'user' | 'premium_user' | 'manager' | 'prime';
  is_premium: boolean;
  daily_match_count: number;
  is_banned: boolean;
  created_at: string;
  interests: Interest[];
  follower_count?: number;
  following_count?: number;
  post_count?: number;
  is_following?: boolean;
}

export interface AuthTokens {
  access: string;
  refresh: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
  password2: string;
  nickname: string;
  country_code: string;
  bio?: string;
  gender?: 'male' | 'female' | 'undisclosed';
  interest_ids: number[];
}

export interface ProfileUpdateRequest {
  nickname?: string;
  bio?: string;
  gender?: 'male' | 'female' | 'undisclosed';
  country_code?: string;
  interest_ids?: number[];
}

export interface UserStats {
  today_match_count: number;
  open_chat_count: number;
}

// ============================================================================
// Chat Types
// ============================================================================

export interface ChatRoom {
  id: number;
  user1: User;
  user2: User;
  created_at: string;
  last_message?: Message;
  unread_count: number;
}

export interface Message {
  id: number;
  room: number;
  sender: User;
  message_type: 'text' | 'image' | 'file' | 'system';
  content: string;
  image?: string;
  file?: string;
  is_read: boolean;
  created_at: string;
}

export interface MatchHistory {
  id: number;
  matched_user: User;
  matched_at: string;
  last_message_preview?: string;
}

export interface BlockedUser {
  id: number;
  blocked_user: User;
  reason?: string;
  created_at: string;
}

export interface OpenChatRoom {
  id: number;
  room_type: 'default' | 'user_created';
  title: string;
  description?: string;
  category?: string;
  country_code: string;
  creator?: User;
  participants?: User[];
  participant_count: number;
  max_participants: number;
  is_full?: boolean;
  is_joined?: boolean;
  is_public?: boolean;
  can_delete?: boolean;
  tags: string[];
  tags_list?: string[];
  is_active: boolean;
  created_at: string;
  updated_at?: string;
}

export interface OpenChatMessage {
  id: number;
  room: number;
  sender?: User;
  message_type: 'text' | 'image' | 'join' | 'leave';
  content: string;
  image?: string;
  created_at: string;
}

// ============================================================================
// Social Types
// ============================================================================

export interface Post {
  id: number;
  author: User;
  content: string;
  images: string[];
  like_count: number;
  comment_count: number;
  view_count: number;
  is_liked: boolean;
  is_mine: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface Comment {
  id: number;
  post: number;
  author: User;
  content: string;
  parent?: number;
  like_count: number;
  reply_count: number;
  is_liked: boolean;
  is_mine: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface UserProfile {
  id: number;
  user: User;
  bio?: string;
  website?: string;
  location?: string;
  avatar_url?: string;
  cover_image_url?: string;
  post_count: number;
  follower_count: number;
  following_count: number;
  created_at: string;
  updated_at: string;
}

export interface Follow {
  id: number;
  follower: User;
  following: User;
  created_at: string;
}

// ============================================================================
// Moderation Types
// ============================================================================

export interface Report {
  id: number;
  reporter: User;
  report_type: 'user' | 'post' | 'comment' | 'message' | 'open_chat_message';
  reason: string;
  description: string;
  status: 'pending' | 'reviewing' | 'resolved' | 'rejected';
  reviewer?: User;
  resolution?: string;
  resolved_at?: string;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// Premium Types
// ============================================================================

export interface Subscription {
  id: number;
  name: string;
  plan_type: 'monthly' | 'quarterly' | 'yearly';
  price: string;
  duration_days: number;
  is_ad_free: boolean;
  unlimited_matches: boolean;
  priority_matching: boolean;
  profile_boost: boolean;
  custom_badge: boolean;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface UserSubscription {
  id: number;
  user: User;
  subscription: Subscription;
  start_date: string;
  end_date: string;
  status: 'active' | 'expired' | 'cancelled';
  auto_renew: boolean;
  is_valid: boolean;
  is_expired: boolean;
  created_at: string;
  updated_at: string;
}

export interface Payment {
  id: number;
  user: User;
  user_subscription?: number;
  payment_method: 'card' | 'bank_transfer' | 'mobile' | 'kakaopay' | 'toss';
  amount: string;
  currency: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  transaction_id: string;
  pg_provider: string;
  receipt_url?: string;
  refunded_at?: string;
  refund_reason?: string;
  created_at: string;
  updated_at: string;
}

export interface Advertisement {
  id: number;
  advertiser_name: string;
  title: string;
  description: string;
  ad_type: 'banner' | 'video' | 'native';
  image_url?: string;
  video_url?: string;
  link_url: string;
  start_date: string;
  end_date: string;
  target_countries: string[];
  target_age_min?: number;
  target_age_max?: number;
  total_impressions: number;
  total_clicks: number;
  ctr: number;
  status: 'active' | 'paused' | 'ended';
  is_active_now: boolean;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// API Response Types
// ============================================================================

export interface ApiError {
  error?: string;
  detail?: string;
  [key: string]: any;
}

export interface PaginatedResponse<T> {
  count: number;
  next: string | null;
  previous: string | null;
  results: T[];
}
