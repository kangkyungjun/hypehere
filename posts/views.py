from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.authentication import TokenAuthentication, SessionAuthentication
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.pagination import PageNumberPagination
from rest_framework.serializers import ValidationError
from django.shortcuts import get_object_or_404
from django.db.models import Count, Q
from .models import Post, Like, Comment, CommentLike, PostFavorite, PostReport, CommentReport, UserInteraction
from .serializers import (
    PostSerializer, PostCreateSerializer,
    CommentSerializer, CommentCreateSerializer,
    LikeSerializer, PostReportSerializer, CommentReportSerializer
)
from .services.recommendation import get_recommendations_for_user


class PostPagination(PageNumberPagination):
    """Pagination for post list and comments"""
    page_size = 5  # Show 5 comments per page for better UX with infinite scroll
    page_size_query_param = 'page_size'
    max_page_size = 50


class PostListCreateAPIView(generics.ListCreateAPIView):
    """
    GET /api/posts/ - List all posts with pagination
    POST /api/posts/ - Create a new post
    """
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = PostPagination

    def get_queryset(self):
        """Return posts with like and comment counts, excluding blocked users and deleted posts"""
        queryset = Post.objects.select_related('author', 'deleted_by').prefetch_related('hashtags').annotate(
            like_count=Count('likes', distinct=True),
            comment_count=Count('comments', distinct=True)
        ).exclude(author__is_deactivated=True)

        # Filter deleted posts based on user role
        if self.request.user.is_authenticated:
            if self.request.user.is_admin() or self.request.user.is_manager_or_above():
                # Admins/managers see all posts (including deleted ones)
                pass
            else:
                # Regular users: see non-deleted posts + their own deleted posts
                # 작성자는 자신의 삭제된 게시물을 리스트에서 보지만 내용은 삭제 메시지로 표시
                queryset = queryset.filter(
                    Q(is_deleted_by_report=False) | Q(author=self.request.user)
                )

            # 차단 관계 필터링
            from accounts.models import Block
            # 내가 차단한 사용자의 게시물 제외
            blocked_users = Block.objects.filter(blocker=self.request.user, is_active=True).values_list('blocked', flat=True)
            queryset = queryset.exclude(author__in=blocked_users)

            # 나를 차단한 사용자의 게시물 제외
            blocking_users = Block.objects.filter(blocked=self.request.user, is_active=True).values_list('blocker', flat=True)
            queryset = queryset.exclude(author__in=blocking_users)
        else:
            # Not authenticated: only show non-deleted posts
            queryset = queryset.filter(is_deleted_by_report=False)

        # Filter by ticker if provided (for MarketLens community)
        ticker = self.request.query_params.get('ticker')
        if ticker:
            queryset = queryset.filter(ticker__iexact=ticker)

        return queryset

    def get_serializer_class(self):
        """Use different serializers for read and write operations"""
        if self.request.method == 'POST':
            return PostCreateSerializer
        return PostSerializer

    def perform_create(self, serializer):
        """Set the author to the current user"""
        return serializer.save(author=self.request.user)

    def create(self, request, *args, **kwargs):
        """Override create to return full post data with author"""
        # Check if user is suspended
        if request.user.is_currently_suspended():
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('계정이 정지되어 게시글을 작성할 수 없습니다.')

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        post = self.perform_create(serializer)

        # Return full post data using PostSerializer with counts
        post = Post.objects.annotate(
            like_count=Count('likes', distinct=True),
            comment_count=Count('comments', distinct=True)
        ).get(pk=post.pk)

        output_serializer = PostSerializer(post, context={'request': request})
        headers = self.get_success_headers(output_serializer.data)
        return Response(
            output_serializer.data,
            status=status.HTTP_201_CREATED,
            headers=headers
        )


class PostDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/posts/<id>/ - Retrieve a single post
    PUT /api/posts/<id>/ - Update a post (author only)
    DELETE /api/posts/<id>/ - Delete a post (author only)
    """
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        """Return post with like and comment counts, with proper deletion filtering

        Note: Does not exclude deactivated authors to allow them to manage their own posts
        """
        queryset = Post.objects.select_related('author', 'deleted_by').prefetch_related('hashtags').annotate(
            like_count=Count('likes', distinct=True),
            comment_count=Count('comments', distinct=True)
        )

        # Filter deleted posts based on user role
        if self.request.user.is_authenticated:
            if self.request.user.is_admin() or self.request.user.is_manager_or_above():
                # Admins/managers see all posts
                pass
            else:
                # Regular users: see non-deleted posts + their own deleted posts
                queryset = queryset.filter(
                    Q(is_deleted_by_report=False) | Q(author=self.request.user)
                )
        else:
            # Not authenticated: only show non-deleted posts
            queryset = queryset.filter(is_deleted_by_report=False)

        return queryset

    def perform_update(self, serializer):
        """Allow author, admin, or manager to update"""
        if serializer.instance.author != self.request.user and not self.request.user.is_admin() and not self.request.user.is_manager_or_above():
            raise permissions.PermissionDenied("본인 게시물만 수정할 수 있습니다")
        serializer.save()

    def perform_destroy(self, instance):
        """Allow author, admin, or manager to delete. Admin/manager use soft deletion, authors use hard deletion."""
        if instance.author != self.request.user and not self.request.user.is_admin() and not self.request.user.is_manager_or_above():
            raise permissions.PermissionDenied("본인 게시물만 삭제할 수 있습니다")

        # Admin/manager deleting someone else's post - use soft deletion
        if (self.request.user.is_admin() or self.request.user.is_manager_or_above()) and instance.author != self.request.user:
            instance.delete_by_report(report_type='admin_delete', admin_user=self.request.user)
        else:
            # Author deleting their own post - hard delete
            instance.delete()


@api_view(['POST'])
@authentication_classes([TokenAuthentication, SessionAuthentication])
@permission_classes([permissions.IsAuthenticated])
def post_like_toggle(request, pk):
    """
    POST /api/posts/<id>/like/ - Toggle like on a post
    Returns: {'liked': bool, 'like_count': int}
    """
    post = get_object_or_404(Post, pk=pk)
    like, created = Like.objects.get_or_create(user=request.user, post=post)

    if not created:
        # Unlike
        like.delete()
        liked = False
    else:
        liked = True

    like_count = post.likes.count()

    return Response({
        'liked': liked,
        'like_count': like_count
    })


@api_view(['POST'])
@authentication_classes([TokenAuthentication, SessionAuthentication])
@permission_classes([permissions.IsAuthenticated])
def comment_like_toggle(request, post_id, comment_id):
    """
    POST /api/posts/<post_id>/comments/<comment_id>/like/ - Toggle like on a comment
    Returns: {'liked': bool, 'like_count': int}
    """
    comment = get_object_or_404(Comment, pk=comment_id, post_id=post_id)
    like, created = CommentLike.objects.get_or_create(user=request.user, comment=comment)

    if not created:
        like.delete()
        liked = False
    else:
        liked = True

    like_count = comment.comment_likes.count()

    return Response({
        'liked': liked,
        'like_count': like_count
    })


class PostCommentListCreateAPIView(generics.ListCreateAPIView):
    """
    GET /api/posts/<post_id>/comments/ - List all comments for a post
    POST /api/posts/<post_id>/comments/ - Create a new comment
    """
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = PostPagination

    def get_queryset(self):
        post_id = self.kwargs['post_id']
        post = get_object_or_404(Post, pk=post_id)

        # 신고로 삭제된 게시글의 댓글은 숨김
        if post.is_deleted_by_report:
            return Comment.objects.none()

        queryset = Comment.objects.filter(post_id=post_id).select_related('author').exclude(author__is_deactivated=True)

        # 차단 관계 필터링 (로그인한 경우)
        if self.request.user.is_authenticated:
            from accounts.models import Block
            # 내가 차단한 사용자의 댓글 제외
            blocked_users = Block.objects.filter(blocker=self.request.user, is_active=True).values_list('blocked', flat=True)
            queryset = queryset.exclude(author__in=blocked_users)

            # 나를 차단한 사용자의 댓글 제외
            blocking_users = Block.objects.filter(blocked=self.request.user, is_active=True).values_list('blocker', flat=True)
            queryset = queryset.exclude(author__in=blocking_users)

        return queryset.order_by('-created_at')

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return CommentCreateSerializer
        return CommentSerializer

    def perform_create(self, serializer):
        post_id = self.kwargs['post_id']
        post = get_object_or_404(Post, pk=post_id)

        # 삭제된 게시글에는 댓글 작성 불가
        if post.is_deleted_by_report:
            raise ValidationError('삭제된 게시글에는 댓글을 작성할 수 없습니다.')

        return serializer.save(author=self.request.user, post=post)

    def create(self, request, *args, **kwargs):
        # Check if user is suspended
        if request.user.is_currently_suspended():
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('계정이 정지되어 댓글을 작성할 수 없습니다.')

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        comment = self.perform_create(serializer)

        output_serializer = CommentSerializer(comment)
        headers = self.get_success_headers(output_serializer.data)
        return Response(
            output_serializer.data,
            status=status.HTTP_201_CREATED,
            headers=headers
        )


class CommentDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET /api/posts/<post_id>/comments/<id>/ - Get a comment
    PUT /api/posts/<post_id>/comments/<id>/ - Update a comment
    DELETE /api/posts/<post_id>/comments/<id>/ - Delete a comment
    """
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        post_id = self.kwargs['post_id']
        return Comment.objects.filter(post_id=post_id).select_related('author')

    def perform_update(self, serializer):
        # Allow author, admin, or manager to update
        if serializer.instance.author != self.request.user and not self.request.user.is_admin() and not self.request.user.is_manager_or_above():
            raise permissions.PermissionDenied("You can only edit your own comments")
        serializer.save()

    def perform_destroy(self, instance):
        # Allow author, admin, or manager to delete
        if instance.author != self.request.user and not self.request.user.is_admin() and not self.request.user.is_manager_or_above():
            raise permissions.PermissionDenied("You can only delete your own comments")
        instance.delete()


class PostSearchAPIView(generics.ListAPIView):
    """
    GET /api/posts/search/?q=<query> - Search posts by content or hashtags
    """
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = PostPagination

    def get_queryset(self):
        """Search posts by query parameter, excluding blocked users"""
        query = self.request.query_params.get('q', '').strip()

        if not query:
            # Return empty queryset if no query
            return Post.objects.none()

        # Search in post title, content, and hashtag names
        queryset = Post.objects.select_related('author').prefetch_related('hashtags').annotate(
            like_count=Count('likes', distinct=True),
            comment_count=Count('comments', distinct=True)
        ).filter(
            Q(title__icontains=query) | Q(content__icontains=query) | Q(hashtags__name__icontains=query)
        ).exclude(author__is_deactivated=True).distinct()

        # Filter by ticker if provided
        ticker = self.request.query_params.get('ticker')
        if ticker:
            queryset = queryset.filter(ticker__iexact=ticker)

        # 차단 관계 필터링 (로그인한 경우)
        if self.request.user.is_authenticated:
            from accounts.models import Block
            # 내가 차단한 사용자의 게시물 제외
            blocked_users = Block.objects.filter(blocker=self.request.user, is_active=True).values_list('blocked', flat=True)
            queryset = queryset.exclude(author__in=blocked_users)

            # 나를 차단한 사용자의 게시물 제외
            blocking_users = Block.objects.filter(blocked=self.request.user, is_active=True).values_list('blocker', flat=True)
            queryset = queryset.exclude(author__in=blocking_users)

        return queryset.order_by('-created_at')


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def post_favorite_toggle(request, pk):
    """
    POST /api/posts/<id>/favorite/ - Toggle favorite on a post
    Returns: {'favorited': bool}
    """
    post = get_object_or_404(Post, pk=pk)
    favorite, created = PostFavorite.objects.get_or_create(user=request.user, post=post)

    if not created:
        # Unfavorite
        favorite.delete()
        favorited = False
    else:
        favorited = True

    return Response({
        'favorited': favorited
    })


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def post_report_view(request, pk):
    """
    POST /api/posts/<id>/report/ - Report a post
    Returns: Report data with 201 status
    """
    post = get_object_or_404(Post, pk=pk)

    # Create a mutable copy of request data
    data = request.data.copy()

    # Auto-set reporter and reported_user
    data['reporter'] = request.user.id
    data['reported_user'] = post.author.id
    data['post'] = post.id

    serializer = PostReportSerializer(data=data)

    if serializer.is_valid():
        serializer.save(reporter=request.user, reported_user=post.author)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def comment_report_view(request, post_id, comment_id):
    """
    POST /api/posts/<post_id>/comments/<comment_id>/report/ - Report a comment
    Returns: Report data with 201 status
    """
    comment = get_object_or_404(Comment, pk=comment_id, post_id=post_id)

    # Prevent self-reporting
    if comment.author == request.user:
        return Response(
            {'error': '자신의 댓글은 신고할 수 없습니다.'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Create a mutable copy of request data
    data = request.data.copy()

    # Auto-set reporter, reported_user, and comment
    data['reporter'] = request.user.id
    data['reported_user'] = comment.author.id
    data['comment'] = comment.id

    serializer = CommentReportSerializer(data=data)

    if serializer.is_valid():
        serializer.save(reporter=request.user, reported_user=comment.author)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def log_interaction(request):
    """
    POST /api/posts/log-interaction/
    Log user interaction with a post

    Request body:
    {
        "post_id": 123,
        "interaction_type": "click",  // view, click, like, unlike, comment, share, favorite, skip, report
        "scroll_depth": 50,  // Optional: 0-100
        "dwell_time": 3.5,   // Optional: seconds
        "metadata": {        // Optional: additional context
            "device": "mobile",
            "feed_position": 5,
            "source_feed": "home"
        }
    }

    Returns:
    {
        "success": true,
        "interaction_id": 456
    }
    """
    post_id = request.data.get('post_id')
    interaction_type = request.data.get('interaction_type')
    scroll_depth = request.data.get('scroll_depth', 0)
    dwell_time = request.data.get('dwell_time', 0.0)
    metadata = request.data.get('metadata', {})

    # Validate required fields
    if not post_id or not interaction_type:
        return Response(
            {'error': 'post_id and interaction_type are required'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Validate interaction_type
    valid_types = ['view', 'click', 'like', 'unlike', 'comment', 'share', 'favorite', 'skip', 'report']
    if interaction_type not in valid_types:
        return Response(
            {'error': f'Invalid interaction_type. Must be one of: {", ".join(valid_types)}'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Get post
    try:
        post = Post.objects.get(id=post_id)
    except Post.DoesNotExist:
        return Response(
            {'error': 'Post not found'},
            status=status.HTTP_404_NOT_FOUND
        )

    # Create interaction
    try:
        interaction = UserInteraction.log_interaction(
            user=request.user,
            post=post,
            interaction_type=interaction_type,
            scroll_depth=int(scroll_depth),
            dwell_time=float(dwell_time),
            metadata=metadata
        )

        return Response({
            'success': True,
            'interaction_id': interaction.id
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response(
            {'error': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


class RecommendedPostListAPIView(generics.ListAPIView):
    """
    GET /api/posts/recommended/ - Get personalized recommended posts

    Uses ML-based recommendation engine with multi-factor scoring:
    - Relationship score (follow/mutual connections)
    - Engagement metrics (likes, comments)
    - Interest alignment (hashtags, language)
    - Freshness (post recency)
    - Penalties (reports, skips, duplicates)

    Query parameters:
    - page: Page number (default: 1)
    - page_size: Posts per page (default: 20, max: 50)
    """
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = PostPagination

    def get_queryset(self):
        """Get recommended posts using recommendation engine"""
        # Get page and page_size from query params
        page = int(self.request.query_params.get('page', 1))
        page_size = min(int(self.request.query_params.get('page_size', 20)), 50)

        # Get recommendations from engine
        recommended_posts = get_recommendations_for_user(
            user=self.request.user,
            page=page,
            page_size=page_size
        )

        # Convert list to QuerySet for proper serialization
        # Note: The recommendation engine returns a list of Post objects
        # We need to preserve the order, so we can't use .filter(id__in=...)
        # Instead, return the list as-is and handle pagination manually
        return recommended_posts

    def list(self, request, *args, **kwargs):
        """Override list to handle non-QuerySet results"""
        posts = self.get_queryset()

        # Manually serialize posts (already paginated by recommendation engine)
        serializer = self.get_serializer(posts, many=True)

        # Return response with metadata
        return Response({
            'count': len(posts),
            'results': serializer.data
        })


class MyPostsAPIView(generics.ListAPIView):
    """
    GET /api/community/posts/my/ - List current user's posts

    MarketLens용: 내가 작성한 게시글 목록 조회
    """
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = PostSerializer
    pagination_class = PostPagination

    def get_queryset(self):
        """Return current user's posts with counts"""
        return Post.objects.filter(
            author=self.request.user
        ).select_related('author', 'deleted_by').prefetch_related('hashtags').annotate(
            like_count=Count('likes', distinct=True),
            comment_count=Count('comments', distinct=True)
        ).order_by('-created_at')


class MyCommentsAPIView(generics.ListAPIView):
    """
    GET /api/community/comments/my/ - List current user's comments

    MarketLens용: 내가 작성한 댓글 목록 조회
    """
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = CommentSerializer
    pagination_class = PostPagination

    def get_queryset(self):
        """Return current user's comments"""
        return Comment.objects.filter(
            author=self.request.user
        ).select_related('author', 'post', 'post__author').order_by('-created_at')
