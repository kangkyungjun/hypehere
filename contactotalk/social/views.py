from rest_framework import status, generics, permissions, serializers
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from django.shortcuts import get_object_or_404

from accounts.permissions import IsUser, IsNotBanned
from accounts.models import User, UserInterest
from .models import Post, PostLike, Comment, CommentLike, Follow, UserProfile
from .serializers import (
    PostSerializer,
    PostCreateSerializer,
    CommentSerializer,
    CommentCreateSerializer,
    FollowSerializer,
    UserProfileSerializer,
)


# ============================================================================
# 프로필 API Views
# ============================================================================


class UserProfileAPIView(APIView):
    """사용자 프로필 조회/수정 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get(self, request, user_id=None):
        """프로필 조회"""

        # user_id가 없으면 본인 프로필 조회
        if user_id is None:
            user = request.user
        else:
            user = get_object_or_404(User, id=user_id)

        # 프로필이 없으면 자동 생성
        profile, created = UserProfile.objects.get_or_create(user=user)

        serializer = UserProfileSerializer(profile, context={"request": request})
        return Response(serializer.data, status=status.HTTP_200_OK)

    def put(self, request):
        """본인 프로필 수정"""

        profile, created = UserProfile.objects.get_or_create(user=request.user)

        serializer = UserProfileSerializer(
            profile, data=request.data, partial=True, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response(serializer.data, status=status.HTTP_200_OK)


# ============================================================================
# 게시글 API Views
# ============================================================================


class PostListAPIView(generics.ListAPIView):
    """게시글 목록 조회 API"""

    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        queryset = Post.objects.filter(is_active=True).select_related("author")

        # 필터링: 특정 사용자의 게시글
        user_id = self.request.query_params.get("user_id")
        if user_id:
            queryset = queryset.filter(author_id=user_id)

        # 검색: 내용
        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(content__icontains=search)

        return queryset


class PostDetailAPIView(generics.RetrieveAPIView):
    """게시글 상세 조회 API"""

    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        return Post.objects.filter(is_active=True).select_related("author")

    def retrieve(self, request, *args, **kwargs):
        """조회 시 조회수 증가"""
        instance = self.get_object()
        instance.increment_view_count()

        serializer = self.get_serializer(instance)
        return Response(serializer.data)


class PostCreateAPIView(generics.CreateAPIView):
    """게시글 작성 API"""

    serializer_class = PostCreateSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser, IsNotBanned]

    def perform_create(self, serializer):
        """게시글 생성"""
        post = serializer.save(author=self.request.user)

        # 프로필 게시글 수 증가
        profile, created = UserProfile.objects.get_or_create(user=self.request.user)
        profile.increment_post_count()


class PostUpdateAPIView(generics.UpdateAPIView):
    """게시글 수정 API"""

    serializer_class = PostCreateSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        # 본인이 작성한 게시글만 수정 가능
        return Post.objects.filter(author=self.request.user, is_active=True)


class PostDeleteAPIView(APIView):
    """게시글 삭제 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def delete(self, request, pk):
        # 본인이 작성한 게시글만 삭제 가능
        post = get_object_or_404(Post, pk=pk, author=request.user)

        # 비활성화 처리
        post.is_active = False
        post.save(update_fields=["is_active"])

        # 프로필 게시글 수 감소
        profile = getattr(request.user, "profile", None)
        if profile:
            profile.decrement_post_count()

        return Response(
            {"message": "게시글이 삭제되었습니다."}, status=status.HTTP_200_OK
        )


# ============================================================================
# 좋아요 API Views
# ============================================================================


class PostLikeAPIView(APIView):
    """게시글 좋아요/취소 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser, IsNotBanned]

    def post(self, request, pk):
        """좋아요"""
        post = get_object_or_404(Post, pk=pk, is_active=True)

        # 이미 좋아요 했는지 확인
        like, created = PostLike.objects.get_or_create(post=post, user=request.user)

        if created:
            # 좋아요 추가
            post.increment_like_count()
            return Response(
                {"message": "좋아요를 눌렀습니다.", "is_liked": True},
                status=status.HTTP_201_CREATED,
            )
        else:
            # 좋아요 취소
            like.delete()
            post.decrement_like_count()
            return Response(
                {"message": "좋아요를 취소했습니다.", "is_liked": False},
                status=status.HTTP_200_OK,
            )


class CommentLikeAPIView(APIView):
    """댓글 좋아요/취소 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser, IsNotBanned]

    def post(self, request, pk):
        """좋아요"""
        comment = get_object_or_404(Comment, pk=pk, is_active=True)

        # 이미 좋아요 했는지 확인
        like, created = CommentLike.objects.get_or_create(
            comment=comment, user=request.user
        )

        if created:
            # 좋아요 추가
            comment.increment_like_count()
            return Response(
                {"message": "좋아요를 눌렀습니다.", "is_liked": True},
                status=status.HTTP_201_CREATED,
            )
        else:
            # 좋아요 취소
            like.delete()
            comment.decrement_like_count()
            return Response(
                {"message": "좋아요를 취소했습니다.", "is_liked": False},
                status=status.HTTP_200_OK,
            )


# ============================================================================
# 댓글 API Views
# ============================================================================


class CommentListAPIView(generics.ListAPIView):
    """댓글 목록 조회 API"""

    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        post_id = self.kwargs.get("post_id")
        post = get_object_or_404(Post, pk=post_id, is_active=True)

        # 부모 댓글만 조회 (대댓글은 제외)
        return Comment.objects.filter(
            post=post, is_active=True, parent__isnull=True
        ).select_related("author").prefetch_related("replies")


class CommentCreateAPIView(generics.CreateAPIView):
    """댓글 작성 API"""

    serializer_class = CommentCreateSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser, IsNotBanned]

    def perform_create(self, serializer):
        """댓글 생성"""
        post_id = self.kwargs.get("post_id")
        post = get_object_or_404(Post, pk=post_id, is_active=True)

        comment = serializer.save(post=post, author=self.request.user)

        # 게시글 댓글 수 증가
        post.increment_comment_count()


class CommentUpdateAPIView(generics.UpdateAPIView):
    """댓글 수정 API"""

    serializer_class = CommentCreateSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        # 본인이 작성한 댓글만 수정 가능
        return Comment.objects.filter(author=self.request.user, is_active=True)


class CommentDeleteAPIView(APIView):
    """댓글 삭제 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def delete(self, request, pk):
        # 본인이 작성한 댓글만 삭제 가능
        comment = get_object_or_404(Comment, pk=pk, author=request.user)

        # 비활성화 처리
        comment.is_active = False
        comment.save(update_fields=["is_active"])

        # 게시글 댓글 수 감소
        comment.post.decrement_comment_count()

        return Response(
            {"message": "댓글이 삭제되었습니다."}, status=status.HTTP_200_OK
        )


# ============================================================================
# 팔로우 API Views
# ============================================================================


class FollowAPIView(APIView):
    """팔로우/언팔로우 API"""

    permission_classes = [permissions.IsAuthenticated, IsUser]

    def post(self, request, user_id):
        """팔로우"""
        following_user = get_object_or_404(User, id=user_id)

        # 자기 자신은 팔로우 불가
        if following_user == request.user:
            return Response(
                {"error": "자기 자신을 팔로우할 수 없습니다."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 이미 팔로우 했는지 확인
        follow, created = Follow.objects.get_or_create(
            follower=request.user, following=following_user
        )

        if created:
            # 팔로우 추가
            # 팔로워 프로필 following_count 증가
            follower_profile, _ = UserProfile.objects.get_or_create(
                user=request.user
            )
            follower_profile.increment_following_count()

            # 팔로잉 프로필 follower_count 증가
            following_profile, _ = UserProfile.objects.get_or_create(
                user=following_user
            )
            following_profile.increment_follower_count()

            return Response(
                {"message": f"{following_user.nickname}님을 팔로우했습니다.", "is_following": True},
                status=status.HTTP_201_CREATED,
            )
        else:
            # 언팔로우
            follow.delete()

            # 팔로워 프로필 following_count 감소
            follower_profile = getattr(request.user, "profile", None)
            if follower_profile:
                follower_profile.decrement_following_count()

            # 팔로잉 프로필 follower_count 감소
            following_profile = getattr(following_user, "profile", None)
            if following_profile:
                following_profile.decrement_follower_count()

            return Response(
                {"message": f"{following_user.nickname}님을 언팔로우했습니다.", "is_following": False},
                status=status.HTTP_200_OK,
            )


class FollowerListAPIView(generics.ListAPIView):
    """팔로워 목록 API"""

    serializer_class = FollowSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        user_id = self.kwargs.get("user_id", None)

        # user_id가 없으면 본인의 팔로워
        if user_id is None:
            user = self.request.user
        else:
            user = get_object_or_404(User, id=user_id)

        return Follow.objects.filter(following=user).select_related(
            "follower", "following"
        )


class FollowingListAPIView(generics.ListAPIView):
    """팔로잉 목록 API"""

    serializer_class = FollowSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        user_id = self.kwargs.get("user_id", None)

        # user_id가 없으면 본인의 팔로잉
        if user_id is None:
            user = self.request.user
        else:
            user = get_object_or_404(User, id=user_id)

        return Follow.objects.filter(follower=user).select_related(
            "follower", "following"
        )


# ============================================================================
# 추천 피드 API Views
# ============================================================================


class RecommendedFeedAPIView(generics.ListAPIView):
    """추천 피드 API (관심사 기반)"""

    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        user = self.request.user

        # 사용자의 관심사 가져오기
        user_interests = UserInterest.objects.filter(user=user).values_list(
            "interest_id", flat=True
        )

        if not user_interests:
            # 관심사가 없으면 최신 게시글 반환
            return Post.objects.filter(is_active=True).select_related("author")[:20]

        # 관심사가 겹치는 사용자 찾기
        similar_users = (
            UserInterest.objects.filter(interest_id__in=user_interests)
            .exclude(user=user)
            .values_list("user_id", flat=True)
            .distinct()
        )

        # 비슷한 관심사를 가진 사용자들의 게시글 반환
        return (
            Post.objects.filter(author_id__in=similar_users, is_active=True)
            .select_related("author")
            .order_by("-like_count", "-created_at")[:50]
        )


class FollowingFeedAPIView(generics.ListAPIView):
    """팔로잉 피드 API"""

    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated, IsUser]

    def get_queryset(self):
        user = self.request.user

        # 팔로잉한 사용자 목록
        following_users = Follow.objects.filter(follower=user).values_list(
            "following_id", flat=True
        )

        # 팔로잉한 사용자들의 게시글 반환
        return (
            Post.objects.filter(author_id__in=following_users, is_active=True)
            .select_related("author")
            .order_by("-created_at")
        )
