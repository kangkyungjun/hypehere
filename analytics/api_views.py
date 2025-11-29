from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAdminUser, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Count, Avg, Sum, Q, Max
from django.utils import timezone
from datetime import timedelta, datetime
from accounts.models import User
from posts.models import Post
from chat.models import Conversation
from .models import DailyVisitor, UserActivityLog, AnonymousChatUsageStats, DailySummary
from lotto.models import NumberCombination, UserLottoNumber, LottoDraw
import hashlib
from itertools import combinations
import random


@api_view(['GET'])
@permission_classes([IsAdminUser])
def dashboard_stats_api(request):
    """
    Get all dashboard statistics
    GET /admin-dashboard/api/stats/

    Returns comprehensive dashboard statistics for admin panel
    """
    today = timezone.now().date()
    yesterday = today - timedelta(days=1)
    week_ago = today - timedelta(days=7)
    month_ago = today - timedelta(days=30)

    # Visitor stats
    visitors_today = DailyVisitor.objects.filter(date=today).count()
    visitors_yesterday = DailyVisitor.objects.filter(date=yesterday).count()
    visitors_week = DailyVisitor.objects.filter(date__gte=week_ago).values('ip_address', 'user').distinct().count()
    visitors_month = DailyVisitor.objects.filter(date__gte=month_ago).values('ip_address', 'user').distinct().count()

    # New users stats
    new_users_today = User.objects.filter(created_at__date=today).count()
    new_users_yesterday = User.objects.filter(created_at__date=yesterday).count()
    new_users_week = User.objects.filter(created_at__date__gte=week_ago).count()
    new_users_month = User.objects.filter(created_at__date__gte=month_ago).count()
    total_users = User.objects.count()

    # Active users stats (users who have activity logs for those days)
    active_today = UserActivityLog.objects.filter(date=today).count()
    active_yesterday = UserActivityLog.objects.filter(date=yesterday).count()

    # 7-day average active users
    last_7_days = [today - timedelta(days=i) for i in range(7)]
    active_counts = []
    for day in last_7_days:
        count = UserActivityLog.objects.filter(date=day).count()
        active_counts.append(count)
    active_week_avg = sum(active_counts) / len(active_counts) if active_counts else 0

    # Post stats
    posts_today = Post.objects.filter(created_at__date=today).count()
    posts_yesterday = Post.objects.filter(created_at__date=yesterday).count()
    posts_week = Post.objects.filter(created_at__date__gte=week_ago).count()
    posts_month = Post.objects.filter(created_at__date__gte=month_ago).count()
    total_posts = Post.objects.count()

    # Anonymous chat stats
    anon_users_today = AnonymousChatUsageStats.objects.filter(date=today).count()
    anon_users_week = AnonymousChatUsageStats.objects.filter(
        date__gte=week_ago
    ).values('user').distinct().count()
    anon_users_month = AnonymousChatUsageStats.objects.filter(
        date__gte=month_ago
    ).values('user').distinct().count()
    anon_users_total = AnonymousChatUsageStats.objects.values('user').distinct().count()

    # Average conversations per user
    avg_daily = 0
    daily_stats = AnonymousChatUsageStats.objects.filter(date=today)
    if daily_stats.exists():
        avg_daily = daily_stats.aggregate(avg=Avg('conversations_started'))['avg'] or 0

    avg_weekly = 0
    weekly_stats = AnonymousChatUsageStats.objects.filter(date__gte=week_ago)
    if weekly_stats.exists():
        avg_weekly = weekly_stats.aggregate(avg=Avg('conversations_started'))['avg'] or 0

    avg_monthly = 0
    monthly_stats = AnonymousChatUsageStats.objects.filter(date__gte=month_ago)
    if monthly_stats.exists():
        avg_monthly = monthly_stats.aggregate(avg=Avg('conversations_started'))['avg'] or 0

    return Response({
        'visitors': {
            'today': visitors_today,
            'yesterday': visitors_yesterday,
            'week': visitors_week,
            'month': visitors_month
        },
        'new_users': {
            'today': new_users_today,
            'yesterday': new_users_yesterday,
            'week': new_users_week,
            'month': new_users_month,
            'total': total_users
        },
        'active_users': {
            'today': active_today,
            'yesterday': active_yesterday,
            'week_average': round(active_week_avg, 1)
        },
        'posts': {
            'today': posts_today,
            'yesterday': posts_yesterday,
            'week': posts_week,
            'month': posts_month,
            'total': total_posts
        },
        'anonymous_chat': {
            'users': {
                'today': anon_users_today,
                'week': anon_users_week,
                'month': anon_users_month,
                'total': anon_users_total
            },
            'average_per_user': {
                'daily': round(avg_daily, 1),
                'weekly': round(avg_weekly, 1),
                'monthly': round(avg_monthly, 1)
            }
        }
    })


@api_view(['GET'])
@permission_classes([IsAdminUser])
def search_users_api(request):
    """
    Search users by email or nickname
    GET /admin-dashboard/api/users/search/?q=query

    Returns list of users matching search query
    """
    query = request.GET.get('q', '').strip()

    if not query:
        return Response({'results': []})

    # Search by email or nickname
    users = User.objects.filter(
        Q(email__icontains=query) | Q(nickname__icontains=query)
    ).values('id', 'email', 'nickname', 'is_staff', 'is_superuser')[:20]

    results = []
    for user in users:
        role = 'Superuser' if user['is_superuser'] else ('Staff' if user['is_staff'] else 'User')
        results.append({
            'id': user['id'],
            'email': user['email'],
            'nickname': user['nickname'],
            'role': role
        })

    return Response({'results': results})


@api_view(['POST'])
@permission_classes([IsAdminUser])
def update_user_permissions_api(request, user_id):
    """
    Update user permissions (staff/superuser status)
    POST /admin-dashboard/api/users/<user_id>/permissions/

    Body: {"role": "user|staff|superuser"}

    Returns updated user information
    """
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

    role = request.data.get('role')

    if role == 'user':
        user.is_staff = False
        user.is_superuser = False
    elif role == 'staff':
        user.is_staff = True
        user.is_superuser = False
    elif role == 'superuser':
        user.is_staff = True
        user.is_superuser = True
    else:
        return Response({'error': 'Invalid role. Must be: user, staff, or superuser'},
                       status=status.HTTP_400_BAD_REQUEST)

    user.save(update_fields=['is_staff', 'is_superuser'])

    return Response({
        'success': True,
        'user': {
            'id': user.id,
            'email': user.email,
            'nickname': user.nickname,
            'role': 'Superuser' if user.is_superuser else ('Staff' if user.is_staff else 'User')
        }
    })


# Helper function for checking lotto numbers
def check_user_numbers(numbers):
    """Check if user numbers match historical winning numbers (1-4등)"""
    sorted_numbers = sorted(numbers)
    combination_hash = hashlib.sha256(str(sorted_numbers).encode()).hexdigest()

    match = NumberCombination.objects.filter(
        combination_hash=combination_hash
    ).first()

    if match:
        draw = LottoDraw.objects.filter(round_number=match.round_number).first()
        draw_date = draw.draw_date.strftime('%Y-%m-%d') if draw else None

        return {
            'is_winning': True,
            'round_number': match.round_number,
            'rank': match.rank,
            'draw_date': draw_date,
            'message': f'{match.round_number}회 {match.rank} 번호입니다',
            'numbers': sorted_numbers
        }
    else:
        return {
            'is_winning': False,
            'round_number': None,
            'rank': None,
            'draw_date': None,
            'message': '나온적 없는 번호입니다',
            'numbers': sorted_numbers
        }


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def check_lotto_number_api(request):
    """
    Check if numbers match historical winning numbers
    POST /admin-dashboard/lottery/check-number/
    Body: {"numbers": [1,2,3,4,5,6]}
    """
    numbers = request.data.get('numbers', [])

    # Input validation
    if not isinstance(numbers, list) or len(numbers) != 6:
        return Response({
            'success': False,
            'error': '6개의 번호를 입력해주세요'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Convert to integers and validate
    try:
        numbers = [int(n) for n in numbers]
    except (ValueError, TypeError):
        return Response({
            'success': False,
            'error': '올바른 숫자를 입력해주세요'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Range check (1-45)
    if any(n < 1 or n > 45 for n in numbers):
        return Response({
            'success': False,
            'error': '1~45 범위의 숫자를 입력해주세요'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Duplicate check
    if len(set(numbers)) != 6:
        return Response({
            'success': False,
            'error': '중복되지 않은 6개의 번호를 입력해주세요'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Check numbers
    result = check_user_numbers(numbers)

    return Response({
        'success': True,
        **result
    }, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_lotto_number_api(request):
    """
    Save user's lotto numbers
    POST /admin-dashboard/lottery/save-number/
    Body: {"numbers": [1,2,3,4,5,6], "round_number": 1150, "strategy": "basic"}
    """
    numbers = request.data.get('numbers', [])
    round_number = request.data.get('round_number', 0)  # Default to 0 if not provided
    strategy = request.data.get('strategy', 'basic')  # Default to basic

    # Input validation
    if not isinstance(numbers, list) or len(numbers) != 6:
        return Response({
            'success': False,
            'error': '6개의 번호를 입력해주세요'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Convert to integers
    try:
        numbers = sorted([int(n) for n in numbers])
        round_number = int(round_number) if round_number else 0
    except (ValueError, TypeError):
        return Response({
            'success': False,
            'error': '올바른 숫자를 입력해주세요'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Check if numbers are winning numbers
    check_result = check_user_numbers(numbers)

    # Create UserLottoNumber
    try:
        user_number = UserLottoNumber.objects.create(
            user=request.user,
            round_number=round_number,
            number1=numbers[0],
            number2=numbers[1],
            number3=numbers[2],
            number4=numbers[3],
            number5=numbers[4],
            number6=numbers[5],
            strategy_type=strategy,  # 추가
            is_checked=check_result['is_winning'],
            matched_rank=check_result['rank'] if check_result['is_winning'] else None
        )

        return Response({
            'success': True,
            'message': '번호가 저장되었습니다',
            'saved_id': user_number.id
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response({
            'success': False,
            'error': f'저장 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_lotto_numbers_api(request):
    """
    Get user's saved lotto numbers
    GET /admin-dashboard/lottery/my-numbers/
    """
    # Get user's saved numbers (최recent 20개)
    user_numbers = UserLottoNumber.objects.filter(
        user=request.user
    ).order_by('-created_at')[:20]

    numbers_list = []
    for un in user_numbers:
        numbers_list.append({
            'id': un.id,
            'numbers': un.get_numbers_as_list(),
            'round_number': un.round_number,
            'is_checked': un.is_checked,
            'matched_rank': un.matched_rank,
            'strategy_type': un.strategy_type,  # 추가
            'created_at': un.created_at.strftime('%Y-%m-%d %H:%M')
        })

    return Response({
        'success': True,
        'numbers': numbers_list
    }, status=status.HTTP_200_OK)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_lotto_number_api(request, number_id):
    """
    Delete user's saved lotto number
    DELETE /admin-dashboard/lottery/my-numbers/<number_id>/
    """
    try:
        user_number = UserLottoNumber.objects.get(id=number_id, user=request.user)
        user_number.delete()

        return Response({
            'success': True,
            'message': '번호가 삭제되었습니다'
        }, status=status.HTTP_200_OK)

    except UserLottoNumber.DoesNotExist:
        return Response({
            'success': False,
            'error': '번호를 찾을 수 없습니다'
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@permission_classes([IsAdminUser])
def get_latest_round_api(request):
    """
    Get the latest round number + 1
    GET /admin-dashboard/lottery/latest-round/
    """
    try:
        latest = LottoDraw.objects.aggregate(Max('round_number'))['round_number__max']
        next_round = (latest + 1) if latest else 1

        return Response({
            'success': True,
            'next_round': next_round
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            'success': False,
            'error': f'회차 조회 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAdminUser])
def save_draw_api(request):
    """
    Save new lotto draw and auto-generate 1-4등 combinations
    POST /admin-dashboard/lottery/save-draw/
    Body: {
        "draw_date": "2024-01-20",
        "numbers": [1,2,3,4,5,6],
        "bonus_number": 7,
        "first_prize_amount": 1000000000,
        "first_prize_winners": 5,
        "second_prize_amount": 50000000,
        "second_prize_winners": 20
    }
    """
    draw_date_str = request.data.get('draw_date')
    numbers = request.data.get('numbers', [])
    bonus_number = request.data.get('bonus_number')
    first_prize_amount = request.data.get('first_prize_amount')
    first_prize_winners = request.data.get('first_prize_winners')
    second_prize_amount = request.data.get('second_prize_amount')
    second_prize_winners = request.data.get('second_prize_winners')

    # Input validation
    if not draw_date_str:
        return Response({
            'success': False,
            'error': '추첨일을 입력해주세요'
        }, status=status.HTTP_400_BAD_REQUEST)

    if not isinstance(numbers, list) or len(numbers) != 6:
        return Response({
            'success': False,
            'error': '6개의 번호를 입력해주세요'
        }, status=status.HTTP_400_BAD_REQUEST)

    if not bonus_number:
        return Response({
            'success': False,
            'error': '보너스 번호를 입력해주세요'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Convert and validate
    try:
        draw_date = datetime.strptime(draw_date_str, '%Y-%m-%d').date()
        numbers = sorted([int(n) for n in numbers])
        bonus_number = int(bonus_number)

        # Range validation
        if any(n < 1 or n > 45 for n in numbers) or bonus_number < 1 or bonus_number > 45:
            return Response({
                'success': False,
                'error': '1~45 범위의 숫자를 입력해주세요'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Duplicate validation
        if len(set(numbers)) != 6:
            return Response({
                'success': False,
                'error': '중복되지 않은 6개의 번호를 입력해주세요'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Bonus number must not be in main numbers
        if bonus_number in numbers:
            return Response({
                'success': False,
                'error': '보너스 번호는 당첨 번호와 중복될 수 없습니다'
            }, status=status.HTTP_400_BAD_REQUEST)

    except (ValueError, TypeError) as e:
        return Response({
            'success': False,
            'error': f'올바른 형식으로 입력해주세요: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Get next round number
    latest = LottoDraw.objects.aggregate(Max('round_number'))['round_number__max']
    next_round = (latest + 1) if latest else 1

    try:
        # Create LottoDraw
        draw = LottoDraw.objects.create(
            round_number=next_round,
            draw_date=draw_date,
            number1=numbers[0],
            number2=numbers[1],
            number3=numbers[2],
            number4=numbers[3],
            number5=numbers[4],
            number6=numbers[5],
            bonus_number=bonus_number,
            first_prize_amount=first_prize_amount,
            first_prize_winners=first_prize_winners,
            second_prize_amount=second_prize_amount,
            second_prize_winners=second_prize_winners
        )

        # Auto-generate NumberCombination (1-4등)
        created_count = _generate_number_combinations(draw, numbers, bonus_number)

        # Update strategy statistics automatically
        update_all_strategy_statistics()

        return Response({
            'success': True,
            'message': f'{next_round}회차 당첨 번호가 저장되었습니다',
            'round_number': next_round,
            'combinations_created': created_count
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response({
            'success': False,
            'error': f'저장 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def _generate_number_combinations(draw, numbers, bonus_number):
    """
    Auto-generate 1-4등 NumberCombination records
    """
    created_count = 0
    round_number = draw.round_number

    # 1등: 6개 모두 일치
    combo_1st = sorted(numbers)
    combination_hash = hashlib.sha256(str(combo_1st).encode()).hexdigest()
    NumberCombination.objects.create(
        combination_hash=combination_hash,
        numbers=combo_1st,
        round_number=round_number,
        rank='1등'
    )
    created_count += 1

    # 2등: 5개 + 보너스 (6가지)
    for combo in combinations(numbers, 5):
        combo_with_bonus = sorted(list(combo) + [bonus_number])
        combination_hash = hashlib.sha256(str(combo_with_bonus).encode()).hexdigest()
        NumberCombination.objects.create(
            combination_hash=combination_hash,
            numbers=combo_with_bonus,
            round_number=round_number,
            rank='2등'
        )
        created_count += 1

    # 3등: 5개 일치 (6가지)
    for combo in combinations(numbers, 5):
        combo_sorted = sorted(list(combo))
        combination_hash = hashlib.sha256(str(combo_sorted).encode()).hexdigest()
        NumberCombination.objects.create(
            combination_hash=combination_hash,
            numbers=combo_sorted,
            round_number=round_number,
            rank='3등'
        )
        created_count += 1

    # 4등: 4개 일치 (15가지)
    for combo in combinations(numbers, 4):
        combo_sorted = sorted(list(combo))
        combination_hash = hashlib.sha256(str(combo_sorted).encode()).hexdigest()
        NumberCombination.objects.create(
            combination_hash=combination_hash,
            numbers=combo_sorted,
            round_number=round_number,
            rank='4등'
        )
        created_count += 1

    return created_count


def _get_top_frequent_numbers(count=25):
    """상위 빈출 번호 가져오기"""
    from lotto.models import NumberStatistics
    stats = NumberStatistics.objects.order_by('-total_count')[:count]
    return [stat.number for stat in stats]


def _generate_strategy1_numbers():
    """추가전략1: 빈출 번호 우선 (상위 25개)"""
    top_numbers = _get_top_frequent_numbers(25)
    if len(top_numbers) < 6:
        return None

    max_attempts = 100
    for _ in range(max_attempts):
        numbers = sorted(random.sample(top_numbers, 6))
        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()

        if not NumberCombination.objects.filter(combination_hash=combination_hash).exists():
            return numbers
    return None


def _generate_strategy2_numbers():
    """추가전략2: 홀짝 비율 최적화 + 빈출번호"""
    top_numbers = _get_top_frequent_numbers(25)
    if len(top_numbers) < 6:
        return None

    odd_numbers = [n for n in top_numbers if n % 2 == 1]
    even_numbers = [n for n in top_numbers if n % 2 == 0]

    max_attempts = 100
    for _ in range(max_attempts):
        # 홀수 3개, 짝수 3개 또는 홀수 4개, 짝수 2개 랜덤 선택
        if random.choice([True, False]) and len(odd_numbers) >= 3 and len(even_numbers) >= 3:
            selected = random.sample(odd_numbers, 3) + random.sample(even_numbers, 3)
        elif len(odd_numbers) >= 4 and len(even_numbers) >= 2:
            selected = random.sample(odd_numbers, 4) + random.sample(even_numbers, 2)
        elif len(odd_numbers) >= 2 and len(even_numbers) >= 4:
            selected = random.sample(odd_numbers, 2) + random.sample(even_numbers, 4)
        else:
            continue

        if len(selected) != 6:
            continue

        numbers = sorted(selected)
        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()

        if not NumberCombination.objects.filter(combination_hash=combination_hash).exists():
            return numbers
    return None


def _generate_strategy3_numbers():
    """추가전략3: 구간 분배 균형"""
    top_numbers = _get_top_frequent_numbers(25)
    if len(top_numbers) < 6:
        return None

    range1 = [n for n in top_numbers if 1 <= n <= 15]
    range2 = [n for n in top_numbers if 16 <= n <= 30]
    range3 = [n for n in top_numbers if 31 <= n <= 45]

    max_attempts = 100
    for _ in range(max_attempts):
        if len(range1) < 2 or len(range2) < 2 or len(range3) < 2:
            # Fallback: 각 구간에서 가능한 만큼 선택
            selected = []
            if len(range1) >= 2:
                selected.extend(random.sample(range1, 2))
            elif len(range1) >= 1:
                selected.extend(random.sample(range1, 1))

            if len(range2) >= 2:
                selected.extend(random.sample(range2, 2))
            elif len(range2) >= 1:
                selected.extend(random.sample(range2, 1))

            if len(range3) >= 2:
                selected.extend(random.sample(range3, 2))
            elif len(range3) >= 1:
                selected.extend(random.sample(range3, 1))

            # 6개가 안되면 top_numbers에서 추가
            while len(selected) < 6:
                remaining = [n for n in top_numbers if n not in selected]
                if not remaining:
                    break
                selected.append(random.choice(remaining))
        else:
            selected = random.sample(range1, 2) + random.sample(range2, 2) + random.sample(range3, 2)

        if len(selected) != 6:
            continue

        numbers = sorted(selected)
        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()

        if not NumberCombination.objects.filter(combination_hash=combination_hash).exists():
            return numbers
    return None


def _generate_strategy4_numbers():
    """추가전략4: 연속번호 제한 (최대 2개)"""
    top_numbers = _get_top_frequent_numbers(25)
    if len(top_numbers) < 6:
        return None

    max_attempts = 100
    for _ in range(max_attempts):
        numbers = sorted(random.sample(top_numbers, 6))

        # 연속 번호 체크
        consecutive_count = 1
        max_consecutive = 1
        for i in range(1, len(numbers)):
            if numbers[i] == numbers[i-1] + 1:
                consecutive_count += 1
                max_consecutive = max(max_consecutive, consecutive_count)
            else:
                consecutive_count = 1

        if max_consecutive > 2:
            continue

        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()

        if not NumberCombination.objects.filter(combination_hash=combination_hash).exists():
            return numbers
    return None


def _generate_strategy5_numbers():
    """통합 전략: 전략 1+2+3+4 모두 적용"""
    top_numbers = _get_top_frequent_numbers(25)
    if len(top_numbers) < 6:
        return None

    # 구간별 번호 분류
    range1 = [n for n in top_numbers if 1 <= n <= 15]
    range2 = [n for n in top_numbers if 16 <= n <= 30]
    range3 = [n for n in top_numbers if 31 <= n <= 45]

    # 홀짝 분류
    odd_numbers = [n for n in top_numbers if n % 2 == 1]
    even_numbers = [n for n in top_numbers if n % 2 == 0]

    max_attempts = 500  # 더 많은 시도 (필터가 많으므로)
    for _ in range(max_attempts):
        # Strategy 3: 각 구간에서 2개씩 선택
        if len(range1) < 2 or len(range2) < 2 or len(range3) < 2:
            # 구간별 충분한 번호가 없으면 실패
            continue

        selected = random.sample(range1, 2) + random.sample(range2, 2) + random.sample(range3, 2)

        if len(selected) != 6:
            continue

        # Strategy 2: 홀짝 비율 체크 (3:3 또는 4:2)
        odd_count = sum(1 for n in selected if n % 2 == 1)
        even_count = 6 - odd_count

        if not ((odd_count == 3 and even_count == 3) or (odd_count == 4 and even_count == 2) or (odd_count == 2 and even_count == 4)):
            continue

        # Strategy 4: 연속번호 최대 2개 체크
        numbers = sorted(selected)
        consecutive_count = 1
        max_consecutive = 1
        for i in range(1, len(numbers)):
            if numbers[i] == numbers[i-1] + 1:
                consecutive_count += 1
                max_consecutive = max(max_consecutive, consecutive_count)
            else:
                consecutive_count = 1

        if max_consecutive > 2:
            continue

        # Strategy 1: 이미 나온 조합 제외
        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()

        if not NumberCombination.objects.filter(combination_hash=combination_hash).exists():
            return numbers

    return None


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def generate_smart_numbers_api(request):
    """Generate smart lottery numbers excluding all historical 1-4등 winners - Optimized version"""
    try:
        # Try to generate unique combination (max 100 attempts)
        max_attempts = 100
        for attempt in range(max_attempts):
            # Generate random 6 numbers from 1-45
            numbers = sorted(random.sample(range(1, 46), 6))

            # Create hash for database lookup
            combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()

            # Fast database check - only query for this specific hash
            if not NumberCombination.objects.filter(combination_hash=combination_hash).exists():
                return Response({
                    'success': True,
                    'numbers': numbers
                }, status=status.HTTP_200_OK)

        # If all attempts failed (extremely unlikely)
        return Response({
            'success': False,
            'error': '번호 생성에 실패했습니다. 다시 시도해주세요.'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    except Exception as e:
        return Response({
            'success': False,
            'error': f'번호 생성 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def generate_strategy1_numbers_api(request):
    """추가전략1: 빈출 번호 우선"""
    try:
        numbers = _generate_strategy1_numbers()
        if numbers:
            return Response({
                'success': True,
                'numbers': numbers,
                'strategy': 'strategy1'
            }, status=status.HTTP_200_OK)
        return Response({
            'success': False,
            'error': '번호 생성에 실패했습니다. 다시 시도해주세요.'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    except Exception as e:
        return Response({
            'success': False,
            'error': f'번호 생성 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def generate_strategy2_numbers_api(request):
    """추가전략2: 홀짝 비율 최적화"""
    try:
        numbers = _generate_strategy2_numbers()
        if numbers:
            return Response({
                'success': True,
                'numbers': numbers,
                'strategy': 'strategy2'
            }, status=status.HTTP_200_OK)
        return Response({
            'success': False,
            'error': '번호 생성에 실패했습니다. 다시 시도해주세요.'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    except Exception as e:
        return Response({
            'success': False,
            'error': f'번호 생성 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def generate_strategy3_numbers_api(request):
    """추가전략3: 구간 분배 균형"""
    try:
        numbers = _generate_strategy3_numbers()
        if numbers:
            return Response({
                'success': True,
                'numbers': numbers,
                'strategy': 'strategy3'
            }, status=status.HTTP_200_OK)
        return Response({
            'success': False,
            'error': '번호 생성에 실패했습니다. 다시 시도해주세요.'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    except Exception as e:
        return Response({
            'success': False,
            'error': f'번호 생성 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def generate_strategy4_numbers_api(request):
    """추가전략4: 연속번호 제한"""
    try:
        numbers = _generate_strategy4_numbers()
        if numbers:
            return Response({
                'success': True,
                'numbers': numbers,
                'strategy': 'strategy4'
            }, status=status.HTTP_200_OK)
        return Response({
            'success': False,
            'error': '번호 생성에 실패했습니다. 다시 시도해주세요.'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    except Exception as e:
        return Response({
            'success': False,
            'error': f'번호 생성 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def generate_strategy5_numbers_api(request):
    """통합 전략: 전략 1+2+3+4 모두 적용"""
    try:
        numbers = _generate_strategy5_numbers()
        if numbers:
            return Response({
                'success': True,
                'numbers': numbers,
                'strategy': 'strategy5'
            }, status=status.HTTP_200_OK)
        return Response({
            'success': False,
            'error': '번호 생성에 실패했습니다. 다시 시도해주세요.'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    except Exception as e:
        return Response({
            'success': False,
            'error': f'번호 생성 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def probability_stats_api(request):
    """
    Get probability statistics for smart number generation
    GET /admin-dashboard/lottery/probability-stats/
    """
    try:
        from lotto.models import LottoDraw

        # Total possible combinations: C(45,6) = 8,145,060
        total_combinations = 8145060

        # Get current and previous round numbers
        latest_draw = LottoDraw.objects.order_by('-round_number').first()
        current_round = latest_draw.round_number if latest_draw else 0
        previous_round = current_round - 1 if current_round > 0 else 0

        # Count UNIQUE excluded combinations (not counting duplicates across ranks)
        excluded_count = NumberCombination.objects.values('combination_hash').distinct().count()

        # Count total records to show duplicate information
        total_records = NumberCombination.objects.count()
        duplicate_count = total_records - excluded_count

        # Remaining combinations
        remaining_combinations = total_combinations - excluded_count

        # Calculate probability
        if remaining_combinations > 0:
            probability = 1 / remaining_combinations
            probability_percent = probability * 100

            # Calculate improvement ratio compared to normal lottery
            normal_probability = 1 / total_combinations
            improvement_ratio = probability / normal_probability
        else:
            probability = 0
            probability_percent = 0
            improvement_ratio = 1

        # Calculate previous round statistics
        prev_excluded_count = 0
        prev_duplicate_count = 0
        prev_remaining_combinations = total_combinations

        if previous_round > 0:
            # Count unique excluded combinations up to previous round
            prev_excluded_count = NumberCombination.objects.filter(
                round_number__lte=previous_round
            ).values('combination_hash').distinct().count()

            # Count total records up to previous round
            prev_total_records = NumberCombination.objects.filter(
                round_number__lte=previous_round
            ).count()
            prev_duplicate_count = prev_total_records - prev_excluded_count

            # Previous remaining combinations
            prev_remaining_combinations = total_combinations - prev_excluded_count

        # Calculate deltas
        excluded_delta = excluded_count - prev_excluded_count
        duplicate_delta = duplicate_count - prev_duplicate_count
        remaining_delta = remaining_combinations - prev_remaining_combinations

        return Response({
            'success': True,
            'current_round': current_round,
            'previous_round': previous_round,
            'total_combinations': total_combinations,
            'excluded_count': excluded_count,
            'duplicate_count': duplicate_count,
            'remaining_combinations': remaining_combinations,
            'probability_fraction': f'1/{remaining_combinations:,}',
            'probability_percent': f'{probability_percent:.7f}',
            'improvement_ratio': f'{improvement_ratio:.4f}',
            'prev_excluded_count': prev_excluded_count,
            'prev_duplicate_count': prev_duplicate_count,
            'prev_remaining_combinations': prev_remaining_combinations,
            'excluded_delta': excluded_delta,
            'duplicate_delta': duplicate_delta,
            'remaining_delta': remaining_delta
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            'success': False,
            'error': f'통계 계산 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ===== Strategy Probability Calculation Functions =====

def _calculate_strategy1_stats():
    """추가전략1 통계 계산: 상위 25개 빈출 번호"""
    from lotto.models import NumberStatistics, NumberCombination, LottoDraw
    from itertools import combinations
    import math

    # 상위 25개 빈출 번호 가져오기
    top_numbers = _get_top_frequent_numbers(25)

    # 이론적 조합 수: C(25, 6)
    total_theoretical = math.comb(25, 6)  # 177,100

    # NumberCombination에서 제외된 조합 카운트
    excluded_count = 0
    for combo in combinations(top_numbers, 6):
        numbers = sorted(combo)
        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()
        if NumberCombination.objects.filter(combination_hash=combination_hash).exists():
            excluded_count += 1

    # 남은 조합 수
    remaining_count = total_theoretical - excluded_count

    # 확률 계산
    probability = 1 / remaining_count if remaining_count > 0 else 0

    # 일반 로또 대비 배수
    improvement_ratio = 8145060 / remaining_count if remaining_count > 0 else 0

    return {
        'total': total_theoretical,
        'excluded': excluded_count,
        'remaining': remaining_count,
        'probability': probability,
        'improvement': improvement_ratio
    }


def _calculate_strategy2_stats():
    """추가전략2 통계 계산: 홀짝 비율 최적화"""
    from lotto.models import NumberCombination
    from itertools import combinations
    import math

    # 상위 25개 빈출 번호
    top_numbers = _get_top_frequent_numbers(25)
    odd_numbers = [n for n in top_numbers if n % 2 == 1]
    even_numbers = [n for n in top_numbers if n % 2 == 0]

    # 가능한 조합: 홀3짝3 + 홀4짝2 + 홀2짝4
    total_theoretical = 0
    total_theoretical += math.comb(len(odd_numbers), 3) * math.comb(len(even_numbers), 3)  # 홀3짝3
    total_theoretical += math.comb(len(odd_numbers), 4) * math.comb(len(even_numbers), 2)  # 홀4짝2
    total_theoretical += math.comb(len(odd_numbers), 2) * math.comb(len(even_numbers), 4)  # 홀2짝4

    # 제외된 조합 카운트
    excluded_count = 0

    # 홀3짝3
    for odd_combo in combinations(odd_numbers, 3):
        for even_combo in combinations(even_numbers, 3):
            numbers = sorted(list(odd_combo) + list(even_combo))
            combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()
            if NumberCombination.objects.filter(combination_hash=combination_hash).exists():
                excluded_count += 1

    # 홀4짝2
    for odd_combo in combinations(odd_numbers, 4):
        for even_combo in combinations(even_numbers, 2):
            numbers = sorted(list(odd_combo) + list(even_combo))
            combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()
            if NumberCombination.objects.filter(combination_hash=combination_hash).exists():
                excluded_count += 1

    # 홀2짝4
    for odd_combo in combinations(odd_numbers, 2):
        for even_combo in combinations(even_numbers, 4):
            numbers = sorted(list(odd_combo) + list(even_combo))
            combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()
            if NumberCombination.objects.filter(combination_hash=combination_hash).exists():
                excluded_count += 1

    remaining_count = total_theoretical - excluded_count
    probability = 1 / remaining_count if remaining_count > 0 else 0
    improvement_ratio = 8145060 / remaining_count if remaining_count > 0 else 0

    return {
        'total': total_theoretical,
        'excluded': excluded_count,
        'remaining': remaining_count,
        'probability': probability,
        'improvement': improvement_ratio
    }


def _calculate_strategy3_stats():
    """추가전략3 통계 계산: 범위 분산"""
    from lotto.models import NumberCombination
    from itertools import combinations
    import math

    top_numbers = _get_top_frequent_numbers(25)
    range1 = [n for n in top_numbers if 1 <= n <= 15]
    range2 = [n for n in top_numbers if 16 <= n <= 30]
    range3 = [n for n in top_numbers if 31 <= n <= 45]

    # 이론적 조합: 각 구간에서 2개씩
    total_theoretical = math.comb(len(range1), 2) * math.comb(len(range2), 2) * math.comb(len(range3), 2)

    # 제외된 조합 카운트
    excluded_count = 0
    for r1_combo in combinations(range1, 2):
        for r2_combo in combinations(range2, 2):
            for r3_combo in combinations(range3, 2):
                numbers = sorted(list(r1_combo) + list(r2_combo) + list(r3_combo))
                combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()
                if NumberCombination.objects.filter(combination_hash=combination_hash).exists():
                    excluded_count += 1

    remaining_count = total_theoretical - excluded_count
    probability = 1 / remaining_count if remaining_count > 0 else 0
    improvement_ratio = 8145060 / remaining_count if remaining_count > 0 else 0

    return {
        'total': total_theoretical,
        'excluded': excluded_count,
        'remaining': remaining_count,
        'probability': probability,
        'improvement': improvement_ratio
    }


def _calculate_strategy4_stats():
    """추가전략4 통계 계산: 연속 번호 제한 (최대 2개)"""
    from lotto.models import NumberCombination
    from itertools import combinations

    top_numbers = _get_top_frequent_numbers(25)

    # 모든 조합 중 연속 번호가 최대 2개인 경우만 카운트
    total_theoretical = 0
    excluded_count = 0

    for combo in combinations(top_numbers, 6):
        numbers = sorted(combo)

        # 연속 번호 체크
        consecutive_count = 1
        max_consecutive = 1
        for i in range(1, len(numbers)):
            if numbers[i] == numbers[i-1] + 1:
                consecutive_count += 1
                max_consecutive = max(max_consecutive, consecutive_count)
            else:
                consecutive_count = 1

        # 연속 번호가 2개 이하인 경우만 카운트
        if max_consecutive <= 2:
            total_theoretical += 1

            # 이 조합이 이미 나왔는지 체크
            combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()
            if NumberCombination.objects.filter(combination_hash=combination_hash).exists():
                excluded_count += 1

    remaining_count = total_theoretical - excluded_count
    probability = 1 / remaining_count if remaining_count > 0 else 0
    improvement_ratio = 8145060 / remaining_count if remaining_count > 0 else 0

    return {
        'total': total_theoretical,
        'excluded': excluded_count,
        'remaining': remaining_count,
        'probability': probability,
        'improvement': improvement_ratio
    }


def _calculate_strategy5_stats():
    """통합 전략 통계 계산: 전략 1+2+3+4 모두 적용"""
    from lotto.models import NumberCombination
    from itertools import combinations

    top_numbers = _get_top_frequent_numbers(25)

    # 모든 필터를 만족하는 조합만 카운트
    total_theoretical = 0
    excluded_count = 0

    for combo in combinations(top_numbers, 6):
        numbers = sorted(combo)

        # Filter 1: 구간별 분배 (각 구간에 최소 1개씩)
        r1_count = sum(1 for n in numbers if 1 <= n <= 15)
        r2_count = sum(1 for n in numbers if 16 <= n <= 30)
        r3_count = sum(1 for n in numbers if 31 <= n <= 45)

        if r1_count == 0 or r2_count == 0 or r3_count == 0:
            continue  # 이 조합은 카운트하지 않음

        # Filter 2: 홀짝 비율 (3:3 또는 4:2 또는 2:4)
        odd_count = sum(1 for n in numbers if n % 2 == 1)
        even_count = 6 - odd_count

        if not ((odd_count == 3 and even_count == 3) or (odd_count == 4 and even_count == 2) or (odd_count == 2 and even_count == 4)):
            continue  # 이 조합은 카운트하지 않음

        # Filter 3: 연속번호 최대 2개
        consecutive_count = 1
        max_consecutive = 1
        for i in range(1, len(numbers)):
            if numbers[i] == numbers[i-1] + 1:
                consecutive_count += 1
                max_consecutive = max(max_consecutive, consecutive_count)
            else:
                consecutive_count = 1

        if max_consecutive > 2:
            continue  # 이 조합은 카운트하지 않음

        # 모든 필터 통과 - 이론적 조합에 포함
        total_theoretical += 1

        # Filter 4: 이미 나온 조합 제외
        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()
        if NumberCombination.objects.filter(combination_hash=combination_hash).exists():
            excluded_count += 1

    remaining_count = total_theoretical - excluded_count
    probability = 1 / remaining_count if remaining_count > 0 else 0
    improvement_ratio = 8145060 / remaining_count if remaining_count > 0 else 0

    return {
        'total': total_theoretical,
        'excluded': excluded_count,
        'remaining': remaining_count,
        'probability': probability,
        'improvement': improvement_ratio
    }


def update_all_strategy_statistics():
    """모든 전략 통계 업데이트"""
    from lotto.models import LottoDraw, StrategyStatistics

    latest_draw = LottoDraw.objects.order_by('-round_number').first()
    if not latest_draw:
        return False

    strategies = [
        ('strategy1', _calculate_strategy1_stats),
        ('strategy2', _calculate_strategy2_stats),
        ('strategy3', _calculate_strategy3_stats),
        ('strategy4', _calculate_strategy4_stats),
        ('strategy5', _calculate_strategy5_stats),
    ]

    for strategy_type, calc_func in strategies:
        stats = calc_func()
        StrategyStatistics.objects.update_or_create(
            strategy_type=strategy_type,
            defaults={
                'round_number': latest_draw.round_number,
                'total_theoretical': stats['total'],
                'excluded_count': stats['excluded'],
                'remaining_count': stats['remaining'],
                'probability': stats['probability'],
                'improvement_ratio': stats['improvement']
            }
        )

    return True


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_strategy_probability_api(request, strategy_type):
    """
    Get probability statistics for a specific strategy
    GET /admin-dashboard/lottery/strategy-probability/<strategy_type>/
    """
    from lotto.models import StrategyStatistics

    try:
        stats = StrategyStatistics.objects.get(strategy_type=strategy_type)

        return Response({
            'success': True,
            'round_number': stats.round_number,
            'total_combinations': stats.total_theoretical,
            'excluded_combinations': stats.excluded_count,
            'remaining_combinations': stats.remaining_count,
            'probability': stats.probability,
            'probability_percent': f"{stats.probability * 100:.8f}%",
            'improvement_ratio': stats.improvement_ratio,
            'last_updated': stats.last_updated.strftime('%Y-%m-%d %H:%M:%S')
        }, status=status.HTTP_200_OK)

    except StrategyStatistics.DoesNotExist:
        return Response({
            'success': False,
            'error': '통계 데이터가 없습니다. 관리자에게 문의하세요.'
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'error': f'통계 조회 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


