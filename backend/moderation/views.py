import logging

from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import BlockedUser

logger = logging.getLogger(__name__)
User = get_user_model()


def blocked_user_ids(user):
    """user가 차단한 사용자 ID 집합 (커뮤니티 쿼리셋 필터용)."""
    if not user or not user.is_authenticated:
        return set()
    return set(
        BlockedUser.objects.filter(blocker=user).values_list('blocked_id', flat=True)
    )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def block_user_view(request, user_id):
    """
    사용자 차단 (Apple Guideline 1.2 (d))
    POST /api/moderation/users/<user_id>/block/
    Body(optional): {"reason": "", "post_id": 1, "comment_id": 2}

    차단 즉시 해당 사용자의 콘텐츠가 요청자 피드에서 제거되며(쿼리셋 필터),
    개발자(관리자)가 검토할 수 있도록 차단 컨텍스트가 기록된다.
    """
    if request.user.id == int(user_id):
        return Response(
            {'detail': '자기 자신은 차단할 수 없습니다.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    target = get_object_or_404(User, pk=user_id)

    context_post = None
    context_comment = None
    post_id = request.data.get('post_id')
    comment_id = request.data.get('comment_id')
    if post_id:
        from community.models import Post
        context_post = Post.objects.filter(pk=post_id).first()
    if comment_id:
        from community.models import Comment
        context_comment = Comment.objects.filter(pk=comment_id).first()

    block, created = BlockedUser.objects.get_or_create(
        blocker=request.user,
        blocked=target,
        defaults={
            'reason': str(request.data.get('reason', ''))[:200],
            'context_post': context_post,
            'context_comment': context_comment,
        },
    )

    if created:
        # 개발자 통보: 차단 발생 로깅 (관리자 admin에서도 확인 가능)
        logger.warning(
            "[MODERATION] User %s blocked user %s. reason=%r post=%s comment=%s",
            request.user.id, target.id, block.reason, post_id, comment_id,
        )

    return Response(
        {'detail': '차단되었습니다.', 'blocked_user_id': target.id},
        status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
    )


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def unblock_user_view(request, user_id):
    """
    차단 해제
    DELETE /api/moderation/users/<user_id>/block/
    """
    deleted, _ = BlockedUser.objects.filter(
        blocker=request.user, blocked_id=user_id
    ).delete()

    if deleted:
        return Response(status=status.HTTP_204_NO_CONTENT)
    return Response(
        {'detail': '차단 내역이 없습니다.'},
        status=status.HTTP_404_NOT_FOUND,
    )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def blocked_users_view(request):
    """
    내가 차단한 사용자 목록
    GET /api/moderation/users/blocked/
    """
    blocks = (
        BlockedUser.objects.filter(blocker=request.user)
        .select_related('blocked')
        .order_by('-created_at')
    )
    data = [
        {
            'id': b.blocked.id,
            'nickname': b.blocked.nickname,
            'created_at': b.created_at.isoformat(),
        }
        for b in blocks
    ]
    return Response(data)
