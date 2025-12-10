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
from lotto.utils import calculate_target_round, check_duplicate_for_user_round
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
    ).values('id', 'email', 'nickname', 'is_staff', 'is_superuser', 'is_prime', 'is_gold')[:20]

    results = []
    for user in users:
        # 5단계 권한 시스템 적용
        if user.get('is_prime'):
            role = 'Prime'
        elif user['is_superuser']:
            role = 'Superuser'
        elif user['is_staff']:
            role = 'Staff'
        elif user.get('is_gold'):
            role = 'GoldUser'
        else:
            role = 'User'

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
    Update user permissions (5-tier permission system)
    POST /admin-dashboard/api/users/<user_id>/permissions/

    Body: {"role": "user|gold|staff|prime|superuser"}

    Permission Hierarchy:
        - User/GoldUser: 권한 부여 불가
        - Staff: user, gold, staff까지만 부여 가능
        - Prime: user, gold, staff까지만 부여 가능 (Prime은 Superuser만 부여 가능)
        - Superuser: 모든 권한 부여 가능

    Returns updated user information
    """
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

    role = request.data.get('role')

    # 권한 부여 제약 검증
    if not request.user.can_assign_role(role):
        return Response({
            'success': False,
            'error': '해당 권한을 부여할 수 없습니다.'
        }, status=status.HTTP_403_FORBIDDEN)

    # 대상 사용자의 현재 역할 검증
    # Prime 사용자는 Superuser만 변경 가능
    if user.is_prime and not request.user.is_superuser:
        return Response({
            'success': False,
            'error': 'Prime의 권한 변경이 불가합니다.'
        }, status=status.HTTP_403_FORBIDDEN)

    # Superuser는 Superuser만 변경 가능 (Prime이 아닌 Superuser)
    if user.is_superuser and not user.is_prime and not request.user.is_superuser:
        return Response({
            'success': False,
            'error': 'Superuser의 권한은 Superuser만 변경할 수 있습니다.'
        }, status=status.HTTP_403_FORBIDDEN)

    # 역할별 권한 설정
    if role == 'user':
        user.is_staff = False
        user.is_superuser = False
        user.is_prime = False
        user.is_gold = False
    elif role == 'gold':
        user.is_staff = False
        user.is_superuser = False
        user.is_prime = False
        user.is_gold = True
    elif role == 'staff':
        user.is_staff = True
        user.is_superuser = False
        user.is_prime = False
        user.is_gold = True  # Staff는 유료 기능 사용 가능
    elif role == 'prime':
        user.is_staff = True
        user.is_superuser = True
        user.is_prime = True
        user.is_gold = True
    elif role == 'superuser':
        user.is_staff = True
        user.is_superuser = True
        user.is_prime = False
        user.is_gold = True
    else:
        return Response({
            'error': 'Invalid role. Must be: user, gold, staff, prime, or superuser'
        }, status=status.HTTP_400_BAD_REQUEST)

    user.save(update_fields=['is_staff', 'is_superuser', 'is_prime', 'is_gold'])

    # 역할 레이블 결정
    if user.is_prime:
        role_label = 'Prime'
    elif user.is_superuser:
        role_label = 'Superuser'
    elif user.is_staff:
        role_label = 'Staff'
    elif user.is_gold:
        role_label = 'GoldUser'
    else:
        role_label = 'User'

    return Response({
        'success': True,
        'user': {
            'id': user.id,
            'email': user.email,
            'nickname': user.nickname,
            'role': role_label
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

        # 등수에 따른 일치 개수와 보너스 정보 계산
        matched_count = 0
        has_bonus = False
        if match.rank == '1등':
            matched_count = 6
            has_bonus = False
        elif match.rank == '2등':
            matched_count = 5
            has_bonus = True
        elif match.rank == '3등':
            matched_count = 5
            has_bonus = False
        elif match.rank == '4등':
            matched_count = 4
            has_bonus = False

        return {
            'is_winning': True,
            'round_number': match.round_number,
            'rank': match.rank,
            'matched_count': matched_count,
            'has_bonus': has_bonus,
            'draw_date': draw_date,
            'message': f'{match.round_number}회 {match.rank} 번호입니다',
            'numbers': sorted_numbers
        }
    else:
        return {
            'is_winning': False,
            'round_number': None,
            'rank': None,
            'matched_count': 0,
            'has_bonus': False,
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
    round_number = request.data.get('round_number')
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
        # 타겟 회차가 없거나 0이면 날짜 기반으로 자동 계산
        if not round_number or round_number == 0:
            round_number = calculate_target_round()
        else:
            round_number = int(round_number)
    except (ValueError, TypeError):
        return Response({
            'success': False,
            'error': '올바른 숫자를 입력해주세요'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Check if numbers are winning numbers
    check_result = check_user_numbers(numbers)

    # Check for duplicate numbers
    is_duplicate, existing_round = check_duplicate_for_user_round(request.user, round_number, numbers)
    if is_duplicate:
        return Response({
            'success': False,
            'error': f'{existing_round}회에 저장한 이력이 있습니다.'
        }, status=status.HTTP_400_BAD_REQUEST)

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
            strategy_type=strategy,
            is_checked=check_result['is_winning'],
            matched_rank=check_result['rank'] if check_result['is_winning'] else None,
            matched_round=check_result['round_number'] if check_result['is_winning'] else None,
            matched_count=check_result['matched_count'],
            has_bonus=check_result['has_bonus']
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
            'matched_round': un.matched_round,  # 실제 당첨 회차
            'matched_count': un.matched_count,  # 일치 개수
            'has_bonus': un.has_bonus,  # 보너스 일치 여부
            'strategy_type': un.strategy_type,
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

        # Update number frequency statistics
        _update_number_statistics(draw, numbers, bonus_number)

        # Update strategy statistics automatically
        update_all_strategy_statistics()

        # AUTO-CHECK: Check unchecked user numbers for winning
        unchecked = UserLottoNumber.objects.filter(
            is_checked=False,
            round_number__lte=draw.round_number
        )

        winners = []
        for user_num in unchecked:
            if user_num.check_winning():
                winners.append({
                    'user_id': user_num.user.id,
                    'target': user_num.round_number,
                    'actual': user_num.matched_round,
                    'rank': user_num.matched_rank,
                })

        return Response({
            'success': True,
            'message': f'{next_round}회차 당첨 번호가 저장되었습니다',
            'round_number': next_round,
            'combinations_created': created_count,
            'winners_checked': len(winners),
            'winners': winners
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

    # 비당첨 번호 목록 (보너스 제외한 나머지 38개)
    non_winning = [n for n in range(1, 46) if n not in numbers and n != bonus_number]

    # 3등: 5개 당첨번호 + 1개 비당첨번호 (6 × 38 = 228가지)
    for winning_5 in combinations(numbers, 5):
        for non_win in non_winning:
            combo_sorted = sorted(list(winning_5) + [non_win])
            combination_hash = hashlib.sha256(str(combo_sorted).encode()).hexdigest()
            NumberCombination.objects.create(
                combination_hash=combination_hash,
                numbers=combo_sorted,
                round_number=round_number,
                rank='3등'
            )
            created_count += 1

    # 4등: 4개 당첨번호 + 2개 비당첨번호 (15 × C(38,2) = 15 × 703 = 10,545가지)
    for winning_4 in combinations(numbers, 4):
        for non_win_2 in combinations(non_winning, 2):
            combo_sorted = sorted(list(winning_4) + list(non_win_2))
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
    """추가전략2: 홀짝 비율 최적화 (전체 45개 번호 사용)"""
    # 전체 45개 번호 사용
    all_numbers = list(range(1, 46))
    odd_numbers = [n for n in all_numbers if n % 2 == 1]  # 1,3,5,...,45 = 23개
    even_numbers = [n for n in all_numbers if n % 2 == 0]  # 2,4,6,...,44 = 22개

    max_attempts = 100
    for _ in range(max_attempts):
        # 홀짝 비율 랜덤 선택: 3:3, 4:2, 2:4
        ratio_choice = random.choice(['3:3', '4:2', '2:4'])

        if ratio_choice == '3:3':
            selected = random.sample(odd_numbers, 3) + random.sample(even_numbers, 3)
        elif ratio_choice == '4:2':
            selected = random.sample(odd_numbers, 4) + random.sample(even_numbers, 2)
        else:  # 2:4
            selected = random.sample(odd_numbers, 2) + random.sample(even_numbers, 4)

        numbers = sorted(selected)
        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()

        # 1~4등 당첨 조합 제외
        if not NumberCombination.objects.filter(combination_hash=combination_hash).exists():
            return numbers
    return None


def _generate_strategy3_numbers():
    """추가전략3: 구간 분배 균형 (전체 45개 번호 사용)"""
    # 전체 45개 번호를 3개 범위로 균등 분할
    range1 = list(range(1, 16))    # [1, 2, ..., 15] = 15개
    range2 = list(range(16, 31))   # [16, 17, ..., 30] = 15개
    range3 = list(range(31, 46))   # [31, 32, ..., 45] = 15개

    max_attempts = 100
    for _ in range(max_attempts):
        # 각 범위에서 정확히 2개씩 선택 (15개씩 있으므로 항상 가능)
        selected = random.sample(range1, 2) + random.sample(range2, 2) + random.sample(range3, 2)

        numbers = sorted(selected)
        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()

        # 1~4등 당첨 조합 제외
        if not NumberCombination.objects.filter(combination_hash=combination_hash).exists():
            return numbers
    return None


def _generate_strategy4_numbers():
    """추가전략4: 연속번호 제한 - 최대 2개 (전체 45개 번호 사용)"""
    # 전체 45개 번호 사용
    all_numbers = list(range(1, 46))

    max_attempts = 100
    for _ in range(max_attempts):
        numbers = sorted(random.sample(all_numbers, 6))

        # 연속 번호 체크
        consecutive_count = 1
        max_consecutive = 1
        for i in range(1, len(numbers)):
            if numbers[i] == numbers[i-1] + 1:
                consecutive_count += 1
                max_consecutive = max(max_consecutive, consecutive_count)
            else:
                consecutive_count = 1

        # 연속 번호가 3개 이상이면 스킵
        if max_consecutive > 2:
            continue

        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()

        # 1~4등 당첨 조합 제외
        if not NumberCombination.objects.filter(combination_hash=combination_hash).exists():
            return numbers
    return None


def _generate_strategy5_numbers():
    """통합 전략: 상위 25개 + 홀짝 + 범위 + 연속 모든 필터 적용"""
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

    # ⚠️ 검증: 각 범위에 최소 2개씩 있어야 범위 분산 필터 적용 가능
    if len(range1) < 2 or len(range2) < 2 or len(range3) < 2:
        # 조건 충족 불가능 - 통합전략 생성 실패
        return None

    max_attempts = 500  # 더 많은 시도 (필터가 많으므로)
    for _ in range(max_attempts):
        # Strategy 3: 각 구간에서 2개씩 선택
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
                'strategy': 'integrated'
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
    """추가전략2 통계 계산: 남은 조합 중 홀짝 비율 최적화"""
    from lotto.models import NumberCombination
    from itertools import combinations

    # ⚡ 성능 최적화: 1~4등 당첨 조합 해시를 메모리에 로드 (1회 DB 쿼리)
    excluded_hashes = set(
        NumberCombination.objects.values_list('combination_hash', flat=True)
    )

    total_theoretical = 0

    for combo in combinations(range(1, 46), 6):
        numbers = sorted(combo)
        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()

        # ⚡ 메모리 set 조회 (O(1) - 극히 빠름)
        if combination_hash in excluded_hashes:
            continue

        # 홀짝 비율 체크 (3:3, 4:2, 2:4만 허용)
        odd_count = sum(1 for n in numbers if n % 2 == 1)
        even_count = 6 - odd_count

        if (odd_count == 3 and even_count == 3) or \
           (odd_count == 4 and even_count == 2) or \
           (odd_count == 2 and even_count == 4):
            total_theoretical += 1

    remaining_count = total_theoretical
    probability = 1 / remaining_count if remaining_count > 0 else 0
    improvement_ratio = 8145060 / remaining_count if remaining_count > 0 else 0

    return {
        'total': total_theoretical,
        'excluded': 0,
        'remaining': remaining_count,
        'probability': probability,
        'improvement': improvement_ratio
    }


def _calculate_strategy3_stats():
    """추가전략3 통계 계산: 남은 조합 중 범위 분산"""
    from lotto.models import NumberCombination
    from itertools import combinations

    # ⚡ 성능 최적화: 1~4등 당첨 조합 해시를 메모리에 로드 (1회 DB 쿼리)
    excluded_hashes = set(
        NumberCombination.objects.values_list('combination_hash', flat=True)
    )

    total_theoretical = 0

    for combo in combinations(range(1, 46), 6):
        numbers = sorted(combo)
        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()

        # ⚡ 메모리 set 조회 (O(1) - 극히 빠름)
        if combination_hash in excluded_hashes:
            continue

        # 범위 분산 체크 (각 범위에서 정확히 2개씩)
        r1_count = sum(1 for n in numbers if 1 <= n <= 15)
        r2_count = sum(1 for n in numbers if 16 <= n <= 30)
        r3_count = sum(1 for n in numbers if 31 <= n <= 45)

        if r1_count == 2 and r2_count == 2 and r3_count == 2:
            total_theoretical += 1

    remaining_count = total_theoretical
    probability = 1 / remaining_count if remaining_count > 0 else 0
    improvement_ratio = 8145060 / remaining_count if remaining_count > 0 else 0

    return {
        'total': total_theoretical,
        'excluded': 0,
        'remaining': remaining_count,
        'probability': probability,
        'improvement': improvement_ratio
    }


def _calculate_strategy4_stats():
    """추가전략4 통계 계산: 남은 조합 중 연속 번호 제한"""
    from lotto.models import NumberCombination
    from itertools import combinations

    # ⚡ 성능 최적화: 1~4등 당첨 조합 해시를 메모리에 로드 (1회 DB 쿼리)
    excluded_hashes = set(
        NumberCombination.objects.values_list('combination_hash', flat=True)
    )

    total_theoretical = 0

    for combo in combinations(range(1, 46), 6):
        numbers = sorted(combo)
        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()

        # ⚡ 메모리 set 조회 (O(1) - 극히 빠름)
        if combination_hash in excluded_hashes:
            continue

        # 연속 번호 체크 (최대 2개까지만 허용)
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

    remaining_count = total_theoretical
    probability = 1 / remaining_count if remaining_count > 0 else 0
    improvement_ratio = 8145060 / remaining_count if remaining_count > 0 else 0

    return {
        'total': total_theoretical,
        'excluded': 0,
        'remaining': remaining_count,
        'probability': probability,
        'improvement': improvement_ratio
    }


def _calculate_strategy5_stats():
    """통합 전략 통계 계산: 상위 25개 + 홀짝 + 범위 + 연속 모든 필터"""
    from lotto.models import NumberCombination
    from itertools import combinations

    # ⚡ 성능 최적화: 1~4등 당첨 조합 해시를 메모리에 로드 (1회 DB 쿼리)
    excluded_hashes = set(
        NumberCombination.objects.values_list('combination_hash', flat=True)
    )

    top_numbers = _get_top_frequent_numbers(25)

    # 구간별 번호 분류
    range1 = [n for n in top_numbers if 1 <= n <= 15]
    range2 = [n for n in top_numbers if 16 <= n <= 30]
    range3 = [n for n in top_numbers if 31 <= n <= 45]

    # ⚠️ 검증: 각 범위에 최소 2개씩 있어야 함
    if len(range1) < 2 or len(range2) < 2 or len(range3) < 2:
        return {
            'total': 0,
            'excluded': 0,
            'remaining': 0,
            'probability': 0,
            'improvement': 0
        }

    total_theoretical = 0
    excluded_count = 0

    for combo in combinations(top_numbers, 6):
        numbers = sorted(combo)

        # Filter 1: 구간별 분배 (각 구간에서 정확히 2개씩)
        r1_count = sum(1 for n in numbers if 1 <= n <= 15)
        r2_count = sum(1 for n in numbers if 16 <= n <= 30)
        r3_count = sum(1 for n in numbers if 31 <= n <= 45)

        if r1_count != 2 or r2_count != 2 or r3_count != 2:
            continue

        # Filter 2: 홀짝 비율 (3:3 또는 4:2 또는 2:4)
        odd_count = sum(1 for n in numbers if n % 2 == 1)
        even_count = 6 - odd_count

        if not ((odd_count == 3 and even_count == 3) or (odd_count == 4 and even_count == 2) or (odd_count == 2 and even_count == 4)):
            continue

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
            continue

        # 모든 필터 통과 - 이론적 조합에 포함
        total_theoretical += 1

        # Filter 4: 이미 나온 조합 제외 (⚡ 메모리 set 조회)
        combination_hash = hashlib.sha256(str(numbers).encode()).hexdigest()
        if combination_hash in excluded_hashes:
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
    """모든 전략 통계 업데이트 및 히스토리 저장"""
    from lotto.models import LottoDraw, StrategyStatistics, StrategyStatisticsHistory

    latest_draw = LottoDraw.objects.order_by('-round_number').first()
    if not latest_draw:
        return False

    strategies = [
        ('strategy1', _calculate_strategy1_stats),
        ('strategy2', _calculate_strategy2_stats),
        ('strategy3', _calculate_strategy3_stats),
        ('strategy4', _calculate_strategy4_stats),
        ('integrated', _calculate_strategy5_stats),  # 통합전략
    ]

    for strategy_type, calc_func in strategies:
        stats = calc_func()

        # 1. 이전 회차 히스토리 조회 (전 회차 데이터)
        previous = StrategyStatisticsHistory.objects.filter(
            strategy_type=strategy_type
        ).order_by('-round_number').first()

        # 2. 변화량 계산
        if previous:
            change_remaining = stats['remaining'] - previous.remaining_count
            change_prob_pct = ((stats['probability'] - previous.probability)
                              / previous.probability * 100) if previous.probability > 0 else 0
            change_ratio = stats['improvement'] - previous.improvement_ratio
        else:
            # 첫 회차는 비교 대상 없음
            change_remaining = None
            change_prob_pct = None
            change_ratio = None

        # 3. 현재 통계 업데이트 (StrategyStatistics - 덮어쓰기)
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

        # 4. 히스토리 저장 (StrategyStatisticsHistory - 새 레코드 추가)
        StrategyStatisticsHistory.objects.create(
            strategy_type=strategy_type,
            round_number=latest_draw.round_number,
            total_theoretical=stats['total'],
            excluded_count=stats['excluded'],
            remaining_count=stats['remaining'],
            probability=stats['probability'],
            improvement_ratio=stats['improvement'],
            change_remaining=change_remaining,
            change_probability_pct=change_prob_pct,
            change_ratio=change_ratio
        )

    return True


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_strategy_probability_api(request, strategy_type):
    """
    Get probability statistics for a specific strategy
    GET /admin-dashboard/lottery/strategy-probability/<strategy_type>/
    """
    from lotto.models import StrategyStatistics, StrategyStatisticsHistory

    try:
        stats = StrategyStatistics.objects.get(strategy_type=strategy_type)

        # 기본 응답 데이터
        response_data = {
            'success': True,
            'round_number': stats.round_number,
            'total_combinations': stats.total_theoretical,
            'excluded_combinations': stats.excluded_count,
            'remaining_combinations': stats.remaining_count,
            'probability': stats.probability,
            'probability_percent': f"{stats.probability * 100:.8f}%",
            'improvement_ratio': stats.improvement_ratio,
            'last_updated': stats.last_updated.strftime('%Y-%m-%d %H:%M:%S')
        }

        # 이전 회차 조회
        previous = StrategyStatisticsHistory.objects.filter(
            strategy_type=strategy_type,
            round_number__lt=stats.round_number
        ).order_by('-round_number').first()

        # 전 회차 비교 데이터 추가
        if previous:
            # 변화량 계산
            change_remaining = stats.remaining_count - previous.remaining_count
            change_ratio = stats.improvement_ratio - previous.improvement_ratio

            # 트렌드 방향 결정 (조합수 감소는 개선)
            trend = 'down' if change_remaining < 0 else ('up' if change_remaining > 0 else 'same')
            trend_arrow = '↓' if trend == 'down' else ('↑' if trend == 'up' else '→')

            response_data['comparison'] = {
                'has_previous': True,
                'previous_round': previous.round_number,
                'previous_remaining': previous.remaining_count,
                'previous_ratio': previous.improvement_ratio,
                'change_remaining': change_remaining,
                'change_ratio': change_ratio,
                'trend': trend,
                'trend_arrow': trend_arrow
            }
        else:
            response_data['comparison'] = {
                'has_previous': False
            }

        return Response(response_data, status=status.HTTP_200_OK)

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


def _update_number_statistics(draw, numbers, bonus_number):
    """
    새 당첨 번호에 대한 NumberStatistics 업데이트

    Args:
        draw: LottoDraw 객체
        numbers: 당첨 번호 리스트 (6개)
        bonus_number: 보너스 번호 (1개)
    """
    from lotto.models import NumberStatistics

    # 당첨 번호 6개 업데이트
    for num in numbers:
        stat, created = NumberStatistics.objects.get_or_create(number=num)
        stat.first_prize_count += 1
        stat.total_count += 1
        stat.last_appeared_round = draw.round_number
        stat.last_appeared_date = draw.draw_date
        stat.save()

    # 보너스 번호 업데이트
    bonus_stat, created = NumberStatistics.objects.get_or_create(number=bonus_number)
    bonus_stat.bonus_count += 1
    bonus_stat.total_count += 1
    bonus_stat.last_appeared_round = draw.round_number
    bonus_stat.last_appeared_date = draw.draw_date
    bonus_stat.save()


@api_view(['GET'])
@permission_classes([IsAdminUser])
def get_recent_draws_api(request):
    """
    Get recent 5 lottery draws
    GET /api/admin/lottery/recent-draws/
    """
    try:
        # 최근 5개 회차 조회
        draws = LottoDraw.objects.all().order_by('-round_number')[:5]

        draws_list = []
        for draw in draws:
            numbers = [draw.number1, draw.number2, draw.number3, draw.number4, draw.number5, draw.number6]

            # 중복 회차 감지 (같은 날짜에 같은 번호)
            is_duplicate = False
            if draws.count() > 1:
                # 이전 회차들과 비교
                prev_draws = LottoDraw.objects.filter(
                    round_number__lt=draw.round_number,
                    draw_date=draw.draw_date
                ).values_list('number1', 'number2', 'number3', 'number4', 'number5', 'number6')

                for prev_numbers in prev_draws:
                    if list(prev_numbers) == numbers:
                        is_duplicate = True
                        break

            draws_list.append({
                'round_number': draw.round_number,
                'draw_date': draw.draw_date.strftime('%Y-%m-%d'),
                'numbers': numbers,
                'bonus_number': draw.bonus_number,
                'is_duplicate': is_duplicate
            })

        return Response({
            'success': True,
            'draws': draws_list
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            'success': False,
            'error': f'회차 조회 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAdminUser])
def delete_draw_api(request, round_number):
    """
    Delete a lottery draw and all related data
    DELETE /api/admin/lottery/draws/<round_number>/

    Deletes:
    - LottoDraw record
    - All NumberCombination records for this round
    - Updates NumberStatistics (decrements counts)
    """
    from django.db import transaction
    from lotto.models import NumberStatistics

    try:
        # 트랜잭션으로 원자성 보장
        with transaction.atomic():
            # 1. LottoDraw 조회
            try:
                draw = LottoDraw.objects.get(round_number=round_number)
            except LottoDraw.DoesNotExist:
                return Response({
                    'success': False,
                    'error': f'{round_number}회차를 찾을 수 없습니다'
                }, status=status.HTTP_404_NOT_FOUND)

            # 2. 당첨 번호 수집 (NumberStatistics 보정용)
            numbers = [draw.number1, draw.number2, draw.number3, draw.number4, draw.number5, draw.number6]
            bonus_number = draw.bonus_number

            # 3. NumberCombination 삭제
            deleted_combos = NumberCombination.objects.filter(round_number=round_number).delete()
            deleted_combo_count = deleted_combos[0] if deleted_combos else 0

            # 4. NumberStatistics 보정 (카운트 감소)
            for num in numbers:
                try:
                    stat = NumberStatistics.objects.get(number=num)
                    stat.first_prize_count = max(0, stat.first_prize_count - 1)
                    stat.total_count = max(0, stat.total_count - 1)

                    # last_appeared_round 재계산 (필요시)
                    if stat.last_appeared_round == round_number:
                        # 이 번호가 마지막으로 나온 회차 찾기
                        prev_draw = LottoDraw.objects.filter(
                            Q(number1=num) | Q(number2=num) | Q(number3=num) |
                            Q(number4=num) | Q(number5=num) | Q(number6=num) | Q(bonus_number=num)
                        ).exclude(round_number=round_number).order_by('-round_number').first()

                        if prev_draw:
                            stat.last_appeared_round = prev_draw.round_number
                            stat.last_appeared_date = prev_draw.draw_date
                        else:
                            # 이 번호가 한번도 안나온 경우
                            stat.last_appeared_round = 0
                            stat.last_appeared_date = None

                    stat.save()
                except NumberStatistics.DoesNotExist:
                    pass  # 통계가 없으면 스킵

            # 5. 보너스 번호 보정
            try:
                bonus_stat = NumberStatistics.objects.get(number=bonus_number)
                bonus_stat.bonus_count = max(0, bonus_stat.bonus_count - 1)
                bonus_stat.total_count = max(0, bonus_stat.total_count - 1)

                if bonus_stat.last_appeared_round == round_number:
                    prev_draw = LottoDraw.objects.filter(
                        Q(number1=bonus_number) | Q(number2=bonus_number) | Q(number3=bonus_number) |
                        Q(number4=bonus_number) | Q(number5=bonus_number) | Q(number6=bonus_number) | Q(bonus_number=bonus_number)
                    ).exclude(round_number=round_number).order_by('-round_number').first()

                    if prev_draw:
                        bonus_stat.last_appeared_round = prev_draw.round_number
                        bonus_stat.last_appeared_date = prev_draw.draw_date
                    else:
                        bonus_stat.last_appeared_round = 0
                        bonus_stat.last_appeared_date = None

                bonus_stat.save()
            except NumberStatistics.DoesNotExist:
                pass

            # 6. LottoDraw 삭제
            draw.delete()

            # 7. StrategyStatistics 재계산 (삭제 후)
            update_all_strategy_statistics()

            return Response({
                'success': True,
                'message': f'{round_number}회차가 삭제되었습니다',
                'deleted_combinations': deleted_combo_count,
                'updated_statistics': len(numbers) + 1  # 당첨번호 6개 + 보너스 1개
            }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({
            'success': False,
            'error': f'삭제 중 오류가 발생했습니다: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


