#!/usr/bin/env python
"""
개발용 슈퍼유저를 자동으로 생성하는 스크립트
실행 방법: python scripts/create_superuser.py
"""

import os
import sys
import django

# Django 설정
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hypehere.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

def main():
    print("🔑 개발용 슈퍼유저 생성 중...\n")

    # 기본 슈퍼유저 정보
    username = "admin"
    email = "admin@hypehere.com"
    password = "admin123"  # 개발용 비밀번호

    # 이미 존재하는지 확인
    if User.objects.filter(username=username).exists():
        user = User.objects.get(username=username)
        print(f"ℹ️  슈퍼유저가 이미 존재합니다: {username}")

        # 슈퍼유저 권한 확인 및 부여
        if not user.is_superuser:
            user.is_superuser = True
            user.is_staff = True
            user.save()
            print(f"✅ {username}에게 슈퍼유저 권한을 부여했습니다.")
    else:
        # 새 슈퍼유저 생성
        user = User.objects.create_superuser(
            username=username,
            email=email,
            password=password
        )
        print(f"✅ 슈퍼유저가 생성되었습니다!")

    print(f"\n📋 슈퍼유저 정보:")
    print(f"   - 사용자명: {user.username}")
    print(f"   - 이메일: {user.email}")
    print(f"   - 비밀번호: {password}")
    print(f"   - ID: {user.id}")

    print(f"\n🌐 Django Admin 접속:")
    print(f"   URL: http://127.0.0.1:8001/admin/")
    print(f"   로그인: {username} / {password}")

    print("\n⚠️  주의: 이는 개발용 계정입니다. 프로덕션에서는 강력한 비밀번호를 사용하세요!")
    print("✨ 완료!")

if __name__ == "__main__":
    main()
