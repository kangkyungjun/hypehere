from django.urls import path
from .views import (
    PostListCreateAPIView, PostDetailAPIView,
    post_like_toggle, post_favorite_toggle, PostCommentListCreateAPIView,
    CommentDetailAPIView, PostSearchAPIView, post_report_view, comment_report_view,
    log_interaction, RecommendedPostListAPIView
)

app_name = 'posts'

urlpatterns = [
    path('', PostListCreateAPIView.as_view(), name='post_list_create'),
    path('recommended/', RecommendedPostListAPIView.as_view(), name='post_recommended'),
    path('search/', PostSearchAPIView.as_view(), name='post_search'),
    path('<int:pk>/', PostDetailAPIView.as_view(), name='post_detail'),
    path('<int:pk>/like/', post_like_toggle, name='post_like_toggle'),
    path('<int:pk>/favorite/', post_favorite_toggle, name='post_favorite_toggle'),
    path('<int:pk>/report/', post_report_view, name='post_report'),
    path('<int:post_id>/comments/', PostCommentListCreateAPIView.as_view(), name='post_comments'),
    path('<int:post_id>/comments/<int:pk>/', CommentDetailAPIView.as_view(), name='comment_detail'),
    path('<int:post_id>/comments/<int:comment_id>/report/', comment_report_view, name='comment_report'),
    path('log-interaction/', log_interaction, name='log_interaction'),
]
