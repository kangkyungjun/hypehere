#!/usr/bin/env python
"""
Prime 사용자에게 관심사 추가 스크립트
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'contactotalk.settings')
django.setup()

from django.contrib.auth import get_user_model
from accounts.models import Interest

User = get_user_model()

# Prime 사용자 가져오기
try:
    user = User.objects.get(username='prime')
except User.DoesNotExist:
    print('❌ User "prime" does not exist.')
    exit(1)

# 기본 관심사 목록
default_interest_names = [
    'Language Exchange',
    'Travel',
    'Technology',
    'Music',
    'Sports'
]

# 관심사 추가
added_interests = []
for interest_name in default_interest_names:
    try:
        interest = Interest.objects.get(name=interest_name)
        user.interests.add(interest)
        added_interests.append(interest_name)
    except Interest.DoesNotExist:
        print(f'⚠️  Interest "{interest_name}" not found, skipping...')

print(f'✅ Added {len(added_interests)} interests to user "prime"')
print(f'   Interests: {", ".join(added_interests)}')
print(f'   Total interests: {user.interests.count()}')
