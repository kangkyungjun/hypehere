from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PostViewSet, CommentViewSet, my_comments_view

# DRF Router
router = DefaultRouter()
router.register(r'posts', PostViewSet, basename='post')
router.register(r'comments', CommentViewSet, basename='comment')  # Flat routes용 (detail/action)

app_name = 'community'

urlpatterns = [
    path('', include(router.urls)),

    # Nested route: 댓글 목록/작성
    path(
        'posts/<int:post_pk>/comments/',
        CommentViewSet.as_view({'get': 'list', 'post': 'create'}),
        name='post-comments-list'
    ),

    # Nested route: 개별 댓글 조회/수정/삭제
    path(
        'posts/<int:post_pk>/comments/<int:pk>/',
        CommentViewSet.as_view({
            'get': 'retrieve',
            'put': 'update',
            'patch': 'partial_update',
            'delete': 'destroy'
        }),
        name='post-comment-detail'
    ),

    # Nested route: 댓글 좋아요 추가/취소
    path(
        'posts/<int:post_pk>/comments/<int:pk>/like/',
        CommentViewSet.as_view({'post': 'like'}),
        name='post-comment-like'
    ),
    path(
        'posts/<int:post_pk>/comments/<int:pk>/unlike/',
        CommentViewSet.as_view({'delete': 'unlike'}),
        name='post-comment-unlike'
    ),

    # Nested route: 댓글 신고
    path(
        'posts/<int:post_pk>/comments/<int:pk>/report/',
        CommentViewSet.as_view({'post': 'report_comment'}),
        name='post-comment-report'
    ),

    # 내 댓글 목록
    path('posts/comments/my/', my_comments_view, name='my-comments'),
]
