from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from community.models import Post, Comment, PostLike, CommentLike
import random

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed community data with test users, posts, comments, and likes for TSLA, AAPL, NVDA'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing community data before seeding',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write(self.style.WARNING('Clearing existing community data...'))
            Post.objects.all().delete()
            Comment.objects.all().delete()
            PostLike.objects.all().delete()
            CommentLike.objects.all().delete()
            self.stdout.write(self.style.SUCCESS('✓ Cleared existing data'))

        # Create test users
        users = self.create_users()

        # Create posts for each ticker
        posts = self.create_posts(users)

        # Create comments
        comments = self.create_comments(users, posts)

        # Create likes
        self.create_likes(users, posts, comments)

        self.stdout.write(self.style.SUCCESS('\n✓ Seeding complete!'))
        self.stdout.write(f'  Created {len(users)} users')
        self.stdout.write(f'  Created {len(posts)} posts')
        self.stdout.write(f'  Created {len(comments)} comments')

    def create_users(self):
        """Create test users"""
        self.stdout.write('Creating test users...')

        users_data = [
            {'email': 'investor1@test.com', 'nickname': '단타왕'},
            {'email': 'investor2@test.com', 'nickname': '장투러'},
            {'email': 'investor3@test.com', 'nickname': '테슬라믿음러'},
            {'email': 'investor4@test.com', 'nickname': '애플빠'},
            {'email': 'investor5@test.com', 'nickname': 'AI투자자'},
        ]

        users = []
        for data in users_data:
            user, created = User.objects.get_or_create(
                email=data['email'],
                defaults={
                    'nickname': data['nickname'],
                }
            )
            if created:
                user.set_password('testpass123')
                user.save()
            users.append(user)

        self.stdout.write(self.style.SUCCESS(f'  ✓ Created {len(users)} users'))
        return users

    def create_posts(self, users):
        """Create posts for TSLA, AAPL, NVDA"""
        self.stdout.write('Creating posts...')

        posts_data = [
            # TSLA posts
            {
                'ticker': 'TSLA',
                'title': '테슬라 Q4 실적 예상보다 좋네요',
                'content': '이번 분기 실적이 예상치를 상회했습니다. 자율주행 업데이트도 예정되어 있고, 중국 시장에서도 회복세가 보이네요. 장기 보유 관점에서 좋은 진입 구간 같습니다.',
                'author': users[2],  # 테슬라믿음러
            },
            {
                'ticker': 'TSLA',
                'title': 'FSD 베타 업데이트 후 주가 반응',
                'content': 'Full Self-Driving 베타 최신 버전이 출시되면서 긍정적인 반응이 많습니다. 규제 승인만 통과하면 큰 폭의 상승이 예상됩니다.',
                'author': users[0],  # 단타왕
            },
            {
                'ticker': 'TSLA',
                'title': '테슬라 새로운 모델 출시 루머',
                'content': '저가형 전기차 모델이 내년에 출시될 것이라는 소식이 있는데, 사실이라면 시장 점유율이 크게 늘어날 것 같습니다.',
                'author': users[1],  # 장투러
            },
            # AAPL posts
            {
                'ticker': 'AAPL',
                'title': 'iPhone 16 사전 예약 폭발적 반응',
                'content': 'iPhone 16 시리즈 사전 예약이 역대 최고치를 기록했다고 합니다. AI 기능이 강화되면서 업그레이드 수요가 많은 것 같아요. 이번 분기 실적도 기대됩니다.',
                'author': users[3],  # 애플빠
            },
            {
                'ticker': 'AAPL',
                'title': 'Apple Vision Pro 2세대 출시 예정',
                'content': 'Vision Pro 2세대가 더 저렴한 가격에 출시될 예정이라고 하네요. 가격이 내려가면 대중화가 가능할까요?',
                'author': users[4],  # AI투자자
            },
            {
                'ticker': 'AAPL',
                'title': '애플 배당 증가 발표',
                'content': '분기 배당이 10% 증가했습니다. 장기 투자자들에게 좋은 소식이네요. 현금 흐름도 안정적이고 꾸준한 수익을 기대할 수 있을 것 같습니다.',
                'author': users[1],  # 장투러
            },
            # NVDA posts
            {
                'ticker': 'NVDA',
                'title': 'NVIDIA H100 수요 폭발',
                'content': '데이터센터향 H100 GPU 수요가 공급을 초과하고 있다고 합니다. AI 붐이 계속되는 한 엔비디아의 성장은 지속될 것 같습니다.',
                'author': users[4],  # AI투자자
            },
            {
                'ticker': 'NVDA',
                'title': 'Blackwell 아키텍처 발표',
                'content': '차세대 Blackwell GPU가 발표되었습니다. 성능이 H100 대비 2.5배 향상되었다고 하는데, 이거 진짜면 대박이겠네요.',
                'author': users[0],  # 단타왕
            },
            {
                'ticker': 'NVDA',
                'title': '엔비디아 주가 조정 후 매수 타이밍?',
                'content': '최근 조정을 받았는데, 이 구간이 좋은 매수 기회일까요? AI 트렌드는 계속될 것 같은데 단기 조정은 매수 기회로 봐야 할 것 같습니다.',
                'author': users[1],  # 장투러
            },
        ]

        posts = []
        for data in posts_data:
            post = Post.objects.create(**data)
            posts.append(post)

        self.stdout.write(self.style.SUCCESS(f'  ✓ Created {len(posts)} posts'))
        return posts

    def create_comments(self, users, posts):
        """Create comments on posts"""
        self.stdout.write('Creating comments...')

        comments_templates = [
            '동의합니다. 좋은 분석이네요!',
            '저도 비슷하게 생각하고 있었습니다.',
            '흥미로운 관점이네요. 감사합니다.',
            '이 부분은 좀 더 지켜봐야 할 것 같아요.',
            '좋은 정보 공유 감사합니다!',
            '저는 반대 의견입니다만, 존중합니다.',
            '장기적으로 보면 맞는 것 같아요.',
            '단기적으로는 조정이 있을 수 있겠네요.',
        ]

        comments = []
        for post in posts:
            # Each post gets 2-4 comments
            num_comments = random.randint(2, 4)
            comment_users = random.sample(users, num_comments)

            for user in comment_users:
                content = random.choice(comments_templates)
                comment = Comment.objects.create(
                    post=post,
                    author=user,
                    content=content
                )
                comments.append(comment)

                # Update post's comment_count
                post.comment_count = Comment.objects.filter(post=post, is_deleted=False, parent=None).count()
                post.save(update_fields=['comment_count'])

        self.stdout.write(self.style.SUCCESS(f'  ✓ Created {len(comments)} comments'))
        return comments

    def create_likes(self, users, posts, comments):
        """Create likes on posts and comments"""
        self.stdout.write('Creating likes...')

        post_like_count = 0
        comment_like_count = 0

        # Create post likes
        for post in posts:
            # Each post gets likes from 1-3 users
            num_likes = random.randint(1, 3)
            liking_users = random.sample(users, num_likes)

            for user in liking_users:
                PostLike.objects.get_or_create(post=post, user=user)

            # Update post's like_count
            post.like_count = PostLike.objects.filter(post=post).count()
            post.save(update_fields=['like_count'])
            post_like_count += num_likes

        # Create comment likes
        for comment in comments:
            # Each comment gets likes from 0-2 users
            num_likes = random.randint(0, 2)
            if num_likes > 0:
                liking_users = random.sample(users, num_likes)

                for user in liking_users:
                    CommentLike.objects.get_or_create(comment=comment, user=user)

                # Update comment's like_count
                comment.like_count = CommentLike.objects.filter(comment=comment).count()
                comment.save(update_fields=['like_count'])
                comment_like_count += num_likes

        self.stdout.write(self.style.SUCCESS(f'  ✓ Created {post_like_count} post likes and {comment_like_count} comment likes'))
