#!/usr/bin/env python
"""
Prime 사용자에게 관심사 추가 (수정 버전)
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'contactotalk.settings')
django.setup()

from django.contrib.auth import get_user_model
from accounts.models import Interest, UserInterest

User = get_user_model()

# Prime 사용자 가져오기
try:
    user = User.objects.get(username='prime')
except User.DoesNotExist:
    print('❌ User "prime" does not exist.')
    exit(1)

# 기본 관심사 한국어 이름 목록 (존재하는 것들로)
default_interest_names = [
    '영어',      # 공부/학습
    '여행',      # 독서/문학
    'AI',        # 기술/IT
    'K-POP',     # 음악
    '축구',      # 스포츠/운동
]

# 관심사 추가
added_count = 0
for interest_name in default_interest_names:
    try:
        # name_ko로 검색
        interest = Interest.objects.get(name_ko=interest_name)

        # 이미 있는지 확인
        if not UserInterest.objects.filter(user=user, interest=interest).exists():
            UserInterest.objects.create(user=user, interest=interest)
            added_count += 1
            print(f'✅ Added: {interest.name_ko} ({interest.get_category_display()})')
        else:
            print(f'⏭️  Already has: {interest.name_ko}')

    except Interest.DoesNotExist:
        print(f'⚠️  Interest "{interest_name}" not found, skipping...')

# 현재 총 관심사 수
total_interests = UserInterest.objects.filter(user=user).count()

print(f'\n✅ Added {added_count} new interests to user "prime"')
print(f'📊 Total interests: {total_interests}')

if total_interests < 3:
    print(f'⚠️  Warning: User has less than 3 interests (minimum required)')
