from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.pagination import PageNumberPagination
from rest_framework.serializers import ValidationError
from django.shortcuts import get_object_or_404
from django.db.models import Count, Q
from .models import Post, Like, Comment, PostFavorite, PostReport, CommentReport
from .serializers import (
    PostSerializer, PostCreateSerializer,
    CommentSerializer, CommentCreateSerializer,
    LikeSerializer, PostReportSerializer, CommentReportSerializer
)


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
        """Return posts with like and comment counts"""
        return Post.objects.select_related('author').prefetch_related('hashtags').annotate(
            like_count=Count('likes', distinct=True),
            comment_count=Count('comments', distinct=True)
        ).exclude(author__is_deactivated=True)

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
        """Return post with like and comment counts

        Note: Does not exclude deactivated authors to allow them to manage their own posts
        """
        return Post.objects.select_related('author').prefetch_related('hashtags').annotate(
            like_count=Count('likes', distinct=True),
            comment_count=Count('comments', distinct=True)
        )

    def perform_update(self, serializer):
        """Only allow author to update"""
        if serializer.instance.author != self.request.user:
            raise permissions.PermissionDenied("본인 게시물만 수정할 수 있습니다")
        serializer.save()

    def perform_destroy(self, instance):
        """Only allow author to delete"""
        if instance.author != self.request.user:
            raise permissions.PermissionDenied("본인 게시물만 삭제할 수 있습니다")
        instance.delete()


@api_view(['POST'])
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

        return Comment.objects.filter(post_id=post_id).select_related('author').exclude(author__is_deactivated=True).order_by('-created_at')

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
        # Only allow author to update
        if serializer.instance.author != self.request.user:
            raise permissions.PermissionDenied("You can only edit your own comments")
        serializer.save()

    def perform_destroy(self, instance):
        # Only allow author to delete
        if instance.author != self.request.user:
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
        """Search posts by query parameter"""
        query = self.request.query_params.get('q', '').strip()

        if not query:
            # Return empty queryset if no query
            return Post.objects.none()

        # Search in post content and hashtag names
        queryset = Post.objects.select_related('author').prefetch_related('hashtags').annotate(
            like_count=Count('likes', distinct=True),
            comment_count=Count('comments', distinct=True)
        ).filter(
            Q(content__icontains=query) | Q(hashtags__name__icontains=query)
        ).exclude(author__is_deactivated=True).distinct().order_by('-created_at')

        return queryset


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
