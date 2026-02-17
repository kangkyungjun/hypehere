from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticatedOrReadOnly, IsAuthenticated
from django.db import transaction
from .models import Post, Comment, PostLike, CommentLike
from .serializers import (
    PostSerializer,
    PostListSerializer,
    CommentSerializer,
    PostLikeSerializer,
    CommentLikeSerializer
)
from .permissions import IsAuthorOrReadOnly, IsAuthenticatedForCommentWrite


class PostViewSet(viewsets.ModelViewSet):
    """
    게시글 ViewSet

    ## 권한
    - GET (list, retrieve): 누구나 가능 (비회원 포함)
    - POST (create): 로그인 필수
    - DELETE (destroy): 작성자 or 관리자만 가능
    - like/unlike: 로그인 필수

    ## 필터링
    - ticker: ?ticker=TSLA (대소문자 무관, 자동 대문자 변환)

    ## 정렬
    - ?ordering=latest (최신순, 기본값)
    - ?ordering=likes (좋아요순)
    - ?ordering=comments (댓글순)
    """
    permission_classes = [IsAuthenticatedOrReadOnly, IsAuthorOrReadOnly]

    def get_queryset(self):
        """is_deleted=False인 게시글만 조회, 필터링 및 정렬 지원"""
        queryset = Post.objects.filter(is_deleted=False).select_related('author')

        # ticker 필터링
        ticker = self.request.query_params.get('ticker')
        if ticker:
            queryset = queryset.filter(ticker=ticker.upper())

        # 정렬 (기본값: -created_at)
        ordering = self.request.query_params.get('ordering', 'latest')
        ordering_map = {
            'latest': '-created_at',
            'likes': '-like_count',
            'comments': '-comment_count',
        }
        order_field = ordering_map.get(ordering, '-created_at')
        queryset = queryset.order_by(order_field)

        return queryset

    def get_serializer_class(self):
        """list는 간소화 버전, 나머지는 전체 버전"""
        if self.action == 'list':
            return PostListSerializer
        return PostSerializer

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticatedOrReadOnly])
    def like(self, request, pk=None):
        """
        게시글 좋아요 추가

        ## 성공 (201)
        - 좋아요 추가됨

        ## 실패
        - 400: 이미 좋아요를 누른 경우
        - 401: 비로그인 사용자
        - 404: 게시글이 존재하지 않음
        """
        post = self.get_object()

        # 이미 좋아요를 눌렀는지 확인
        if PostLike.objects.filter(post=post, user=request.user).exists():
            return Response(
                {'detail': '이미 좋아요를 누른 게시글입니다.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 좋아요 생성 및 카운터 증가 (트랜잭션)
        with transaction.atomic():
            PostLike.objects.create(post=post, user=request.user)
            post.increment_like_count()

        return Response(
            {'detail': '좋아요를 추가했습니다.'},
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['delete'], permission_classes=[IsAuthenticatedOrReadOnly])
    def unlike(self, request, pk=None):
        """
        게시글 좋아요 취소

        ## 성공 (204)
        - 좋아요 취소됨

        ## 실패
        - 401: 비로그인 사용자
        - 404: 좋아요를 누르지 않은 경우 or 게시글이 존재하지 않음
        """
        post = self.get_object()

        # 좋아요를 눌렀는지 확인
        try:
            post_like = PostLike.objects.get(post=post, user=request.user)
        except PostLike.DoesNotExist:
            return Response(
                {'detail': '좋아요를 누르지 않은 게시글입니다.'},
                status=status.HTTP_404_NOT_FOUND
            )

        # 좋아요 삭제 및 카운터 감소 (트랜잭션)
        with transaction.atomic():
            post_like.delete()
            post.decrement_like_count()

        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my(self, request):
        """
        내 게시글 목록 (paginated)
        Flutter: GET /api/community/posts/my/
        """
        queryset = Post.objects.filter(
            author=request.user, is_deleted=False
        ).order_by('-created_at')

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = PostListSerializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)

        serializer = PostListSerializer(queryset, many=True, context={'request': request})
        return Response(serializer.data)


class CommentViewSet(viewsets.ModelViewSet):
    """
    댓글 ViewSet

    ## 권한
    - GET (list): 누구나 가능 (비회원에게는 내용 숨김)
    - POST (create): 로그인 필수
    - DELETE (destroy): 작성자 or 관리자만 가능
    - like/unlike: 로그인 필수

    ## 필터링
    - post: 필수, ?post={post_id}

    ## 정렬
    - created_at 오름차순 (시간 흐름대로, 기본값)
    """
    permission_classes = [IsAuthenticatedForCommentWrite, IsAuthorOrReadOnly]
    serializer_class = CommentSerializer

    def get_queryset(self):
        """is_deleted=False인 댓글만 조회, post 필터링 지원"""
        queryset = Comment.objects.filter(is_deleted=False).select_related('author', 'post')

        # Nested route: URL에서 post_pk 가져오기
        post_pk = self.kwargs.get('post_pk')
        if post_pk:
            queryset = queryset.filter(post_id=post_pk)

        # parent=None인 최상위 댓글만 조회 (대댓글은 serializer에서 nested로 처리)
        queryset = queryset.filter(parent=None)

        return queryset.order_by('created_at')

    def perform_create(self, serializer):
        """댓글 생성 시 post의 comment_count 증가"""
        # Nested route: URL에서 post_pk 가져오기
        post_pk = self.kwargs.get('post_pk')
        if post_pk:
            from django.shortcuts import get_object_or_404
            post = get_object_or_404(Post, pk=post_pk, is_deleted=False)
            comment = serializer.save(post=post)
        else:
            comment = serializer.save()

        # 최상위 댓글인 경우에만 post의 comment_count 증가
        if comment.parent is None:
            with transaction.atomic():
                comment.post.increment_comment_count()

    def perform_destroy(self, instance):
        """댓글 삭제 시 소프트 삭제 및 post의 comment_count 감소"""
        with transaction.atomic():
            instance.is_deleted = True
            instance.save(update_fields=['is_deleted'])

            # 최상위 댓글인 경우에만 post의 comment_count 감소
            if instance.parent is None:
                instance.post.decrement_comment_count()

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticatedForCommentWrite])
    def like(self, request, pk=None, **kwargs):
        """
        댓글 좋아요 추가

        ## 성공 (201)
        - 좋아요 추가됨

        ## 실패
        - 400: 이미 좋아요를 누른 경우
        - 401: 비로그인 사용자
        - 404: 댓글이 존재하지 않음
        """
        comment = self.get_object()

        # 이미 좋아요를 눌렀는지 확인
        if CommentLike.objects.filter(comment=comment, user=request.user).exists():
            return Response(
                {'detail': '이미 좋아요를 누른 댓글입니다.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 좋아요 생성 및 카운터 증가 (트랜잭션)
        with transaction.atomic():
            CommentLike.objects.create(comment=comment, user=request.user)
            comment.increment_like_count()

        return Response(
            {'detail': '좋아요를 추가했습니다.'},
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['delete'], permission_classes=[IsAuthenticatedForCommentWrite])
    def unlike(self, request, pk=None, **kwargs):
        """
        댓글 좋아요 취소

        ## 성공 (204)
        - 좋아요 취소됨

        ## 실패
        - 401: 비로그인 사용자
        - 404: 좋아요를 누르지 않은 경우 or 댓글이 존재하지 않음
        """
        comment = self.get_object()

        # 좋아요를 눌렀는지 확인
        try:
            comment_like = CommentLike.objects.get(comment=comment, user=request.user)
        except CommentLike.DoesNotExist:
            return Response(
                {'detail': '좋아요를 누르지 않은 댓글입니다.'},
                status=status.HTTP_404_NOT_FOUND
            )

        # 좋아요 삭제 및 카운터 감소 (트랜잭션)
        with transaction.atomic():
            comment_like.delete()
            comment.decrement_like_count()

        return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_comments_view(request):
    """
    내 댓글 목록 (paginated)
    Flutter: GET /api/community/posts/comments/my/
    """
    from rest_framework.pagination import PageNumberPagination

    queryset = Comment.objects.filter(
        author=request.user, is_deleted=False
    ).select_related('author', 'post').order_by('-created_at')

    paginator = PageNumberPagination()
    paginator.page_size = 20
    page = paginator.paginate_queryset(queryset, request)

    if page is not None:
        serializer = CommentSerializer(page, many=True, context={'request': request})
        return paginator.get_paginated_response(serializer.data)

    serializer = CommentSerializer(queryset, many=True, context={'request': request})
    return Response(serializer.data)
