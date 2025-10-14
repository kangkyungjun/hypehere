#!/usr/bin/env python
"""
관심사 데이터 확인 (모든 필드)
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'contactotalk.settings')
django.setup()

from accounts.models import Interest

# 처음 20개만 출력
interests = Interest.objects.all()[:20]

print("📋 First 20 Interests:")
print("-" * 100)
for interest in interests:
    print(f"  ID: {interest.id:3} | name: {interest.name:30} | name_ko: {interest.name_ko:20} | name_en: {interest.name_en:20} | category: {interest.get_category_display()}")
print("-" * 100)
print(f"Total: {Interest.objects.count()} interests")
