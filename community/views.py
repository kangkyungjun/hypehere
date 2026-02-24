from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticatedOrReadOnly, IsAuthenticated
from django.db import transaction
from .models import Post, Comment, PostLike, CommentLike, PostReport, CommentReport
from .serializers import (
    PostSerializer,
    PostListSerializer,
    CommentSerializer,
    PostLikeSerializer,
    CommentLikeSerializer,
    PostReportSerializer,
    CommentReportSerializer,
)
from .permissions import IsAuthorOrReadOnly, IsAuthenticatedForCommentWrite
from .pagination import CommunityPagination
from .moderation import moderate_content


class PostViewSet(viewsets.ModelViewSet):
    """
    게시글 ViewSet

    ## 권한
    - GET (list, retrieve): 누구나 가능 (비회원 포함)
    - POST (create): 로그인 필수
    - DELETE (destroy): 작성자 or 관리자만 가능 (소프트 삭제)
    - like/unlike: 로그인 필수

    ## 필터링
    - ticker: ?ticker=TSLA (대소문자 무관, 자동 대문자 변환)

    ## 정렬
    - ?ordering=latest (최신순, 기본값)
    - ?ordering=likes (좋아요순)
    - ?ordering=comments (댓글순)
    """
    permission_classes = [IsAuthenticatedOrReadOnly, IsAuthorOrReadOnly]
    pagination_class = CommunityPagination

    def get_queryset(self):
        """is_deleted=False, is_hidden=False 게시글만 조회"""
        queryset = Post.objects.filter(
            is_deleted=False, is_hidden=False
        ).select_related('author')

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
        if self.action == 'list':
            return PostListSerializer
        return PostSerializer

    def perform_create(self, serializer):
        """게시글 생성 시 콘텐츠 모더레이션 검사"""
        content = serializer.validated_data.get('content', '')
        title = serializer.validated_data.get('title', '')
        moderate_content(f"{title} {content}")
        serializer.save()

    def perform_destroy(self, instance):
        """소프트 삭제 (is_deleted=True)"""
        instance.is_deleted = True
        instance.save(update_fields=['is_deleted'])

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def like(self, request, pk=None):
        """게시글 좋아요 추가"""
        post = self.get_object()

        if PostLike.objects.filter(post=post, user=request.user).exists():
            return Response(
                {'detail': '이미 좋아요를 누른 게시글입니다.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        with transaction.atomic():
            PostLike.objects.create(post=post, user=request.user)
            post.increment_like_count()

        return Response(
            {'detail': '좋아요를 추가했습니다.'},
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['delete'], permission_classes=[IsAuthenticated])
    def unlike(self, request, pk=None):
        """게시글 좋아요 취소"""
        post = self.get_object()

        try:
            post_like = PostLike.objects.get(post=post, user=request.user)
        except PostLike.DoesNotExist:
            return Response(
                {'detail': '좋아요를 누르지 않은 게시글입니다.'},
                status=status.HTTP_404_NOT_FOUND
            )

        with transaction.atomic():
            post_like.delete()
            post.decrement_like_count()

        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticatedOrReadOnly])
    def search(self, request):
        """
        게시글 검색 (제목 + 내용)
        Flutter: GET /api/community/posts/search/?q=<query>&ticker=<ticker>
        """
        from django.db.models import Q

        query = request.query_params.get('q', '').strip()
        if not query:
            return Response([])

        queryset = Post.objects.filter(
            is_deleted=False, is_hidden=False,
        ).filter(
            Q(title__icontains=query) | Q(content__icontains=query)
        ).select_related('author')

        ticker = request.query_params.get('ticker')
        if ticker:
            queryset = queryset.filter(ticker=ticker.upper())

        queryset = queryset.order_by('-created_at')

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = PostListSerializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)

        serializer = PostListSerializer(queryset, many=True, context={'request': request})
        return Response(serializer.data)

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

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated],
            url_path='report', url_name='report')
    def report(self, request, pk=None):
        """
        게시글 신고
        - 중복 신고 방지
        - 신고 3건 이상 → 자동 숨김
        """
        post = self.get_object()

        if post.author == request.user:
            return Response(
                {'detail': '자신의 게시글은 신고할 수 없습니다.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if PostReport.objects.filter(reporter=request.user, post=post).exists():
            return Response(
                {'detail': '이미 신고한 게시글입니다.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = PostReportSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        with transaction.atomic():
            PostReport.objects.create(
                reporter=request.user,
                reported_user=post.author,
                post=post,
                report_type=serializer.validated_data['report_type'],
                description=serializer.validated_data.get('description', ''),
            )

            # 신고 3건 이상 → 자동 숨김
            report_count = PostReport.objects.filter(post=post).count()
            if report_count >= 3 and not post.is_hidden:
                post.is_hidden = True
                post.save(update_fields=['is_hidden'])

        return Response(
            {'detail': '신고가 접수되었습니다.'},
            status=status.HTTP_201_CREATED
        )


class CommentViewSet(viewsets.ModelViewSet):
    """
    댓글 ViewSet

    ## 권한
    - GET (list): 누구나 가능 (비회원에게는 내용 숨김)
    - POST (create): 로그인 필수
    - DELETE (destroy): 작성자 or 관리자만 가능
    - like/unlike: 로그인 필수
    """
    permission_classes = [IsAuthenticatedForCommentWrite, IsAuthorOrReadOnly]
    serializer_class = CommentSerializer
    pagination_class = CommunityPagination

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
        """댓글 생성 시 모더레이션 + comment_count 증가"""
        content = self.request.data.get('content', '')
        moderate_content(content)

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
        """댓글 소프트 삭제 및 post의 comment_count 감소"""
        with transaction.atomic():
            instance.is_deleted = True
            instance.save(update_fields=['is_deleted'])

            if instance.parent is None:
                instance.post.decrement_comment_count()

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def like(self, request, pk=None, **kwargs):
        """댓글 좋아요 추가"""
        comment = self.get_object()

        if CommentLike.objects.filter(comment=comment, user=request.user).exists():
            return Response(
                {'detail': '이미 좋아요를 누른 댓글입니다.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        with transaction.atomic():
            CommentLike.objects.create(comment=comment, user=request.user)
            comment.increment_like_count()

        return Response(
            {'detail': '좋아요를 추가했습니다.'},
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['delete'], permission_classes=[IsAuthenticated])
    def unlike(self, request, pk=None, **kwargs):
        """댓글 좋아요 취소"""
        comment = self.get_object()

        try:
            comment_like = CommentLike.objects.get(comment=comment, user=request.user)
        except CommentLike.DoesNotExist:
            return Response(
                {'detail': '좋아요를 누르지 않은 댓글입니다.'},
                status=status.HTTP_404_NOT_FOUND
            )

        with transaction.atomic():
            comment_like.delete()
            comment.decrement_like_count()

        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated],
            url_path='report', url_name='report')
    def report_comment(self, request, pk=None, **kwargs):
        """댓글 신고"""
        comment = self.get_object()

        if comment.author == request.user:
            return Response(
                {'detail': '자신의 댓글은 신고할 수 없습니다.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if CommentReport.objects.filter(reporter=request.user, comment=comment).exists():
            return Response(
                {'detail': '이미 신고한 댓글입니다.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = CommentReportSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        CommentReport.objects.create(
            reporter=request.user,
            reported_user=comment.author,
            comment=comment,
            report_type=serializer.validated_data['report_type'],
            description=serializer.validated_data.get('description', ''),
        )

        return Response(
            {'detail': '신고가 접수되었습니다.'},
            status=status.HTTP_201_CREATED
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_comments_view(request):
    """
    내 댓글 목록 (paginated)
    Flutter: GET /api/community/posts/comments/my/
    """
    queryset = Comment.objects.filter(
        author=request.user, is_deleted=False
    ).select_related('author', 'post').order_by('-created_at')

    paginator = CommunityPagination()
    page = paginator.paginate_queryset(queryset, request)

    if page is not None:
        serializer = CommentSerializer(page, many=True, context={'request': request})
        return paginator.get_paginated_response(serializer.data)

    serializer = CommentSerializer(queryset, many=True, context={'request': request})
    return Response(serializer.data)
