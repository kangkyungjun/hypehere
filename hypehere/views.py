from django.views.generic import TemplateView, RedirectView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.db.models import Count, Exists, OuterRef
from posts.models import Post, Like, PostFavorite


class HomeView(TemplateView):
    """
    Home page view
    Displays landing page for guests and feed for authenticated users
    """
    template_name = 'home.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        if self.request.user.is_authenticated:
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

            # Fetch posts with like and comment counts
            posts = Post.objects.select_related('author').prefetch_related('hashtags').annotate(
                like_count=Count('likes', distinct=True),
                comment_count=Count('comments', distinct=True),
                is_liked=Exists(user_likes),
                is_favorited=Exists(user_favorites)
            ).order_by('-created_at')[:20]

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
