from django.views.generic import TemplateView, RedirectView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.db.models import Count, Exists, OuterRef
from posts.models import Post, Like, PostFavorite
from posts.services.recommendation import get_recommendations_for_user


class HomeView(TemplateView):
    """
    Home page view
    Displays landing page for guests and personalized feed for authenticated users
    """
    template_name = 'home.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        if self.request.user.is_authenticated:
            try:
                # Get personalized recommendations using ML-based recommendation engine
                recommended_posts = get_recommendations_for_user(
                    user=self.request.user,
                    page=1,
                    page_size=20
                )

                # Fallback 1: 추천 엔진이 빈 리스트 반환 시
                if not recommended_posts:
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.warning(f"추천 엔진이 빈 리스트 반환 (사용자: {self.request.user.email})")

                    # 최신 게시글 반환 (기존 DB 데이터 사용)
                    recommended_posts = Post.objects.filter(
                        is_deleted_by_report=False
                    ).exclude(
                        author=self.request.user
                    ).select_related('author').prefetch_related('hashtags').order_by('-created_at')[:20]

            except Exception as e:
                # Fallback 2: 추천 엔진 에러 발생 시
                import logging
                logger = logging.getLogger(__name__)
                logger.error(f"추천 엔진 에러 (사용자: {self.request.user.email}): {e}", exc_info=True)

                # 최신 게시글로 안전하게 Fallback
                recommended_posts = Post.objects.filter(
                    is_deleted_by_report=False
                ).exclude(
                    author=self.request.user
                ).select_related('author').prefetch_related('hashtags').order_by('-created_at')[:20]

            # Annotate recommended posts with user-specific data
            if recommended_posts:
                # Get post IDs from recommendations
                post_ids = [post.id for post in recommended_posts]

                # Subquery to check if current user liked the post
                user_likes = Like.objects.filter(
                    post=OuterRef('pk'),
                    user=self.request.user
                )

                # Subquery to check if current user favorited the post
                user_favorites = PostFavorite.objects.filter(
                    post=OuterRef('pk'),
                    user=self.request.user
                )

                # Annotate posts with is_liked and is_favorited
                # Note: recommended_posts already have like_count and comment_count
                annotated_posts = Post.objects.filter(id__in=post_ids).select_related('author').prefetch_related('hashtags').annotate(
                    like_count=Count('likes', distinct=True),
                    comment_count=Count('comments', distinct=True),
                    is_liked=Exists(user_likes),
                    is_favorited=Exists(user_favorites)
                )

                # Preserve recommendation order
                post_dict = {post.id: post for post in annotated_posts}
                posts = [post_dict[post.id] for post in recommended_posts if post.id in post_dict]

                # Add permission flags for each post (admin can edit/delete any post)
                for post in posts:
                    post.can_edit = post.author == self.request.user or self.request.user.is_admin()
                    post.can_delete = post.author == self.request.user or self.request.user.is_admin()
            else:
                posts = []

            context['posts'] = posts
        return context


class MessageView(TemplateView):
    """
    Messages page view
    Displays message interface placeholder
    """
    template_name = 'messages.html'


class ExploreView(TemplateView):
    """
    Explore page view
    Displays search interface for discovering posts
    """
    template_name = 'explore.html'


class LearningMatchingView(LoginRequiredMixin, TemplateView):
    """
    1:1 language exchange matching page view
    Displays language partner matching interface
    """
    template_name = 'learning/matching.html'


class LearningChatView(LoginRequiredMixin, TemplateView):
    """
    Learning open chat page view
    Displays group learning chat rooms
    """
    template_name = 'learning/chat.html'
