'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth';
import {
  getPost,
  deletePost,
  likePost,
  unlikePost,
  getComments,
  createComment,
  deleteComment,
} from '@/lib/api/social';
import { reportPost, reportComment } from '@/lib/api/moderation';
import { formatRelativeTime } from '@/lib/utils';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Button from '@/components/ui/Button';
import ReportModal from '@/components/moderation/ReportModal';
import type { Post, Comment } from '@/types';

function PostDetailContent() {
  const router = useRouter();
  const params = useParams();
  const postId = parseInt(params.id as string);

  const { user } = useAuthStore();

  const [post, setPost] = useState<Post | null>(null);
  const [comments, setComments] = useState<Comment[]>([]);
  const [newComment, setNewComment] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isCommenting, setIsCommenting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showReportModal, setShowReportModal] = useState(false);
  const [reportType, setReportType] = useState<'post' | 'comment'>('post');
  const [reportTargetId, setReportTargetId] = useState<number>(0);

  useEffect(() => {
    if (!postId || isNaN(postId)) {
      router.push('/social');
      return;
    }

    loadPost();
    loadComments();
  }, [postId, router]);

  const loadPost = async () => {
    try {
      const data = await getPost(postId);
      setPost(data);
    } catch (error) {
      console.error('Failed to load post:', error);
      setError('게시글을 불러오는데 실패했습니다.');
    } finally {
      setIsLoading(false);
    }
  };

  const loadComments = async () => {
    try {
      const data = await getComments(postId);
      setComments(data.results);
    } catch (error) {
      console.error('Failed to load comments:', error);
    }
  };

  const handleLike = async () => {
    if (!post) return;

    try {
      if (post.is_liked) {
        await unlikePost(postId);
      } else {
        await likePost(postId);
      }

      setPost({
        ...post,
        is_liked: !post.is_liked,
        like_count: post.is_liked ? post.like_count - 1 : post.like_count + 1,
      });
    } catch (error) {
      console.error('Failed to like/unlike post:', error);
    }
  };

  const handleDeletePost = async () => {
    if (!confirm('게시글을 삭제하시겠습니까?')) {
      return;
    }

    try {
      await deletePost(postId);
      router.push('/social');
    } catch (error) {
      console.error('Failed to delete post:', error);
      alert('게시글 삭제에 실패했습니다.');
    }
  };

  const handleSubmitComment = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!newComment.trim()) {
      return;
    }

    setIsCommenting(true);

    try {
      const comment = await createComment(postId, newComment);
      setComments([...comments, comment]);
      setNewComment('');

      // Update post comment count
      if (post) {
        setPost({ ...post, comment_count: post.comment_count + 1 });
      }
    } catch (error) {
      console.error('Failed to create comment:', error);
      alert('댓글 작성에 실패했습니다.');
    } finally {
      setIsCommenting(false);
    }
  };

  const handleDeleteComment = async (commentId: number) => {
    if (!confirm('댓글을 삭제하시겠습니까?')) {
      return;
    }

    try {
      await deleteComment(commentId);
      setComments(comments.filter((c) => c.id !== commentId));

      // Update post comment count
      if (post) {
        setPost({ ...post, comment_count: post.comment_count - 1 });
      }
    } catch (error) {
      console.error('Failed to delete comment:', error);
      alert('댓글 삭제에 실패했습니다.');
    }
  };

  const handleReportPost = () => {
    setReportType('post');
    setReportTargetId(postId);
    setShowReportModal(true);
  };

  const handleReportComment = (commentId: number) => {
    setReportType('comment');
    setReportTargetId(commentId);
    setShowReportModal(true);
  };

  const handleSubmitReport = async (reason: string, description: string) => {
    if (reportType === 'post') {
      await reportPost(reportTargetId, reason, description);
      alert('신고가 접수되었습니다.');
    } else {
      await reportComment(reportTargetId, reason, description);
      alert('신고가 접수되었습니다.');
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

  if (!post) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <p className="text-red-600">게시글을 찾을 수 없습니다.</p>
          <Button onClick={() => router.push('/social')} className="mt-4">
            목록으로
          </Button>
        </div>
      </div>
    );
  }

  const isAuthor = user && post.author.id === user.id;

  return (
    <div className="min-h-screen bg-gray-50 pb-6">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <button
              onClick={() => router.back()}
              className="text-gray-600 hover:text-gray-900"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <h1 className="text-xl font-bold text-gray-900">게시글</h1>
            <div className="flex gap-2">
              {isAuthor ? (
                <button
                  onClick={handleDeletePost}
                  className="text-red-600 hover:text-red-700"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              ) : (
                <button
                  onClick={handleReportPost}
                  className="text-gray-600 hover:text-red-600"
                  title="신고하기"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9" />
                  </svg>
                </button>
              )}
            </div>
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

        {/* Post */}
        <div className="bg-white rounded-xl shadow-sm overflow-hidden mb-6">
          {/* Post Header */}
          <div className="p-4 border-b border-gray-100">
            <div className="flex items-center gap-3">
              <Link href={`/social/users/${post.author.id}`}>
                <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white font-semibold text-lg cursor-pointer hover:opacity-80">
                  {post.author.nickname[0].toUpperCase()}
                </div>
              </Link>
              <div className="flex-1">
                <Link href={`/social/users/${post.author.id}`}>
                  <h3 className="font-semibold text-gray-900 hover:text-blue-600">
                    {post.author.nickname}
                  </h3>
                </Link>
                <p className="text-sm text-gray-500">
                  {formatRelativeTime(post.created_at)}
                </p>
              </div>
            </div>
          </div>

          {/* Post Content */}
          <div className="p-6">
            <p className="text-gray-900 whitespace-pre-wrap mb-4">{post.content}</p>
            {post.images && post.images.length > 0 && (
              <img
                src={post.images[0]}
                alt="Post image"
                className="w-full rounded-lg"
              />
            )}
          </div>

          {/* Post Actions */}
          <div className="px-6 py-4 border-t border-gray-100 flex items-center gap-6">
            <button
              onClick={handleLike}
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

            <div className="flex items-center gap-2 text-gray-600">
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
            </div>
          </div>
        </div>

        {/* Comments Section */}
        <div className="bg-white rounded-xl shadow-sm p-6">
          <h2 className="text-lg font-bold text-gray-900 mb-4">
            댓글 {comments.length}개
          </h2>

          {/* Comment Form */}
          <form onSubmit={handleSubmitComment} className="mb-6">
            <div className="flex gap-3">
              <input
                type="text"
                value={newComment}
                onChange={(e) => setNewComment(e.target.value)}
                placeholder="댓글을 입력하세요..."
                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                disabled={isCommenting}
              />
              <Button
                type="submit"
                isLoading={isCommenting}
                disabled={!newComment.trim() || isCommenting}
              >
                작성
              </Button>
            </div>
          </form>

          {/* Comments List */}
          <div className="space-y-4">
            {comments.length === 0 ? (
              <p className="text-center text-gray-500 py-8">
                첫 번째 댓글을 작성해보세요
              </p>
            ) : (
              comments.map((comment) => (
                <div
                  key={comment.id}
                  className="flex gap-3 p-4 rounded-lg hover:bg-gray-50"
                >
                  <Link href={`/social/users/${comment.author.id}`}>
                    <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center text-white font-semibold flex-shrink-0 cursor-pointer hover:opacity-80">
                      {comment.author.nickname[0].toUpperCase()}
                    </div>
                  </Link>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between mb-1">
                      <Link href={`/social/users/${comment.author.id}`}>
                        <span className="font-semibold text-gray-900 hover:text-blue-600">
                          {comment.author.nickname}
                        </span>
                      </Link>
                      <div className="flex gap-2">
                        {user && comment.author.id === user.id ? (
                          <button
                            onClick={() => handleDeleteComment(comment.id)}
                            className="text-red-600 hover:text-red-700 text-sm"
                          >
                            삭제
                          </button>
                        ) : (
                          <button
                            onClick={() => handleReportComment(comment.id)}
                            className="text-gray-500 hover:text-red-600 text-sm"
                          >
                            신고
                          </button>
                        )}
                      </div>
                    </div>
                    <p className="text-gray-900 mb-1">{comment.content}</p>
                    <p className="text-xs text-gray-500">
                      {formatRelativeTime(comment.created_at)}
                    </p>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Report Modal */}
      <ReportModal
        isOpen={showReportModal}
        onClose={() => setShowReportModal(false)}
        onSubmit={handleSubmitReport}
        title={reportType === 'post' ? '게시글 신고' : '댓글 신고'}
      />
    </div>
  );
}

export default function PostDetailPage() {
  return (
    <ProtectedRoute>
      <PostDetailContent />
    </ProtectedRoute>
  );
}
