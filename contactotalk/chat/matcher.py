"""
매칭 알고리즘 모듈

기획서 기준:
- 매칭 점수 = location_weight + interest_overlap * 2
- location_weight: 같은 국가면 50점, 다르면 30점
- interest_overlap: 공통 관심사 개수 * 10점
"""

from django.db import transaction
from django.db.models import Q, Count
from accounts.models import UserInterest
from .models import MatchingQueue, ChatRoom, BlockedUser


class MatchingAlgorithm:
    """랜덤 매칭 알고리즘"""

    @staticmethod
    def calculate_matching_score(user1, user2):
        """두 사용자 간의 매칭 점수 계산"""

        # 1. 위치 가중치 (같은 국가면 50점, 다르면 30점)
        if user1.country_code == user2.country_code:
            location_weight = 50
        else:
            location_weight = 30

        # 2. 관심사 중복도 계산
        user1_interests = set(
            UserInterest.objects.filter(user=user1).values_list("interest_id", flat=True)
        )
        user2_interests = set(
            UserInterest.objects.filter(user=user2).values_list("interest_id", flat=True)
        )

        # 공통 관심사 개수
        common_interests = user1_interests.intersection(user2_interests)
        interest_overlap = len(common_interests) * 10

        # 3. 최종 점수 = location_weight + interest_overlap * 2
        matching_score = location_weight + (interest_overlap * 2)

        return matching_score

    @staticmethod
    def is_blocked(user1, user2):
        """두 사용자가 서로 차단했는지 확인"""
        return BlockedUser.objects.filter(
            Q(user=user1, blocked_user=user2) | Q(user=user2, blocked_user=user1)
        ).exists()

    @staticmethod
    def has_active_room(user1, user2):
        """두 사용자 간에 이미 활성 채팅방이 있는지 확인"""
        return ChatRoom.objects.filter(
            Q(user1=user1, user2=user2) | Q(user1=user2, user2=user1),
            is_active=True,
        ).exists()

    @classmethod
    def find_match(cls, user, country_preference=None, gender_preference=None):
        """
        사용자에게 맞는 상대를 찾습니다.

        매칭 우선순위:
        1. 차단된 사용자 제외
        2. 이미 활성 채팅방이 있는 사용자 제외 (단, 본인이 나간 방은 제외)
        3. 국가 필터링 (선택 시 해당 국가만)
        4. 성별 필터링 (선택 시 해당 성별만)
        5. 매칭 점수가 높은 순
        6. 대기열 선입선출 (FIFO)

        Args:
            user: 매칭을 원하는 사용자
            country_preference: 선호 국가 코드 (optional)
            gender_preference: 선호 성별 (optional, male/female)

        Returns:
            매칭된 사용자 또는 None
        """

        # 차단한/차단된 사용자 목록
        blocked_ids = list(
            BlockedUser.objects.filter(
                Q(user=user) | Q(blocked_user=user)
            ).values_list("blocked_user_id", "user_id")
        )
        blocked_user_ids = set()
        for blocked_id, user_id in blocked_ids:
            blocked_user_ids.add(blocked_id)
            blocked_user_ids.add(user_id)

        # 이미 활성 채팅방이 있는 사용자 목록 (본인이 나가지 않은 방만)
        active_rooms = ChatRoom.objects.filter(
            Q(user1=user) | Q(user2=user),
            is_active=True,
        )

        active_user_ids = set()
        for room in active_rooms:
            # 본인이 user1인 경우
            if room.user1 == user:
                # user1_left가 False인 경우에만 상대방(user2)을 제외
                if not room.user1_left:
                    active_user_ids.add(room.user2_id)
            # 본인이 user2인 경우
            elif room.user2 == user:
                # user2_left가 False인 경우에만 상대방(user1)을 제외
                if not room.user2_left:
                    active_user_ids.add(room.user1_id)

        # 제외할 사용자 ID 목록
        excluded_ids = blocked_user_ids.union(active_user_ids)
        excluded_ids.add(user.id)  # 본인 제외

        # 대기열에서 후보 검색
        candidates = MatchingQueue.objects.exclude(
            user_id__in=excluded_ids
        ).select_related("user")

        # 국가 필터링 (선택 시 해당 국가만)
        if country_preference and country_preference.strip():
            candidates = candidates.filter(user__country_code=country_preference)

        # 성별 필터링 (선택 시 해당 성별만)
        if gender_preference and gender_preference.strip():
            candidates = candidates.filter(user__gender=gender_preference)

        # 매칭 점수 계산 및 정렬
        scored_candidates = []
        for candidate in candidates[:50]:  # 성능을 위해 상위 50명만 계산
            score = cls.calculate_matching_score(user, candidate.user)
            scored_candidates.append((candidate.user, score))

        # 점수 기준 내림차순 정렬
        scored_candidates.sort(key=lambda x: x[1], reverse=True)

        # 가장 높은 점수의 사용자 반환
        if scored_candidates:
            return scored_candidates[0][0]

        return None

    @classmethod
    @transaction.atomic
    def create_match(cls, user1, user2, country_code=None):
        """
        매칭된 두 사용자 간의 채팅방을 생성합니다.

        Args:
            user1: 첫 번째 사용자
            user2: 두 번째 사용자
            country_code: 매칭 기준 국가 코드

        Returns:
            생성된 ChatRoom 객체
        """

        # 매칭 점수 계산
        matching_score = cls.calculate_matching_score(user1, user2)

        # 채팅방 생성
        room = ChatRoom.objects.create(
            user1=user1,
            user2=user2,
            country_code=country_code,
            matching_score=matching_score,
        )

        # 대기열에서 제거
        MatchingQueue.objects.filter(user__in=[user1, user2]).delete()

        # 매칭 카운트 증가
        user1.increment_match_count()
        user2.increment_match_count()

        return room


class MatchingService:
    """매칭 서비스 - 대기열 관리 및 매칭 처리"""

    @staticmethod
    def add_to_queue(user, country_preference=None):
        """
        사용자를 매칭 대기열에 추가합니다.

        Args:
            user: 대기열에 추가할 사용자
            country_preference: 선호 국가 코드 (optional)

        Returns:
            MatchingQueue 객체
        """

        # 이미 대기 중이면 업데이트
        queue, created = MatchingQueue.objects.update_or_create(
            user=user,
            defaults={"country_preference": country_preference},
        )

        return queue

    @staticmethod
    def remove_from_queue(user):
        """
        사용자를 매칭 대기열에서 제거합니다.

        Args:
            user: 제거할 사용자

        Returns:
            삭제된 개수
        """
        return MatchingQueue.objects.filter(user=user).delete()[0]

    @staticmethod
    def get_queue_position(user):
        """
        사용자의 대기열 위치를 반환합니다.

        Args:
            user: 확인할 사용자

        Returns:
            대기열 위치 (1부터 시작), 대기 중이 아니면 None
        """
        try:
            queue = MatchingQueue.objects.get(user=user)
            position = MatchingQueue.objects.filter(
                created_at__lt=queue.created_at
            ).count() + 1
            return position
        except MatchingQueue.DoesNotExist:
            return None

    @classmethod
    @transaction.atomic
    def process_matching(cls, user, country_preference=None, gender_preference=None):
        """
        매칭 프로세스를 처리합니다.

        1. 대기열에 추가
        2. 즉시 매칭 시도
        3. 매칭 성공 시 채팅방 생성, 실패 시 대기

        Args:
            user: 매칭을 원하는 사용자
            country_preference: 선호 국가 코드 (optional)
            gender_preference: 선호 성별 (optional, male/female)

        Returns:
            (success: bool, room: ChatRoom or None, message: str)
        """

        # 1. 매칭 가능 여부 확인
        if not user.can_match_today():
            return (
                False,
                None,
                "오늘의 매칭 횟수를 모두 사용했습니다. 프리미엄으로 업그레이드하세요.",
            )

        # 2. 대기열에 추가
        cls.add_to_queue(user, country_preference)

        # 3. 즉시 매칭 시도
        matched_user = MatchingAlgorithm.find_match(user, country_preference, gender_preference)

        if matched_user:
            # 매칭 성공 - 채팅방 생성
            room = MatchingAlgorithm.create_match(
                user, matched_user, country_preference
            )
            return (True, room, "매칭되었습니다!")

        # 매칭 실패 - 대기열에서 대기
        position = cls.get_queue_position(user)
        return (
            False,
            None,
            f"매칭 대기 중입니다. 현재 대기 순위: {position}",
        )
