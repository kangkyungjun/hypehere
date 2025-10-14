from django.urls import path
from .views import (
    # 프로필
    UserProfileAPIView,
    # 게시글
    PostListAPIView,
    PostDetailAPIView,
    PostCreateAPIView,
    PostUpdateAPIView,
    PostDeleteAPIView,
    # 좋아요
    PostLikeAPIView,
    CommentLikeAPIView,
    # 댓글
    CommentListAPIView,
    CommentCreateAPIView,
    CommentUpdateAPIView,
    CommentDeleteAPIView,
    # 팔로우
    FollowAPIView,
    FollowerListAPIView,
    FollowingListAPIView,
    # 피드
    RecommendedFeedAPIView,
    FollowingFeedAPIView,
)

app_name = "social"

urlpatterns = [
    # 프로필
    path("profile/", UserProfileAPIView.as_view(), name="profile"),
    path("profile/<int:user_id>/", UserProfileAPIView.as_view(), name="profile_detail"),

    # 게시글
    path("posts/", PostListAPIView.as_view(), name="post_list"),
    path("posts/<int:pk>/", PostDetailAPIView.as_view(), name="post_detail"),
    path("posts/create/", PostCreateAPIView.as_view(), name="post_create"),
    path("posts/<int:pk>/update/", PostUpdateAPIView.as_view(), name="post_update"),
    path("posts/<int:pk>/delete/", PostDeleteAPIView.as_view(), name="post_delete"),

    # 좋아요
    path("posts/<int:pk>/like/", PostLikeAPIView.as_view(), name="post_like"),
    path("comments/<int:pk>/like/", CommentLikeAPIView.as_view(), name="comment_like"),

    # 댓글
    path("posts/<int:post_id>/comments/", CommentListAPIView.as_view(), name="comment_list"),
    path("posts/<int:post_id>/comments/create/", CommentCreateAPIView.as_view(), name="comment_create"),
    path("comments/<int:pk>/update/", CommentUpdateAPIView.as_view(), name="comment_update"),
    path("comments/<int:pk>/delete/", CommentDeleteAPIView.as_view(), name="comment_delete"),

    # 팔로우
    path("follow/<int:user_id>/", FollowAPIView.as_view(), name="follow"),
    path("followers/", FollowerListAPIView.as_view(), name="follower_list"),
    path("followers/<int:user_id>/", FollowerListAPIView.as_view(), name="follower_list_detail"),
    path("following/", FollowingListAPIView.as_view(), name="following_list"),
    path("following/<int:user_id>/", FollowingListAPIView.as_view(), name="following_list_detail"),

    # 피드
    path("feed/recommended/", RecommendedFeedAPIView.as_view(), name="feed_recommended"),
    path("feed/following/", FollowingFeedAPIView.as_view(), name="feed_following"),
]
