#!/usr/bin/env python
"""
Prime 슈퍼유저 생성 스크립트
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'contactotalk.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

username = 'prime'
email = 'prime@contactotalk.com'
password = 'Prime2025!@#'

# 이미 존재하는지 확인
if User.objects.filter(username=username).exists():
    print(f'❌ User "{username}" already exists.')
    existing_user = User.objects.get(username=username)
    print(f'   - is_superuser: {existing_user.is_superuser}')
    print(f'   - is_staff: {existing_user.is_staff}')
else:
    # 슈퍼유저 생성
    user = User.objects.create_superuser(
        username=username,
        email=email,
        password=password
    )

    print('✅ Superuser created successfully!')
    print(f'   - Username: {username}')
    print(f'   - Password: {password}')
    print(f'   - Email: {email}')
    print(f'   - Superuser: True')
    print(f'   - Staff: True')
