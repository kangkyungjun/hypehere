"""
로또 번호 생성 및 관리를 위한 헬퍼 함수들
"""
from datetime import datetime, timedelta
from lotto.models import LottoDraw, UserLottoNumber


def calculate_target_round():
    """
    현재 날짜를 기반으로 타겟 회차 계산

    로직:
    - 토요일 추첨일 기준
    - 일요일~금요일: 다음 토요일 (최신 회차 + 1)
    - 토요일 00:00 이후: 다음다음 토요일 (최신 회차 + 2)

    Returns:
        int: 타겟 회차 번호
    """
    # 최신 회차 가져오기
    latest_draw = LottoDraw.objects.order_by('-round_number').first()

    if not latest_draw:
        # 로또 데이터가 없는 경우 기본값
        return 1

    latest_round = latest_draw.round_number
    today = datetime.now().date()
    weekday = today.weekday()  # 월요일=0, 일요일=6

    # 토요일(5)인 경우
    if weekday == 5:
        # 토요일 00:00 이후면 다음다음 토요일 회차
        return latest_round + 2
    else:
        # 일요일~금요일이면 다음 토요일 회차
        return latest_round + 1


def check_duplicate_for_user_round(user, round_number, numbers):
    """
    특정 사용자가 동일한 번호를 이미 저장했는지 확인 (모든 회차 대상)

    Args:
        user: User 객체
        round_number (int): 타겟 회차 번호 (현재는 사용되지 않음, API 호환성 유지)
        numbers (list): 6개 번호 리스트 [1, 2, 3, 4, 5, 6]

    Returns:
        tuple: (중복 여부 bool, 기존 저장 회차 int 또는 None)
    """
    # 번호 정렬 (비교를 위해)
    sorted_numbers = sorted(numbers)

    # 해당 사용자의 모든 저장 번호들 가져오기 (회차 무관)
    existing_numbers = UserLottoNumber.objects.filter(
        user=user
    )

    for existing in existing_numbers:
        existing_sorted = existing.get_numbers_as_list()

        # 정렬된 번호가 일치하면 중복
        if sorted_numbers == existing_sorted:
            return (True, existing.round_number)

    return (False, None)


def get_user_generation_limit(user):
    """
    사용자의 번호 생성 제한 개수 반환

    Args:
        user: User 객체

    Returns:
        int: Prime/Gold는 -1 (무제한), 일반 사용자는 5
    """
    if user.is_prime or user.is_gold:
        return -1  # 무제한
    else:
        return 5  # 일반 사용자는 5개


def check_generation_limit(user, target_round):
    """
    사용자가 특정 회차에 더 번호를 생성할 수 있는지 확인

    Args:
        user: User 객체
        target_round (int): 타겟 회차 번호

    Returns:
        dict: {
            'can_generate': bool,
            'current_count': int,
            'limit': int,
            'remaining': int
        }
    """
    limit = get_user_generation_limit(user)

    # Prime/Gold 사용자는 무제한
    if limit == -1:
        return {
            'can_generate': True,
            'current_count': 0,
            'limit': -1,
            'remaining': -1
        }

    # 일반 사용자는 개수 체크
    current_count = UserLottoNumber.objects.filter(
        user=user,
        round_number=target_round
    ).count()

    can_generate = current_count < limit
    remaining = max(0, limit - current_count)

    return {
        'can_generate': can_generate,
        'current_count': current_count,
        'limit': limit,
        'remaining': remaining
    }
