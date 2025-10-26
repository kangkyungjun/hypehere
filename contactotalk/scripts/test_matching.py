"""
매칭 시스템 테스트 스크립트
"""

import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "contactotalk.settings")
django.setup()

from accounts.models import User, Interest, UserInterest
from chat.models import ChatRoom, MatchingQueue
from chat.matcher import MatchingAlgorithm, MatchingService

def create_test_users():
    """테스트 사용자 생성"""

    print("\n" + "="*60)
    print("테스트 사용자 생성 중...")
    print("="*60)

    # 기존 테스트 사용자 삭제
    User.objects.filter(username__startswith="test_").delete()

    # 관심사 가져오기
    interests = {
        "축구": Interest.objects.get(name="축구"),
        "농구": Interest.objects.get(name="농구"),
        "K-POP": Interest.objects.get(name="K-POP"),
        "영화": Interest.objects.get(name="액션"),
        "요리": Interest.objects.get(name="요리하기"),
        "여행": Interest.objects.get(name="해외여행"),
        "코딩": Interest.objects.get(name="코딩"),
    }

    # 사용자 1: 한국, 축구/K-POP/영화
    user1 = User.objects.create_user(
        username="test_user1",
        email="test1@example.com",
        password="test1234!",
        nickname="축구팬",
        country_code="KOR",
        role=User.Role.USER
    )
    UserInterest.objects.create(user=user1, interest=interests["축구"])
    UserInterest.objects.create(user=user1, interest=interests["K-POP"])
    UserInterest.objects.create(user=user1, interest=interests["영화"])
    print(f"✅ {user1.nickname} (KOR) - 축구, K-POP, 영화")

    # 사용자 2: 한국, 축구/농구/코딩 (축구 1개 공통)
    user2 = User.objects.create_user(
        username="test_user2",
        email="test2@example.com",
        password="test1234!",
        nickname="스포츠맨",
        country_code="KOR",
        role=User.Role.USER
    )
    UserInterest.objects.create(user=user2, interest=interests["축구"])
    UserInterest.objects.create(user=user2, interest=interests["농구"])
    UserInterest.objects.create(user=user2, interest=interests["코딩"])
    print(f"✅ {user2.nickname} (KOR) - 축구, 농구, 코딩")

    # 사용자 3: 미국, 축구/K-POP/영화 (3개 모두 공통)
    user3 = User.objects.create_user(
        username="test_user3",
        email="test3@example.com",
        password="test1234!",
        nickname="K팝러버",
        country_code="USA",
        role=User.Role.USER
    )
    UserInterest.objects.create(user=user3, interest=interests["축구"])
    UserInterest.objects.create(user=user3, interest=interests["K-POP"])
    UserInterest.objects.create(user=user3, interest=interests["영화"])
    print(f"✅ {user3.nickname} (USA) - 축구, K-POP, 영화")

    # 사용자 4: 일본, 요리/여행/코딩 (공통 관심사 없음)
    user4 = User.objects.create_user(
        username="test_user4",
        email="test4@example.com",
        password="test1234!",
        nickname="여행가",
        country_code="JPN",
        role=User.Role.USER
    )
    UserInterest.objects.create(user=user4, interest=interests["요리"])
    UserInterest.objects.create(user=user4, interest=interests["여행"])
    UserInterest.objects.create(user=user4, interest=interests["코딩"])
    print(f"✅ {user4.nickname} (JPN) - 요리, 여행, 코딩")

    return [user1, user2, user3, user4]


def test_matching_algorithm():
    """매칭 알고리즘 테스트"""

    print("\n" + "="*60)
    print("매칭 점수 계산 테스트")
    print("="*60)

    users = User.objects.filter(username__startswith="test_").order_by('id')
    user1, user2, user3, user4 = users

    # 테스트 1: 같은 국가 + 1개 공통 관심사
    score_1_2 = MatchingAlgorithm.calculate_matching_score(user1, user2)
    print(f"\n1. {user1.nickname}(KOR) ↔ {user2.nickname}(KOR)")
    print(f"   - 같은 국가: 50점")
    print(f"   - 공통 관심사 1개 (축구): 10점 × 2 = 20점")
    print(f"   - 예상 점수: 70점")
    print(f"   - 실제 점수: {score_1_2}점")
    print(f"   - {'✅ 통과' if score_1_2 == 70 else '❌ 실패'}")

    # 테스트 2: 다른 국가 + 3개 공통 관심사
    score_1_3 = MatchingAlgorithm.calculate_matching_score(user1, user3)
    print(f"\n2. {user1.nickname}(KOR) ↔ {user3.nickname}(USA)")
    print(f"   - 다른 국가: 30점")
    print(f"   - 공통 관심사 3개 (축구, K-POP, 영화): 30점 × 2 = 60점")
    print(f"   - 예상 점수: 90점")
    print(f"   - 실제 점수: {score_1_3}점")
    print(f"   - {'✅ 통과' if score_1_3 == 90 else '❌ 실패'}")

    # 테스트 3: 다른 국가 + 공통 관심사 없음
    score_1_4 = MatchingAlgorithm.calculate_matching_score(user1, user4)
    print(f"\n3. {user1.nickname}(KOR) ↔ {user4.nickname}(JPN)")
    print(f"   - 다른 국가: 30점")
    print(f"   - 공통 관심사 0개: 0점 × 2 = 0점")
    print(f"   - 예상 점수: 30점")
    print(f"   - 실제 점수: {score_1_4}점")
    print(f"   - {'✅ 통과' if score_1_4 == 30 else '❌ 실패'}")

    # 테스트 4: 같은 국가 + 1개 공통 관심사 (코딩)
    score_2_4 = MatchingAlgorithm.calculate_matching_score(user2, user4)
    print(f"\n4. {user2.nickname}(KOR) ↔ {user4.nickname}(JPN)")
    print(f"   - 다른 국가: 30점")
    print(f"   - 공통 관심사 1개 (코딩): 10점 × 2 = 20점")
    print(f"   - 예상 점수: 50점")
    print(f"   - 실제 점수: {score_2_4}점")
    print(f"   - {'✅ 통과' if score_2_4 == 50 else '❌ 실패'}")

    return all([
        score_1_2 == 70,
        score_1_3 == 90,
        score_1_4 == 30,
        score_2_4 == 50,
    ])


def test_matching_service():
    """매칭 서비스 테스트"""

    print("\n" + "="*60)
    print("매칭 서비스 테스트")
    print("="*60)

    # 기존 매칭 큐와 채팅방 삭제
    MatchingQueue.objects.all().delete()
    ChatRoom.objects.all().delete()

    users = User.objects.filter(username__startswith="test_").order_by('id')
    user1, user2, user3, user4 = users

    # 테스트 1: 대기열에 추가
    print("\n1. 대기열에 사용자 추가")
    MatchingService.add_to_queue(user2, country_preference="KOR")
    MatchingService.add_to_queue(user3, country_preference=None)
    MatchingService.add_to_queue(user4, country_preference="KOR")

    queue_count = MatchingQueue.objects.count()
    print(f"   - 대기열 인원: {queue_count}명")
    print(f"   - {'✅ 통과' if queue_count == 3 else '❌ 실패'}")

    # 테스트 2: User1 매칭 시도 (User3과 매칭되어야 함 - 점수 90점)
    print("\n2. User1 매칭 시도")
    success, room, message = MatchingService.process_matching(user1, country_preference=None)

    if success:
        print(f"   - 매칭 성공: {message}")
        print(f"   - 매칭 상대: {room.get_other_user(user1).nickname}")
        print(f"   - 매칭 점수: {room.matching_score}점")

        # User3이 매칭되었는지 확인 (점수가 가장 높음)
        other_user = room.get_other_user(user1)
        is_correct = other_user == user3 and room.matching_score == 90
        print(f"   - {'✅ 통과 (User3과 90점으로 매칭)' if is_correct else '❌ 실패'}")
    else:
        print(f"   - 매칭 실패: {message}")
        print(f"   - ❌ 실패")

    # 테스트 3: 남은 대기열 확인
    remaining_count = MatchingQueue.objects.count()
    print(f"\n3. 남은 대기열: {remaining_count}명")
    print(f"   - {'✅ 통과 (User2, User4 남음)' if remaining_count == 2 else '❌ 실패'}")

    # 테스트 4: 매칭 횟수 증가 확인
    user1.refresh_from_db()
    user3.refresh_from_db()
    print(f"\n4. 매칭 횟수 증가 확인")
    print(f"   - User1 매칭 횟수: {user1.daily_match_count}")
    print(f"   - User3 매칭 횟수: {user3.daily_match_count}")
    print(f"   - {'✅ 통과' if user1.daily_match_count == 1 and user3.daily_match_count == 1 else '❌ 실패'}")

    return all([
        queue_count == 3,
        success and room.get_other_user(user1) == user3 and room.matching_score == 90,
        remaining_count == 2,
        user1.daily_match_count == 1 and user3.daily_match_count == 1,
    ])


def run_all_tests():
    """모든 테스트 실행"""

    print("\n" + "🚀 " + "="*56 + " 🚀")
    print("🧪 ConTacToTalk 매칭 시스템 테스트 시작")
    print("🚀 " + "="*56 + " 🚀")

    # 테스트 사용자 생성
    create_test_users()

    # 매칭 알고리즘 테스트
    algo_result = test_matching_algorithm()

    # 매칭 서비스 테스트
    service_result = test_matching_service()

    # 결과 출력
    print("\n" + "="*60)
    print("📊 테스트 결과 요약")
    print("="*60)
    print(f"매칭 알고리즘: {'✅ 통과' if algo_result else '❌ 실패'}")
    print(f"매칭 서비스: {'✅ 통과' if service_result else '❌ 실패'}")

    if algo_result and service_result:
        print("\n🎉 모든 테스트 통과! 매칭 시스템이 정상 작동합니다.")
    else:
        print("\n⚠️  일부 테스트 실패. 로그를 확인하세요.")

    print("="*60 + "\n")


if __name__ == "__main__":
    run_all_tests()
