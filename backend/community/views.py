import logging

from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticatedOrReadOnly, IsAuthenticated
from django.db import transaction
from .models import Post, Comment, PostLike, CommentLike
from moderation.models import PostReport, CommentReport
from moderation.views import blocked_user_ids

# 동일 콘텐츠가 이 수 이상으로 신고되면 자동으로 숨김 처리 (관리자 검토 전 선제 차단)
REPORT_AUTOHIDE_THRESHOLD = 3
from accounts.fcm_utils import (
    send_general_to_ticker_subscribers,
    send_comment_notification,
)

logger = logging.getLogger(__name__)
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
        queryset = Post.objects.filter(
            is_deleted=False, is_hidden=False
        ).select_related('author')

        # 차단한 사용자의 게시글 제외 (Apple Guideline 1.2 (d))
        blocked = blocked_user_ids(self.request.user)
        if blocked:
            queryset = queryset.exclude(author_id__in=blocked)

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

    def perform_create(self, serializer):
        """글 작성 + FCM 알림 (일반, 1시간 제한)"""
        post = serializer.save(author=self.request.user)
        try:
            send_general_to_ticker_subscribers(
                ticker=post.ticker,
                msg_key="NEW_POST",
                msg_params={"ticker": post.ticker, "title": post.title[:100]},
                data={"type": "NEW_POST", "post_id": str(post.id), "ticker": post.ticker},
                exclude_user=self.request.user.id,
            )
        except Exception as e:
            logger.error(f"FCM new post error: {e}")

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

        # 인기글 알림 (일반, 1시간 제한)
        post.refresh_from_db()
        if post.like_count in (10, 30, 100):
            try:
                send_general_to_ticker_subscribers(
                    ticker=post.ticker,
                    msg_key="HOT_POST",
                    msg_params={"ticker": post.ticker, "title": post.title[:50], "count": post.like_count},
                    data={
                        "type": f"HOT_POST_{post.like_count}",
                        "post_id": str(post.id),
                        "ticker": post.ticker,
                    },
                )
            except Exception as e:
                logger.error(f"FCM hot post error: {e}")

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

        # 차단한 사용자의 게시글 제외
        blocked = blocked_user_ids(request.user)
        if blocked:
            queryset = queryset.exclude(author_id__in=blocked)

        # ticker 필터 (선택)
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

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def report(self, request, pk=None):
        """
        게시글 신고
        Flutter: POST /api/community/posts/{id}/report/
        Body: {"report_type": "spam|abuse|false_info|inappropriate|other", "description": ""}
        """
        post = self.get_object()

        # 자기 글 신고 방지
        if post.author == request.user:
            return Response(
                {'detail': '본인의 게시글은 신고할 수 없습니다.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 중복 신고 방지
        if PostReport.objects.filter(post=post, reporter=request.user).exists():
            return Response(
                {'detail': '이미 신고한 게시글입니다.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        report_type = request.data.get('report_type', 'other')
        description = request.data.get('description', '')

        valid_reasons = [c[0] for c in PostReport.REASON_CHOICES]
        if report_type not in valid_reasons:
            return Response(
                {'detail': f'유효하지 않은 신고 사유입니다. ({", ".join(valid_reasons)})'},
                status=status.HTTP_400_BAD_REQUEST
            )

        PostReport.objects.create(
            post=post,
            reporter=request.user,
            reason=report_type,
            description=description[:500],
        )

        # 신고 누적 임계치 도달 시 자동 숨김 (관리자 최종 검토 전 선제 차단)
        report_total = PostReport.objects.filter(post=post).count()
        if report_total >= REPORT_AUTOHIDE_THRESHOLD and not post.is_hidden:
            post.is_hidden = True
            post.save(update_fields=['is_hidden'])
            logger.warning(
                "[MODERATION] Post %s auto-hidden after %s reports",
                post.id, report_total,
            )

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

        # 차단한 사용자의 댓글 제외 (Apple Guideline 1.2 (d))
        blocked = blocked_user_ids(self.request.user)
        if blocked:
            queryset = queryset.exclude(author_id__in=blocked)

        # Nested route: URL에서 post_pk 가져오기
        post_pk = self.kwargs.get('post_pk')
        if post_pk:
            queryset = queryset.filter(post_id=post_pk)

        # parent=None인 최상위 댓글만 조회 (대댓글은 serializer에서 nested로 처리)
        queryset = queryset.filter(parent=None)

        return queryset.order_by('created_at')

    def perform_create(self, serializer):
        """댓글 생성 시 post의 comment_count 증가 + FCM 알림"""
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

        # FCM 댓글 알림 (즉시, 제한 면제)
        try:
            post_obj = comment.post
            author = self.request.user

            # 1) 글 작성자에게 알림 (본인 댓글 제외)
            if post_obj.author_id != author.id:
                send_comment_notification(
                    user_id=post_obj.author_id,
                    msg_key="COMMENT_ON_MY_POST",
                    msg_params={"ticker": post_obj.ticker, "nickname": author.nickname, "content": comment.content[:80]},
                    data={"type": "COMMENT_ON_MY_POST", "post_id": str(post_obj.id), "ticker": post_obj.ticker},
                )

            # 2) 같은 글에 댓글 단 다른 사용자들에게 알림
            commenters = Comment.objects.filter(
                post=post_obj, is_deleted=False
            ).exclude(
                author_id=author.id
            ).exclude(
                author_id=post_obj.author_id
            ).values_list('author_id', flat=True).distinct()

            for user_id in commenters:
                send_comment_notification(
                    user_id=user_id,
                    msg_key="COMMENT_ON_THREAD",
                    msg_params={"ticker": post_obj.ticker, "nickname": author.nickname, "content": comment.content[:80]},
                    data={"type": "COMMENT_ON_THREAD", "post_id": str(post_obj.id), "ticker": post_obj.ticker},
                )
        except Exception as e:
            logger.error(f"FCM comment error: {e}")

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

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def report(self, request, pk=None, **kwargs):
        """
        댓글 신고
        Flutter: POST /api/community/posts/{post_pk}/comments/{id}/report/
        Body: {"report_type": "spam|abuse|false_info|inappropriate|other", "description": ""}
        """
        comment = self.get_object()

        # 자기 댓글 신고 방지
        if comment.author == request.user:
            return Response(
                {'detail': '본인의 댓글은 신고할 수 없습니다.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 중복 신고 방지
        if CommentReport.objects.filter(comment=comment, reporter=request.user).exists():
            return Response(
                {'detail': '이미 신고한 댓글입니다.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        report_type = request.data.get('report_type', 'other')
        description = request.data.get('description', '')

        valid_reasons = [c[0] for c in CommentReport.REASON_CHOICES]
        if report_type not in valid_reasons:
            return Response(
                {'detail': f'유효하지 않은 신고 사유입니다. ({", ".join(valid_reasons)})'},
                status=status.HTTP_400_BAD_REQUEST
            )

        CommentReport.objects.create(
            comment=comment,
            reporter=request.user,
            reason=report_type,
            description=description[:500],
        )

        # 신고 누적 임계치 도달 시 자동 숨김 (소프트 삭제로 피드에서 제거)
        report_total = CommentReport.objects.filter(comment=comment).count()
        if report_total >= REPORT_AUTOHIDE_THRESHOLD and not comment.is_deleted:
            with transaction.atomic():
                comment.is_deleted = True
                comment.save(update_fields=['is_deleted'])
                if comment.parent is None:
                    comment.post.decrement_comment_count()
            logger.warning(
                "[MODERATION] Comment %s auto-hidden after %s reports",
                comment.id, report_total,
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
