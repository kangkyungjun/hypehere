"""
관심사 데이터 생성 스크립트
16개 카테고리, 100개 이상의 관심사 항목
"""

import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "contactotalk.settings")
django.setup()

from accounts.models import Interest

# 관심사 데이터 (16개 카테고리)
INTERESTS_DATA = {
    "sports": [
        "축구", "농구", "야구", "배구", "테니스", "탁구", "배드민턴",
        "골프", "수영", "달리기", "등산", "자전거", "요가", "필라테스"
    ],
    "music": [
        "K-POP", "팝", "힙합", "R&B", "재즈", "클래식", "록", "인디",
        "EDM", "발라드", "트로트", "OST", "악기연주", "노래부르기"
    ],
    "movie": [
        "액션", "코미디", "로맨스", "SF", "스릴러", "공포", "드라마",
        "애니메이션", "다큐멘터리", "뮤지컬", "범죄", "판타지"
    ],
    "book": [
        "소설", "시", "에세이", "자기계발", "경제/경영", "역사", "과학",
        "철학", "심리학", "여행", "요리", "만화/웹툰"
    ],
    "game": [
        "LOL", "배틀그라운드", "오버워치", "피파", "마인크래프트",
        "모바일게임", "닌텐도", "플레이스테이션", "PC게임", "보드게임"
    ],
    "travel": [
        "국내여행", "해외여행", "배낭여행", "캠핑", "등산", "섬여행",
        "도시여행", "맛집투어", "문화유적", "자연경관", "호캉스", "워케이션"
    ],
    "food": [
        "한식", "중식", "일식", "양식", "이탈리안", "멕시칸", "베트남음식",
        "태국음식", "디저트", "카페", "맥주", "와인", "위스키", "칵테일", "요리하기"
    ],
    "art": [
        "그림그리기", "사진촬영", "조각", "서예", "전시회", "갤러리",
        "미술관", "디자인", "일러스트", "캘리그라피", "공예"
    ],
    "study": [
        "영어", "중국어", "일본어", "스페인어", "프랑스어", "독일어",
        "코딩", "자격증", "취업준비", "대학원", "MBA", "온라인강의"
    ],
    "tech": [
        "AI", "블록체인", "가상화폐", "프로그래밍", "웹개발", "앱개발",
        "데이터분석", "보안", "클라우드", "IoT", "로봇", "VR/AR"
    ],
    "fashion": [
        "스트릿패션", "빈티지", "럭셔리", "미니멀", "스포티", "캐주얼",
        "포멀", "뷰티", "메이크업", "헤어스타일", "네일아트", "액세서리"
    ],
    "pet": [
        "강아지", "고양이", "햄스터", "토끼", "앵무새", "물고기",
        "파충류", "반려동물훈련", "동물병원", "펫카페", "펫샵"
    ],
    "volunteer": [
        "환경보호", "동물보호", "아동복지", "노인복지", "장애인지원",
        "해외봉사", "재능기부", "헌혈", "기부", "사회운동"
    ],
    "invest": [
        "주식", "펀드", "부동산", "채권", "금", "외환", "ETF",
        "코인", "경제뉴스", "재테크", "절약", "저축"
    ],
    "hobby": [
        "수집", "모형제작", "퍼즐", "레고", "낚시", "드론", "천체관측",
        "원예", "인테리어", "DIY", "핸드메이드", "뜨개질", "자수"
    ],
    "culture": [
        "공연", "연극", "뮤지컬", "콘서트", "페스티벌", "전통문화",
        "K-문화", "역사탐방", "박물관", "문화센터", "강연"
    ]
}

def populate_interests():
    """관심사 데이터베이스 채우기"""

    created_count = 0

    for category_key, items in INTERESTS_DATA.items():
        # 카테고리명 한글 변환
        category_names = {
            "sports": "스포츠/운동",
            "music": "음악",
            "movie": "영화/드라마",
            "book": "독서/문학",
            "game": "게임",
            "travel": "여행",
            "food": "음식/요리",
            "art": "예술/미술",
            "study": "공부/학습",
            "tech": "기술/IT",
            "fashion": "패션/뷰티",
            "pet": "반려동물",
            "volunteer": "봉사/사회활동",
            "invest": "투자/재테크",
            "hobby": "취미/여가",
            "culture": "문화/공연"
        }

        category_name = category_names.get(category_key, category_key)

        for item in items:
            interest, created = Interest.objects.get_or_create(
                name=item,
                defaults={"category": category_name}
            )
            if created:
                created_count += 1
                print(f"✅ Created: {category_name} - {item}")
            else:
                print(f"⏭️  Already exists: {category_name} - {item}")

    total_count = Interest.objects.count()
    print(f"\n{'='*60}")
    print(f"✅ 총 {created_count}개의 관심사가 추가되었습니다.")
    print(f"📊 데이터베이스에 총 {total_count}개의 관심사가 있습니다.")
    print(f"{'='*60}")

if __name__ == "__main__":
    populate_interests()
