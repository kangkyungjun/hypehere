"""
국가별 기본 오픈 채팅방 생성 스크립트
"""

import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "contactotalk.settings")
django.setup()

from chat.models import OpenChatRoom

# 주요 국가 목록 (ISO 3166-1 alpha-3)
COUNTRIES = {
    "KOR": "대한민국 🇰🇷",
    "USA": "United States 🇺🇸",
    "JPN": "日本 🇯🇵",
    "CHN": "中国 🇨🇳",
    "GBR": "United Kingdom 🇬🇧",
    "FRA": "France 🇫🇷",
    "DEU": "Germany 🇩🇪",
    "ESP": "Spain 🇪🇸",
    "ITA": "Italy 🇮🇹",
    "RUS": "Russia 🇷🇺",
    "BRA": "Brazil 🇧🇷",
    "CAN": "Canada 🇨🇦",
    "AUS": "Australia 🇦🇺",
    "IND": "India 🇮🇳",
    "MEX": "Mexico 🇲🇽",
    "THA": "Thailand 🇹🇭",
    "VNM": "Vietnam 🇻🇳",
    "PHL": "Philippines 🇵🇭",
    "SGP": "Singapore 🇸🇬",
    "NLD": "Netherlands 🇳🇱",
}


def create_default_rooms():
    """국가별 기본 채팅방 생성"""

    print("\n" + "=" * 60)
    print("국가별 기본 오픈 채팅방 생성")
    print("=" * 60)

    created_count = 0
    skipped_count = 0

    for country_code, country_name in COUNTRIES.items():
        # 이미 해당 국가의 기본방이 있는지 확인
        existing = OpenChatRoom.objects.filter(
            country_code=country_code, room_type=OpenChatRoom.RoomType.DEFAULT
        ).exists()

        if existing:
            print(f"⏭️  {country_name} - 이미 존재함")
            skipped_count += 1
            continue

        # 기본 채팅방 생성
        room = OpenChatRoom.objects.create(
            room_type=OpenChatRoom.RoomType.DEFAULT,
            title=f"{country_name} 오픈 채팅",
            description=f"{country_name} 사용자들을 위한 기본 오픈 채팅방입니다. 자유롭게 대화를 나누세요!",
            country_code=country_code,
            creator=None,  # 기본방은 생성자 없음
            category="일반",
            tags="기본방, 국가별",
            max_participants=0,  # 무제한
            is_active=True,
        )

        print(f"✅ {country_name} - 생성 완료 (Room #{room.id})")
        created_count += 1

    # 전 세계 공용 채팅방 생성
    global_room_code = "WLD"
    existing_global = OpenChatRoom.objects.filter(
        country_code=global_room_code, room_type=OpenChatRoom.RoomType.DEFAULT
    ).exists()

    if not existing_global:
        global_room = OpenChatRoom.objects.create(
            room_type=OpenChatRoom.RoomType.DEFAULT,
            title="🌍 Global Chat / 全球聊天 / グローバルチャット",
            description="Welcome to the global chat room! Connect with people from all around the world. 전 세계 사람들과 대화하세요!",
            country_code=global_room_code,
            creator=None,
            category="국제",
            tags="기본방, 전세계, 국제, global",
            max_participants=0,
            is_active=True,
        )
        print(f"✅ 🌍 Global Chat - 생성 완료 (Room #{global_room.id})")
        created_count += 1
    else:
        print(f"⏭️  🌍 Global Chat - 이미 존재함")
        skipped_count += 1

    # 결과 출력
    print("\n" + "=" * 60)
    print(f"✅ {created_count}개의 기본 채팅방이 생성되었습니다.")
    print(f"⏭️  {skipped_count}개의 채팅방은 이미 존재합니다.")

    total_count = OpenChatRoom.objects.filter(
        room_type=OpenChatRoom.RoomType.DEFAULT
    ).count()
    print(f"📊 현재 총 {total_count}개의 기본 채팅방이 있습니다.")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    create_default_rooms()
