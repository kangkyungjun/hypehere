'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import {
  getUserProfile,
  getUserPosts,
  followUser,
  unfollowUser,
  likePost,
  unlikePost,
} from '@/lib/api/social';
import { reportUser, blockUser } from '@/lib/api/moderation';
import { formatRelativeTime } from '@/lib/utils';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Button from '@/components/ui/Button';
import ReportModal from '@/components/moderation/ReportModal';
import type { User, Post } from '@/types';

function UserProfileContent() {
  const router = useRouter();
  const params = useParams();
  const userId = parseInt(params.id as string);

  const { user: currentUser } = useAuthStore();

  const [profile, setProfile] = useState<User | null>(null);
  const [posts, setPosts] = useState<Post[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isFollowing, setIsFollowing] = useState(false);
  const [showReportModal, setShowReportModal] = useState(false);

  useEffect(() => {
    if (!userId || isNaN(userId)) {
      router.push('/social');
      return;
    }

    loadProfile();
    loadPosts();
  }, [userId, router]);

  const loadProfile = async () => {
    try {
      const data = await getUserProfile(userId);
      setProfile(data);
      setIsFollowing(data.is_following || false);
    } catch (error) {
      console.error('Failed to load profile:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const loadPosts = async () => {
    try {
      const data = await getUserPosts(userId);
      setPosts(data.results);
    } catch (error) {
      console.error('Failed to load posts:', error);
    }
  };

  const handleFollow = async () => {
    try {
      if (isFollowing) {
        await unfollowUser(userId);
      } else {
        await followUser(userId);
      }

      setIsFollowing(!isFollowing);

      // Update follower count
      if (profile) {
        setProfile({
          ...profile,
          follower_count: isFollowing
            ? (profile.follower_count || 0) - 1
            : (profile.follower_count || 0) + 1,
        });
      }
    } catch (error) {
      console.error('Failed to follow/unfollow:', error);
    }
  };

  const handleLike = async (postId: number, isLiked: boolean) => {
    try {
      if (isLiked) {
        await unlikePost(postId);
      } else {
        await likePost(postId);
      }

      setPosts((prev) =>
        prev.map((post) =>
          post.id === postId
            ? {
                ...post,
                is_liked: !isLiked,
                like_count: isLiked ? post.like_count - 1 : post.like_count + 1,
              }
            : post
        )
      );
    } catch (error) {
      console.error('Failed to like/unlike post:', error);
    }
  };

  const handleReportUser = () => {
    setShowReportModal(true);
  };

  const handleBlockUser = async () => {
    if (!confirm('이 사용자를 차단하시겠습니까?\n차단하면 서로의 게시글과 댓글을 볼 수 없습니다.')) {
      return;
    }

    try {
      await blockUser(userId);
      alert('사용자를 차단했습니다.');
      router.push('/social');
    } catch (error) {
      console.error('Failed to block user:', error);
      alert('차단에 실패했습니다.');
    }
  };

  const handleSubmitReport = async (reason: string, description: string) => {
    await reportUser(userId, reason, description);
    alert('신고가 접수되었습니다.');
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">로딩 중...</p>
        </div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <p className="text-red-600">사용자를 찾을 수 없습니다.</p>
          <Button onClick={() => router.push('/social')} className="mt-4">
            목록으로
          </Button>
        </div>
      </div>
    );
  }

  const isOwnProfile = currentUser && profile.id === currentUser.id;

  return (
    <div className="min-h-screen bg-gray-50 pb-6">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <div className="flex items-center gap-3">
            <button
              onClick={() => router.back()}
              className="text-gray-600 hover:text-gray-900"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <h1 className="text-xl font-bold text-gray-900">프로필</h1>
          </div>
        </div>
      </div>

      {/* Profile Info */}
      <div className="max-w-2xl mx-auto px-4 py-6">
        <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
          <div className="flex items-start gap-4 mb-6">
            <div className="w-20 h-20 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white font-bold text-2xl flex-shrink-0">
              {profile.nickname[0].toUpperCase()}
            </div>
            <div className="flex-1 min-w-0">
              <h2 className="text-2xl font-bold text-gray-900 mb-1">
                {profile.nickname}
              </h2>
              <p className="text-gray-600 mb-2">{profile.email}</p>
              <div className="flex gap-4 text-sm text-gray-600">
                <span>
                  {profile.country_code} · {profile.gender === 'male' ? '남성' : profile.gender === 'female' ? '여성' : '기타'}
                </span>
              </div>
            </div>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-4 mb-6 p-4 bg-gray-50 rounded-lg">
            <div className="text-center">
              <p className="text-2xl font-bold text-gray-900">{profile.post_count || 0}</p>
              <p className="text-sm text-gray-600">게시글</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-gray-900">{profile.follower_count}</p>
              <p className="text-sm text-gray-600">팔로워</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-gray-900">{profile.following_count}</p>
              <p className="text-sm text-gray-600">팔로잉</p>
            </div>
          </div>

          {/* Bio */}
          {profile.bio && (
            <p className="text-gray-900 mb-6 whitespace-pre-wrap">{profile.bio}</p>
          )}

          {/* Interests */}
          {profile.interests && profile.interests.length > 0 && (
            <div className="mb-6">
              <h3 className="text-sm font-semibold text-gray-700 mb-2">관심사</h3>
              <div className="flex flex-wrap gap-2">
                {profile.interests.map((interest) => (
                  <span
                    key={interest.id}
                    className="px-3 py-1 bg-blue-50 text-blue-600 rounded-full text-sm"
                  >
                    {interest.name_ko}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Action Buttons */}
          {!isOwnProfile && (
            <div className="space-y-3">
              <Button
                onClick={handleFollow}
                variant={isFollowing ? 'outline' : 'primary'}
                fullWidth
              >
                {isFollowing ? '팔로잉' : '팔로우'}
              </Button>
              <div className="flex gap-3">
                <Button
                  variant="outline"
                  onClick={handleReportUser}
                  fullWidth
                >
                  신고
                </Button>
                <Button
                  variant="outline"
                  onClick={handleBlockUser}
                  fullWidth
                >
                  차단
                </Button>
              </div>
            </div>
          )}
        </div>

        {/* Posts */}
        <div className="space-y-4">
          <h2 className="text-lg font-bold text-gray-900">게시글</h2>

          {posts.length === 0 ? (
            <div className="bg-white rounded-xl shadow-sm p-12 text-center">
              <p className="text-gray-500">작성한 게시글이 없습니다</p>
            </div>
          ) : (
            posts.map((post) => (
              <div
                key={post.id}
                className="bg-white rounded-xl shadow-sm overflow-hidden"
              >
                {/* Post Header */}
                <div className="p-4 border-b border-gray-100">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white font-semibold">
                      {profile.nickname[0].toUpperCase()}
                    </div>
                    <div className="flex-1">
                      <h3 className="font-semibold text-gray-900">
                        {profile.nickname}
                      </h3>
                      <p className="text-xs text-gray-500">
                        {formatRelativeTime(post.created_at)}
                      </p>
                    </div>
                  </div>
                </div>

                {/* Post Content */}
                <Link href={`/social/posts/${post.id}`}>
                  <div className="p-4 cursor-pointer hover:bg-gray-50">
                    <p className="text-gray-900 whitespace-pre-wrap mb-3">
                      {post.content}
                    </p>
                    {post.images && post.images.length > 0 && (
                      <img
                        src={post.images[0]}
                        alt="Post image"
                        className="w-full rounded-lg"
                      />
                    )}
                  </div>
                </Link>

                {/* Post Actions */}
                <div className="px-4 py-3 border-t border-gray-100 flex items-center gap-6">
                  <button
                    onClick={() => handleLike(post.id, post.is_liked)}
                    className="flex items-center gap-2 text-gray-600 hover:text-red-600 transition-colors"
                  >
                    <svg
                      className={`w-6 h-6 ${
                        post.is_liked ? 'fill-red-600 text-red-600' : 'fill-none'
                      }`}
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
                      />
                    </svg>
                    <span className="text-sm font-medium">{post.like_count}</span>
                  </button>

                  <Link
                    href={`/social/posts/${post.id}`}
                    className="flex items-center gap-2 text-gray-600 hover:text-blue-600 transition-colors"
                  >
                    <svg
                      className="w-6 h-6"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                      />
                    </svg>
                    <span className="text-sm font-medium">{post.comment_count}</span>
                  </Link>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Report Modal */}
      <ReportModal
        isOpen={showReportModal}
        onClose={() => setShowReportModal(false)}
        onSubmit={handleSubmitReport}
        title="사용자 신고"
      />
    </div>
  );
}

export default function UserProfilePage() {
  return (
    <ProtectedRoute>
      <UserProfileContent />
    </ProtectedRoute>
  );
}
