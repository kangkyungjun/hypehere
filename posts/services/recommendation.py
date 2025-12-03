"""
HypeHere - SNS Feed Recommendation System
=========================================

4-Stage Recommendation Pipeline:
1. Candidate Extraction - Filter posts based on basic criteria
2. Scoring - Calculate multi-factor scores for each post
3. Sorting & Mixing - Sort by score and apply diversity mixing
4. Country/Language Control - Apply diversity constraints

Scoring Factors (Total: 100 points):
- Relationship Score (0-40): Follow relationships
- Engagement Score (0-30): Likes and comments
- Interest Score (0-20): Hashtag/language alignment
- Freshness Score (0-10): Recency bonus
- Penalty (-10~0): Reports, skips, duplicates
"""

from django.db.models import Q, Count, Prefetch, F, Case, When, IntegerField
from django.utils import timezone
from django.core.cache import cache
from datetime import timedelta
from collections import defaultdict
import random

from posts.models import Post, UserInteraction
from accounts.models import Follow, Block


class RecommendationEngine:
    """
    Main recommendation engine for personalized post feed
    """

    def __init__(self, user, page_size=20):
        """
        Initialize recommendation engine

        Args:
            user: Current user requesting recommendations
            page_size: Number of posts per page
        """
        self.user = user
        self.page_size = page_size
        self.cache_timeout = 60 * 60 * 24  # 24 hours

    def get_recommended_posts(self, page=1, use_cache=True):
        """
        Get recommended posts for user

        Returns:
            QuerySet of recommended Post objects
        """
        # Check cache first
        cache_key = f'recommend:user:{self.user.id}:page:{page}'
        if use_cache:
            cached_posts = cache.get(cache_key)
            if cached_posts is not None:
                return cached_posts

        # 1. Extract candidates
        candidates = self._extract_candidates()

        # 2. Score each post
        scored_posts = self._score_posts(candidates)

        # 3. Sort and mix
        sorted_posts = self._sort_and_mix(scored_posts)

        # 4. Apply country/language diversity
        final_posts = self._apply_diversity_control(sorted_posts)

        # Pagination
        start_idx = (page - 1) * self.page_size
        end_idx = start_idx + self.page_size
        result = final_posts[start_idx:end_idx]

        # Cache result
        if use_cache:
            cache.set(cache_key, result, self.cache_timeout)

        return result

    def _extract_candidates(self):
        """
        Stage 1: Extract candidate posts

        Filters:
        - Not deleted by report
        - Not from blocked/blocking users
        - Created within last 30 days
        - Not already seen (optional optimization)
        """
        # Get blocked user IDs
        blocked_ids = set(Block.objects.filter(
            Q(blocker=self.user) | Q(blocked=self.user),
            is_active=True
        ).values_list('blocked_id', 'blocker_id', flat=False))

        blocked_user_ids = set()
        for blocker_id, blocked_id in blocked_ids:
            blocked_user_ids.add(blocker_id)
            blocked_user_ids.add(blocked_id)

        # Build candidate queryset
        thirty_days_ago = timezone.now() - timedelta(days=30)

        candidates = Post.objects.filter(
            is_deleted_by_report=False,
            created_at__gte=thirty_days_ago
        ).exclude(
            author_id__in=blocked_user_ids
        ).exclude(
            author_id=self.user.id  # Exclude own posts
        ).select_related(
            'author'
        ).prefetch_related(
            'hashtags',
            'likes',
            'comments'
        )

        return candidates

    def _score_posts(self, candidates):
        """
        Stage 2: Calculate score for each post

        Returns:
            List of tuples: [(post, score), ...]
        """
        # Get user's follow relationships
        following_ids = set(Follow.objects.filter(
            follower=self.user
        ).values_list('following_id', flat=True))

        # Get mutual follow (맞팔로우)
        followers_ids = set(Follow.objects.filter(
            following=self.user
        ).values_list('follower_id', flat=True))

        mutual_follow_ids = following_ids & followers_ids

        # Get user's past interactions
        user_interactions = defaultdict(list)
        interactions = UserInteraction.objects.filter(
            user=self.user
        ).values('post_id', 'interaction_type')

        for interaction in interactions:
            user_interactions[interaction['post_id']].append(interaction['interaction_type'])

        # Get user's hashtag preferences
        user_hashtags = set()
        if hasattr(self.user, 'native_language'):
            user_lang = self.user.native_language
        else:
            user_lang = None

        scored_posts = []

        for post in candidates:
            score = 0

            # 1. Relationship Score (0-40)
            if post.author_id in mutual_follow_ids:
                score += 40  # 맞팔로우
            elif post.author_id in following_ids:
                score += 30  # 팔로잉
            elif post.author_id in followers_ids:
                score += 20  # 팔로워
            else:
                score += 10  # 낯선 사람

            # 2. Engagement Score (0-30)
            like_count = post.likes.count()
            comment_count = post.comments.count()
            score += min(like_count, 10) * 1  # Max +10 from likes
            score += min(comment_count, 10) * 2  # Max +20 from comments

            # 3. Interest Score (0-20)
            # Hashtag matching
            post_hashtags = set(post.hashtags.values_list('name', flat=True))
            hashtag_match = len(user_hashtags & post_hashtags)
            score += min(hashtag_match * 5, 15)  # Max +15 from hashtags

            # Language preference
            if user_lang and post.native_language == user_lang:
                score += 5

            # 4. Freshness Score (0-10)
            hours_ago = (timezone.now() - post.created_at).total_seconds() / 3600
            if hours_ago < 24:
                score += 10
            elif hours_ago < 72:
                score += 7
            elif hours_ago < 168:  # 1 week
                score += 5
            elif hours_ago < 720:  # 30 days
                score += 1

            # 5. Penalty (-10~0)
            post_interactions = user_interactions.get(post.id, [])
            if 'report' in post_interactions:
                score -= 50  # Heavy penalty for reports
            if 'skip' in post_interactions:
                score -= 15  # Penalty for skips

            # Duplicate exposure penalty
            if 'view' in post_interactions:
                view_count = post_interactions.count('view')
                score -= min(view_count * 5, 20)  # Max -20 for multiple views

            scored_posts.append((post, score))

        return scored_posts

    def _sort_and_mix(self, scored_posts):
        """
        Stage 3: Sort by score and apply diversity mixing

        - Sort by score descending
        - Apply 20% random shuffle for exploration
        """
        # Sort by score
        scored_posts.sort(key=lambda x: x[1], reverse=True)

        # Take top 100 posts
        top_posts = scored_posts[:100]

        # Extract just the posts
        posts = [post for post, score in top_posts]

        # Apply 20% random shuffle for exploration
        shuffle_count = int(len(posts) * 0.2)
        if shuffle_count > 0:
            shuffle_indices = random.sample(range(len(posts)), shuffle_count)
            shuffled_posts = [posts[i] for i in shuffle_indices]
            random.shuffle(shuffled_posts)

            for i, idx in enumerate(shuffle_indices):
                posts[idx] = shuffled_posts[i]

        return posts

    def _apply_diversity_control(self, posts):
        """
        Stage 4: Apply country/language diversity constraints

        Rules:
        - Single country max 40% exposure
        - Language diversity enforcement
        """
        if not posts:
            return posts

        # Count posts by author country
        country_counts = defaultdict(int)
        total_posts = len(posts)
        max_per_country = int(total_posts * 0.4)  # 40% cap

        # Filter posts while maintaining diversity
        diverse_posts = []
        remaining_posts = []

        for post in posts:
            author_country = getattr(post.author, 'country', None)

            if not author_country:
                diverse_posts.append(post)
                continue

            if country_counts[author_country] < max_per_country:
                diverse_posts.append(post)
                country_counts[author_country] += 1
            else:
                remaining_posts.append(post)

        # Fill remaining slots with overflow posts
        diverse_posts.extend(remaining_posts)

        return diverse_posts

    def invalidate_cache(self):
        """
        Invalidate recommendation cache for this user
        Call this when user follows/unfollows someone or creates new post
        """
        # Delete all cached pages for this user
        for page in range(1, 11):  # Assume max 10 pages cached
            cache_key = f'recommend:user:{self.user.id}:page:{page}'
            cache.delete(cache_key)


def get_recommendations_for_user(user, page=1, page_size=20):
    """
    Helper function to get recommendations for a user

    Args:
        user: User object
        page: Page number (1-indexed)
        page_size: Posts per page

    Returns:
        QuerySet of recommended posts
    """
    engine = RecommendationEngine(user, page_size=page_size)
    return engine.get_recommended_posts(page=page)


def invalidate_user_recommendations(user):
    """
    Helper function to invalidate user's recommendation cache

    Args:
        user: User object
    """
    engine = RecommendationEngine(user)
    engine.invalidate_cache()
