'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import { getPosts, getFollowingFeed, likePost, unlikePost } from '@/lib/api/social';
import { formatRelativeTime } from '@/lib/utils';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Button from '@/components/ui/Button';
import type { Post } from '@/types';

function SocialFeedContent() {
  const router = useRouter();
  const { user } = useAuthStore();

  const [posts, setPosts] = useState<Post[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [feedType, setFeedType] = useState<'all' | 'following'>('all');

  useEffect(() => {
    loadPosts();
  }, [feedType]);

  const loadPosts = async () => {
    try {
      const data =
        feedType === 'following'
          ? await getFollowingFeed()
          : await getPosts({ ordering: '-created_at' });
      setPosts(data.results);
      setError(null);
    } catch (error) {
      console.error('Failed to load posts:', error);
      setError('게시글을 불러오는데 실패했습니다.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleLike = async (postId: number, isLiked: boolean) => {
    try {
      if (isLiked) {
        await unlikePost(postId);
      } else {
        await likePost(postId);
      }

      // Update local state
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

  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between mb-4">
            <h1 className="text-2xl font-bold text-gray-900">SNS</h1>
            <Button size="sm" onClick={() => router.push('/social/create')}>
              <svg
                className="w-5 h-5 mr-2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 4v16m8-8H4"
                />
              </svg>
              글쓰기
            </Button>
          </div>

          {/* Feed Type Tabs */}
          <div className="flex gap-2">
            <button
              onClick={() => setFeedType('all')}
              className={`flex-1 py-2 px-4 rounded-lg font-medium transition-colors ${
                feedType === 'all'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              전체
            </button>
            <button
              onClick={() => setFeedType('following')}
              className={`flex-1 py-2 px-4 rounded-lg font-medium transition-colors ${
                feedType === 'following'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              팔로잉
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-2xl mx-auto px-4 py-6">
        {error && (
          <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {posts.length === 0 ? (
          <div className="bg-white rounded-xl shadow-sm p-12 text-center">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-gray-100 rounded-full mb-4">
              <svg
                className="w-10 h-10 text-gray-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"
                />
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              게시글이 없습니다
            </h3>
            <p className="text-gray-600 mb-6">
              첫 번째 게시글을 작성해보세요
            </p>
            <Button onClick={() => router.push('/social/create')}>
              글쓰기
            </Button>
          </div>
        ) : (
          <div className="space-y-4">
            {posts.map((post) => (
              <div
                key={post.id}
                className="bg-white rounded-xl shadow-sm overflow-hidden"
              >
                {/* Post Header */}
                <div className="p-4 border-b border-gray-100">
                  <div className="flex items-center gap-3">
                    <Link href={`/social/users/${post.author.id}`}>
                      <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white font-semibold cursor-pointer hover:opacity-80">
                        {post.author.nickname[0].toUpperCase()}
                      </div>
                    </Link>
                    <div className="flex-1">
                      <Link href={`/social/users/${post.author.id}`}>
                        <h3 className="font-semibold text-gray-900 hover:text-blue-600">
                          {post.author.nickname}
                        </h3>
                      </Link>
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
            ))}
          </div>
        )}
      </div>

      {/* Bottom Navigation */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 py-2">
        <div className="max-w-4xl mx-auto px-4">
          <div className="grid grid-cols-4 gap-2">
            <Link
              href="/"
              className="flex flex-col items-center py-2 text-gray-600 hover:text-blue-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              <span className="text-xs mt-1">홈</span>
            </Link>
            <Link
              href="/chat"
              className="flex flex-col items-center py-2 text-gray-600 hover:text-blue-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
              <span className="text-xs mt-1">채팅</span>
            </Link>
            <Link
              href="/open-chat"
              className="flex flex-col items-center py-2 text-gray-600 hover:text-blue-600"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
              <span className="text-xs mt-1">오픈채팅</span>
            </Link>
            <Link
              href="/profile"
              className="flex flex-col items-center py-2 text-blue-600"
            >
              <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                <path d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              <span className="text-xs mt-1 font-semibold">프로필</span>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function SocialFeedPage() {
  return (
    <ProtectedRoute>
      <SocialFeedContent />
    </ProtectedRoute>
  );
}
