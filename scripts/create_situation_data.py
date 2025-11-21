"""
Create sample situation-based learning data
Run with: python scripts/create_situation_data.py
"""
import os
import sys
import django

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hypehere.settings')
django.setup()

from learning.models import SituationCategory, SituationLesson, SituationExpression


def create_categories():
    """Create 7 main situation categories"""
    categories_data = [
        {
            'code': 'daily',
            'name_ko': '일상생활',
            'name_en': 'Daily Life',
            'icon': '🏠',
            'description': '일상생활에서 자주 사용하는 표현들',
            'order': 1
        },
        {
            'code': 'travel',
            'name_ko': '여행',
            'name_en': 'Travel',
            'icon': '✈️',
            'description': '여행 중 필요한 실용적인 표현들',
            'order': 2
        },
        {
            'code': 'business',
            'name_ko': '비즈니스',
            'name_en': 'Business',
            'icon': '💼',
            'description': '업무 환경에서 사용하는 전문적인 표현들',
            'order': 3
        },
        {
            'code': 'academic',
            'name_ko': '학업',
            'name_en': 'Academic',
            'icon': '📚',
            'description': '학교와 학습 환경에서 필요한 표현들',
            'order': 4
        },
        {
            'code': 'social',
            'name_ko': '사교/친구',
            'name_en': 'Social',
            'icon': '👥',
            'description': '친구 및 사교 모임에서 사용하는 표현들',
            'order': 5
        },
        {
            'code': 'health',
            'name_ko': '건강/의료',
            'name_en': 'Health',
            'icon': '🏥',
            'description': '병원 방문 및 건강 관련 표현들',
            'order': 6
        },
        {
            'code': 'work',
            'name_ko': '직장생활',
            'name_en': 'Work Life',
            'icon': '🏢',
            'description': '직장에서의 일상적인 업무 표현들',
            'order': 7
        }
    ]

    categories = {}
    for cat_data in categories_data:
        category, created = SituationCategory.objects.get_or_create(
            code=cat_data['code'],
            defaults=cat_data
        )
        categories[cat_data['code']] = category
        print(f"{'Created' if created else 'Found'} category: {category}")

    return categories


def create_daily_lessons(category):
    """Create sample lessons for daily life category"""

    # Lesson 1: Self Introduction
    lesson1, created = SituationLesson.objects.get_or_create(
        category=category,
        slug='jagisokaehagi',
        defaults={
            'title_ko': '자기소개하기',
            'title_en': 'Introducing Yourself',
            'language': 'EN',
            'order': 1
        }
    )
    print(f"{'Created' if created else 'Found'} lesson: {lesson1}")

    if created:
        expressions = [
            {
                'expression': '안녕하세요, 저는 김민수입니다.',
                'translation': "Hello, I'm Minsu Kim.",
                'pronunciation': '헬로우, 아임 민수 킴',
                'situation_context': '처음 만난 사람에게 자신을 소개할 때',
                'vocabulary': [
                    {'word': 'Hello', 'meaning': '안녕하세요', 'example': 'Hello, nice to meet you.'},
                    {'word': "I'm", 'meaning': '저는 (I am의 축약형)', 'example': "I'm a student."},
                    {'word': 'name', 'meaning': '이름', 'example': 'My name is John.'}
                ],
                'order': 1
            },
            {
                'expression': '만나서 반갑습니다.',
                'translation': 'Nice to meet you.',
                'pronunciation': '나이스 투 밋 유',
                'situation_context': '인사를 나눈 후 바로 사용',
                'vocabulary': [
                    {'word': 'Nice', 'meaning': '좋은, 반가운', 'example': "It's nice to see you."},
                    {'word': 'meet', 'meaning': '만나다', 'example': "Let's meet tomorrow."},
                    {'word': 'you', 'meaning': '당신', 'example': 'How are you?'}
                ],
                'order': 2
            },
            {
                'expression': '저는 한국에서 왔어요.',
                'translation': "I'm from Korea.",
                'pronunciation': '아임 프롬 코리아',
                'situation_context': '출신 국가를 말할 때',
                'vocabulary': [
                    {'word': 'from', 'meaning': '~에서 온', 'example': 'Where are you from?'},
                    {'word': 'Korea', 'meaning': '한국', 'example': 'I love Korea.'},
                    {'word': 'country', 'meaning': '국가', 'example': 'What country are you from?'}
                ],
                'order': 3
            },
            {
                'expression': '저는 회사원이에요.',
                'translation': "I'm an office worker.",
                'pronunciation': '아임 앤 오피스 워커',
                'situation_context': '직업을 소개할 때',
                'vocabulary': [
                    {'word': 'office', 'meaning': '사무실', 'example': 'I work in an office.'},
                    {'word': 'worker', 'meaning': '직원, 근로자', 'example': 'She is a hard worker.'},
                    {'word': 'job', 'meaning': '직업', 'example': "What's your job?"}
                ],
                'order': 4
            },
            {
                'expression': '취미는 음악 듣기예요.',
                'translation': 'My hobby is listening to music.',
                'pronunciation': '마이 하비 이즈 리스닝 투 뮤직',
                'situation_context': '취미에 대해 이야기할 때',
                'vocabulary': [
                    {'word': 'hobby', 'meaning': '취미', 'example': 'What is your hobby?'},
                    {'word': 'listen', 'meaning': '듣다', 'example': 'I listen to music.'},
                    {'word': 'music', 'meaning': '음악', 'example': 'I love music.'}
                ],
                'order': 5
            }
        ]

        for expr_data in expressions:
            SituationExpression.objects.create(lesson=lesson1, **expr_data)
            print(f"  Added expression: {expr_data['expression']}")

    # Lesson 2: Restaurant
    lesson2, created = SituationLesson.objects.get_or_create(
        category=category,
        slug='sikdangeseo-jumunhagi',
        defaults={
            'title_ko': '식당에서 주문하기',
            'title_en': 'Ordering at a Restaurant',
            'language': 'EN',
            'order': 2
        }
    )
    print(f"{'Created' if created else 'Found'} lesson: {lesson2}")

    if created:
        expressions = [
            {
                'expression': '메뉴판 좀 볼 수 있을까요?',
                'translation': 'Can I see the menu, please?',
                'pronunciation': '캔 아이 씨 더 메뉴, 플리즈?',
                'situation_context': '식당에 앉아서 메뉴를 요청할 때',
                'vocabulary': [
                    {'word': 'Can I', 'meaning': '~해도 될까요?', 'example': 'Can I help you?'},
                    {'word': 'see', 'meaning': '보다', 'example': 'I want to see it.'},
                    {'word': 'menu', 'meaning': '메뉴판', 'example': 'The menu looks good.'},
                    {'word': 'please', 'meaning': '부탁합니다', 'example': 'Help me, please.'}
                ],
                'order': 1
            },
            {
                'expression': '이거 하나 주세요.',
                'translation': "I'll have this one, please.",
                'pronunciation': '아일 해브 디스 원, 플리즈',
                'situation_context': '메뉴를 가리키며 주문할 때',
                'vocabulary': [
                    {'word': "I'll have", 'meaning': '~을 주세요 (주문)', 'example': "I'll have coffee."},
                    {'word': 'this', 'meaning': '이것', 'example': 'I like this.'},
                    {'word': 'one', 'meaning': '하나', 'example': 'Give me one.'}
                ],
                'order': 2
            },
            {
                'expression': '물 좀 더 주실 수 있나요?',
                'translation': 'Could I get more water, please?',
                'pronunciation': '쿠드 아이 겟 모어 워터, 플리즈?',
                'situation_context': '추가로 물이 필요할 때',
                'vocabulary': [
                    {'word': 'Could I', 'meaning': '~해도 될까요? (정중)', 'example': 'Could I ask you something?'},
                    {'word': 'get', 'meaning': '받다, 얻다', 'example': 'Can I get help?'},
                    {'word': 'more', 'meaning': '더 많은', 'example': 'I need more time.'},
                    {'word': 'water', 'meaning': '물', 'example': 'I drink water.'}
                ],
                'order': 3
            }
        ]

        for expr_data in expressions:
            SituationExpression.objects.create(lesson=lesson2, **expr_data)
            print(f"  Added expression: {expr_data['expression']}")


def create_travel_lessons(category):
    """Create sample lessons for travel category"""

    lesson, created = SituationLesson.objects.get_or_create(
        category=category,
        slug='gonghang-immigration',
        defaults={
            'title_ko': '공항 입국심사',
            'title_en': 'Airport Immigration',
            'language': 'EN',
            'order': 1
        }
    )
    print(f"{'Created' if created else 'Found'} lesson: {lesson}")

    if created:
        expressions = [
            {
                'expression': '관광 목적으로 왔어요.',
                'translation': "I'm here for tourism.",
                'pronunciation': '아임 히어 포 투어리즘',
                'situation_context': '입국 목적을 물어볼 때',
                'vocabulary': [
                    {'word': 'here', 'meaning': '여기', 'example': 'I am here.'},
                    {'word': 'for', 'meaning': '~을 위해', 'example': 'This is for you.'},
                    {'word': 'tourism', 'meaning': '관광', 'example': 'I love tourism.'}
                ],
                'order': 1
            },
            {
                'expression': '일주일 동안 머물 예정이에요.',
                'translation': "I'm staying for one week.",
                'pronunciation': '아임 스테잉 포 원 위크',
                'situation_context': '체류 기간을 말할 때',
                'vocabulary': [
                    {'word': 'stay', 'meaning': '머물다', 'example': 'I will stay here.'},
                    {'word': 'for', 'meaning': '~동안', 'example': 'Stay for a while.'},
                    {'word': 'week', 'meaning': '주', 'example': 'One week has seven days.'}
                ],
                'order': 2
            }
        ]

        for expr_data in expressions:
            SituationExpression.objects.create(lesson=lesson, **expr_data)
            print(f"  Added expression: {expr_data['expression']}")


def main():
    """Main function to create all sample data"""
    print("=" * 60)
    print("Creating Situation-Based Learning Sample Data")
    print("=" * 60)

    # Create categories
    print("\n[1/2] Creating categories...")
    categories = create_categories()

    # Create sample lessons
    print("\n[2/2] Creating sample lessons...")
    create_daily_lessons(categories['daily'])
    create_travel_lessons(categories['travel'])

    print("\n" + "=" * 60)
    print("✅ Sample data creation completed!")
    print("=" * 60)
    print(f"Categories created: {SituationCategory.objects.count()}")
    print(f"Lessons created: {SituationLesson.objects.count()}")
    print(f"Expressions created: {SituationExpression.objects.count()}")
    print("\nYou can now access the admin panel to add more lessons.")


if __name__ == '__main__':
    main()
