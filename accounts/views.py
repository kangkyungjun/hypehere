from rest_framework import status, generics, permissions
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.authtoken.models import Token
from django.contrib.auth import get_user_model, login, logout
from django.views.generic import TemplateView, FormView, ListView, CreateView, DetailView, View
from django.contrib.auth.views import LoginView as DjangoLoginView, LogoutView as DjangoLogoutView
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.urls import reverse_lazy
from django.contrib import messages
from django.shortcuts import get_object_or_404, redirect, render
from django.db.models import Q, Count, Prefetch
from django.utils import timezone
from django.utils.translation import gettext as _
from datetime import timedelta
from .utils import format_timedelta
from .serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserProfileSerializer,
    UserUpdateSerializer,
    PasswordChangeSerializer,
    FollowSerializer,
    UserProfileDetailSerializer,
    PrivacySettingsSerializer,
    BlockSerializer,
    UserReportSerializer
)
from .models import Follow, Block, SupportTicket, UserReport
from posts.models import Post, PostFavorite, PostReport, CommentReport
from posts.serializers import PostSerializer, PostFavoriteSerializer
from posts.views import PostPagination
from chat.models import OpenChatFavorite, Report
from chat.serializers import OpenChatFavoriteSerializer
from posts.admin_actions import (
    handle_report_delete,
    handle_report_dismiss,
    handle_comment_report_delete,
    handle_comment_report_dismiss
)

User = get_user_model()


class UserRegistrationView(generics.CreateAPIView):
    """
    API view for user registration
    POST /api/accounts/register/
    """
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Create authentication token
        token, created = Token.objects.get_or_create(user=user)

        return Response({
            'user': UserProfileSerializer(user).data,
            'token': token.key,
            'message': 'User registered successfully'
        }, status=status.HTTP_201_CREATED)


class UserLoginView(APIView):
    """
    API view for user login
    POST /api/accounts/login/
    """
    permission_classes = [permissions.AllowAny]
    serializer_class = UserLoginSerializer

    def post(self, request):
        serializer = self.serializer_class(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)

        user = serializer.validated_data['user']
        login(request, user)

        # Reactivate account if deactivated
        if user.is_deactivated:
            user.is_deactivated = False
            user.deactivated_at = None

        # Get or create authentication token
        token, created = Token.objects.get_or_create(user=user)

        # Update last login IP
        if 'HTTP_X_FORWARDED_FOR' in request.META:
            user.last_login_ip = request.META['HTTP_X_FORWARDED_FOR'].split(',')[0]
        else:
            user.last_login_ip = request.META.get('REMOTE_ADDR')

        # Save all changes
        user.save(update_fields=['last_login_ip', 'is_deactivated', 'deactivated_at'])

        return Response({
            'user': UserProfileSerializer(user).data,
            'token': token.key,
            'message': 'Login successful'
        }, status=status.HTTP_200_OK)


class UserLogoutView(APIView):
    """
    API view for user logout
    POST /api/accounts/logout/
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # Delete the user's token
        try:
            request.user.auth_token.delete()
        except:
            pass

        logout(request)

        return Response({
            'message': 'Logout successful'
        }, status=status.HTTP_200_OK)


class UserProfileView(generics.RetrieveAPIView):
    """
    API view for retrieving user profile
    GET /api/accounts/profile/
    """
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


class UserUpdateView(generics.UpdateAPIView):
    """
    API view for updating user profile
    PUT/PATCH /api/accounts/update/
    """
    serializer_class = UserUpdateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(
            instance,
            data=request.data,
            partial=partial
        )
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)

        return Response({
            'user': UserProfileSerializer(instance).data,
            'message': 'Profile updated successfully'
        }, status=status.HTTP_200_OK)


class PasswordChangeView(APIView):
    """
    API view for changing password
    POST /api/accounts/change-password/
    """
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = PasswordChangeSerializer

    def post(self, request):
        serializer = self.serializer_class(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

        # Delete old token and create new one
        try:
            request.user.auth_token.delete()
        except:
            pass

        token = Token.objects.create(user=request.user)

        return Response({
            'token': token.key,
            'message': 'Password changed successfully'
        }, status=status.HTTP_200_OK)


class UserDeleteView(APIView):
    """
    API view for deleting user account
    DELETE /api/accounts/delete/
    """
    permissions_classes = [permissions.IsAuthenticated]

    def delete(self, request):
        user = request.user
        user.is_active = False
        user.save()

        return Response({
            'message': 'Account deactivated successfully'
        }, status=status.HTTP_200_OK)


class CombinedSearchAPIView(APIView):
    """
    API view for combined user and post search
    GET /api/accounts/search/combined/?q=query
    Returns: {users: [...], posts: [...]}
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        query = request.query_params.get('q', '').strip()

        if not query:
            return Response({'users': [], 'posts': []})

        # Search users by nickname (case-insensitive)
        users = User.objects.filter(
            Q(nickname__icontains=query)
        ).exclude(is_deactivated=True)

        # 차단 관계 필터링 (로그인한 경우)
        if request.user.is_authenticated:
            from accounts.models import Block
            # 내가 차단한 사용자 제외
            blocked_users = Block.objects.filter(blocker=request.user, is_active=True).values_list('blocked', flat=True)
            users = users.exclude(id__in=blocked_users)

            # 나를 차단한 사용자 제외
            blocking_users = Block.objects.filter(blocked=request.user, is_active=True).values_list('blocker', flat=True)
            users = users.exclude(id__in=blocking_users)

        users = users.order_by('nickname')[:20]  # Limit to 20 users

        # Search posts by content and hashtags
        from posts.models import Post
        posts = Post.objects.select_related('author').prefetch_related('hashtags').annotate(
            like_count=Count('likes', distinct=True),
            comment_count=Count('comments', distinct=True)
        ).filter(
            Q(content__icontains=query) | Q(hashtags__name__icontains=query)
        ).distinct()

        # 차단 관계 필터링 (로그인한 경우) - 게시물도 필터링
        if request.user.is_authenticated:
            from accounts.models import Block
            # 내가 차단한 사용자의 게시물 제외
            blocked_users = Block.objects.filter(blocker=request.user, is_active=True).values_list('blocked', flat=True)
            posts = posts.exclude(author__in=blocked_users)

            # 나를 차단한 사용자의 게시물 제외
            blocking_users = Block.objects.filter(blocked=request.user, is_active=True).values_list('blocker', flat=True)
            posts = posts.exclude(author__in=blocking_users)

        posts = posts.order_by('-created_at')[:30]  # Limit to 30 posts

        # Serialize the data
        user_data = []
        for user in users:
            # Get posts count for each user
            posts_count = Post.objects.filter(author=user).count()

            user_data.append({
                'id': user.id,
                'username': user.username,
                'nickname': user.nickname,
                'display_name': user.display_name,
                'profile_picture': user.profile_picture.url if user.profile_picture else None,
                'bio': user.bio[:10] if hasattr(user, 'bio') and user.bio else '',  # First 10 chars of bio
                'follower_count': user.get_follower_count(),  # Real follower count
                'following_count': user.get_following_count(),  # Real following count
                'posts_count': posts_count
            })

        post_data = PostSerializer(posts, many=True, context={'request': request}).data

        return Response({
            'users': user_data,
            'posts': post_data
        })


# ==========================================
# HTML Template Views
# ==========================================

class LoginTemplateView(DjangoLoginView):
    """
    HTML view for user login
    GET/POST /accounts/login/
    """
    template_name = 'accounts/login.html'
    redirect_authenticated_user = True
    success_url = reverse_lazy('home')

    def get_success_url(self):
        return self.get_redirect_url() or reverse_lazy('home')


class LogoutTemplateView(DjangoLogoutView):
    """
    HTML view for user logout
    POST /accounts/logout/
    """
    next_page = reverse_lazy('home')


class RegisterTemplateView(TemplateView):
    """
    HTML view for user registration
    GET /accounts/register/
    """
    template_name = 'accounts/register.html'


class ProfileTemplateView(LoginRequiredMixin, TemplateView):
    """
    HTML view for user profile
    GET /accounts/profile/ - Own profile
    GET /accounts/profile/<username>/ - Other user's profile
    """
    template_name = 'accounts/profile.html'
    login_url = reverse_lazy('accounts:login')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        username = kwargs.get('username')

        if username:
            # Viewing another user's profile
            profile_user = get_object_or_404(User, username=username)
            # Check if profile is deactivated
            if profile_user.is_deactivated:
                context.update({
                    'deactivated': True,
                    'profile_user': profile_user,
                })
                return context
        else:
            # Viewing own profile
            profile_user = self.request.user

        is_own_profile = (self.request.user == profile_user)

        # Check if blocked (only if viewing another user's profile)
        if not is_own_profile:
            is_blocking = self.request.user.is_blocking(profile_user)
            is_blocked_by = profile_user.is_blocking(self.request.user)

            if is_blocking or is_blocked_by:
                context.update({
                    'blocked': True,
                    'is_blocking': is_blocking,
                    'is_blocked_by': is_blocked_by,
                    'profile_user': profile_user,
                    'is_own_profile': False,
                })
                return context

        # Fetch user's posts
        user_posts = Post.objects.filter(author=profile_user).select_related('author').prefetch_related('hashtags').annotate(
            like_count=Count('likes', distinct=True),
            comment_count=Count('comments', distinct=True)
        ).order_by('-created_at')
        initial_posts = user_posts[:10]  # First 10 posts for initial load
        total_posts = user_posts.count()

        context.update({
            'profile_user': profile_user,
            'is_own_profile': is_own_profile,
            'initial_posts': initial_posts,
            'total_posts': total_posts,
            'has_more_posts': total_posts > 10,
        })

        # Admin-only section
        if self.request.user.is_staff:
            # Get approved report counts by type
            cutoff = timezone.now() - timedelta(days=30)

            post_reports_count = PostReport.objects.filter(
                reported_user=profile_user,
                status='resolved'
            ).count()

            comment_reports_count = CommentReport.objects.filter(
                reported_user=profile_user,
                status='resolved'
            ).count()

            chat_reports_count = Report.objects.filter(
                reported_user=profile_user,
                status='resolved'
            ).count()

            # Active reports (within 1 month)
            active_post_reports = PostReport.objects.filter(
                reported_user=profile_user,
                status='resolved',
                reviewed_at__gte=cutoff
            ).count()

            active_comment_reports = CommentReport.objects.filter(
                reported_user=profile_user,
                status='resolved',
                reviewed_at__gte=cutoff
            ).count()

            active_chat_reports = Report.objects.filter(
                reported_user=profile_user,
                status='resolved',
                reviewed_at__gte=cutoff
            ).count()

            active_reports_count = active_post_reports + active_comment_reports + active_chat_reports

            # Recent reports (removed for UI optimization)
            # recent_post_reports = PostReport.objects.filter(
            #     reported_user=profile_user,
            #     status='resolved'
            # ).select_related('reporter', 'post').order_by('-reviewed_at')[:5]
            #
            # recent_comment_reports = CommentReport.objects.filter(
            #     reported_user=profile_user,
            #     status='resolved'
            # ).select_related('reporter', 'comment').order_by('-reviewed_at')[:5]
            #
            # # Combine and sort recent reports
            # all_recent_reports = list(recent_post_reports) + list(recent_comment_reports)
            # all_recent_reports.sort(key=lambda x: x.reviewed_at, reverse=True)
            # recent_reports = all_recent_reports[:5]

            # Pending reports count
            pending_reports = (
                PostReport.objects.filter(reported_user=profile_user, status='pending').count() +
                CommentReport.objects.filter(reported_user=profile_user, status='pending').count() +
                Report.objects.filter(reported_user=profile_user, status='pending').count()
            )

            context['admin_section'] = {
                'approved_report_count': profile_user.report_count,
                'active_reports_count': active_reports_count,
                'pending_reports': pending_reports,
                'report_breakdown': {
                    'post_reports': post_reports_count,
                    'comment_reports': comment_reports_count,
                    'chat_reports': chat_reports_count,
                },
                'active_report_breakdown': {
                    'post_reports': active_post_reports,
                    'comment_reports': active_comment_reports,
                    'chat_reports': active_chat_reports,
                }
            }

        # Suspension info for own profile
        if is_own_profile and profile_user.is_currently_suspended():
            remaining = profile_user.get_suspension_time_remaining()
            context['suspension_info'] = {
                'is_suspended': True,
                'reason': profile_user.suspension_reason,
                'until': profile_user.suspended_until,
                'time_remaining': format_timedelta(remaining)
            }

        return context


class UserPostsAPIView(generics.ListAPIView):
    """
    API view for user's posts with pagination
    GET /api/accounts/<username>/posts/
    """
    serializer_class = PostSerializer
    pagination_class = PostPagination
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        """Get posts for specific user"""
        username = self.kwargs.get('username')
        user = get_object_or_404(User, username=username)
        # Don't show posts if user is deactivated
        if user.is_deactivated:
            return Post.objects.none()
        return Post.objects.filter(author=user).select_related('author').prefetch_related('hashtags').order_by('-created_at')


class UserPostsSearchAPIView(generics.ListAPIView):
    """
    API view for searching user's posts
    GET /api/accounts/<username>/posts/search/?q=query&hashtags=tag1,tag2
    """
    serializer_class = PostSerializer
    pagination_class = PostPagination
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        """Search posts for specific user by content or hashtags"""
        username = self.kwargs.get('username')
        user = get_object_or_404(User, username=username)

        # Base queryset: posts by this user
        queryset = Post.objects.filter(author=user)

        # Get search parameters
        query = self.request.query_params.get('q', '').strip()
        hashtags = self.request.query_params.get('hashtags', '').strip()

        # Build search filters using Q objects
        filters = Q()

        if query:
            filters |= Q(content__icontains=query)

        if hashtags:
            hashtag_list = [tag.strip().lower() for tag in hashtags.split(',') if tag.strip()]
            if hashtag_list:
                filters |= Q(hashtags__name__in=hashtag_list)

        # Apply filters if any
        if filters:
            queryset = queryset.filter(filters).distinct()

        return queryset.select_related('author').prefetch_related('hashtags').order_by('-created_at')


class ProfileUpdateTemplateView(LoginRequiredMixin, TemplateView):
    """
    HTML view for updating user profile
    GET /accounts/update/
    """
    template_name = 'accounts/profile_update.html'
    login_url = reverse_lazy('accounts:login')


class SettingsTemplateView(LoginRequiredMixin, TemplateView):
    """
    HTML view for user settings
    GET /accounts/settings/
    """
    template_name = 'accounts/settings.html'
    login_url = reverse_lazy('accounts:login')


class AdminPanelView(LoginRequiredMixin, UserPassesTestMixin, TemplateView):
    """
    Admin panel view - only accessible to staff users
    GET /accounts/admin-panel/
    """
    template_name = 'accounts/admin_panel.html'
    login_url = reverse_lazy('accounts:login')

    def test_func(self):
        """Check if user is staff"""
        return self.request.user.is_staff


class NotificationSettingsTemplateView(LoginRequiredMixin, TemplateView):
    """
    HTML view for notification settings
    GET /accounts/settings/notifications/
    """
    template_name = 'accounts/notification_settings.html'
    login_url = reverse_lazy('accounts:login')


class FollowersListTemplateView(LoginRequiredMixin, TemplateView):
    """
    HTML view for displaying followers list
    GET /accounts/profile/<username>/followers/
    """
    template_name = 'accounts/followers_list.html'
    login_url = reverse_lazy('accounts:login')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        username = self.kwargs.get('username')
        context['username'] = username
        context['page_type'] = 'followers'
        return context


class FollowingListTemplateView(LoginRequiredMixin, TemplateView):
    """
    HTML view for displaying following list
    GET /accounts/profile/<username>/following/
    """
    template_name = 'accounts/following_list.html'
    login_url = reverse_lazy('accounts:login')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        username = self.kwargs.get('username')
        context['username'] = username
        context['page_type'] = 'following'
        return context


class PrivacySettingsTemplateView(LoginRequiredMixin, TemplateView):
    """
    HTML view for privacy settings
    GET /accounts/settings/privacy/
    """
    template_name = 'accounts/privacy_settings.html'
    login_url = reverse_lazy('accounts:login')


class BlockedUsersListTemplateView(LoginRequiredMixin, TemplateView):
    """
    HTML view for blocked users list
    GET /accounts/settings/blocked-users/
    """
    template_name = 'accounts/blocked_users_list.html'
    login_url = reverse_lazy('accounts:login')


class AccountManagementTemplateView(LoginRequiredMixin, TemplateView):
    """
    HTML view for account management
    GET /accounts/settings/account-management/
    """
    template_name = 'accounts/account_management.html'
    login_url = reverse_lazy('accounts:login')


# ==========================================
# Follow System Views
# ==========================================

class FollowUserView(APIView):
    """
    API view for following a user
    POST /api/accounts/<username>/follow/
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, username):
        # Get user to follow
        user_to_follow = get_object_or_404(User, username=username)

        # Can't follow yourself
        if request.user == user_to_follow:
            return Response({
                'error': 'You cannot follow yourself'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Check if already following
        if request.user.is_following(user_to_follow):
            return Response({
                'error': 'You are already following this user'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Create follow relationship
        Follow.objects.create(
            follower=request.user,
            following=user_to_follow
        )

        return Response({
            'message': 'Successfully followed user',
            'is_following': True,
            'is_follower': user_to_follow.is_following(request.user),
            'follower_count': user_to_follow.get_follower_count()
        }, status=status.HTTP_201_CREATED)


class UnfollowUserView(APIView):
    """
    API view for unfollowing a user
    DELETE /api/accounts/<username>/unfollow/
    """
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, username):
        # Get user to unfollow
        user_to_unfollow = get_object_or_404(User, username=username)

        # Check if following
        follow_relation = Follow.objects.filter(
            follower=request.user,
            following=user_to_unfollow
        ).first()

        if not follow_relation:
            return Response({
                'error': 'You are not following this user'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Delete follow relationship
        follow_relation.delete()

        return Response({
            'message': 'Successfully unfollowed user',
            'is_following': False,
            'is_follower': user_to_unfollow.is_following(request.user),
            'follower_count': user_to_unfollow.get_follower_count()
        }, status=status.HTTP_200_OK)


class FollowStatusView(APIView):
    """
    API view for checking follow status
    GET /api/accounts/<username>/follow-status/
    """
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get(self, request, username):
        user = get_object_or_404(User, username=username)

        is_following = False
        is_follower = False
        if request.user.is_authenticated:
            is_following = request.user.is_following(user)
            is_follower = user.is_following(request.user)

        return Response({
            'username': user.username,
            'follower_count': user.get_follower_count(),
            'following_count': user.get_following_count(),
            'is_following': is_following,
            'is_follower': is_follower
        }, status=status.HTTP_200_OK)


class FollowersListView(generics.ListAPIView):
    """
    API view for listing user's followers
    GET /api/accounts/<username>/followers/
    """
    serializer_class = UserProfileDetailSerializer
    permission_classes = [permissions.AllowAny]

    def list(self, request, *args, **kwargs):
        username = self.kwargs.get('username')
        target_user = get_object_or_404(User, username=username)
        current_user = request.user if request.user.is_authenticated else None

        # Check visibility permissions
        if target_user.show_followers_list == 'nobody':
            if current_user != target_user:
                return Response(
                    {'error': '이 사용자의 팔로워 목록은 비공개입니다'},
                    status=status.HTTP_403_FORBIDDEN
                )
        elif target_user.show_followers_list == 'followers':
            if current_user != target_user:
                if not current_user or not target_user.is_follower(current_user):
                    return Response(
                        {'error': '팔로워만 목록을 볼 수 있습니다'},
                        status=status.HTTP_403_FORBIDDEN
                    )

        # Check if blocked
        if current_user and (target_user.is_blocking(current_user) or current_user.is_blocking(target_user)):
            return Response(
                {'error': '접근할 수 없습니다'},
                status=status.HTTP_403_FORBIDDEN
            )

        return super().list(request, *args, **kwargs)

    def get_queryset(self):
        username = self.kwargs.get('username')
        user = get_object_or_404(User, username=username)
        # Get followers: users who follow this user
        follower_ids = Follow.objects.filter(following=user).values_list('follower_id', flat=True)
        return User.objects.filter(id__in=follower_ids).exclude(is_deactivated=True)


class FollowingListView(generics.ListAPIView):
    """
    API view for listing users that this user follows
    GET /api/accounts/<username>/following/
    """
    serializer_class = UserProfileDetailSerializer
    permission_classes = [permissions.AllowAny]

    def list(self, request, *args, **kwargs):
        username = self.kwargs.get('username')
        target_user = get_object_or_404(User, username=username)
        current_user = request.user if request.user.is_authenticated else None

        # Check visibility permissions
        if target_user.show_following_list == 'nobody':
            if current_user != target_user:
                return Response(
                    {'error': '이 사용자의 팔로잉 목록은 비공개입니다'},
                    status=status.HTTP_403_FORBIDDEN
                )
        elif target_user.show_following_list == 'followers':
            if current_user != target_user:
                if not current_user or not target_user.is_follower(current_user):
                    return Response(
                        {'error': '팔로워만 목록을 볼 수 있습니다'},
                        status=status.HTTP_403_FORBIDDEN
                    )

        # Check if blocked
        if current_user and (target_user.is_blocking(current_user) or current_user.is_blocking(target_user)):
            return Response(
                {'error': '접근할 수 없습니다'},
                status=status.HTTP_403_FORBIDDEN
            )

        return super().list(request, *args, **kwargs)

    def get_queryset(self):
        username = self.kwargs.get('username')
        user = get_object_or_404(User, username=username)
        # Get following: users this user follows
        following_ids = Follow.objects.filter(follower=user).values_list('following_id', flat=True)
        return User.objects.filter(id__in=following_ids).exclude(is_deactivated=True)


# ============================================
# Privacy & Block Management Views
# ============================================

class PrivacySettingsView(APIView):
    """
    API view for managing user privacy settings
    GET /api/accounts/privacy-settings/ - Get current privacy settings
    PATCH /api/accounts/privacy-settings/ - Update privacy settings
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Get current user's privacy settings"""
        serializer = PrivacySettingsSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        """Update current user's privacy settings"""
        serializer = PrivacySettingsSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class BlockUserView(APIView):
    """
    API view for blocking a user
    POST /api/accounts/<username>/block/
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, username):
        """Block a user"""
        user_to_block = get_object_or_404(User, username=username)

        # Cannot block yourself
        if user_to_block == request.user:
            return Response(
                {'error': 'You cannot block yourself'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if already actively blocked
        if request.user.is_blocking(user_to_block):
            return Response(
                {'error': 'User is already blocked'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if there's an inactive block record (previously blocked then unblocked)
        existing_block = Block.objects.filter(
            blocker=request.user,
            blocked=user_to_block,
            is_active=False
        ).first()

        if existing_block:
            # Re-activate the existing block
            existing_block.is_active = True
            existing_block.unblocked_at = None
            existing_block.save(update_fields=['is_active', 'unblocked_at'])
            block = existing_block
        else:
            # Create new block relationship
            block = Block.objects.create(
                blocker=request.user,
                blocked=user_to_block
            )

        # Remove follow relationships if they exist
        Follow.objects.filter(
            Q(follower=request.user, following=user_to_block) |
            Q(follower=user_to_block, following=request.user)
        ).delete()

        serializer = BlockSerializer(block)
        return Response({
            'message': 'User blocked successfully',
            'block': serializer.data
        }, status=status.HTTP_201_CREATED)


class UnblockUserView(APIView):
    """
    API view for unblocking a user
    DELETE /api/accounts/<username>/unblock/
    """
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, username):
        """Unblock a user"""
        from django.utils import timezone

        user_to_unblock = get_object_or_404(User, username=username)

        # Check if user is actively blocked
        block = Block.objects.filter(
            blocker=request.user,
            blocked=user_to_unblock,
            is_active=True
        ).first()

        if not block:
            return Response(
                {'error': 'User is not blocked'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Soft delete: 삭제하지 않고 is_active=False로 변경
        block.is_active = False
        block.unblocked_at = timezone.now()
        block.save(update_fields=['is_active', 'unblocked_at'])

        return Response({
            'message': 'User unblocked successfully'
        }, status=status.HTTP_200_OK)


class BlockedUsersListView(generics.ListAPIView):
    """
    API view for listing blocked users
    GET /api/accounts/blocked-users/
    """
    serializer_class = UserProfileDetailSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Get users that current user has actively blocked
        blocked_ids = Block.objects.filter(
            blocker=self.request.user,
            is_active=True
        ).values_list('blocked_id', flat=True)
        return User.objects.filter(id__in=blocked_ids)


# ============================================
# Account Management Views
# ============================================

class AccountStatusView(APIView):
    """
    API view for getting account status
    GET /api/accounts/account-status/
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = AccountManagementSerializer(request.user)
        return Response(serializer.data)


class DeactivateAccountView(APIView):
    """
    API view for deactivating account
    POST /api/accounts/deactivate/
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        user.is_deactivated = True
        user.deactivated_at = timezone.now()
        user.save()

        return Response({
            'message': '계정이 비활성화되었습니다'
        })


class ReactivateAccountView(APIView):
    """
    API view for reactivating account
    POST /api/accounts/reactivate/
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        user.is_deactivated = False
        user.deactivated_at = None
        user.save()

        return Response({
            'message': '계정이 다시 활성화되었습니다'
        })


class RequestAccountDeletionView(APIView):
    """
    API view for requesting account deletion
    POST /api/accounts/request-deletion/
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user

        if user.deletion_requested_at:
            return Response({
                'error': '이미 삭제가 예약되어 있습니다'
            }, status=status.HTTP_400_BAD_REQUEST)

        user.deletion_requested_at = timezone.now()
        user.save()

        from datetime import timedelta
        deletion_date = user.deletion_requested_at + timedelta(days=30)

        # TODO: Send email notification

        return Response({
            'message': '계정 삭제가 예약되었습니다. 30일 후 영구 삭제됩니다.',
            'deletion_date': deletion_date,
            'days_remaining': 30
        })


class CancelAccountDeletionView(APIView):
    """
    API view for cancelling account deletion
    POST /api/accounts/cancel-deletion/
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user

        if not user.deletion_requested_at:
            return Response({
                'error': '삭제 요청이 없습니다'
            }, status=status.HTTP_400_BAD_REQUEST)

        if not user.can_cancel_deletion():
            return Response({
                'error': '취소 가능 기간이 지났습니다'
            }, status=status.HTTP_400_BAD_REQUEST)

        user.deletion_requested_at = None
        user.save()

        return Response({
            'message': '계정 삭제가 취소되었습니다'
        })


# ============================================
# Favorites Views
# ============================================

class FavoritesTemplateView(LoginRequiredMixin, TemplateView):
    """
    HTML view for unified favorites page
    GET /accounts/favorites/
    """
    template_name = 'accounts/favorites.html'
    login_url = reverse_lazy('accounts:login')


class UserFavoritesAPIView(APIView):
    """
    API view for fetching all user favorites
    GET /api/accounts/favorites/
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        # Fetch chat room favorites
        chat_favorites = OpenChatFavorite.objects.filter(
            user=request.user
        ).select_related('room')

        # Fetch post favorites
        post_favorites = PostFavorite.objects.filter(
            user=request.user
        ).prefetch_related(
            Prefetch(
                'post',
                queryset=Post.objects.select_related('author').prefetch_related('hashtags').annotate(
                    like_count=Count('likes', distinct=True),
                    comment_count=Count('comments', distinct=True)
                )
            )
        )

        return Response({
            'chat_rooms': OpenChatFavoriteSerializer(
                chat_favorites,
                many=True,
                context={'request': request}
            ).data,
            'posts': PostFavoriteSerializer(
                post_favorites,
                many=True,
                context={'request': request}
            ).data
        })


# ==================== Support Ticket Views ====================

class SupportTicketListView(LoginRequiredMixin, ListView):
    """
    Support ticket list view
    - Regular users see only their own tickets
    - Staff users see all tickets
    """
    model = SupportTicket
    template_name = 'accounts/support/list.html'
    context_object_name = 'tickets'
    paginate_by = 20

    def get_queryset(self):
        # Get base queryset based on user role
        if self.request.user.is_staff:
            queryset = SupportTicket.objects.all()
        else:
            queryset = SupportTicket.objects.filter(user=self.request.user)

        # Apply status filter
        status = self.request.GET.get('status')
        if status and status in ['pending', 'answered']:
            queryset = queryset.filter(status=status)

        # Apply search filter
        search = self.request.GET.get('search')
        if search:
            queryset = queryset.filter(title__icontains=search)

        return queryset.select_related('user', 'responded_by')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['is_staff'] = self.request.user.is_staff

        # Get base queryset for counts (before filtering)
        if self.request.user.is_staff:
            base_qs = SupportTicket.objects.all()
        else:
            base_qs = SupportTicket.objects.filter(user=self.request.user)

        # Calculate status counts
        context['total_count'] = base_qs.count()
        context['pending_count'] = base_qs.filter(status='pending').count()
        context['answered_count'] = base_qs.filter(status='answered').count()

        return context


class SupportTicketCreateView(LoginRequiredMixin, CreateView):
    """
    Support ticket creation view
    Users can create new support tickets
    """
    model = SupportTicket
    template_name = 'accounts/support/create.html'
    fields = ['category', 'title', 'content']
    success_url = reverse_lazy('accounts:support_list')

    def form_valid(self, form):
        form.instance.user = self.request.user
        messages.success(self.request, _('문의가 성공적으로 등록되었습니다.'))
        return super().form_valid(form)


class SupportTicketDetailView(LoginRequiredMixin, DetailView):
    """
    Support ticket detail view
    - Regular users can view only their own tickets
    - Staff can view all tickets
    """
    model = SupportTicket
    template_name = 'accounts/support/detail.html'
    context_object_name = 'ticket'

    def get_queryset(self):
        if self.request.user.is_staff:
            # Staff can view all tickets
            return SupportTicket.objects.all().select_related('user', 'responded_by')
        else:
            # Regular users can view only their own tickets
            return SupportTicket.objects.filter(user=self.request.user).select_related('responded_by')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['is_staff'] = self.request.user.is_staff
        return context


class SupportTicketRespondView(LoginRequiredMixin, UserPassesTestMixin, View):
    """
    Support ticket response view (Staff only)
    Allows staff to respond to support tickets
    """

    def test_func(self):
        # Only staff can respond to tickets
        return self.request.user.is_staff

    def post(self, request, pk):
        ticket = get_object_or_404(SupportTicket, pk=pk)

        admin_response = request.POST.get('admin_response', '').strip()

        if not admin_response:
            messages.error(request, _('답변 내용을 입력해주세요.'))
            return redirect('accounts:support_detail', pk=pk)

        # Save response
        ticket.admin_response = admin_response
        ticket.responded_by = request.user
        ticket.responded_at = timezone.now()
        ticket.status = 'answered'
        ticket.save()

        messages.success(request, _('답변이 성공적으로 등록되었습니다.'))
        return redirect('accounts:support_detail', pk=pk)


class ReportHistoryTemplateView(LoginRequiredMixin, TemplateView):
    """사용자가 제출한 신고 내역 조회"""
    template_name = 'accounts/report_history.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)

        # 초기 20개만 로드 (무한 스크롤용)
        # 게시물 신고 내역
        post_reports_query = PostReport.objects.select_related('reported_user', 'post').order_by('-created_at')
        if not self.request.user.is_staff:
            post_reports_query = post_reports_query.filter(reporter=self.request.user)
        context['post_reports'] = post_reports_query[:20]

        # 댓글 신고 내역
        comment_reports_query = CommentReport.objects.select_related('reported_user', 'comment', 'comment__post').order_by('-created_at')
        if not self.request.user.is_staff:
            comment_reports_query = comment_reports_query.filter(reporter=self.request.user)
        context['comment_reports'] = comment_reports_query[:20]

        # 채팅 신고 내역
        chat_reports_query = Report.objects.select_related('reported_user').order_by('-created_at')
        if not self.request.user.is_staff:
            chat_reports_query = chat_reports_query.filter(reporter=self.request.user)
        context['chat_reports'] = chat_reports_query[:20]

        return context


class ReportListAPIView(APIView):
    """AJAX로 신고 목록 반환 (무한 스크롤용)"""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        # URL 파라미터
        report_type = request.GET.get('report_type', 'post')  # 'post', 'comment', or 'chat'
        page = int(request.GET.get('page', 1))
        status_filter = request.GET.get('status', '')
        type_filter = request.GET.get('type', '')
        date_filter = request.GET.get('date', '')
        search_query = request.GET.get('q', '')

        # 기본 쿼리셋
        if report_type == 'post':
            queryset = PostReport.objects.select_related('reporter', 'reported_user', 'post')
        elif report_type == 'comment':
            queryset = CommentReport.objects.select_related('reporter', 'reported_user', 'comment', 'comment__post')
        else:
            queryset = Report.objects.select_related('reporter', 'reported_user')

        # 권한별 필터링
        if not request.user.is_staff:
            queryset = queryset.filter(reporter=request.user)

        # 상태 필터
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        # 신고 타입 필터
        if type_filter:
            queryset = queryset.filter(report_type=type_filter)

        # 날짜 필터
        if date_filter:
            from datetime import timedelta
            today = timezone.now().date()
            if date_filter == 'today':
                queryset = queryset.filter(created_at__date=today)
            elif date_filter == 'week':
                week_ago = today - timedelta(days=7)
                queryset = queryset.filter(created_at__date__gte=week_ago)
            elif date_filter == 'month':
                month_ago = today - timedelta(days=30)
                queryset = queryset.filter(created_at__date__gte=month_ago)

        # 검색 쿼리
        if search_query:
            if report_type == 'post':
                queryset = queryset.filter(
                    Q(reported_user__nickname__icontains=search_query) |
                    Q(description__icontains=search_query) |
                    Q(post__content__icontains=search_query)
                )
            elif report_type == 'comment':
                queryset = queryset.filter(
                    Q(reported_user__nickname__icontains=search_query) |
                    Q(description__icontains=search_query) |
                    Q(comment__content__icontains=search_query)
                )
            else:
                queryset = queryset.filter(
                    Q(reported_user__nickname__icontains=search_query) |
                    Q(description__icontains=search_query)
                )

        # 정렬
        queryset = queryset.order_by('-created_at')

        # 페이지네이션 (20개씩)
        items_per_page = 20
        start = (page - 1) * items_per_page
        end = start + items_per_page

        reports = queryset[start:end + 1]  # +1 to check if there's a next page
        has_next = len(reports) > items_per_page
        reports = reports[:items_per_page]  # Trim to actual page size

        # 데이터 직렬화
        reports_data = []
        for report in reports:
            report_dict = {
                'id': report.id,
                'reporter_nickname': report.reporter.nickname if hasattr(report.reporter, 'nickname') else report.reporter.username,
                'reported_user_nickname': report.reported_user.nickname if hasattr(report.reported_user, 'nickname') else report.reported_user.username,
                'report_type': report.report_type,
                'report_type_display': report.get_report_type_display(),
                'status': report.status,
                'status_display': report.get_status_display(),
                'description': report.description,
                'created_at': report.created_at.isoformat(),
            }

            if report_type == 'post' and hasattr(report, 'post') and report.post:
                report_dict['post_id'] = report.post.id
                report_dict['post_content'] = report.post.content[:100] if report.post.content else ''
            elif report_type == 'comment' and hasattr(report, 'comment') and report.comment:
                report_dict['comment_id'] = report.comment.id
                report_dict['comment_content'] = report.comment.content[:100] if report.comment.content else ''
                if report.comment.post:
                    report_dict['post_id'] = report.comment.post.id
            elif report_type == 'chat':
                # Add evidence fields for chat reports
                if hasattr(report, 'message_snapshot') and report.message_snapshot:
                    report_dict['message_snapshot'] = report.message_snapshot
                if hasattr(report, 'video_frame') and report.video_frame:
                    report_dict['video_frame_url'] = request.build_absolute_uri(report.video_frame.url)

            reports_data.append(report_dict)

        return Response({
            'reports': reports_data,
            'has_next': has_next,
            'page': page,
            'report_type': report_type
        }, status=status.HTTP_200_OK)


class ReportDeleteAPIView(APIView):
    """관리자 전용: 신고된 게시물 삭제 처리 API"""
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, report_id):
        try:
            # Get report (both PostReport and Chat Report)
            report_type = request.data.get('report_type', 'post')

            if report_type == 'post':
                report = get_object_or_404(PostReport, id=report_id)
                success = handle_report_delete(report, request.user)

                if success:
                    return Response({
                        'success': True,
                        'message': '게시물이 삭제되고 신고가 처리되었습니다.'
                    }, status=status.HTTP_200_OK)
                else:
                    return Response({
                        'success': False,
                        'message': '이미 처리된 신고입니다.'
                    }, status=status.HTTP_400_BAD_REQUEST)
            elif report_type == 'comment':
                report = get_object_or_404(CommentReport, id=report_id)
                success = handle_comment_report_delete(report, request.user)

                if success:
                    return Response({
                        'success': True,
                        'message': '댓글이 삭제되고 신고가 처리되었습니다.'
                    }, status=status.HTTP_200_OK)
                else:
                    return Response({
                        'success': False,
                        'message': '이미 처리된 신고입니다.'
                    }, status=status.HTTP_400_BAD_REQUEST)
            elif report_type == 'chat':
                from chat.models import Report as ChatReport
                from chat.admin_actions import handle_chat_report_delete

                report = get_object_or_404(ChatReport, id=report_id)
                result = handle_chat_report_delete(report, request.user)

                if result['success']:
                    return Response({
                        'success': True,
                        'message': result['message'],
                        'suspension_result': result.get('suspension_result'),
                        'report_count': result['report_count'],
                        'active_report_count': result['active_report_count']
                    }, status=status.HTTP_200_OK)
                else:
                    return Response({
                        'success': False,
                        'message': result['message']
                    }, status=status.HTTP_400_BAD_REQUEST)
            else:
                return Response({
                    'success': False,
                    'message': '알 수 없는 신고 유형입니다.'
                }, status=status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            return Response({
                'success': False,
                'message': f'오류가 발생했습니다: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ReportDismissAPIView(APIView):
    """관리자 전용: 신고 기각 처리 API"""
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, report_id):
        try:
            # Get report (both PostReport and Chat Report)
            report_type = request.data.get('report_type', 'post')

            if report_type == 'post':
                report = get_object_or_404(PostReport, id=report_id)
                success = handle_report_dismiss(report, request.user)

                if success:
                    return Response({
                        'success': True,
                        'message': '신고가 기각 처리되었습니다.'
                    }, status=status.HTTP_200_OK)
                else:
                    return Response({
                        'success': False,
                        'message': '신고 처리에 실패했습니다.'
                    }, status=status.HTTP_400_BAD_REQUEST)
            elif report_type == 'comment':
                report = get_object_or_404(CommentReport, id=report_id)
                success = handle_comment_report_dismiss(report, request.user)

                if success:
                    return Response({
                        'success': True,
                        'message': '신고가 기각 처리되었습니다.'
                    }, status=status.HTTP_200_OK)
                else:
                    return Response({
                        'success': False,
                        'message': '신고 처리에 실패했습니다.'
                    }, status=status.HTTP_400_BAD_REQUEST)
            elif report_type == 'chat':
                from chat.models import Report as ChatReport
                from chat.admin_actions import handle_chat_report_dismiss

                report = get_object_or_404(ChatReport, id=report_id)
                result = handle_chat_report_dismiss(report, request.user)

                if result['success']:
                    return Response({
                        'success': True,
                        'message': result['message'],
                        'report_count': result['report_count'],
                        'active_report_count': result['active_report_count']
                    }, status=status.HTTP_200_OK)
                else:
                    return Response({
                        'success': False,
                        'message': result['message']
                    }, status=status.HTTP_400_BAD_REQUEST)
            else:
                return Response({
                    'success': False,
                    'message': '알 수 없는 신고 유형입니다.'
                }, status=status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            return Response({
                'success': False,
                'message': f'오류가 발생했습니다: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class SuspendUserAPIView(APIView):
    """Admin-only API to suspend a user account"""
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, username):
        try:
            user = get_object_or_404(User, username=username)

            # Validation
            if user.is_staff:
                return Response({
                    'success': False,
                    'message': '관리자 계정은 정지할 수 없습니다.'
                }, status=status.HTTP_400_BAD_REQUEST)

            if user.is_banned:
                return Response({
                    'success': False,
                    'message': '이미 영구 밴 처리된 계정입니다.'
                }, status=status.HTTP_400_BAD_REQUEST)

            duration_days = request.data.get('duration_days')
            reason = request.data.get('reason', '')

            if not duration_days:
                return Response({
                    'success': False,
                    'message': '정지 기간을 입력해주세요.'
                }, status=status.HTTP_400_BAD_REQUEST)

            try:
                duration_days = int(duration_days)
                if duration_days < 1:
                    raise ValueError
            except ValueError:
                return Response({
                    'success': False,
                    'message': '정지 기간은 1일 이상이어야 합니다.'
                }, status=status.HTTP_400_BAD_REQUEST)

            # Suspend the account
            user.suspend_account(duration_days, reason, request.user)

            return Response({
                'success': True,
                'message': f'{user.username} 계정이 {duration_days}일 정지되었습니다.',
                'data': {
                    'username': user.username,
                    'suspended_until': user.suspended_until.isoformat() if user.suspended_until else None,
                    'reason': user.suspension_reason,
                    'suspended_by': request.user.username,
                }
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'message': f'오류가 발생했습니다: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class LiftSuspensionAPIView(APIView):
    """Admin-only API to lift user suspension"""
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, username):
        try:
            user = get_object_or_404(User, username=username)

            if not user.is_suspended:
                return Response({
                    'success': False,
                    'message': '정지되지 않은 계정입니다.'
                }, status=status.HTTP_400_BAD_REQUEST)

            # Lift suspension
            user.lift_suspension()

            return Response({
                'success': True,
                'message': f'{user.username} 계정의 정지가 해제되었습니다.',
                'data': {
                    'username': user.username,
                }
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'message': f'오류가 발생했습니다: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class BanUserAPIView(APIView):
    """Admin-only API to permanently ban a user account"""
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, username):
        try:
            user = get_object_or_404(User, username=username)

            # Validation
            if user.is_staff:
                return Response({
                    'success': False,
                    'message': '관리자 계정은 밴 처리할 수 없습니다.'
                }, status=status.HTTP_400_BAD_REQUEST)

            if user.is_banned:
                return Response({
                    'success': False,
                    'message': '이미 밴 처리된 계정입니다.'
                }, status=status.HTTP_400_BAD_REQUEST)

            reason = request.data.get('reason', '')

            # Ban the account
            user.ban_account(reason, request.user)

            return Response({
                'success': True,
                'message': f'{user.username} 계정이 영구 밴 처리되었습니다.',
                'data': {
                    'username': user.username,
                    'banned_at': user.banned_at.isoformat() if user.banned_at else None,
                    'reason': user.ban_reason,
                    'banned_by': request.user.username,
                }
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'message': f'오류가 발생했습니다: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class UnbanUserAPIView(APIView):
    """Admin-only API to remove user ban"""
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, username):
        try:
            user = get_object_or_404(User, username=username)

            if not user.is_banned:
                return Response({
                    'success': False,
                    'message': '밴 처리되지 않은 계정입니다.'
                }, status=status.HTTP_400_BAD_REQUEST)

            # Unban the account
            user.unban_account()

            return Response({
                'success': True,
                'message': f'{user.username} 계정의 밴이 해제되었습니다.',
                'data': {
                    'username': user.username,
                }
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'message': f'오류가 발생했습니다: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==================== Password Reset Views ====================

def password_reset_request_view(request):
    """
    Render password reset request form page.
    """
    return render(request, 'accounts/password_reset/request.html')


class PasswordResetRequestAPIView(APIView):
    """
    API endpoint to process password reset requests.

    POST /api/accounts/password-reset/
    Body: { "email": "user@example.com" }

    Features:
    - Rate limiting: Max 3 attempts per email per hour
    - Generates temporary password
    - Sends email with temp password
    - Returns success/error response
    """
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()

        # Validate email format
        if not email:
            return Response({
                'success': False,
                'message': _('이메일 주소를 입력해주세요.')
            }, status=status.HTTP_400_BAD_REQUEST)

        # Check rate limit
        from accounts.utils import check_rate_limit, record_password_reset_attempt, generate_temporary_password, send_password_reset_email

        allowed, attempts_count, time_remaining = check_rate_limit(email)

        if not allowed:
            return Response({
                'success': False,
                'message': _('너무 많은 요청이 있었습니다. {}후에 다시 시도해주세요.').format(time_remaining)
            }, status=status.HTTP_429_TOO_MANY_REQUESTS)

        # Check if user exists
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            # Don't reveal if email exists (security best practice)
            # Still record attempt for rate limiting
            ip_address = self.get_client_ip(request)
            record_password_reset_attempt(email, ip_address)

            return Response({
                'success': True,
                'message': _('등록된 이메일 주소라면 임시 비밀번호가 발송되었습니다.')
            }, status=status.HTTP_200_OK)

        # Check if user account is active
        if not user.is_active:
            return Response({
                'success': False,
                'message': _('비활성화된 계정입니다. 관리자에게 문의하세요.')
            }, status=status.HTTP_403_FORBIDDEN)

        # Generate temporary password
        temp_password = generate_temporary_password()

        # Set new password (will be hashed automatically)
        user.set_password(temp_password)
        user.save(update_fields=['password'])

        # Send email
        email_sent = send_password_reset_email(user, temp_password)

        # Record attempt
        ip_address = self.get_client_ip(request)
        record_password_reset_attempt(email, ip_address)

        if email_sent:
            return Response({
                'success': True,
                'message': _('임시 비밀번호가 이메일로 발송되었습니다.')
            }, status=status.HTTP_200_OK)
        else:
            # Email sending failed - revert password change
            user.refresh_from_db()
            return Response({
                'success': False,
                'message': _('이메일 발송에 실패했습니다. 잠시 후 다시 시도해주세요.')
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def get_client_ip(self, request):
        """Get client IP address from request"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip


class ProfilePictureDeleteView(APIView):
    """
    API view for deleting user profile picture
    DELETE /api/accounts/profile-picture/
    """
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request):
        """Delete the current user's profile picture"""
        user = request.user

        # Delete the profile picture file if it exists
        if user.profile_picture:
            user.profile_picture.delete(save=False)

        # Set profile_picture field to None
        user.profile_picture = None
        user.save()

        return Response({
            'success': True,
            'message': _('프로필 사진이 삭제되었습니다.')
        }, status=status.HTTP_200_OK)


class UserReportCreateView(generics.CreateAPIView):
    """
    API view for creating user reports
    POST /api/accounts/users/report/
    """
    queryset = UserReport.objects.all()
    serializer_class = UserReportSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        """Set the reporter to the current user"""
        serializer.save(reporter=self.request.user)
