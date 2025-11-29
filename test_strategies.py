#!/usr/bin/env python
"""Test script for lottery strategy APIs"""
import os
import django
import sys

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hypehere.settings')
django.setup()

from accounts.models import User
from analytics.api_views import (
    _generate_strategy1_numbers,
    _generate_strategy2_numbers,
    _generate_strategy3_numbers,
    _generate_strategy4_numbers
)

def test_strategies():
    print("=" * 60)
    print("로또 추가 전략 번호 생성 테스트")
    print("=" * 60)

    strategies = [
        ("추가전략 1 (빈출 번호)", _generate_strategy1_numbers),
        ("추가전략 2 (홀짝 비율)", _generate_strategy2_numbers),
        ("추가전략 3 (범위 분산)", _generate_strategy3_numbers),
        ("추가전략 4 (연속 제한)", _generate_strategy4_numbers),
    ]

    for name, func in strategies:
        print(f"\n{name}")
        print("-" * 60)
        try:
            numbers = func()
            if numbers:
                print(f"✅ 생성 성공: {numbers}")
                print(f"   - 번호 개수: {len(numbers)}")
                print(f"   - 중복 여부: {'중복 없음' if len(set(numbers)) == 6 else '중복 있음'}")
                print(f"   - 범위 검증: {'정상 (1-45)' if all(1 <= n <= 45 for n in numbers) else '범위 오류'}")
            else:
                print(f"⚠️  번호 생성 실패 (조건을 만족하는 조합을 찾지 못함)")
        except Exception as e:
            print(f"❌ 에러 발생: {str(e)}")

    print("\n" + "=" * 60)
    print("테스트 완료")
    print("=" * 60)

if __name__ == '__main__':
    test_strategies()
