from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import render
from django.contrib.auth.decorators import login_required
from .models import Notification, NotificationSettings
from .serializers import NotificationSerializer, NotificationSettingsSerializer


@login_required
def notifications_page(request):
    """알림 페이지 렌더링"""
    return render(request, 'notifications.html')


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    """
    알림 ViewSet (읽기 전용)
    알림 조회, 읽음 처리 기능 제공
    """
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSerializer

    def get_queryset(self):
        """현재 사용자의 알림만 반환 (차단한 사용자 제외)"""
        from accounts.models import Block

        # 차단한 사용자 목록 조회
        blocked_user_ids = Block.objects.filter(
            blocker=self.request.user
        ).values_list('blocked_id', flat=True)

        queryset = Notification.objects.filter(
            recipient=self.request.user
        ).select_related('sender').order_by('-created_at')

        # 차단한 사용자의 알림 제외
        if blocked_user_ids:
            queryset = queryset.exclude(sender_id__in=blocked_user_ids)

        return queryset

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """
        개별 알림을 읽음 처리
        POST /notifications/api/{id}/mark_read/
        """
        notification = self.get_object()
        notification.mark_as_read()
        return Response({'status': 'marked as read'})

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """
        모든 알림을 읽음 처리
        POST /notifications/api/mark_all_read/
        """
        count = Notification.objects.filter(
            recipient=request.user,
            is_read=False
        ).update(is_read=True)

        return Response({
            'status': 'success',
            'count': count
        })

    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        """
        안읽은 알림 개수 조회 (차단한 사용자 제외)
        GET /notifications/api/unread_count/
        """
        from accounts.models import Block

        # 차단한 사용자 목록 조회
        blocked_user_ids = Block.objects.filter(
            blocker=request.user
        ).values_list('blocked_id', flat=True)

        notifications = Notification.objects.filter(
            recipient=request.user,
            is_read=False
        )

        # 차단한 사용자의 알림 제외
        if blocked_user_ids:
            notifications = notifications.exclude(sender_id__in=blocked_user_ids)

        count = notifications.count()

        return Response({'unread_count': count})


class NotificationSettingsViewSet(viewsets.GenericViewSet):
    """
    알림 설정 관리 ViewSet
    GET/PUT/PATCH /notifications/api/settings/me/ - 현재 사용자 설정 조회/수정
    """
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationSettingsSerializer

    @action(detail=False, methods=['get', 'put', 'patch'])
    def me(self, request):
        """
        현재 사용자의 알림 설정 조회 및 수정

        GET /notifications/api/settings/me/ - 설정 조회
        PUT/PATCH /notifications/api/settings/me/ - 설정 수정
        """
        # 사용자 설정 가져오기 (없으면 생성)
        settings, created = NotificationSettings.objects.get_or_create(
            user=request.user
        )

        if request.method == 'GET':
            serializer = self.get_serializer(settings)
            return Response(serializer.data)

        # PUT or PATCH
        partial = request.method == 'PATCH'
        serializer = self.get_serializer(settings, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
