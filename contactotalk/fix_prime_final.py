#!/usr/bin/env python
"""
Prime 사용자에게 관심사 추가 (최종 버전 - ID 사용)
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

# ID로 관심사 추가 (위에서 확인한 실제 데이터)
interest_ids = [
    100,  # 영어
    53,   # LOL
    1,    # 축구 (스포츠 첫번째일 것으로 예상)
    15,   # K-POP (음악 첫번째일 것으로 예상)
    63,   # 국내여행
]

# 관심사 추가
added_count = 0
for interest_id in interest_ids:
    try:
        interest = Interest.objects.get(id=interest_id)

        # 이미 있는지 확인
        if not UserInterest.objects.filter(user=user, interest=interest).exists():
            UserInterest.objects.create(user=user, interest=interest)
            added_count += 1
            print(f'✅ Added: ID {interest.id:3} - {interest.name:30} ({interest.get_category_display()})')
        else:
            print(f'⏭️  Already has: {interest.name}')

    except Interest.DoesNotExist:
        print(f'⚠️  Interest ID {interest_id} not found, skipping...')

# 현재 총 관심사 수
total_interests = UserInterest.objects.filter(user=user).count()

print(f'\n✅ Added {added_count} new interests to user "prime"')
print(f'📊 Total interests: {total_interests}')

if total_interests >= 3:
    print(f'✅ Minimum requirement met (3+ interests)')
else:
    print(f'⚠️  Warning: User has less than 3 interests (minimum required)')
